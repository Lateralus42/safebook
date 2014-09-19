class Messages extends Backbone.Collection
  model: App.Models.Message
  url: '/users'

App.Collections.Messages = new Messages()
