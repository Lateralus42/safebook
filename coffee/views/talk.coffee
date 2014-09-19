class App.Views.talk extends Backbone.View
  render: =>
    template = Handlebars.compile $("#talkTemplate").html()
    @$el.html template(user: @model.attributes)
    $("textarea").autosize()

  events:
    'click #send_message': 'talk'

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
      App.Views.TalkMessageList.collection.push(message)
      App.Views.TalkMessageList.render()
      $("#message_input").val("")
    message.save()
