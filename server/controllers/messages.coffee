crypto    = require 'crypto'
Sequelize = require 'sequelize'
_         = Sequelize.Utils._

module.exports = (App) ->

  create: (req, res, next) ->
    return res.status(401).end() unless req.session.user_id
    message = req.body
    message.user_id = req.session.user_id
    crypto.randomBytes 48, (ex, buf) ->
      message.id = buf.toString('base64').replace(/\//g,'_').replace(/\+/g,'-')
      App.Models.message.create(message).done (err, message) ->
        return res.status(401).end() if err
        res.status(201).json(message)
