import 'dart:math';
import 'package:flutter/material.dart';
import '../models/postcard.dart';
import '../services/api_service.dart';
import 'app_image.dart';

class PostcardCanvas extends StatelessWidget {
  final PostcardDesign design;
  final bool showStampAnimation;

  static const double canvasW = 420.0;
  static const double canvasH = 270.0;

  const PostcardCanvas({
    super.key,
    required this.design,
    this.showStampAnimation = false,
  });

  @override
  Widget build(BuildContext context) {
    final template = design.template;
    final stamp = design.stamp;
    final postmark = design.postmark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth - 32;
        final maxH = constraints.maxHeight - 16;
        double w, h;
        if (maxW / maxH > PostcardDesign.aspectRatio) {
          h = maxH;
          w = h * PostcardDesign.aspectRatio;
        } else {
          w = maxW;
          h = w / PostcardDesign.aspectRatio;
        }
        final s = w / canvasW;

        return Center(
          child: Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(template.cornerRadius * s),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 24 * s, offset: Offset(0, 8 * s)),
                BoxShadow(color: Colors.white.withOpacity(0.05), blurRadius: 40 * s, offset: const Offset(0, 0)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(template.cornerRadius * s),
              child: FittedBox(
                fit: BoxFit.fill,
                child: SizedBox(
                  width: canvasW,
                  height: canvasH,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: template.gradientColors,
                      ),
                    ),
                    child: Stack(
                      children: [
                      if (template.imageUrl != null && template.imageUrl!.isNotEmpty)
                        Positioned.fill(
                          child: AppImage(
                            url: template.imageUrl,
                            fit: BoxFit.cover,
                          ),
                        ),

                      _buildDecoration(template),

                      // Stamp
                      _stampElement(template, stamp),

                      // Postmark (after stamp = on top)
                      _postmarkElement(template, postmark),

                      // To field
                      _textElement('收件人', design.toName, template.toColor, template.toFont, template.toSize, template.toX, template.toY, template.toW, template.toH, template.toBorderColor, template.toBorderWidth, template.toBgColor, template.toBgOpacity, design.toName.isEmpty),

                      // From field
                      _textElement('寄件人', design.fromName, template.fromColor, template.fromFont, template.fromSize, template.fromX, template.fromY, template.fromW, template.fromH, template.fromBorderColor, template.fromBorderWidth, template.fromBgColor, template.fromBgOpacity, design.fromName.isEmpty),

                      // Message
                      _messageElement(template, design.message),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      },
    );
  }

  // ======== Element builders ========

  Widget _stampElement(PostcardTemplate template, PostcardStamp? stamp) {
    final stScl = template.stampScale / 100;
    final stW = 52.0 * stScl;
    final stH = 62.0 * stScl;
    final rotRad = template.stampRotation * 3.14159 / 180;

    final content = stamp != null
        ? (stamp.imageUrl != null && stamp.imageUrl!.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: AppImage(url: stamp.imageUrl, width: stW, height: stH, fit: BoxFit.cover, errorWidget: () => Text(stamp.emoji, style: TextStyle(fontSize: stScl * 22))),
              )
            : Center(child: Text(stamp.emoji, style: TextStyle(fontSize: stScl * 22))))
        : SizedBox(width: stW, height: stH, child: CustomPaint(painter: _DashedRectPainter()));

    return Positioned(
      left: canvasW * template.stampX / 100,
      top: canvasH * template.stampY / 100,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: Transform(
          transform: Matrix4.rotationZ(rotRad),
          origin: Offset(stW / 2, stH / 2),
          child: content,
        ),
      ),
    );
  }

  Widget _postmarkElement(PostcardTemplate template, PostcardPostmark? postmark) {
    final pmkScl = template.postmarkScale / 100;
    final pmkSize = 72.0 * pmkScl;
    final rotRad = template.postmarkRotation * 3.14159 / 180;

    Widget inner;
    if (postmark != null) {
      if (postmark.imageUrl != null && postmark.imageUrl!.isNotEmpty) {
        inner = SizedBox(
          width: pmkSize,
          height: pmkSize,
          child: AppImage(url: postmark.imageUrl, width: pmkSize, height: pmkSize, fit: BoxFit.contain, errorWidget: () => _buildDefaultPostmark(postmark, pmkSize)),
        );
      } else {
        inner = _buildDefaultPostmark(postmark, pmkSize);
      }
    } else {
      inner = SizedBox(width: pmkSize, height: pmkSize, child: CustomPaint(painter: _DashedCirclePainter()));
    }

    return Positioned(
      left: canvasW * template.postmarkX / 100,
      top: canvasH * template.postmarkY / 100,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: Transform(
          transform: Matrix4.rotationZ(rotRad),
          origin: Offset(pmkSize / 2, pmkSize / 2),
          child: inner,
        ),
      ),
    );
  }

  Widget _textElement(String placeholder, String name, Color color, String fontFamily, double fontSize, double xPct, double yPct, double boxW, double boxH, Color borderColor, double borderWidth, Color bgColor, double bgOpacity, bool isEmpty) {
    final bg = bgColor.withOpacity(bgOpacity / 100);
    return Positioned(
      left: canvasW * xPct / 100,
      top: canvasH * yPct / 100,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: Container(
          width: boxW,
          height: boxH,
          decoration: BoxDecoration(
            color: bg,
            border: isEmpty
                ? Border.all(color: color.withOpacity(0.3), width: 1)
                : (borderWidth > 0 ? Border.all(color: borderColor, width: borderWidth) : null),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          alignment: Alignment.centerLeft,
          child: isEmpty
              ? Text(placeholder, style: TextStyle(fontSize: fontSize, color: color.withOpacity(0.35), fontFamily: fontFamily))
              : Text(name, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500, color: color, fontFamily: fontFamily)),
        ),
      ),
    );
  }

  Widget _messageElement(PostcardTemplate template, String message) {
    return Positioned(
      left: canvasW * template.messageX / 100,
      top: canvasH * template.messageY / 100,
      width: canvasW * template.messageW / 100,
      height: template.messageH,
      child: Container(
        padding: const EdgeInsets.all(6),
        alignment: Alignment.topLeft,
        child: design.message.isNotEmpty
            ? Text(
                design.message,
                maxLines: null,
                overflow: TextOverflow.clip,
                style: TextStyle(
                  fontSize: template.messageSize,
                  color: template.messageColor,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                  fontFamily: template.messageFont,
                ),
              )
            : Text(
                '祝福语',
                style: TextStyle(fontSize: template.messageSize, color: Colors.black26, fontStyle: FontStyle.italic, fontFamily: template.messageFont),
              ),
      ),
    );
  }

  // ======== Shared helpers ========

  Widget _buildDefaultPostmark(PostcardPostmark postmark, double size) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PostmarkPainter(
          color: postmark.color,
          dateText: postmark.dateText,
        ),
      ),
    );
  }

  // ======== Decorations ========

  Widget _buildDecoration(PostcardTemplate template) {
    switch (template.decorationPattern) {
      case 'floral':
        return const Positioned(top: 10, right: 14, child: Opacity(opacity: 0.25, child: Text('🌸', style: TextStyle(fontSize: 22))));
      case 'geometric':
        return Positioned.fill(child: CustomPaint(painter: _GeometricPatternPainter()));
      case 'vintage':
        return const Positioned(top: 10, right: 14, child: Opacity(opacity: 0.25, child: Text('📮', style: TextStyle(fontSize: 22))));
      case 'nature':
        return const Positioned(top: 10, right: 14, child: Opacity(opacity: 0.25, child: Text('🌿', style: TextStyle(fontSize: 22))));
      case 'ocean':
        return Positioned(bottom: 0, left: 0, right: 0, child: CustomPaint(painter: _WavePatternPainter(canvasW: canvasW)));
      default:
        return const SizedBox.shrink();
    }
  }
}

// ======== Painters ========

class _PostmarkPainter extends CustomPainter {
  final Color color;
  final String dateText;

  _PostmarkPainter({required this.color, required this.dateText});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    canvas.drawCircle(center, radius, paint);

    paint.strokeWidth = 1.0;
    canvas.drawCircle(center, radius - 10, paint);

    final wavePaint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (int i = 0; i < 24; i++) {
      final angle = i * (3.14159 * 2 / 24);
      final r1 = radius - 4;
      final r2 = radius - 9;
      canvas.drawLine(
        Offset(center.dx + cos(angle) * r1, center.dy + sin(angle) * r1),
        Offset(center.dx + cos(angle) * r2, center.dy + sin(angle) * r2),
        wavePaint,
      );
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: dateText,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color.withOpacity(0.8)),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: radius * 1.5);
    textPainter.paint(canvas, Offset(center.dx - textPainter.width / 2, center.dy - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _PostmarkPainter oldDelegate) => false;
}

class _GeometricPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF888888).withOpacity(0.08)
      ..strokeWidth = 0.5;

    const spacing = 24.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GeometricPatternPainter oldDelegate) => false;
}

class _WavePatternPainter extends CustomPainter {
  final double canvasW;

  _WavePatternPainter({this.canvasW = 420});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4488AA).withOpacity(0.1)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height - 20);
    for (double x = 0; x < size.width; x += 2) {
      final y = size.height - 20 + sin(x / 20) * 6;
      path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);

    path.reset();
    path.moveTo(0, size.height - 12);
    for (double x = 0; x < size.width; x += 2) {
      final y = size.height - 12 + sin(x / 16 + 1) * 5;
      path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavePatternPainter oldDelegate) => false;
}

class _DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    _drawDashedCircle(canvas, center, radius, paint);
  }

  void _drawDashedCircle(Canvas canvas, Offset center, double radius, Paint paint) {
    const dashCount = 32;
    const dashAngle = 3.14159 * 2 / dashCount;
    for (int i = 0; i < dashCount; i += 2) {
      final startAngle = i * dashAngle;
      final sweepAngle = dashAngle;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) => false;
}

class _DashedRectPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black26
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    const dashLen = 4.0;
    const gapLen = 3.0;
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 2, size.width - 4, size.height - 4),
      const Radius.circular(2),
    );

    _drawDashedLine(canvas, Offset(r.left, r.top), Offset(r.right, r.top), dashLen, gapLen, paint);
    _drawDashedLine(canvas, Offset(r.left, r.bottom), Offset(r.right, r.bottom), dashLen, gapLen, paint);
    _drawDashedLine(canvas, Offset(r.left, r.top), Offset(r.left, r.bottom), dashLen, gapLen, paint);
    _drawDashedLine(canvas, Offset(r.right, r.top), Offset(r.right, r.bottom), dashLen, gapLen, paint);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, double dashLen, double gapLen, Paint paint) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final dist = (dx == 0 && dy == 0) ? 0.0 : (dx != 0 ? dx.abs() : dy.abs());
    final steps = dist / (dashLen + gapLen);
    for (int i = 0; i < steps; i++) {
      final t = (i * (dashLen + gapLen)) / dist;
      final dashEnd = ((i * (dashLen + gapLen)) + dashLen) / dist;
      final s = Offset(start.dx + dx * t, start.dy + dy * t);
      final e = Offset(start.dx + dx * dashEnd.clamp(0, 1), start.dy + dy * dashEnd.clamp(0, 1));
      canvas.drawLine(s, e, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRectPainter oldDelegate) => false;
}
