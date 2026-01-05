// lib/Core/speed_monitor_base.dart

import 'package:cyberframework/cyberframework.dart';

/// Base mixin for speed monitoring functionality
/// Provides shared logic for all speed monitor widgets
mixin SpeedMonitorMixin<T extends StatefulWidget> on State<T> {
  final CyberConnectivityService _connectivity = CyberConnectivityService();

  double? _speed;
  Timer? _monitorTimer;
  bool _isMonitoring = false;

  // Configuration
  Duration get checkInterval => const Duration(seconds: 3);
  String get testUrl =>
      'https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png';
  Duration get timeout => const Duration(seconds: 5);

  // Getters
  double? get currentSpeed => _speed;
  bool get isMonitoring => _isMonitoring;

  String get speedText {
    if (_speed == null) return '--';
    if (_speed! >= 1024) {
      return '${(_speed! / 1024).toStringAsFixed(2)} MB/s';
    }
    return '${_speed!.toStringAsFixed(1)} KB/s';
  }

  Color get speedColor {
    if (_speed == null) return Colors.grey;
    if (_speed! < 50) return Colors.red;
    if (_speed! < 200) return Colors.orange;
    return Colors.green;
  }

  String get speedLabel {
    if (_speed == null) return setText('Đang kiểm tra...', 'Checking...');
    if (_speed! < 50) return setText('Rất chậm', 'Very Slow');
    if (_speed! < 200) return setText('Chậm', 'Slow');
    if (_speed! < 500) return setText('Trung bình', 'Average');
    if (_speed! < 1024) return setText('Nhanh', 'Fast');
    return setText('Rất nhanh', 'Very Fast');
  }

  /// Start monitoring
  void startMonitoring() {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(checkInterval, (_) {
      checkSpeed();
    });
    checkSpeed(); // Initial check
  }

  /// Stop monitoring
  void stopMonitoring() {
    _isMonitoring = false;
    _monitorTimer?.cancel();
    _monitorTimer = null;
  }

  /// Check internet speed
  Future<void> checkSpeed() async {
    if (!mounted) return;

    try {
      final speed = await _connectivity.checkInternetSpeed(
        testUrl: testUrl,
        timeout: timeout,
      );

      if (!mounted) return;

      if (speed != null) {
        // Only update if significant change (>10%)
        if (_speed == null || (_speed! - speed).abs() / _speed! > 0.1) {
          setState(() {
            _speed = speed;
          });
        }
      }
    } catch (e) {
      // Keep previous speed on error
    }
  }

  /// Must call in dispose
  void disposeMonitoring() {
    stopMonitoring();
  }
}
