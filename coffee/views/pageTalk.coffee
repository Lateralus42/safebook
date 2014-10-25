class App.Views.pageTalk extends Backbone.View

  selected_messages: =>
    messages = new App.Collections.messages()
    messages.push(App.Collections.Messages.where(
      destination_type: 'page'
      destination_id: @model.get('id')
    ))
    messages

  page_users: =>
    users = App.Collections.Users.toJSON()
    for user in users
      links = App.Collections.pageLinks.where( # links au singulier après
        page_id: @model.get('id')
        user_id: user.id
      )
      user.auth = true if links
    users

  render: =>
    template = Handlebars.compile $("#pageTalkTemplate").html()
    @$el.html(template(page: @model.attributes))
    $("textarea").autosize()

    App.Views.MessageList = new App.Views.messageList(
      el: $("#messageList")
      collection: @selected_messages()
    )
    App.Views.MessageList.render()

    App.Views.PageLinkList = new App.Views.pageLinkList(
      el: $("#pageLinkList")
      model: @model
    )
    App.Views.PageLinkList.render()

  events:
    'click #send_message': 'talk'
    'click #back_button': 'go_home'

  talk: =>
    content = $("#message_input").val()
    hidden_content = App.S.hide_text @model.get('key'), content

    message = new App.Models.Message(
      destination_type: "page"
      destination_id: @model.get('id')
      hidden_content: hidden_content
      content: content
    )
    message.on 'error', => alert "Sending error"
    message.on 'sync', =>
      App.Collections.Messages.add(message)
      App.Views.MessageList.collection.push(message)
      App.Views.MessageList.render()
      $("#message_input").val("")
    message.save()

  go_home: =>
    App.Router.show("home")
