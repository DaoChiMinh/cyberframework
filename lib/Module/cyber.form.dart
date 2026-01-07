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
// lib/Module/cyber.form.dart

class CyberFormView extends StatefulWidget {
  final CyberForm Function() formBuilder;
  final String title;
  final String cp_name;
  final String strparameter;
  final dynamic objectdata;
  final bool hideAppBar;
  final bool showSpeedMonitor;
  final SpeedMonitorPosition speedMonitorPosition;
  final bool isMainScreen;
  final bool enablePageAnimation; // ✅ NEW
  final Duration pageAnimationDuration; // ✅ NEW

  const CyberFormView({
    super.key,
    required this.title,
    required this.formBuilder,
    required this.cp_name,
    required this.strparameter,
    this.objectdata,
    this.hideAppBar = false,
    this.showSpeedMonitor = true,
    this.speedMonitorPosition = SpeedMonitorPosition.appBar,
    this.isMainScreen = false,
    this.enablePageAnimation = true, // ✅ NEW
    this.pageAnimationDuration = const Duration(milliseconds: 400), // ✅ NEW
  });

  @override
  State<CyberFormView> createState() => _CyberFormViewState();
}

class _CyberFormViewState extends State<CyberFormView>
    with SingleTickerProviderStateMixin {
  // ✅ Single ticker (tối ưu nhất)

  late final CyberForm _form;
  bool _isLoading = true;
  String? _errorMessage;

  // ✅ Page-level animation controller (optional, lazy init)
  AnimationController? _pageAnimationController;
  Animation<double>? _pageFadeAnimation;

  @override
  void initState() {
    super.initState();

    // ✅ Create form instance
    _form = widget.formBuilder();
    _form._context = context;
    _form._widget = widget;
    _form._setState = () {
      if (mounted) setState(() {});
    };
    _form._tickerProvider = this; // ✅ Pass ticker provider

    // ✅ Initialize page animation if enabled
    if (widget.enablePageAnimation) {
      _pageAnimationController = AnimationController(
        vsync: this,
        duration: widget.pageAnimationDuration,
      );

      _pageFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _pageAnimationController!,
          curve: Curves.easeOut,
        ),
      );

      // ✅ Pass to form (optional)
      _form._pageAnimationController = _pageAnimationController;
    }

    _initializeForm();
  }

  Future<void> _initializeForm() async {
    try {
      _form.onInit();
      await _form.onBeforeLoad();

      // ✅ Start page animation
      _pageAnimationController?.forward();

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
    // ✅ Dispose page animation controller first
    _pageAnimationController?.dispose();

    // ✅ Then dispose form resources
    _form.onDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _form._context = context;

    Widget body = CyberLanguageBuilder(
      builder: (context, language) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          appBar: (_form.hideAppBar ?? widget.hideAppBar)
              ? null
              : _buildAppBar(),
          backgroundColor: _form.backgroundColor ?? Colors.white,
          body: _buildBodyWithSpeedMonitor(),
          bottomNavigationBar: _buildBottomNavigationBar(),
        ),
      ),
    );

    // ✅ Wrap với page animation nếu enabled
    if (widget.enablePageAnimation && _pageFadeAnimation != null) {
      body = FadeTransition(opacity: _pageFadeAnimation!, child: body);
    }

    return body;
  }

  // ✅ NEW METHOD
  Widget? _buildBottomNavigationBar() {
    // Ẩn nếu form yêu cầu
    if (_form.hideBottomNavigationBar == true) {
      return null;
    }

    // Cho phép form custom bottom navigation bar
    return _form.buildBottomNavigationBar(context);
  }
  // ... rest of code giữ nguyên

  PreferredSizeWidget _buildAppBar() {
    final showInAppBar =
        (widget.showSpeedMonitor || _form.showSpeedMonitor == true) &&
        widget.speedMonitorPosition == SpeedMonitorPosition.appBar;

    return AppBar(
      backgroundColor: Color(0xFF0F3D34),
      title: Text(
        _form.title ?? widget.title,
        style: TextStyle(color: Colors.white),
      ),
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
    // final showMonitor = widget.showSpeedMonitor || _form.showSpeedMonitor == true;
    final showMonitor = _form.showSpeedMonitor ?? widget.showSpeedMonitor;
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
// lib/Module/cyber.form.dart

abstract class CyberForm {
  late BuildContext _context;
  late CyberFormView _widget;
  late VoidCallback _setState;

  // ✅ Animation support (lazy initialization)
  TickerProvider? _tickerProvider;
  AnimationController? _pageAnimationController;
  final Map<String, AnimationController> _namedControllers = {};

  // ✅ Resource management
  final List<dynamic> _disposables = [];
  final Map<Listenable, Set<VoidCallback>> _listeners = {};
  bool _isDisposed = false;

  BuildContext get context => _context;
  CyberFormView get widget => _widget;

  // ============================================================================
  // GETTERS
  // ============================================================================

  String get cp_name => _widget.cp_name;
  String get strparameter => _widget.strparameter;
  dynamic get objectdata => _widget.objectdata;

  // ============================================================================
  // PROPERTIES - Override in subclass
  // ============================================================================

  String? _title;
  Color? _backgroundColor;
  bool? _hideAppBar;
  bool? _showSpeedMonitor;
  bool? _hideBottomNavigationBar;
  Color? XanhChu = Color(0xFF0F3D34);
  // Getters với fallback cho override
  String? get title => _title;
  set title(String? value) => _title = value;

  Color? get backgroundColor => _backgroundColor;
  set backgroundColor(Color? value) => _backgroundColor = value;

  bool? get hideAppBar => _hideAppBar;
  set hideAppBar(bool? value) => _hideAppBar = value;

  bool? get showSpeedMonitor => _showSpeedMonitor;
  set showSpeedMonitor(bool? value) => _showSpeedMonitor = value;

  bool? get hideBottomNavigationBar => _hideBottomNavigationBar;
  set hideBottomNavigationBar(bool? value) => _hideBottomNavigationBar = value;
  // ============================================================================
  // ✅ ANIMATION PROPERTIES
  // ============================================================================

  /// Page animation controller (available if enablePageAnimation = true)
  AnimationController? get pageAnimationController => _pageAnimationController;

  /// Check if ticker provider is available
  bool get canAnimate => _tickerProvider != null;

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
  // ✅ OPTIMIZED: IMPLICIT ANIMATIONS (Recommended - No Controllers Needed)
  // ============================================================================

  /// Fade in/out widget - BEST PERFORMANCE
  Widget fadeTransition({
    required bool show,
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
  }) {
    return AnimatedOpacity(
      opacity: show ? 1.0 : 0.0,
      duration: duration,
      curve: curve,
      child: child,
    );
  }

  /// Animated container - EXCELLENT PERFORMANCE
  Widget animatedBox({
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
    Color? color,
    EdgeInsets? padding,
    EdgeInsets? margin,
    double? width,
    double? height,
    BoxDecoration? decoration,
    AlignmentGeometry? alignment,
  }) {
    return AnimatedContainer(
      duration: duration,
      curve: curve,
      color: decoration == null ? color : null,
      padding: padding,
      margin: margin,
      width: width,
      height: height,
      decoration: decoration,
      alignment: alignment,
      child: child,
    );
  }

  /// Slide transition - GOOD PERFORMANCE
  Widget slideTransition({
    required bool show,
    required Widget child,
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeOut,
    Offset beginOffset = const Offset(0, 0.3),
    Offset endOffset = Offset.zero,
  }) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween(
        begin: show ? beginOffset : endOffset,
        end: show ? endOffset : beginOffset,
      ),
      duration: duration,
      curve: curve,
      builder: (context, offset, child) => Transform.translate(
        offset: Offset(offset.dx * 100, offset.dy * 100),
        child: child,
      ),
      child: child,
    );
  }

  /// Scale transition - GOOD PERFORMANCE
  Widget scaleTransition({
    required bool show,
    required Widget child,
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeOut,
    double beginScale = 0.8,
    double endScale = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(
        begin: show ? beginScale : endScale,
        end: show ? endScale : beginScale,
      ),
      duration: duration,
      curve: curve,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: child,
    );
  }

  /// Rotation transition - GOOD PERFORMANCE
  Widget rotateTransition({
    required bool show,
    required Widget child,
    Duration duration = const Duration(milliseconds: 500),
    Curve curve = Curves.easeOut,
    double turns = 0.125, // 45 degrees = 0.125 turns
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: show ? -turns : 0, end: show ? 0 : turns),
      duration: duration,
      curve: curve,
      builder: (context, value, child) =>
          Transform.rotate(angle: value * 2 * 3.14159, child: child),
      child: child,
    );
  }

  /// Combined slide + fade - GOOD PERFORMANCE
  Widget slideAndFade({
    required bool show,
    required Widget child,
    Duration duration = const Duration(milliseconds: 400),
    Curve curve = Curves.easeOut,
    Offset beginOffset = const Offset(0, 0.2),
  }) {
    return AnimatedOpacity(
      opacity: show ? 1.0 : 0.0,
      duration: duration,
      curve: curve,
      child: TweenAnimationBuilder<Offset>(
        tween: Tween(
          begin: show ? beginOffset : Offset.zero,
          end: show ? Offset.zero : beginOffset,
        ),
        duration: duration,
        curve: curve,
        builder: (context, offset, child) => Transform.translate(
          offset: Offset(offset.dx * 100, offset.dy * 100),
          child: child,
        ),
        child: child,
      ),
    );
  }

  // ============================================================================
  // ✅ ADVANCED: EXPLICIT ANIMATIONS (Use when you need full control)
  // ============================================================================

  /// Get or create named controller - LAZY INITIALIZATION
  AnimationController getController(
    String name, {
    Duration duration = const Duration(milliseconds: 300),
    Duration? reverseDuration,
    double initialValue = 0.0,
    double lowerBound = 0.0,
    double upperBound = 1.0,
  }) {
    // ✅ Return existing controller
    if (_namedControllers.containsKey(name)) {
      return _namedControllers[name]!;
    }

    // ✅ Check ticker provider
    if (_tickerProvider == null) {
      throw Exception(
        'TickerProvider not available. Cannot create AnimationController.\n'
        'Make sure CyberFormView is properly initialized.',
      );
    }

    // ✅ Create new controller
    final controller = AnimationController(
      vsync: _tickerProvider!,
      duration: duration,
      reverseDuration: reverseDuration,
      lowerBound: lowerBound,
      upperBound: upperBound,
    )..value = initialValue;

    _namedControllers[name] = controller;
    registerDisposable(controller);

    return controller;
  }

  /// Create animation from controller
  Animation<T> createAnimation<T>({
    required String controllerName,
    required T begin,
    required T end,
    Curve curve = Curves.linear,
  }) {
    final controller = getController(controllerName);
    return Tween<T>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(parent: controller, curve: curve));
  }

  /// Quick fade animation with controller
  Animation<double> createFadeAnimation(
    String controllerName, {
    Curve curve = Curves.easeOut,
  }) {
    return createAnimation<double>(
      controllerName: controllerName,
      begin: 0.0,
      end: 1.0,
      curve: curve,
    );
  }

  /// Quick slide animation with controller
  Animation<Offset> createSlideAnimation(
    String controllerName, {
    Offset begin = const Offset(0, 0.3),
    Offset end = Offset.zero,
    Curve curve = Curves.easeOut,
  }) {
    return createAnimation<Offset>(
      controllerName: controllerName,
      begin: begin,
      end: end,
      curve: curve,
    );
  }

  /// Quick scale animation with controller
  Animation<double> createScaleAnimation(
    String controllerName, {
    double begin = 0.8,
    double end = 1.0,
    Curve curve = Curves.easeOut,
  }) {
    return createAnimation<double>(
      controllerName: controllerName,
      begin: begin,
      end: end,
      curve: curve,
    );
  }

  // ============================================================================
  // ✅ STAGGERED ANIMATIONS (For complex sequences)
  // ============================================================================

  /// Play animations in sequence
  Future<void> playSequence(
    List<AnimationController> controllers, {
    Duration delay = const Duration(milliseconds: 100),
  }) async {
    for (var controller in controllers) {
      if (_isDisposed) break;
      await controller.forward();
      await Future.delayed(delay);
    }
  }

  /// Play named controllers in sequence
  Future<void> playControllerSequence(
    List<String> controllerNames, {
    Duration delay = const Duration(milliseconds: 100),
  }) async {
    for (var name in controllerNames) {
      if (_isDisposed) break;
      final controller = _namedControllers[name];
      if (controller != null) {
        await controller.forward();
        await Future.delayed(delay);
      }
    }
  }

  // ============================================================================
  // ✅ PERFORMANCE MONITORING
  // ============================================================================

  /// Get active controller count
  int get activeControllerCount => _namedControllers.length;

  /// Log performance metrics
  void logAnimationMetrics() {
    debugPrint('🎭 [$runtimeType] Animation Metrics:');
    debugPrint('   Active Controllers: ${_namedControllers.length}');
    debugPrint('   Controller Names: ${_namedControllers.keys.join(", ")}');
    debugPrint('   Disposables: ${_disposables.length}');
    debugPrint('   Listeners: ${_listeners.length}');

    // ✅ Memory estimation
    final estimatedMemory =
        (_namedControllers.length * 200) + (_disposables.length * 50);
    debugPrint('   Estimated Memory: ~${estimatedMemory}bytes');
  }

  // ============================================================================
  // ✅ RESOURCE MANAGEMENT
  // ============================================================================

  void registerDisposable(dynamic resource) {
    if (resource == null || _isDisposed) return;
    _disposables.add(resource);
  }

  void registerListener(Listenable listenable, VoidCallback listener) {
    if (_isDisposed) return;
    listenable.addListener(listener);
    _listeners.putIfAbsent(listenable, () => {}).add(listener);
  }

  void removeListener(Listenable listenable, VoidCallback listener) {
    listenable.removeListener(listener);
    _listeners[listenable]?.remove(listener);
  }

  void _disposeAllResources() {
    if (_isDisposed) return;
    _isDisposed = true;

    // 1. Dispose named controllers first
    for (var entry in _namedControllers.entries) {
      try {
        entry.value.dispose();
      } catch (e) {
        debugPrint('Error disposing controller ${entry.key}: $e');
      }
    }
    _namedControllers.clear();

    // 2. Remove all listeners
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

    // 3. Dispose all resources
    for (var resource in _disposables) {
      try {
        _disposeResource(resource);
      } catch (e) {
        debugPrint('Error disposing ${resource.runtimeType}: $e');
      }
    }
    _disposables.clear();
  }

  void _disposeResource(dynamic resource) {
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
  Widget? buildBottomNavigationBar(BuildContext context) => null;
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

  bool get isDisposed => _isDisposed;
}
