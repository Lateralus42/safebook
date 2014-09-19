class App.Views.home extends Backbone.View
  render: =>
    @$el.html $("#homeViewTemplate").html()
    @
