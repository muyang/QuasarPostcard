var api = require('../../utils/api');
var renderer = require('../../utils/canvas-renderer');
var constants = require('../../utils/constants');
var imageCache = require('../../utils/image-cache');


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
    groupOrder: [],
    loading: true,
    saving: false,
    sending: false,
    canvasW: constants.CANVAS_W,
    canvasH: constants.CANVAS_H,
    statusBarHeight: 20,
    navRight: 16,
    navHeight: 44,
    textEditorVisible: false,
    textEditField: '',
    textEditValue: '',
    textEditFont: 'sans-serif',
    textEditSize: 14,
    textEditColor: '#333333',
    showTextHint: true,
    fontOptions: ['sans-serif', 'serif', 'monospace', 'cursive'],
    sizeOptions: [
      { value: 12, label: '小' },
      { value: 14, label: '中' },
      { value: 16, label: '大' },
      { value: 20, label: '特大' },
    ],
    colorOptions: ['#333333', '#000000', '#FF5252', '#FF9800', '#4CAF50', '#2196F3', '#9C27B0', '#795548'],
  },

  _canvas: null,
  _renderTimer: null,

  onLoad: function(options) {
    var self = this;
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
    // Hide text hint after 3 seconds
    setTimeout(function() {
      self.setData({ showTextHint: false });
    }, 3000);
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

  // Apply default material from config, or fall back to first item.
  _applyDefault: function(items, defaultId, designField, isNew, design) {
    if (isNew && defaultId) {
      var has = items.some(function(item) { return item.id === defaultId; });
      if (has) { design[designField] = defaultId; return; }
    }
    if (!design[designField] && items.length > 0) {
      design[designField] = items[0].id;
    }
  },

  // Fetch cached or fresh materials, resolving display URLs.
  _fetchMaterials: function(typeKey, fetchFn, app) {
    var cached = app.globalData[typeKey];
    if (cached && cached.length > 0) return Promise.resolve(cached);
    return fetchFn().then(function(items) {
      var r = api.resolveUrls(items);
      app.globalData[typeKey] = r;
      return r;
    });
  },

  loadMaterials: function() {
    var self = this;
    var app = getApp();

    Promise.all([
      self._fetchMaterials('templates', api.getTemplates, app),
      self._fetchMaterials('stamps', api.getStamps, app),
      self._fetchMaterials('postmarks', api.getPostmarks, app),
      api.getConfig(),
    ]).then(function(results) {
      var templates = results[0];
      var stamps = results[1];
      var postmarks = results[2];
      var config = results[3] || {};
      var groupOrder = config.group_order || [];
      var design = self.data.design;
      var isNew = !design.id || design.id === 0;

      self._applyDefault(templates, config.default_template, 'template_id', isNew, design);
      self._applyDefault(stamps, config.default_stamp, 'stamp_id', isNew, design);
      self._applyDefault(postmarks, config.default_postmark, 'postmark_id', isNew, design);

      self.setData({
        templates: templates,
        stamps: stamps,
        postmarks: postmarks,
        groupOrder: groupOrder,
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
      toColor: design.to_name_color,
      toFont: design.to_name_font,
      toSize: design.to_name_size,
      fromColor: design.from_name_color,
      fromFont: design.from_name_font,
      fromSize: design.from_name_size,
      messageColor: design.message_color,
      messageFont: design.message_font,
      messageSize: design.message_size,
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
    var step = e.detail.step;
    this.setData({ step: step });
    if (step === 4) this._triggerSend();
  },

  onPrevStep: function() {
    if (this.data.step > 0) {
      this.setData({ step: this.data.step - 1 });
    }
  },

  onNextStep: function() {
    if (this.data.step < 4) {
      var next = this.data.step + 1;
      this.setData({ step: next });
      if (next === 4) this._triggerSend();
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
        title: '登录',
        content: '保存和发送明信片需要登录认证',
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
  _sendTriggered: false,

  _triggerSend: function() {
    var self = this;
    if (self._sendTriggered || self.data.sending) return;
    self._sendTriggered = true;
    self._ensureLogin().then(function() {
      return self._doSend();
    }).catch(function() {
      self._sendTriggered = false;
    });
  },

  onSend: function() {
    this._triggerSend();
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
        success: function() {
          setTimeout(function() {
            wx.reLaunch({ url: '/pages/index/index' });
          }, 300);
        },
        fail: function() {
          wx.showToast({ title: '已取消', icon: 'none' });
          setTimeout(function() {
            wx.reLaunch({ url: '/pages/index/index' });
          }, 300);
        },
      });
    }).catch(function(err) {
      console.error('send error', err);
      wx.showToast({ title: '发送失败', icon: 'error' });
      self.setData({ sending: false });
    });
  },

  // ===== Text editing via canvas touch =====
  onCanvasTouch: function(e) {
    var touch = e.touches && e.touches[0];
    if (!touch) return;
    var self = this;
    var design = self.data.design;
    var template = null;
    for (var i = 0; i < self.data.templates.length; i++) {
      if (self.data.templates[i].id === design.template_id) {
        template = self.data.templates[i];
        break;
      }
    }
    if (!template) return;

    var canvasW = self.data.canvasW;
    var canvasH = self.data.canvasH;
    var touchX = touch.x;
    var touchY = touch.y;

    var fields = constants.getFieldBounds(template, canvasW, canvasH);

    var clickedField = null;
    for (var j = 0; j < fields.length; j++) {
      var f = fields[j];
      var halfW = f.w / 2;
      var halfH = f.h / 2;
      if (touchX >= f.x - halfW && touchX <= f.x + halfW &&
          touchY >= f.y - halfH && touchY <= f.y + halfH) {
        clickedField = f;
        break;
      }
    }

    if (clickedField) {
      self.showTextEditor(clickedField.key, clickedField.name);
    }
  },

  showTextEditor: function(field, label) {
    var design = this.data.design;
    var value = design[field] || '';
    this.setData({
      textEditorVisible: true,
      textEditField: field,
      textEditValue: value,
      textEditFont: design[field + '_font'] || 'sans-serif',
      textEditSize: design[field + '_size'] || 14,
      textEditColor: design[field + '_color'] || '#333333',
    });
  },

  onTextEditInput: function(e) {
    this.setData({ textEditValue: e.detail.value });
  },

  onFontSelect: function(e) {
    this.setData({ textEditFont: e.currentTarget.dataset.font });
  },

  onSizeSelect: function(e) {
    this.setData({ textEditSize: parseInt(e.currentTarget.dataset.size, 10) });
  },

  onColorSelect: function(e) {
    this.setData({ textEditColor: e.currentTarget.dataset.color });
  },

  onTextEditConfirm: function() {
    var field = this.data.textEditField;
    var update = {};
    update['design.' + field] = this.data.textEditValue;
    update['design.' + field + '_font'] = this.data.textEditFont;
    update['design.' + field + '_size'] = this.data.textEditSize;
    update['design.' + field + '_color'] = this.data.textEditColor;
    update.textEditorVisible = false;
    this.setData(update);
    this.renderCanvas();
  },

  onTextEditCancel: function() {
    this.setData({ textEditorVisible: false });
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
