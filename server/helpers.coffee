crypto    = require 'crypto'

module.exports = (App) ->

  create_id: (length, next) ->
    crypto.randomBytes length, (ex, buf) ->
      str = buf.toString('base64').replace(/\//g,'_').replace(/\+/g,'-')
      next(str.replace(/\=+$/, ''))

  # XXX
  gen_salt: -> "fixthissalt"
  hash: (password, salt) -> password
