class App.Views.pageList extends Backbone.View

  render: =>
    template = Handlebars.compile $("#pageListTemplate").html()
    @$el.html template(pages: App.Collections.Pages.toJSON())
    @

  events:
    'keypress #create_page_input': 'create_page'

  create_page: (e) =>
    if e.which is 13
      name = $("#create_page_input").val()
      page = new App.Models.Page(name: name)
      page.on 'error', =>
        alert("Can't save...")
      page.on 'sync', =>
        $("#create_page_input").val("")
        App.Collections.Pages.add(page)
        @render()
      page.save()
