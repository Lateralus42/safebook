class App.Views.messageList extends Backbone.View
  initialize: =>
    console.log "initialize"
    super
    App.Collections.Messages.fetch(success: @render)
    @

  render: =>
    console.log "render"
    template = $("#messageListTemplate").html()
    @$el.html _.template(template)(messages: App.Collections.Messages.toArray())
    @
