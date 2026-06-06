import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';
import '../services/wechat_share_service.dart';
import '../services/email_share_service.dart';
import '../utils/download_helper.dart';
import '../utils/launcher.dart';

class ShareSheet extends StatefulWidget {
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
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E36),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ShareSheet(imageBytes: bytes, filename: filename),
    );
  }

  @override
  State<ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<ShareSheet> {
  String? _shareImageUrl;
  bool _uploading = true;
  String? _uploadError;

  @override
  void initState() {
    super.initState();
    _uploadShareImage();
  }

  Future<void> _uploadShareImage() async {
    final completer = Completer<void>();
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/api/share/upload-image');
      final base64Data = base64Encode(widget.imageBytes);

      final xhr = html.HttpRequest()
        ..open('POST', uri.toString())
        ..setRequestHeader('Content-Type', 'application/json')
        ..setRequestHeader('Authorization', 'Bearer ${ApiService.token}');

      xhr.onLoad.listen((_) {
        if (xhr.status == 200) {
          try {
            final data = jsonDecode(xhr.responseText!) as Map<String, dynamic>;
            if (data['success'] == true) {
              _shareImageUrl = data['url'] as String;
              _uploading = false;
              if (mounted) setState(() {});
              completer.complete();
              return;
            }
          } catch (_) {}
        }
        _uploadError = '上传图片失败';
        _uploading = false;
        if (mounted) setState(() {});
        completer.complete();
      });

      xhr.onError.listen((_) {
        _uploadError = '网络错误';
        _uploading = false;
        if (mounted) setState(() {});
        completer.complete();
      });

      xhr.send(jsonEncode({'image_data': base64Data}));
      await completer.future;
    } catch (e) {
      if (mounted) {
        _uploadError = e.toString();
        _uploading = false;
        setState(() {});
      }
    }
  }

  String get _absoluteImageUrl {
    if (_shareImageUrl == null) return '';
    return '${ApiService.baseUrl}$_shareImageUrl';
  }

  String get _shareViewUrl {
    if (_shareImageUrl == null) return '';
    final filename = _shareImageUrl!.split('/').last;
    return '${ApiService.baseUrl}/share/view/$filename';
  }

  @override
  Widget build(BuildContext context) {
    final inWechat = WechatShareService.isInWechat;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 32, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('分享明信片', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 24),
          if (_uploading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(color: Color(0xFF7C4DFF)),
            )
          else if (_uploadError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(children: [
                Text(_uploadError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                const SizedBox(height: 12),
                _Option(icon: Icons.download_rounded, label: '保存', color: const Color(0xFF7C4DFF), onTap: () => _save(context)),
              ]),
            )
          else
            Wrap(spacing: 16, runSpacing: 16, children: [
              if (inWechat) ...[
                _Option(icon: Icons.chat_rounded, label: '微信朋友', color: const Color(0xFF07C160), onTap: () => _shareToFriend(context)),
                _Option(icon: Icons.circle_rounded, label: '朋友圈', color: const Color(0xFF2196F3), onTap: () => _shareToTimeline(context)),
              ],
              _Option(icon: Icons.qr_code_rounded, label: '二维码', color: const Color(0xFFFF8F00), onTap: () => _showQrCode(context)),
              _Option(icon: Icons.email_rounded, label: '邮件', color: const Color(0xFFEA4335), onTap: () => _emailShare(context)),
              _Option(icon: Icons.download_rounded, label: '保存', color: const Color(0xFF7C4DFF), onTap: () => _save(context)),
            ]),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  void _shareToFriend(BuildContext context) async {
    WechatShareService.configShare(
      title: '一张明信片',
      desc: '有人给你寄了一张明信片',
      link: _shareViewUrl,
      imgUrl: _absoluteImageUrl,
    );
    Navigator.pop(context);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已配置微信分享，点击右上角菜单分享'), backgroundColor: Color(0xFF4CAF50)));
    }
  }

  void _shareToTimeline(BuildContext context) async {
    WechatShareService.configShare(
      title: '一张明信片',
      desc: '',
      link: _shareViewUrl,
      imgUrl: _absoluteImageUrl,
    );
    Navigator.pop(context);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已配置朋友圈分享，点击右上角菜单分享'), backgroundColor: Color(0xFF4CAF50)));
    }
  }

  void _showQrCode(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E36),
        title: const Text('扫码查看', style: TextStyle(color: Colors.white70, fontSize: 16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          if (_shareViewUrl.isNotEmpty)
            Container(
              width: 200, height: 200,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.all(8),
              child: QrImageView(data: _shareViewUrl, version: QrVersions.auto, eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF1A1A2E))),
            ),
          const SizedBox(height: 12),
          Text(_shareViewUrl, style: const TextStyle(fontSize: 11, color: Colors.white38), textAlign: TextAlign.center),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('关闭', style: TextStyle(color: Colors.white38))),
        ],
      ),
    );
  }

  void _emailShare(BuildContext context) {
    final emailCtrl = TextEditingController();
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E36),
        title: const Text('发送邮件', style: TextStyle(color: Colors.white70, fontSize: 16)),
        content: TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(fontSize: 14, color: Colors.white),
          decoration: const InputDecoration(
            hintText: '输入收件人邮箱',
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消', style: TextStyle(color: Colors.white38))),
          TextButton(
            onPressed: () async {
              final email = emailCtrl.text.trim();
              if (email.isEmpty) return;
              Navigator.pop(ctx);
              final result = await EmailShareService.sendEmail(
                email: email,
                imageUrl: _shareImageUrl ?? '',
              );
              if (result['success'] == true) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('邮件已发送'), backgroundColor: Color(0xFF4CAF50)));
                }
              } else if (result['fallback'] == 'mailto') {
                EmailShareService.openMailtoFallback(email: email, subject: '有人给你寄了一张明信片', shareUrl: _shareViewUrl);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('发送失败: ${result['message'] ?? '未知错误'}'), backgroundColor: Colors.redAccent));
                }
              }
            },
            child: const Text('发送', style: TextStyle(color: Color(0xFF7C4DFF))),
          ),
        ],
      ),
    );
  }

  void _save(BuildContext context) {
    downloadBytes(widget.imageBytes, widget.filename);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存到设备'), backgroundColor: Color(0xFF4CAF50)));
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
      child: SizedBox(
        width: 72,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 56, height: 56, decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle), child: Icon(icon, color: color, size: 28)),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
