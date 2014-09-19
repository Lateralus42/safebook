class App.Views.messageList extends Backbone.View
  initialize: =>
    super # needed ?
    App.Collections.Messages.fetch(success: @render)
    @

  render: =>
    template = Handlebars.compile $("#messageListTemplate").html()
    @$el.html template(messages: App.Collections.Messages.toJSON())
    @
