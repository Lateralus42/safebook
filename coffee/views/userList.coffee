class App.Views.userList extends Backbone.View

  render: =>
    template = Handlebars.compile $("#userListTemplate").html()
    @$el.html template(users: App.Users.toJSON())
    @

  events:
    'keypress #search_user_input': 'keypress'

  keypress: (e) =>
    if e.which is 13
      @search_user $("#search_user_input").val()

  search_user: (pseudo) =>
    user = new App.Models.User(pseudo: pseudo)
    user
      .on 'error', => alert("Not found...")
      .on 'sync', =>
        $("#search_user_input").val("")
        user.shared()
        App.Users.add(user)
        @render()
      .fetch()
