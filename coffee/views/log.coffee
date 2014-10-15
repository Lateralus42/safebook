class App.Views.log extends Backbone.View
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

    file = e.target.files[0]

    FileHasher file, (result) ->
      # Update progress bar
      template = $("#EndHashFileTemplate").html()
      @$(".progress").replaceWith(_.template(template))
      @$(".progress").addClass("progress-bar-success")
      # Store result
      $('#file_password_result_input').val(result)

  load_user: =>
    # Mix string_password and file_password using [sha256]
    sha = new sjcl.hash.sha256()
    sha.update($('#file_password_result_input').val())
    sha.update($('#string_password_input').val())

    App.I = new App.Models.User(
      pseudo:   $('#pseudo_input').val()
      password: sha.finalize()
    )
    App.I.auth()


  signup: =>
    @load_user()
    App.I.create_ecdh().create_mainkey().hide_ecdh().hide_mainkey()
    App.I.isNew = -> true

    App.I.on 'error', => alert("Login error...")
    App.I.on 'sync', => App.Router.show("home") # !
    App.I.save()

  signin: =>
    @load_user()

    $.ajax(
      type: "POST"
      url: "/login"
      data: JSON.stringify(App.I)
      contentType: 'application/json'
      dataType: 'json'
    ).success (res) ->
      console.log res

      App.I.set(res.I)
      App.I.bare_mainkey().bare_ecdh()

      App.Collections.Users.push App.I
      App.Collections.Users.push res.users
      App.Collections.PageLinks.push res.pageLinks
      App.Collections.Pages.push res.created_pages
      App.Collections.Pages.push res.accessible_pages
      App.Collections.Messages.push res.messages

      App.Collections.Users.each (user) ->
        user.shared()

      App.Collections.Messages.each (message) ->
        user = if message.get('user_id') isnt App.I.get('id')
          App.Collections.Users.findWhere(id: message.get('user_id'))
        else
          App.Collections.Users.findWhere(id: message.get('destination_id'))
        content = App.S.bare_text(user.get('shared'), message.get('hidden_content'))
        console.log content
        message.set content: content

      App.Router.show("home")
