class Router extends Backbone.Router

  routes:
    '': 'index'
    'home': 'home'
    'logout': 'logout'
    'user/:id': 'userTalk'
    'page/:id': 'pageTalk'

  show: (route) =>
    @navigate(route, {trigger: true, replace: true})

  logout: =>
    localStorage.clear()
    App.Messages.reset()
    App.Users.reset()
    App.FriendRequests.reset()
    @show('')

  auto_signin_tried: false

  auto_signin: (callback) ->
    return @index() if @auto_signin_tried
    @auto_signin_tried = true
    return @index() if localStorage.length < 3

    App.I = new App.Models.I
      pseudo: localStorage.getItem "pseudo"
      local_secret: from_b64(localStorage.getItem("local_secret"))
      remote_secret: localStorage.getItem "remote_secret"
    App.I.login(
      ((res) =>
        App.I.set(res.I).bare_mainkey().bare_ecdh()
        # App.Users.push(App.I)
        App.Users.push(res.users)
        App.PageLinks.push(res.pageLinks)
        App.Pages.push(res.created_pages)
        App.Pages.push(res.accessible_pages)
        App.Messages.push(res.messages)
        App.Users.each (user) -> user.shared()
        App.Pages.each (page) -> page.bare()
        App.Messages.each (message) -> message.bare()
        callback()
      ),
      (=>
        localStorage.clear()
        console.log("fail")
        @index()
      ))

  index: =>
    return @auto_signin(=> @show("home")) unless @auto_signin_tried

    @navigate("", {trigger: false, replace: true})
    @view = new App.Views.Index(el: $("#content"))
    @view.render()

  home: =>
    return @auto_signin(@home) unless App.I or @auto_signin_tried
    return @show("") unless App.I

    @view.undelegateEvents() if @view
    # App.Users.add(App.I)

    @view = new App.Views.home(el: $("#content"))
    @view.render()

  userTalk: (id) =>
    return @auto_signin(=> @userTalk(id)) unless App.I or @auto_signin_tried
    return @show("") unless App.I

    @view.undelegateEvents() if @view
    model = App.Users.findWhere(id: id)
    @view = new App.Views.userTalk(el: $("#content"), model: model)
    @view.render()

  pageTalk: (id) =>
    return @auto_signin(=> @pageTalk(id)) unless App.I or @auto_signin_tried
    return @show("") unless App.I

    @view.undelegateEvents() if @view
    model = App.Pages.findWhere(id: id)
    @view = new App.Views.pageTalk(el: $("#content"), model: model)
    @view.render()

App.Router = new Router
