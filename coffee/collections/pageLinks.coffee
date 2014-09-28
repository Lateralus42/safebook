class App.Collections.pageLinks extends Backbone.Collection
  model: App.Models.PageLink
  url: '/pageLinks'

App.Collections.PageLinks = new App.Collections.pageLinks()
