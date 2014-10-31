class App.Views.pageLinkList extends Backbone.View

  initialize: =>
    @listenTo App.PageLinks, 'add', @render
    @listenTo App.PageLinks, 'remove', @render

  page_users: =>
    users = []
    App.Users.each (user) =>
      tmp = user.pick('id', 'pseudo')
      if @model.get('user_id') is user.get('id')
        tmp.creator = true
      link = App.PageLinks.findWhere
        page_id: @model.get('id'), user_id: user.get('id')
      if link then tmp.auth = true
      users.push(tmp)
    users

  render: =>
    template = Handlebars.compile $("#pageLinkListTemplate").html()
    @$el.html template(users: @page_users())
    @

  events:
    'click .create': 'create'
    'click .delete': 'delete'

  create: (e) =>
    page_id = @model.get('id')
    user_id = $(e.target).data('id')

    user = App.Users.findWhere(id: user_id)
    page = App.Pages.findWhere(id: page_id)

    hidden_key = App.S.hide user.get('shared'), page.get('key')

    App.PageLinks.create(
      page_id: page_id
      user_id: user_id
      hidden_key: hidden_key
    )
    false

  delete: (e) =>
    App.PageLinks.findWhere(
      page_id: @model.get('id')
      user_id: $(e.target).data('id')
    ).destroy()
    false
