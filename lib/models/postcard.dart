import 'dart:convert';
import 'dart:ui';

// ======== Postcard Templates ========

Color _parseColor(String? hex, String fallback) {
  return Color(int.parse((hex ?? fallback).toString(), radix: 16) | 0xFF000000);
}

class PostcardTemplate {
  final String id;
  final String name;
  final List<Color> gradientColors;
  final double cornerRadius;
  final String? decorationPattern;
  final String? imageUrl;
  final String status;

  // Text colors
  final Color fromColor;
  final Color toColor;
  final Color messageColor;

  // Text fonts
  final String fromFont;
  final String toFont;
  final String messageFont;

  // Text sizes
  final double fromSize;
  final double toSize;
  final double messageSize;

  // Text positions (percentage 0-100)
  final double fromX;
  final double fromY;
  final double toX;
  final double toY;
  final double messageX;
  final double messageY;
  final double messageW;
  final double messageH;

  // Stamp position & transform
  final double stampX;
  final double stampY;
  final double stampRotation;
  final double stampScale;

  // Postmark position & transform
  final double postmarkX;
  final double postmarkY;
  final double postmarkRotation;
  final double postmarkScale;

  // From/To box styling
  final double fromW;
  final double fromH;
  final double toW;
  final double toH;
  final Color fromBorderColor;
  final Color toBorderColor;
  final double fromBorderWidth;
  final double toBorderWidth;
  final Color fromBgColor;
  final Color toBgColor;
  final double fromBgOpacity;
  final double toBgOpacity;

  const PostcardTemplate({
    required this.id,
    required this.name,
    required this.gradientColors,
    this.cornerRadius = 8,
    this.decorationPattern,
    this.imageUrl,
    this.status = 'published_free',
    this.fromColor = const Color(0xFF333333),
    this.toColor = const Color(0xFF333333),
    this.messageColor = const Color(0xFF555555),
    this.fromFont = 'sans-serif',
    this.toFont = 'sans-serif',
    this.messageFont = 'sans-serif',
    this.fromSize = 14,
    this.toSize = 14,
    this.messageSize = 13,
    this.fromX = 10,
    this.fromY = 82,
    this.toX = 55,
    this.toY = 82,
    this.messageX = 10,
    this.messageY = 60,
    this.messageW = 80,
    this.messageH = 80,
    this.stampX = 78,
    this.stampY = 5,
    this.stampRotation = 0,
    this.stampScale = 100,
    this.postmarkX = 45,
    this.postmarkY = 45,
    this.postmarkRotation = 0,
    this.postmarkScale = 100,
    this.fromW = 120,
    this.fromH = 28,
    this.toW = 120,
    this.toH = 28,
    this.fromBorderColor = const Color(0xFFCCCCCC),
    this.toBorderColor = const Color(0xFFCCCCCC),
    this.fromBorderWidth = 0,
    this.toBorderWidth = 0,
    this.fromBgColor = const Color(0xFFFFFFFF),
    this.toBgColor = const Color(0xFFFFFFFF),
    this.fromBgOpacity = 0,
    this.toBgOpacity = 0,
  });

  factory PostcardTemplate.fromJson(Map<String, dynamic> json) {
    return PostcardTemplate(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      gradientColors: [
        _parseColor(json['gradient_from'], 'FFF0F5'),
        _parseColor(json['gradient_mid'] ?? json['gradient_from'], 'FFE4E1'),
        _parseColor(json['gradient_to'], 'FFC0CB'),
      ],
      cornerRadius: (json['corner_radius'] ?? 8).toDouble(),
      decorationPattern: json['pattern'],
      imageUrl: json['image_url'],
      status: json['status'] ?? 'published_free',
      fromColor: _parseColor(json['from_color'], '333333'),
      toColor: _parseColor(json['to_color'], '333333'),
      messageColor: _parseColor(json['message_color'], '555555'),
      fromFont: json['from_font'] ?? 'sans-serif',
      toFont: json['to_font'] ?? 'sans-serif',
      messageFont: json['message_font'] ?? 'sans-serif',
      fromSize: (json['from_size'] ?? 14).toDouble(),
      toSize: (json['to_size'] ?? 14).toDouble(),
      messageSize: (json['message_size'] ?? 13).toDouble(),
      fromX: (json['from_x'] ?? 10).toDouble(),
      fromY: (json['from_y'] ?? 82).toDouble(),
      toX: (json['to_x'] ?? 55).toDouble(),
      toY: (json['to_y'] ?? 82).toDouble(),
      messageX: (json['message_x'] ?? 10).toDouble(),
      messageY: (json['message_y'] ?? 60).toDouble(),
      messageW: (json['message_w'] ?? 80).toDouble(),
      messageH: (json['message_h'] ?? 80).toDouble(),
      stampX: (json['stamp_x'] ?? 78).toDouble(),
      stampY: (json['stamp_y'] ?? 5).toDouble(),
      stampRotation: (json['stamp_rotation'] ?? 0).toDouble(),
      stampScale: (json['stamp_scale'] ?? 100).toDouble(),
      postmarkX: (json['postmark_x'] ?? 45).toDouble(),
      postmarkY: (json['postmark_y'] ?? 45).toDouble(),
      postmarkRotation: (json['postmark_rotation'] ?? 0).toDouble(),
      postmarkScale: (json['postmark_scale'] ?? 100).toDouble(),
      fromW: (json['from_w'] ?? 120).toDouble(),
      fromH: (json['from_h'] ?? 28).toDouble(),
      toW: (json['to_w'] ?? 120).toDouble(),
      toH: (json['to_h'] ?? 28).toDouble(),
      fromBorderColor: _parseColor(json['from_border_color'], 'CCCCCC'),
      toBorderColor: _parseColor(json['to_border_color'], 'CCCCCC'),
      fromBorderWidth: (json['from_border_width'] ?? 0).toDouble(),
      toBorderWidth: (json['to_border_width'] ?? 0).toDouble(),
      fromBgColor: _parseColor(json['from_bg_color'], 'FFFFFF'),
      toBgColor: _parseColor(json['to_bg_color'], 'FFFFFF'),
      fromBgOpacity: (json['from_bg_opacity'] ?? 0).toDouble(),
      toBgOpacity: (json['to_bg_opacity'] ?? 0).toDouble(),
    );
  }

  factory PostcardTemplate.empty() {
    return PostcardTemplate(
      id: '__empty__',
      name: '加载中...',
      gradientColors: [const Color(0xFFF5F5F5), const Color(0xFFEEEEEE), const Color(0xFFE0E0E0)],
    );
  }
}

const POSTCARD_TEMPLATES = [
  PostcardTemplate(
    id: 'floral',
    name: '花卉',
    gradientColors: [Color(0xFFFFF0F5), Color(0xFFFFE4E1), Color(0xFFFFC0CB)],
    decorationPattern: 'floral',
    fromColor: Color(0xFF7B4B6A), toColor: Color(0xFF7B4B6A), messageColor: Color(0xFF9B6B8A),
  ),
  PostcardTemplate(
    id: 'geometric',
    name: '几何',
    gradientColors: [Color(0xFFF0F4FF), Color(0xFFE8ECF4), Color(0xFFB8C8E8)],
    decorationPattern: 'geometric',
    fromColor: Color(0xFF3A5070), toColor: Color(0xFF3A5070), messageColor: Color(0xFF4A6080),
  ),
  PostcardTemplate(
    id: 'minimalist',
    name: '极简',
    gradientColors: [Color(0xFFFAFAFA), Color(0xFFF5F5F5), Color(0xFFEEEEEE)],
    cornerRadius: 4,
    decorationPattern: 'minimalist',
    fromColor: Color(0xFF444444), toColor: Color(0xFF444444), messageColor: Color(0xFF666666),
  ),
  PostcardTemplate(
    id: 'vintage',
    name: '复古',
    gradientColors: [Color(0xFFFFF8F0), Color(0xFFF5E6D3), Color(0xFFE8D5B7)],
    decorationPattern: 'vintage',
    fromColor: Color(0xFF5D4037), toColor: Color(0xFF5D4037), messageColor: Color(0xFF795548),
  ),
  PostcardTemplate(
    id: 'nature',
    name: '自然',
    gradientColors: [Color(0xFFF0FFF0), Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
    decorationPattern: 'nature',
    fromColor: Color(0xFF2E5D3A), toColor: Color(0xFF2E5D3A), messageColor: Color(0xFF3E6D4A),
  ),
  PostcardTemplate(
    id: 'ocean',
    name: '海洋',
    gradientColors: [Color(0xFFF0F8FF), Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
    decorationPattern: 'ocean',
    fromColor: Color(0xFF1A3A5C), toColor: Color(0xFF1A3A5C), messageColor: Color(0xFF2A4A6C),
  ),
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

  List<PostcardTemplate> _templates = [];
  List<PostcardStamp> _stamps = [];
  List<PostcardPostmark> _postmarks = [];

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

  PostcardTemplate get template {
    if (_templates.isEmpty) return PostcardTemplate.empty();
    return _templates.firstWhere((t) => t.id == templateId, orElse: () => _templates[0]);
  }

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
