class App.Views.talk extends Backbone.View
  render: =>
    template = $("#talkTemplate").html()
    @$el.html _.template(template)(user: @model)
