Sequelize = require 'sequelize'
_         = Sequelize.Utils._

module.exports = (App) ->

  create: (req, res) ->
    return res.status(401).end() unless req.session.user_id
    pageUser = req.body
    App.Models.page.find(where:
      Sequelize.and(
        { id: pageUser.page_id },
        { user_id: req.session.user_id }
      )
    ).done (err, page) ->
      return res.status(401).end() if err
      App.Helpers.create_id 16, (id) ->
        pageUser.id = id
        App.Models.pageUser.create(pageUser).done (err, page) ->
          return res.status(401).end() if err
          res.status(201).json(pageUser)

  delete: (req, res) ->
    return res.status(401).end() unless req.session.user_id
    App.Models.pageUser.find(where: id: req.params.id).done (err, pageUser) ->
      return res.status(401).end() if err
      App.Models.page.find(
        Sequelize.and(
          { page_id: pageUser.page_id },
          { user_id: req.session.user_id }
        )
      ).done (err, page) ->
        return res.status(401).end() if err
        pageUser.destroy().done (err) ->
          return res.status(401).end() if err
          res.status(200).end()

  # A terme a mettre dans /login
  findAll: (req, res, next) ->
    return res.status(401).end() unless req.session.user_id
    App.Models.page.findAll(
      where: user_id: req.session.user_id
    ).done (err, pages) ->
      return res.status(401).end() if err
      page_ids = (page.id for page in pages)
      App.Models.pageUser.findAll(where: page_id: page_ids).done (err, pageUsers) ->
        return res.status(401).end() if err
        res.status(200).json(pageUsers)
