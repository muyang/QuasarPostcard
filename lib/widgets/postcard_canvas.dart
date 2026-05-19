import 'dart:math';
import 'package:flutter/material.dart';
import '../models/postcard.dart';
import '../services/api_service.dart';

class PostcardCanvas extends StatelessWidget {
  final PostcardDesign design;
  final bool showStampAnimation;

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

        return Center(
          child: Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(template.cornerRadius),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 8)),
                BoxShadow(color: design.themeColor.withOpacity(0.08), blurRadius: 40, offset: const Offset(0, 0)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(template.cornerRadius),
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
                    // Template image as background
                    if (template.imageUrl != null && template.imageUrl!.isNotEmpty)
                      Positioned.fill(
                        child: Image.network(
                          ApiService.imageUrl(template.imageUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),

                    // Decorative pattern
                    _buildDecoration(template),

                    // Inner border with theme color
                    Positioned(
                      left: 12, top: 12, right: 12, bottom: 12,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(template.cornerRadius - 2),
                          border: Border.all(color: design.themeColor.withOpacity(0.35), width: 1),
                        ),
                      ),
                    ),

                    // Stamp
                    Positioned(
                      left: w * template.stampX / 100 - 24 * template.stampScale / 100,
                      top: h * template.stampY / 100 - 28 * template.stampScale / 100,
                      child: stamp != null
                          ? _buildStamp(stamp, showStampAnimation, template.stampScale, template.stampRotation)
                          : Transform.scale(
                              scale: template.stampScale / 100,
                              child: _buildStampPlaceholder(),
                            ),
                    ),

                    // Postmark (rendered after stamp so it appears on top)
                    Positioned(
                      left: w * template.postmarkX / 100 - 40 * template.postmarkScale / 100,
                      top: h * template.postmarkY / 100 - 40 * template.postmarkScale / 100,
                      child: Transform.scale(
                        scale: template.postmarkScale / 100,
                        child: postmark != null
                            ? _buildPostmark(postmark, design.themeColor, stamp, template)
                            : _buildPostmarkPlaceholder(),
                      ),
                    ),

                    // Header line
                    Positioned(
                      left: w * 0.06, top: h * 0.04, right: w * 0.06,
                      child: _headerLine(design.themeColor),
                    ),

                    // To field (centered on position to match admin canvas)
                    Positioned(
                      left: w * template.toX / 100,
                      top: h * template.toY / 100,
                      child: FractionalTranslation(
                        translation: const Offset(-0.5, -0.5),
                        child: _addressLine('To:', design.toName, template.toColor, design.toName.isEmpty, fontSize: template.toSize, fontFamily: template.toFont),
                      ),
                    ),

                    // From field (centered on position to match admin canvas)
                    Positioned(
                      left: w * template.fromX / 100,
                      top: h * template.fromY / 100,
                      child: FractionalTranslation(
                        translation: const Offset(-0.5, -0.5),
                        child: _addressLine('From:', design.fromName, template.fromColor, design.fromName.isEmpty, fontSize: template.fromSize, fontFamily: template.fromFont),
                      ),
                    ),

                    // Message body (vertically centered on position like admin canvas)
                    Positioned(
                      left: w * template.messageX / 100,
                      top: h * template.messageY / 100,
                      width: w * template.messageW / 100,
                      bottom: h * (1 - template.fromY / 100) - 4,
                      child: design.message.isNotEmpty
                          ? Text(
                              design.message,
                              style: TextStyle(
                                fontSize: template.messageSize,
                                color: template.messageColor,
                                height: 1.5,
                                fontStyle: FontStyle.italic,
                                fontFamily: template.messageFont,
                              ),
                            )
                          : Center(
                              child: Text(
                                '书写你的祝福…',
                                style: TextStyle(fontSize: template.messageSize, color: Colors.black26, fontStyle: FontStyle.italic, fontFamily: template.messageFont),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _headerLine(Color color) {
    return Row(
      children: [
        Container(width: 36, height: 2, color: color.withOpacity(0.6)),
        const SizedBox(width: 8),
        Icon(Icons.mail_outline, size: 16, color: color.withOpacity(0.6)),
        const Spacer(),
        Container(width: 36, height: 2, color: color.withOpacity(0.6)),
      ],
    );
  }

  Widget _addressLine(String label, String name, Color color, bool isEmpty, {double fontSize = 14, String fontFamily = 'sans-serif'}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600, color: color, fontFamily: fontFamily)),
        const SizedBox(width: 8),
        if (isEmpty)
          Container(
            width: 80,
            height: fontSize + 4,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: color.withOpacity(0.3), width: 1)),
            ),
          )
        else
          Text(name, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500, color: color, fontFamily: fontFamily)),
      ],
    );
  }

  Widget _buildStamp(PostcardStamp stamp, bool animate, double scale, double rotation) {
    return AnimatedScale(
      scale: 1.0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      child: AnimatedRotation(
        turns: 0.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
        child: Transform.rotate(
          angle: rotation * 3.14159 / 180,
          child: Transform.scale(
            scale: scale / 100,
            child: stamp.imageUrl != null && stamp.imageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Image.network(ApiService.imageUrl(stamp.imageUrl), width: 48, height: 56, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Text(stamp.emoji, style: const TextStyle(fontSize: 24))),
                  )
                : Text(stamp.emoji, style: const TextStyle(fontSize: 24)),
          ),
        ),
      ),
    );
  }

  Widget _buildPostmark(PostcardPostmark postmark, Color themeColor, PostcardStamp? stamp, PostcardTemplate template) {
    final size = 80.0;
    Widget inner;
    if (postmark.imageUrl != null && postmark.imageUrl!.isNotEmpty) {
      inner = SizedBox(
        width: size,
        height: size,
        child: Image.network(ApiService.imageUrl(postmark.imageUrl), width: size, height: size, fit: BoxFit.contain, errorBuilder: (_, __, ___) => _buildDefaultPostmark(postmark, size)),
      );
    } else {
      inner = _buildDefaultPostmark(postmark, size);
    }
    return Transform.rotate(
      angle: template.postmarkRotation * 3.14159 / 180,
      child: inner,
    );
  }

  Widget _buildPostmarkPlaceholder() {
    return SizedBox(
      width: 80,
      height: 80,
      child: CustomPaint(
        painter: _DashedCirclePainter(),
      ),
    );
  }

  Widget _buildStampPlaceholder() {
    return SizedBox(
      width: 48,
      height: 56,
      child: CustomPaint(
        painter: _DashedRectPainter(),
      ),
    );
  }

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

  Widget _buildDecoration(PostcardTemplate template) {
    switch (template.decorationPattern) {
      case 'floral':
        return _floralDecoration();
      case 'geometric':
        return _geometricDecoration();
      case 'vintage':
        return _vintageDecoration();
      case 'nature':
        return _natureDecoration();
      case 'ocean':
        return _oceanDecoration();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _floralDecoration() {
    return const Positioned(
      top: -20, right: -10,
      child: Opacity(opacity: 0.15, child: Text('🌸', style: TextStyle(fontSize: 80))),
    );
  }

  Widget _geometricDecoration() {
    return Positioned.fill(
      child: CustomPaint(painter: _GeometricPatternPainter()),
    );
  }

  Widget _vintageDecoration() {
    return const Positioned(
      bottom: -15, left: -10,
      child: Opacity(opacity: 0.12, child: Text('📮', style: TextStyle(fontSize: 70))),
    );
  }

  Widget _natureDecoration() {
    return const Positioned(
      top: -15, left: -5,
      child: Opacity(opacity: 0.12, child: Text('🌿', style: TextStyle(fontSize: 65))),
    );
  }

  Widget _oceanDecoration() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: CustomPaint(painter: _WavePatternPainter()),
    );
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

    // Outer circle
    canvas.drawCircle(center, radius, paint);

    // Inner circle
    paint.strokeWidth = 1.0;
    canvas.drawCircle(center, radius - 10, paint);

    // Wavy lines between circles
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

    // Date text in center
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

