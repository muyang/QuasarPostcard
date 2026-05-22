Component({
  properties: {
    current: { type: Number, value: 0 },
  },
  data: {
    steps: [
      { icon: 'palette', label: '模版' },
      { icon: 'text', label: '文字' },
      { icon: 'stamp', label: '邮票' },
      { icon: 'postmark', label: '邮戳' },
    ],
  },
  methods: {
    onTap: function(e) {
      var idx = e.currentTarget.dataset.index;
      this.triggerEvent('stepchange', { step: idx });
    },
  },
});
