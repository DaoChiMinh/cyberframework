import 'package:flutter/foundation.dart';

/// ============================================================================
/// CyberSignatureController - Điều khiển CyberSignature từ bên ngoài
/// ============================================================================

enum CyberSignatureAction { none, sign, view, clear }

class CyberSignatureController extends ChangeNotifier {
  String? _signatureData;
  bool _enabled = true;
  CyberSignatureAction _pendingAction = CyberSignatureAction.none;

  /// Current signature data (base64)
  String? get signatureData => _signatureData;

  /// Enabled state
  bool get enabled => _enabled;

  /// Pending action
  CyberSignatureAction get pendingAction {
    final action = _pendingAction;
    _pendingAction = CyberSignatureAction.none;
    return action;
  }

  /// ============================================================================
  /// PUBLIC METHODS - Gọi từ bên ngoài
  /// ============================================================================

  /// Load signature data (từ binding hoặc external source)
  void loadSignature(String? data) {
    if (_signatureData != data) {
      _signatureData = data;
      notifyListeners();
    }
  }

  /// Sync từ binding vào controller (internal use)
  void syncFromBinding(String? value) {
    _signatureData = value;
    // Không notify vì đang sync từ binding
  }

  /// Trigger sign action
  void triggerSign() {
    _pendingAction = CyberSignatureAction.sign;
    notifyListeners();
  }

  /// Trigger view action
  void triggerView() {
    _pendingAction = CyberSignatureAction.view;
    notifyListeners();
  }

  /// Trigger clear action
  void triggerClear() {
    _pendingAction = CyberSignatureAction.clear;
    notifyListeners();
  }

  /// Clear signature
  void clear() {
    _signatureData = null;
    notifyListeners();
  }

  /// Set enabled state
  void setEnabled(bool value) {
    if (_enabled != value) {
      _enabled = value;
      notifyListeners();
    }
  }

  /// Check if has signature
  bool get hasSignature => _signatureData != null && _signatureData!.isNotEmpty;
}
