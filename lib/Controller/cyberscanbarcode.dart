import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';

/// Loại nguồn âm thanh
enum SoundSourceType {
  system, // System sound (không cần file/url)
  asset, // File trong assets/
  url, // URL từ server
  file, // File path local
}

class Cyberscanbarcode extends StatefulWidget {
  final Function(String)? onCapture;
  final double? height;
  final double? borderRadius;
  final int debounceMs;
  final bool torchEnabled;
  final bool autoZoom;
  final bool clickScan;
  final bool continuousScan;
  final bool showStatus;
  final Color statusTextColor;
  final Color statusBackgroundColor;
  final String? message;
  final String Function()? messageGetter;
  final bool showMessage;
  final Color messageTextColor;
  final Color messageBackgroundColor;
  final String messagePosition;
  final double messageFontSize;
  final IconData? messageIcon;
  final int messageUpdateInterval;
  final int messageDuration;
  final bool playBeepSound;
  final double beepVolume;

  /// Loại nguồn âm thanh success
  final SoundSourceType successSoundType;

  /// Đường dẫn/URL âm thanh success
  /// - SoundSourceType.asset: 'sounds/success.mp3'
  /// - SoundSourceType.url: 'https://example.com/success.mp3'
  /// - SoundSourceType.file: '/path/to/success.mp3'
  final String? successSoundPath;

  /// Loại nguồn âm thanh error
  final SoundSourceType errorSoundType;

  /// Đường dẫn/URL âm thanh error
  final String? errorSoundPath;

  /// Loại nguồn âm thanh default
  final SoundSourceType defaultSoundType;

  /// Đường dẫn/URL âm thanh default
  final String? defaultSoundPath;

  /// Chế độ âm thanh hiện tại: 'success', 'error', 'default'
  final String currentSoundMode;

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
    this.message,
    this.messageGetter,
    this.showMessage = true,
    this.messageTextColor = Colors.white,
    this.messageBackgroundColor = const Color(0xFF2196F3),
    this.messagePosition = 'bottom',
    this.messageFontSize = 16.0,
    this.messageIcon,
    this.messageUpdateInterval = 500,
    this.messageDuration = 2000,
    this.playBeepSound = true,
    this.beepVolume = 0.5,
    // Sound configuration
    this.successSoundType = SoundSourceType.system,
    this.successSoundPath,
    this.errorSoundType = SoundSourceType.system,
    this.errorSoundPath,
    this.defaultSoundType = SoundSourceType.system,
    this.defaultSoundPath,
    this.currentSoundMode = 'default',
  });

  @override
  State<StatefulWidget> createState() => _CyberCameraScreenState();
}

class _CyberCameraScreenState extends State<Cyberscanbarcode>
    with WidgetsBindingObserver {
  late MobileScannerController controller;
  Timer? _debounceTimer;
  String? _lastScannedValue;
  bool _isDisposed = false;
  bool _isScanning = false;
  String _currentMessage = '';
  Timer? _messageUpdateTimer;
  String _temporaryMessage = '';
  Timer? _messageDurationTimer;
  bool _showTemporaryMessage = false;

  final AudioPlayer _audioPlayer = AudioPlayer();

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
    _updateMessage();
    if (widget.messageGetter != null) {
      _startMessageUpdateTimer();
    }
    _audioPlayer.setVolume(widget.beepVolume);
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

  void _displayTemporaryMessage(String message) {
    if (!widget.showMessage || widget.messageDuration == 0) return;

    _messageDurationTimer?.cancel();
    setState(() {
      _temporaryMessage = message;
      _showTemporaryMessage = true;
    });

    _messageDurationTimer = Timer(
      Duration(milliseconds: widget.messageDuration),
      () {
        if (mounted) {
          setState(() {
            _showTemporaryMessage = false;
            _temporaryMessage = '';
          });
        }
      },
    );
  }

  Future<void> _playBeep() async {
    if (!widget.playBeepSound) return;

    try {
      // Chọn sound source dựa vào currentSoundMode
      SoundSourceType sourceType;
      String? soundPath;

      switch (widget.currentSoundMode) {
        case 'success':
          sourceType = widget.successSoundType;
          soundPath = widget.successSoundPath;
          break;
        case 'error':
          sourceType = widget.errorSoundType;
          soundPath = widget.errorSoundPath;
          break;
        default:
          sourceType = widget.defaultSoundType;
          soundPath = widget.defaultSoundPath;
      }

      // Play sound dựa vào source type
      switch (sourceType) {
        case SoundSourceType.system:
          SystemSound.play(SystemSoundType.click);
          HapticFeedback.mediumImpact();
          break;

        case SoundSourceType.asset:
          if (soundPath != null) {
            await _audioPlayer.play(AssetSource(soundPath));
            HapticFeedback.mediumImpact();
          } else {
            _playSystemSound();
          }
          break;

        case SoundSourceType.url:
          if (soundPath != null) {
            await _audioPlayer.play(UrlSource(soundPath));
            HapticFeedback.mediumImpact();
          } else {
            _playSystemSound();
          }
          break;

        case SoundSourceType.file:
          if (soundPath != null) {
            await _audioPlayer.play(DeviceFileSource(soundPath));
            HapticFeedback.mediumImpact();
          } else {
            _playSystemSound();
          }
          break;
      }
    } catch (e) {
      debugPrint('Error playing beep: $e');
      _playSystemSound();
    }
  }

  void _playSystemSound() {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.mediumImpact();
  }

  @override
  void didUpdateWidget(Cyberscanbarcode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.message != oldWidget.message ||
        widget.messageGetter != oldWidget.messageGetter) {
      _updateMessage();
      if (widget.messageGetter != oldWidget.messageGetter) {
        _messageUpdateTimer?.cancel();
        if (widget.messageGetter != null) {
          _startMessageUpdateTimer();
        }
      }
    }

    if (widget.beepVolume != oldWidget.beepVolume) {
      _audioPlayer.setVolume(widget.beepVolume);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed || !controller.value.hasCameraPermission) return;
    switch (state) {
      case AppLifecycleState.resumed:
        _resumeScanning();
        break;
      case AppLifecycleState.inactive:
        _pauseScanning();
        break;
      default:
        break;
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
    if (!widget.continuousScan && _lastScannedValue != null) return;
    if (_lastScannedValue == value && _debounceTimer?.isActive == true) return;

    _debounceTimer?.cancel();
    _lastScannedValue = value;

    _playBeep();

    if (widget.messageDuration > 0) {
      _displayTemporaryMessage('✅ Quét: $value');
    }

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
    _messageDurationTimer?.cancel();
    _messageDurationTimer = null;
    _audioPlayer.dispose();
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  Widget _buildMessageWidget() {
    if (!widget.showMessage) return SizedBox.shrink();

    String displayMessage = _showTemporaryMessage
        ? _temporaryMessage
        : _currentMessage;

    if (displayMessage.isEmpty) return SizedBox.shrink();

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
              displayMessage,
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
          _buildPositionedMessage(),
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
