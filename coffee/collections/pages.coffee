class App.Collections.pages extends Backbone.Collection
  model: App.Models.Page

  url: '/pages'

App.Collections.Pages = new App.Collections.pages()
