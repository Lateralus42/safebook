class App.Views.Index extends Backbone.View
  render: =>
    @$el.html $("#logViewTemplate").html()
    @

  events:
    'change #file_password_input': 'hash_file'
    'click #signin': 'signin'
    'click #signup': 'signup'

  hash_file: (e) =>
    template = $("#StartHashFileTemplate").html()
    @$("#file_password_input").replaceWith(_.template(template))

    FileHasher e.target.files[0], (result) ->
      template = $("#EndHashFileTemplate").html()
      @$(".progress").replaceWith(_.template(template))
      @$(".progress").addClass("progress-bar-success")
      $('#file_password_result_input').val(result)

  init_user: =>
    # Mix string_password and file_password using sha256
    sha = new sjcl.hash.sha256()
    sha.update($('#string_password_input').val())
    sha.update($('#file_password_result_input').val())

    App.I = new App.Models.I
      pseudo:   $('#pseudo_input').val()
      password: sha.finalize()
    App.I.compute_secrets()

  load_data: (res) =>
    App.I.set(res.I).bare_mainkey().bare_ecdh()

    App.Users.push(App.I)
    App.Users.push(res.users)
    App.PageLinks.push(res.pageLinks)
    App.Pages.push(res.created_pages)
    App.Pages.push(res.accessible_pages)
    App.Messages.push(res.messages)

  bare_data: ->
    App.Users.each (user) -> user.shared()
    App.Pages.each (page) -> page.bare()
    App.Messages.each (message) -> message.bare()

  store_login: =>
    localStorage.setItem "pseudo", App.I.get "pseudo"
    localStorage.setItem "local_secret", to_b64(App.I.get("local_secret"))
    localStorage.setItem "remote_secret", App.I.get "remote_secret"

  init_socket: =>
    socket = io()
    socket.emit('join', App.I.id, App.I.attributes.id)
    socket.on 'message', (message) ->
      console.log('new message')
      sender = App.Users.findWhere(id: message.user_id)
      message = new App.Models.Message message
      message.bare()
      App.Messages.push(message)
      console.log 'looking for user with id ' + sender
      if sender and sender.messages_collection
        sender.messages_collection.push message

  signup: =>
    @init_user()
    App.I.create_ecdh().create_mainkey().hide_ecdh().hide_mainkey()
    App.I.isNew = -> true
    App.I
      .on 'error', => alert("Login error...")
      .on 'sync', =>
        @store_login() if $("#remember_input")[0].checked
        @init_socket()
        App.Router.show("home")
      .save()

  signin: =>
    @init_user()
    App.I.login (res) =>
      @store_login() if $("#remember_input")[0].checked
      @load_data(res)
      @bare_data()
      @init_socket()
      App.Router.show("home")

  auto_signin: =>
    App.I.login (res) =>
      @store_login() if $("#remember_input")[0].checked
      @load_data(res)
      @bare_data()
      @init_socket()
      App.Router.show("home")
