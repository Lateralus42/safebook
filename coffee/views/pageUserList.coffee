class App.Views.pageUserList extends Backbone.View

  initialize: =>
    @listenTo App.Collections.PageUsers, 'add', @render
    @listenTo App.Collections.PageUsers, 'remove', @render

  page_users: =>
    users = App.Collections.Users.toJSON()
    for user in users
      if App.Collections.PageUsers.findWhere(
        page_id: @model.get('id')
        user_id: user.id
      ) then user.auth = true
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
    App.Collections.PageUsers.create(
      page_id: @model.get('id')
      user_id: $(e.target).data('id')
    )
    false

  delete: (e) =>
    pageUser = App.Collections.PageUsers.findWhere(
      page_id: @model.get('id')
      user_id: $(e.target).data('id')
    )
    pageUser.destroy()# success: =>
    # App.Collections.PageUsers.remove(pageUser)
    false
