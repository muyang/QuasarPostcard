var api = require('../../utils/api');
var renderer = require('../../utils/canvas-renderer');
var constants = require('../../utils/constants');

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
  },

  _canvas: null,
  _renderTimer: null,

  onLoad: function(options) {
    if (options.data) {
      try {
        var card = JSON.parse(decodeURIComponent(options.data));
        this.setData({
          design: {
            id: card.id || 0,
            template_id: card.template_id || '',
            to_name: card.to_name || '',
            from_name: card.from_name || '',
            message: card.message || '',
            stamp_id: card.stamp_id || '',
            postmark_id: card.postmark_id || '',
            status: card.status || 'PENDING',
          },
        });
      } catch (e) {
        console.error('Parse card data failed', e);
      }
    }
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
        : api.getTemplates().then(function(items) { app.globalData.templates = items; return items; }),
      app.globalData.stamps && app.globalData.stamps.length > 0
        ? Promise.resolve(app.globalData.stamps)
        : api.getStamps().then(function(items) { app.globalData.stamps = items; return items; }),
      app.globalData.postmarks && app.globalData.postmarks.length > 0
        ? Promise.resolve(app.globalData.postmarks)
        : api.getPostmarks().then(function(items) { app.globalData.postmarks = items; return items; }),
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

  // Save
  onSave: function() {
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
      return renderer.canvasToTempFile(self._canvas);
    }).then(function(tempPath) {
      self._shareImage = tempPath;
      self.setData({ sending: false });
      wx.showShareMenu({ withShareTicket: true });
      wx.showToast({ title: '已保存，点击右上角分享', icon: 'none', duration: 2500 });
    }).catch(function(err) {
      console.error('send error', err);
      wx.showToast({ title: '发送失败', icon: 'error' });
      self.setData({ sending: false });
    });
  },

  onGoBack: function() {
    wx.navigateBack();
  },
});
