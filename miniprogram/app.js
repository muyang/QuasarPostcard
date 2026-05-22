var api = require('./utils/api');
var auth = require('./utils/auth');

App({
  globalData: {
    token: '',
    nickname: '',
    avatarUrl: '',
    userId: null,
    templates: [],
    stamps: [],
    postmarks: [],
    serverUrl: 'https://postcard.hn.takin.cc',
    loggedIn: false,
    loginPromise: null,
  },

  onLaunch: function() {
    this._restoreSession();
  },

  _restoreSession: function() {
    var token = wx.getStorageSync('token');
    if (!token) return;
    api.setToken(token);
    var self = this;
    api.getMe().then(function(me) {
      if (me && me.authenticated) {
        self.globalData.token = token;
        self.globalData.nickname = me.nickname || '';
        self.globalData.avatarUrl = me.avatar_url || '';
        self.globalData.loggedIn = true;
        self._preloadMaterials();
      } else {
        self._clearSession();
      }
    }).catch(function() {
      self._clearSession();
    });
  },

  _clearSession: function() {
    wx.removeStorageSync('token');
    api.setToken('');
    this.globalData.token = '';
    this.globalData.loggedIn = false;
  },

  isLoggedIn: function() {
    return this.globalData.loggedIn;
  },

  login: function() {
    var self = this;
    if (self.globalData.loginPromise) {
      return self.globalData.loginPromise;
    }
    self.globalData.loginPromise = auth.wxMiniLogin().then(function(result) {
      self.globalData.token = result.token;
      self.globalData.nickname = result.nickname || '';
      self.globalData.avatarUrl = result.avatar_url || '';
      self.globalData.loggedIn = true;
      self.globalData.loginPromise = null;
      self._preloadMaterials();
      return result;
    }).catch(function(err) {
      self.globalData.loginPromise = null;
      throw err;
    });
    return self.globalData.loginPromise;
  },

  _resolveImageUrls: function(items) {
    if (!items || !items.length) return items;
    return items.map(function(item) {
      if (item.image_url) {
        item.display_url = item.image_url.indexOf('http') === 0
          ? item.image_url
          : api.imageUrl(item.image_url, 'thumb');
      }
      return item;
    });
  },

  _preloadMaterials: function() {
    var self = this;
    Promise.all([
      api.getTemplates(),
      api.getStamps(),
      api.getPostmarks(),
    ]).then(function(results) {
      self.globalData.templates = self._resolveImageUrls(results[0]);
      self.globalData.stamps = self._resolveImageUrls(results[1]);
      self.globalData.postmarks = self._resolveImageUrls(results[2]);
    }).catch(function() {});
  },
});
