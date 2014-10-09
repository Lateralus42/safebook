class App.Views.pageList extends Backbone.View

  processed_pages: =>
    pages = []
    App.Collections.Pages.each (page) ->
      tmp  = page.attributes
      user = App.Collections.Users.findWhere(id: tmp.user_id)
      tmp.user_name = user.get('pseudo')
      pages.push(tmp)
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
      key  = sjcl.random.randomWords(8)
      page = new App.Models.Page(
        hidden_key: App.S.hide(App.I.get('mainkey'), key)
        name: name
        key: key
      )
      page.on 'error', =>
        alert("Can't save...")
      page.on 'sync', =>
        $("#create_page_input").val("")
        App.Collections.Pages.add(page)
        @render()
      page.save()
