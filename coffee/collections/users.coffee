class App.Collections.Users extends Backbone.Collection
  url: '/users'

  model: App.Models.User

App.Users = new App.Collections.Users()
# App.FriendRequests = new App.Collections.Users()

class App.Collections.Talks extends Backbone.Collection
  initialize: =>
    @on 'update', => @sort()

  comparator: (a, b) =>
    console.log 'comparing'
    a_date = if a.messages.last()
      a.messages.last().get('createdAt')
    else
      a.get('createdAt') # should be a.get(friendship_confirmed_at)
    b_date = if b.messages.last()
      b.messages.last().get('createdAt')
    else
      b.get('createdAt') # should be b.get(friendship_confirmed_at)

    (new Date(a_date)) > (new Date(b_date))

App.Talks = new App.Collections.Talks()
