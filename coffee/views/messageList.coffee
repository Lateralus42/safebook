class App.Views.messageList extends Backbone.View

  render: =>
    @collection.sort()
    messages = @collection.toJSON()

    for message in messages
      user = App.Collections.Users.findWhere(id: message.user_id)
      if user # if useless now
        message.user_pseudo = user.get('pseudo')
      destination = App.Collections.Users.findWhere(id: message.destination_id)
      if destination # if useless now
        message.destination_pseudo = destination.get('pseudo')
      message.createdAt = (new Date(message.createdAt)).toLocaleString()

    template = Handlebars.compile $("#messageListTemplate").html()
    @$el.html template(messages: messages)
    @