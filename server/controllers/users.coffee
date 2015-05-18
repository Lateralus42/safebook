Sequelize = require 'sequelize'
_         = Sequelize.Utils._

module.exports = (App, sequelize) ->

  create: (req, res) ->
    user = req.body
    user.id = user.pubkey.substring(0, 8)
    user.remote_password_salt = App.Helpers.gen_salt()
    user.remote_password_hash = App.Helpers.hash(req.body.remote_secret, user.remote_secret_salt)
    App.Models.user.create(user).then((user) ->
      req.session.user_id = user.id
      res.status(201).send(user)).error (error) ->
        return res.status(401).end()

#   find: (req, res) ->
#     pseudo = req.params.pseudo
#     App.Models.user.find(where: pseudo: pseudo).done (err, user) ->
#       return res.status(401).end() if err or !user
#       console.log 'adding user id: ' + req.session.user_id
#       App.Models.user.find(where: id: req.session.user_id).done (err, adding_user) ->
#         console.log 'user trouve'
#         console.log adding_user.public()
#         adding_user.addFriends(user)
#         App.io.to(user.id).emit('add', adding_user.public())
#       res.json(user.public())

  find: (req, res) ->
    return unless req.session.user_id
    pseudo = req.params.pseudo
    App.Models.user.findAll(where: not: {id: req.session.user_id}, pseudo: $like: '%' + pseudo + '%').then((users) ->
      users_list = (user.public() for user in users)
      console.log users_list
      res.json(users_list))
        .error (err) ->
          console.log(err)

  send_request: (req, res) ->
    # App.Models.user.find(where: id: req.session.user_id).then (adding_user) ->
    #   App.Models.user.find(where: id: req.params.user_id).then (added_user) ->
    #     added_user.addFriendRequests(adding_user)
    #     res.json(added_user)
      sequelize.query("INSERT INTO friends (UserId, FriendId, Confirmed) VALUES (:user_id, :friend_id, 0);",
        { replacements: { user_id: req.session.user_id, friend_id: req.params.user_id},
        type: sequelize.QueryTypes.INSERT })
        .then (result) ->
          App.Models.user.find(req.session.user_id).then (user) ->
            App.io.to(req.params.user_id).emit('add', user.public())
            res.json({status: 'success'})
        .catch (error) ->
          return res.status(401).end()
    

  accept_request: (req, res) ->
    sequelize.query("UPDATE friends SET Confirmed = 1 WHERE userId = :user_id AND friendId = :friend_id AND Confirmed = 0;",
      { replacements: { user_id: req.params.user_id, friend_id: req.session.user_id },
      type: sequelize.QueryTypes.UPDATE})
      .then (result) ->
        App.Models.user.find(req.session.user_id).then (user) ->
          App.io.to(req.params.user_id).emit('accept', user.public())
          res.json({status: 'success'})
      .catch (error) ->
        return res.status(401).end()

  ## ###
  # Login Middleware
  ## ###

  auth: (req, res, next) ->
    App.Models.user.find(where: pseudo: req.body.pseudo).then (user) ->
      return res.status(401).json(error: "No such pseudo") if not user
      return res.status(401).json(error: "Bad password !") unless user.remote_password_hash is App.Helpers.hash(req.body.remote_secret, user.remote_password_salt)
      req.session.user_id = user.id
      req.data = {}
      req.data.I = user.full()
      # user.getFriends(attributes: ['id', 'pseudo', 'pubkey']).then (friends) ->
      sequelize.query("SELECT friend.id, friend.pseudo, friend.pubkey, relation.confirmed FROM friends AS relation INNER JOIN users AS friend ON (relation.FriendId = friend.id) OR (relation.UserId = friend.id) WHERE friend.id != :user_id AND relation.UserId = :user_id AND relation.confirmed = 1 OR friend.id != :user_id AND relation.FriendId = :user_id AND relation.confirmed != -1;", {replacements: { user_id: user.id }, type: sequelize.QueryTypes.SELECT}).then (friends) ->
        # console.log(friends)
        req.data.Friends = friends
        next()

  fetch: (req, res, next) ->
    a = (msg.user_id        for msg  in req.data.messages)
    b = (msg.destination_id for msg  in req.data.messages)
    c = (page.user_id       for page in req.data.accessible_pages)
    d = (link.user_id       for link in req.data.pageLinks)
    user_contacts = _.union(_.union(a,b), _.union(c,d))

    App.Models.user.findAll(where: id: user_contacts).then (users) ->
      req.data.users = (user.public() for user in users)
      next()
    .error (err) ->
      return res.status(401).end()

### Login old pipeline
    data = user_keys = user_contacts = null # old stuff
    ....
      App.Models.key.findAll(where: Sequelize.or({user_id: data.id}, {dest_id: data.id})).done (err, keys) ->
          data.keys = (key.full() for key in keys)
          user_keys = (key.id for key in keys)
          user_contacts = _.union (key.user_id for key in keys), (key.dest_id for key in keys)
          next(err, null)
      , (next) ->
        App.Models.user.findAll(where: id: user_contacts).done (err, users) ->
          data.users = (user.public() for user in users)
          next(err, null)
      , (next) ->
        App.Models.message.findAll(where: key_id: user_keys).done (err, messages) ->
          data.messages = (message.full() for message in messages)
          next(err, null)
    ], (err)->
###

  #findAll: (req, res) ->
  #  App.Models.user.findAll().done (err, users) ->
  #    return res.json(401, null) if err or !users
  #    res.json 200, users

  # XXX Middlewares

  #load: (req, res, next) ->
  #  return res.json(401, null) unless req.session.user_id
  #  App.Models.user.find(where: id: req.session.user_id).done (err, user) ->
  #    return res.json(401, null) if err
  #    req.user = user
  #    next()

  #find_dest: (req, res, next) ->
  #  return res.json(401, null) unless req.body.dest_id
  #  App.Models.user.find(where: id: req.body.dest_id).done (err, user) ->
  #    return res.json(401, null) if err or not user
  #    req.dest = user
  #    next()

