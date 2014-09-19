class App.Collections.messages extends Backbone.Collection
  model: App.Models.Message
  url: '/messages'

App.Collections.Messages = new App.Collections.messages()
