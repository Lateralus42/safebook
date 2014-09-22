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

    # Testing
    $("#groupList").html($("#groupListTemplate").html())
    @
