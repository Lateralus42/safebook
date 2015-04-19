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
      App.Models.message.create(message).done (err, message) ->
        return res.status(401).end() if err
        res.status(201).json(message)
        App.io.to(message.destination_id).emit('message', message)

  ## ###
  # Login Middleware
  ## ###

  fetch: (req, res, next) ->
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
    App.Models.message.findAll(query).done (err, messages) ->
      return res.status(401).end() if err
      res.json messages


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
