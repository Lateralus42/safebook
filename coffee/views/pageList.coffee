class App.Views.pageList extends Backbone.View

  initialize: =>
    @listenTo(App.Pages, 'add', @render)
    @listenTo(App.Pages, 'remove', @render)

  processed_pages: =>
    pages = []
    App.Pages.each (page) ->
      tmp  = _.clone(page.attributes)
      user = if tmp.user_id is App.I.get('id')
        App.I
      else
        App.Users.findWhere(id: tmp.user_id)
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
      page = @new_page($("#create_page_input").val())
      page.on 'error', => alert("Can't save...")
      page.on 'sync', =>
        $("#create_page_input").val("")
        App.Pages.add(page)
        @render()
      page.save()

  new_page: (name) =>
    key  = sjcl.random.randomWords(8)
    new App.Models.Page(
      hidden_key: App.S.hide(App.I.get('mainkey'), key)
      name: name
      key: key
    )
