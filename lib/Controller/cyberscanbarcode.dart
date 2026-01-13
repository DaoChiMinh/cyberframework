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
  final bool continuousScan;

  /// Hiển thị trạng thái quét
  final bool showStatus;

  /// Màu của text trạng thái
  final Color statusTextColor;

  /// Màu nền của trạng thái
  final Color statusBackgroundColor;

  /// Message runtime - text tĩnh
  /// Ví dụ: "Quét mã sản phẩm"
  final String? message;

  /// Message runtime - getter động (binding từ CyberDataRow)
  /// Ví dụ: () => dataRow["ProductName"]?.toString() ?? ""
  final String Function()? messageGetter;

  /// Hiển thị message
  final bool showMessage;

  /// Màu text của message
  final Color messageTextColor;

  /// Màu nền của message
  final Color messageBackgroundColor;

  /// Vị trí message: 'top', 'center', 'bottom'
  final String messagePosition;

  /// Font size của message
  final double messageFontSize;

  /// Icon cho message (optional)
  final IconData? messageIcon;

  /// Interval để update message từ getter (ms)
  /// Chỉ áp dụng khi dùng messageGetter
  final int messageUpdateInterval;

  const Cyberscanbarcode({
    super.key,
    this.onCapture,
    this.height,
    this.borderRadius = 0,
    this.debounceMs = 1000,
    this.torchEnabled = false,
    this.autoZoom = false,
    this.clickScan = true,
    this.continuousScan = true,
    this.showStatus = true,
    this.statusTextColor = Colors.white,
    this.statusBackgroundColor = Colors.black54,
    // Message properties
    this.message,
    this.messageGetter,
    this.showMessage = true,
    this.messageTextColor = Colors.white,
    this.messageBackgroundColor = const Color(0xFF2196F3), // Blue
    this.messagePosition = 'bottom', // 'top', 'center', 'bottom'
    this.messageFontSize = 16.0,
    this.messageIcon,
    this.messageUpdateInterval = 500, // Update message every 500ms
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

  // Message runtime
  String _currentMessage = '';
  Timer? _messageUpdateTimer;

  @override
  void initState() {
    super.initState();

    controller = MobileScannerController(
      autoStart: true,
      detectionSpeed: DetectionSpeed.normal,
      detectionTimeoutMs: 350,
      formats: [BarcodeFormat.all],
      torchEnabled: widget.torchEnabled,
      autoZoom: widget.autoZoom,
    );

    _isScanning = true;

    WidgetsBinding.instance.addObserver(this);

    // Initialize message
    _updateMessage();

    // Start periodic message update nếu có messageGetter
    if (widget.messageGetter != null) {
      _startMessageUpdateTimer();
    }
  }

  void _updateMessage() {
    if (widget.messageGetter != null) {
      try {
        final newMessage = widget.messageGetter!();
        if (mounted && newMessage != _currentMessage) {
          setState(() {
            _currentMessage = newMessage;
          });
        }
      } catch (e) {
        debugPrint('Error updating message: $e');
      }
    } else if (widget.message != null) {
      if (_currentMessage != widget.message) {
        setState(() {
          _currentMessage = widget.message!;
        });
      }
    }
  }

  void _startMessageUpdateTimer() {
    _messageUpdateTimer?.cancel();
    _messageUpdateTimer = Timer.periodic(
      Duration(milliseconds: widget.messageUpdateInterval),
      (_) => _updateMessage(),
    );
  }

  @override
  void didUpdateWidget(Cyberscanbarcode oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update message nếu có thay đổi
    if (widget.message != oldWidget.message ||
        widget.messageGetter != oldWidget.messageGetter) {
      _updateMessage();

      // Restart timer nếu messageGetter thay đổi
      if (widget.messageGetter != oldWidget.messageGetter) {
        _messageUpdateTimer?.cancel();
        if (widget.messageGetter != null) {
          _startMessageUpdateTimer();
        }
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;

    if (!controller.value.hasCameraPermission) {
      return;
    }

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        _resumeScanning();
      case AppLifecycleState.inactive:
        _pauseScanning();
    }
  }

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

  Future<void> _toggleScanning() async {
    if (_isDisposed || !widget.clickScan) return;

    if (_isScanning) {
      await _stopScanning();
    } else {
      await _startScanning();
    }
  }

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
    if (!widget.continuousScan && _lastScannedValue != null) {
      return;
    }

    if (_lastScannedValue == value && _debounceTimer?.isActive == true) {
      return;
    }

    _debounceTimer?.cancel();
    _lastScannedValue = value;

    widget.onCapture?.call(value);

    if (!widget.continuousScan) {
      _stopScanning();
    }

    _debounceTimer = Timer(Duration(milliseconds: widget.debounceMs), () {
      if (widget.continuousScan) {
        _lastScannedValue = null;
      }
    });
  }

  void resetScanner() {
    _lastScannedValue = null;
    _debounceTimer?.cancel();
    if (!_isScanning) {
      _startScanning();
    }
  }

  /// Public method để update message từ bên ngoài
  void updateMessage(String message) {
    if (mounted) {
      setState(() {
        _currentMessage = message;
      });
    }
  }

  @override
  void dispose() {
    _isDisposed = true;

    _debounceTimer?.cancel();
    _debounceTimer = null;

    _messageUpdateTimer?.cancel();
    _messageUpdateTimer = null;

    WidgetsBinding.instance.removeObserver(this);

    controller.dispose();

    super.dispose();
  }

  Widget _buildMessageWidget() {
    if (!widget.showMessage || _currentMessage.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.messageBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.messageIcon != null) ...[
            Icon(
              widget.messageIcon,
              color: widget.messageTextColor,
              size: widget.messageFontSize + 4,
            ),
            SizedBox(width: 12),
          ],
          Flexible(
            child: Text(
              _currentMessage,
              style: TextStyle(
                color: widget.messageTextColor,
                fontSize: widget.messageFontSize,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionedMessage() {
    final messageWidget = _buildMessageWidget();

    switch (widget.messagePosition.toLowerCase()) {
      case 'top':
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Center(child: messageWidget),
        );
      case 'center':
        return Center(child: messageWidget);
      case 'bottom':
      default:
        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Center(child: messageWidget),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
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
              if (!_isScanning) return;

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

          // Status (luôn ở top)
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
                      Icon(
                        _isScanning ? Icons.qr_code_scanner : Icons.pause,
                        color: widget.statusTextColor,
                        size: 16,
                      ),
                      SizedBox(width: 8),
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

          // Runtime Message
          _buildPositionedMessage(),

          // Hướng dẫn click
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

    if (widget.clickScan) {
      return GestureDetector(onTap: _toggleScanning, child: scannerWidget);
    }

    return scannerWidget;
  }
}
