crypto    = require 'crypto'

module.exports = (App) ->

  create_id: (length, next) ->
    crypto.randomBytes length, (ex, buf) ->
      next(buf.toString('base64').replace(/\//g,'_').replace(/\+/g,'-'))

  # XXX
  gen_salt: -> "fixthissalt"
  hash: (password, salt) -> password
