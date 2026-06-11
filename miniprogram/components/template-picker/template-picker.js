var api = require('../../utils/api');
var imageCache = require('../../utils/image-cache');
var constants = require('../../utils/constants');

Component({
  properties: {
    templates: { type: Array, value: [], observer: '_onTemplatesChange' },
    selected: { type: String, value: '' },
    loading: { type: Boolean, value: false },
    groupOrder: { type: Array, value: [], observer: '_onGroupOrderChange' },
  },

  data: {
    groups: [],
    activeGroup: '',
    filteredTemplates: [],
  },

  methods: {
    _onTemplatesChange: function(items) {
      if (!items || !items.length) return;
      this._recomputeGroups();
      // Preload images
      var self = this;
      items.forEach(function(item, idx) {
        if (!item.image_url) return;
        var url = item.display_url || api.imageUrl(item.image_url, 'thumb');
        imageCache.loadImage(url).then(function(localPath) {
          if (localPath) {
            self.setData({ ['templates[' + idx + '].local_img']: localPath });
          }
        }).catch(function() {});
      });
    },

    _onGroupOrderChange: function() {
      if (!this.data.templates || !this.data.templates.length) return;
      this._recomputeGroups();
    },

    _recomputeGroups: function() {
      var items = this.data.templates;
      if (!items || !items.length) return;
      var self = this;
      // Compute unique groups
      var groupSet = {};
      var groupList = [];
      items.forEach(function(item) {
        var g = item.template_group || '默认';
        if (!groupSet[g]) {
          groupSet[g] = true;
          groupList.push(g);
        }
      });
      // Sort groups by configured order
      var order = self.data.groupOrder || [];
      if (order && order.length > 0) {
        groupList.sort(function(a, b) {
          var ai = order.indexOf(a);
          var bi = order.indexOf(b);
          var aIdx = ai >= 0 ? ai : 9999;
          var bIdx = bi >= 0 ? bi : 9999;
          return aIdx - bIdx;
        });
      }
      self.setData({ groups: groupList });
      // Auto-select group containing the currently selected template
      var activeGroup = self.data.activeGroup;
      if (self.data.selected) {
        for (var i = 0; i < items.length; i++) {
          if (items[i].id === self.data.selected) {
            activeGroup = items[i].template_group || '默认';
            break;
          }
        }
      }
      if (!activeGroup || groupList.indexOf(activeGroup) === -1) {
        activeGroup = groupList[0] || '';
      }
      self.setData({ activeGroup: activeGroup });
      self._filterTemplates();
    },

    _filterTemplates: function() {
      var activeGroup = this.data.activeGroup;
      var templates = this.data.templates || [];
      var filtered;
      if (activeGroup === '全部') {
        filtered = templates;
      } else {
        filtered = templates.filter(function(t) {
          return (t.template_group || '默认') === activeGroup;
        });
      }
      this.setData({ filteredTemplates: filtered });
    },

    onGroupTap: function(e) {
      var group = e.currentTarget.dataset.group;
      this.setData({ activeGroup: group });
      this._filterTemplates();
    },

    onSelect: function(e) {
      var id = e.currentTarget.dataset.id;
      this.triggerEvent('select', { id: id });
    },
  },
});