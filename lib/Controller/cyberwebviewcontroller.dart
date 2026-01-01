import 'package:flutter/foundation.dart';

class CyberWebViewController extends ChangeNotifier {
  String? _url;
  String? _html;
  bool _enabled = true;

  String? get url => _url;
  String? get html => _html;
  bool get enabled => _enabled;

  void loadUrl(String url) {
    if (_url == url && _html == null) return; // Guard

    _html = null;
    _url = url;
    notifyListeners();
  }

  void loadHtml(String html) {
    if (_html == html && _url == null) return; // Guard

    _url = null;
    _html = html;
    notifyListeners();
  }

  void clear() {
    if (_url == null && _html == null) return; // Guard

    _url = null;
    _html = null;
    notifyListeners();
  }

  void setEnabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
  }

  // Internal method - dùng trong framework
  void setUrlInternal(String? url) {
    _url = url;
  }

  void setHtmlInternal(String? html) {
    _html = html;
  }
}
