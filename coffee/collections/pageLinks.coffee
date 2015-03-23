class App.Collections.PageLinks extends Backbone.Collection
  model: App.Models.PageLink
  url: '/pageLinks'

App.PageLinks = new App.Collections.PageLinks()
