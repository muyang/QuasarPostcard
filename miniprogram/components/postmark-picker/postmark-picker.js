var api = require('../../utils/api');

Component({
  properties: {
    postmarks: { type: Array, value: [] },
    selected: { type: String, value: '' },
    loading: { type: Boolean, value: false },
  },
  methods: {
    onSelect: function(e) {
      var id = e.currentTarget.dataset.id;
      this.triggerEvent('select', { id: id });
    },
  },
});
