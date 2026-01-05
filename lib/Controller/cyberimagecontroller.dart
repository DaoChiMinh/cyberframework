import 'package:flutter/foundation.dart';

enum CyberImageAction { none, upload, view, delete }

/// CyberImageController - điều khiển CyberImage programmatically
/// Không bắt buộc phải dùng, widget tự tạo internal controller
class CyberImageController extends ChangeNotifier {
  String? _imageUrl;
  bool _enabled = true;
  CyberImageAction _pendingAction = CyberImageAction.none;
  
  // Internal flag để tránh loop notification
  bool _isSyncing = false;

  String? get imageUrl => _imageUrl;
  bool get enabled => _enabled;
  CyberImageAction get pendingAction => _pendingAction;

  bool get hasImage => _imageUrl != null && _imageUrl!.isNotEmpty;

  /// Load URL image
  void loadUrl(String? url) {
    if (_imageUrl == url) return;
    _imageUrl = url;
    if (!_isSyncing) {
      notifyListeners();
    }
  }

  /// Load Base64 image
  void loadBase64(String base64) {
    loadUrl(base64);
  }

  /// Clear image
  void clear() {
    loadUrl(null);
  }

  /// Set enabled state
  void setEnabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
  }

  /// Trigger upload action
  void triggerUpload() {
    _pendingAction = CyberImageAction.upload;
    notifyListeners();
    Future.microtask(() {
      _pendingAction = CyberImageAction.none;
    });
  }

  /// Trigger view action
  void triggerView() {
    _pendingAction = CyberImageAction.view;
    notifyListeners();
    Future.microtask(() {
      _pendingAction = CyberImageAction.none;
    });
  }

  /// Trigger delete action
  void triggerDelete() {
    _pendingAction = CyberImageAction.delete;
    notifyListeners();
    Future.microtask(() {
      _pendingAction = CyberImageAction.none;
    });
  }

  /// Internal: Sync from binding without triggering notification loop
  void syncFromBinding(String? url) {
    if (_imageUrl == url) return;
    _isSyncing = true;
    _imageUrl = url;
    _isSyncing = false;
  }
}