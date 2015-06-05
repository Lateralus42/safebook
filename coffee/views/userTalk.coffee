class App.Views.userTalk extends Backbone.View

  events:
    'click #send_message': 'send_message'
    'click #back_button': 'go_home'

  send_message: =>
    content = $("#message_input").val()
    hidden_content = @hide_message(content)

    message = new App.Models.Message
      destination_type: @model_type
      destination_id: @model.get('id')
      hidden_content: hidden_content
      content: content

    message
      .on 'error', => alert "Sending error"
      .on 'sync', =>
        @model.messages.push(message)
        $("#message_input").val("")
      .save()

  hide_message: (content) =>
    if @model_type == 'page'
      App.S.hide_text(@model.get('key'), content)
    else
      App.S.hide_text(@model.get('shared'), content)

  go_home: =>
    App.Router.show("home")

  render: =>
    @$el.html($("#userTalkTemplate").html())
    $("textarea").autosize()

    # @messageList = new App.Views.messageList
    #   el: $("#messageList")
    #   collection: @model.messages
    # @messageList.render()
