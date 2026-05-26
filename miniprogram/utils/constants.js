// Canvas dimensions (logical pixels, will be scaled by dpr)
const CANVAS_W = 420;
const CANVAS_H = 270;
const ASPECT_RATIO = CANVAS_W / CANVAS_H; // 14:9

// Export scale factor — renders at 4x logical size for sharp output
const EXPORT_SCALE = 4;
const EXPORT_W = CANVAS_W * EXPORT_SCALE; // 1680
const EXPORT_H = CANVAS_H * EXPORT_SCALE; // 1080

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
};
