class App.Views.messageList extends Backbone.View
  initialize: =>
    super
    App.Collections.Messages.fetch(success: @render)
    @

  render: =>
    messages = App.Collections.Messages.toJSON()
    for message in messages
      user = App.Collections.Users.findWhere(id: message.user_id)
      if user
        message.user_pseudo = user.get('pseudo')
      destination = App.Collections.Users.findWhere(id: message.destination_id)
      if destination
        message.destination_pseudo = destination.get('pseudo')
    template = Handlebars.compile $("#messageListTemplate").html()
    @$el.html template(messages: messages)
    @
