class App.Views.userTalk extends Backbone.View

  selected_messages: =>
    messages = new App.Collections.messages()
    messages.push(App.Collections.Messages.where(
      destination_type: 'user'
      user_id: App.I.get('id')
      destination_id: @model.get('id')
    ))
    messages.push(App.Collections.Messages.where(
      destination_type: 'user'
      user_id: @model.get('id')
      destination_id: App.I.get('id')
    ))
    messages

  render: =>
    template = Handlebars.compile $("#userTalkTemplate").html()
    @$el.html(template(user: @model.attributes))
    $("textarea").autosize()

    App.Views.MessageList = new App.Views.messageList(
      el: $("#messageList")
      collection: @selected_messages()
    )
    App.Views.MessageList.render()

  events:
    'click #send_message': 'talk' # why not on the messageList controller ?
    'click #back_button': 'go_home'

  talk: =>
    # XXX
    # hidden_content = App.S.hide_text()
    # @model.get('shared'), $("message_input").val()
    hidden_content = $("#message_input").val()

    message = new App.Models.Message(
      destination_type: "user"
      destination_id: @model.get('id')
      hidden_content: hidden_content
    )
    message.on 'error', =>
      alert "Sending error"
    message.on 'sync', =>
      App.Collections.Messages.add(message)
      App.Views.MessageList.collection.push(message)
      App.Views.MessageList.render()
      $("#message_input").val("")
    message.save()

  go_home: =>
    App.Router.show("home")
