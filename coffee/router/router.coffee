class Router extends Backbone.Router

  routes:
    '': 'index'
    'home': 'home'
    'user/:id': 'userTalk'
    'page/:id': 'pageTalk'

  show: (route) =>
    @navigate(route, {trigger: true, replace: true})

  fetched: false

  index: =>
    App.Content = new App.Views.log(el: $("#content"))
    App.Content.render()

    # XXX Si localstorage -> reconnexion

  home: =>
    return @show("") unless App.I
    App.Content.undelegateEvents() if App.Content

    App.Users.add(App.I)
    App.Content = new App.Views.home(el: $("#content"))
    App.Content.render()

  userTalk: (id) =>
    return @show("") unless App.I
    App.Content.undelegateEvents() if App.Content

    model = App.Users.findWhere(id: id)

    if model
      App.Content = new App.Views.userTalk(el: $("#content"), model: model)
      App.Content.render()
    else
      console.log "user not found !"
      @show("home")

  pageTalk: (id) =>
    return @show("") unless App.I
    App.Content.undelegateEvents() if App.Content

    model = App.Pages.findWhere(id: id)

    if model
      App.Content = new App.Views.pageTalk(el: $("#content"), model: model)
      App.Content.render()
    else
      console.log "page not found !"
      @show("home")


App.Router = new Router
