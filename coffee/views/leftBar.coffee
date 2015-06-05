class App.Views.leftBar extends Backbone.View

  initialize: =>
    # @listenTo App.Users, 'add', @render
    # @listenTo App.PageLinks, 'add', @render
    # @listenTo App.PageLinks, 'remove', @render
    @listenTo App.Talks, 'update', @render_items
    # @listenTo App.Messages, 'add', @render
    # this should work
    # App.Users.each (user) ->
    #   @listenTo user.messages, 'add', @render
    # App.Pages.each (page) ->
    #   @listenTo page.messages, 'add', @render
    # no this should work
   # App.Talks.each (talk) =>
   #   @listenTo talk.messages, 'add', @render
    @display_user_talks = on
    @display_group_talks = on


  events:
    'click #filter_user_talks': 'filter_user_talks'
    'click #filter_group_talks': 'filter_group_talks'

  filter_user_talks: (e) =>
    e.preventDefault()
    $("#filter_user_talks").toggleClass('active_filter')
    @display_user_talks = not @display_user_talks
    @render_items()

  filter_group_talks: (e) =>
    e.preventDefault()
    $("#filter_group_talks").toggleClass('active_filter')
    @display_group_talks = not @display_group_talks
    @render_items()

  render: =>
    template = Handlebars.compile $("#leftBarTemplate").html()
    @$el.html template()
    @render_items()
    @

  render_items: =>
    console.log 'render_items'
    @$("#talk_list").empty()
    # App.Talks.sort()
    App.Talks.each (talk) =>
      if @display_user_talks and (talk.get('type') is 'user' or talk.get('type') is 'request') or @display_group_talks and talk.get('type') is 'page'
        unless talk.talk_item
          talk.talk_item = new App.Views.talkItem(model: talk)
          talk.talk_item.render()
        @$("#talk_list").append(talk.talk_item.el)


class App.Views.talkItem extends Backbone.View
  initialize: =>
    @listenTo @model.messages, 'add', -> App.Talks.trigger 'update'

  render: =>
    template = Handlebars.compile $("#talkItemTemplate").html()
    console.log @model.toJSON()
    @$el.html template(@model.toJSON())
    @
