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

      App.Collections.Users.each (user) -> user.shared()

      App.Collections.Pages.each (page) ->
        if page.get('user_id') is App.I.get('id')
          page.set key: App.S.bare(App.I.get('mainkey'), page.get('hidden_key'))
        else
          user = App.Collections.Users.findWhere(id: page.get('user_id'))
          page.set key: App.S.bare(user.get('shared'), page.get('hidden_key'))

      App.Collections.Messages.each (message) ->
        key = null

        if message.get('user_id') is App.I.get('id') and message.get('destination_id') is App.I.get('id')
          key = App.I.get('mainkey')
        else if message.get('destination_type') is 'user'
          user = if message.get('user_id') is App.I.get('id')
            App.Collections.Users.findWhere(id: message.get('destination_id'))
          else
            App.Collections.Users.findWhere(id: message.get('user_id'))
          key = user.get('shared')
        else if message.get('destination_type') is 'page'
          page = App.Collections.Pages.findWhere(id: message.get('user_id'))
          key = page.get('key')
        else
          console.log('The message type is invalid')
          return

        content = App.S.bare_text(key, message.get('hidden_content'))
        message.set content: content

        console.log message.get 'hidden_content'
        console.log message.get 'content'

      App.Router.show("home")
