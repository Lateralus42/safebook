class App.Views.home extends Backbone.View

  render: =>
    template = Handlebars.compile $("#homeViewTemplate").html()
    @$el.html template(I: App.I.get('pseudo'))

    # App.Views.UserList = new App.Views.userList(el: $("#userList"))
    # App.Views.UserList.render()

    # App.Views.UserRequestList = new App.Views.userRequestList(el: $("#userRequestList"), collection: App.FriendRequests)
    # App.Views.UserRequestList.render()

    # App.Views.UserSearch = new App.Views.userSearch(el: $("#userSearch"), collection: App.SearchResults)
    # App.Views.UserSearch.render()

    # App.Views.PageList = new App.Views.pageList(el: $("#pageList"), collection: App.Pages)
    # App.Views.PageList.render()

    @left_bar = new App.Views.leftBar(el: @$("#left"))
    @left_bar.render()

    # @right_bar = new App.Views.rightBar(el: $("#right"))
    # @right_bar.render()

   #  @message_view = new App.Views.messageList(el: $("#middle"), collection: model.messages)
   #  @message_view.render()

    App.Views.SendMessage = new App.Views.userTalk(el: @$("#send_message"))
    App.Views.SendMessage.render()

    @member_list = new App.Views.pageLinkList(el: @$("#right"))
    # @related_pages = new App.Views.relatedPages()

    @

  select_talk: (id) =>
    @left_bar.select_talk id
    @
