class App.Views.talk extends Backbone.View
  render: =>
    template = $("#talkTemplate").html()
    @$el.html _.template(template)(user: @model)
    $("textarea").autosize()

  event:
    'click #send_message'

  talk: =>
    hidden_content = App.S.hide_text() #... $("message_input").val()

    message = App.Models.Message(
      destination: @model.get('id')
      hidden_content: hidden_content
    )
    message.on 'sync', =>
      $("#message_input").val("")
      App.Collections.Messages.add(message)
