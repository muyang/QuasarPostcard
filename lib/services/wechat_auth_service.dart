import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'api_service.dart';

class WechatAuthResult {
  final String? token;
  final String? nickname;
  final String? error;
  const WechatAuthResult({this.token, this.nickname, this.error});
  bool get success => token != null;
}

class WechatAuthService {
  static Map<String, dynamic>? _cachedConfig;

  static Future<Map<String, dynamic>> getConfig() async {
    final uri = Uri.parse('${ApiService.baseUrl}/api/auth/wechat/config');
    final resp = await html.HttpRequest.request(uri.toString(), method: 'GET');
    return jsonDecode(resp.responseText!) as Map<String, dynamic>;
  }

  /// Prefetch config so the popup can be opened synchronously on click.
  static Future<void> prefetchConfig() async {
    try {
      _cachedConfig = await getConfig();
    } catch (_) {}
  }

  static Future<WechatAuthResult> login() async {
    // Open popup FIRST (synchronous, before any async) to avoid blocker
    final left = ((html.window.screen?.width ?? 1200) / 2 - 300).round();
    final popup = html.window.open(
      'about:blank',
      'wechat_login',
      'width=600,height=600,left=$left,top=100',
    );

    if (popup == null) {
      return WechatAuthResult(error: '浏览器阻止了弹窗，请先允许弹窗后重试');
    }

    // Now safe to do async work — popup is already open
    try {
      _cachedConfig ??= await getConfig();
    } catch (e) {
      popup.close();
      return WechatAuthResult(error: '无法获取微信配置');
    }

    final config = _cachedConfig!;
    if (config['configured'] != true) {
      popup.close();
      return WechatAuthResult(error: '微信登录未配置');
    }

    final appid = config['appid'] as String;
    final redirectUri = config['redirect_uri'] as String;
    final state = DateTime.now().millisecondsSinceEpoch.toString();

    final authUrl = 'https://open.weixin.qq.com/connect/qrconnect?'
        'appid=$appid'
        '&redirect_uri=${Uri.encodeComponent(redirectUri)}'
        '&response_type=code'
        '&scope=snsapi_login'
        '&state=$state'
        '#wechat_redirect';

    // Navigate the already-open popup to WeChat
    popup.location.href = authUrl;

    // Listen for postMessage from callback
    final completer = Completer<WechatAuthResult>();
    late StreamSubscription<dynamic> listener;

    listener = html.window.onMessage.listen((event) {
      try {
        final data = (event as html.MessageEvent).data;
        if (data is Map && data['type'] == 'wechat_oauth_callback') {
          listener.cancel();
          try { popup.close(); } catch (_) {}
          if (data['error'] != null) {
            completer.complete(WechatAuthResult(error: '微信授权失败: ${data['error']}'));
          } else if (data['code'] != null) {
            _exchangeCode(data['code'] as String).then(completer.complete);
          } else {
            completer.complete(WechatAuthResult(error: '授权取消'));
          }
        }
      } catch (_) {}
    });

    Timer(const Duration(minutes: 5), () {
      if (!completer.isCompleted) {
        listener.cancel();
        try { popup.close(); } catch (_) {}
        completer.complete(WechatAuthResult(error: '登录超时，请重试'));
      }
    });

    return completer.future;
  }

  static Future<WechatAuthResult> _exchangeCode(String code) async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/api/auth/wechat/login');
      final resp = await html.HttpRequest.request(
        uri.toString(),
        method: 'POST',
        sendData: jsonEncode({'code': code}),
        requestHeaders: {'Content-Type': 'application/json'},
      );
      final data = jsonDecode(resp.responseText!) as Map<String, dynamic>;
      if (data['success'] == true && data['token'] != null) {
        await ApiService.saveToken(data['token'] as String);
        return WechatAuthResult(
          token: data['token'] as String,
          nickname: data['nickname'] as String?,
        );
      }
      return WechatAuthResult(error: data['message'] as String? ?? '登录失败');
    } catch (e) {
      return WechatAuthResult(error: '网络错误: $e');
    }
  }

  static bool isInWechatBrowser() {
    try {
      return html.window.navigator.userAgent.contains('MicroMessenger');
    } catch (_) {
      return false;
    }
  }
}
