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

    @io.on 'pageLink:add', (page) ->
      console.log 'new page'
      console.log page
      page = new App.Models.Page page
      App.Pages.push page

    @io.on 'pageLink:delete', (page) ->
      console.log 'delete page'
      console.log page
      App.Pages.remove page.id

App.Io = new App.Socket()
