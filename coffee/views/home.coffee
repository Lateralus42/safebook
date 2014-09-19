class App.Views.home extends Backbone.View
  render: =>
    template = $("#homeViewTemplate").html()
    @$el.html _.template(template)()
    @
