class Router extends Backbone.Router

  routes:
    '': 'index'
    'home': 'home'
    'user/:id': 'userTalk'
    'page/:id': 'pageTalk'

  show: (route) =>
    @navigate(route, {trigger: true, replace: true})

  index: =>
    @view = new App.Views.Index(el: $("#content"))
    @view.render()

    if localStorage.length isnt 0
      App.I = new App.Models.I
        pseudo: localStorage.getItem "pseudo"
        local_secret: from_b64(localStorage.getItem("local_secret"))
        remote_secret: localStorage.getItem "remote_secret"
      # @view.auto_signin()

  home: =>
    return @show("") unless App.I
    @view.undelegateEvents() if @view

    App.Users.add(App.I)
    @view = new App.Views.home(el: $("#content"))
    @view.render()

  userTalk: (id) =>
    return @show("") unless App.I
    @view.undelegateEvents() if @view

    model = App.Users.findWhere(id: id)

    if model
      @view = new App.Views.userTalk(el: $("#content"), model: model)
      @view.render()
    else
      console.log "user not found !"
      @show("home")

  pageTalk: (id) =>
    return @show("") unless App.I
    @view.undelegateEvents() if @view

    model = App.Pages.findWhere(id: id)
    @view = new App.Views.pageTalk(el: $("#content"), model: model)
    @view.render()


App.Router = new Router
