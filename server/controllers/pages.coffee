Sequelize = require 'sequelize'
_         = Sequelize.Utils._

module.exports = (App) ->

  create: (req, res) ->
    return res.status(401).end() unless req.session.user_id
    page = req.body
    page.user_id = req.session.user_id
    App.Helpers.create_id 16, (id) ->
      page.id = id
      App.Models.page.create(page).done (err, page) ->
        return res.status(401).end() if err
        res.status(201).json(page)

  ## ###
  # Login Middleware
  ## ###

  fetch: (req, res, next) ->
    App.Models.pageLink.findAll(
      where: user_id: req.data.I.id
    ).done (err, pageLinks) ->
      return res.status(401).end() if err
      req.data.pageLinks = pageLinks
      page_ids = (link.page_id for link in req.data.pageLinks)
      App.Models.page.findAll(
        where: Sequelize.or(
          { id: page_ids },
          { user_id: req.data.I.id }
        )
      ).done (err, pages) ->
        return res.status(401).end() if err
        req.data.pages = pages
        next()
