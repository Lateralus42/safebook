casper.options.viewportSize = width: 1024, height: 768

getRandomInt = (max) ->
	Math.floor(Math.random() * (max + 1))

getRandomString = ->
  getRandomInt(9999999).toString()

user_name1 = getRandomString()
user_name2 = getRandomString()

casper.test.begin 'You can use it with several people', 4, (test) ->

  casper.start('http://0.0.0.0:8000/').waitForSelector '#pseudo_input', ->
    @sendKeys "#pseudo_input", user_name2
    @sendKeys "#string_password_input", user_name2
    @click "#signup"

  casper.waitForUrl('#home').thenOpen('http://0.0.0.0:8000/')
  casper.waitForSelector '#pseudo_input', ->
    @sendKeys "#pseudo_input", user_name1
    @sendKeys "#string_password_input", user_name1
    @click "#signup"

  casper.waitForUrl '#home', ->
    @sendKeys "#search_user_input", user_name2
    @sendKeys "#search_user_input", casper.page.event.key.Enter

  casper.waitForSelectorTextChange "#userList", ->
    test.assertElementCount("#userList li a", 2)

  casper.then ->
    @sendKeys "#create_page_input", "my page"
    @sendKeys "#create_page_input", casper.page.event.key.Enter

  casper.waitForSelector "#pageList a", ->
    @click("#pageList a")

  casper.waitForUrl /#page\/.*/, ->
    @sendKeys "#message_input", "Secret message"
    @click "#send_message"
    @clickLabel "(Add)"

  casper.thenOpen('http://0.0.0.0:8000/').waitForSelector '#pseudo_input', ->
    @sendKeys "#pseudo_input", user_name2
    @sendKeys "#string_password_input", user_name2
    @click "#signin"

  casper.waitForUrl '#home', ->
    @click("#pageList a")

  casper.waitForUrl /#page\/.*/, ->
    test.assertElementCount("#messageList > div", 1)
    test.assertSelectorHasText("#messageList", "Secret message")

  casper.thenOpen('http://0.0.0.0:8000/').waitForSelector '#pseudo_input', ->
    @sendKeys "#pseudo_input", user_name1
    @sendKeys "#string_password_input", user_name1
    @click "#signin"

  casper.waitForUrl '#home', ->
    @click("#pageList a")

  casper.waitForUrl /#page\/.*/, ->
    @clickLabel "(Remove)"

  # User 2 can't see the page
  casper.thenOpen('http://0.0.0.0:8000/').waitForSelector '#pseudo_input', ->
    @sendKeys "#pseudo_input", user_name2
    @sendKeys "#string_password_input", user_name2
    @click "#signin"

  casper.waitForUrl '#home', ->
    test.assertElementCount("#pageList a", 0)

  casper.then(-> test.done()).run()
