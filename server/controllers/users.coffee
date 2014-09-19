Sequelize = require 'sequelize'
_         = Sequelize.Utils._

module.exports = (App) ->

  create: (req, res) ->
    user = req.body
    user.id = user.pubkey.substring(0, 8)
    user.remote_password_salt = App.Helpers.gen_salt()
    user.remote_password_hash = App.Helpers.hash(req.body.remote_secret, user.remote_secret_salt)
    App.Models.user.create(user).done (err, user) ->
      return res.status(401).end() if err
      req.session.user_id = user.id
      res.status(201).send(user)

  find: (req, res) ->
    pseudo = req.params.pseudo
    App.Models.user.find(where: pseudo: pseudo).done (err, user) ->
      return res.status(401).end() if err or !user
      res.json(user.public())

  login: (req, res) ->
    App.Models.user.find(where: pseudo: req.params.pseudo).done (err, user) ->
      return res.status(401).json(error: "No such pseudo") if err or not user
      return res.status(401).json(error: "Bad password !") unless user.remote_password_hash is App.Helpers.hash(req.body.remote_secret, user.remote_password_salt)
      req.session.user_id = user.id
      data = user.full()
      res.json(data)

### Login old pipeline
    data = user_keys = user_contacts = null # old stuff
    ....
      App.Models.key.findAll(where: Sequelize.or({user_id: data.id}, {dest_id: data.id})).done (err, keys) ->
          data.keys = (key.full() for key in keys)
          user_keys = (key.id for key in keys)
          user_contacts = _.union (key.user_id for key in keys), (key.dest_id for key in keys)
          next(err, null)
      , (next) ->
        App.Models.user.findAll(where: id: user_contacts).done (err, users) ->
          data.users = (user.public() for user in users)
          next(err, null)
      , (next) ->
        App.Models.message.findAll(where: key_id: user_keys).done (err, messages) ->
          data.messages = (message.full() for message in messages)
          next(err, null)
    ], (err)->
###

  #findAll: (req, res) ->
  #  App.Models.user.findAll().done (err, users) ->
  #    return res.json(401, null) if err or !users
  #    res.json 200, users

  # XXX Middlewares

  #load: (req, res, next) ->
  #  return res.json(401, null) unless req.session.user_id
  #  App.Models.user.find(where: id: req.session.user_id).done (err, user) ->
  #    return res.json(401, null) if err
  #    req.user = user
  #    next()

  #find_dest: (req, res, next) ->
  #  return res.json(401, null) unless req.body.dest_id
  #  App.Models.user.find(where: id: req.body.dest_id).done (err, user) ->
  #    return res.json(401, null) if err or not user
  #    req.dest = user
  #    next()

