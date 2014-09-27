class App.Collections.pageUsers extends Backbone.Collection
  model: App.Models.PageUser
  url: '/pageUsers'

App.Collections.PageUsers = new App.Collections.pageUsers()
