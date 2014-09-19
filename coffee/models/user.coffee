class App.Models.User extends Backbone.Model

  urlRoot: "/user"

  idAttribute: "pseudo"

  toJSON: ->
    @pick "id", "pseudo", "pubkey", "remote_secret", "hidden_seckey", "hidden_mainkey"

  auth: ->
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

  shared: (user) ->
    point = App.S.curve.fromBits(from_b64(@get('pubkey'))).mult(App.I.get('seckey'))
    @set shared: sjcl.hash.sha256.hash point.toBits()

###
  keys: ->
    keys = App.M.Keys.filter((o)=> o.user_id == @get('id') || App.M.Keys.where(dest_id: @get('id')))

  constructor: ->
    super
    unless @isNew()
      @load()
    else
      @on 'sync', @load
    @

  load: =>
    @bare_ecdh() if not @has('seckey') and @has('hidden_seckey')
    @bare_mainkey() if not @has('mainkey') and @has('hidden_mainkey')
    @shared() if not @has('shared') and @has('pubkey')

  log: =>
    shared = if @has('shared') then to_b64(@get('shared')) else "(null)"
###
