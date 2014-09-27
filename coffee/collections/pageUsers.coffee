class App.Collections.pageUsers extends Backbone.Collection
  model: App.Models.pageUser
  url: '/pageUsers'

App.Collections.PageUsers = new App.Collections.pageUsers()
