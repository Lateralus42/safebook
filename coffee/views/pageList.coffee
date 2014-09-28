class App.Views.pageList extends Backbone.View

  processed_pages: =>
    pages = App.Collections.Pages.toJSON()
    for page in pages
      user = App.Collections.Users.findWhere(id: page.user_id)
      page.user_name = user.get('pseudo')
    pages

  render: =>
    template = Handlebars.compile $("#pageListTemplate").html()
    @$el.html template(pages: @processed_pages())
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