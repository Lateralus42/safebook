class App.Collections.Messages extends Backbone.Collection
  url: '/messages'

  model: App.Models.Message

  comparator: (a, b) =>
    (new Date(a.get('createdAt'))) < (new Date(b.get('createdAt')))

  where_user: (id) ->
    messages = new App.Collections.Messages()
    messages.push @where
      destination_type: 'user'
      destination_id: id
    messages.push App.Messages.where
      destination_type: 'user'
      user_id: id
    messages

  where_page: (id) ->
    messages = new App.Collections.Messages()
    messages.push @where
      destination_type: 'page'
      destination_id: id
    messages

App.Messages = new App.Collections.Messages()
