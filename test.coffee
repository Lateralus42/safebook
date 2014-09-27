casper.options.viewportSize = width: 1024, height: 768

getRandomInt = (max) ->
	Math.floor(Math.random() * (max + 1))

user_name1 = getRandomInt(9999999).toString()
user_name2 = getRandomInt(9999999).toString()

casper.test.begin 'You can use it alone', 5, (test) ->

	casper.start 'http://0.0.0.0:8000/', ->
		test.assertTitle "Safebook"

	casper.then ->
		@sendKeys "#pseudo_input", user_name1
		@sendKeys "#string_password_input", user_name1
		@click "#signup"

	casper.waitForUrl('#home').wait 500, ->
		test.assertExists('#userList')
		test.assertExists('#pageList')
		test.assertExists('#messageList')
		@click "#userList a"

	casper.waitForUrl /#user\/.*/, ->
		test.assert(@fetchText('h3').trim() == "User Talk")

	casper.then ->
		test.done()

	casper.run()