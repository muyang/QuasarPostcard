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
                BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6)),
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
                          border: Border.all(color: design.themeColor.withOpacity(0.5), width: 1.5),
                        ),
                      ),
                    ),

                    // Postmark (behind everything, bottom-left area)
                    if (postmark != null)
                      Positioned(
                        left: w * 0.12,
                        bottom: h * 0.15,
                        child: _buildPostmark(postmark, design.themeColor, stamp),
                      ),

                    // Stamp in top-right corner
                    if (stamp != null)
                      Positioned(
                        top: h * 0.08,
                        right: w * 0.1,
                        child: _buildStamp(stamp, showStampAnimation),
                      ),

                    // Text content
                    Padding(
                      padding: EdgeInsets.all(w * 0.06),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header line
                          _headerLine(design.themeColor),
                          SizedBox(height: h * 0.04),

                          // To field
                          _addressLine('To:', design.toName, design.themeColor, design.toName.isEmpty),
                          SizedBox(height: h * 0.03),

                          // Message body
                          Expanded(
                            child: design.message.isNotEmpty
                                ? Text(
                                    design.message,
                                    style: TextStyle(
                                      fontSize: w * 0.04,
                                      color: const Color(0xFF444444),
                                      height: 1.5,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      '书写你的祝福…',
                                      style: TextStyle(fontSize: w * 0.04, color: Colors.black26, fontStyle: FontStyle.italic),
                                    ),
                                  ),
                          ),

                          // From field
                          Align(
                            alignment: Alignment.bottomRight,
                            child: _addressLine('From:', design.fromName, design.themeColor, design.fromName.isEmpty, isFrom: true),
                          ),
                        ],
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
        Text('POSTCARD', style: TextStyle(fontSize: 11, letterSpacing: 3, color: color.withOpacity(0.4))),
      ],
    );
  }

  Widget _addressLine(String label, String name, Color color, bool isEmpty, {bool isFrom = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        const SizedBox(width: 8),
        if (isEmpty)
          Container(
            width: 80,
            height: 18,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: color.withOpacity(0.3), width: 1)),
            ),
          )
        else
          Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF333333))),
      ],
    );
  }

  Widget _buildStamp(PostcardStamp stamp, bool animate) {
    return AnimatedScale(
      scale: 1.0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      child: AnimatedRotation(
        turns: 0.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
        child: Container(
          width: 48,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: stamp.accentColor, width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(2, 2))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (stamp.imageUrl != null && stamp.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: Image.network(ApiService.imageUrl(stamp.imageUrl), width: 36, height: 36, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Text(stamp.emoji, style: const TextStyle(fontSize: 20))),
                )
              else
                Text(stamp.emoji, style: const TextStyle(fontSize: 20)),
              Text(stamp.label, style: TextStyle(fontSize: 7, color: stamp.accentColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostmark(PostcardPostmark postmark, Color themeColor, PostcardStamp? stamp) {
    final size = 80.0;
    if (postmark.imageUrl != null && postmark.imageUrl!.isNotEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: Image.network(ApiService.imageUrl(postmark.imageUrl), width: size, height: size, fit: BoxFit.contain, errorBuilder: (_, __, ___) => _buildDefaultPostmark(postmark, size)),
      );
    }
    return _buildDefaultPostmark(postmark, size);
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

