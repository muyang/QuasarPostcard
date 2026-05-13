import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../models/postcard.dart';
import '../services/api_service.dart';
import '../widgets/postcard_canvas.dart';
import '../widgets/editor_step_panel.dart';
import '../utils/download_helper.dart';

class PostcardEditScreen extends StatefulWidget {
  final PostcardDesign? initialDesign;
  const PostcardEditScreen({super.key, this.initialDesign});

  @override
  State<PostcardEditScreen> createState() => _PostcardEditScreenState();
}

class _PostcardEditScreenState extends State<PostcardEditScreen> with SingleTickerProviderStateMixin {
  late PostcardDesign _design;
  EditorStep _step = EditorStep.template;
  bool _saving = false;
  bool _stampAnimating = false;
  bool _sending = false;
  bool _downloading = false;
  final _repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _design = widget.initialDesign ?? PostcardDesign();
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    try {
      final templates = await ApiService.getTemplates();
      final stamps = await ApiService.getStamps();
      final postmarks = await ApiService.getPostmarks();
      if (!mounted) return;
      setState(() {
        _design.updateMaterials(
          templates: templates.map((j) => PostcardTemplate.fromJson(j)).toList(),
          stamps: stamps.map((j) => PostcardStamp.fromJson(j)).toList(),
          postmarks: postmarks.map((j) => PostcardPostmark.fromJson(j)).toList(),
        );
      });
    } catch (_) {
      // Use hardcoded defaults
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final body = {
        'template_id': _design.templateId,
        'theme_color': _design.themeColor.value.toRadixString(16),
        'to_name': _design.toName,
        'from_name': _design.fromName,
        'message': _design.message,
        'stamp_id': _design.stampId,
        'postmark_id': _design.postmarkId,
        'image_url': _design.imageUrl,
        'status': _design.status,
      };
      if (_design.id == 0) {
        await ApiService.createPostcard(body);
      } else {
        await ApiService.updatePostcard(_design.id, body);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存成功'), backgroundColor: Color(0xFF4CAF50)));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _onStepChanged(EditorStep step) {
    setState(() { _step = step; });
    // Trigger stamp animation when entering stamp step
    if (step == EditorStep.stamp && _design.stampId != null) {
      _stampAnimating = false;
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() => _stampAnimating = true);
      });
    }
  }

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      // Delay briefly to ensure layout is complete
      await Future.delayed(const Duration(milliseconds: 100));
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null || !mounted) return;
      await downloadBytes(byteData.buffer.asUint8List(), 'postcard_${DateTime.now().millisecondsSinceEpoch}.png');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('下载完成'), backgroundColor: Color(0xFF4CAF50)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('下载失败: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Widget _buildCanvas() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: _sending
          ? Container(
              key: const ValueKey('sending'),
              color: const Color(0xFF121212),
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.send_rounded, size: 64, color: const Color(0xFF7C4DFF).withOpacity(0.6)),
                  const SizedBox(height: 16),
                  const Text('明信片已寄出 ✈️', style: TextStyle(fontSize: 18, color: Colors.white70)),
                ]),
              ),
            )
          : RepaintBoundary(
              key: _repaintKey,
              child: PostcardCanvas(
                key: const ValueKey('canvas'),
                design: _design,
                showStampAnimation: _stampAnimating,
              ),
            ),
    );
  }

  Future<void> _onSend() async {
    setState(() => _sending = true);
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    await _save();
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('明信片设计器'),
        actions: [
          IconButton(icon: _downloading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.download_rounded), tooltip: '下载明信片', onPressed: _downloading ? null : _download),
          const SizedBox(width: 4),
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('保存', style: TextStyle(color: Color(0xFF7C4DFF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;
          final canvas = _buildCanvas();
          final panel = EditorStepPanel(
            currentStep: _step,
            design: _design,
            onStepChanged: _onStepChanged,
            onDesignChanged: (d) => setState(() => _design = d),
            onSend: _onSend,
          );
          if (isWide) {
            return Row(children: [
              Expanded(flex: 6, child: canvas),
              const VerticalDivider(width: 1, color: Color(0xFF2A2A4A)),
              Expanded(flex: 4, child: panel),
            ]);
          }
          return Column(children: [
            Expanded(flex: 11, child: canvas),
            Expanded(flex: 9, child: panel),
          ]);
        },
      ),
    );
  }
}
