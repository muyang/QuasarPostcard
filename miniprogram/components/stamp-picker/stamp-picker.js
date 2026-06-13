var api = require('../../utils/api');
var imageCache = require('../../utils/image-cache');

Component({
  properties: {
    stamps: { type: Array, value: [], observer: '_onItemsChange' },
    selected: { type: String, value: '' },
    loading: { type: Boolean, value: false },
  },

  data: {
    groups: [],
    groupMap: {},
    groupList: [],
    activeGroup: '',
    filteredStamps: [],
  },

  lifetimes: {
    attached: function() {
      this._loadGroups();
    },
  },

  methods: {
    _loadGroups: function() {
      var self = this;
      if (!api.getStampGroups) {
        console.warn('stamp-picker: api.getStampGroups is not defined');
        self._computeGroups();
        return;
      }
      api.getStampGroups().then(function(result) {
        var groups = result;
        if (result && Array.isArray(result.items)) {
          groups = result.items;
        } else if (result && result.data && Array.isArray(result.data.items)) {
          groups = result.data.items;
        } else if (!Array.isArray(groups)) {
          groups = [];
        }
        var groupMap = {};
        groups.forEach(function(g) {
          if (g && g.id) {
            groupMap[g.id] = g.name || g.id;
          }
        });
        self.setData({ groupMap: groupMap, groupList: groups });
        self._computeGroups();
      }).catch(function(err) {
        console.warn('stamp-picker: failed to load groups', err);
        self._computeGroups();
      });
    },

    _onItemsChange: function(items) {
      if (!items || !items.length) {
        this.setData({ filteredStamps: [] });
        return;
      }
      this._computeGroups();
      // Preload images
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

    _computeGroups: function() {
      var items = this.data.stamps || [];
      var groupList = this.data.groupList || [];
      var groupMap = this.data.groupMap || {};

      // Collect unique group IDs from items, excluding empty ones
      var itemGroupSet = {};
      items.forEach(function(item) {
        var gid = (item && item.group_id) || '';
        if (gid) {
          itemGroupSet[gid] = true;
        }
      });

      // Build tab list: sort groups by sort_order, only include those with items
      var tabs = [];
      groupList.forEach(function(g) {
        if (g && g.id && itemGroupSet[g.id]) {
          tabs.push({ id: g.id, name: g.name || g.id, sort_order: g.sort_order || 0 });
        }
      });
      tabs.sort(function(a, b) { return a.sort_order - b.sort_order; });

      this.setData({ groups: tabs });

      // Auto-select group containing the currently selected stamp
      var activeGroup = this.data.activeGroup;
      if (this.data.selected) {
        for (var i = 0; i < items.length; i++) {
          if (items[i] && items[i].id === this.data.selected) {
            activeGroup = (items[i].group_id) || '';
            break;
          }
        }
      }
      // Default to first actual group
      if (!activeGroup || tabs.length > 0 && !tabs.some(function(t) { return t.id === activeGroup; })) {
        activeGroup = tabs[0] ? tabs[0].id : '';
      }
      this.setData({ activeGroup: activeGroup });
      this._filterStamps();
    },

    _filterStamps: function() {
      var activeGroup = this.data.activeGroup;
      var stamps = this.data.stamps || [];
      var filtered;
      if (!activeGroup) {
        filtered = [];
      } else {
        filtered = stamps.filter(function(s) {
          return (s && s.group_id) === activeGroup;
        });
      }
      this.setData({ filteredStamps: filtered });
    },

    onGroupTap: function(e) {
      var group = e.currentTarget.dataset.group;
      this.setData({ activeGroup: group });
      this._filterStamps();
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
