module.exports = (App) ->

  # XXX
  gen_salt: -> "fixthissalt"
  hash: (password, salt) -> password
