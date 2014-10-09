class App.Models.Page extends Backbone.Model
  urlRoot: "/page"

  toJSON: -> @pick("name", "hidden_key")
