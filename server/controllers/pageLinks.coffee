Sequelize = require 'sequelize'
_         = Sequelize.Utils._

module.exports = (App) ->

  create: (req, res) ->
    return res.status(401).end() unless req.session.user_id
    pageLink = req.body
    App.Models.page.find(where: { id: pageLink.page_id, user_id: req.session.user_id })
      .then (page) ->
        App.Helpers.create_id 16, (id) ->
          pageLink.id = id
          App.Models.pageLink.create(pageLink)
            .then (pageLink) ->
              page.hidden_key = pageLink.hidden_key
              App.io.to(pageLink.user_id).emit('pageLink:add', page)
              res.status(201).json(pageLink)
            .catch (err) ->
              return res.status(401).end()
      .catch (err) ->
        return res.status(401).end()

  delete: (req, res) ->
    return res.status(401).end() unless req.session.user_id
    App.Models.pageLink.find(where: id: req.params.id)
      .then (pageLink) ->
        console.log 'found pagelink'
        App.Models.page.find( where: { id: pageLink.page_id, user_id: req.session.user_id })
          .then (page) ->
            console.log 'found page'
            pageLink.destroy()
              .then ->
                console.log 'deleted pagelink'
                App.io.to(pageLink.user_id).emit('pageLink:delete', page)
                res.status(200).end()
              .catch (err) ->
                return res.status(401).end()
          .catch (err) ->
            return res.status(401).end()
      .catch (err) ->
        return res.status(401).end()

  ## ###
  # Login Middleware
  ## ###

  fetch: (req, res, next) ->
    a = (page.id for page in req.data.created_pages)
    b = (page.id for page in req.data.accessible_pages)
    page_ids = _.union(a, b)
    App.Models.pageLink.findAll(where: page_id: page_ids)
      .then (pageLinks) ->
        req.data.pageLinks = pageLinks
        next()
      .catch (err) ->
        return res.status(401).end()
