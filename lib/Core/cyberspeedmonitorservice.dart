import 'package:cyberframework/cyberframework.dart';

/// Service để monitor tốc độ internet và hiển thị overlay
class CyberSpeedMonitorService extends ChangeNotifier {
  static final CyberSpeedMonitorService _instance =
      CyberSpeedMonitorService._internal();
  factory CyberSpeedMonitorService() => _instance;
  CyberSpeedMonitorService._internal();

  final CyberConnectivityService _connectivity = CyberConnectivityService();

  // ============================================================================
  // STATE
  // ============================================================================
  bool _isRunning = false;
  bool _isVisible = true;
  double? _currentSpeed; // KB/s
  Timer? _monitorTimer;
  OverlayEntry? _overlayEntry;

  // ============================================================================
  // CONFIGURATION
  // ============================================================================
  Duration checkInterval = const Duration(seconds: 3);
  String testUrl =
      'https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png';
  Duration timeout = const Duration(seconds: 5);

  // ============================================================================
  // GETTERS
  // ============================================================================
  bool get isRunning => _isRunning;
  bool get isVisible => _isVisible;
  double? get currentSpeed => _currentSpeed;

  String get speedText {
    if (_currentSpeed == null) return '--';
    if (_currentSpeed! >= 1024) {
      return '${(_currentSpeed! / 1024).toStringAsFixed(2)} MB/s';
    }
    return '${_currentSpeed!.toStringAsFixed(1)} KB/s';
  }

  Color get speedColor {
    if (_currentSpeed == null) return Colors.grey;
    if (_currentSpeed! < 50) return Colors.red;
    if (_currentSpeed! < 200) return Colors.orange;
    return Colors.green;
  }

  // ============================================================================
  // METHODS
  // ============================================================================

  /// Bắt đầu monitor tốc độ
  void start(BuildContext context) {
    if (_isRunning) return;

    _isRunning = true;
    _showOverlay(context);
    _startMonitoring();
    notifyListeners();
  }

  /// Dừng monitor
  void stop() {
    if (!_isRunning) return;

    _isRunning = false;
    _stopMonitoring();
    _hideOverlay();
    notifyListeners();
  }

  /// Toggle hiển thị/ẩn overlay
  void toggleVisibility() {
    _isVisible = !_isVisible;
    notifyListeners();
  }

  /// Ẩn tạm thời (không dừng monitor)
  void hide() {
    _isVisible = false;
    notifyListeners();
  }

  /// Hiện lại
  void show() {
    _isVisible = true;
    notifyListeners();
  }

  /// Bắt đầu monitoring loop
  void _startMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(checkInterval, (timer) {
      _checkSpeed();
    });
    // Check ngay lần đầu
    _checkSpeed();
  }

  /// Dừng monitoring loop
  void _stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
  }

  /// Kiểm tra tốc độ
  Future<void> _checkSpeed() async {
    try {
      final speed = await _connectivity.checkInternetSpeed(
        testUrl: testUrl,
        timeout: timeout,
      );

      if (speed != null) {
        // Chỉ update nếu thay đổi đáng kể (>10%)
        if (_currentSpeed == null ||
            ((_currentSpeed! - speed).abs() / _currentSpeed! > 0.1)) {
          _currentSpeed = speed;
          notifyListeners();
        }
      }
    } catch (e) {
      // Không làm gì nếu lỗi, giữ nguyên tốc độ cũ
    }
  }

  /// Hiển thị overlay
  void _showOverlay(BuildContext context) {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => CyberSpeedOverlay(service: this),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  /// Ẩn overlay
  void _hideOverlay() {
    try {
      _overlayEntry?.remove();
      _overlayEntry?.dispose(); // ✅ Thêm dispose
      _overlayEntry = null;
    } catch (e) {
      // Ignore error nếu overlay đã bị remove
    }
  }

  @override
  void dispose() {
    _stopMonitoring();
    _hideOverlay();
    super.dispose();
  }
}

/// Global instance
final speedMonitor = CyberSpeedMonitorService();
