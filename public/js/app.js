var App, socket;

App = {
  Models: {},
  Collections: {},
  Views: {}
};

socket = null;

var from_b64, from_hex, from_utf8, to_b64, to_hex, to_utf8;

to_b64 = function(bin) {
  return sjcl.codec.base64.fromBits(bin).replace(/\//g, '_').replace(/\+/g, '-');
};

from_b64 = function(b64) {
  return sjcl.codec.base64.toBits(b64.replace(/\_/g, '/').replace(/\-/g, '+'));
};

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

var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

App.Views.home = (function(superClass) {
  extend(home, superClass);

  function home() {
    this.render = bind(this.render, this);
    return home.__super__.constructor.apply(this, arguments);
  }

  home.prototype.render = function() {
    this.$el.html($("#homeViewTemplate").html());
    App.Views.UserList = new App.Views.userList({
      el: $("#userList")
    });
    App.Views.UserList.render();
    App.Views.MessageList = new App.Views.messageList({
      el: $("#messageList"),
      collection: App.Messages
    });
    App.Views.MessageList.render();
    App.Views.PageList = new App.Views.pageList({
      el: $("#pageList"),
      collection: App.Pages
    });
    App.Views.PageList.render();
    return this;
  };

  return home;

})(Backbone.View);

var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

App.Views.Index = (function(superClass) {
  extend(Index, superClass);

  function Index() {
    this.auto_signin = bind(this.auto_signin, this);
    this.signin = bind(this.signin, this);
    this.signup = bind(this.signup, this);
    this.store_login = bind(this.store_login, this);
    this.load_data = bind(this.load_data, this);
    this.init_user = bind(this.init_user, this);
    this.hash_file = bind(this.hash_file, this);
    this.render = bind(this.render, this);
    return Index.__super__.constructor.apply(this, arguments);
  }

  Index.prototype.render = function() {
    this.$el.html($("#logViewTemplate").html());
    return this;
  };

  Index.prototype.events = {
    'change #file_password_input': 'hash_file',
    'click #signin': 'signin',
    'click #signup': 'signup'
  };

  Index.prototype.hash_file = function(e) {
    var template;
    template = $("#StartHashFileTemplate").html();
    this.$("#file_password_input").replaceWith(_.template(template));
    return FileHasher(e.target.files[0], function(result) {
      template = $("#EndHashFileTemplate").html();
      this.$(".progress").replaceWith(_.template(template));
      this.$(".progress").addClass("progress-bar-success");
      return $('#file_password_result_input').val(result);
    });
  };

  Index.prototype.init_user = function() {
    var sha;
    sha = new sjcl.hash.sha256();
    sha.update($('#string_password_input').val());
    sha.update($('#file_password_result_input').val());
    App.I = new App.Models.I({
      pseudo: $('#pseudo_input').val(),
      password: sha.finalize()
    });
    return App.I.compute_secrets();
  };

  Index.prototype.load_data = function(res) {
    App.I.set(res.I).bare_mainkey().bare_ecdh();
    App.Users.push(App.I);
    App.Users.push(res.users);
    App.PageLinks.push(res.pageLinks);
    App.Pages.push(res.created_pages);
    App.Pages.push(res.accessible_pages);
    return App.Messages.push(res.messages);
  };

  Index.prototype.bare_data = function() {
    App.Users.each(function(user) {
      return user.shared();
    });
    App.Pages.each(function(page) {
      return page.bare();
    });
    return App.Messages.each(function(message) {
      return message.bare();
    });
  };

  Index.prototype.store_login = function() {
    localStorage.setItem("pseudo", App.I.get("pseudo"));
    localStorage.setItem("local_secret", to_b64(App.I.get("local_secret")));
    return localStorage.setItem("remote_secret", App.I.get("remote_secret"));
  };

  Index.prototype.signup = function() {
    this.init_user();
    App.I.create_ecdh().create_mainkey().hide_ecdh().hide_mainkey();
    App.I.isNew = function() {
      return true;
    };
    return App.I.on('error', (function(_this) {
      return function() {
        return alert("Login error...");
      };
    })(this)).on('sync', (function(_this) {
      return function() {
        if ($("#remember_input")[0].checked) {
          _this.store_login();
        }
        return App.Router.show("home");
      };
    })(this)).save();
  };

  Index.prototype.signin = function() {
    this.init_user();
    return App.I.login((function(_this) {
      return function(res) {
        var socket;
        if ($("#remember_input")[0].checked) {
          _this.store_login();
        }
        _this.load_data(res);
        _this.bare_data();
        socket = window.socket(App.socket = io());
        socket.emit('join', App.I.id, App.I.attributes.id);
        socket.on('message', function(message) {
          return App.Messages.push(message);
        });
        return App.Router.show("home");
      };
    })(this));
  };

  Index.prototype.auto_signin = function() {
    return App.I.login((function(_this) {
      return function(res) {
        if ($("#remember_input")[0].checked) {
          _this.store_login();
        }
        _this.load_data(res);
        _this.bare_data();
        return App.Router.show("home");
      };
    })(this));
  };

  return Index;

})(Backbone.View);

var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

App.Views.messageList = (function(superClass) {
  extend(messageList, superClass);

  function messageList() {
    this.render = bind(this.render, this);
    this.process_collection = bind(this.process_collection, this);
    return messageList.__super__.constructor.apply(this, arguments);
  }

  messageList.prototype.process_collection = function() {
<<<<<<< HEAD
<<<<<<< HEAD
    var destination, i, len, message, messages, user;
<<<<<<< HEAD
    messages = this.collection.sort().map(function(e) {
      return e.attributes;
    });
=======
    messages = this.collection.sort().toJSON();
>>>>>>> modifs by Max
    for (i = 0, len = messages.length; i < len; i++) {
      message = messages[i];
=======
    var destination, message, messages, user, _i, _len;
    messages = this.collection.sort().toJSON();
    for (_i = 0, _len = messages.length; _i < _len; _i++) {
      message = messages[_i];
>>>>>>> Revert "modifs by Max"
=======
    var destination, i, len, message, messages, user;
    messages = this.collection.sort().toJSON();
    for (i = 0, len = messages.length; i < len; i++) {
      message = messages[i];
>>>>>>> first try with socket.io (POC)
      user = App.Users.findWhere({
        id: message.user_id
      });
      destination = message.destination_type === "user" ? App.Users.findWhere({
        id: message.destination_id
      }) : App.Pages.findWhere({
        id: message.destination_id
      });
      message.source = user.attributes;
      message.destination = destination.attributes;
      message.createdAt = (new Date(message.createdAt)).toLocaleString();
    }
    return messages;
  };

  messageList.prototype.render = function() {
    var template;
    template = Handlebars.compile($("#messageListTemplate").html());
    this.$el.html(template({
      messages: this.process_collection()
    }));
    return this;
  };

  return messageList;

})(Backbone.View);

var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

App.Views.pageLinkList = (function(superClass) {
  extend(pageLinkList, superClass);

  function pageLinkList() {
    this["delete"] = bind(this["delete"], this);
    this.create = bind(this.create, this);
    this.render = bind(this.render, this);
    this.page_users = bind(this.page_users, this);
    this.initialize = bind(this.initialize, this);
    return pageLinkList.__super__.constructor.apply(this, arguments);
  }

  pageLinkList.prototype.initialize = function() {
    this.listenTo(App.PageLinks, 'add', this.render);
    return this.listenTo(App.PageLinks, 'remove', this.render);
  };

  pageLinkList.prototype.page_users = function() {
    var users;
    users = [];
    App.Users.each((function(_this) {
      return function(user) {
        var link, tmp;
        tmp = user.pick('id', 'pseudo');
        if (_this.model.get('user_id') === user.get('id')) {
          tmp.creator = true;
        }
        link = App.PageLinks.findWhere({
          page_id: _this.model.get('id'),
          user_id: user.get('id')
        });
        if (link) {
          tmp.auth = true;
        }
        return users.push(tmp);
      };
    })(this));
    return users;
  };

  pageLinkList.prototype.render = function() {
    var template;
    template = Handlebars.compile($("#pageLinkListTemplate").html());
    this.$el.html(template({
      users: this.page_users()
    }));
    return this;
  };

  pageLinkList.prototype.events = {
    'click .create': 'create',
    'click .delete': 'delete'
  };

  pageLinkList.prototype.create = function(e) {
    var hidden_key, page, page_id, user, user_id;
    page_id = this.model.get('id');
    user_id = $(e.target).data('id');
    user = App.Users.findWhere({
      id: user_id
    });
    page = App.Pages.findWhere({
      id: page_id
    });
    hidden_key = App.S.hide(user.get('shared'), page.get('key'));
    App.PageLinks.create({
      page_id: page_id,
      user_id: user_id,
      hidden_key: hidden_key
    });
    return false;
  };

  pageLinkList.prototype["delete"] = function(e) {
    App.PageLinks.findWhere({
      page_id: this.model.get('id'),
      user_id: $(e.target).data('id')
    }).destroy();
    return false;
  };

  return pageLinkList;

})(Backbone.View);

var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

App.Views.pageList = (function(superClass) {
  extend(pageList, superClass);

  function pageList() {
    this.new_page = bind(this.new_page, this);
    this.create_page = bind(this.create_page, this);
    this.render = bind(this.render, this);
    this.processed_pages = bind(this.processed_pages, this);
    return pageList.__super__.constructor.apply(this, arguments);
  }

  pageList.prototype.processed_pages = function() {
    var pages;
    pages = [];
    App.Pages.each(function(page) {
      var tmp, user;
      tmp = _.clone(page.attributes);
      user = App.Users.findWhere({
        id: tmp.user_id
      });
      tmp.user_name = user.get('pseudo');
      return pages.push(tmp);
    });
    return pages;
  };

  pageList.prototype.render = function() {
    var template;
    template = Handlebars.compile($("#pageListTemplate").html());
    this.$el.html(template({
      pages: this.processed_pages()
    }));
    return this;
  };

  pageList.prototype.events = {
    'keypress #create_page_input': 'create_page'
  };

  pageList.prototype.create_page = function(e) {
    var page;
    if (e.which === 13) {
      page = this.new_page($("#create_page_input").val());
      page.on('error', (function(_this) {
        return function() {
          return alert("Can't save...");
        };
      })(this));
      page.on('sync', (function(_this) {
        return function() {
          $("#create_page_input").val("");
          App.Pages.add(page);
          return _this.render();
        };
      })(this));
      return page.save();
    }
  };

  pageList.prototype.new_page = function(name) {
    var key;
    key = sjcl.random.randomWords(8);
    return new App.Models.Page({
      hidden_key: App.S.hide(App.I.get('mainkey'), key),
      name: name,
      key: key
    });
  };

  return pageList;

})(Backbone.View);

var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

App.Views.pageTalk = (function(superClass) {
  extend(pageTalk, superClass);

  function pageTalk() {
    this.go_home = bind(this.go_home, this);
    this.talk = bind(this.talk, this);
    this.render = bind(this.render, this);
    this.page_users = bind(this.page_users, this);
    return pageTalk.__super__.constructor.apply(this, arguments);
  }

  pageTalk.prototype.page_users = function() {
    return _.map(App.Users.toJSON(), function(user) {
      var link;
      link = App.pageLinks.where({
        page_id: this.model.get('id'),
        user_id: user.id
      });
      if (link) {
        user.auth = true;
      }
      return user;
    });
  };

  pageTalk.prototype.render = function() {
    var template;
    template = Handlebars.compile($("#pageTalkTemplate").html());
    this.$el.html(template({
      page: this.model.attributes
    }));
    $("textarea").autosize();
    this.messageList = new App.Views.messageList({
      el: $("#messageList"),
      collection: App.Messages.where_page(this.model.get('id'))
    });
    this.pageLinkList = new App.Views.pageLinkList({
      el: $("#pageLinkList"),
      model: this.model
    });
    this.messageList.render();
    return this.pageLinkList.render();
  };

  pageTalk.prototype.events = {
    'click #send_message': 'talk',
    'click #back_button': 'go_home'
  };

  pageTalk.prototype.talk = function() {
    var content, hidden_content, message;
    content = $("#message_input").val();
    hidden_content = App.S.hide_text(this.model.get('key'), content);
    message = new App.Models.Message({
      destination_type: "page",
      destination_id: this.model.get('id'),
      hidden_content: hidden_content,
      content: content
    });
    return message.on('error', (function(_this) {
      return function() {
        return alert("Sending error");
      };
    })(this)).on('sync', (function(_this) {
      return function() {
        App.Messages.add(message);
        _this.messageList.collection.push(message);
        _this.messageList.render();
        return $("#message_input").val("");
      };
    })(this)).save();
  };

  pageTalk.prototype.go_home = function() {
    return App.Router.show("home");
  };

  return pageTalk;

})(Backbone.View);

var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

App.Views.userList = (function(superClass) {
  extend(userList, superClass);

  function userList() {
    this.search_user = bind(this.search_user, this);
    this.keypress = bind(this.keypress, this);
    this.render = bind(this.render, this);
    return userList.__super__.constructor.apply(this, arguments);
  }

  userList.prototype.render = function() {
    var template;
    template = Handlebars.compile($("#userListTemplate").html());
    this.$el.html(template({
      users: App.Users.toJSON()
    }));
    return this;
  };

  userList.prototype.events = {
    'keypress #search_user_input': 'keypress'
  };

  userList.prototype.keypress = function(e) {
    if (e.which === 13) {
      return this.search_user($("#search_user_input").val());
    }
  };

  userList.prototype.search_user = function(pseudo) {
    var user;
    user = new App.Models.User({
      pseudo: pseudo
    });
    return user.on('error', (function(_this) {
      return function() {
        return alert("Not found...");
      };
    })(this)).on('sync', (function(_this) {
      return function() {
        $("#search_user_input").val("");
        user.shared();
        App.Users.add(user);
        return _this.render();
      };
    })(this)).fetch();
  };

  return userList;

})(Backbone.View);

var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

App.Views.userTalk = (function(superClass) {
  extend(userTalk, superClass);

  function userTalk() {
    this.render = bind(this.render, this);
    this.go_home = bind(this.go_home, this);
    this.hide_message = bind(this.hide_message, this);
    this.send_message = bind(this.send_message, this);
    return userTalk.__super__.constructor.apply(this, arguments);
  }

  userTalk.prototype.events = {
    'click #send_message': 'send_message',
    'click #back_button': 'go_home'
  };

  userTalk.prototype.send_message = function() {
    var content, hidden_content, message;
    content = $("#message_input").val();
    hidden_content = this.hide_message(content);
    message = new App.Models.Message({
      destination_type: "user",
      destination_id: this.model.get('id'),
      hidden_content: hidden_content,
      content: content
    });
    return message.on('error', (function(_this) {
      return function() {
        return alert("Sending error");
      };
    })(this)).on('sync', (function(_this) {
      return function() {
        App.Messages.add(message);
        _this.messageList.collection.push(message);
        _this.messageList.render();
        return $("#message_input").val("");
      };
    })(this)).save();
  };

  userTalk.prototype.hide_message = function(content) {
    if (this.model.get('id') === App.I.get('id')) {
      return App.S.hide_text(App.I.get('mainkey'), content);
    } else {
      return App.S.hide_text(this.model.get('shared'), content);
    }
  };

  userTalk.prototype.go_home = function() {
    return App.Router.show("home");
  };

  userTalk.prototype.render = function() {
    var template;
    template = Handlebars.compile($("#userTalkTemplate").html());
    this.$el.html(template({
      user: this.model.attributes
    }));
    $("textarea").autosize();
    this.messageList = new App.Views.messageList({
      el: $("#messageList"),
      collection: App.Messages.where_user(this.model.get('id'))
    });
    return this.messageList.render();
  };

  return userTalk;

})(Backbone.View);

var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

App.Models.Message = (function(superClass) {
  extend(Message, superClass);

  function Message() {
<<<<<<< HEAD
<<<<<<< HEAD
    this.bare = bind(this.bare, this);
<<<<<<< HEAD
    this.toJSON = bind(this.toJSON, this);
=======
>>>>>>> modifs by Max
=======
    this.bare = __bind(this.bare, this);
>>>>>>> Revert "modifs by Max"
=======
    this.bare = bind(this.bare, this);
>>>>>>> first try with socket.io (POC)
    return Message.__super__.constructor.apply(this, arguments);
  }

  Message.prototype.urlRoot = "/message";

  Message.prototype.toJSON = function() {
    return this.omit('content');
  };

  Message.prototype.bare = function() {
    var key, page, user;
    key = null;
    if (this.get('user_id') === App.I.get('id') && this.get('destination_id') === App.I.get('id')) {
      key = App.I.get('mainkey');
    } else if (this.get('destination_type') === 'user') {
      user = this.get('user_id') !== App.I.get('id') ? App.Users.findWhere({
        id: this.get('user_id')
      }) : App.Users.findWhere({
        id: this.get('destination_id')
      });
      key = user.get('shared');
    } else if (this.get('destination_type') === 'page') {
      page = App.Pages.findWhere({
        id: this.get('destination_id')
      });
      key = page.get('key');
    } else {
      return console.log('The message type is invalid');
    }
    return this.set({
      content: App.S.bare_text(key, this.get('hidden_content'))
    });
  };

  return Message;

})(Backbone.Model);

var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

App.Models.Page = (function(superClass) {
  extend(Page, superClass);

  function Page() {
    return Page.__super__.constructor.apply(this, arguments);
  }

  Page.prototype.urlRoot = "/page";

  Page.prototype.toJSON = function() {
    return this.pick("name", "hidden_key");
  };

  Page.prototype.bare = function() {
    var user;
    if (this.get('user_id') === App.I.get('id')) {
      return this.set({
        key: App.S.bare(App.I.get('mainkey'), this.get('hidden_key'))
      });
    } else {
      user = App.Users.findWhere({
        id: this.get('user_id')
      });
      return this.set({
        key: App.S.bare(user.get('shared'), this.get('hidden_key'))
      });
    }
  };

  return Page;

})(Backbone.Model);

var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

App.Models.PageLink = (function(superClass) {
  extend(PageLink, superClass);

  function PageLink() {
    return PageLink.__super__.constructor.apply(this, arguments);
  }

  PageLink.prototype.urlRoot = "/pageLink";

  return PageLink;

})(Backbone.Model);

var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

App.Models.User = (function(superClass) {
  extend(User, superClass);

  function User() {
    return User.__super__.constructor.apply(this, arguments);
  }

  User.prototype.urlRoot = "/user";

  User.prototype.idAttribute = "pseudo";

  User.prototype.shared = function() {
    var public_point, shared_point;
    public_point = App.S.curve.fromBits(from_b64(this.get('pubkey')));
    shared_point = public_point.mult(App.I.get('seckey'));
    return this.set({
      shared: sjcl.hash.sha256.hash(shared_point)
    });
  };

  return User;

})(Backbone.Model);

App.Models.I = (function(superClass) {
  extend(I, superClass);

  function I() {
    return I.__super__.constructor.apply(this, arguments);
  }

  I.prototype.toJSON = function() {
    return this.pick("id", "pseudo", "pubkey", "remote_secret", "hidden_seckey", "hidden_mainkey");
  };

  I.prototype.compute_secrets = function() {
    var cipher, key;
    key = sjcl.misc.pbkdf2(this.get('password'), this.get('pseudo'));
    cipher = new sjcl.cipher.aes(key);
    this.set('local_secret', sjcl.bitArray.concat(cipher.encrypt(App.S.x00), cipher.encrypt(App.S.x01)));
    return this.set('remote_secret', to_b64(sjcl.bitArray.concat(cipher.encrypt(App.S.x02), cipher.encrypt(App.S.x03))));
  };

  I.prototype.create_ecdh = function() {
    this.set({
      seckey: sjcl.bn.random(App.S.curve.r, 6)
    });
    return this.set({
      pubkey: to_b64(App.S.curve.G.mult(this.get('seckey')).toBits())
    });
  };

  I.prototype.hide_ecdh = function() {
    return this.set({
      hidden_seckey: App.S.hide_seckey(this.get('local_secret'), this.get('seckey'))
    });
  };

  I.prototype.bare_ecdh = function() {
    return this.set({
      seckey: App.S.bare_seckey(this.get('local_secret'), this.get('hidden_seckey'))
    });
  };

  I.prototype.create_mainkey = function() {
    return this.set({
      mainkey: sjcl.random.randomWords(8)
    });
  };

  I.prototype.hide_mainkey = function() {
    return this.set({
      hidden_mainkey: App.S.hide(this.get('local_secret'), this.get('mainkey'))
    });
  };

  I.prototype.bare_mainkey = function() {
    return this.set({
      mainkey: App.S.bare(this.get('local_secret'), this.get('hidden_mainkey'))
    });
  };

  I.prototype.login = function(cb) {
    return $.ajax({
      url: "/login",
      type: "POST",
      contentType: 'application/json',
      dataType: 'json',
      data: JSON.stringify(this)
    }).success(cb).error(function(res) {
      return alert(JSON.parse(res.responseText).error);
    });
  };

  return I;

})(App.Models.User);

var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

App.Collections.Messages = (function(superClass) {
  extend(Messages, superClass);

  function Messages() {
    this.comparator = bind(this.comparator, this);
    return Messages.__super__.constructor.apply(this, arguments);
  }

  Messages.prototype.url = '/messages';

  Messages.prototype.model = App.Models.Message;

  Messages.prototype.comparator = function(a, b) {
    return (new Date(a.get('createdAt'))) < (new Date(b.get('createdAt')));
  };

  Messages.prototype.where_user = function(id) {
    var messages;
    messages = new App.Collections.Messages();
    messages.push(this.where({
      destination_type: 'user',
      destination_id: id
    }));
    messages.push(App.Messages.where({
      destination_type: 'user',
      user_id: id
    }));
    return messages;
  };

  Messages.prototype.where_page = function(id) {
    var messages;
    messages = new App.Collections.Messages();
    messages.push(this.where({
      destination_type: 'page',
      destination_id: id
    }));
    return messages;
  };

  return Messages;

})(Backbone.Collection);

App.Messages = new App.Collections.Messages();

var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

App.Collections.PageLinks = (function(superClass) {
  extend(PageLinks, superClass);

  function PageLinks() {
    return PageLinks.__super__.constructor.apply(this, arguments);
  }

  PageLinks.prototype.model = App.Models.PageLink;

  PageLinks.prototype.url = '/pageLinks';

  return PageLinks;

})(Backbone.Collection);

App.PageLinks = new App.Collections.PageLinks();

var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

App.Collections.Pages = (function(superClass) {
  extend(Pages, superClass);

  function Pages() {
    return Pages.__super__.constructor.apply(this, arguments);
  }

  Pages.prototype.model = App.Models.Page;

  Pages.prototype.url = '/pages';

  return Pages;

})(Backbone.Collection);

App.Pages = new App.Collections.Pages();

var extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

App.Collections.Users = (function(superClass) {
  extend(Users, superClass);

  function Users() {
    return Users.__super__.constructor.apply(this, arguments);
  }

  Users.prototype.model = App.Models.User;

  Users.prototype.url = '/users';

  return Users;

})(Backbone.Collection);

App.Users = new App.Collections.Users();

var Router,
  bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

Router = (function(superClass) {
  extend(Router, superClass);

  function Router() {
    this.pageTalk = bind(this.pageTalk, this);
    this.userTalk = bind(this.userTalk, this);
    this.home = bind(this.home, this);
    this.index = bind(this.index, this);
    this.show = bind(this.show, this);
    return Router.__super__.constructor.apply(this, arguments);
  }

  Router.prototype.routes = {
    '': 'index',
    'home': 'home',
    'user/:id': 'userTalk',
    'page/:id': 'pageTalk'
  };

  Router.prototype.show = function(route) {
    return this.navigate(route, {
      trigger: true,
      replace: true
    });
  };

  Router.prototype.index = function() {
    this.view = new App.Views.Index({
      el: $("#content")
    });
    this.view.render();
    if (localStorage.length >= 3) {
      App.I = new App.Models.I({
        pseudo: localStorage.getItem("pseudo"),
        local_secret: from_b64(localStorage.getItem("local_secret")),
        remote_secret: localStorage.getItem("remote_secret")
      });
      return this.view.auto_signin();
    }
  };

  Router.prototype.home = function() {
    if (!App.I) {
      return this.show("");
    }
    if (this.view) {
      this.view.undelegateEvents();
    }
    App.Users.add(App.I);
    this.view = new App.Views.home({
      el: $("#content")
    });
    return this.view.render();
  };

  Router.prototype.userTalk = function(id) {
    var model;
    if (!App.I) {
      return this.show("");
    }
    if (this.view) {
      this.view.undelegateEvents();
    }
    model = App.Users.findWhere({
      id: id
    });
    if (model) {
      this.view = new App.Views.userTalk({
        el: $("#content"),
        model: model
      });
      return this.view.render();
    } else {
      console.log("user not found !");
      return this.show("home");
    }
  };

  Router.prototype.pageTalk = function(id) {
    var model;
    if (!App.I) {
      return this.show("");
    }
    if (this.view) {
      this.view.undelegateEvents();
    }
    model = App.Pages.findWhere({
      id: id
    });
    this.view = new App.Views.pageTalk({
      el: $("#content"),
      model: model
    });
    return this.view.render();
  };

  return Router;

})(Backbone.Router);

App.Router = new Router;

$(function() {
  return Backbone.history.start();
});
