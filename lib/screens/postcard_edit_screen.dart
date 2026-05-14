import 'package:flutter/material.dart';
import '../models/postcard.dart';
import '../services/api_service.dart';
import '../widgets/postcard_canvas.dart';
import '../widgets/editor_step_panel.dart';
import '../widgets/share_sheet.dart';
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
    } catch (_) {}
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
      final bytes = await ShareSheet.capture(_repaintKey);
      if (bytes == null || !mounted) return;
      await downloadBytes(bytes, 'postcard_${DateTime.now().millisecondsSinceEpoch}.png');
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
                  const Text('明信片已寄出', style: TextStyle(fontSize: 18, color: Colors.white70)),
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
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;

    // Capture the postcard image before saving
    final bytes = await ShareSheet.capture(_repaintKey);
    await _save();

    if (!mounted) return;
    setState(() => _sending = false);

    if (bytes != null) {
      ShareSheet.show(context, bytes, 'postcard_${DateTime.now().millisecondsSinceEpoch}.png');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        title: const Text('明信片设计器', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        actions: [
          IconButton(icon: _downloading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70)) : const Icon(Icons.download_rounded, color: Colors.white70), tooltip: '下载', onPressed: _downloading ? null : _download),
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7C4DFF)))
                : const Text('保存', style: TextStyle(color: Color(0xFF7C4DFF), fontWeight: FontWeight.w600)),
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
              Container(width: 1, color: const Color(0xFF1E1E36)),
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
