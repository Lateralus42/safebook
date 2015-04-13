class App.Views.userTalk extends Backbone.View

  events:
    'click #send_message': 'send_message'
    'click #back_button': 'go_home'

  send_message: =>
    content = $("#message_input").val()
    hidden_content = @hide_message(content)

    message = new App.Models.Message
      destination_type: "user"
      destination_id: @model.get('id')
      hidden_content: hidden_content
      content: content

    message
      .on 'error', => alert "Sending error"
      .on 'sync', =>
        App.Messages.add(message)
        @messageList.collection.push(message)
        @messageList.render()
        $("#message_input").val("")
      .save()

  hide_message: (content) =>
    if @model.get('id') is App.I.get('id')
      App.S.hide_text(App.I.get('mainkey'), content)
    else
      App.S.hide_text(@model.get('shared'), content)

  go_home: =>
    App.Router.show("home")

  render: =>
    template = Handlebars.compile($("#userTalkTemplate").html())
    @$el.html(template(user: @model.attributes))
    $("textarea").autosize()

    @model.messages_collection = App.Messages.where_user(@model.get('id'))
    @messageList = new App.Views.messageList
      el: $("#messageList")
      collection: @model.messages_collection
    @messageList.render()
