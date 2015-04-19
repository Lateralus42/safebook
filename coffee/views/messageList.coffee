class App.Views.messageList extends Backbone.View

  initialize: =>
    @collection.fetch(remove: false, data: limit: @collection.limit)
    @listenTo(@collection, 'add', @render)
    
  events:
    'click #load_older_messages': 'load_older_messages'

  load_older_messages: =>
    @collection.fetch(remove: false, data: limit: @collection.limit, offset: @collection.length)

  process_collection: =>
    messages = @collection.sort().map((e) -> e.attributes)
    for message in messages
      user = if message.user_id is App.I.get('id')
        App.I
      else
        App.Users.findWhere(id: message.user_id)
      destination = if message.destination_id is App.I.get('id')
        App.I
      else if message.destination_type == "user"
        App.Users.findWhere(id: message.destination_id)
      else
        App.Pages.findWhere(id: message.destination_id)
      message.source = user.attributes
      message.destination = destination.attributes
      message.createdAt = (new Date(message.createdAt)).toLocaleString()
    messages

  render: =>
    template = Handlebars.compile $("#messageListTemplate").html()
    @$el.html template(messages: @process_collection())
    @
