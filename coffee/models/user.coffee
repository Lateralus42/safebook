class App.Models.User extends Backbone.Model
  urlRoot: "/user"

  initialize: =>
    @on 'add', =>
      @messages = App.Messages.where_user(@get('id'))
      @shared()
      if @get('Confirmed') is 1
        @set('type', 'user')
      else
        @set('type', 'request')
      @set('url', '#user/' + @get('id'))
      
  idAttribute: "pseudo"

  shared: ->
    public_point = App.S.curve.fromBits(from_b64(@get('pubkey')))
    shared_point = public_point.mult(App.I.get('seckey'))
    @set shared: sjcl.hash.sha256.hash(shared_point)

class App.Models.I extends App.Models.User

  toJSON: ->
    @pick "id", "pseudo", "pubkey", "remote_secret", "hidden_seckey", "hidden_mainkey"

  compute_secrets: ->
    key    = sjcl.misc.pbkdf2(@get('password'), @get('pseudo'))
    cipher = new sjcl.cipher.aes(key)
    @set 'local_secret', sjcl.bitArray.concat(cipher.encrypt(App.S.x00), cipher.encrypt(App.S.x01))
    @set 'remote_secret', to_b64 sjcl.bitArray.concat(cipher.encrypt(App.S.x02), cipher.encrypt(App.S.x03))

  create_ecdh: ->
    @set seckey: sjcl.bn.random(App.S.curve.r, 6)
    @set pubkey: to_b64(App.S.curve.G.mult(@get('seckey')).toBits())

  hide_ecdh: ->
    @set hidden_seckey: App.S.hide_seckey(@get('local_secret'), @get('seckey'))

  bare_ecdh: ->
    @set seckey: App.S.bare_seckey(@get('local_secret'), @get('hidden_seckey'))

  create_mainkey: ->
    @set mainkey: sjcl.random.randomWords(8)

  hide_mainkey: ->
    @set hidden_mainkey: App.S.hide(@get('local_secret'), @get('mainkey'))

  bare_mainkey: ->
    @set mainkey: App.S.bare(@get('local_secret'), @get('hidden_mainkey'))

  login: (success_cb, error_cb) ->
    unless error_cb
      error_cb = -> alert(JSON.parse(res.responseText).error)
    $.ajax(
      url: "/login"
      type: "POST"
      contentType: 'application/json'
      dataType: 'json'
      data: JSON.stringify(@)
    ).success(success_cb).error(error_cb)
