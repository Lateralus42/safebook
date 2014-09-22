fs        = require 'fs'
express   = require 'express'
Sequelize = require 'sequelize'
_         = Sequelize.Utils._

# Loading App structure

App =
  Controllers: {}
  Models: {}

App.Helpers = require("#{__dirname}/helpers")(App)

sequelize = new Sequelize(null, null, null, dialect: 'sqlite', storage: 'db.sqlite')
for model in _.map(fs.readdirSync("#{__dirname}/models"), (f)-> f.split('.')[0])
  App.Models[model] = sequelize.import("#{__dirname}/models/#{model}")

for ctrl in _.map(fs.readdirSync("#{__dirname}/controllers"), (f)-> f.split('.')[0])
  App.Controllers[ctrl] = require("#{__dirname}/controllers/#{ctrl}")(App)

# Loading server and middlewares

server = express()

server.use require('express-session')(secret: "XXX SET THIS IN CONFIG XXX")

server.use require('body-parser').json()

server.use (req, res, next) ->
  console.log('%s %s', req.method, req.url)
  console.log req.body
  next()

server.use express.static(__dirname + '/../public')

# Server routes

server.post   '/user', App.Controllers.users.create
server.put    '/user/:pseudo', App.Controllers.users.login
server.get    '/user/:pseudo', App.Controllers.users.find

# A terme a mettre dans /login
server.get    '/users', App.Controllers.users.findAll

server.post   '/message', App.Controllers.messages.create

# A terme a mettre dans /login
server.get    '/messages', App.Controllers.messages.findAll

# Syncing DB, then server

sequelize.sync(force: true).error(->
  console.log("Database error")
).success(->
  server.listen(8000)
  console.log("Server listening on port 8000")
)
