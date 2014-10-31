class App.Views.home extends Backbone.View

  render: =>
    @$el.html($("#homeViewTemplate").html())

    App.Views.UserList = new App.Views.userList(el: $("#userList"))
    App.Views.UserList.render()

    App.Views.MessageList = new App.Views.messageList(
      el: $("#messageList")
      collection: App.Messages
    )
    App.Views.MessageList.render()

    App.Views.PageList = new App.Views.pageList(
      el: $("#pageList")
      collection: App.Pages
    )
    App.Views.PageList.render()

    @
