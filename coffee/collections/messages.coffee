class App.Collections.Messages extends Backbone.Collection
  url: '/messages'

  model: App.Models.Message

  limit: 2

  comparator: (a, b) =>
    (new Date(a.get('createdAt'))) < (new Date(b.get('createdAt')))

  where_user: (id) ->
    messages = new App.Collections.Messages()
    messages.url = '/messages/user/' + id
    messages

  where_page: (id) ->
    messages = new App.Collections.Messages()
    messages.url = '/messages/page/' + id
    # messages.push @where
    #   destination_type: 'page'
    #   destination_id: id
    messages

App.Messages = new App.Collections.Messages()
