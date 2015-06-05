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
    App.Pages.reset()
    App.PageLinks.reset()
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
    @index_view = new App.Views.Index()
    $("#content").html(@index_view.render().el)

  home: =>
    console.log 'home'
    return @auto_signin(@home) unless App.I or @auto_signin_tried
    return @show("") unless App.I

    #@index_view.undelegateEvents() if @index_view
    @index_view.remove() if @index_view
    unless @home_view
      @home_view = new App.Views.home()
      $("#content").html(@home_view.render().el)

  userTalk: (id) =>
    console.log 'usertalk'
    return @auto_signin(=> @userTalk(id)) unless App.I or @auto_signin_tried
    return @show("") unless App.I

    unless @home_view
      @home_view = new App.Views.home()
      @home_view.render()
    # a revenir
    model = App.Users.findWhere(id: id)
    model.set active: true
    model.talk_item.render()
    if App.Talks.active_talk
      App.Talks.active_talk.set('active', false)
      App.Talks.active_talk.talk_item.render()
    App.Talks.active_talk = model
    model.message_view = model.message_view or new App.Views.messageList(el: $("#middle"), collection: model.messages)
    model.message_view.render()
    App.Views.SendMessage.model = model
    App.Views.SendMessage.model_type = 'user'
    # @home_view.related_pages.model = model
    # @home_view.related_pages.render()

  pageTalk: (id) =>
    return @auto_signin(=> @pageTalk(id)) unless App.I or @auto_signin_tried
    return @show("") unless App.I

    unless @home_view
      @home_view = new App.Views.home()
      @home_view.render()
    model = App.Pages.findWhere(id: id)
    model.set active: true
    model.talk_item.render()
    if App.Talks.active_talk
      App.Talks.active_talk.set('active', false)
      App.Talks.active_talk.talk_item.render()
    App.Talks.active_talk = model
    model.message_view = model.message_view or new App.Views.messageList(el: $("#middle"), collection: model.messages)
    model.message_view.render()
    App.Views.SendMessage.model = model
    App.Views.SendMessage.model_type = 'page'
    @home_view.member_list.model = model
    @home_view.member_list.render()

App.Router = new Router
