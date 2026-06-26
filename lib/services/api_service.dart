import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginResult {
  final String? token;
  final String? error;
  const LoginResult({this.token, this.error});
  bool get success => token != null;
}

class ApiService {
  static String _baseUrl = '';
  static String _token = '';

  static String get baseUrl => _baseUrl;
  static String get token => _token;
  static bool get isAuthenticated => _token.isNotEmpty;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString('postcard_server_url') ?? '';
    _token = prefs.getString('postcard_token') ?? '';
  }

  static Future<void> saveConfig(String serverUrl, String token) async {
    _baseUrl = serverUrl;
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('postcard_server_url', serverUrl);
    await prefs.setString('postcard_token', token);
  }

  static Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('postcard_token', token);
  }

  static Future<void> logout() async {
    _token = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('postcard_token', '');
  }

  static Future<Map<String, dynamic>?> getMe() async {
    try {
      final resp = await http.get(
        Uri.parse('$_baseUrl/api/auth/me'),
        headers: _headers,
      ).timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body);
      }
    } catch (_) {}
    return null;
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token.isNotEmpty) 'Authorization': 'Bearer $_token',
      };

  static String imageUrl(String? path, {String? size}) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    // Route static files through the API image proxy for reliable CORS headers
    var url = '';
    if (path.startsWith('/static/')) {
      url = '$_baseUrl/api/images/${path.substring(8)}';
    } else {
      url = '$_baseUrl$path';
    }
    if (size != null && (size == 'thumb' || size == 'small')) {
      final sep = url.contains('?') ? '&' : '?';
      url = '$url$sep size=$size';
    }
    return url;
  }

  static Future<Uint8List?> fetchImageBytes(String url) async {
    try {
      final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
      if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
        return resp.bodyBytes;
      }
    } catch (_) {}
    return null;
  }

  // ========== Auth ==========

  static Future<LoginResult> login(String username, String password) async {
    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['success'] == true) {
          final token = data['token'] as String?;
          if (token != null && token.isNotEmpty) {
            return LoginResult(token: token);
          }
        }
      }
      return LoginResult(error: '用户名或密码错误');
    } catch (e) {
      return LoginResult(error: '无法连接服务器，请检查地址和网络');
    }
  }

  // ========== Postcards ==========

  static Future<Map<String, dynamic>> getPostcards({
    int skip = 0,
    int limit = 50,
    String? status,
  }) async {
    final params = <String, String>{
      'skip': skip.toString(),
      'limit': limit.toString(),
    };
    if (status != null && status.isNotEmpty) params['status'] = status;

    final uri = Uri.parse('$_baseUrl/api/postcards').replace(queryParameters: params);
    final resp = await http.get(uri, headers: _headers);
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    }
    throw Exception('Failed: ${resp.statusCode}');
  }

  static Future<Map<String, dynamic>> createPostcard(Map<String, dynamic> body) async {
    final resp = await http.post(
      Uri.parse('$_baseUrl/api/postcards'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    }
    throw Exception('Failed: ${resp.statusCode} ${resp.body}');
  }

  static Future<Map<String, dynamic>> updatePostcard(int id, Map<String, dynamic> body) async {
    final resp = await http.put(
      Uri.parse('$_baseUrl/api/postcards/$id'),
      headers: _headers,
      body: jsonEncode(body),
    );
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    }
    throw Exception('Failed: ${resp.statusCode} ${resp.body}');
  }

  static Future<void> deletePostcard(int id) async {
    final resp = await http.delete(
      Uri.parse('$_baseUrl/api/postcards/$id'),
      headers: _headers,
    );
    if (resp.statusCode != 200) {
      throw Exception('Failed: ${resp.statusCode}');
    }
  }

  static Future<int> batchDeletePostcards(List<int> ids) async {
    final resp = await http.post(
      Uri.parse('$_baseUrl/api/postcards/batch-delete'),
      headers: _headers,
      body: jsonEncode({'ids': ids}),
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return data['deleted'] ?? 0;
    }
    throw Exception('Failed: ${resp.statusCode}');
  }

  // ========== Materials ==========

  static Future<List<Map<String, dynamic>>> getTemplates({Map<String, String>? queryParams}) async {
    final defaults = {'status': 'published_free,published_member', 'limit': '1000'};
    final uri = Uri.parse('$_baseUrl/api/materials/templates').replace(queryParameters: queryParams ?? defaults);
    final resp = await http.get(uri, headers: _headers);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data is Map && data.containsKey('items')) {
        return List<Map<String, dynamic>>.from(data['items']);
      }
      return List<Map<String, dynamic>>.from(data);
    }
    throw Exception('Failed: ${resp.statusCode}');
  }

  static Future<List<Map<String, dynamic>>> getStamps({Map<String, String>? queryParams}) async {
    final defaults = {'status': 'published_free,published_member', 'limit': '1000'};
    final uri = Uri.parse('$_baseUrl/api/materials/stamps').replace(queryParameters: queryParams ?? defaults);
    final resp = await http.get(uri, headers: _headers);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data is Map && data.containsKey('items')) {
        return List<Map<String, dynamic>>.from(data['items']);
      }
      return List<Map<String, dynamic>>.from(data);
    }
    throw Exception('Failed: ${resp.statusCode}');
  }

  static Future<List<Map<String, dynamic>>> getPostmarks({Map<String, String>? queryParams}) async {
    final defaults = {'status': 'published_free,published_member', 'limit': '1000'};
    final uri = Uri.parse('$_baseUrl/api/materials/postmarks').replace(queryParameters: queryParams ?? defaults);
    final resp = await http.get(uri, headers: _headers);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data is Map && data.containsKey('items')) {
        return List<Map<String, dynamic>>.from(data['items']);
      }
      return List<Map<String, dynamic>>.from(data);
    }
    throw Exception('Failed: ${resp.statusCode}');
  }

  // ========== Image Upload ==========

  static Future<Map<String, dynamic>?> getConfig() async {
    try {
      final uri = Uri.parse('$_baseUrl/api/materials/config');
      final resp = await http.get(uri, headers: _headers);
      if (resp.statusCode == 200) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  static Future<String> uploadImage(String filePath) async {
    final uri = Uri.parse('$_baseUrl/api/upload/image');
    final request = http.MultipartRequest('POST', uri);
    if (_token.isNotEmpty) request.headers['Authorization'] = 'Bearer $_token';
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamedResp = await request.send();
    final resp = await http.Response.fromStream(streamedResp);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data['success'] == true) {
        return data['url'] ?? '';
      }
      throw Exception(data['detail'] ?? 'Upload failed');
    }
    throw Exception('Upload failed: ${resp.statusCode}');
  }

  /// Convert a portrait photo to anime style via the AI service.
  /// Returns the saved image URL, or null on failure.
  static Future<String?> animeFace(String imageBase64, {String prompt = ''}) async {
    try {
      final resp = await http.post(
        Uri.parse('$_baseUrl/api/ai/anime-face'),
        headers: _headers,
        body: jsonEncode({'image_base64': imageBase64, 'prompt': prompt}),
      ).timeout(const Duration(seconds: 120));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['success'] == true) {
          return data['image_url'] as String?;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Upload a share image (PNG bytes) and return the server-side URL.
  static Future<String> uploadShareImage(Uint8List bytes) async {
    final base64Data = base64Encode(bytes);
    final resp = await http.post(
      Uri.parse('$_baseUrl/api/share/upload-image'),
      headers: _headers,
      body: jsonEncode({'image_data': base64Data}),
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data['success'] == true) {
        return data['url'] as String? ?? '';
      }
      throw Exception(data['detail'] ?? 'Upload failed');
    }
    throw Exception('Upload failed: ${resp.statusCode}');
  }
}
