Sequelize = require 'sequelize'
_         = Sequelize.Utils._

module.exports = (App) ->

  create: (req, res, next) ->
    return res.status(401).end() unless req.session.user_id
    message = req.body
    message.user_id = req.session.user_id
    App.Helpers.create_id 16, (id) ->
      message.id = id
      App.Models.message.create(message).done (err, message) ->
        return res.status(401).end() if err
        res.status(201).json(message)

  # A terme a mettre dans /login
  findAll: (req, res, next) ->
    return res.status(401).end() unless req.session.user_id
    App.Models.message.findAll(
      where: Sequelize.or(
        { user_id: req.session.user_id },
        { destination_id: req.session.user_id }
      )
    ).done (err, messages) ->
      return res.status(401).end() if err
      res.status(200).json(messages)
