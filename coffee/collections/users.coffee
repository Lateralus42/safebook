class App.Collections.users extends Backbone.Collection
  model: App.Models.User
  url: '/users'

App.Collections.Users = new App.Collections.users()
