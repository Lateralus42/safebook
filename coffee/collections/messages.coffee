class Messages extends Backbone.Collection
  model: App.Models.Message
  url: '/messages'

App.Collections.Messages = new Messages()
