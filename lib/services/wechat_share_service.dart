import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;
import 'api_service.dart';

class WechatShareService {
  static bool _sdkLoaded = false;

  static bool get isInWechat {
    try {
      return html.window.navigator.userAgent.contains('MicroMessenger');
    } catch (_) {
      return false;
    }
  }

  static Future<void> _loadSdk() async {
    if (_sdkLoaded) return;
    final completer = Completer<void>();
    final script = html.ScriptElement()
      ..src = 'https://res.wx.qq.com/open/js/jweixin-1.6.0.js'
      ..async = true;
    script.onLoad.first.then((_) {
      _sdkLoaded = true;
      completer.complete();
    });
    html.document.head!.append(script);
    await completer.future;
  }

  static Future<bool> configShare({
    required String title,
    required String desc,
    required String link,
    required String imgUrl,
  }) async {
    if (!isInWechat) return false;

    try {
      await _loadSdk();

      // Get JS-SDK signature from backend
      final uri = Uri.parse('${ApiService.baseUrl}/api/wechat/jsapi-signature');
      final resp = await html.HttpRequest.request(
        uri.toString(),
        method: 'POST',
        sendData: jsonEncode({'url': html.window.location.href}),
        requestHeaders: {'Content-Type': 'application/json'},
      );
      final config = jsonDecode(resp.responseText!) as Map<String, dynamic>;

      final safeTitle = title.replaceAll("'", "\\'");
      final safeDesc = desc.replaceAll("'", "\\'");
      final safeLink = link.replaceAll("'", "\\'");
      final safeImgUrl = imgUrl.replaceAll("'", "\\'");

      final jsCode = '''
        wx.config({
          debug: false,
          appId: '${config['appId']}',
          timestamp: ${config['timestamp']},
          nonceStr: '${config['nonceStr']}',
          signature: '${config['signature']}',
          jsApiList: ['updateAppMessageShareData', 'updateTimelineShareData']
        });
        wx.ready(function() {
          wx.updateAppMessageShareData({
            title: '$safeTitle',
            desc: '$safeDesc',
            link: '$safeLink',
            imgUrl: '$safeImgUrl'
          });
          wx.updateTimelineShareData({
            title: '$safeTitle',
            link: '$safeLink',
            imgUrl: '$safeImgUrl'
          });
        });
      ''';
      js.context.callMethod('eval', [jsCode]);
      return true;
    } catch (e) {
      return false;
    }
  }
}
