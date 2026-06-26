import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/postcard.dart';
import 'app_image.dart';
import 'anime_avatar_dialog.dart';

enum EditorStep { template, text, stamp, postmark }

const _stepLabels = ['模版', '文字', '邮票', '邮戳'];
const _stepIcons = [Icons.palette_outlined, Icons.text_fields, Icons.album_outlined, Icons.circle_outlined];

class EditorStepPanel extends StatelessWidget {
  final EditorStep currentStep;
  final PostcardDesign design;
  final ValueChanged<EditorStep> onStepChanged;
  final ValueChanged<PostcardDesign> onDesignChanged;
  final VoidCallback onSend;
  final bool materialsLoading;

  const EditorStepPanel({
    super.key,
    required this.currentStep,
    required this.design,
    required this.onStepChanged,
    required this.onDesignChanged,
    required this.onSend,
    this.materialsLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.panelDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildStepIndicator(),
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: AppColors.divider),
          Expanded(
            child: IndexedStack(
              index: currentStep.index,
              children: [
                _TemplateStep(design: design, onUpdate: (fn) => _update(fn), onNavigate: onStepChanged, loading: materialsLoading),
                _TextStep(design: design, onUpdate: (fn) => _update(fn), onNavigate: onStepChanged),
                _StampStep(design: design, onUpdate: (fn) => _update(fn), onNavigate: onStepChanged, loading: materialsLoading),
                _PostmarkStep(design: design, onUpdate: (fn) => _update(fn), onNavigate: onStepChanged, onSend: onSend, loading: materialsLoading),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _update(void Function(PostcardDesign d) fn) {
    final d = design.copyWith();
    fn(d);
    onDesignChanged(d);
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final step = EditorStep.values[i];
        final active = currentStep.index >= i;
        final current = currentStep == step;
        return GestureDetector(
          onTap: () => onStepChanged(step),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(children: [
              Container(
                width: current ? 38 : 30,
                height: current ? 38 : 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: current ? AppColors.primary : active ? AppColors.primary.withOpacity(0.25) : AppColors.divider,
                  border: Border.all(color: current ? AppColors.primaryLight : active ? AppColors.primary.withOpacity(0.4) : AppColors.inputFill, width: 1.5),
                ),
                child: Icon(_stepIcons[i], size: current ? 19 : 15, color: current ? Colors.white : Colors.white38),
              ),
              const SizedBox(height: 4),
              Text(_stepLabels[i], style: TextStyle(fontSize: 10, color: current ? AppColors.primary : Colors.white30, fontWeight: current ? FontWeight.w600 : FontWeight.normal)),
            ]),
          ),
        );
      }),
    );
  }
}

// ======== Step 1: Template + Theme ========

class _TemplateStep extends StatefulWidget {
  final PostcardDesign design;
  final void Function(void Function(PostcardDesign d)) onUpdate;
  final ValueChanged<EditorStep> onNavigate;
  final bool loading;

  const _TemplateStep({required this.design, required this.onUpdate, required this.onNavigate, this.loading = false});

  @override
  State<_TemplateStep> createState() => _TemplateStepState();
}

class _TemplateStepState extends State<_TemplateStep> {
  String _activeGroup = '全部';

  @override
  void didUpdateWidget(covariant _TemplateStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncGroup();
  }

  @override
  void initState() {
    super.initState();
    _syncGroup();
  }

  void _syncGroup() {
    final templates = widget.design.templates;
    if (templates.isEmpty) return;
    // Build unique group list
    final groups = <String>{};
    for (final t in templates) {
      groups.add(t.templateGroup);
    }
    // Auto-select group of the currently selected template
    final selectedId = widget.design.templateId;
    if (selectedId.isNotEmpty) {
      for (final t in templates) {
        if (t.id == selectedId) {
          final g = t.templateGroup;
          if (_activeGroup != '全部' && _activeGroup != g) {
            _activeGroup = g;
          }
          break;
        }
      }
    }
    // If active group no longer exists, reset
    if (_activeGroup != '全部' && !groups.contains(_activeGroup)) {
      _activeGroup = groups.isNotEmpty ? groups.first : '全部';
    }
  }

  List<PostcardTemplate> get _filteredTemplates {
    final templates = widget.design.templates;
    if (_activeGroup == '全部') return templates;
    return templates.where((t) => t.templateGroup == _activeGroup).toList();
  }

  List<String> get _groups {
    final groups = <String>{};
    for (final t in widget.design.templates) {
      groups.add(t.templateGroup);
    }
    final allGroups = groups.toList();
    // Sort by groupOrder from config
    final order = widget.design.groupOrder;
    if (order.isNotEmpty) {
      allGroups.sort((a, b) {
        final ai = order.indexOf(a);
        final bi = order.indexOf(b);
        final aIdx = ai >= 0 ? ai : 9999;
        final bIdx = bi >= 0 ? bi : 9999;
        return aIdx.compareTo(bIdx);
      });
    }
    return ['全部', ...allGroups];
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups;
    final filtered = _filteredTemplates;
    final showGroups = groups.length > 2; // "全部" + at least 2 groups

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        const Text('选择模版', style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        // Group tabs
        if (showGroups)
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: groups.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final g = groups[i];
                final active = _activeGroup == g;
                return GestureDetector(
                  onTap: () => setState(() => _activeGroup = g),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: active ? AppColors.primary : Colors.transparent,
                      border: Border.all(color: active ? AppColors.primary : Colors.white24),
                    ),
                    child: Text(
                      g,
                      style: TextStyle(
                        fontSize: 12,
                        color: active ? Colors.white : Colors.white60,
                        fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        if (showGroups) const SizedBox(height: 10),
        // Template list
        if (widget.loading && widget.design.templates.isEmpty)
          const SizedBox(
            height: 56,
            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))),
          )
        else
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final t = filtered[i];
                final sel = widget.design.templateId == t.id;
                return GestureDetector(
                  onTap: () => widget.onUpdate((d) { d.templateId = t.id; }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 76,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(colors: t.gradientColors),
                      border: Border.all(color: sel ? AppColors.primary : Colors.white10, width: sel ? 2 : 1),
                      boxShadow: sel ? [BoxShadow(color: AppColors.primary.withOpacity(0.25), blurRadius: 8)] : null,
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      if (t.imageUrl != null && t.imageUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: AppImage(url: t.imageUrl, width: 76, height: 34, fit: BoxFit.cover, thumbnailSize: 'thumb', errorWidget: () => Icon(Icons.style, size: 16, color: Colors.black45)),
                        )
                      else
                        Icon(Icons.style, size: 16, color: Colors.black45),
                      const SizedBox(height: 2),
                      Text(t.name, style: TextStyle(fontSize: 10, color: Colors.black87, fontWeight: FontWeight.w500)),
                    ]),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 20),
        Align(alignment: Alignment.centerRight, child: _nextBtn(() => widget.onNavigate(EditorStep.text))),
        const SizedBox(height: 16),
      ]),
    );
  }
}

// ======== Step 2: Text ========

class _TextStep extends StatefulWidget {
  final PostcardDesign design;
  final void Function(void Function(PostcardDesign d)) onUpdate;
  final ValueChanged<EditorStep> onNavigate;

  const _TextStep({required this.design, required this.onUpdate, required this.onNavigate});

  @override
  State<_TextStep> createState() => _TextStepState();
}

class _TextStepState extends State<_TextStep> {
  late TextEditingController _toCtrl, _fromCtrl, _msgCtrl;

  @override
  void initState() {
    super.initState();
    _toCtrl = TextEditingController(text: widget.design.toName);
    _toCtrl.addListener(_sync);
    _fromCtrl = TextEditingController(text: widget.design.fromName);
    _fromCtrl.addListener(_sync);
    _msgCtrl = TextEditingController(text: widget.design.message);
    _msgCtrl.addListener(_sync);
  }

  void _sync() {
    widget.onUpdate((d) { d.toName = _toCtrl.text; d.fromName = _fromCtrl.text; d.message = _msgCtrl.text; });
  }

  @override
  void dispose() { _toCtrl.dispose(); _fromCtrl.dispose(); _msgCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final tpl = widget.design.template;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        const Text('填写收寄人', style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        Row(children: [
          Container(width: 42, child: Text('收件人', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tpl.toColor))),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: _toCtrl, decoration: const InputDecoration(hintText: '收件人名字', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)), style: const TextStyle(fontSize: 14, color: Colors.white))),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Container(width: 42, child: Text('寄件人', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tpl.fromColor))),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: _fromCtrl, decoration: const InputDecoration(hintText: '寄件人名字', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)), style: const TextStyle(fontSize: 14, color: Colors.white))),
        ]),
        const SizedBox(height: 18),
        const Text('祝福语', style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        TextField(controller: _msgCtrl, maxLines: 3, decoration: const InputDecoration(hintText: '写下你想说的话…', contentPadding: EdgeInsets.all(12)), style: const TextStyle(fontSize: 14, color: Colors.white)),
        const SizedBox(height: 20),
        Row(children: [_prevBtn(() => widget.onNavigate(EditorStep.template)), const Spacer(), _nextBtn(() => widget.onNavigate(EditorStep.stamp))]),
        const SizedBox(height: 16),
      ]),
    );
  }
}

// ======== Step 3: Stamp ========

class _StampStep extends StatelessWidget {
  final PostcardDesign design;
  final void Function(void Function(PostcardDesign d)) onUpdate;
  final ValueChanged<EditorStep> onNavigate;
  final bool loading;

  const _StampStep({required this.design, required this.onUpdate, required this.onNavigate, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        Row(children: [
          const Text('选择邮票', style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500)),
          const Spacer(),
          if (design.stampId != null || design.hasCustomStamp)
            TextButton(onPressed: () => onUpdate((d) { d.stampId = null; d.customStampImageUrl = null; }), child: const Text('移除', style: TextStyle(fontSize: 12, color: Colors.white38))),
        ]),
        const SizedBox(height: 10),
        // AI anime avatar button
        if (design.hasCustomStamp)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.primary.withOpacity(0.3))),
            child: Row(children: [
              const Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              const Expanded(child: Text('AI 动漫头像已生成', style: TextStyle(fontSize: 12, color: AppColors.primary))),
              TextButton(onPressed: () async {
                final url = await AnimeAvatarDialog.show(context);
                if (url != null) onUpdate((d) { d.customStampImageUrl = url; d.stampId = null; });
              }, child: const Text('重新生成', style: TextStyle(fontSize: 11, color: AppColors.primary))),
            ]),
          )
        else
          GestureDetector(
            onTap: () async {
              final url = await AnimeAvatarDialog.show(context);
              if (url != null) onUpdate((d) { d.customStampImageUrl = url; d.stampId = null; });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1, strokeAlign: BorderSide.strokeAlignOutside), borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                const Text('AI 动漫头像', style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500)),
                const SizedBox(width: 6),
                const Text('上传照片生成动漫邮票', style: TextStyle(fontSize: 11, color: Colors.white30)),
              ]),
            ),
          ),
        const SizedBox(height: 10),
        if (loading && design.stamps.isEmpty)
          const SizedBox(
            height: 136,
            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))),
          )
        else
          SizedBox(
            height: 136,
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.85),
              itemCount: design.stamps.length,
              itemBuilder: (_, i) {
                final s = design.stamps[i];
                final sel = design.stampId == s.id;
                return GestureDetector(
                  onTap: () => onUpdate((d) { d.stampId = s.id; }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: sel ? s.accentColor : Colors.white10, width: sel ? 2 : 1),
                      boxShadow: sel ? [BoxShadow(color: s.accentColor.withOpacity(0.25), blurRadius: 8)] : null,
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      if (s.imageUrl != null && s.imageUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: AppImage(url: s.imageUrl, width: 40, height: 40, fit: BoxFit.cover, thumbnailSize: 'thumb', errorWidget: () => Text(s.emoji, style: TextStyle(fontSize: sel ? 32 : 28))),
                        )
                      else
                        Text(s.emoji, style: TextStyle(fontSize: sel ? 32 : 28)),
                      const SizedBox(height: 4),
                      Text(s.label, style: TextStyle(fontSize: 10, color: sel ? Colors.white : Colors.white54)),
                    ]),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 16),
        Row(children: [_prevBtn(() => onNavigate(EditorStep.text)), const Spacer(), _nextBtn(() => onNavigate(EditorStep.postmark))]),
        const SizedBox(height: 16),
      ]),
    );
  }
}

// ======== Step 4: Postmark & Send ========

class _PostmarkStep extends StatelessWidget {
  final PostcardDesign design;
  final void Function(void Function(PostcardDesign d)) onUpdate;
  final ValueChanged<EditorStep> onNavigate;
  final VoidCallback onSend;
  final bool loading;

  const _PostmarkStep({required this.design, required this.onUpdate, required this.onNavigate, required this.onSend, this.loading = false});

  bool get _canSend => design.stampId != null && design.postmarkId != null;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        const Text('选择邮戳', style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        if (loading && design.postmarks.isEmpty)
          const SizedBox(
            height: 60,
            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))),
          )
        else
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: design.postmarks.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final p = design.postmarks[i];
                final sel = design.postmarkId == p.id;
                return GestureDetector(
                  onTap: () => onUpdate((d) { d.postmarkId = p.id; }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 76,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: sel ? p.color : Colors.white10, width: sel ? 2 : 1),
                    ),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      if (p.imageUrl != null && p.imageUrl!.isNotEmpty)
                        ClipRRect(borderRadius: BorderRadius.circular(8), child: AppImage(url: p.imageUrl, width: 28, height: 28, fit: BoxFit.cover, thumbnailSize: 'thumb', errorWidget: () => Icon(Icons.circle_outlined, size: 22, color: p.color)))
                      else
                        Icon(Icons.circle_outlined, size: 22, color: p.color),
                      const SizedBox(height: 2),
                      Text(p.label, style: TextStyle(fontSize: 10, color: sel ? Colors.white : Colors.white54)),
                    ]),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 28),
        Row(children: [
          _prevBtn(() => onNavigate(EditorStep.stamp)),
          const Spacer(),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: _canSend ? onSend : null,
              icon: const Icon(Icons.send_rounded, size: 18),
              label: Text(_canSend ? '发送明信片' : '请选择邮票和邮戳'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.inputFill,
                disabledForegroundColor: Colors.white38,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 16),
      ]),
    );
  }
}

// ======== Common nav buttons ========

Widget _nextBtn(VoidCallback onTap) {
  return ElevatedButton(
    onPressed: onTap,
    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10)),
    child: const Text('下一步', style: TextStyle(fontWeight: FontWeight.w500)),
  );
}

Widget _prevBtn(VoidCallback onTap) {
  return OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(foregroundColor: Colors.white54, side: const BorderSide(color: AppColors.outline), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10)),
    child: const Text('上一步'),
  );
}
