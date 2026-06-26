// Canvas dimensions (logical pixels, will be scaled by dpr)
const CANVAS_W = 420;
const CANVAS_H = 270;
const ASPECT_RATIO = CANVAS_W / CANVAS_H; // 14:9

// Export scale factor — renders at 6x logical size for sharp output on high-DPI phones
const EXPORT_SCALE = 6;
const EXPORT_W = CANVAS_W * EXPORT_SCALE; // 2520
const EXPORT_H = CANVAS_H * EXPORT_SCALE; // 1620

// Device pixel ratio
function getDpr() {
  return wx.getSystemInfoSync().pixelRatio || 2;
}

// Parse hex color (ARGB or RGB) to CSS rgba string
function parseColor(hex, fallback) {
  fallback = fallback || '333333';
  const h = (hex || fallback).replace('#', '').replace('0x', '');
  if (h.length === 8) {
    const a = parseInt(h.slice(0, 2), 16) / 255;
    const r = parseInt(h.slice(2, 4), 16);
    const g = parseInt(h.slice(4, 6), 16);
    const b = parseInt(h.slice(6, 8), 16);
    return 'rgba(' + r + ',' + g + ',' + b + ',' + a + ')';
  }
  if (h.length === 6) {
    const r = parseInt(h.slice(0, 2), 16);
    const g = parseInt(h.slice(2, 4), 16);
    const b = parseInt(h.slice(4, 6), 16);
    return 'rgb(' + r + ',' + g + ',' + b + ')';
  }
  return fallback;
}

// Get gradient colors array from template
function getGradientColors(tpl) {
  const colors = [];
  if (tpl.gradient_from) colors.push(parseColor(tpl.gradient_from));
  if (tpl.gradient_mid) colors.push(parseColor(tpl.gradient_mid));
  if (tpl.gradient_to) colors.push(parseColor(tpl.gradient_to));
  if (colors.length < 2) {
    colors.push(parseColor('FFF0F5'));
    colors.push(parseColor('FFC0CB'));
  }
  return colors;
}


// Compute touchable bounds for text fields on the canvas.
// Returns array of {key, name, x, y, w, h} in canvas pixels.
function getFieldBounds(tpl, canvasW, canvasH) {
  var scaleX = canvasW / 375;
  var scaleY = canvasH / 243;
  var fields = [
    {
      key: 'to_name', name: '收件人',
      x: (tpl.to_x !== undefined ? tpl.to_x : 60) / 100 * canvasW,
      y: (tpl.to_y !== undefined ? tpl.to_y : 88) / 100 * canvasH,
      w: (tpl.to_w !== undefined ? tpl.to_w : 120) * scaleX,
      h: (tpl.to_h !== undefined ? tpl.to_h : 28) * scaleY,
    },
    {
      key: 'from_name', name: '寄件人',
      x: (tpl.from_x !== undefined ? tpl.from_x : 18) / 100 * canvasW,
      y: (tpl.from_y !== undefined ? tpl.from_y : 88) / 100 * canvasH,
      w: (tpl.from_w !== undefined ? tpl.from_w : 120) * scaleX,
      h: (tpl.from_h !== undefined ? tpl.from_h : 28) * scaleY,
    },
    {
      key: 'message', name: '祝福语',
      x: (tpl.message_x !== undefined ? tpl.message_x : 8) / 100 * canvasW,
      y: (tpl.message_y !== undefined ? tpl.message_y : 40) / 100 * canvasH,
      w: (tpl.message_w !== undefined ? tpl.message_w : 82) * scaleX,
      h: (tpl.message_h !== undefined ? tpl.message_h : 70) * scaleY,
    },
  ];
  return fields;
}

module.exports = {
  CANVAS_W,
  CANVAS_H,
  ASPECT_RATIO,
  EXPORT_SCALE,
  EXPORT_W,
  EXPORT_H,
  getDpr,
  parseColor,
  getGradientColors,
  getFieldBounds,
};
