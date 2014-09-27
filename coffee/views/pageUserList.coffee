class App.Views.pageUserList extends Backbone.View

  page_users: =>
    users = App.Collections.Users.toJSON()
    for user in users
      links = App.Collections.PageUsers.findWhere(
        page_id: @model.get('id')
        user_id: user.id
      )
      user.auth = true if links
    users

  render: =>
    template = Handlebars.compile $("#pageUserListTemplate").html()
    @$el.html template(users: @page_users())
    @

  events:
    'click .create': 'create'
    'click .delete': 'delete'

  create: (e) =>
    # Chiffrer la clef de la page, puis
    # XXX
    # Sauvegarder le liens
    pageUser = new App.Models.PageUser(
      page_id: @model.id
      user_id: $(e.target).data('id')
    )
    pageUser.on 'error', =>
      alert("Can't save...")
    pageUser.on 'sync', =>
      App.Collections.PageUsers.add(pageUser)
      @render()
    pageUser.save()
    false

  delete: =>
    console.log "call delete"
    false