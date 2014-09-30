Sequelize = require 'sequelize'
_         = Sequelize.Utils._

module.exports = (App) ->

  create: (req, res) ->
    return res.status(401).end() unless req.session.user_id
    pageLink = req.body
    App.Models.page.find(where:
      Sequelize.and(
        { id: pageLink.page_id },
        { user_id: req.session.user_id }
      )
    ).done (err, page) ->
      return res.status(401).end() if err
      App.Helpers.create_id 16, (id) ->
        pageLink.id = id
        App.Models.pageLink.create(pageLink).done (err, page) ->
          return res.status(401).end() if err
          res.status(201).json(pageLink)

  delete: (req, res) ->
    return res.status(401).end() unless req.session.user_id
    App.Models.pageLink.find(where: id: req.params.id).done (err, pageLink) ->
      return res.status(401).end() if err
      App.Models.page.find(
        Sequelize.and(
          { page_id: pageLink.page_id },
          { user_id: req.session.user_id }
        )
      ).done (err, page) ->
        return res.status(401).end() if err
        pageLink.destroy().done (err) ->
          return res.status(401).end() if err
          res.status(200).end()

  ## ###
  # Login Middleware
  ## ###

  fetch: (req, res, next) ->
    App.Models.pageLink.findAll(
      where: user_id: req.data.I.id
    ).done (err, pageLinks) ->
      return res.status(401).end() if err
      req.data.pageLinks = pageLinks
      next()
