var api = require('../../utils/api');
var auth = require('../../utils/auth');

function resolveUrls(items) {
  if (!items || !items.length) return items;
  return items.map(function(item) {
    if (item.image_url) {
      item.display_url = item.image_url.indexOf('http') === 0
        ? item.image_url
        : api.imageUrl(item.image_url, 'thumb');
    }
    return item;
  });
}

Page({
  data: {
    postcards: [],
    templates: [],
    loading: true,
    error: '',
    selectMode: false,
    selectedIds: [],
    deleting: false,
    loggedIn: false,
    statusBarHeight: 20,
  },

  onLoad: function() {
    this.setData({ statusBarHeight: getApp().globalData.statusBarHeight });
  },

  onShow: function() {
    this.checkLoginStatus();
    this.loadData();
  },

  onPullDownRefresh: function() {
    this.loadData().then(function() {
      wx.stopPullDownRefresh();
    });
  },

  loadData: function() {
    var self = this;
    self.setData({ loading: true, error: '' });

    var app = getApp();
    var tplPromise = app.globalData.templates && app.globalData.templates.length > 0
      ? Promise.resolve(app.globalData.templates)
      : api.getTemplates().then(function(items) {
          var resolved = resolveUrls(items);
          app.globalData.templates = resolved;
          return resolved;
        });

    return tplPromise.then(function(templates) {
      self.setData({ templates: templates });
      return api.getPostcards(0, 100);
    }).then(function(res) {
      var cards = res.cards || res || [];
      self.setData({ postcards: cards, loading: false });
    }).catch(function(err) {
      console.error('loadData error', err);
      self.setData({ error: '加载失败', loading: false });
    });
  },

  getTemplate: function(templateId) {
    var templates = this.data.templates;
    for (var i = 0; i < templates.length; i++) {
      if (templates[i].id === templateId) return templates[i];
    }
    return { name: '明信片', gradient_from: 'FFF0F5', gradient_to: 'FFC0CB' };
  },

  onCreateNew: function() {
    wx.navigateTo({ url: '/pages/editor/editor' });
  },

  onCardTap: function(e) {
    var id = e.detail.id;
    if (this.data.selectMode) {
      this.toggleSelect(id);
      return;
    }
    var card = null;
    for (var i = 0; i < this.data.postcards.length; i++) {
      if (this.data.postcards[i].id === id) { card = this.data.postcards[i]; break; }
    }
    if (card) {
      wx.navigateTo({
        url: '/pages/editor/editor?id=' + id + '&data=' + encodeURIComponent(JSON.stringify(card)),
      });
    }
  },

  onCardLongPress: function(e) {
    if (!this.data.selectMode) {
      this.setData({ selectMode: true, selectedIds: [e.detail.id] });
    }
  },

  toggleSelect: function(id) {
    var ids = this.data.selectedIds.slice();
    var idx = ids.indexOf(id);
    if (idx >= 0) {
      ids.splice(idx, 1);
    } else {
      ids.push(id);
    }
    this.setData({ selectedIds: ids });
    if (ids.length === 0) {
      this.setData({ selectMode: false });
    }
  },

  onCancelSelect: function() {
    this.setData({ selectMode: false, selectedIds: [] });
  },

  onSelectAll: function() {
    var ids = this.data.postcards.map(function(c) { return c.id; });
    this.setData({ selectedIds: ids });
  },

  onDeleteSelected: function() {
    var self = this;
    var ids = this.data.selectedIds;
    if (ids.length === 0) return;

    wx.showModal({
      title: '确认删除',
      content: '确定要删除选中的 ' + ids.length + ' 张明信片吗？',
      success: function(res) {
        if (!res.confirm) return;
        self.setData({ deleting: true });
        api.batchDeletePostcards(ids).then(function() {
          wx.showToast({ title: '删除成功', icon: 'success' });
          self.setData({ selectMode: false, selectedIds: [], deleting: false });
          self.loadData();
        }).catch(function() {
          wx.showToast({ title: '删除失败', icon: 'error' });
          self.setData({ deleting: false });
        });
      },
    });
  },

  onLogout: function() {
    var self = this;
    wx.showModal({
      title: '退出登录',
      content: '确定要退出吗？',
      success: function(res) {
        if (res.confirm) {
          auth.logout();
          getApp().globalData.loggedIn = false;
          self.setData({ loggedIn: false });
        }
      },
    });
  },

  onLogin: function() {
    var self = this;
    wx.showLoading({ title: '登录中...' });
    getApp().login().then(function() {
      wx.hideLoading();
      wx.showToast({ title: '登录成功', icon: 'success' });
      self.setData({ loggedIn: true });
      self.loadData();
    }).catch(function() {
      wx.hideLoading();
      wx.showToast({ title: '登录失败', icon: 'error' });
    });
  },

  checkLoginStatus: function() {
    this.setData({ loggedIn: getApp().isLoggedIn() });
  },
});
