class Router extends Backbone.Router
  routes:
    '': 'index'
    'home': 'home'
    'user/:pseudo': 'talk'

  show: (route) =>
    @navigate(route, {trigger: true, replace: true})

  index: =>
    App.Content = new App.Views.log(el: $("#content"))
    App.Content.render()

    # Dans le futur:
    # Faire des trucs si on a un bon cookie :)

  home: =>
    return @show("") unless App.I

    App.Collections.Users.add(App.I)

    App.Content = new App.Views.home(el: $("#content"))
    App.Content.render()

    App.Views.UserList = new App.Views.userList(el: $("#userList"))
    App.Views.UserList.render()

    App.Views.MessageList = new App.Views.messageList(el: $("#messageList"))

  talk: (pseudo) =>
    return @show("") unless App.I

    model = App.Collections.Users.get(pseudo)
    unless model
      alert "user not found !"
      return @show("home")

    console.log model

    App.Content = new App.Views.talk(
      el: $("#content")
      model: model
    )
    App.Content.render()

    App.Views.TalkMessageList = new App.Views.talkMessageList(
      el: $("#talkMessageList")
      model: model
    )

App.Router = new Router
