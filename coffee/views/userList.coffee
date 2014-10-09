class App.Views.userList extends Backbone.View

  render: =>
    template = Handlebars.compile $("#userListTemplate").html()
    @$el.html template(users: App.Collections.Users.toJSON())
    @

  events:
    'keypress #search_user_input': 'search_user'

  search_user: (e) =>
    if e.which is 13
      pseudo = $("#search_user_input").val()
      user = new App.Models.User(pseudo: pseudo)
      user.fetch()
      user.on 'error', => alert("Not found...")
      user.on 'sync', =>
        $("#search_user_input").val("")
        user.shared()
        App.Collections.Users.add(user)
        @render()
