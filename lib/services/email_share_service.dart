import 'dart:convert';
import 'dart:html' as html;
import 'api_service.dart';

class EmailShareService {
  static Future<Map<String, dynamic>> sendEmail({
    required String email,
    required String imageUrl,
    String subject = '有人给你寄了一张明信片',
    String body = '请查收附件中的明信片～',
  }) async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/api/share/email');
      final resp = await html.HttpRequest.request(
        uri.toString(),
        method: 'POST',
        sendData: jsonEncode({
          'email': email,
          'image_url': imageUrl,
          'subject': subject,
          'body': body,
        }),
        requestHeaders: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiService.token}',
        },
      );
      final data = jsonDecode(resp.responseText!) as Map<String, dynamic>;
      return data;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static void openMailtoFallback({required String email, required String subject, required String shareUrl}) {
    final mailtoUrl = 'mailto:$email?subject=${Uri.encodeComponent(subject)}'
        '&body=${Uri.encodeComponent('查看明信片: $shareUrl')}';
    html.window.open(mailtoUrl, '_blank');
  }
}
