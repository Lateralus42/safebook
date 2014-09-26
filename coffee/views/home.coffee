class App.Views.home extends Backbone.View

  render: =>
    @$el.html($("#homeViewTemplate").html())

    App.Views.UserList = new App.Views.userList(el: $("#userList"))
    App.Views.UserList.render()

    App.Views.MessageList = new App.Views.messageList(
      el: $("#messageList")
      collection: App.Collections.Messages
    )
    App.Views.MessageList.render()

    App.Views.GroupList = new App.Views.groupList(
      el: $("#groupList")
      collection: App.Collections.Groups
    )
    App.Views.GroupList.render()

    @
