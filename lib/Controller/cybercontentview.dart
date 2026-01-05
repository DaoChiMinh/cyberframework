import 'package:cyberframework/cyberframework.dart';

// ============================================================================
// ABSTRACT CLASS - CyberContentViewForm
// ============================================================================

/// Abstract class cho ContentView với lifecycle methods giống CyberForm
/// Hỗ trợ truyền parameters qua constructor
///
/// Usage:
/// ```dart
/// class MyView extends CyberContentViewForm {
///   MyView({String? title}) : super(cpName: "MyView", strParameter: title ?? "");
///
///   @override
///   Widget buildBody(BuildContext context) {
///     return Container(child: Text('Hello'));
///   }
/// }
///
/// // Show popup
/// await MyView(title: "Test").showAsDialog(context);
/// ```
abstract class CyberContentViewForm {
  BuildContext? _context;
  String _cpName;
  String _strParameter;
  dynamic _objectData;
  VoidCallback? _setState;

  // ============================================================================
  // CONSTRUCTOR - Cho phép truyền parameters
  // ============================================================================

  CyberContentViewForm({
    String? cpName,
    String? strParameter,
    dynamic objectData,
  }) : _cpName = cpName ?? "",
       _strParameter = strParameter ?? "",
       _objectData = objectData;

  // ============================================================================
  // GETTERS
  // ============================================================================

  /// BuildContext của ContentView (throw error nếu chưa mount)
  BuildContext get context {
    if (_context == null) {
      throw StateError(
        'Context chưa được khởi tạo. ContentView chưa được mount.',
      );
    }
    return _context!;
  }

  /// Tên component
  String get cpName => _cpName;

  /// String parameter
  String get strParameter => _strParameter;

  /// Object data (dynamic)
  dynamic get objectData => _objectData;

  /// Check xem context có sẵn sàng không
  bool get hasContext => _context != null && _context!.mounted;

  // ============================================================================
  // SETTERS - Cho phép update parameters
  // ============================================================================

  /// Update cpName (có thể gọi từ code)
  set cpName(String value) => _cpName = value;

  /// Update strParameter (có thể gọi từ code)
  set strParameter(String value) => _strParameter = value;

  /// Update objectData (có thể gọi từ code)
  set objectData(dynamic value) => _objectData = value;

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
  /// Called khi ContentView được tạo, trước khi load data
  void onInit() {}

  /// 2. onBeforeLoad - Chuẩn bị trước khi load (async)
  /// Called sau onInit, trước khi load data
  Future<void> onBeforeLoad() async {}

  /// 3. onLoadData - Load data từ API (async)
  /// Called để load data chính từ API/Database
  Future<void> onLoadData() async {}

  /// 4. onAfterLoad - Xử lý sau khi load xong (async)
  /// Called sau khi load data thành công
  Future<void> onAfterLoad() async {}

  /// 5. onLoadError - Xử lý lỗi khi load (sync)
  /// Called khi có lỗi xảy ra trong quá trình load
  void onLoadError(dynamic error) {
    debugPrint('❌ [$runtimeType] Load error: $error');
  }

  /// 6. onDispose - Cleanup (sync)
  /// Called khi ContentView bị dispose, cleanup resources ở đây
  void onDispose() {}

  // ============================================================================
  // BUILD METHODS
  // ============================================================================

  /// Build nội dung chính của ContentView (REQUIRED)
  /// Method này BẮT BUỘC phải implement
  Widget buildBody(BuildContext context);

  /// Build loading widget (OPTIONAL)
  /// Override để custom loading UI
  Widget? buildLoadingWidget() => null;

  /// Build error widget (OPTIONAL)
  /// Override để custom error UI
  Widget? buildErrorWidget(String error) => null;

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Rebuild ContentView
  /// Gọi khi cần rebuild UI (tương tự setState)
  void rebuild() {
    if (_setState != null && hasContext) {
      _setState!();
    }
  }

  /// Show loading dialog
  /// Hiển thị dialog loading với message tùy chọn
  void showLoading([String? message]) {
    if (!hasContext) return;

    showDialog<void>(
      context: _context!,
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
  /// Đóng dialog loading đang hiển thị
  void hideLoading() {
    if (hasContext) {
      Navigator.of(_context!).pop();
    }
  }

  // ============================================================================
  // POPUP METHODS
  // ============================================================================

  /// Show ContentView as popup với tùy chỉnh đầy đủ
  ///
  /// Usage:
  /// ```dart
  /// final result = await myView.showPopup<String>(
  ///   context,
  ///   position: PopupPosition.center,
  ///   width: 400,
  ///   height: 600,
  /// );
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
  ///
  /// Usage:
  /// ```dart
  /// final result = await myView.showBottom<Product>(context);
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
  ///
  /// Usage:
  /// ```dart
  /// final result = await myView.showAsDialog<bool>(
  ///   context,
  ///   width: 400,
  ///   height: 300,
  /// );
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
  ///
  /// Usage trong ContentView:
  /// ```dart
  /// void _onSave() {
  ///   closePopup(context, myData);
  /// }
  /// ```
  void closePopup<T>(BuildContext context, [T? result]) {
    CyberPopup.close(context, result);
  }
}

// ============================================================================
// WIDGET WRAPPER - CyberContentViewWidget
// ============================================================================

/// Widget wrapper cho CyberContentViewForm với lifecycle management
///
/// Đây là widget internal của framework, user không nên dùng trực tiếp.
/// Thay vào đó, dùng các method showPopup/showBottom/showAsDialog của CyberContentViewForm
/// hoặc dùng V_callView() cho embedded view.
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

    // Set parameters từ widget (nếu có)
    // Ưu tiên parameters từ widget, fallback về constructor của form
    if (widget.cpName.isNotEmpty) {
      _form.internalCpName = widget.cpName;
    }
    if (widget.strParameter.isNotEmpty) {
      _form.internalStrParameter = widget.strParameter;
    }
    if (widget.objectData != null) {
      _form.internalObjectData = widget.objectData;
    }

    _form.internalContext = context;
    _form.internalSetState = () {
      if (mounted) setState(() {});
    };

    _initializeForm();
  }

  Future<void> _initializeForm() async {
    try {
      // Call lifecycle methods theo thứ tự
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
    // Update context mỗi lần build
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
