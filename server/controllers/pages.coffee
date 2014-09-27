Sequelize = require 'sequelize'
_         = Sequelize.Utils._

module.exports = (App) ->

  create: (req, res) ->
    console.log "On pages.create"
    return res.status(401).end() unless req.session.user_id
    console.log "Got session.user_id"
    page = req.body
    page.user_id = req.session.user_id
    App.Helpers.create_id 16, (id) ->
      page.id = id
      console.log "registering :"
      console.log JSON.stringify(page)
      App.Models.page.create(page).done (err, page) ->
        console.log err
        return res.status(401).end() if err
        res.status(201).json(page)

  # A terme a mettre dans /login
  findAll: (req, res, next) ->
    return res.status(401).end() unless req.session.user_id
    App.Models.page.findAll(
      where: user_id: req.session.user_id
    ).done (err, pages) ->
      return res.status(401).end() if err
      res.status(200).json(pages)