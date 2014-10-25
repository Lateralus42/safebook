class App.Views.pageLinkList extends Backbone.View

  initialize: =>
    @listenTo App.Collections.PageLinks, 'add', @render
    @listenTo App.Collections.PageLinks, 'remove', @render

  page_users: =>
    users = []
    App.Collections.Users.each (user) =>
      tmp = user.pick('id', 'pseudo')
      if @model.get('user_id') is user.get('id')
        tmp.creator = true
      link = App.Collections.PageLinks.findWhere
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

    user = App.Collections.Users.findWhere(id: user_id)
    page = App.Collections.Pages.findWhere(id: page_id)

    hidden_key = App.S.hide user.get('shared'), page.get('key')

    App.Collections.PageLinks.create(
      page_id: page_id
      user_id: user_id
      hidden_key: hidden_key
    )
    false

  delete: (e) =>
    App.Collections.PageLinks.findWhere(
      page_id: @model.get('id')
      user_id: $(e.target).data('id')
    ).destroy()
    false
