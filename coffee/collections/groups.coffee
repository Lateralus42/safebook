class App.Collections.groups extends Backbone.Collection
  model: App.Models.Group

  url: '/groups'

App.Collections.Groups = new App.Collections.groups()
