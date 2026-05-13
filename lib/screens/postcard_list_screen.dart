import 'package:flutter/material.dart';
import '../models/postcard.dart';
import '../services/api_service.dart';
import 'postcard_edit_screen.dart';

class PostcardListScreen extends StatefulWidget {
  const PostcardListScreen({super.key});

  @override
  State<PostcardListScreen> createState() => _PostcardListScreenState();
}

class _PostcardListScreenState extends State<PostcardListScreen> {
  List<PostcardDesign> _postcards = [];
  List<PostcardTemplate> _templates = POSTCARD_TEMPLATES;
  List<PostcardStamp> _stamps = POSTCARD_STAMPS;
  List<PostcardPostmark> _postmarks = POSTCARD_POSTMARKS;
  bool _loading = true;
  String? _error;
  int _columns = 2; // 1, 2, 3, 4

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('明信片设计器'),
        actions: [
          IconButton(icon: Icon(_columns == 1 ? Icons.grid_view_rounded : Icons.view_agenda_rounded), tooltip: _columns == 1 ? '网格视图' : '单列视图', onPressed: () => setState(() => _columns = _columns == 1 ? 2 : 1)),
          if (_postcards.isNotEmpty)
            Center(child: Padding(padding: const EdgeInsets.only(right: 12), child: Text('${_postcards.length} 张', style: const TextStyle(fontSize: 13, color: Color(0xFF888888))))),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(backgroundColor: const Color(0xFF7C4DFF), onPressed: _createNew, child: const Icon(Icons.add)),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
        const SizedBox(height: 8),
        Text(_error!, style: const TextStyle(color: Colors.redAccent)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _load, child: const Text('重试')),
      ]));
    }
    if (_postcards.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.mail_outline, size: 64, color: Colors.white.withOpacity(0.15)),
        const SizedBox(height: 16),
        const Text('还没有明信片\n点击右下角创建第一张', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF888888), fontSize: 14)),
      ]));
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final crossAxisCount = _columns == 1 ? 1
                               : constraints.maxWidth >= 1200 ? 4
                               : constraints.maxWidth >= 800 ? 3 : 2;
          if (crossAxisCount == 1) {
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _postcards.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AspectRatio(aspectRatio: PostcardDesign.aspectRatio, child: _buildTile(_postcards[i])),
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: _postcards.length,
            itemBuilder: (_, i) => _buildTile(_postcards[i]),
          );
        },
      ),
    );
  }

  Widget _buildTile(PostcardDesign d) {
    final t = d.template;
    final stamp = d.stamp;
    final postmark = d.postmark;
    return GestureDetector(
      onTap: () => _editPostcard(d),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(colors: t.gradientColors),
          border: Border.all(color: d.themeColor.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              if (t.imageUrl != null && t.imageUrl!.isNotEmpty)
                Positioned.fill(
                  child: Image.network(ApiService.imageUrl(t.imageUrl), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                ),
              // Postmark bottom-left
              if (postmark != null)
                Positioned(
                  left: 20, bottom: 24,
                  child: _buildTilePostmark(postmark),
                ),
              // Stamp top-right
              if (stamp != null)
                Positioned(
                  top: 12, right: 16,
                  child: _buildTileStamp(stamp),
                ),
              // Inner border
              Positioned(
                left: 6, top: 6, right: 6, bottom: 6,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: d.themeColor.withOpacity(0.35), width: 1),
                  ),
                ),
              ),
              Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Icon(Icons.mail_outline, size: 16, color: d.themeColor)]),
            const Spacer(),
            if (d.toName.isNotEmpty) Text('To: ${d.toName}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF444444))),
            if (d.fromName.isNotEmpty) Text('From: ${d.fromName}', style: TextStyle(fontSize: 11, color: const Color(0xFF666666))),
            if (d.message.isNotEmpty) ...[const SizedBox(height: 4), Text(d.message, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: const Color(0xFF888888), fontStyle: FontStyle.italic))],
          ]),
        ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTileStamp(PostcardStamp stamp) {
    return Container(
      width: 28, height: 32,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(1), border: Border.all(color: stamp.accentColor, width: 1)),
      child: stamp.imageUrl != null && stamp.imageUrl!.isNotEmpty
          ? ClipRRect(borderRadius: BorderRadius.circular(1), child: Image.network(ApiService.imageUrl(stamp.imageUrl), width: 24, height: 24, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: Text(stamp.emoji, style: const TextStyle(fontSize: 12)))))
          : Center(child: Text(stamp.emoji, style: const TextStyle(fontSize: 12))),
    );
  }

  Widget _buildTilePostmark(PostcardPostmark postmark) {
    if (postmark.imageUrl != null && postmark.imageUrl!.isNotEmpty) {
      return Image.network(ApiService.imageUrl(postmark.imageUrl), width: 40, height: 40, fit: BoxFit.contain, errorBuilder: (_, __, ___) => _buildTilePostmarkCircle(postmark));
    }
    return _buildTilePostmarkCircle(postmark);
  }

  Widget _buildTilePostmarkCircle(PostcardPostmark postmark) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: postmark.color.withOpacity(0.5), width: 1.5)),
      child: Center(child: Text(postmark.dateText, style: TextStyle(fontSize: 7, color: postmark.color.withOpacity(0.7), fontWeight: FontWeight.w600))),
    );
  }
}
