class App.Models.Message extends Backbone.Model
  urlRoot: "/message"

  toJSON: =>
    @omit('content')


  bare: =>
    key = null

    if @get('user_id') is App.I.get('id') and @get('destination_id') is App.I.get('id')
      key = App.I.get('mainkey')

    else if @get('destination_type') is 'user'
      user = if @get('user_id') isnt App.I.get('id')
        App.Users.findWhere(id: @get('user_id'))
      else
        App.Users.findWhere(id: @get('destination_id'))
      key = user.get('shared')

    else if @get('destination_type') is 'page'
      page = App.Pages.findWhere(id: @get('destination_id'))
      key = page.get('key')
    else
      return console.log('The message type is invalid')

    @set content: App.S.bare_text(key, @get('hidden_content'))
