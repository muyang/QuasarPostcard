var api = require('../../utils/api');
var imageCache = require('../../utils/image-cache');

Component({
  properties: {
    stamps: { type: Array, value: [], observer: '_onItemsChange' },
    selected: { type: String, value: '' },
    loading: { type: Boolean, value: false },
  },

  methods: {
    _onItemsChange: function(items) {
      if (!items || !items.length) return;
      var self = this;
      items.forEach(function(item, idx) {
        if (!item.image_url) return;
        var url = item.display_url || api.imageUrl(item.image_url, 'thumb');
        imageCache.loadImage(url).then(function(localPath) {
          if (localPath) {
            self.setData({ ['stamps[' + idx + '].local_img']: localPath });
          }
        }).catch(function() {});
      });
    },

    onSelect: function(e) {
      var id = e.currentTarget.dataset.id;
      this.triggerEvent('select', { id: id });
    },

    onRemove: function() {
      this.triggerEvent('select', { id: '' });
    },
  },
});
