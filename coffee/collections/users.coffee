class App.Collections.Users extends Backbone.Collection
  model: App.Models.User
  url: '/users'

App.Users = new App.Collections.Users()
