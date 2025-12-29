import 'package:cyberframework/cyberframework.dart';

/// Vị trí hiển thị Speed Monitor trong CyberForm
enum SpeedMonitorPosition {
  topLeft,
  topRight,
  topCenter,
  bottomLeft,
  bottomRight,
  bottomCenter,
  appBar, // Trong AppBar
  banner, // Banner ở đầu body
}

class CyberFormView extends StatefulWidget {
  final CyberForm Function() formBuilder;
  final String title;
  // ignore: non_constant_identifier_names
  final String cp_name;
  final String strparameter;
  final dynamic objectdata;
  final bool hideAppBar;
  final bool showSpeedMonitor;
  final SpeedMonitorPosition speedMonitorPosition;
  final bool isMainScreen; // ✅ NEW: Track nếu là main screen

  const CyberFormView({
    super.key,
    required this.title,
    required this.formBuilder,
    // ignore: non_constant_identifier_names
    required this.cp_name,
    required this.strparameter,
    this.objectdata,
    this.hideAppBar = false,
    this.showSpeedMonitor = true,
    this.speedMonitorPosition = SpeedMonitorPosition.appBar,
    this.isMainScreen = false, // ✅ Mặc định false
  });

  @override
  State<CyberFormView> createState() => _CyberFormViewState();
}

class _CyberFormViewState extends State<CyberFormView> {
  late final CyberForm _form;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _form = widget.formBuilder();
    _form._context = context;
    _form._widget = widget;
    _form._setState = () {
      if (mounted) setState(() {});
    };

    // Call lifecycle methods
    _initializeForm();
  }

  Future<void> _initializeForm() async {
    try {
      // 1. onInit - Khởi tạo cơ bản
      _form.onInit();

      // 2. onBeforeLoad - Chuẩn bị trước khi load API
      await _form.onBeforeLoad();

      // 3. onLoadData - Load data từ API
      await _form.onLoadData();

      // 4. onAfterLoad - Xử lý sau khi load xong
      await _form.onAfterLoad();

      // Done loading
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
      _form.onLoadError(e);
    }
  }

  @override
  void dispose() {
    // Gọi onDispose của form để cleanup resources
    _form.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _form._context = context;

    return CyberLanguageBuilder(
      builder: (context, language) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          appBar: (_form.hideAppBar ?? widget.hideAppBar)
              ? null
              : _buildAppBar(),
          backgroundColor: _form.backgroundColor ?? Colors.white,
          body: _buildBodyWithSpeedMonitor(),
        ),
      ),
    );
  }

  /// Build AppBar với Speed Monitor nếu cần
  PreferredSizeWidget _buildAppBar() {
    final showInAppBar =
        (widget.showSpeedMonitor || _form.showSpeedMonitor == true) &&
        widget.speedMonitorPosition == SpeedMonitorPosition.appBar;

    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      title: Text(_form.title ?? widget.title),
      actions: showInAppBar
          ? [
              const Padding(
                padding: EdgeInsets.only(right: 8.0),
                child: CyberSpeedIndicator(
                  showLabel: false,
                  autoStart: true,
                  compact: true,
                ),
              ),
            ]
          : null,
    );
  }

  /// Build body với Speed Monitor ở các vị trí khác
  Widget _buildBodyWithSpeedMonitor() {
    final body = _buildBody();
    final showMonitor =
        widget.showSpeedMonitor || _form.showSpeedMonitor == true;

    if (!showMonitor ||
        widget.speedMonitorPosition == SpeedMonitorPosition.appBar) {
      return body;
    }

    // Banner position
    if (widget.speedMonitorPosition == SpeedMonitorPosition.banner) {
      return Column(
        children: [
          const CyberSpeedBanner(),
          Expanded(child: body),
        ],
      );
    }

    // Floating positions
    return Stack(children: [body, _buildFloatingSpeedMonitor()]);
  }

  /// Build Floating Speed Monitor
  /// ✅ FIXED: Nếu là Main Screen thì hiển thị ở top 30, right 30
  Widget _buildFloatingSpeedMonitor() {
    // ✅ Check nếu là Main Screen
    final isMainScreen = widget.isMainScreen;

    return Positioned(
      top: isMainScreen ? 30 : _getTop(),
      left: _getLeft(),
      right: isMainScreen ? 30 : _getRight(),
      bottom: _getBottom(),
      child: const IgnorePointer(
        ignoring: false,
        child: CyberSpeedIndicator(
          showLabel: false,
          autoStart: true,
          compact: true,
        ),
      ),
    );
  }

  double? _getTop() {
    switch (widget.speedMonitorPosition) {
      case SpeedMonitorPosition.topLeft:
      case SpeedMonitorPosition.topRight:
      case SpeedMonitorPosition.topCenter:
        return 16;
      default:
        return null;
    }
  }

  double? _getBottom() {
    switch (widget.speedMonitorPosition) {
      case SpeedMonitorPosition.bottomLeft:
      case SpeedMonitorPosition.bottomRight:
      case SpeedMonitorPosition.bottomCenter:
        return 16;
      default:
        return null;
    }
  }

  double? _getLeft() {
    switch (widget.speedMonitorPosition) {
      case SpeedMonitorPosition.topLeft:
      case SpeedMonitorPosition.bottomLeft:
        return 16;
      case SpeedMonitorPosition.topCenter:
      case SpeedMonitorPosition.bottomCenter:
        return 0;
      default:
        return null;
    }
  }

  double? _getRight() {
    switch (widget.speedMonitorPosition) {
      case SpeedMonitorPosition.topRight:
      case SpeedMonitorPosition.bottomRight:
        return 16;
      case SpeedMonitorPosition.topCenter:
      case SpeedMonitorPosition.bottomCenter:
        return 0;
      default:
        return null;
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _form.buildLoadingWidget() ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(setText('Đang tải dữ liệu...', 'Loading data...')),
              ],
            ),
          );
    }

    if (_errorMessage != null) {
      return _form.buildErrorWidget(_errorMessage!) ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('${setText("Lỗi", "Error")}: $_errorMessage'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    _initializeForm();
                  },
                  child: Text(setText('Thử lại', 'Retry')),
                ),
              ],
            ),
          );
    }

    return _form.buildBody(context);
  }
}

abstract class CyberForm {
  late BuildContext _context;
  late CyberFormView _widget;
  late VoidCallback _setState;

  // Danh sách resources cần dispose (controllers, streams, listeners...)
  final List<dynamic> _disposables = [];

  BuildContext get context => _context;
  CyberFormView get widget => _widget;

  // ============================================================================
  // ✅ GETTERS ĐỂ TRUY CẬP CÁC THAM SỐ
  // ============================================================================

  /// Lấy cp_name từ CyberFormView
  // ignore: non_constant_identifier_names
  String get cp_name => _widget.cp_name;

  /// Lấy strparameter từ CyberFormView
  String get strparameter => _widget.strparameter;

  /// Lấy objectdata từ CyberFormView
  dynamic get objectdata => _widget.objectdata;

  // ============================================================================
  // PROPERTIES - Có thể override trong form con
  // ============================================================================

  String? get title => null;
  Color? get backgroundColor => null;
  bool? get hideAppBar => null;

  /// ✅ NEW: Hiển thị Speed Monitor cố định trong form
  bool? get showSpeedMonitor => null;

  // ============================================================================
  // LIFECYCLE METHODS
  // ============================================================================

  void onInit() {}
  Future<void> onBeforeLoad() async {}
  Future<void> onLoadData() async {}
  Future<void> onAfterLoad() async {}
  void onLoadError(dynamic error) {
    //debugPrint('Load error: $error');
  }

  /// Override method này để cleanup resources khi form bị dispose
  /// Ví dụ: dispose controllers, cancel timers, close streams...
  void onDispose() {
    // Tự động dispose tất cả resources đã register
    _disposeAllResources();
  }

  // ============================================================================
  // RESOURCE MANAGEMENT HELPERS
  // ============================================================================

  /// Register một resource để tự động dispose
  /// Hỗ trợ: TextEditingController, StreamController, Timer, etc
  void registerDisposable(dynamic resource) {
    _disposables.add(resource);
  }

  /// Dispose tất cả resources đã register
  void _disposeAllResources() {
    for (var resource in _disposables) {
      try {
        if (resource is TextEditingController) {
          resource.dispose();
        } else if (resource is StreamController) {
          resource.close();
        } else if (resource is AnimationController) {
          resource.dispose();
        } else if (resource is FocusNode) {
          resource.dispose();
        } else if (resource is ScrollController) {
          resource.dispose();
        } else if (resource is TabController) {
          resource.dispose();
        } else if (resource is PageController) {
          resource.dispose();
        } else // Nếu có method dispose() hoặc close()
        if (resource.runtimeType.toString().contains('Controller') ||
            resource.runtimeType.toString().contains('Stream')) {
          try {
            resource.dispose?.call();
          } catch (_) {
            try {
              resource.close?.call();
            } catch (_) {}
          }
        }
      } catch (e) {
        debugPrint('Error disposing resource: $e');
      }
    }
    _disposables.clear();
  }

  // ============================================================================
  // BUILD METHODS
  // ============================================================================

  Widget buildBody(BuildContext context);
  Widget? buildLoadingWidget() => null;
  Widget? buildErrorWidget(String error) => null;

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Navigate đến form khác
  // ignore: non_constant_identifier_names
  void V_Call(
    String strfrm, {
    bool hideAppBar = false,
    String title = "",
    String cpName = "",
    String strparameter = "",
    dynamic objectdata,
  }) {
    var frm = V_getScreen(
      strfrm,
      title,
      cpName,
      strparameter,
      hideAppBar: hideAppBar,
    );
    if (frm == null) return;
    Navigator.push(_context, MaterialPageRoute(builder: (context) => frm));
  }

  void rebuild() {
    _setState();
  }

  void showLoading([String? message]) {
    showDialog(
      context: _context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(message),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void hideLoading() {
    if (_context.mounted) {
      Navigator.of(_context).pop();
    }
  }
}
