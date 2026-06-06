import 'package:flutter/material.dart';
import '../models/postcard.dart';
import '../services/api_service.dart';
import '../widgets/app_image.dart';
import 'postcard_edit_screen.dart';

class PostcardListScreen extends StatefulWidget {
  const PostcardListScreen({super.key});

  @override
  State<PostcardListScreen> createState() => _PostcardListScreenState();
}

class _PostcardListScreenState extends State<PostcardListScreen> {
  List<PostcardDesign> _postcards = [];
  List<PostcardTemplate> _templates = [];
  List<PostcardStamp> _stamps = [];
  List<PostcardPostmark> _postmarks = [];
  bool _loading = true;
  String? _error;
  int _columns = 2;
  bool _selecting = false;
  final Set<int> _selectedIds = {};
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _loadMaterials() async {
    try {
      final templates = await ApiService.getTemplates();
      final stamps = await ApiService.getStamps();
      final postmarks = await ApiService.getPostmarks();
      if (!mounted) return;
      setState(() {
        _templates = templates.map((j) => PostcardTemplate.fromJson(j)).toList();
        _stamps = stamps.map((j) => PostcardStamp.fromJson(j)).toList();
        _postmarks = postmarks.map((j) => PostcardPostmark.fromJson(j)).toList();
      });
    } catch (_) {}
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      await _loadMaterials();
      final data = await ApiService.getPostcards(skip: 0, limit: 100);
      final cards = (data['cards'] as List?) ?? [];
      final list = <PostcardDesign>[];
      for (final c in cards) {
        if (c is Map<String, dynamic>) {
          final d = PostcardDesign(
            templateId: c['template_id'] ?? 'floral',
            themeColor: Color(int.parse((c['theme_color'] ?? 'FFE91E63').toString(), radix: 16) | 0xFF000000),
            toName: c['to_name'] ?? '',
            fromName: c['from_name'] ?? '',
            message: c['message'] ?? '',
            stampId: c['stamp_id'],
            postmarkId: c['postmark_id'],
            imageUrl: c['image_url'],
            id: c['id'] ?? 0,
            status: c['status'] ?? 'PENDING',
          );
          d.updateMaterials(templates: _templates, stamps: _stamps, postmarks: _postmarks);
          list.add(d);
        }
      }
      setState(() { _postcards = list; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _createNew() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PostcardEditScreen())).then((_) => _load());
  }

  void _editPostcard(PostcardDesign design) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => PostcardEditScreen(initialDesign: design))).then((_) => _load());
  }

  void _toggleSelectMode() {
    setState(() {
      _selecting = !_selecting;
      if (!_selecting) _selectedIds.clear();
    });
  }

  void _toggleSelect(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _batchDelete() async {
    if (_selectedIds.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('确认删除', style: TextStyle(color: Colors.white70, fontSize: 16)),
        content: Text('确定要删除选中的 ${_selectedIds.length} 张明信片吗？\n此操作不可撤销。', style: const TextStyle(color: Colors.white54, fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消', style: TextStyle(color: Colors.white38))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除', style: TextStyle(color: Color(0xFFC62828)))),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      final deleted = await ApiService.batchDeletePostcards(_selectedIds.toList());
      if (!mounted) return;
      _selectedIds.clear();
      _selecting = false;
      await _load();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已删除 $deleted 张明信片'), backgroundColor: const Color(0xFF4CAF50)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('删除失败: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: _selecting ? const Color(0xFF1A1030) : const Color(0xFF0D0D1A),
        title: _selecting
            ? Text('已选 ${_selectedIds.length} 项', style: const TextStyle(fontSize: 16, color: Color(0xFF7C4DFF)))
            : const Text('明信片', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300, letterSpacing: 1)),
        actions: _selecting
            ? [
                if (_deleting)
                  const Center(child: Padding(padding: EdgeInsets.only(right: 12), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFC62828))))),
                IconButton(icon: const Icon(Icons.delete_outline, color: Color(0xFFC62828)), tooltip: '删除选中', onPressed: _deleting ? null : _batchDelete),
                IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: _toggleSelectMode),
              ]
            : [
                if (_postcards.isNotEmpty)
                  IconButton(icon: const Icon(Icons.checklist_rounded, color: Colors.white54), tooltip: '选择', onPressed: _toggleSelectMode),
                IconButton(icon: Icon(_columns == 1 ? Icons.grid_view_rounded : Icons.view_agenda_rounded, color: Colors.white54), tooltip: _columns == 1 ? '网格' : '列表', onPressed: () => setState(() => _columns = _columns == 1 ? 2 : 1)),
                if (_postcards.isNotEmpty)
                  Center(child: Padding(padding: const EdgeInsets.only(right: 8), child: Text('${_postcards.length}', style: const TextStyle(fontSize: 13, color: Color(0xFF555577))))),
                IconButton(icon: const Icon(Icons.refresh, color: Colors.white54), onPressed: _load),
              ],
      ),
      body: _buildBody(),
      floatingActionButton: _selecting
          ? null
          : FloatingActionButton(
              backgroundColor: const Color(0xFF7C4DFF),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onPressed: _createNew,
              child: const Icon(Icons.add, size: 28),
            ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Color(0xFF7C4DFF)));
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.cloud_off, size: 48, color: Colors.white.withOpacity(0.15)),
        const SizedBox(height: 12),
        Text(_error!, style: const TextStyle(color: Color(0xFF666688), fontSize: 13), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        OutlinedButton(onPressed: _load, style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF7C4DFF), side: const BorderSide(color: Color(0xFF333355)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))), child: const Text('重试')),
      ]));
    }
    if (_postcards.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.mail_outline, size: 64, color: Colors.white.withOpacity(0.08)),
        const SizedBox(height: 16),
        const Text('还没有明信片', style: TextStyle(color: Color(0xFF555577), fontSize: 15)),
        const SizedBox(height: 4),
        const Text('点击下方按钮创建第一张', style: TextStyle(color: Color(0xFF444466), fontSize: 12)),
      ]));
    }
    return RefreshIndicator(
      color: const Color(0xFF7C4DFF),
      onRefresh: _load,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = _columns == 1 ? 1 : constraints.maxWidth >= 1200 ? 4 : constraints.maxWidth >= 800 ? 3 : 2;
          if (crossAxisCount == 1) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _postcards.length,
              itemBuilder: (_, i) => Padding(padding: const EdgeInsets.only(bottom: 14), child: AspectRatio(aspectRatio: PostcardDesign.aspectRatio, child: _buildTile(_postcards[i]))),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: crossAxisCount, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: PostcardDesign.aspectRatio),
            itemCount: _postcards.length,
            itemBuilder: (_, i) => _buildTile(_postcards[i]),
          );
        },
      ),
    );
  }

  static const double _tileW = 420.0;
  static const double _tileH = 270.0;

  Widget _buildTile(PostcardDesign d) {
    final t = d.template;
    final stamp = d.stamp;
    final postmark = d.postmark;
    final isSelected = _selectedIds.contains(d.id);
    return GestureDetector(
      onTap: () => _selecting ? _toggleSelect(d.id) : _editPostcard(d),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final s = w / _tileW;
          return Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14 * s),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6 * s, offset: Offset(0, 3 * s))],
              border: isSelected ? Border.all(color: const Color(0xFF7C4DFF), width: 2.5 * s) : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14 * s),
              child: FittedBox(
                fit: BoxFit.fill,
                child: SizedBox(
                  width: _tileW,
                  height: _tileH,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: t.gradientColors),
                    ),
                    child: Stack(children: [
                      if (t.imageUrl != null && t.imageUrl!.isNotEmpty)
                        Positioned.fill(child: AppImage(url: t.imageUrl, fit: BoxFit.cover, thumbnailSize: 'small')),
                      // Postmark
                      if (postmark != null)
                        _tilePostmark(postmark, t),
                      // Stamp
                      if (stamp != null)
                        _tileStamp(stamp, t),
                      // To field
                      _tileTextField('收件人', d.toName, t.toColor, t.toFont, t.toSize, t.toX, t.toY, t.toW, t.toH, d.toName.isEmpty),
                      // From field
                      _tileTextField('寄件人', d.fromName, t.fromColor, t.fromFont, t.fromSize, t.fromX, t.fromY, t.fromW, t.fromH, d.fromName.isEmpty),
                      // Message
                      _tileMessage(t, d.message),
                      // Selection overlay
                      if (_selecting)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? const Color(0xFF7C4DFF) : Colors.black.withOpacity(0.35),
                              border: Border.all(color: isSelected ? const Color(0xFF7C4DFF) : Colors.white.withOpacity(0.5), width: 2),
                            ),
                            child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                          ),
                        ),
                    ]),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _tileStamp(PostcardStamp stamp, PostcardTemplate t) {
    final stScl = t.stampScale / 100;
    final stW = 52.0 * stScl;
    final stH = 62.0 * stScl;
    return Positioned(
      left: _tileW * t.stampX / 100,
      top: _tileH * t.stampY / 100,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: stamp.imageUrl != null && stamp.imageUrl!.isNotEmpty
            ? ClipRRect(borderRadius: BorderRadius.circular(2), child: AppImage(url: stamp.imageUrl, width: stW, height: stH, fit: BoxFit.cover, thumbnailSize: 'small', errorWidget: () => Center(child: Text(stamp.emoji, style: TextStyle(fontSize: 10 * stScl)))))
            : Text(stamp.emoji, style: TextStyle(fontSize: 14 * stScl)),
      ),
    );
  }

  Widget _tilePostmark(PostcardPostmark postmark, PostcardTemplate t) {
    final pmkScl = t.postmarkScale / 100;
    final pmkSize = 72.0 * pmkScl;
    return Positioned(
      left: _tileW * t.postmarkX / 100,
      top: _tileH * t.postmarkY / 100,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: postmark.imageUrl != null && postmark.imageUrl!.isNotEmpty
            ? AppImage(url: postmark.imageUrl, width: pmkSize, height: pmkSize, fit: BoxFit.contain, thumbnailSize: 'small', errorWidget: () => _tilePostmarkCircle(postmark, pmkSize))
            : _tilePostmarkCircle(postmark, pmkSize),
      ),
    );
  }

  Widget _tilePostmarkCircle(PostcardPostmark postmark, double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: postmark.color.withOpacity(0.4), width: 1.5)),
      child: Center(child: Text(postmark.dateText, style: TextStyle(fontSize: 8, color: postmark.color.withOpacity(0.6), fontWeight: FontWeight.w600))),
    );
  }

  Widget _tileTextField(String placeholder, String name, Color color, String fontFamily, double fontSize, double xPct, double yPct, double boxW, double boxH, bool isEmpty) {
    return Positioned(
      left: _tileW * xPct / 100,
      top: _tileH * yPct / 100,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: Container(
          width: boxW,
          height: boxH,
          decoration: BoxDecoration(
            border: isEmpty ? Border.all(color: color.withOpacity(0.2), width: 0.8) : null,
            borderRadius: BorderRadius.circular(3),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          alignment: Alignment.centerLeft,
          child: isEmpty
              ? Text(placeholder, style: TextStyle(fontSize: fontSize, color: color.withOpacity(0.25), fontFamily: fontFamily))
              : Text(name, style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500, color: color, fontFamily: fontFamily)),
        ),
      ),
    );
  }

  Widget _tileMessage(PostcardTemplate t, String message) {
    return Positioned(
      left: _tileW * t.messageX / 100,
      top: _tileH * t.messageY / 100,
      width: _tileW * t.messageW / 100,
      height: t.messageH,
      child: Container(
        padding: const EdgeInsets.all(4),
        alignment: Alignment.topLeft,
        child: message.isNotEmpty
            ? Text(message, maxLines: null, overflow: TextOverflow.clip,
                style: TextStyle(fontSize: t.messageSize, color: t.messageColor, height: 1.5, fontStyle: FontStyle.italic, fontFamily: t.messageFont))
            : Text('祝福语', style: TextStyle(fontSize: t.messageSize, color: Colors.black26, fontStyle: FontStyle.italic, fontFamily: t.messageFont)),
      ),
    );
  }
}
