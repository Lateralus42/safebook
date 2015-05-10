class App.Views.userList extends Backbone.View

  initialize: =>
    @listenTo(App.Users, 'add', @render)

  render: =>
    if App.Users.length > 0
      template = Handlebars.compile $("#userListTemplate").html()
      @$el.html template(users: App.Users.toJSON())
    @

class App.Views.userRequestList extends Backbone.View
  initialize: =>
    @listenTo(@collection, 'add', @render)
    @listenTo(@collection, 'remove', @render)

  render_list: =>
    @$('#requests_list').empty()
    @collection.each (user) =>
      user_request_view = new App.Views.userRequest(model: user)
      user_request_view.render()
      @$('#requests_list').append(user_request_view.el)


  render: =>
    if App.FriendRequests.length > 0
      template = Handlebars.compile $("#userRequestListTemplate").html()
      @$el.html template(users: App.FriendRequests.toJSON())
      @render_list()
    else
      @$el.empty()
    @

class App.Views.userRequest extends Backbone.View

  events:
    'click a': 'accept_request'

  accept_request: (e) =>
    e.preventDefault()
    console.log 'add'
    $.ajax url: '/friend_requests/' + @model.get('id') + '/accept', success: (res) =>
      console.log 'muahaha'
      App.FriendRequests.remove @model
      App.Users.push @model
    , error: =>
      alert 'error !'

  render: =>
    template = Handlebars.compile $("#userRequestTemplate").html()
    @$el.html template(@model.toJSON())
    @

class App.Views.userSearch extends Backbone.View

  initialize: =>
    @listenTo(@collection, 'reset', @render_results)

  render: =>
    @$el.html $("#userSearchTemplate").html()
    @

  render_results: =>
    @$('#search_user_results').empty()
    @collection.each (user) =>
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
    $.ajax url: '/friend_requests/' + @model.get('id') + '/add', success: =>
      App.SearchResults.reset()
      $("#userSearchTemplate").val("")
      alert 'request sent !'
    , error: =>
      alert 'error !'


  render: =>
    template = Handlebars.compile $("#searchResultTemplate").html()
    @$el.html template(@model.toJSON())
    @

