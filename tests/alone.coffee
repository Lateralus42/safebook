casper.options.viewportSize = width: 1024, height: 768

getRandomInt = (max) ->
	Math.floor(Math.random() * (max + 1))

getRandomPseudo = ->
  getRandomInt(9999999).toString()

user_name = getRandomPseudo()

casper.test.begin 'You can use it alone', 8, (test) ->

	casper.start 'http://0.0.0.0:8000/', ->
		@sendKeys "#pseudo_input", user_name
		@sendKeys "#string_password_input", user_name
		@click "#signup"

	casper.waitForUrl('#home').wait 500, ->
		test.assertExists('#userList')
		test.assertExists('#pageList')
		test.assertExists('#messageList')
		@click "#userList a"

	casper.waitForUrl /#user\/.*/, ->
    @sendKeys "#message_input", "Sample message"
    @click "#send_message"

  casper.wait 500, ->
    test.assertEqual(@evaluate(-> $("#messageList > div").size()), 1, "We see our message")

	casper.thenOpen 'http://0.0.0.0:8000/', ->
		@sendKeys "#pseudo_input", user_name
		@sendKeys "#string_password_input", user_name
		@click "#signin"

	casper.waitForUrl('#home').wait 500, ->
		test.assertExists('#userList')
		test.assertExists('#pageList')
		test.assertExists('#messageList')
		@click "#userList a"

	casper.waitForUrl /#user\/.*/, ->
    test.assertEqual(@evaluate(-> $("#messageList > div").size()), 1, "We see our message")

	casper.then ->
		test.done()

	casper.run()
