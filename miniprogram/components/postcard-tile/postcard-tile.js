var constants = require('../../utils/constants');

Component({
  properties: {
    postcard: { type: Object, value: {} },
    template: { type: Object, value: {} },
    selected: { type: Boolean, value: false },
    selectMode: { type: Boolean, value: false },
  },
  methods: {
    onTap: function() {
      this.triggerEvent('cardtap', { id: this.data.postcard.id });
    },
    onLongPress: function() {
      this.triggerEvent('cardlongpress', { id: this.data.postcard.id });
    },
  },
});
