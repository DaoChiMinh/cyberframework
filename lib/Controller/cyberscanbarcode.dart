import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class Cyberscanbarcode extends StatefulWidget {
  final Function(String)? onCapture;
  final double? height;
  final double? borderRadius;

  /// Thời gian debounce giữa các lần scan (ms)
  final int debounceMs;

  /// Có bật torch mặc định không
  final bool torchEnabled;

  /// Có bật auto zoom không
  final bool autoZoom;

  const Cyberscanbarcode({
    super.key,
    this.onCapture,
    this.height,
    this.borderRadius = 12.0,
    this.debounceMs = 1000, // 1 giây debounce mặc định
    this.torchEnabled = false, // Tắt torch mặc định để tiết kiệm pin
    this.autoZoom = false, // Tắt autoZoom để tăng performance
  });

  @override
  State<StatefulWidget> createState() => _CyberCameraScreenState();
}

class _CyberCameraScreenState extends State<Cyberscanbarcode>
    with WidgetsBindingObserver {
  late MobileScannerController controller;

  // Debouncing
  Timer? _debounceTimer;
  String? _lastScannedValue;

  // Track state
  bool _isDisposed = false;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();

    // Initialize controller
    controller = MobileScannerController(
      autoStart: false,
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 350,
      formats: [BarcodeFormat.all],
      torchEnabled: widget.torchEnabled,
      autoZoom: widget.autoZoom,
    );

    // Start listening to lifecycle changes
    WidgetsBinding.instance.addObserver(this);

    // Start camera
    _startCamera();
  }

  Future<void> _startCamera() async {
    if (_isDisposed) return;

    try {
      await controller.start();
      if (mounted) {
        setState(() {
          _isScanning = true;
        });
      }
    } catch (e) {
      debugPrint('Error starting camera: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;

    // If the controller is not ready, do not try to start or stop it
    if (!controller.value.hasCameraPermission) {
      return;
    }

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        _startCamera();
      case AppLifecycleState.inactive:
        _stopCamera();
    }
  }

  Future<void> _stopCamera() async {
    if (_isDisposed) return;

    try {
      await controller.stop();
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    } catch (e) {
      debugPrint('Error stopping camera: $e');
    }
  }

  void _handleBarcodeDetection(String value) {
    // Kiểm tra debouncing
    if (_lastScannedValue == value && _debounceTimer?.isActive == true) {
      return; // Bỏ qua nếu cùng giá trị và trong thời gian debounce
    }

    // Cancel timer cũ nếu có
    _debounceTimer?.cancel();

    // Lưu giá trị mới
    _lastScannedValue = value;

    // Gọi callback
    widget.onCapture?.call(value);

    // Set timer mới
    _debounceTimer = Timer(Duration(milliseconds: widget.debounceMs), () {
      _lastScannedValue = null; // Reset sau debounce time
    });
  }

  @override
  Future<void> dispose() async {
    _isDisposed = true;

    // 1. Cancel debounce timer
    _debounceTimer?.cancel();
    _debounceTimer = null;

    // 2. Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    // 3. Stop camera trước
    try {
      await controller.stop();
    } catch (e) {
      debugPrint('Error stopping camera in dispose: $e');
    }

    // 4. Dispose controller
    try {
      await controller.dispose();
    } catch (e) {
      debugPrint('Error disposing controller: $e');
    }

    // 5. Gọi super.dispose() SAU CÙNG
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(widget.borderRadius!),
      ),
      clipBehavior: Clip.antiAlias, // Clip với borderRadius
      child: _isScanning
          ? MobileScanner(
              controller: controller,
              fit: BoxFit.cover, // Fill toàn bộ container
              onDetect: (data) {
                final barcode = data.barcodes.firstOrNull;
                if (barcode?.rawValue != null) {
                  _handleBarcodeDetection(barcode!.rawValue!);
                }
              },
            )
          : const Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}
