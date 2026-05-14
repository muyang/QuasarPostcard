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
  int _columns = 2;

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
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D1A),
        title: const Text('明信片', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300, letterSpacing: 1)),
        actions: [
          IconButton(icon: Icon(_columns == 1 ? Icons.grid_view_rounded : Icons.view_agenda_rounded, color: Colors.white54), tooltip: _columns == 1 ? '网格' : '列表', onPressed: () => setState(() => _columns = _columns == 1 ? 2 : 1)),
          if (_postcards.isNotEmpty)
            Center(child: Padding(padding: const EdgeInsets.only(right: 8), child: Text('${_postcards.length}', style: const TextStyle(fontSize: 13, color: Color(0xFF555577))))),
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white54), onPressed: _load),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
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
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: crossAxisCount, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 1.2),
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
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(colors: t.gradientColors),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(children: [
            if (t.imageUrl != null && t.imageUrl!.isNotEmpty)
              Positioned.fill(child: Image.network(ApiService.imageUrl(t.imageUrl), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink())),
            // Postmark
            if (postmark != null)
              Positioned(left: 22, bottom: 26, child: _buildTilePostmark(postmark)),
            // Stamp
            if (stamp != null)
              Positioned(top: 14, right: 18, child: _buildTileStamp(stamp)),
            // Inner border
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: d.themeColor.withOpacity(0.3), width: 1)),
              ),
            ),
            // Text content
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Icon(Icons.mail_outline, size: 14, color: d.themeColor.withOpacity(0.6))]),
                const Spacer(),
                if (d.toName.isNotEmpty)
                  Text('To: ${d.toName}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF444444))),
                if (d.fromName.isNotEmpty)
                  Padding(padding: const EdgeInsets.only(top: 2), child: Text('From: ${d.fromName}', style: TextStyle(fontSize: 11, color: const Color(0xFF666666)))),
                if (d.message.isNotEmpty)
                  Padding(padding: const EdgeInsets.only(top: 4), child: Text(d.message, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, color: const Color(0xFF888888), fontStyle: FontStyle.italic))),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildTileStamp(PostcardStamp stamp) {
    return Container(
      width: 28, height: 32,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(2), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 3)]),
      child: stamp.imageUrl != null && stamp.imageUrl!.isNotEmpty
          ? ClipRRect(borderRadius: BorderRadius.circular(2), child: Image.network(ApiService.imageUrl(stamp.imageUrl), width: 26, height: 30, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: Text(stamp.emoji, style: const TextStyle(fontSize: 12)))))
          : Center(child: Text(stamp.emoji, style: const TextStyle(fontSize: 12))),
    );
  }

  Widget _buildTilePostmark(PostcardPostmark postmark) {
    if (postmark.imageUrl != null && postmark.imageUrl!.isNotEmpty) {
      return Image.network(ApiService.imageUrl(postmark.imageUrl), width: 42, height: 42, fit: BoxFit.contain, errorBuilder: (_, __, ___) => _buildTilePostmarkCircle(postmark));
    }
    return _buildTilePostmarkCircle(postmark);
  }

  Widget _buildTilePostmarkCircle(PostcardPostmark postmark) {
    return Container(
      width: 42, height: 42,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: postmark.color.withOpacity(0.4), width: 1.5)),
      child: Center(child: Text(postmark.dateText, style: TextStyle(fontSize: 7, color: postmark.color.withOpacity(0.6), fontWeight: FontWeight.w600))),
    );
  }
}
