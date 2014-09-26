class Router extends Backbone.Router

  routes:
    '': 'index'
    'home': 'home'
    'user/:pseudo': 'talk'

  show: (route) =>
    @navigate(route, {trigger: true, replace: true})

  fetched: false

  index: =>
    App.Content = new App.Views.log(el: $("#content"))
    App.Content.render()

    # Dans le futur:
    # Faire des trucs si on a un bon cookie :)

  home: =>
    return @show("") unless App.I

    App.Content.undelegateEvents() if App.Content

    if @fetched
      App.Collections.Users.add(App.I)
      App.Content = new App.Views.home(el: $("#content"))
      App.Content.render()
    else
      App.Collections.Messages.fetch success: =>
        App.Collections.Users.fetch success: =>
          App.Collections.Groups.fetch success: =>
            @fetched = true
            App.Collections.Users.add(App.I)

            App.Content = new App.Views.home(el: $("#content"))
            App.Content.render()

  talk: (id) =>
    return @show("") unless App.I

    App.Content.undelegateEvents() if App.Content

    model = App.Collections.Users.findWhere(id: id)
    if model
      App.Content = new App.Views.talk(el: $("#content"), model: model)
      App.Content.render()
    else
      console.log "user not found !"
      return @show("home")


App.Router = new Router
