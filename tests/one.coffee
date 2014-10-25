casper.options.viewportSize = {width: 1024, height: 768}

getRandomInt = (max) -> Math.floor(Math.random() * (max + 1))
getRandomString = -> getRandomInt(9999999).toString()

user_name = getRandomString()

#messages_count = -> $("#messageList > div").size()

casper.test.begin 'You can use it alone', 3, (test) ->

  casper.start 'http://0.0.0.0:8000/', ->
    @sendKeys("#pseudo_input", user_name)
    @sendKeys("#string_password_input", user_name)
    @click("#signup")

  casper.waitForUrl '#home', ->
    @click("#userList a")

  casper.waitForUrl /#user\/.*/, ->
    @sendKeys("#message_input", "Secret message")
    @click("#send_message")

  casper.wait 500, ->
    test.assertElementCount("#messageList > div", 1)
    #test.assertEqual(@evaluate(messages_count), 1, "We see our message")

  casper.thenOpen 'http://0.0.0.0:8000/', ->
    @sendKeys("#pseudo_input", user_name)
    @sendKeys("#string_password_input", user_name)
    @click("#signin")

  casper.waitForUrl('#home').wait 500, ->
    @click("#userList a")

  casper.waitForUrl /#user\/.*/, ->
    test.assertElementCount("#messageList > div", 1)
    test.assertSelectorHasText("#messageList", "Secret message")
    #test.assertEqual(@evaluate(messages_count), 1, "We see our message again")

  casper.then ->
    test.done()

  casper.run()
