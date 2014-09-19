var App, from_b64, from_hex, from_utf8, to_b64, to_hex, to_utf8;

App = {
  Models: {},
  Collections: {},
  Views: {}
};

to_b64 = sjcl.codec.base64.fromBits;

from_b64 = sjcl.codec.base64.toBits;

to_hex = sjcl.codec.hex.fromBits;

from_hex = sjcl.codec.hex.toBits;

to_utf8 = sjcl.codec.utf8String.fromBits;

from_utf8 = sjcl.codec.utf8String.toBits;

App.S = {
  cipher: sjcl.cipher.aes,
  mode: sjcl.mode.ccm,
  curve: sjcl.ecc.curves.c384,
  x00: sjcl.codec.hex.toBits("0x00000000000000000000000000000000"),
  x01: sjcl.codec.hex.toBits("0x00000000000000000000000000000001"),
  x02: sjcl.codec.hex.toBits("0x00000000000000000000000000000002"),
  x03: sjcl.codec.hex.toBits("0x00000000000000000000000000000003"),
  encrypt: function(key, data, iv) {
    var cipher;
    cipher = new App.S.cipher(key);
    return App.S.mode.encrypt(cipher, data, iv);
  },
  decrypt: function(key, data, iv) {
    var cipher;
    cipher = new App.S.cipher(key);
    return App.S.mode.decrypt(cipher, data, iv);
  },
  hide: function(key, data) {
    var iv;
    iv = sjcl.random.randomWords(4);
    return to_b64(sjcl.bitArray.concat(iv, App.S.encrypt(key, data, iv)));
  },
  bare: function(key, data) {
    var hidden_data, iv;
    data = from_b64(data);
    iv = sjcl.bitArray.bitSlice(data, 0, 128);
    hidden_data = sjcl.bitArray.bitSlice(data, 128);
    return App.S.decrypt(key, hidden_data, iv);
  },
  hide_text: function(key, text) {
    return App.S.hide(key, from_utf8(text));
  },
  bare_text: function(key, data) {
    return to_utf8(App.S.bare(key, data));
  },
  hide_seckey: function(key, seckey) {
    return App.S.hide(key, seckey.toBits());
  },
  bare_seckey: function(key, data) {
    return sjcl.bn.fromBits(App.S.bare(key, data));
  }
};

var FileHasher;

FileHasher = function(file, callback) {
  var BLOCKSIZE, hash_slice, i, j, reader, sha;
  BLOCKSIZE = 2048;
  i = 0;
  j = Math.min(BLOCKSIZE, file.size);
  reader = new FileReader();
  sha = new sjcl.hash.sha256();
  hash_slice = function(i, j) {
    return reader.readAsArrayBuffer(file.slice(i, j));
  };
  reader.onloadend = function(e) {
    var array, bitArray;
    array = new Uint8Array(this.result);
    bitArray = sjcl.codec.bytes.toBits(array);
    sha.update(bitArray);
    if (i !== file.size) {
      i = j;
      j = Math.min(i + BLOCKSIZE, file.size);
      return setTimeout((function() {
        return hash_slice(i, j);
      }), 0);
    } else {
      return callback(sha.finalize());
    }
  };
  return hash_slice(i, j);
};

var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

App.Views.home = (function(_super) {
  __extends(home, _super);

  function home() {
    this.render = __bind(this.render, this);
    return home.__super__.constructor.apply(this, arguments);
  }

  home.prototype.render = function() {
    var template;
    template = $("#homeViewTemplate").html();
    this.$el.html(_.template(template)());
    return this;
  };

  return home;

})(Backbone.View);

var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

App.Views.log = (function(_super) {
  __extends(log, _super);

  function log() {
    this.signin = __bind(this.signin, this);
    this.signup = __bind(this.signup, this);
    this.load_user = __bind(this.load_user, this);
    this.hash_file = __bind(this.hash_file, this);
    this.render = __bind(this.render, this);
    return log.__super__.constructor.apply(this, arguments);
  }

  log.prototype.render = function() {
    var template;
    template = $("#logViewTemplate").html();
    this.$el.html(_.template(template)());
    return this;
  };

  log.prototype.events = {
    'change #file_password_input': 'hash_file',
    'click #signin': 'signin',
    'click #signup': 'signup'
  };

  log.prototype.hash_file = function(e) {
    var file, template;
    template = $("#StartHashFileTemplate").html();
    this.$("#file_password_input").replaceWith(_.template(template));
    file = e.target.files[0];
    return FileHasher(file, function(result) {
      template = $("#EndHashFileTemplate").html();
      this.$(".progress").replaceWith(_.template(template));
      this.$(".progress").addClass("progress-bar-success");
      return $('#file_password_result_input').val(result);
    });
  };

  log.prototype.load_user = function() {
    var password, sha;
    App.I = new App.Models.User({
      pseudo: $('#pseudo_input').val(),
      string_password: $('#string_password_input').val(),
      file_password: $('#file_password_result_input').val()
    });
    sha = new sjcl.hash.sha256();
    sha.update(App.I.get('file_password'));
    sha.update(App.I.get('string_password'));
    password = sha.finalize();
    App.I.set({
      password: password
    }).auth();
    App.I.on('error', (function(_this) {
      return function() {
        return alert("Login error...");
      };
    })(this));
    return App.I.on('sync', (function(_this) {
      return function() {
        return App.Router.show("home");
      };
    })(this));
  };

  log.prototype.signup = function() {
    this.load_user();
    App.I.create_ecdh().create_mainkey().hide_ecdh().hide_mainkey();
    App.I.isNew = function() {
      return true;
    };
    return App.I.save();
  };

  log.prototype.signin = function() {
    this.load_user();
    App.I.isNew = function() {
      return false;
    };
    return App.I.save();
  };

  return log;

})(Backbone.View);

var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

App.Views.talk = (function(_super) {
  __extends(talk, _super);

  function talk() {
    this.talk = __bind(this.talk, this);
    this.render = __bind(this.render, this);
    return talk.__super__.constructor.apply(this, arguments);
  }

  talk.prototype.render = function() {
    var template;
    template = $("#talkTemplate").html();
    this.$el.html(_.template(template)({
      user: this.model
    }));
    return $("textarea").autosize();
  };

  talk.prototype.event = 'click #send_message';

  talk.prototype.talk = function() {
    var hidden_content, message;
    hidden_content = App.S.hide_text();
    message = App.Models.Message({
      destination: this.model.get('id'),
      hidden_content: hidden_content
    });
    return message.on('sync', (function(_this) {
      return function() {
        $("#message_input").val("");
        return App.Collections.Messages.add(message);
      };
    })(this));
  };

  return talk;

})(Backbone.View);

var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

App.Views.userList = (function(_super) {
  __extends(userList, _super);

  function userList() {
    this.search_user = __bind(this.search_user, this);
    this.render = __bind(this.render, this);
    return userList.__super__.constructor.apply(this, arguments);
  }

  userList.prototype.render = function() {
    var template;
    template = $("#userListTemplate").html();
    this.$el.html(_.template(template)({
      users: App.Collections.Users.toArray()
    }));
    return this;
  };

  userList.prototype.events = {
    'keypress #search_input': 'search_user'
  };

  userList.prototype.search_user = function(e) {
    var user;
    if (e.which === 13) {
      user = new App.Models.User({
        pseudo: $("#search_input").val()
      });
      user.fetch();
      user.on('error', (function(_this) {
        return function() {
          return alert("Not found...");
        };
      })(this));
      return user.on('sync', (function(_this) {
        return function() {
          $("#search_input").val("");
          App.Collections.Users.add(user);
          return _this.render();
        };
      })(this));
    }
  };

  return userList;

})(Backbone.View);

var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

App.Models.User = (function(_super) {
  __extends(User, _super);

  function User() {
    return User.__super__.constructor.apply(this, arguments);
  }

  User.prototype.urlRoot = "/user";

  User.prototype.idAttribute = "pseudo";

  User.prototype.toJSON = function() {
    return this.pick("id", "pseudo", "pubkey", "remote_secret", "hidden_seckey", "hidden_mainkey");
  };

  User.prototype.auth = function() {
    var cipher, key;
    key = sjcl.misc.pbkdf2(this.get('password'), this.get('pseudo'));
    cipher = new sjcl.cipher.aes(key);
    this.set('local_secret', sjcl.bitArray.concat(cipher.encrypt(App.S.x00), cipher.encrypt(App.S.x01)));
    return this.set('remote_secret', to_b64(sjcl.bitArray.concat(cipher.encrypt(App.S.x02), cipher.encrypt(App.S.x03))));
  };

  User.prototype.create_ecdh = function() {
    this.set({
      seckey: sjcl.bn.random(App.S.curve.r, 6)
    });
    return this.set({
      pubkey: to_b64(App.S.curve.G.mult(this.get('seckey')).toBits())
    });
  };

  User.prototype.hide_ecdh = function() {
    return this.set({
      hidden_seckey: App.S.hide_seckey(this.get('local_secret'), this.get('seckey'))
    });
  };

  User.prototype.bare_ecdh = function() {
    return this.set({
      seckey: App.S.bare_seckey(this.get('local_secret'), this.get('hidden_seckey'))
    });
  };

  User.prototype.create_mainkey = function() {
    return this.set({
      mainkey: sjcl.random.randomWords(8)
    });
  };

  User.prototype.hide_mainkey = function() {
    return this.set({
      hidden_mainkey: App.S.hide(this.get('local_secret'), this.get('mainkey'))
    });
  };

  User.prototype.bare_mainkey = function() {
    return this.set({
      mainkey: App.S.bare(this.get('local_secret'), this.get('hidden_mainkey'))
    });
  };

  User.prototype.shared = function(user) {
    var point;
    point = App.S.curve.fromBits(from_b64(this.get('pubkey'))).mult(App.User.get('seckey'));
    return this.set({
      shared: sjcl.hash.sha256.hash(point.toBits())
    });
  };

  return User;

})(Backbone.Model);


/*
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
 */

var Users,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Users = (function(_super) {
  __extends(Users, _super);

  function Users() {
    return Users.__super__.constructor.apply(this, arguments);
  }

  Users.prototype.model = App.Models.User;

  Users.prototype.url = '/users';

  return Users;

})(Backbone.Collection);

App.Collections.Users = new Users();

var Router,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Router = (function(_super) {
  __extends(Router, _super);

  function Router() {
    this.talk = __bind(this.talk, this);
    this.home = __bind(this.home, this);
    this.index = __bind(this.index, this);
    this.show = __bind(this.show, this);
    return Router.__super__.constructor.apply(this, arguments);
  }

  Router.prototype.routes = {
    '': 'index',
    'home': 'home',
    'user/:pseudo': 'talk'
  };

  Router.prototype.show = function(route) {
    return this.navigate(route, {
      trigger: true,
      replace: true
    });
  };

  Router.prototype.index = function() {
    App.Content = new App.Views.log({
      el: $("#content")
    });
    return App.Content.render();
  };

  Router.prototype.home = function() {
    if (!App.I) {
      return this.show("");
    }
    App.Collections.Users.add(App.I);
    App.Content = new App.Views.home({
      el: $("#content")
    });
    App.Content.render();
    App.Views.UserList = new App.Views.userList({
      el: $("#userList")
    });
    return App.Views.UserList.render();
  };

  Router.prototype.talk = function(pseudo) {
    var model;
    model = App.Collections.Users.get(pseudo);
    if (!model) {
      alert("user not found !");
      return this.show("home");
    }
    console.log(model);
    App.Content = new App.Views.talk({
      el: $("#content"),
      model: model
    });
    return App.Content.render();
  };

  return Router;

})(Backbone.Router);

App.Router = new Router;

$(function() {
  return Backbone.history.start();
});
