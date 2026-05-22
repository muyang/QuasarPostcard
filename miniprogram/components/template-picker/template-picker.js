var api = require('../../utils/api');
var constants = require('../../utils/constants');

Component({
  properties: {
    templates: { type: Array, value: [] },
    selected: { type: String, value: '' },
    loading: { type: Boolean, value: false },
  },
  methods: {
    onSelect: function(e) {
      var id = e.currentTarget.dataset.id;
      this.triggerEvent('select', { id: id });
    },
    getGradient: function(tpl) {
      var colors = constants.getGradientColors(tpl);
      return 'linear-gradient(135deg, ' + colors.join(', ') + ')';
    },
    imageUrl: function(path) {
      return api.imageUrl(path, 'thumb');
    },
  },
});
