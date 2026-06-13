var api = require('./utils/api');
var auth = require('./utils/auth');
var imageCache = require('./utils/image-cache');

App({
  globalData: {
    token: '',
    nickname: '',
    avatarUrl: '',
    userId: null,
    templates: [],
    stamps: [],
    postmarks: [],
    serverUrl: 'https://card.qpvisiontech.com',
    //serverUrl: 'http://localhost:8100',
    loggedIn: false,
    loginPromise: null,
    statusBarHeight: 0,
    capsuleRight: 0,
    capsuleLeft: 0,
    capsuleTop: 0,
    capsuleHeight: 0,
    screenWidth: 375,
  },

  onLaunch: function() {
    var sysInfo = wx.getSystemInfoSync();
    this.globalData.statusBarHeight = sysInfo.statusBarHeight || 20;
    this.globalData.screenWidth = sysInfo.windowWidth || 375;
    try {
      var capsule = wx.getMenuButtonBoundingClientRect();
      this.globalData.capsuleRight = capsule.right;
      this.globalData.capsuleLeft = capsule.left;
      this.globalData.capsuleTop = capsule.top;
      this.globalData.capsuleHeight = capsule.height;
    } catch (e) {}
    this._sessionPromise = this._restoreSession();
  },

  _restoreSession: function() {
    var token = wx.getStorageSync('token');
    if (!token) return Promise.resolve(false);
    api.setToken(token);
    var self = this;
    return api.getMe().then(function(me) {
      if (me && me.authenticated) {
        self.globalData.token = token;
        self.globalData.nickname = me.nickname || '';
        self.globalData.avatarUrl = me.avatar_url || '';
        self.globalData.loggedIn = true;
        self._preloadMaterials();
        return true;
      } else {
        self._clearSession();
        return false;
      }
    }).catch(function() {
      self._clearSession();
      return false;
    });
  },

  checkSession: function() {
    return this._sessionPromise || Promise.resolve(false);
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
      self._preloadImages();
    }).catch(function() {});
  },

  _preloadImages: function() {
    var all = [].concat(
      this.globalData.templates,
      this.globalData.stamps,
      this.globalData.postmarks
    );
    all.forEach(function(item) {
      if (item && item.display_url) {
        imageCache.loadImage(item.display_url).catch(function() {});
      }
    });
  },
});
