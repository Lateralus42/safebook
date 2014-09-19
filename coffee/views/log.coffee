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
    App.I = new App.Models.User(
      pseudo:          $('#pseudo_input').val()
      string_password: $('#string_password_input').val()
      file_password:   $('#file_password_result_input').val()
    )

    # Mix string_password and file_password to "password"
    sha = new sjcl.hash.sha256()
    sha.update(App.I.get('file_password'))
    sha.update(App.I.get('string_password'))
    password = sha.finalize()

    App.I.set(password: password).auth()

    App.I.on 'error', => alert("Login error...")
    App.I.on 'sync', => App.Router.show("home")

  signup: =>
    @load_user()
    App.I.create_ecdh().create_mainkey().hide_ecdh().hide_mainkey()
    App.I.isNew = -> true
    App.I.save()

  signin: =>
    @load_user()
    App.I.isNew = -> false
    App.I.save()
