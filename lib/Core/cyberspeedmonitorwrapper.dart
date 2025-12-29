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
class CyberSpeedIndicator extends StatefulWidget {
  final bool showLabel;
  final bool autoStart;
  final TextStyle? textStyle;
  final EdgeInsets? padding;

  const CyberSpeedIndicator({
    super.key,
    this.showLabel = true,
    this.autoStart = true,
    this.textStyle,
    this.padding,
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
      setState(() {
        _speed = speed;
      });
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

/// Mixin để dễ dàng thêm speed monitor vào CyberForm
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
