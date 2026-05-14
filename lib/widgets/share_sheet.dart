import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../utils/download_helper.dart';
import '../utils/share_helper.dart';
import '../utils/launcher.dart';

class ShareSheet extends StatelessWidget {
  final Uint8List imageBytes;
  final String filename;

  const ShareSheet({super.key, required this.imageBytes, required this.filename});

  static Future<Uint8List?> capture(GlobalKey repaintKey, {double pixelRatio = 3.0}) async {
    final boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    await Future.delayed(const Duration(milliseconds: 100));
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  static void show(BuildContext context, Uint8List bytes, String filename) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E36),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ShareSheet(imageBytes: bytes, filename: filename),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 32, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('分享明信片', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            _Option(icon: Icons.share_rounded, label: '系统分享', color: const Color(0xFF4CAF50), onTap: () => _systemShare(context)),
            _Option(icon: Icons.email_rounded, label: '邮件', color: const Color(0xFFEA4335), onTap: () => _emailShare(context)),
            _Option(icon: Icons.download_rounded, label: '保存', color: const Color(0xFF7C4DFF), onTap: () => _save(context)),
            _Option(icon: Icons.more_horiz, label: '更多', color: Colors.white54, onTap: () => _saveAndHint(context)),
          ]),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  void _systemShare(BuildContext context) async {
    final ok = await shareImage(imageBytes, filename);
    if (!ok && context.mounted) {
      Navigator.pop(context);
      await downloadBytes(imageBytes, filename);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存到设备'), backgroundColor: Color(0xFF4CAF50)));
      }
    }
  }

  void _emailShare(BuildContext context) {
    downloadBytes(imageBytes, filename);
    final subject = Uri.encodeComponent('分享一张明信片给你');
    final body = Uri.encodeComponent('请查收附件中的明信片～');
    openUrl('mailto:?subject=$subject&body=$body');
    Navigator.pop(context);
  }

  void _save(BuildContext context) {
    downloadBytes(imageBytes, filename);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存到设备'), backgroundColor: Color(0xFF4CAF50)));
  }

  void _saveAndHint(BuildContext context) async {
    await downloadBytes(imageBytes, filename);
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存，可分享到微信、微博等平台'), backgroundColor: Color(0xFF4CAF50)));
    }
  }
}

class _Option extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _Option({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 56, height: 56, decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle), child: Icon(icon, color: color, size: 28)),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
      ]),
    );
  }
}
