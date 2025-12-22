import 'package:cyberframework/cyberframework.dart';

// ============================================================================
// ABSTRACT CLASS - CyberContentViewForm
// ============================================================================

/// Abstract class cho ContentView với lifecycle methods giống CyberForm
abstract class CyberContentViewForm {
  late BuildContext _context;
  late String _cpName;
  late String _strParameter;
  late dynamic _objectData;
  late VoidCallback _setState;

  BuildContext get context => _context;
  String get cpName => _cpName;
  String get strParameter => _strParameter;
  dynamic get objectData => _objectData;

  // ============================================================================
  // INTERNAL SETTERS (for framework use only, not for user code)
  // ============================================================================

  /// @nodoc - Internal use only
  set internalCpName(String value) => _cpName = value;

  /// @nodoc - Internal use only
  set internalStrParameter(String value) => _strParameter = value;

  /// @nodoc - Internal use only
  set internalObjectData(dynamic value) => _objectData = value;

  /// @nodoc - Internal use only
  set internalContext(BuildContext value) => _context = value;

  /// @nodoc - Internal use only
  set internalSetState(VoidCallback value) => _setState = value;

  // ============================================================================
  // LIFECYCLE METHODS
  // ============================================================================

  /// 1. onInit - Khởi tạo cơ bản (sync)
  void onInit() {}

  /// 2. onBeforeLoad - Chuẩn bị trước khi load (async)
  Future<void> onBeforeLoad() async {}

  /// 3. onLoadData - Load data từ API (async)
  Future<void> onLoadData() async {}

  /// 4. onAfterLoad - Xử lý sau khi load xong (async)
  Future<void> onAfterLoad() async {}

  /// 5. onLoadError - Xử lý lỗi khi load (sync)
  void onLoadError(dynamic error) {
    debugPrint('Load error: $error');
  }

  /// 6. onDispose - Cleanup (sync)
  void onDispose() {}

  // ============================================================================
  // BUILD METHODS
  // ============================================================================

  /// Build nội dung chính của ContentView (REQUIRED)
  Widget buildBody(BuildContext context);

  /// Build loading widget (OPTIONAL)
  Widget? buildLoadingWidget() => null;

  /// Build error widget (OPTIONAL)
  Widget? buildErrorWidget(String error) => null;

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Rebuild ContentView
  void rebuild() => _setState();

  /// Show loading dialog
  void showLoading([String? message]) {
    // Use Flutter's showDialog explicitly
    showDialog<void>(
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

  /// Hide loading dialog
  void hideLoading() {
    if (_context.mounted) Navigator.of(_context).pop();
  }

  // ============================================================================
  // POPUP METHODS - NEW! 🎉
  // ============================================================================

  /// Show ContentView as popup
  /// Usage:
  /// ```dart
  /// final result = await myContentView.showPopup(context);
  /// ```
  Future<T?> showPopup<T>(
    BuildContext context, {
    PopupPosition position = PopupPosition.center,
    PopupAnimation animation = PopupAnimation.slideAndFade,
    bool barrierDismissible = true,
    Color? barrierColor,
    EdgeInsets? margin,
    EdgeInsets? padding,
    double? width,
    double? height,
    BorderRadius? borderRadius,
    Color? backgroundColor,
  }) async {
    final widget = CyberContentViewWidget(
      formBuilder: () => this,
      cpName: _cpName,
      strParameter: _strParameter,
      objectData: _objectData,
    );

    final popup = CyberPopup(
      context: context,
      child: widget,
      position: position,
      animation: animation,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      margin: margin,
      padding: padding,
      width: width,
      height: height,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
    );

    return await popup.show<T>();
  }

  /// Show ContentView as bottom sheet
  /// Usage:
  /// ```dart
  /// final result = await myContentView.showBottom(context);
  /// ```
  Future<T?> showBottom<T>(
    BuildContext context, {
    PopupAnimation animation = PopupAnimation.slideAndFade,
    bool barrierDismissible = true,
    Color? barrierColor,
    EdgeInsets? margin,
    EdgeInsets? padding,
    BorderRadius? borderRadius,
    Color? backgroundColor,
  }) async {
    return await showPopup<T>(
      context,
      position: PopupPosition.bottom,
      animation: animation,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      margin: margin,
      padding: padding,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
    );
  }

  /// Show ContentView as center dialog
  /// Usage:
  /// ```dart
  /// final result = await myContentView.showAsDialog(context);
  /// ```
  Future<T?> showAsDialog<T>(
    BuildContext context, {
    PopupAnimation animation = PopupAnimation.scale,
    bool barrierDismissible = true,
    Color? barrierColor,
    EdgeInsets? margin,
    EdgeInsets? padding,
    double? width,
    double? height,
    BorderRadius? borderRadius,
    Color? backgroundColor,
  }) async {
    return await showPopup<T>(
      context,
      position: PopupPosition.center,
      animation: animation,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      margin: margin,
      padding: padding,
      width: width,
      height: height,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
    );
  }

  /// Close popup với result
  /// Usage trong ContentView:
  /// ```dart
  /// closePopup(context, result);
  /// ```
  void closePopup<T>(BuildContext context, [T? result]) {
    CyberPopup.close(context, result);
  }
}

// ============================================================================
// WIDGET WRAPPER - CyberContentViewWidget
// ============================================================================

/// Widget wrapper cho CyberContentViewForm với lifecycle management
class CyberContentViewWidget extends StatefulWidget {
  final CyberContentViewForm Function() formBuilder;
  final String cpName;
  final String strParameter;
  final dynamic objectData;

  const CyberContentViewWidget({
    super.key,
    required this.formBuilder,
    this.cpName = "",
    this.strParameter = "",
    this.objectData,
  });

  @override
  State<CyberContentViewWidget> createState() => _CyberContentViewWidgetState();
}

class _CyberContentViewWidgetState extends State<CyberContentViewWidget> {
  late final CyberContentViewForm _form;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _form = widget.formBuilder();
    _form.internalContext = context;
    _form.internalCpName = widget.cpName;
    _form.internalStrParameter = widget.strParameter;
    _form.internalObjectData = widget.objectData;
    _form.internalSetState = () {
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
        setState(() => _isLoading = false);
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
    _form.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _form.internalContext = context;

    return _buildBody();
  }

  Widget _buildBody() {
    // Show loading
    if (_isLoading) {
      return _form.buildLoadingWidget() ??
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Đang tải dữ liệu...'),
              ],
            ),
          );
    }

    // Show error
    if (_errorMessage != null) {
      return _form.buildErrorWidget(_errorMessage!) ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Lỗi: $_errorMessage'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    _initializeForm();
                  },
                  child: const Text('Thử lại'),
                ),
              ],
            ),
          );
    }

    // Show content
    return _form.buildBody(context);
  }
}

// ============================================================================
// LEGACY CLASS - CyberContentView (For backward compatibility)
// ============================================================================

/// Legacy CyberContentView class cho popup (giữ lại để backward compatible)
class CyberContentView extends StatelessWidget {
  final Widget child;
  final PopupPosition position;
  final PopupAnimation animation;
  final bool barrierDismissible;
  final Color? barrierColor;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final BoxShadow? boxShadow;
  final Duration transitionDuration;
  final bool isScrollControlled;

  final Function(dynamic)? onClose;
  final Function()? onShow;
  final Function()? onBeforeShow;
  final Function(dynamic)? onAfterClose;

  const CyberContentView({
    super.key,
    required this.child,
    this.position = PopupPosition.center,
    this.animation = PopupAnimation.slideAndFade,
    this.barrierDismissible = true,
    this.barrierColor,
    this.margin,
    this.padding,
    this.width,
    this.height,
    this.borderRadius,
    this.backgroundColor,
    this.boxShadow,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.isScrollControlled = true,
    this.onClose,
    this.onShow,
    this.onBeforeShow,
    this.onAfterClose,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }

  Future<T?> show<T>(BuildContext context) async {
    onBeforeShow?.call();

    final popup = CyberPopup(
      context: context,
      child: child,
      position: position,
      animation: animation,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      margin: margin,
      padding: padding,
      width: width,
      height: height,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      boxShadow: boxShadow,
      transitionDuration: transitionDuration,
      isScrollControlled: isScrollControlled,
      onShow: onShow,
      onClose: (result) {
        onClose?.call(result);
        onAfterClose?.call(result);
      },
    );

    return await popup.show<T>();
  }

  Future<T?> showBottom<T>(BuildContext context) async {
    onBeforeShow?.call();

    final popup = CyberPopup(
      context: context,
      child: child,
      position: PopupPosition.bottom,
      animation: animation,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      margin: margin,
      padding: padding,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      boxShadow: boxShadow,
      transitionDuration: transitionDuration,
      isScrollControlled: isScrollControlled,
      onShow: onShow,
      onClose: (result) {
        onClose?.call(result);
        onAfterClose?.call(result);
      },
    );

    return await popup.show<T>();
  }

  Future<T?> showWith<T>(
    BuildContext context, {
    PopupPosition? position,
    PopupAnimation? animation,
    bool? barrierDismissible,
  }) async {
    final popup = CyberPopup(
      context: context,
      child: child,
      position: position ?? this.position,
      animation: animation ?? this.animation,
      barrierDismissible: barrierDismissible ?? this.barrierDismissible,
      barrierColor: barrierColor,
      margin: margin,
      padding: padding,
      width: width,
      height: height,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      boxShadow: boxShadow,
      transitionDuration: transitionDuration,
      isScrollControlled: isScrollControlled,
      onShow: onShow,
      onClose: onClose,
    );

    return await popup.show<T>();
  }
}
