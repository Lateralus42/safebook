class App.Views.talkMessageList extends Backbone.View

  initialize: =>
    super # needed ?
    @collection = new App.Collections.messages()
    @collection.push(App.Collections.Messages.where(user_id: @model.get('id')))
    @collection.push(App.Collections.Messages.where(destination_id: @model.get('id')))
    @render()

  render: =>
    template = Handlebars.compile $("#messageListTemplate").html()
    @$el.html template(messages: App.Collections.Messages.toJSON())
    @
