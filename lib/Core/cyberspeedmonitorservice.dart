// lib/Core/cyberspeedmonitorservice.dart

import 'package:cyberframework/cyberframework.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ✅ LIFECYCLE-AWARE Speed Monitor Service
/// Automatically pauses when app goes to background
class CyberSpeedMonitorService extends ChangeNotifier
    with WidgetsBindingObserver {
  // ✅ Add lifecycle observer

  static final CyberSpeedMonitorService _instance =
      CyberSpeedMonitorService._internal();
  factory CyberSpeedMonitorService() => _instance;

  CyberSpeedMonitorService._internal() {
    // ✅ Register lifecycle observer on creation
    WidgetsBinding.instance.addObserver(this);
  }

  final CyberConnectivityService _connectivity = CyberConnectivityService();

  // ============================================================================
  // STATE
  // ============================================================================
  bool _isRunning = false;
  bool _isVisible = true;
  bool _isPaused = false; // ✅ NEW: Track pause state
  double? _currentSpeed;
  Timer? _monitorTimer;
  OverlayEntry? _overlayEntry;
  BuildContext? _overlayContext;

  // ✅ Persisted overlay position
  Offset _position = const Offset(10, 100);
  bool _positionLoaded = false;

  // ============================================================================
  // CONFIGURATION
  // ============================================================================
  Duration checkInterval = const Duration(seconds: 3);
  String testUrl =
      'https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png';
  Duration timeout = const Duration(seconds: 5);

  // ✅ NEW: Auto-pause configuration
  bool autoPauseOnBackground = true; // Pause when app goes to background
  bool autoPauseOnInactive = true; // Pause when app becomes inactive

  // ============================================================================
  // GETTERS
  // ============================================================================
  bool get isRunning => _isRunning;
  bool get isVisible => _isVisible;
  bool get isPaused => _isPaused; // ✅ NEW
  double? get currentSpeed => _currentSpeed;
  Offset get position => _position;

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
  // ✅ LIFECYCLE OBSERVER - AUTO PAUSE/RESUME
  // ============================================================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isRunning) return; // Only handle if service is running

    switch (state) {
      case AppLifecycleState.resumed:
        // ✅ App returned to foreground - resume monitoring
        if (_isPaused) {
          _resumeMonitoring();
        }
        break;

      case AppLifecycleState.inactive:
        // ✅ App is transitioning (e.g., system dialog, app switcher)
        if (autoPauseOnInactive) {
          _pauseMonitoring();
        }
        break;

      case AppLifecycleState.paused:
        // ✅ App in background - MUST pause to save battery
        if (autoPauseOnBackground) {
          _pauseMonitoring();
        }
        break;

      case AppLifecycleState.detached:
        // ✅ App is being destroyed - stop completely
        _pauseMonitoring();
        break;

      case AppLifecycleState.hidden:
        // ✅ App is hidden - pause monitoring
        if (autoPauseOnBackground) {
          _pauseMonitoring();
        }
        break;
    }
  }

  // ============================================================================
  // METHODS
  // ============================================================================

  /// Bắt đầu monitor tốc độ
  Future<void> start(BuildContext context) async {
    if (_isRunning) return;

    _isRunning = true;
    _isPaused = false;
    _overlayContext = context;

    // Load persisted position
    await _loadPosition();

    _showOverlay(context);
    _startMonitoring();
    notifyListeners();
  }

  /// Dừng monitor hoàn toàn
  void stop() {
    if (!_isRunning) return;

    _isRunning = false;
    _isPaused = false;
    _stopMonitoring();
    _hideOverlay();
    _overlayContext = null;
    notifyListeners();
  }

  /// ✅ NEW: Pause monitoring (keep service running, stop timer)
  void _pauseMonitoring() {
    if (!_isRunning || _isPaused) return;

    _isPaused = true;
    _stopMonitoringTimer(); // ✅ Stop timer to save CPU/battery

    debugPrint('🔋 SpeedMonitor: PAUSED (saving battery)');
    notifyListeners();
  }

  /// ✅ NEW: Resume monitoring
  void _resumeMonitoring() {
    if (!_isRunning || !_isPaused) return;

    _isPaused = false;
    _startMonitoringTimer(); // ✅ Restart timer

    debugPrint('▶️ SpeedMonitor: RESUMED');
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

  /// Update overlay position
  Future<void> updatePosition(Offset newPosition) async {
    _position = newPosition;
    await _savePosition();
    notifyListeners();
  }

  // ============================================================================
  // ✅ MONITORING CONTROL - SEPARATED START/STOP
  // ============================================================================

  /// Start monitoring loop
  void _startMonitoring() {
    if (_isPaused) {
      // Don't start if paused
      return;
    }
    _startMonitoringTimer();
  }

  /// Start timer
  void _startMonitoringTimer() {
    _stopMonitoringTimer(); // Clear existing timer

    _monitorTimer = Timer.periodic(checkInterval, (timer) {
      if (_isPaused) {
        // ✅ Safety check: Don't check if paused
        return;
      }
      _checkSpeed();
    });

    // Initial check
    _checkSpeed();
  }

  /// Stop monitoring loop
  void _stopMonitoring() {
    _stopMonitoringTimer();
  }

  /// ✅ NEW: Stop timer only (extracted for pause/resume)
  void _stopMonitoringTimer() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
  }

  /// Check internet speed
  Future<void> _checkSpeed() async {
    // ✅ Double-check: Don't check if paused
    if (_isPaused) return;

    try {
      final speed = await _connectivity.checkInternetSpeed(
        testUrl: testUrl,
        timeout: timeout,
      );

      if (speed != null && !_isPaused) {
        // ✅ Check again after async
        // Only update if significant change (>10%)
        if (_currentSpeed == null ||
            ((_currentSpeed! - speed).abs() / _currentSpeed! > 0.1)) {
          _currentSpeed = speed;
          notifyListeners();
        }
      }
    } catch (e) {
      // Keep previous speed on error
    }
  }

  // ============================================================================
  // OVERLAY MANAGEMENT
  // ============================================================================

  /// Show overlay
  void _showOverlay(BuildContext context) {
    if (_overlayEntry != null) return;

    try {
      _overlayEntry = OverlayEntry(
        builder: (context) => CyberSpeedOverlay(service: this),
      );

      Overlay.of(context).insert(_overlayEntry!);
    } catch (e) {
      _overlayEntry = null;
    }
  }

  /// Hide overlay
  void _hideOverlay() {
    try {
      _overlayEntry?.remove();
    } catch (e) {
      // Ignore removal errors
    } finally {
      _overlayEntry = null;
    }
  }

  // ============================================================================
  // PERSISTENCE
  // ============================================================================

  /// Load persisted overlay position
  Future<void> _loadPosition() async {
    if (_positionLoaded) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final dx = prefs.getDouble('speed_overlay_x');
      final dy = prefs.getDouble('speed_overlay_y');

      if (dx != null && dy != null) {
        _position = Offset(dx, dy);
      }
      _positionLoaded = true;
    } catch (e) {
      // Use default position on error
    }
  }

  /// Save overlay position
  Future<void> _savePosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('speed_overlay_x', _position.dx);
      await prefs.setDouble('speed_overlay_y', _position.dy);
    } catch (e) {
      // Ignore save errors
    }
  }

  // ============================================================================
  // ✅ CLEANUP - PROPER SINGLETON CLEANUP
  // ============================================================================

  /// Clean up resources (for singleton - doesn't dispose ChangeNotifier)
  void cleanup() {
    _stopMonitoring();
    _hideOverlay();
    _overlayContext = null;
    _currentSpeed = null;
    _isRunning = false;
    _isPaused = false;
    _isVisible = true;
    notifyListeners();
  }

  /// ✅ PROPER DISPOSAL - Only when app terminates
  /// This should ONLY be called when app is shutting down
  void shutdown() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    // Clean up resources
    cleanup();

    // Don't call super.dispose() - singleton may be accessed again
  }
}

/// Global instance
final speedMonitor = CyberSpeedMonitorService();
