const api = require('./utils/api');
const auth = require('./utils/auth');

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
  },

  onLaunch() {
    this._initLogin();
  },

  async _initLogin() {
    const token = wx.getStorageSync('token');
    if (token) {
      api.setToken(token);
      try {
        const me = await api.getMe();
        if (me && me.authenticated) {
          this.globalData.token = token;
          this.globalData.nickname = me.nickname || '';
          this.globalData.avatarUrl = me.avatar_url || '';
          this._preloadMaterials();
          return;
        }
      } catch (_) {}
    }
    // No valid token, do login
    try {
      const result = await auth.wxMiniLogin();
      this.globalData.token = result.token;
      this.globalData.nickname = result.nickname || '';
      this.globalData.avatarUrl = result.avatar_url || '';
      this._preloadMaterials();
    } catch (e) {
      console.error('Login failed:', e);
    }
  },

  _resolveImageUrls(items) {
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

  async _preloadMaterials() {
    try {
      const [templates, stamps, postmarks] = await Promise.all([
        api.getTemplates(),
        api.getStamps(),
        api.getPostmarks(),
      ]);
      this.globalData.templates = this._resolveImageUrls(templates);
      this.globalData.stamps = this._resolveImageUrls(stamps);
      this.globalData.postmarks = this._resolveImageUrls(postmarks);
    } catch (_) {}
  },
});
