import 'dart:html' as html;
import 'dart:typed_data';

Future<bool> shareImage(Uint8List bytes, String filename) async {
  try {
    final nav = html.window.navigator;
    if (!(nav as dynamic).canShare) return false;
    final blob = html.Blob([bytes], 'image/png');
    final file = html.File([blob], filename, {'type': 'image/png'});
    await (nav as dynamic).share({'files': [file], 'title': '明信片'});
    return true;
  } catch (_) {
    return false;
  }
}

Future<bool> shareUrl(String url, String title) async {
  try {
    final nav = html.window.navigator;
    if (!(nav as dynamic).canShare) return false;
    await (nav as dynamic).share({'url': url, 'title': title, 'text': '分享一张明信片给你'});
    return true;
  } catch (_) {
    return false;
  }
}
