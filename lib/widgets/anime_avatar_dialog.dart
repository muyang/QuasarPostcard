import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_service.dart';

/// Dialog for uploading a portrait photo and generating an anime-style avatar.
/// The result image URL is returned as a stamp image_url.
class AnimeAvatarDialog extends StatefulWidget {
  const AnimeAvatarDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (_) => const AnimeAvatarDialog(),
    );
  }

  @override
  State<AnimeAvatarDialog> createState() => _AnimeAvatarDialogState();
}

class _AnimeAvatarDialogState extends State<AnimeAvatarDialog> {
  Uint8List? _photoBytes;
  String? _previewUrl;
  String? _resultUrl;
  bool _processing = false;
  String? _error;

  void _pickImage() {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.onChange.listen((e) async {
      final files = input.files;
      if (files == null || files.isEmpty) return;
      final reader = html.FileReader();
      reader.onLoadEnd.listen((_) async {
        final bytes = Uint8List.fromList(reader.result as List<int>);
        setState(() {
          _photoBytes = bytes;
          _previewUrl = html.Url.createObjectUrlFromBlob(files[0]);
          _resultUrl = null;
          _error = null;
        });
      });
      reader.readAsArrayBuffer(files[0]);
    });
    input.click();
  }

  Future<void> _generate() async {
    if (_photoBytes == null) return;
    setState(() { _processing = true; _error = null; });

    try {
      final b64 = base64Encode(_photoBytes!);
      final result = await ApiService.animeFace(b64);
      if (result != null) {
        setState(() {
          _resultUrl = result;
          _processing = false;
        });
      } else {
        setState(() {
          _error = 'AI 生成失败，请重试';
          _processing = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _processing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 420,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Icon(Icons.auto_awesome, color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                const Text('AI 动漫头像', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
              ]),

              const SizedBox(height: 20),

              // Photo preview / result
              Container(
                width: 200, height: 200,
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outline),
                ),
                child: _processing
                    ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        SizedBox(width: 32, height: 32, child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 3)),
                        SizedBox(height: 12),
                        Text('正在生成动漫头像…', style: TextStyle(fontSize: 12, color: Colors.white54)),
                      ]))
                    : _resultUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              '${ApiService.baseUrl}$_resultUrl',
                              width: 200, height: 200, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 48, color: Colors.white30),
                            ),
                          )
                        : _previewUrl != null
                            ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(_previewUrl!, width: 200, height: 200, fit: BoxFit.cover))
                            : GestureDetector(
                                onTap: _pickImage,
                                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Icon(Icons.cloud_upload, size: 40, color: Colors.white.withOpacity(0.3)),
                                  const SizedBox(height: 8),
                                  const Text('点击上传人像照片', style: TextStyle(fontSize: 12, color: Colors.white38)),
                                ]),
                              ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(fontSize: 12, color: Colors.redAccent), textAlign: TextAlign.center),
              ],

              const SizedBox(height: 20),

              // Action buttons
              Row(children: [
                if (_photoBytes != null && _resultUrl == null && !_processing)
                  TextButton(onPressed: _pickImage, child: const Text('重新选图', style: TextStyle(color: Colors.white54))),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消', style: TextStyle(color: Colors.white54)),
                ),
                if (_resultUrl != null)
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, _resultUrl),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                    child: const Text('用作邮票'),
                  )
                else if (_photoBytes != null && !_processing)
                  ElevatedButton.icon(
                    onPressed: _generate,
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: const Text('生成'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
