class App.Collections.messages extends Backbone.Collection
  model: App.Models.Message

  url: '/messages'

  comparator: (a, b) =>
    (new Date(a.get('createdAt'))) < (new Date(b.get('createdAt')))

App.Collections.Messages = new App.Collections.messages()
