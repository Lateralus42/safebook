class App.Views.pageTalk extends Backbone.View

  selected_messages: =>
    messages = new App.Collections.messages()
    messages.push(App.Collections.Messages.where(
      destination_type: 'page'
      destination_id: @model.get('id')
    ))
    messages

  page_users: =>
    App.Collections.Users.toJSON()

  render: =>
    template = Handlebars.compile $("#pageTalkTemplate").html()
    @$el.html(template(page: @model.attributes))
    $("textarea").autosize()

    App.Views.MessageList = new App.Views.messageList(
      el: $("#messageList")
      collection: @selected_messages()
    )
    App.Views.MessageList.render()

    App.Views.PageUserList = new App.Views.pageUserList(
      el: $("#pageUserList")
      collection: @page_users()
    )
    App.Views.PageUserList.render()

  events:
    'click #send_message': 'talk'
    'click #back_button': 'go_home'

  talk: =>
    # XXX
    # hidden_content = App.S.hide_text()
    # @model.get('shared'), $("message_input").val()
    hidden_content = $("#message_input").val()

    message = new App.Models.Message(
      destination_type: "page"
      destination_id: @model.get('id')
      hidden_content: hidden_content
    )
    message.on 'error', =>
      alert "Sending error"
    message.on 'sync', =>
      console.log "sync"
      console.log message
      App.Collections.Messages.add(message)
      App.Views.MessageList.collection.push(message)
      App.Views.MessageList.render()
      $("#message_input").val("")
    message.save()

  go_home: =>
    App.Router.show("home")