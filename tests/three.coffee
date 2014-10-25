casper.options.viewportSize = width: 1024, height: 768

getRandomInt = (max) ->
	Math.floor(Math.random() * (max + 1))

getRandomString = ->
  getRandomInt(9999999).toString()

user_name1 = getRandomString()
user_name2 = getRandomString()
user_name3 = getRandomString()

casper.test.begin 'You can use it with several people', 1, (test) ->

  casper.start 'http://0.0.0.0:8000/', ->
    @sendKeys "#pseudo_input", user_name3
    @sendKeys "#string_password_input", user_name3
    @click "#signup"

  casper.waitForUrl('#home').thenOpen 'http://0.0.0.0:8000/', ->
    @sendKeys "#pseudo_input", user_name2
    @sendKeys "#string_password_input", user_name2
    @click "#signup"

  casper.waitForUrl('#home').thenOpen 'http://0.0.0.0:8000/', ->
    @sendKeys "#pseudo_input", user_name1
    @sendKeys "#string_password_input", user_name1
    @click "#signup"

  casper.waitForUrl('#home', ->
    @sendKeys "#search_user_input", user_name2
    @sendKeys "#search_user_input", casper.page.event.key.Enter
  ).wait 200, ->
    test.assertElementCount("#userList li a", 2)

  casper.waitForUrl('#home', ->
    @sendKeys "#search_user_input", user_name3
    @sendKeys "#search_user_input", casper.page.event.key.Enter
  ).wait 200, ->
    test.assertElementCount("#userList li a", 3)

  casper.then ->
    @sendKeys "#create_page_input", "my page"
    @sendKeys "#create_page_input", casper.page.event.key.Enter

  casper.wait 500, ->
    @click("#pageList a")

  casper.waitForUrl /#page\/.*/, ->
    @sendKeys "#message_input", "Secret message"
    @click "#send_message"

  casper.then(-> test.done()).run()
