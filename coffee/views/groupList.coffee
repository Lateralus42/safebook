class App.Views.groupList extends Backbone.View

  render: =>
    template = Handlebars.compile $("#groupListTemplate").html()
    @$el.html template(groups: App.Collections.Groups.toJSON())
    @

  events:
    'keypress #search_group_input': 'search_group'

  search_group: (e) =>
    if e.which is 13
      name = $("#search_group_input").val()
      group = new App.Models.Group(name: name)
      group.save()
      group.on 'error', => alert("Can't save...")
      group.on 'sync', =>
        $("#search_group_input").val("")
        App.Collections.Groups.add(group)
        @render()
