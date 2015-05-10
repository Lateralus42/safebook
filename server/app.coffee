fs        = require 'fs'
express   = require 'express'
Sequelize = require 'sequelize'
http      = require 'http'
session   = require 'express-session'
_         = Sequelize.Utils._

# ###
# Loading app
# ###

App =
  Controllers: {}
  Models: {}

App.Helpers = require("#{__dirname}/helpers")(App)

# Loading server and middlewares
app = express()
server = http.createServer(app)

sessionMiddleware = session(secret: "XXX SET THIS IN CONFIG XXX", resave: true, saveUninitialized: true)
app.use sessionMiddleware
app.use require('body-parser').json()
app.use (req, res, next) ->
  console.log('===== %s %s (session: %s) =====', req.method, req.url, req.session.user_id)
  console.log req.body if req.body.keys?
  next()
app.use express.static(__dirname + '/../public')



# tests with socket.io
io = App.io = require('socket.io')(server)

io.use (socket, next) ->
  #console.log socket.request.headers.cookie
  sessionMiddleware(socket.handshake, socket.request.res, next)
  next()

io.on 'connection', (socket) =>
  socket.on 'join', (name, id) =>
    console.log(name + ' joined')
    socket.handshake.session and console.log 'sessID: ' + socket.handshake.session.user_id
    socket.join(id)

# Load all App.Models in models/
sequelize = new Sequelize(null, null, null, dialect: 'sqlite', storage: 'db.sqlite')
for model in _.map(fs.readdirSync("#{__dirname}/models"), (f)-> f.split('.')[0])
  App.Models[model] = sequelize.import("#{__dirname}/models/#{model}")

# before
# CREATE TABLE IF NOT EXISTS `Friends` (`UserId` VARCHAR(255) NOT NULL REFERENCES `Users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE, `FriendId` VARCHAR(255) NOT NULL REFERENCES `Users` (`id`), PRIMARY KEY (`UserId`, `FriendId`));
# CREATE TABLE IF NOT EXISTS `friends` (`UserId` VARCHAR(255) NOT NULL REFERENCES `Users` (`id`), `FriendId` VARCHAR(255) NOT NULL REFERENCES `Users` (`id`), `createdAt` DATETIME NOT NULL, `updatedAt` DATETIME NOT NULL, PRIMARY KEY (`UserId`, `FriendId`));
# )

App.Models.friends = sequelize.define('friends',
        {
            UserId: {
                type: Sequelize.STRING,
                references: App.Models.user,
                referencesKey: 'id',
                # primaryKey: true
            },
            FriendId: {
                type: Sequelize.STRING,
                references: App.Models.user,
                referencesKey: 'id',
                # primaryKey: true
            },
            Confirmed: {
                type: Sequelize.INTEGER
            }
        }, { timestamps: false }) # A FINIR

App.Models.user.belongsToMany(App.Models.user, { as: 'Friends', through: App.Models.friends, foreignKey: 'UserId', constraints: false})
App.Models.user.belongsToMany(App.Models.user, { as: 'Friends2', through: App.Models.friends, foreignKey: 'FriendId', constraints: false})
# App.Models.user.belongsToMany(App.Models.user, { as: 'Friends', through: 'Friends'})
# App.Models.user.belongsToMany(App.Models.user, { as: 'FriendRequests', through: 'FriendRequests'})

# Load all App.Controllers in controllers/
for ctrl in _.map(fs.readdirSync("#{__dirname}/controllers"), (f)-> f.split('.')[0])
  App.Controllers[ctrl] = require("#{__dirname}/controllers/#{ctrl}")(App, sequelize)

# ###
# Server routes
# ###

# ###
# /login draft
# [
#   App.Controller.Users.auth,  // finish with req.data = {}; req.data.user = user
#   App.Controller.Links.fetch,
#   App.Controller.Pages.fetch,
#   App.Controller.Messages.fetch,
#   App.Controller.Users.fetch,
#   App.Middleware.send_req_data
# ]
# ###

app.post   '/user', App.Controllers.users.create
app.get    '/user/:pseudo', App.Controllers.users.find

app.get    '/friend_requests/:user_id/add', App.Controllers.users.send_request
app.get    '/friend_requests/:user_id/accept', App.Controllers.users.accept_request

app.post   '/login', [
    App.Controllers.users.auth,
#    App.Controllers.pages.fetch_created,
#    App.Controllers.pages.fetch_accessibles,
#    App.Controllers.pageLinks.fetch,
#    App.Controllers.messages.fetch,
#    App.Controllers.users.fetch,
    (req, res, next) ->
      console.log(req.data)
      next()
    ,(req, res) -> res.json(req.data)
  ]

app.get    '/messages/:dest_id', App.Controllers.messages.fetch

app.post   '/message', App.Controllers.messages.create
app.post   '/page', App.Controllers.pages.create

# Maybe post '/page/:page_id/link'
app.post   '/pageLink', App.Controllers.pageLinks.create
# Maybe delete '/page/:page_id/link/:id'
app.delete '/pageLink/:id', App.Controllers.pageLinks.delete

# Sync DB, then start server
sequelize.sync().then(->
  server.listen(8000)
  console.log("Server listening on port 8000")
).catch((e) ->
  console.log("DB error")
  console.log e
)
