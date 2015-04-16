class App.Views.messageList extends Backbone.View

  process_collection: =>
    messages = @collection.sort().map((e) -> e.attributes)
    for message in messages
      user = App.Users.findWhere(id: message.user_id)
      destination = if message.destination_type == "user"
        App.Users.findWhere(id: message.destination_id)
      else
        App.Pages.findWhere(id: message.destination_id)
      message.source = user.attributes
      message.destination = destination.attributes
      message.createdAt = (new Date(message.createdAt)).toLocaleString()
    messages

  render: =>
    template = Handlebars.compile $("#messageListTemplate").html()
    @$el.html template(messages: @process_collection())
    @
