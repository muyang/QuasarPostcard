var constants = require('./constants');
var imageCache = require('./image-cache');
var api = require('./api');

var CANVAS_W = constants.CANVAS_W;
var CANVAS_H = constants.CANVAS_H;

function defaults(val, def) {
  return val !== undefined && val !== null ? val : def;
}

function toNum(val, def) {
  var n = Number(val);
  return isNaN(n) ? def : n;
}

function parseTemplate(tpl) {
  return {
    id: tpl.id || '',
    name: tpl.name || '',
    cornerRadius: toNum(tpl.corner_radius, 8),
    pattern: tpl.pattern || '',
    imageUrl: tpl.image_url || '',
    gradientFrom: tpl.gradient_from || 'FFF0F5',
    gradientMid: tpl.gradient_mid || '',
    gradientTo: tpl.gradient_to || 'FFC0CB',
    fromColor: constants.parseColor(tpl.from_color, '333333'),
    toColor: constants.parseColor(tpl.to_color, '333333'),
    messageColor: constants.parseColor(tpl.message_color, '555555'),
    fromFont: tpl.from_font || 'sans-serif',
    toFont: tpl.to_font || 'sans-serif',
    messageFont: tpl.message_font || 'sans-serif',
    fromSize: toNum(tpl.from_size, 14),
    toSize: toNum(tpl.to_size, 14),
    messageSize: toNum(tpl.message_size, 13),
    fromX: toNum(tpl.from_x, 10),
    fromY: toNum(tpl.from_y, 82),
    toX: toNum(tpl.to_x, 55),
    toY: toNum(tpl.to_y, 82),
    messageX: toNum(tpl.message_x, 10),
    messageY: toNum(tpl.message_y, 60),
    messageW: toNum(tpl.message_w, 80),
    messageH: toNum(tpl.message_h, 80),
    stampX: toNum(tpl.stamp_x, 78),
    stampY: toNum(tpl.stamp_y, 5),
    stampRotation: toNum(tpl.stamp_rotation, 0),
    stampScale: toNum(tpl.stamp_scale, 100),
    postmarkX: toNum(tpl.postmark_x, 45),
    postmarkY: toNum(tpl.postmark_y, 45),
    postmarkRotation: toNum(tpl.postmark_rotation, 0),
    postmarkScale: toNum(tpl.postmark_scale, 100),
    fromW: toNum(tpl.from_w, 120),
    fromH: toNum(tpl.from_h, 28),
    toW: toNum(tpl.to_w, 120),
    toH: toNum(tpl.to_h, 28),
    fromBorderColor: constants.parseColor(tpl.from_border_color, 'CCCCCC'),
    toBorderColor: constants.parseColor(tpl.to_border_color, 'CCCCCC'),
    fromBorderWidth: toNum(tpl.from_border_width, 0),
    toBorderWidth: toNum(tpl.to_border_width, 0),
    fromBgColor: constants.parseColor(tpl.from_bg_color, 'FFFFFF'),
    toBgColor: constants.parseColor(tpl.to_bg_color, 'FFFFFF'),
    fromBgOpacity: toNum(tpl.from_bg_opacity, 0),
    toBgOpacity: toNum(tpl.to_bg_opacity, 0),
  };
}

function preloadImages(tpl, stamp, postmark) {
  var urls = [];
  if (tpl.imageUrl) urls.push(api.imageUrl(tpl.imageUrl));
  if (stamp && stamp.image_url) urls.push(api.imageUrl(stamp.image_url));
  if (postmark && postmark.image_url) urls.push(api.imageUrl(postmark.image_url));
  return Promise.all(urls.map(function(u) {
    return imageCache.loadImage(u).catch(function() { return ''; });
  }));
}

function drawPostcard(canvas, design) {
  if (!canvas) return Promise.resolve();

  var ctx = canvas.getContext('2d');
  var dpr = constants.getDpr();
  var w = CANVAS_W;
  var h = CANVAS_H;

  canvas.width = w * dpr;
  canvas.height = h * dpr;
  ctx.scale(dpr, dpr);

  var rawTpl = design.template || {};
  var tpl = parseTemplate(rawTpl);
  var stamp = design.stamp || null;
  var postmark = design.postmark || null;
  var toName = design.toName || '';
  var fromName = design.fromName || '';
  var message = design.message || '';

  return preloadImages(tpl, stamp, postmark).then(function() {
    ctx.clearRect(0, 0, w, h);
    drawGradient(ctx, tpl, w, h);
    return drawBackgroundImage(ctx, canvas, tpl, w, h);
  }).then(function() {
    drawDecoration(ctx, tpl, w, h);
    return drawStampElement(ctx, canvas, tpl, stamp, w, h);
  }).then(function() {
    return drawPostmarkElement(ctx, canvas, tpl, postmark, w, h);
  }).then(function() {
    drawTextField(ctx, '寄件人', fromName, tpl.fromColor, tpl.fromFont, tpl.fromSize,
      tpl.fromX, tpl.fromY, tpl.fromW, tpl.fromH,
      tpl.fromBorderColor, tpl.fromBorderWidth, tpl.fromBgColor, tpl.fromBgOpacity, w, h);
    drawTextField(ctx, '收件人', toName, tpl.toColor, tpl.toFont, tpl.toSize,
      tpl.toX, tpl.toY, tpl.toW, tpl.toH,
      tpl.toBorderColor, tpl.toBorderWidth, tpl.toBgColor, tpl.toBgOpacity, w, h);
    drawMessage(ctx, message, tpl, w, h);
  });
}

// Layer 2: Gradient background
function drawGradient(ctx, tpl, w, h) {
  var colors = constants.getGradientColors({
    gradient_from: tpl.gradientFrom,
    gradient_mid: tpl.gradientMid,
    gradient_to: tpl.gradientTo,
  });
  var grad = ctx.createLinearGradient(0, 0, w, h);
  for (var i = 0; i < colors.length; i++) {
    grad.addColorStop(i / (colors.length - 1), colors[i]);
  }
  ctx.fillStyle = grad;
  roundRect(ctx, 0, 0, w, h, tpl.cornerRadius);
  ctx.fill();
}

// Layer 3: Template background image
function drawBackgroundImage(ctx, canvas, tpl, w, h) {
  if (!tpl.imageUrl) return Promise.resolve();
  var url = api.imageUrl(tpl.imageUrl);
  return imageCache.loadImage(url).then(function(localPath) {
    if (!localPath) return;
    var img = canvas.createImage();
    return new Promise(function(resolve) {
      img.onload = function() {
        ctx.save();
        roundRect(ctx, 0, 0, w, h, tpl.cornerRadius);
        ctx.clip();
        var imgRatio = img.width / img.height;
        var canvasRatio = w / h;
        var sx = 0, sy = 0, sw = img.width, sh = img.height;
        if (imgRatio > canvasRatio) {
          sw = img.height * canvasRatio;
          sx = (img.width - sw) / 2;
        } else {
          sh = img.width / canvasRatio;
          sy = (img.height - sh) / 2;
        }
        ctx.drawImage(img, sx, sy, sw, sh, 0, 0, w, h);
        ctx.restore();
        resolve();
      };
      img.onerror = function() { resolve(); };
      img.src = localPath;
    });
  }).catch(function() {});
}

// Layer 4: Pattern decoration
function drawDecoration(ctx, tpl, w, h) {
  switch (tpl.pattern) {
    case 'floral':
      ctx.save();
      ctx.globalAlpha = 0.25;
      ctx.font = '22px sans-serif';
      ctx.fillText('🌸', w - 36, 30);
      ctx.restore();
      break;
    case 'geometric':
      drawGeometricPattern(ctx, w, h);
      break;
    case 'vintage':
      ctx.save();
      ctx.globalAlpha = 0.25;
      ctx.font = '22px sans-serif';
      ctx.fillText('📮', w - 36, 30);
      ctx.restore();
      break;
    case 'nature':
      ctx.save();
      ctx.globalAlpha = 0.25;
      ctx.font = '22px sans-serif';
      ctx.fillText('🌿', w - 36, 30);
      ctx.restore();
      break;
    case 'ocean':
      drawWavePattern(ctx, w, h);
      break;
  }
}

function drawGeometricPattern(ctx, w, h) {
  ctx.save();
  ctx.strokeStyle = 'rgba(136,136,136,0.08)';
  ctx.lineWidth = 0.5;
  var spacing = 24;
  for (var x = 0; x < w; x += spacing) {
    ctx.beginPath();
    ctx.moveTo(x, 0);
    ctx.lineTo(x, h);
    ctx.stroke();
  }
  for (var y = 0; y < h; y += spacing) {
    ctx.beginPath();
    ctx.moveTo(0, y);
    ctx.lineTo(w, y);
    ctx.stroke();
  }
  ctx.restore();
}

function drawWavePattern(ctx, w, h) {
  ctx.save();
  ctx.strokeStyle = 'rgba(68,136,170,0.1)';
  ctx.lineWidth = 1.5;
  ctx.beginPath();
  ctx.moveTo(0, h - 20);
  for (var x = 0; x < w; x += 2) {
    ctx.lineTo(x, h - 20 + Math.sin(x / 20) * 6);
  }
  ctx.stroke();
  ctx.beginPath();
  ctx.moveTo(0, h - 12);
  for (var x2 = 0; x2 < w; x2 += 2) {
    ctx.lineTo(x2, h - 12 + Math.sin(x2 / 16 + 1) * 5);
  }
  ctx.stroke();
  ctx.restore();
}

// Layer 5: Postmark
function drawPostmarkElement(ctx, canvas, tpl, postmark, w, h) {
  var pmkScl = tpl.postmarkScale / 100;
  var pmkSize = 72 * pmkScl;
  var rotRad = tpl.postmarkRotation * Math.PI / 180;
  var cx = w * tpl.postmarkX / 100;
  var cy = h * tpl.postmarkY / 100;

  if (!postmark) {
    drawDashedCircle(ctx, cx, cy, pmkSize / 2 - 4);
    return Promise.resolve();
  }

  if (postmark.image_url) {
    var url = api.imageUrl(postmark.image_url);
    return imageCache.loadImage(url).then(function(localPath) {
      if (localPath) {
        var img = canvas.createImage();
        return new Promise(function(resolve) {
          img.onload = function() {
            var drawW = pmkSize;
            var drawH = pmkSize;
            if (img.width && img.height) {
              var ratio = img.width / img.height;
              if (ratio > 1) {
                drawH = pmkSize / ratio;
              } else {
                drawW = pmkSize * ratio;
              }
            }
            ctx.save();
            ctx.translate(cx, cy);
            ctx.rotate(rotRad);
            ctx.drawImage(img, -drawW / 2, -drawH / 2, drawW, drawH);
            ctx.restore();
            resolve();
          };
          img.onerror = function() {
            drawDefaultPostmark(ctx, cx, cy, pmkSize, postmark, rotRad);
            resolve();
          };
          img.src = localPath;
        });
      } else {
        drawDefaultPostmark(ctx, cx, cy, pmkSize, postmark, rotRad);
      }
    }).catch(function() {
      drawDefaultPostmark(ctx, cx, cy, pmkSize, postmark, rotRad);
    });
  }

  drawDefaultPostmark(ctx, cx, cy, pmkSize, postmark, rotRad);
  return Promise.resolve();
}

function drawDefaultPostmark(ctx, cx, cy, size, postmark, rotRad) {
  var color = constants.parseColor(postmark.color, '333333');
  var radius = size / 2 - 6;
  var dateText = postmark.date_text || '2026.05.22';

  ctx.save();
  ctx.translate(cx, cy);
  ctx.rotate(rotRad);

  // Outer circle
  ctx.strokeStyle = color.replace(')', ',0.7)').replace('rgb(', 'rgba(');
  ctx.lineWidth = 2;
  ctx.beginPath();
  ctx.arc(0, 0, radius, 0, Math.PI * 2);
  ctx.stroke();

  // Inner circle
  ctx.lineWidth = 1;
  ctx.beginPath();
  ctx.arc(0, 0, radius - 10, 0, Math.PI * 2);
  ctx.stroke();

  // Tick marks
  ctx.strokeStyle = color.replace(')', ',0.5)').replace('rgb(', 'rgba(');
  ctx.lineWidth = 0.8;
  for (var i = 0; i < 24; i++) {
    var angle = i * (Math.PI * 2 / 24);
    var r1 = radius - 4;
    var r2 = radius - 9;
    ctx.beginPath();
    ctx.moveTo(Math.cos(angle) * r1, Math.sin(angle) * r1);
    ctx.lineTo(Math.cos(angle) * r2, Math.sin(angle) * r2);
    ctx.stroke();
  }

  // Date text
  ctx.fillStyle = color.replace(')', ',0.8)').replace('rgb(', 'rgba(');
  ctx.font = '600 9px sans-serif';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText(dateText, 0, 0);

  ctx.restore();
}

function drawDashedCircle(ctx, cx, cy, radius) {
  ctx.save();
  ctx.strokeStyle = 'rgba(0,0,0,0.26)';
  ctx.lineWidth = 1.5;
  var dashCount = 32;
  var dashAngle = Math.PI * 2 / dashCount;
  for (var i = 0; i < dashCount; i += 2) {
    ctx.beginPath();
    ctx.arc(cx, cy, radius, i * dashAngle, (i + 1) * dashAngle);
    ctx.stroke();
  }
  ctx.restore();
}

// Layer 6: Stamp
function drawStampElement(ctx, canvas, tpl, stamp, w, h) {
  var stScl = tpl.stampScale / 100;
  var stW = 52 * stScl;
  var stH = 62 * stScl;
  var rotRad = tpl.stampRotation * Math.PI / 180;
  var cx = w * tpl.stampX / 100;
  var cy = h * tpl.stampY / 100;

  if (!stamp) {
    drawDashedRect(ctx, cx - stW / 2, cy - stH / 2, stW, stH);
    return Promise.resolve();
  }

  if (stamp.image_url) {
    var url = api.imageUrl(stamp.image_url);
    return imageCache.loadImage(url).then(function(localPath) {
      if (localPath) {
        var img = canvas.createImage();
        return new Promise(function(resolve) {
          img.onload = function() {
            ctx.save();
            ctx.translate(cx, cy);
            ctx.rotate(rotRad);
            ctx.drawImage(img, -stW / 2, -stH / 2, stW, stH);
            ctx.restore();
            resolve();
          };
          img.onerror = function() {
            drawStampEmoji(ctx, cx, cy, stamp.emoji, stScl, rotRad);
            resolve();
          };
          img.src = localPath;
        });
      } else {
        drawStampEmoji(ctx, cx, cy, stamp.emoji, stScl, rotRad);
      }
    }).catch(function() {
      drawStampEmoji(ctx, cx, cy, stamp.emoji, stScl, rotRad);
    });
  }

  drawStampEmoji(ctx, cx, cy, stamp.emoji, stScl, rotRad);
  return Promise.resolve();
}

function drawStampEmoji(ctx, cx, cy, emoji, scale, rotRad) {
  if (!emoji) return;
  ctx.save();
  ctx.translate(cx, cy);
  ctx.rotate(rotRad);
  ctx.font = (scale * 22) + 'px sans-serif';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText(emoji, 0, 0);
  ctx.restore();
}

function drawDashedRect(ctx, x, y, w, h) {
  ctx.save();
  ctx.strokeStyle = 'rgba(0,0,0,0.26)';
  ctx.lineWidth = 1.5;
  ctx.setLineDash([4, 3]);
  ctx.strokeRect(x + 2, y + 2, w - 4, h - 4);
  ctx.setLineDash([]);
  ctx.restore();
}

// Layers 7-8: Text fields (From / To)
function drawTextField(ctx, placeholder, name, color, fontFamily, fontSize,
  xPct, yPct, boxW, boxH, borderColor, borderWidth, bgColor, bgOpacity, w, h) {
  var cx = w * xPct / 100;
  var cy = h * yPct / 100;
  var x = cx - boxW / 2;
  var y = cy - boxH / 2;
  var isEmpty = !name;

  ctx.save();

  // Background fill
  if (bgOpacity > 0) {
    ctx.globalAlpha = bgOpacity / 100;
    ctx.fillStyle = bgColor;
    roundRect(ctx, x, y, boxW, boxH, 4);
    ctx.fill();
    ctx.globalAlpha = 1;
  }

  // Border
  if (isEmpty) {
    ctx.strokeStyle = withAlpha(color, 0.3);
    ctx.lineWidth = 1;
    roundRect(ctx, x, y, boxW, boxH, 4);
    ctx.stroke();
  } else if (borderWidth > 0) {
    ctx.strokeStyle = borderColor;
    ctx.lineWidth = borderWidth;
    roundRect(ctx, x, y, boxW, boxH, 4);
    ctx.stroke();
  }

  // Text
  ctx.textBaseline = 'middle';
  ctx.textAlign = 'left';
  var textX = x + 8;
  var textY = y + boxH / 2;

  if (isEmpty) {
    ctx.fillStyle = withAlpha(color, 0.35);
    ctx.font = fontSize + 'px ' + fontFamily;
    ctx.fillText(placeholder, textX, textY);
  } else {
    ctx.fillStyle = color;
    ctx.font = '500 ' + fontSize + 'px ' + fontFamily;
    ctx.fillText(name, textX, textY);
  }

  ctx.restore();
}

// Layer 9: Message
function drawMessage(ctx, message, tpl, w, h) {
  var x = w * tpl.messageX / 100 + 6;
  var y = h * tpl.messageY / 100 + 6;
  var maxW = w * tpl.messageW / 100 - 12;
  var maxH = tpl.messageH - 12;
  var text = message || '';

  ctx.save();
  ctx.textBaseline = 'top';
  ctx.textAlign = 'left';

  if (!text) {
    ctx.fillStyle = 'rgba(0,0,0,0.26)';
    ctx.font = 'italic ' + tpl.messageSize + 'px ' + tpl.messageFont;
    ctx.fillText('祝福语', x, y);
    ctx.restore();
    return;
  }

  ctx.fillStyle = tpl.messageColor;
  ctx.font = 'italic ' + tpl.messageSize + 'px ' + tpl.messageFont;
  var lineHeight = tpl.messageSize * 1.5;
  var lines = wrapText(ctx, text, maxW);
  for (var i = 0; i < lines.length; i++) {
    var ly = y + i * lineHeight;
    if (ly + lineHeight > y + maxH) break;
    ctx.fillText(lines[i], x, ly);
  }

  ctx.restore();
}

// ======== Helpers ========

function wrapText(ctx, text, maxWidth) {
  var lines = [];
  var paragraphs = text.split('\n');
  for (var p = 0; p < paragraphs.length; p++) {
    var para = paragraphs[p];
    if (!para) {
      lines.push('');
      continue;
    }
    var currentLine = '';
    for (var i = 0; i < para.length; i++) {
      var ch = para[i];
      var testLine = currentLine + ch;
      var metrics = ctx.measureText(testLine);
      if (metrics.width > maxWidth && currentLine) {
        lines.push(currentLine);
        currentLine = ch;
      } else {
        currentLine = testLine;
      }
    }
    if (currentLine) lines.push(currentLine);
  }
  return lines;
}

function roundRect(ctx, x, y, w, h, r) {
  if (r <= 0) {
    ctx.beginPath();
    ctx.rect(x, y, w, h);
    return;
  }
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.lineTo(x + w - r, y);
  ctx.arcTo(x + w, y, x + w, y + r, r);
  ctx.lineTo(x + w, y + h - r);
  ctx.arcTo(x + w, y + h, x + w - r, y + h, r);
  ctx.lineTo(x + r, y + h);
  ctx.arcTo(x, y + h, x, y + h - r, r);
  ctx.lineTo(x, y + r);
  ctx.arcTo(x, y, x + r, y, r);
  ctx.closePath();
}

function withAlpha(colorStr, alpha) {
  if (colorStr.indexOf('rgba') === 0) {
    return colorStr.replace(/,[^,]+\)$/, ',' + alpha + ')');
  }
  if (colorStr.indexOf('rgb') === 0) {
    return colorStr.replace('rgb(', 'rgba(').replace(')', ',' + alpha + ')');
  }
  return colorStr;
}

function canvasToTempFile(canvas) {
  return new Promise(function(resolve, reject) {
    wx.canvasToTempFilePath({
      canvas: canvas,
      success: function(res) { resolve(res.tempFilePath); },
      fail: reject,
    });
  });
}

module.exports = {
  drawPostcard: drawPostcard,
  canvasToTempFile: canvasToTempFile,
  CANVAS_W: CANVAS_W,
  CANVAS_H: CANVAS_H,
};
