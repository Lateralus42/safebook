class App.Views.talk extends Backbone.View
  render: =>
    template = $("#talkTemplate").html()
    @$el.html _.template(template)(user: @model)
    $("textarea").autosize()

  events:
    'click #send_message': 'talk'

  talk: =>
    hidden_content = $("#message_input").val()
    # hidden_content = App.S.hide_text() ... @model.get('shared'), $("message_input").val()

    message = new App.Models.Message(
      destination_id: @model.get('id')
      hidden_content: hidden_content
    )
    message.on 'error', => alert "Sending error"
    message.on 'sync', =>
      $("#message_input").val("")
      App.Collections.Messages.add(message)
    message.save()
