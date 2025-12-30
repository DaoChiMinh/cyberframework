// lib/Module/cyber.form.dart

import 'package:cyberframework/cyberframework.dart';

/// Vị trí hiển thị Speed Monitor trong CyberForm
enum SpeedMonitorPosition {
  topLeft,
  topRight,
  topCenter,
  bottomLeft,
  bottomRight,
  bottomCenter,
  appBar,
  banner,
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
  final bool isMainScreen;

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
    this.isMainScreen = false,
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

    // ✅ Create NEW form instance
    _form = widget.formBuilder();
    _form._context = context;
    _form._widget = widget;
    _form._setState = () {
      if (mounted) setState(() {});
    };

    _initializeForm();
  }

  Future<void> _initializeForm() async {
    try {
      _form.onInit();
      await _form.onBeforeLoad();
      await _form.onLoadData();
      await _form.onAfterLoad();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
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
    // ✅ Proper cleanup
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

  Widget _buildBodyWithSpeedMonitor() {
    final body = _buildBody();
    final showMonitor =
        widget.showSpeedMonitor || _form.showSpeedMonitor == true;

    var position = widget.speedMonitorPosition;
    if (widget.isMainScreen &&
        (_form.hideAppBar ?? widget.hideAppBar) &&
        position == SpeedMonitorPosition.appBar) {
      position = SpeedMonitorPosition.topRight;
    }

    if (!showMonitor || position == SpeedMonitorPosition.appBar) {
      return body;
    }

    if (position == SpeedMonitorPosition.banner) {
      return Column(
        children: [
          const CyberSpeedBanner(),
          Expanded(child: body),
        ],
      );
    }

    return Stack(children: [body, _buildFloatingSpeedMonitor()]);
  }

  Widget _buildFloatingSpeedMonitor() {
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

  // ✅ Typed resource management
  final List<dynamic> _disposables = [];
  final Map<Listenable, Set<VoidCallback>> _listeners = {};
  bool _isDisposed = false;

  BuildContext get context => _context;
  CyberFormView get widget => _widget;

  // ============================================================================
  // GETTERS
  // ============================================================================

  // ignore: non_constant_identifier_names
  String get cp_name => _widget.cp_name;
  String get strparameter => _widget.strparameter;
  dynamic get objectdata => _widget.objectdata;

  // ============================================================================
  // PROPERTIES - Override in subclass
  // ============================================================================

  String? get title => null;
  Color? get backgroundColor => null;
  bool? get hideAppBar => null;
  bool? get showSpeedMonitor => null;

  // ============================================================================
  // LIFECYCLE METHODS
  // ============================================================================

  void onInit() {}
  Future<void> onBeforeLoad() async {}
  Future<void> onLoadData() async {}
  Future<void> onAfterLoad() async {}
  void onLoadError(dynamic error) {}

  void onDispose() {
    _disposeAllResources();
  }

  // ============================================================================
  // ✅ IMPROVED: Resource Management
  // ============================================================================

  /// Register resource for automatic disposal
  void registerDisposable(dynamic resource) {
    if (resource == null || _isDisposed) return;
    _disposables.add(resource);
  }

  /// ✅ Register listener with tracking
  void registerListener(Listenable listenable, VoidCallback listener) {
    if (_isDisposed) return;

    listenable.addListener(listener);
    _listeners.putIfAbsent(listenable, () => {}).add(listener);
  }

  /// ✅ Remove specific listener
  void removeListener(Listenable listenable, VoidCallback listener) {
    listenable.removeListener(listener);
    _listeners[listenable]?.remove(listener);
  }

  /// ✅ FIXED: Proper disposal implementation
  void _disposeAllResources() {
    if (_isDisposed) return;
    _isDisposed = true;

    // 1. Remove all listeners first
    for (var entry in _listeners.entries) {
      final listenable = entry.key;
      final listeners = entry.value;

      for (var listener in listeners) {
        try {
          listenable.removeListener(listener);
        } catch (e) {
          debugPrint('Error removing listener: $e');
        }
      }
    }
    _listeners.clear();

    // 2. Dispose all resources
    for (var resource in _disposables) {
      try {
        _disposeResource(resource);
      } catch (e) {
        debugPrint('Error disposing ${resource.runtimeType}: $e');
      }
    }
    _disposables.clear();
  }

  /// ✅ Smart resource disposal with type checking
  void _disposeResource(dynamic resource) {
    // ✅ Check concrete types (fastest path)
    if (resource is TextEditingController) {
      resource.dispose();
      return;
    }
    if (resource is ScrollController) {
      resource.dispose();
      return;
    }
    if (resource is TabController) {
      resource.dispose();
      return;
    }
    if (resource is PageController) {
      resource.dispose();
      return;
    }
    if (resource is AnimationController) {
      resource.dispose();
      return;
    }
    if (resource is FocusNode) {
      resource.dispose();
      return;
    }
    if (resource is StreamController) {
      resource.close();
      return;
    }
    if (resource is StreamSubscription) {
      resource.cancel();
      return;
    }
    if (resource is Timer) {
      resource.cancel();
      return;
    }
    if (resource is ChangeNotifier) {
      resource.dispose();
      return;
    }
    if (resource is ValueNotifier) {
      resource.dispose();
      return;
    }

    // ✅ Try dynamic dispatch as fallback
    try {
      final dynamic obj = resource;
      if (obj.dispose != null) {
        obj.dispose();
        return;
      }
    } catch (_) {}

    try {
      final dynamic obj = resource;
      if (obj.close != null) {
        obj.close();
        return;
      }
    } catch (_) {}

    try {
      final dynamic obj = resource;
      if (obj.cancel != null) {
        obj.cancel();
        return;
      }
    } catch (_) {}
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
    if (!_isDisposed && _context.mounted) {
      _setState();
    }
  }

  void showLoading([String? message]) {
    if (_isDisposed || !_context.mounted) return;

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
    if (!_isDisposed && _context.mounted) {
      Navigator.of(_context).pop();
    }
  }

  /// ✅ Check if form is disposed
  bool get isDisposed => _isDisposed;
}
