import 'package:cyberframework/cyberframework.dart';

/// Widget wrapper để tự động tích hợp Speed Monitor vào app
/// Usage:
/// ```dart
/// void main() {
///   runApp(
///     CyberSpeedMonitorWrapper(
///       autoStart: true, // Tự động bật khi app chạy
///       child: MyApp(),
///     ),
///   );
/// }
/// ```
class CyberSpeedMonitorWrapper extends StatefulWidget {
  final Widget child;
  final bool autoStart;
  final Duration? checkInterval;
  final String? testUrl;

  const CyberSpeedMonitorWrapper({
    super.key,
    required this.child,
    this.autoStart = false,
    this.checkInterval,
    this.testUrl,
  });

  @override
  State<CyberSpeedMonitorWrapper> createState() =>
      _CyberSpeedMonitorWrapperState();
}

class _CyberSpeedMonitorWrapperState extends State<CyberSpeedMonitorWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Cấu hình service nếu có
    if (widget.checkInterval != null) {
      speedMonitor.checkInterval = widget.checkInterval!;
    }
    if (widget.testUrl != null) {
      speedMonitor.testUrl = widget.testUrl!;
    }

    // Auto start nếu được config
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && AppNavigator.context != null) {
          speedMonitor.start(AppNavigator.context!);
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Tạm dừng khi app ở background để tiết kiệm pin
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        if (speedMonitor.isRunning) {
          speedMonitor.hide();
        }
        break;
      case AppLifecycleState.resumed:
        if (speedMonitor.isRunning) {
          speedMonitor.show();
        }
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Floating Action Button để toggle speed monitor
/// Sử dụng trong Scaffold:
/// ```dart
/// Scaffold(
///   floatingActionButton: CyberSpeedMonitorFAB(),
/// )
/// ```
class CyberSpeedMonitorFAB extends StatelessWidget {
  final Color? backgroundColor;
  final Color? iconColor;
  final double? size;

  const CyberSpeedMonitorFAB({
    super.key,
    this.backgroundColor,
    this.iconColor,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: speedMonitor,
      builder: (context, _) {
        return FloatingActionButton(
          mini: true,
          backgroundColor:
              backgroundColor ??
              (speedMonitor.isRunning ? Colors.green : Colors.grey),
          onPressed: () {
            if (speedMonitor.isRunning) {
              speedMonitor.stop();
            } else {
              speedMonitor.start(context);
            }
          },
          child: Icon(
            speedMonitor.isRunning ? Icons.speed : Icons.speed_outlined,
            color: iconColor ?? Colors.white,
            size: size ?? 20,
          ),
        );
      },
    );
  }
}

/// Widget hiển thị tốc độ inline (không dùng overlay)
/// Usage trong form:
/// ```dart
/// CyberSpeedIndicator(
///   showLabel: true,
///   autoStart: true,
/// )
/// ```

/// Widget hiển thị tốc độ inline (không dùng overlay)
/// Hỗ trợ nhiều chế độ hiển thị
class CyberSpeedIndicator extends StatefulWidget {
  final bool showLabel;
  final bool autoStart;
  final TextStyle? textStyle;
  final EdgeInsets? padding;
  final bool compact; // Chế độ compact (chỉ icon + số)

  const CyberSpeedIndicator({
    super.key,
    this.showLabel = true,
    this.autoStart = true,
    this.textStyle,
    this.padding,
    this.compact = false,
  });

  @override
  State<CyberSpeedIndicator> createState() => _CyberSpeedIndicatorState();
}

class _CyberSpeedIndicatorState extends State<CyberSpeedIndicator> {
  final _service = CyberConnectivityService();
  double? _speed;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.autoStart) {
      _startMonitoring();
    }
  }

  void _startMonitoring() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkSpeed();
    });
    _checkSpeed();
  }

  Future<void> _checkSpeed() async {
    final speed = await _service.checkInternetSpeed();
    if (mounted && speed != null) {
      // Chỉ update nếu thay đổi > 10%
      if (_speed == null || (_speed! - speed).abs() / _speed! > 0.1) {
        setState(() {
          _speed = speed;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final speedText = _speed == null
        ? '--'
        : _speed! >= 1024
        ? '${(_speed! / 1024).toStringAsFixed(2)} MB/s'
        : '${_speed!.toStringAsFixed(1)} KB/s';

    final color = _speed == null
        ? Colors.grey
        : _speed! < 50
        ? Colors.red
        : _speed! < 200
        ? Colors.orange
        : Colors.green;

    // Compact mode
    if (widget.compact) {
      return Container(
        padding:
            widget.padding ??
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.speed, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              speedText,
              style:
                  widget.textStyle ??
                  TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      );
    }

    // Normal mode
    return Container(
      padding:
          widget.padding ??
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.speed, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            speedText,
            style:
                widget.textStyle ??
                TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (widget.showLabel) ...[
            const SizedBox(width: 6),
            Text(
              setText('Tốc độ', 'Speed'),
              style: TextStyle(color: color.withOpacity(0.7), fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

/// Banner hiển thị tốc độ ở đầu màn hình
class CyberSpeedBanner extends StatefulWidget {
  final Color? backgroundColor;
  final EdgeInsets? padding;

  const CyberSpeedBanner({super.key, this.backgroundColor, this.padding});

  @override
  State<CyberSpeedBanner> createState() => _CyberSpeedBannerState();
}

class _CyberSpeedBannerState extends State<CyberSpeedBanner> {
  final _service = CyberConnectivityService();
  double? _speed;
  Timer? _timer;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _startMonitoring();
  }

  void _startMonitoring() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkSpeed();
    });
    _checkSpeed();
  }

  Future<void> _checkSpeed() async {
    final speed = await _service.checkInternetSpeed();
    if (mounted && speed != null && !_isDismissed) {
      if (_speed == null || (_speed! - speed).abs() / _speed! > 0.1) {
        setState(() {
          _speed = speed;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) {
      return const SizedBox.shrink();
    }

    final color = _speed == null
        ? Colors.grey
        : _speed! < 50
        ? Colors.red
        : _speed! < 200
        ? Colors.orange
        : Colors.green;

    final speedText = _speed == null
        ? setText('Đang kiểm tra...', 'Checking...')
        : _speed! >= 1024
        ? '${(_speed! / 1024).toStringAsFixed(2)} MB/s'
        : '${_speed!.toStringAsFixed(1)} KB/s';

    return Container(
      width: double.infinity,
      padding:
          widget.padding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? color.withOpacity(0.1),
        border: Border(bottom: BorderSide(color: color.withOpacity(0.3))),
      ),
      child: Row(
        children: [
          Icon(Icons.speed, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  setText('Tốc độ kết nối', 'Connection Speed'),
                  style: TextStyle(color: color.withOpacity(0.8), fontSize: 11),
                ),
                Text(
                  speedText,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: color.withOpacity(0.6),
            onPressed: () {
              setState(() {
                _isDismissed = true;
              });
            },
          ),
        ],
      ),
    );
  }
}

/// Floating Speed Monitor - Hiển thị cố định ở góc màn hình
class CyberSpeedFloating extends StatefulWidget {
  final Alignment alignment;
  final EdgeInsets margin;
  final bool showDetails;

  const CyberSpeedFloating({
    super.key,
    this.alignment = Alignment.topRight,
    this.margin = const EdgeInsets.all(16),
    this.showDetails = false,
  });

  @override
  State<CyberSpeedFloating> createState() => _CyberSpeedFloatingState();
}

class _CyberSpeedFloatingState extends State<CyberSpeedFloating> {
  final _service = CyberConnectivityService();
  double? _speed;
  Timer? _timer;
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    _showDetails = widget.showDetails;
    _startMonitoring();
  }

  void _startMonitoring() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkSpeed();
    });
    _checkSpeed();
  }

  Future<void> _checkSpeed() async {
    final speed = await _service.checkInternetSpeed();
    if (mounted && speed != null) {
      if (_speed == null || (_speed! - speed).abs() / _speed! > 0.1) {
        setState(() {
          _speed = speed;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _speed == null
        ? Colors.grey
        : _speed! < 50
        ? Colors.red
        : _speed! < 200
        ? Colors.orange
        : Colors.green;

    final speedText = _speed == null
        ? '--'
        : _speed! >= 1024
        ? '${(_speed! / 1024).toStringAsFixed(2)} MB/s'
        : '${_speed!.toStringAsFixed(1)} KB/s';

    return Align(
      alignment: widget.alignment,
      child: Padding(
        padding: widget.margin,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _showDetails = !_showDetails;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(_showDetails ? 12 : 20),
              border: Border.all(color: color.withOpacity(0.5), width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: _showDetails
                ? _buildDetailView(color, speedText)
                : _buildCompactView(color, speedText),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactView(Color color, String speedText) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.speed, color: color, size: 16),
        const SizedBox(width: 6),
        Text(
          speedText,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailView(Color color, String speedText) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.speed, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              setText('Tốc độ', 'Speed'),
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          speedText,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _getSpeedLabel(),
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ],
    );
  }

  String _getSpeedLabel() {
    if (_speed == null) return setText('Đang kiểm tra...', 'Checking...');
    if (_speed! < 50) return setText('Rất chậm', 'Very Slow');
    if (_speed! < 200) return setText('Chậm', 'Slow');
    if (_speed! < 500) return setText('Trung bình', 'Average');
    if (_speed! < 1024) return setText('Nhanh', 'Fast');
    return setText('Rất nhanh', 'Very Fast');
  }
}

/// Mixin để dễ dàng thêm speed monitor vào CyberForm
/// Chỉ cần override enableSpeedMonitor = true
mixin CyberSpeedMonitorMixin on CyberForm {
  bool get enableSpeedMonitor => false;

  @override
  void onInit() {
    super.onInit();
    if (enableSpeedMonitor) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          speedMonitor.start(context);
        }
      });
    }
  }

  @override
  void onDispose() {
    if (enableSpeedMonitor) {
      speedMonitor.stop();
    }
    super.onDispose();
  }
}
