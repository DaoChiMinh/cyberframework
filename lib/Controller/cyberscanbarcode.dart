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

  /// Cho phép click vào màn hình để bật/tắt quét
  final bool clickScan;

  /// Quét liên tục hay dừng sau lần quét đầu tiên
  /// - true: Quét liên tục (mặc định)
  /// - false: Dừng sau lần quét đầu, phải click để quét lại
  final bool continuousScan;

  /// Hiển thị trạng thái quét
  final bool showStatus;

  /// Màu của text trạng thái
  final Color statusTextColor;

  /// Màu nền của trạng thái
  final Color statusBackgroundColor;

  const Cyberscanbarcode({
    super.key,
    this.onCapture,
    this.height,
    this.borderRadius = 12.0,
    this.debounceMs = 1000,
    this.torchEnabled = false,
    this.autoZoom = false,
    this.clickScan = true,
    this.continuousScan = true,
    this.showStatus = true,
    this.statusTextColor = Colors.white,
    this.statusBackgroundColor = Colors.black54,
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
  bool _isScanning = false; // Trạng thái đang quét hay không

  @override
  void initState() {
    super.initState();

    // Initialize controller với autoStart dựa vào continuousScan
    controller = MobileScannerController(
      autoStart: true, // Luôn autoStart khi khởi tạo
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 350,
      formats: [BarcodeFormat.all],
      torchEnabled: widget.torchEnabled,
      autoZoom: widget.autoZoom,
    );

    // Set initial scanning state
    _isScanning = true;

    // Start listening to lifecycle changes
    WidgetsBinding.instance.addObserver(this);
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
        // Restart camera khi app quay lại foreground
        _resumeScanning();
      case AppLifecycleState.inactive:
        // Stop camera khi app inactive
        _pauseScanning();
    }
  }

  /// Resume scanning (khi app resume)
  Future<void> _resumeScanning() async {
    if (_isDisposed) return;

    try {
      await controller.start();
      if (mounted) {
        setState(() {
          _isScanning = true;
        });
      }
    } catch (e) {
      debugPrint('Error resuming camera: $e');
    }
  }

  /// Pause scanning (khi app pause)
  Future<void> _pauseScanning() async {
    if (_isDisposed) return;

    try {
      await controller.stop();
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    } catch (e) {
      debugPrint('Error pausing camera: $e');
    }
  }

  /// Toggle scanning (bật/tắt quét khi click)
  Future<void> _toggleScanning() async {
    print("aaaaaaaaaaaaaaaaaaaaaaaa");
    if (_isDisposed || !widget.clickScan) return;

    if (_isScanning) {
      // Đang quét → Dừng
      await _stopScanning();
    } else {
      // Đang dừng → Bật
      await _startScanning();
    }
  }

  /// Start scanning
  Future<void> _startScanning() async {
    if (_isDisposed) return;

    try {
      await controller.start();
      if (mounted) {
        setState(() {
          _isScanning = true;
        });
      }
    } catch (e) {
      debugPrint('Error starting scanner: $e');
    }
  }

  /// Stop scanning
  Future<void> _stopScanning() async {
    if (_isDisposed) return;

    try {
      await controller.stop();
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    } catch (e) {
      debugPrint('Error stopping scanner: $e');
    }
  }

  void _handleBarcodeDetection(String value) {
    // Nếu không quét liên tục và đã quét được 1 lần, dừng quét
    if (!widget.continuousScan && _lastScannedValue != null) {
      return; // Đã quét rồi, không quét nữa
    }

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

    // Nếu không quét liên tục, dừng scanner sau khi quét xong
    if (!widget.continuousScan) {
      _stopScanning();
    }

    // Set timer mới
    _debounceTimer = Timer(Duration(milliseconds: widget.debounceMs), () {
      if (widget.continuousScan) {
        _lastScannedValue =
            null; // Reset sau debounce time (chỉ khi quét liên tục)
      }
      // Nếu không quét liên tục, giữ nguyên _lastScannedValue để block scan tiếp
    });
  }

  /// Reset scanner để có thể quét lại (dùng khi continuousScan = false)
  void resetScanner() {
    _lastScannedValue = null;
    _debounceTimer?.cancel();
    if (!_isScanning) {
      _startScanning();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;

    // Cancel debounce timer
    _debounceTimer?.cancel();
    _debounceTimer = null;

    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    // Dispose controller
    controller.dispose();

    // Call super last
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Widget chính
    Widget scannerWidget = Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(widget.borderRadius!),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Camera scanner
          MobileScanner(
            controller: controller,
            fit: BoxFit.cover,
            onDetect: (data) {
              if (!_isScanning) return; // Không xử lý nếu đang dừng

              final barcode = data.barcodes.firstOrNull;
              if (barcode?.rawValue != null) {
                _handleBarcodeDetection(barcode!.rawValue!);
              }
            },
          ),

          // Overlay khi dừng quét
          if (!_isScanning)
            Container(
              color: Colors.black38,
              child: Center(
                child: Icon(
                  Icons.pause_circle_outline,
                  size: 64,
                  color: Colors.white70,
                ),
              ),
            ),

          // Hiển thị trạng thái
          if (widget.showStatus)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: widget.statusBackgroundColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon
                      Icon(
                        _isScanning ? Icons.qr_code_scanner : Icons.pause,
                        color: widget.statusTextColor,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      // Text
                      Text(
                        _isScanning ? 'Đang quét...' : 'Dừng quét',
                        style: TextStyle(
                          color: widget.statusTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Hướng dẫn click (nếu bật clickScan)
          if (widget.clickScan && !_isScanning)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Chạm để tiếp tục quét',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    // Wrap với GestureDetector nếu bật clickScan
    if (widget.clickScan) {
      return GestureDetector(onTap: _toggleScanning, child: scannerWidget);
    }

    return scannerWidget;
  }
}
