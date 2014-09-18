class Users extends Backbone.Collection
  model: App.Models.User
  url: '/users'

App.Collections.Users = new Users()
