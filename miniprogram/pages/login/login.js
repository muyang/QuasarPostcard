Page({
  data: {
    logging: false,
    ready: false,
    statusBarHeight: 20,
  },

  onLoad: function() {
    var app = getApp();
    var self = this;
    self.setData({ statusBarHeight: app.globalData.statusBarHeight });
    app.checkSession().then(function(loggedIn) {
      if (loggedIn) {
        wx.reLaunch({ url: '/pages/editor/editor' });
      } else {
        self.setData({ ready: true });
      }
    });
  },

  onLogin: function() {
    if (this.data.logging) return;
    var self = this;
    self.setData({ logging: true });
    getApp().login().then(function() {
      wx.reLaunch({ url: '/pages/editor/editor' });
    }).catch(function() {
      wx.showToast({ title: '登录失败，请重试', icon: 'none' });
      self.setData({ logging: false });
    });
  },

  onSkip: function() {
    wx.reLaunch({ url: '/pages/editor/editor' });
  },
});
