Sequelize = require 'sequelize'
_         = Sequelize.Utils._

module.exports = (App) ->

  create: (req, res) ->
    console.log "On groups.create"
    return res.status(401).end() unless req.session.user_id
    console.log "Got session.user_id"
    group = req.body
    group.user_id = req.session.user_id
    App.Helpers.create_id 16, (id) ->
      group.id = id
      console.log "registering :"
      console.log JSON.stringify(group)
      App.Models.group.create(group).done (err, group) ->
        console.log err
        return res.status(401).end() if err
        res.status(201).json(group)

  # A terme a mettre dans /login
  findAll: (req, res, next) ->
    return res.status(401).end() unless req.session.user_id
    App.Models.group.findAll(
      where: user_id: req.session.user_id
    ).done (err, groups) ->
      return res.status(401).end() if err
      res.status(200).json(groups)
