class App.Collections.Pages extends Backbone.Collection
  model: App.Models.Page
  url: '/pages'

App.Pages = new App.Collections.Pages()
