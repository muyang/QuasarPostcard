import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
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
  bool _materialsLoading = true;
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
      final results = await Future.wait([
        ApiService.getTemplates(),
        ApiService.getStamps(),
        ApiService.getPostmarks(),
        ApiService.getConfig(),
      ]);
      if (!mounted) return;
      final templates = results[0] as List<Map<String, dynamic>>;
      final stamps = results[1] as List<Map<String, dynamic>>;
      final postmarks = results[2] as List<Map<String, dynamic>>;
      final config = results[3] as Map<String, dynamic>?;

      setState(() {
        final tplList = templates.map((j) => PostcardTemplate.fromJson(j)).toList();
        final stampList = stamps.map((j) => PostcardStamp.fromJson(j)).toList();
        final pmkList = postmarks.map((j) => PostcardPostmark.fromJson(j)).toList();
        final groupOrder = config != null && config['group_order'] is List
            ? List<String>.from(config['group_order'])
            : <String>[];
        _design.updateMaterials(
          templates: tplList,
          stamps: stampList,
          postmarks: pmkList,
          groupOrder: groupOrder,
        );

        // Apply defaults for new designs
        if (widget.initialDesign == null && config != null) {
          final defTpl = config['default_template'] as String? ?? '';
          final defStamp = config['default_stamp'] as String? ?? '';
          final defPmk = config['default_postmark'] as String? ?? '';
          if (defTpl.isNotEmpty && tplList.any((t) => t.id == defTpl)) {
            _design.templateId = defTpl;
          }
          if (defStamp.isNotEmpty && stampList.any((s) => s.id == defStamp)) {
            _design.stampId = defStamp;
          }
          if (defPmk.isNotEmpty && pmkList.any((p) => p.id == defPmk)) {
            _design.postmarkId = defPmk;
          }
        }

        _materialsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _materialsLoading = false);
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
        'custom_stamp_image_url': _design.customStampImageUrl,
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存成功'), backgroundColor: AppColors.success));
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

  Future<void> _sharePostcard() async {
    final bytes = await ShareSheet.capture(_repaintKey);
    if (bytes == null || !mounted) return;
    ShareSheet.show(context, bytes, 'postcard_${DateTime.now().millisecondsSinceEpoch}.png');
  }

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      final bytes = await ShareSheet.capture(_repaintKey);
      if (bytes == null || !mounted) return;
      await downloadBytes(bytes, 'postcard_${DateTime.now().millisecondsSinceEpoch}.png');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('下载完成'), backgroundColor: AppColors.success));
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
              color: AppColors.scaffoldBackground,
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.send_rounded, size: 64, color: AppColors.primary.withOpacity(0.6)),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('明信片设计器', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        actions: [
          IconButton(icon: _downloading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70)) : const Icon(Icons.share_rounded, color: Colors.white70), tooltip: '分享', onPressed: _downloading ? null : _sharePostcard),
          IconButton(icon: _downloading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70)) : const Icon(Icons.download_rounded, color: Colors.white70), tooltip: '下载', onPressed: _downloading ? null : _download),
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                : const Text('保存', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
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
            materialsLoading: _materialsLoading,
          );
          if (isWide) {
            return Row(children: [
              Expanded(flex: 6, child: canvas),
              Container(width: 1, color: AppColors.surfaceVariant),
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
