Sequelize = require 'sequelize'
_         = Sequelize.Utils._

module.exports = (App) ->

  ## ###
  # Application end point
  ## ###

  create: (req, res, next) ->
    return res.status(401).end() unless req.session.user_id
    message = req.body
    message.user_id = req.session.user_id
    App.Helpers.create_id 16, (id) ->
      message.id = id
      App.Models.message.create(message).then (message) ->
        res.status(201).json(message)
        App.io.to(message.destination_id).emit('message', message)
      .error (err) ->
        return res.status(401).end()
    #io.to(message.destination_id).emit(message.user_id, message.hidden_content)

  ## ###
  # Login Middleware
  ## ###

  fetch_user: (req, res, next) ->
    query = {
      where:
        $or: [{ user_id: req.session.user_id, destination_id: req.params.dest_id },
              { user_id: req.params.dest_id, destination_id: req.session.user_id }]
    }
    if req.query.offset?
      query.offset = parseInt(req.query.offset, 10)
    if req.query.limit?
      query.limit = parseInt(req.query.limit, 10)
    console.log query
    App.Models.message.findAll(query).then (messages) ->
      res.json messages
    .error (err) ->
      return res.status(401).end()

  fetch_page: (req, res, next) ->
    query = {
      where: { destination_type: 'page', destination_id: req.params.dest_id }
    }
    if req.query.offset?
      query.offset = parseInt(req.query.offset, 10)
    if req.query.limit?
      query.limit = parseInt(req.query.limit, 10)
    console.log query
    App.Models.message.findAll(query).then (messages) ->
      res.json messages
    .error (err) ->
      return res.status(401).end()


#  fetch: (req, res, next) ->
#    a = (page.id for page in req.data.created_pages)
#    b = (page.id for page in req.data.accessible_pages)
#    page_ids = _.union(a,b)
#    App.Models.message.findAll(
#      where: Sequelize.or(
#        { user_id: req.data.I.id },
#        { destination_id: req.data.I.id },
#        { destination_id: page_ids }
#      )
#    ).done (err, messages) ->
#      return res.status(401).end() if err
#      req.data.messages = messages
#      next()

#App.Models.message.findAll(
#  where: Sequelize.or(
#    Sequelize.and(
#      { destination_type: 'user' },
#      Sequelize.or(
#        { user_id: req.session.user_id },
#        { destination_id: req.session.user_id }
#      )
#    ),
#    Sequelize.and(
#      { destination_type: 'page' },
#      { destination_id: page_ids }
#    )
#  )
#)
