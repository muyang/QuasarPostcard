import 'package:flutter/material.dart';
import '../models/postcard.dart';
import '../services/api_service.dart';

enum EditorStep { template, text, stamp, postmark }

const _stepLabels = ['模版', '文字', '邮票', '邮戳'];
const _stepIcons = [Icons.palette_outlined, Icons.text_fields, Icons.album_outlined, Icons.circle_outlined];

class EditorStepPanel extends StatelessWidget {
  final EditorStep currentStep;
  final PostcardDesign design;
  final ValueChanged<EditorStep> onStepChanged;
  final ValueChanged<PostcardDesign> onDesignChanged;
  final VoidCallback onSend;

  const EditorStepPanel({
    super.key,
    required this.currentStep,
    required this.design,
    required this.onStepChanged,
    required this.onDesignChanged,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF13132B),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _buildStepIndicator(),
          ),
          const SizedBox(height: 8),
          Container(height: 1, color: const Color(0xFF1E1E3A)),
          Expanded(
            child: IndexedStack(
              index: currentStep.index,
              children: [
                _TemplateStep(design: design, onUpdate: (fn) => _update(fn), onNavigate: onStepChanged),
                _TextStep(design: design, onUpdate: (fn) => _update(fn), onNavigate: onStepChanged),
                _StampStep(design: design, onUpdate: (fn) => _update(fn), onNavigate: onStepChanged),
                _PostmarkStep(design: design, onUpdate: (fn) => _update(fn), onNavigate: onStepChanged, onSend: onSend),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _update(void Function(PostcardDesign d) fn) {
    final d = PostcardDesign(
      templateId: design.templateId,
      themeColor: design.themeColor,
      toName: design.toName,
      fromName: design.fromName,
      message: design.message,
      stampId: design.stampId,
      postmarkId: design.postmarkId,
      imageUrl: design.imageUrl,
      id: design.id,
      status: design.status,
    );
    d.updateMaterials(templates: design.templates, stamps: design.stamps, postmarks: design.postmarks);
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
                  color: current ? const Color(0xFF7C4DFF) : active ? const Color(0xFF7C4DFF).withOpacity(0.25) : const Color(0xFF1E1E3A),
                  border: Border.all(color: current ? const Color(0xFF9B7BFF) : active ? const Color(0xFF7C4DFF).withOpacity(0.4) : const Color(0xFF2A2A4A), width: 1.5),
                ),
                child: Icon(_stepIcons[i], size: current ? 19 : 15, color: current ? Colors.white : Colors.white38),
              ),
              const SizedBox(height: 4),
              Text(_stepLabels[i], style: TextStyle(fontSize: 10, color: current ? const Color(0xFF7C4DFF) : Colors.white30, fontWeight: current ? FontWeight.w600 : FontWeight.normal)),
            ]),
          ),
        );
      }),
    );
  }
}

// ======== Step 1: Template + Theme ========

class _TemplateStep extends StatelessWidget {
  final PostcardDesign design;
  final void Function(void Function(PostcardDesign d)) onUpdate;
  final ValueChanged<EditorStep> onNavigate;

  const _TemplateStep({required this.design, required this.onUpdate, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        const Text('选择模版', style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: design.templates.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final t = design.templates[i];
              final sel = design.templateId == t.id;
              return GestureDetector(
                onTap: () => onUpdate((d) { d.templateId = t.id; }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 76,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(colors: t.gradientColors),
                    border: Border.all(color: sel ? const Color(0xFF7C4DFF) : Colors.white10, width: sel ? 2 : 1),
                    boxShadow: sel ? [BoxShadow(color: const Color(0xFF7C4DFF).withOpacity(0.25), blurRadius: 8)] : null,
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    if (t.imageUrl != null && t.imageUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(ApiService.imageUrl(t.imageUrl), width: 76, height: 34, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.style, size: 16, color: Colors.black45)),
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
        const SizedBox(height: 18),
        const Text('主题色', style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: THEME_COLORS.map((tc) {
            final sel = design.themeColor.value == tc.color.value;
            return GestureDetector(
              onTap: () => onUpdate((d) { d.themeColor = tc.color; }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: sel ? 32 : 26, height: sel ? 32 : 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, color: tc.color,
                  border: sel ? Border.all(color: Colors.white, width: 2.5) : null,
                  boxShadow: sel ? [BoxShadow(color: tc.color.withOpacity(0.4), blurRadius: 10)] : null,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        Align(alignment: Alignment.centerRight, child: _nextBtn(() => onNavigate(EditorStep.text))),
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
          Container(width: 28, child: Text('To:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: tpl.toColor))),
          const SizedBox(width: 8),
          Expanded(child: TextField(controller: _toCtrl, decoration: const InputDecoration(hintText: '收件人名字', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)), style: const TextStyle(fontSize: 14, color: Colors.white))),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Container(width: 28, child: Text('From:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tpl.fromColor))),
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

  const _StampStep({required this.design, required this.onUpdate, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        Row(children: [
          const Text('选择邮票', style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500)),
          const Spacer(),
          if (design.stampId != null)
            TextButton(onPressed: () => onUpdate((d) { d.stampId = null; }), child: const Text('移除', style: TextStyle(fontSize: 12, color: Colors.white38))),
        ]),
        const SizedBox(height: 10),
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
                    color: const Color(0xFF1E1E36), borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sel ? s.accentColor : Colors.white10, width: sel ? 2 : 1),
                    boxShadow: sel ? [BoxShadow(color: s.accentColor.withOpacity(0.25), blurRadius: 8)] : null,
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    if (s.imageUrl != null && s.imageUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(ApiService.imageUrl(s.imageUrl), width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Text(s.emoji, style: TextStyle(fontSize: sel ? 32 : 28))),
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

  const _PostmarkStep({required this.design, required this.onUpdate, required this.onNavigate, required this.onSend});

  bool get _canSend => design.stampId != null && design.postmarkId != null;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        const Text('选择邮戳', style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),
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
                    color: const Color(0xFF1E1E36), borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sel ? p.color : Colors.white10, width: sel ? 2 : 1),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    if (p.imageUrl != null && p.imageUrl!.isNotEmpty)
                      ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(ApiService.imageUrl(p.imageUrl), width: 28, height: 28, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.circle_outlined, size: 22, color: p.color)))
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
                backgroundColor: const Color(0xFF7C4DFF),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF2A2A4A),
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
    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C4DFF), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10)),
    child: const Text('下一步', style: TextStyle(fontWeight: FontWeight.w500)),
  );
}

Widget _prevBtn(VoidCallback onTap) {
  return OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(foregroundColor: Colors.white54, side: const BorderSide(color: Color(0xFF333355)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10)),
    child: const Text('上一步'),
  );
}
