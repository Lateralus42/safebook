class App.Models.Page extends Backbone.Model
  urlRoot: "/page"

  initialize: =>
    @on 'add', =>
      @bare()

  toJSON: -> @pick("name", "hidden_key")

  bare: ->
    if @get('user_id') is App.I.get('id')
      @set key: App.S.bare(App.I.get('mainkey'), @get('hidden_key'))
    else
      user = App.Users.findWhere(id: @get('user_id'))
      @set key: App.S.bare(user.get('shared'), @get('hidden_key'))
