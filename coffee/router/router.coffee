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

    App.Content.undelegateEvents() if App.Content

    unless App.Collections.Messages.length is 0 # XXX: Fix to use it only once
      App.Content = new App.Views.home(el: $("#content"))
      App.Content.render()
    else
      App.Collections.Messages.fetch success: =>
        App.Content = new App.Views.home(el: $("#content"))
        App.Content.render()

  talk: (pseudo) =>
    return @show("") unless App.I

    App.Content.undelegateEvents() if App.Content

    model = App.Collections.Users.get(pseudo)
    if model
      App.Content = new App.Views.talk(el: $("#content"), model: model)
      App.Content.render()
    else
      console.log "user not found !"
      return @show("home")


App.Router = new Router
