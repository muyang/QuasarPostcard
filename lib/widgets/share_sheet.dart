import '../theme/app_colors.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';
import '../services/wechat_share_service.dart';
import '../services/email_share_service.dart';
import '../utils/download_helper.dart';

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
      backgroundColor: AppColors.surfaceVariant,
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
    try {
      final url = await ApiService.uploadShareImage(widget.imageBytes);
      _shareImageUrl = url;
      _uploading = false;
      if (mounted) setState(() {});
    } catch (e) {
      _uploadError = '上传图片失败';
      _uploading = false;
      if (mounted) setState(() {});
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
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          else if (_uploadError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(children: [
                Text(_uploadError!, style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
                const SizedBox(height: 12),
                _Option(icon: Icons.download_rounded, label: '保存', color: AppColors.primary, onTap: () => _save(context)),
              ]),
            )
          else
            Wrap(spacing: 16, runSpacing: 16, children: [
              if (inWechat) ...[
                _Option(icon: Icons.chat_rounded, label: '微信朋友', color: AppColors.wechatGreen, onTap: () => _shareToFriend(context)),
                _Option(icon: Icons.circle_rounded, label: '朋友圈', color: AppColors.shareBlue, onTap: () => _shareToTimeline(context)),
              ],
              _Option(icon: Icons.qr_code_rounded, label: '二维码', color: AppColors.gold, onTap: () => _showQrCode(context)),
              _Option(icon: Icons.email_rounded, label: '邮件', color: AppColors.emailRed, onTap: () => _emailShare(context)),
              _Option(icon: Icons.download_rounded, label: '保存', color: AppColors.primary, onTap: () => _save(context)),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已配置微信分享，点击右上角菜单分享'), backgroundColor: AppColors.success));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已配置朋友圈分享，点击右上角菜单分享'), backgroundColor: AppColors.success));
    }
  }

  void _showQrCode(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceVariant,
        title: const Text('扫码查看', style: TextStyle(color: Colors.white70, fontSize: 16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          if (_shareViewUrl.isNotEmpty)
            Container(
              width: 200, height: 200,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.all(8),
              child: QrImageView(data: _shareViewUrl, version: QrVersions.auto, eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.surface)),
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
        backgroundColor: AppColors.surfaceVariant,
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
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('邮件已发送'), backgroundColor: AppColors.success));
                }
              } else if (result['fallback'] == 'mailto') {
                EmailShareService.openMailtoFallback(email: email, subject: '有人给你寄了一张明信片', shareUrl: _shareViewUrl);
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('发送失败: ${result['message'] ?? '未知错误'}'), backgroundColor: Colors.redAccent));
                }
              }
            },
            child: const Text('发送', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _save(BuildContext context) {
    downloadBytes(widget.imageBytes, widget.filename);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存到设备'), backgroundColor: AppColors.success));
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
