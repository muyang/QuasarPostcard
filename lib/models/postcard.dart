import 'dart:convert';
import 'dart:ui';

// ======== Postcard Templates ========

class PostcardTemplate {
  final String id;
  final String name;
  final List<Color> gradientColors;
  final double cornerRadius;
  final String? decorationPattern;
  final String? imageUrl;
  final String status;

  const PostcardTemplate({
    required this.id,
    required this.name,
    required this.gradientColors,
    this.cornerRadius = 8,
    this.decorationPattern,
    this.imageUrl,
    this.status = 'published_free',
  });

  factory PostcardTemplate.fromJson(Map<String, dynamic> json) {
    return PostcardTemplate(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      gradientColors: [
        Color(int.parse((json['gradient_from'] ?? 'FFF0F5').toString(), radix: 16) | 0xFF000000),
        Color(int.parse((json['gradient_mid'] ?? json['gradient_from'] ?? 'FFE4E1').toString(), radix: 16) | 0xFF000000),
        Color(int.parse((json['gradient_to'] ?? 'FFC0CB').toString(), radix: 16) | 0xFF000000),
      ],
      cornerRadius: (json['corner_radius'] ?? 8).toDouble(),
      decorationPattern: json['pattern'],
      imageUrl: json['image_url'],
      status: json['status'] ?? 'published_free',
    );
  }
}

const POSTCARD_TEMPLATES = [
  PostcardTemplate(
    id: 'floral',
    name: '花卉',
    gradientColors: [Color(0xFFFFF0F5), Color(0xFFFFE4E1), Color(0xFFFFC0CB)],
    decorationPattern: 'floral',
  ),
  PostcardTemplate(
    id: 'geometric',
    name: '几何',
    gradientColors: [Color(0xFFF0F4FF), Color(0xFFE8ECF4), Color(0xFFB8C8E8)],
    decorationPattern: 'geometric',
  ),
  PostcardTemplate(
    id: 'minimalist',
    name: '极简',
    gradientColors: [Color(0xFFFAFAFA), Color(0xFFF5F5F5), Color(0xFFEEEEEE)],
    cornerRadius: 4,
    decorationPattern: 'minimalist',
  ),
  PostcardTemplate(
    id: 'vintage',
    name: '复古',
    gradientColors: [Color(0xFFFFF8F0), Color(0xFFF5E6D3), Color(0xFFE8D5B7)],
    decorationPattern: 'vintage',
  ),
  PostcardTemplate(
    id: 'nature',
    name: '自然',
    gradientColors: [Color(0xFFF0FFF0), Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
    decorationPattern: 'nature',
  ),
  PostcardTemplate(
    id: 'ocean',
    name: '海洋',
    gradientColors: [Color(0xFFF0F8FF), Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
    decorationPattern: 'ocean',
  ),
];

// ======== Theme Colors ========

class ThemeColorOption {
  final Color color;
  final String name;

  const ThemeColorOption({required this.color, required this.name});
}

const THEME_COLORS = [
  ThemeColorOption(color: Color(0xFFE91E63), name: '玫红'),
  ThemeColorOption(color: Color(0xFF4CAF50), name: '翠绿'),
  ThemeColorOption(color: Color(0xFF2196F3), name: '海蓝'),
  ThemeColorOption(color: Color(0xFFFF9800), name: '暖橙'),
  ThemeColorOption(color: Color(0xFF9C27B0), name: '紫罗兰'),
  ThemeColorOption(color: Color(0xFF607D8B), name: '灰蓝'),
  ThemeColorOption(color: Color(0xFF795548), name: '棕色'),
  ThemeColorOption(color: Color(0xFFF44336), name: '红色'),
];

// ======== Stamps ========

class PostcardStamp {
  final String id;
  final String emoji;
  final String label;
  final Color accentColor;
  final String? imageUrl;
  final String status;

  const PostcardStamp({
    required this.id,
    required this.emoji,
    required this.label,
    required this.accentColor,
    this.imageUrl,
    this.status = 'published_free',
  });

  factory PostcardStamp.fromJson(Map<String, dynamic> json) {
    return PostcardStamp(
      id: json['id'] ?? '',
      emoji: json['emoji'] ?? '',
      label: json['label'] ?? '',
      accentColor: Color(int.parse((json['accent_color'] ?? 'FFB7C5').toString(), radix: 16) | 0xFF000000),
      imageUrl: json['image_url'],
      status: json['status'] ?? 'published_free',
    );
  }
}

const POSTCARD_STAMPS = [
  PostcardStamp(id: 'flower', emoji: '🌸', label: '樱花', accentColor: Color(0xFFFFB7C5)),
  PostcardStamp(id: 'rose', emoji: '🌹', label: '玫瑰', accentColor: Color(0xFFE91E63)),
  PostcardStamp(id: 'sunflower', emoji: '🌻', label: '向日葵', accentColor: Color(0xFFFFD700)),
  PostcardStamp(id: 'tulip', emoji: '🌷', label: '郁金香', accentColor: Color(0xFFFF6B6B)),
  PostcardStamp(id: 'maple', emoji: '🍁', label: '枫叶', accentColor: Color(0xFFD2691E)),
  PostcardStamp(id: 'bird', emoji: '🕊️', label: '白鸽', accentColor: Color(0xFFB0C4DE)),
  PostcardStamp(id: 'butterfly', emoji: '🦋', label: '蝴蝶', accentColor: Color(0xFF87CEEB)),
  PostcardStamp(id: 'heart', emoji: '💝', label: '爱心', accentColor: Color(0xFFFF69B4)),
  PostcardStamp(id: 'star', emoji: '⭐', label: '星辰', accentColor: Color(0xFFFFD700)),
  PostcardStamp(id: 'clover', emoji: '🍀', label: '四叶草', accentColor: Color(0xFF90EE90)),
  PostcardStamp(id: 'snow', emoji: '❄️', label: '雪花', accentColor: Color(0xFFB0E0E6)),
  PostcardStamp(id: 'moon', emoji: '🌙', label: '月亮', accentColor: Color(0xFFC0C0FF)),
];

// ======== Postmarks ========

class PostcardPostmark {
  final String id;
  final String label;
  final String dateText;
  final Color color;
  final String? imageUrl;
  final String status;

  const PostcardPostmark({
    required this.id,
    required this.label,
    required this.dateText,
    required this.color,
    this.imageUrl,
    this.status = 'published_free',
  });

  factory PostcardPostmark.fromJson(Map<String, dynamic> json) {
    return PostcardPostmark(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      dateText: json['date_text'] ?? '2026.05.13',
      color: Color(int.parse((json['color'] ?? '333333').toString(), radix: 16) | 0xFF000000),
      imageUrl: json['image_url'],
      status: json['status'] ?? 'published_free',
    );
  }
}

const POSTCARD_POSTMARKS = [
  PostcardPostmark(id: 'classic', label: '经典圆形', dateText: '2026.05.13', color: Color(0xFF333333)),
  PostcardPostmark(id: 'red', label: '红色邮戳', dateText: '2026.05.13', color: Color(0xFFC62828)),
  PostcardPostmark(id: 'blue', label: '蓝色邮戳', dateText: '2026.05.13', color: Color(0xFF1565C0)),
  PostcardPostmark(id: 'gold', label: '金色纪念', dateText: '2026.05.13', color: Color(0xFFFF8F00)),
  PostcardPostmark(id: 'vintage_sepia', label: '复古棕', dateText: '2026.05.13', color: Color(0xFF795548)),
];

// ======== Postcard Design (runtime state) ========

class PostcardDesign {
  String templateId;
  Color themeColor;
  String toName;
  String fromName;
  String message;
  String? stampId;
  String? postmarkId;
  String? imageUrl;
  int id;
  String status;

  List<PostcardTemplate> _templates = POSTCARD_TEMPLATES;
  List<PostcardStamp> _stamps = POSTCARD_STAMPS;
  List<PostcardPostmark> _postmarks = POSTCARD_POSTMARKS;

  void updateMaterials({
    List<PostcardTemplate>? templates,
    List<PostcardStamp>? stamps,
    List<PostcardPostmark>? postmarks,
  }) {
    if (templates != null) _templates = templates;
    if (stamps != null) _stamps = stamps;
    if (postmarks != null) _postmarks = postmarks;
  }

  List<PostcardTemplate> get templates => _templates;
  List<PostcardStamp> get stamps => _stamps;
  List<PostcardPostmark> get postmarks => _postmarks;

  PostcardDesign({
    this.templateId = 'floral',
    this.themeColor = const Color(0xFFE91E63),
    this.toName = '',
    this.fromName = '',
    this.message = '',
    this.stampId,
    this.postmarkId,
    this.imageUrl,
    this.id = 0,
    this.status = 'PENDING',
  });

  PostcardTemplate get template =>
      _templates.firstWhere((t) => t.id == templateId, orElse: () => _templates[0]);

  PostcardStamp? get stamp =>
      stampId != null ? _stamps.cast<PostcardStamp?>().firstWhere((s) => s!.id == stampId, orElse: () => null) : null;

  PostcardPostmark? get postmark =>
      postmarkId != null ? _postmarks.cast<PostcardPostmark?>().firstWhere((p) => p!.id == postmarkId, orElse: () => null) : null;

  static const double aspectRatio = 14.0 / 9.0;
  static const double defaultWidth = 420.0;
  static const double defaultHeight = 270.0;

  String toDesignJsonString() {
    return jsonEncode({
      'templateId': templateId,
      'themeColor': themeColor.value.toRadixString(16),
      'toName': toName,
      'fromName': fromName,
      'stampId': stampId,
      'postmarkId': postmarkId,
    });
  }

  factory PostcardDesign.fromDesignJson(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return PostcardDesign();
    try {
      final m = jsonDecode(jsonStr) as Map<String, dynamic>;
      return PostcardDesign(
        templateId: m['templateId'] ?? 'floral',
        themeColor: Color(int.parse((m['themeColor'] ?? 'FFE91E63').toString(), radix: 16) | 0xFF000000),
        toName: m['toName'] ?? '',
        fromName: m['fromName'] ?? '',
        stampId: m['stampId'],
        postmarkId: m['postmarkId'],
      );
    } catch (_) {
      return PostcardDesign();
    }
  }
}
