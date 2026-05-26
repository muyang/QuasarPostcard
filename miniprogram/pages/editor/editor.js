var api = require('../../utils/api');
var renderer = require('../../utils/canvas-renderer');
var constants = require('../../utils/constants');
var imageCache = require('../../utils/image-cache');

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
    step: 0,
    design: {
      id: 0,
      template_id: '',
      to_name: '',
      from_name: '',
      message: '',
      stamp_id: '',
      postmark_id: '',
      status: 'PENDING',
    },
    templates: [],
    stamps: [],
    postmarks: [],
    loading: true,
    saving: false,
    sending: false,
    canvasW: constants.CANVAS_W,
    canvasH: constants.CANVAS_H,
    statusBarHeight: 20,
    navRight: 16,
    navHeight: 44,
  },

  _canvas: null,
  _renderTimer: null,

  onLoad: function(options) {
    // Calculate canvas display size to fit screen while maintaining 14:9 ratio
    var sysInfo = wx.getSystemInfoSync();
    var screenW = sysInfo.windowWidth;
    var displayW = Math.min(screenW - 32, constants.CANVAS_W);
    var displayH = Math.round(displayW / constants.ASPECT_RATIO);

    var g = getApp().globalData;
    var initData = {
      canvasW: displayW,
      canvasH: displayH,
      statusBarHeight: g.statusBarHeight,
      navRight: g.screenWidth - g.capsuleLeft + 12,
      navHeight: g.capsuleTop - g.statusBarHeight + g.capsuleHeight + 12,
    };

    if (options.data) {
      try {
        var card = JSON.parse(decodeURIComponent(options.data));
        initData.design = {
          id: card.id || 0,
          template_id: card.template_id || '',
          to_name: card.to_name || '',
          from_name: card.from_name || '',
          message: card.message || '',
          stamp_id: card.stamp_id || '',
          postmark_id: card.postmark_id || '',
          status: card.status || 'PENDING',
        };
      } catch (e) {
        console.error('Parse card data failed', e);
      }
    }
    // Auto-fill sender name with WeChat nickname when logged in
    var app = getApp();
    var design = initData.design || {};
    if (app.isLoggedIn() && !design.from_name) {
      design.from_name = app.globalData.nickname || '';
      initData.design = design;
    }
    this.setData(initData);
    this.loadMaterials();
  },

  onReady: function() {
    var self = this;
    var query = wx.createSelectorQuery();
    query.select('#postcard-canvas')
      .fields({ node: true, size: true })
      .exec(function(res) {
        if (res && res[0] && res[0].node) {
          self._canvas = res[0].node;
          self.renderCanvas();
        }
      });
  },

  onShareAppMessage: function() {
    return {
      title: '一张明信片送给你',
      imageUrl: this._shareImage || '',
    };
  },

  loadMaterials: function() {
    var self = this;
    var app = getApp();

    Promise.all([
      app.globalData.templates && app.globalData.templates.length > 0
        ? Promise.resolve(app.globalData.templates)
        : api.getTemplates().then(function(items) { var r = resolveUrls(items); app.globalData.templates = r; return r; }),
      app.globalData.stamps && app.globalData.stamps.length > 0
        ? Promise.resolve(app.globalData.stamps)
        : api.getStamps().then(function(items) { var r = resolveUrls(items); app.globalData.stamps = r; return r; }),
      app.globalData.postmarks && app.globalData.postmarks.length > 0
        ? Promise.resolve(app.globalData.postmarks)
        : api.getPostmarks().then(function(items) { var r = resolveUrls(items); app.globalData.postmarks = r; return r; }),
    ]).then(function(results) {
      var templates = results[0];
      var stamps = results[1];
      var postmarks = results[2];
      var design = self.data.design;
      if (!design.template_id && templates.length > 0) {
        design.template_id = templates[0].id;
      }
      self.setData({
        templates: templates,
        stamps: stamps,
        postmarks: postmarks,
        design: design,
        loading: false,
      });
      [].concat(templates, stamps, postmarks).forEach(function(item) {
        if (item && item.display_url) {
          imageCache.loadImage(item.display_url).catch(function() {});
        }
      });
      self.renderCanvas();
    }).catch(function(err) {
      console.error('loadMaterials error', err);
      self.setData({ loading: false });
    });
  },

  getDesignForRender: function() {
    var design = this.data.design;
    var template = null;
    var stamp = null;
    var postmark = null;

    for (var i = 0; i < this.data.templates.length; i++) {
      if (this.data.templates[i].id === design.template_id) {
        template = this.data.templates[i];
        break;
      }
    }
    if (design.stamp_id) {
      for (var j = 0; j < this.data.stamps.length; j++) {
        if (this.data.stamps[j].id === design.stamp_id) {
          stamp = this.data.stamps[j];
          break;
        }
      }
    }
    if (design.postmark_id) {
      for (var k = 0; k < this.data.postmarks.length; k++) {
        if (this.data.postmarks[k].id === design.postmark_id) {
          postmark = this.data.postmarks[k];
          break;
        }
      }
    }

    return {
      template: template || {},
      stamp: stamp,
      postmark: postmark,
      toName: design.to_name,
      fromName: design.from_name,
      message: design.message,
    };
  },

  renderCanvas: function() {
    if (!this._canvas) return;
    var self = this;
    if (self._renderTimer) clearTimeout(self._renderTimer);
    self._renderTimer = setTimeout(function() {
      var designData = self.getDesignForRender();
      renderer.drawPostcard(self._canvas, designData).catch(function(err) {
        console.error('renderCanvas error', err);
      });
    }, 50);
  },

  // Step navigation
  onStepChange: function(e) {
    this.setData({ step: e.detail.step });
  },

  onPrevStep: function() {
    if (this.data.step > 0) {
      this.setData({ step: this.data.step - 1 });
    }
  },

  onNextStep: function() {
    if (this.data.step < 3) {
      this.setData({ step: this.data.step + 1 });
    }
  },

  // Template selection
  onTemplateSelect: function(e) {
    var design = this.data.design;
    design.template_id = e.detail.id;
    this.setData({ design: design });
    this.renderCanvas();
  },

  // Stamp selection
  onStampSelect: function(e) {
    var design = this.data.design;
    design.stamp_id = e.detail.id;
    this.setData({ design: design });
    this.renderCanvas();
  },

  // Postmark selection
  onPostmarkSelect: function(e) {
    var design = this.data.design;
    design.postmark_id = e.detail.id;
    this.setData({ design: design });
    this.renderCanvas();
  },

  // Text inputs
  onToInput: function(e) {
    var design = this.data.design;
    design.to_name = e.detail.value;
    this.setData({ design: design });
    this.renderCanvas();
  },

  onFromInput: function(e) {
    var design = this.data.design;
    design.from_name = e.detail.value;
    this.setData({ design: design });
    this.renderCanvas();
  },

  onMessageInput: function(e) {
    var design = this.data.design;
    design.message = e.detail.value;
    this.setData({ design: design });
    this.renderCanvas();
  },

  // Login gate for save/send actions
  _ensureLogin: function() {
    var app = getApp();
    if (app.isLoggedIn()) return Promise.resolve();

    return new Promise(function(resolve, reject) {
      wx.showModal({
        title: '微信登录',
        content: '保存和发送明信片需要微信登录认证',
        confirmText: '去登录',
        cancelText: '稍后',
        success: function(res) {
          if (!res.confirm) return reject(new Error('cancelled'));
          wx.showLoading({ title: '登录中...' });
          app.login().then(function() {
            wx.hideLoading();
            wx.showToast({ title: '登录成功', icon: 'success' });
            resolve();
          }).catch(function(err) {
            wx.hideLoading();
            wx.showToast({ title: '登录失败', icon: 'error' });
            reject(err);
          });
        },
        fail: reject,
      });
    });
  },

  // Save to phone album
  onSaveToAlbum: function() {
    var self = this;
    if (self.data.saving) return;
    self.setData({ saving: true });

    renderer.exportHiRes(self.getDesignForRender()).then(function(tempPath) {
      return new Promise(function(resolve, reject) {
        wx.saveImageToPhotosAlbum({
          filePath: tempPath,
          success: function() { resolve(); },
          fail: function(err) {
            if (err.errMsg && err.errMsg.indexOf('auth deny') !== -1) {
              wx.showModal({
                title: '需要相册权限',
                content: '请在设置中允许访问相册',
                confirmText: '去设置',
                success: function(res) {
                  if (res.confirm) wx.openSetting();
                },
              });
            }
            reject(err);
          },
        });
      });
    }).then(function() {
      wx.showToast({ title: '已保存到相册', icon: 'success' });
      self.setData({ saving: false });
    }).catch(function(err) {
      console.error('saveToAlbum error', err);
      if (!(err.errMsg && err.errMsg.indexOf('auth deny') !== -1)) {
        wx.showToast({ title: '保存失败', icon: 'error' });
      }
      self.setData({ saving: false });
    });
  },

  // Save to server
  onSave: function() {
    var self = this;
    self._ensureLogin().then(function() {
      return self._doSave();
    }).catch(function() {});
  },

  _doSave: function() {
    var self = this;
    var design = self.data.design;
    self.setData({ saving: true });

    var body = {
      template_id: design.template_id,
      to_name: design.to_name,
      from_name: design.from_name,
      message: design.message,
      stamp_id: design.stamp_id,
      postmark_id: design.postmark_id,
      status: design.status,
    };

    var promise = design.id
      ? api.updatePostcard(design.id, body)
      : api.createPostcard(body);

    promise.then(function(res) {
      if (res && res.id) {
        design.id = res.id;
        self.setData({ design: design });
      }
      wx.showToast({ title: '保存成功', icon: 'success' });
      self.setData({ saving: false });
    }).catch(function(err) {
      console.error('save error', err);
      wx.showToast({ title: '保存失败', icon: 'error' });
      self.setData({ saving: false });
    });
  },

  // Send (save + share)
  onSend: function() {
    var self = this;
    if (self.data.sending) return;
    self._ensureLogin().then(function() {
      return self._doSend();
    }).catch(function() {});
  },

  _doSend: function() {
    var self = this;
    if (self.data.sending) return;
    self.setData({ sending: true });

    var design = self.data.design;
    var body = {
      template_id: design.template_id,
      to_name: design.to_name,
      from_name: design.from_name,
      message: design.message,
      stamp_id: design.stamp_id,
      postmark_id: design.postmark_id,
      status: 'SENT',
    };

    var savePromise = design.id
      ? api.updatePostcard(design.id, body)
      : api.createPostcard(body);

    savePromise.then(function(res) {
      if (res && res.id) {
        design.id = res.id;
        design.status = 'SENT';
        self.setData({ design: design });
      }
      return renderer.exportHiRes(self.getDesignForRender());
    }).then(function(tempPath) {
      self.setData({ sending: false });
      wx.showShareImageMenu({
        path: tempPath,
        fail: function() {
          wx.showToast({ title: '分享取消', icon: 'none' });
        },
      });
    }).catch(function(err) {
      console.error('send error', err);
      wx.showToast({ title: '发送失败', icon: 'error' });
      self.setData({ sending: false });
    });
  },

  onGoBack: function() {
    var pages = getCurrentPages();
    if (pages.length > 1) {
      wx.navigateBack();
    } else {
      wx.reLaunch({ url: '/pages/index/index' });
    }
  },
});
