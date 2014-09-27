class App.Views.pageUserList extends Backbone.View

  render: =>
    template = Handlebars.compile $("#pageUserListTemplate").html()
    @$el.html template(users: @collection)
    @