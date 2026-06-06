var api = require('../../utils/api');
var imageCache = require('../../utils/image-cache');
var constants = require('../../utils/constants');

Component({
  properties: {
    postcard: { type: Object, value: {} },
    template: { type: Object, value: {}, observer: '_onTemplateChange' },
    selected: { type: Boolean, value: false },
    selectMode: { type: Boolean, value: false },
  },

  methods: {
    _onTemplateChange: function(tpl) {
      if (!tpl || !tpl.image_url) return;
      var self = this;
      var url = tpl.display_url || api.imageUrl(tpl.image_url, 'thumb');
      imageCache.loadImage(url).then(function(localPath) {
        if (localPath) self.setData({ localImg: localPath });
      }).catch(function() {});
    },

    onTap: function() {
      this.triggerEvent('cardtap', { id: this.data.postcard.id });
    },

    onLongPress: function() {
      this.triggerEvent('cardlongpress', { id: this.data.postcard.id });
    },
  },
});
