import 'package:flutter/foundation.dart';

enum CyberImageAction { none, upload, view, delete }

class CyberImageController extends ChangeNotifier {
  String? _imageUrl;
  bool _enabled = true;
  CyberImageAction _pendingAction = CyberImageAction.none;

  String? get imageUrl => _imageUrl;
  bool get enabled => _enabled;
  CyberImageAction get pendingAction => _pendingAction;

  bool get hasImage => _imageUrl != null && _imageUrl!.isNotEmpty;

  void loadUrl(String url) {
    if (_imageUrl == url) return; // Guard
    _imageUrl = url;
    notifyListeners();
  }

  void loadBase64(String base64) {
    if (_imageUrl == base64) return; // Guard
    _imageUrl = base64;
    notifyListeners();
  }

  void clear() {
    if (_imageUrl == null) return; // Guard
    _imageUrl = null;
    notifyListeners();
  }

  void setEnabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
  }

  // Trigger actions programmatically
  void triggerUpload() {
    _pendingAction = CyberImageAction.upload;
    notifyListeners();
    // Reset sau khi notify để widget xử lý 1 lần
    Future.microtask(() {
      _pendingAction = CyberImageAction.none;
    });
  }

  void triggerView() {
    _pendingAction = CyberImageAction.view;
    notifyListeners();
    Future.microtask(() {
      _pendingAction = CyberImageAction.none;
    });
  }

  void triggerDelete() {
    _pendingAction = CyberImageAction.delete;
    notifyListeners();
    Future.microtask(() {
      _pendingAction = CyberImageAction.none;
    });
  }

  // Internal: set URL without notify (dùng khi update từ binding)
  void setUrlInternal(String? url) {
    _imageUrl = url;
  }
}
