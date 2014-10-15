var App, from_b64, from_hex, from_utf8, to_b64, to_hex, to_utf8;

App = {
  Models: {},
  Collections: {},
  Views: {}
};

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
    this.$el.html($("#homeViewTemplate").html());
    App.Views.UserList = new App.Views.userList({
      el: $("#userList")
    });
    App.Views.UserList.render();
    App.Views.MessageList = new App.Views.messageList({
      el: $("#messageList"),
      collection: App.Collections.Messages
    });
    App.Views.MessageList.render();
    App.Views.PageList = new App.Views.pageList({
      el: $("#pageList"),
      collection: App.Collections.Pages
    });
    App.Views.PageList.render();
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
    this.$el.html($("#logViewTemplate").html());
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
    var sha;
    sha = new sjcl.hash.sha256();
    sha.update($('#file_password_result_input').val());
    sha.update($('#string_password_input').val());
    App.I = new App.Models.User({
      pseudo: $('#pseudo_input').val(),
      password: sha.finalize()
    });
    return App.I.auth();
  };

  log.prototype.signup = function() {
    this.load_user();
    App.I.create_ecdh().create_mainkey().hide_ecdh().hide_mainkey();
    App.I.isNew = function() {
      return true;
    };
    App.I.on('error', (function(_this) {
      return function() {
        return alert("Login error...");
      };
    })(this));
    App.I.on('sync', (function(_this) {
      return function() {
        return App.Router.show("home");
      };
    })(this));
    return App.I.save();
  };

  log.prototype.signin = function() {
    this.load_user();
    return $.ajax({
      type: "POST",
      url: "/login",
      data: JSON.stringify(App.I),
      contentType: 'application/json',
      dataType: 'json'
    }).success(function(res) {
      console.log(res);
      App.I.set(res.I);
      App.I.bare_mainkey().bare_ecdh();
      App.Collections.Users.push(App.I);
      App.Collections.Users.push(res.users);
      App.Collections.PageLinks.push(res.pageLinks);
      App.Collections.Pages.push(res.created_pages);
      App.Collections.Pages.push(res.accessible_pages);
      App.Collections.Messages.push(res.messages);
      App.Collections.Users.each(function(user) {
        return user.shared();
      });
      App.Collections.Messages.each(function(message) {
        var content, user;
        user = message.get('user_id') !== App.I.get('id') ? App.Collections.Users.findWhere({
          id: message.get('user_id')
        }) : App.Collections.Users.findWhere({
          id: message.get('destination_id')
        });
        content = App.S.bare_text(user.get('shared'), message.get('hidden_content'));
        console.log(content);
        return message.set({
          content: content
        });
      });
      return App.Router.show("home");
    });
  };

  return log;

})(Backbone.View);

var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

App.Views.messageList = (function(_super) {
  __extends(messageList, _super);

  function messageList() {
    this.render = __bind(this.render, this);
    this.process_collection = __bind(this.process_collection, this);
    return messageList.__super__.constructor.apply(this, arguments);
  }

  messageList.prototype.process_collection = function() {
    var destination, message, messages, user, _i, _len;
    messages = this.collection.sort().toJSON();
    for (_i = 0, _len = messages.length; _i < _len; _i++) {
      message = messages[_i];
      user = App.Collections.Users.findWhere({
        id: message.user_id
      });
      destination = message.destination_type === "user" ? App.Collections.Users.findWhere({
        id: message.destination_id
      }) : App.Collections.Pages.findWhere({
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

var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

App.Views.pageLinkList = (function(_super) {
  __extends(pageLinkList, _super);

  function pageLinkList() {
    this["delete"] = __bind(this["delete"], this);
    this.create = __bind(this.create, this);
    this.render = __bind(this.render, this);
    this.page_users = __bind(this.page_users, this);
    this.initialize = __bind(this.initialize, this);
    return pageLinkList.__super__.constructor.apply(this, arguments);
  }

  pageLinkList.prototype.initialize = function() {
    this.listenTo(App.Collections.PageLinks, 'add', this.render);
    return this.listenTo(App.Collections.PageLinks, 'remove', this.render);
  };

  pageLinkList.prototype.page_users = function() {
    var users;
    users = [];
    App.Collections.Users.each((function(_this) {
      return function(user) {
        var link, tmp;
        tmp = user.pick('id', 'pseudo');
        if (_this.model.get('user_id') === user.get('id')) {
          tmp.creator = true;
        }
        link = App.Collections.PageLinks.findWhere({
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
    App.Collections.PageLinks.create({
      page_id: this.model.get('id'),
      user_id: $(e.target).data('id')
    });
    return false;
  };

  pageLinkList.prototype["delete"] = function(e) {
    App.Collections.PageLinks.findWhere({
      page_id: this.model.get('id'),
      user_id: $(e.target).data('id')
    }).destroy();
    return false;
  };

  return pageLinkList;

})(Backbone.View);

var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

App.Views.pageList = (function(_super) {
  __extends(pageList, _super);

  function pageList() {
    this.new_page = __bind(this.new_page, this);
    this.create_page = __bind(this.create_page, this);
    this.render = __bind(this.render, this);
    this.processed_pages = __bind(this.processed_pages, this);
    return pageList.__super__.constructor.apply(this, arguments);
  }

  pageList.prototype.processed_pages = function() {
    var pages;
    pages = [];
    App.Collections.Pages.each(function(page) {
      var tmp, user;
      tmp = _.clone(page.attributes);
      user = App.Collections.Users.findWhere({
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
          App.Collections.Pages.add(page);
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

var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

App.Views.pageTalk = (function(_super) {
  __extends(pageTalk, _super);

  function pageTalk() {
    this.go_home = __bind(this.go_home, this);
    this.talk = __bind(this.talk, this);
    this.render = __bind(this.render, this);
    this.page_users = __bind(this.page_users, this);
    this.selected_messages = __bind(this.selected_messages, this);
    return pageTalk.__super__.constructor.apply(this, arguments);
  }

  pageTalk.prototype.selected_messages = function() {
    var messages;
    messages = new App.Collections.messages();
    messages.push(App.Collections.Messages.where({
      destination_type: 'page',
      destination_id: this.model.get('id')
    }));
    return messages;
  };

  pageTalk.prototype.page_users = function() {
    var links, user, users, _i, _len;
    users = App.Collections.Users.toJSON();
    for (_i = 0, _len = users.length; _i < _len; _i++) {
      user = users[_i];
      links = App.Collections.pageLinks.where({
        page_id: this.model.get('id'),
        user_id: user.id
      });
      if (links) {
        user.auth = true;
      }
    }
    return users;
  };

  pageTalk.prototype.render = function() {
    var template;
    template = Handlebars.compile($("#pageTalkTemplate").html());
    this.$el.html(template({
      page: this.model.attributes
    }));
    $("textarea").autosize();
    App.Views.MessageList = new App.Views.messageList({
      el: $("#messageList"),
      collection: this.selected_messages()
    });
    App.Views.MessageList.render();
    App.Views.PageLinkList = new App.Views.pageLinkList({
      el: $("#pageLinkList"),
      model: this.model
    });
    return App.Views.PageLinkList.render();
  };

  pageTalk.prototype.events = {
    'click #send_message': 'talk',
    'click #back_button': 'go_home'
  };

  pageTalk.prototype.talk = function() {
    var hidden_content, message;
    hidden_content = $("#message_input").val();
    message = new App.Models.Message({
      destination_type: "page",
      destination_id: this.model.get('id'),
      hidden_content: hidden_content
    });
    message.on('error', (function(_this) {
      return function() {
        return alert("Sending error");
      };
    })(this));
    message.on('sync', (function(_this) {
      return function() {
        console.log("sync");
        console.log(message);
        App.Collections.Messages.add(message);
        App.Views.MessageList.collection.push(message);
        App.Views.MessageList.render();
        return $("#message_input").val("");
      };
    })(this));
    return message.save();
  };

  pageTalk.prototype.go_home = function() {
    return App.Router.show("home");
  };

  return pageTalk;

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
    template = Handlebars.compile($("#userListTemplate").html());
    this.$el.html(template({
      users: App.Collections.Users.toJSON()
    }));
    return this;
  };

  userList.prototype.events = {
    'keypress #search_user_input': 'search_user'
  };

  userList.prototype.search_user = function(e) {
    var pseudo, user;
    if (e.which === 13) {
      pseudo = $("#search_user_input").val();
      user = new App.Models.User({
        pseudo: pseudo
      });
      user.fetch();
      user.on('error', (function(_this) {
        return function() {
          return alert("Not found...");
        };
      })(this));
      return user.on('sync', (function(_this) {
        return function() {
          $("#search_user_input").val("");
          user.shared();
          App.Collections.Users.add(user);
          return _this.render();
        };
      })(this));
    }
  };

  return userList;

})(Backbone.View);

var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

App.Views.userTalk = (function(_super) {
  __extends(userTalk, _super);

  function userTalk() {
    this.go_home = __bind(this.go_home, this);
    this.talk = __bind(this.talk, this);
    this.render = __bind(this.render, this);
    this.selected_messages = __bind(this.selected_messages, this);
    return userTalk.__super__.constructor.apply(this, arguments);
  }

  userTalk.prototype.selected_messages = function() {
    var messages;
    messages = new App.Collections.messages();
    messages.push(App.Collections.Messages.where({
      destination_type: 'user',
      user_id: App.I.get('id'),
      destination_id: this.model.get('id')
    }));
    messages.push(App.Collections.Messages.where({
      destination_type: 'user',
      user_id: this.model.get('id'),
      destination_id: App.I.get('id')
    }));
    return messages;
  };

  userTalk.prototype.render = function() {
    var template;
    template = Handlebars.compile($("#userTalkTemplate").html());
    this.$el.html(template({
      user: this.model.attributes
    }));
    $("textarea").autosize();
    App.Views.MessageList = new App.Views.messageList({
      el: $("#messageList"),
      collection: this.selected_messages()
    });
    return App.Views.MessageList.render();
  };

  userTalk.prototype.events = {
    'click #send_message': 'talk',
    'click #back_button': 'go_home'
  };

  userTalk.prototype.talk = function() {
    var content, hidden_content, message;
    content = $("#message_input").val();
    hidden_content = App.S.hide_text(this.model.get('shared'), content);
    message = new App.Models.Message({
      destination_type: "user",
      destination_id: this.model.get('id'),
      hidden_content: hidden_content,
      content: content
    });
    message.on('error', (function(_this) {
      return function() {
        return alert("Sending error");
      };
    })(this));
    message.on('sync', (function(_this) {
      return function() {
        App.Collections.Messages.add(message);
        App.Views.MessageList.collection.push(message);
        App.Views.MessageList.render();
        return $("#message_input").val("");
      };
    })(this));
    return message.save();
  };

  userTalk.prototype.go_home = function() {
    return App.Router.show("home");
  };

  return userTalk;

})(Backbone.View);

var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

App.Models.Message = (function(_super) {
  __extends(Message, _super);

  function Message() {
    return Message.__super__.constructor.apply(this, arguments);
  }

  Message.prototype.urlRoot = "/message";

  return Message;

})(Backbone.Model);

var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

App.Models.Page = (function(_super) {
  __extends(Page, _super);

  function Page() {
    return Page.__super__.constructor.apply(this, arguments);
  }

  Page.prototype.urlRoot = "/page";

  Page.prototype.toJSON = function() {
    return this.pick("name", "hidden_key");
  };

  return Page;

})(Backbone.Model);

var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

App.Models.PageLink = (function(_super) {
  __extends(PageLink, _super);

  function PageLink() {
    return PageLink.__super__.constructor.apply(this, arguments);
  }

  PageLink.prototype.urlRoot = "/pageLink";

  return PageLink;

})(Backbone.Model);

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

  User.prototype.shared = function() {
    var point;
    point = App.S.curve.fromBits(from_b64(this.get('pubkey'))).mult(App.I.get('seckey'));
    this.set({
      shared: sjcl.hash.sha256.hash(point.toBits())
    });
    console.log(this.get('pseudo') + " - " + to_b64(this.get('shared')));
    return this;
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

var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

App.Collections.messages = (function(_super) {
  __extends(messages, _super);

  function messages() {
    this.comparator = __bind(this.comparator, this);
    return messages.__super__.constructor.apply(this, arguments);
  }

  messages.prototype.model = App.Models.Message;

  messages.prototype.url = '/messages';

  messages.prototype.comparator = function(a, b) {
    return (new Date(a.get('createdAt'))) < (new Date(b.get('createdAt')));
  };

  return messages;

})(Backbone.Collection);

App.Collections.Messages = new App.Collections.messages();

var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

App.Collections.pageLinks = (function(_super) {
  __extends(pageLinks, _super);

  function pageLinks() {
    return pageLinks.__super__.constructor.apply(this, arguments);
  }

  pageLinks.prototype.model = App.Models.PageLink;

  pageLinks.prototype.url = '/pageLinks';

  return pageLinks;

})(Backbone.Collection);

App.Collections.PageLinks = new App.Collections.pageLinks();

var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

App.Collections.pages = (function(_super) {
  __extends(pages, _super);

  function pages() {
    return pages.__super__.constructor.apply(this, arguments);
  }

  pages.prototype.model = App.Models.Page;

  pages.prototype.url = '/pages';

  return pages;

})(Backbone.Collection);

App.Collections.Pages = new App.Collections.pages();

var __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

App.Collections.users = (function(_super) {
  __extends(users, _super);

  function users() {
    return users.__super__.constructor.apply(this, arguments);
  }

  users.prototype.model = App.Models.User;

  users.prototype.url = '/users';

  return users;

})(Backbone.Collection);

App.Collections.Users = new App.Collections.users();

var Router,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Router = (function(_super) {
  __extends(Router, _super);

  function Router() {
    this.pageTalk = __bind(this.pageTalk, this);
    this.userTalk = __bind(this.userTalk, this);
    this.home = __bind(this.home, this);
    this.index = __bind(this.index, this);
    this.show = __bind(this.show, this);
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

  Router.prototype.fetched = false;

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
    if (App.Content) {
      App.Content.undelegateEvents();
    }
    App.Collections.Users.add(App.I);
    App.Content = new App.Views.home({
      el: $("#content")
    });
    return App.Content.render();
  };

  Router.prototype.userTalk = function(id) {
    var model;
    if (!App.I) {
      return this.show("");
    }
    if (App.Content) {
      App.Content.undelegateEvents();
    }
    model = App.Collections.Users.findWhere({
      id: id
    });
    if (model) {
      App.Content = new App.Views.userTalk({
        el: $("#content"),
        model: model
      });
      return App.Content.render();
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
    if (App.Content) {
      App.Content.undelegateEvents();
    }
    model = App.Collections.Pages.findWhere({
      id: id
    });
    if (model) {
      App.Content = new App.Views.pageTalk({
        el: $("#content"),
        model: model
      });
      return App.Content.render();
    } else {
      console.log("page not found !");
      return this.show("home");
    }
  };

  return Router;

})(Backbone.Router);

App.Router = new Router;

$(function() {
  return Backbone.history.start();
});
