casper.options.viewportSize = width: 1024, height: 768

getRandomInt = (max) ->
	Math.floor(Math.random() * (max + 1))

getRandomString = ->
  getRandomInt(9999999).toString()

user_name1 = getRandomString()
user_name2 = getRandomString()

casper.test.begin 'You can use it with several people', 4, (test) ->

  # Create User 2
  casper.start('http://0.0.0.0:8000/').wait 100, ->
    @sendKeys "#pseudo_input", user_name2
    @sendKeys "#string_password_input", user_name2
    @click "#signup"

  # Create User 1
  casper.waitForUrl('#home').thenOpen('http://0.0.0.0:8000/').wait 100, ->
    @sendKeys "#pseudo_input", user_name1
    @sendKeys "#string_password_input", user_name1
    @click "#signup"

  # Fetch User 2
  casper.waitForUrl('#home', ->
    @sendKeys "#search_user_input", user_name2
    @sendKeys "#search_user_input", casper.page.event.key.Enter
  ).wait 200, ->
    test.assertElementCount("#userList li a", 2)

  # Create Page
  casper.then ->
    @sendKeys "#create_page_input", "my page"
    @sendKeys "#create_page_input", casper.page.event.key.Enter
  casper.wait(500, -> @click("#pageList a"))

  # Send a message and add User 2
  casper.waitForUrl /#page\/.*/, ->
    @sendKeys "#message_input", "Secret message"
    @click "#send_message"
    @clickLabel "(Add)"

  # User 2 can see the page and the message
  casper.thenOpen('http://0.0.0.0:8000/').wait 100, ->
    @sendKeys "#pseudo_input", user_name2
    @sendKeys "#string_password_input", user_name2
    @click "#signin"
  casper.wait 500, -> @click("#pageList a")
  casper.waitForUrl /#page\/.*/, ->
    test.assertElementCount("#messageList > div", 1)
    test.assertSelectorHasText("#messageList", "Secret message")

  # User 1 remove User 2
  casper.thenOpen('http://0.0.0.0:8000/').wait 100, ->
    @sendKeys "#pseudo_input", user_name1
    @sendKeys "#string_password_input", user_name1
    @click "#signin"
  casper.wait 500, -> @click("#pageList a")
  casper.waitForUrl /#page\/.*/, ->
    @clickLabel "(Remove)"

  # User 2 can't see the page
  casper.thenOpen('http://0.0.0.0:8000/').wait 100, ->
    @sendKeys "#pseudo_input", user_name2
    @sendKeys "#string_password_input", user_name2
    @click "#signin"
  casper.waitForUrl '#home', ->
    test.assertElementCount("#pageList a", 0)

  casper.then(-> test.done()).run()
