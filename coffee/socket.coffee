class App.Socket
  
  init: ->
    @io = io()

    # probably useless because the server gets a 'connection' hook
    @io.emit('join', App.I.id, App.I.attributes.id)

    # future improvement: move all of this in the corresponding views

    @io.on 'message', (message) ->
      sender = App.Users.findWhere(id: message.user_id)
      message = new App.Models.Message message
      App.Messages.push(message)
      if sender and sender.messages_collection
        sender.messages_collection.push message

    @io.on 'add', (user) ->
      user = new App.Models.User user
      App.FriendRequests.push(user)

    @io.on 'accept', (user) ->
      user = new App.Models.User user
      App.Users.push(user)

App.Io = new App.Socket()
