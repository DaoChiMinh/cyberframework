import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';

enum CyberCameraAction { none, capture, switchCamera }

class CyberCameraController extends ChangeNotifier {
  bool _enabled = true;
  CyberCameraAction _pendingAction = CyberCameraAction.none;
  CameraLensDirection _preferredCamera = CameraLensDirection.back;

  bool get enabled => _enabled;
  CyberCameraAction get pendingAction => _pendingAction;
  CameraLensDirection get preferredCamera => _preferredCamera;

  void setEnabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
  }

  void setPreferredCamera(CameraLensDirection direction) {
    if (_preferredCamera == direction) return;
    _preferredCamera = direction;
    notifyListeners();
  }

  // Trigger actions programmatically
  void captureImage() {
    if (!_enabled) return;
    _pendingAction = CyberCameraAction.capture;
    notifyListeners();
    Future.microtask(() {
      _pendingAction = CyberCameraAction.none;
    });
  }

  void switchCamera() {
    if (!_enabled) return;
    _pendingAction = CyberCameraAction.switchCamera;
    notifyListeners();
    Future.microtask(() {
      _pendingAction = CyberCameraAction.none;
    });
  }
}

/// Result data sau khi chụp ảnh
class CyberCameraResult {
  final File file;
  final String fileName;
  final int fileSize;
  final bool isCompressed;
  final int? quality;

  CyberCameraResult({
    required this.file,
    required this.fileName,
    required this.fileSize,
    this.isCompressed = false,
    this.quality,
  });

  /// Get file as bytes
  Future<List<int>> getBytes() async {
    return await file.readAsBytes();
  }

  /// Get base64 string
  Future<String> getBase64() async {
    final bytes = await getBytes();
    return base64Encode(bytes);
  }

  /// Get base64 with data URI
  Future<String> getBase64DataUri() async {
    final base64 = await getBase64();
    return 'data:image/jpeg;base64,$base64';
  }
}

/// Callback khi chụp ảnh thành công
typedef OnCaptureImage = void Function(CyberCameraResult result);

/// Callback khi có lỗi
typedef OnCameraError = void Function(String error);
