class App.Models.Page extends Backbone.Model
  urlRoot: "/page"

  initialize: =>
    @messages = App.Messages.where_page(@get('id'))
    @on 'add', =>
      @bare()
      @set('type', 'page')
      @set('url', '#page/' + @get('id'))

  bare: ->
    if @get('user_id') is App.I.get('id')
      @set key: App.S.bare(App.I.get('mainkey'), @get('hidden_key'))
    else
      user = App.Users.findWhere(id: @get('user_id'))
      @set key: App.S.bare(user.get('shared'), @get('hidden_key'))
