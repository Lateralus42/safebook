class App.Views.userList extends Backbone.View
  render: =>
    template = $("#userListTemplate").html()
    @$el.html _.template(template)(users: App.Collections.Users.toArray())
    @

  events:
    'keypress #search_input': 'search_user'

  search_user: (e) =>
    if e.which is 13
      user = new App.Models.User(pseudo: $("#search_input").val())
      user.fetch()
      user.on 'error', => alert("Not found...")
      user.on 'sync', =>
        $("#search_input").val("")
        App.Collections.Users.add(user)
        @render()
