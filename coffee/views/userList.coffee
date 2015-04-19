class App.Views.userList extends Backbone.View

  initialize: =>
    @listenTo(App.Users, 'add', @render)

  render: =>
    template = Handlebars.compile $("#userListTemplate").html()
    @$el.html template(users: App.Users.toJSON())
    @

class App.Views.userSearch extends Backbone.View
  # collection: App.SearchResults

  initialize: =>
    @listenTo(@collection, 'reset', @render_results)

  render: =>
    @$el.html $("#userSearchTemplate").html()
    @

  render_results: =>
    @$('#search_user_results').empty()
    @collection.each (user) =>
      console.log user.toJSON()
      user_result_view = new App.Views.searchResult(model: user)
      user_result_view.render()
      @$('#search_user_results').append(user_result_view.el)

  events:
    'keyup #search_user_input': 'keypress'

  keypress: (e) =>
    #if e.which is 13
    @search_user $("#search_user_input").val()

  search_user: (pseudo) =>
    return unless pseudo
    $.ajax url: '/user/' + pseudo, success: (users) =>
      @collection.reset(users)


class App.Views.searchResult extends Backbone.View

  events:
    'click a': 'add_friend'

  add_friend: (e) =>
    e.preventDefault()
    console.log 'add'

  render: =>
    template = Handlebars.compile $("#searchResultTemplate").html()
    @$el.html template(@model.toJSON())
    @

