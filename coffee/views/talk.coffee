class App.Views.talk extends Backbone.View

  render: =>
    template = Handlebars.compile $("#talkTemplate").html()
    @$el.html(template(user: @model.attributes))
    $("textarea").autosize()

    messages = new App.Collections.messages()
    messages.push(App.Collections.Messages.where(user_id: @model.get('id')))
    messages.push(App.Collections.Messages.where(destination_id: @model.get('id')))

    App.Views.MessageList = new App.Views.messageList(
      el: $("#messageList")
      collection: messages
    )
    App.Views.MessageList.render()

  events:
    'click #send_message': 'talk'
    'click #back_button': 'go_home'

  talk: =>
    hidden_content = $("#message_input").val()
    # hidden_content = App.S.hide_text()
    # ...
    # @model.get('shared'), $("message_input").val()

    message = new App.Models.Message(
      destination_id: @model.get('id')
      hidden_content: hidden_content
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
