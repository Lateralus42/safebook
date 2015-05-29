class App.Views.pageTalk extends Backbone.View

  page_users: =>
    _.map App.Users.toJSON(), (user) ->
      link = App.pageLinks.where
        page_id: @model.get('id')
        user_id: user.id
      user.auth = true if link
      user

  render: =>
    template = Handlebars.compile $("#pageTalkTemplate").html()
    @$el.html(template(page: @model.attributes))
    $("textarea").autosize()

    @messageList = new App.Views.messageList
      el: $("#messageList")
      collection: @model.messages_collection
    @pageLinkList = new App.Views.pageLinkList
      el: $("#pageLinkList")
      model: @model

    @messageList.render()
    @pageLinkList.render()

  events:
    'click #send_message': 'talk'
    'click #back_button': 'go_home'

  talk: =>
    content = $("#message_input").val()
    hidden_content = App.S.hide_text(@model.get('key'), content)

    message = new App.Models.Message
      destination_type: "page"
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

  go_home: =>
    App.Router.show("home")
