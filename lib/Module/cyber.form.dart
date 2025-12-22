import 'package:cyberframework/Module/Screenmap.dart';
import 'package:flutter/material.dart';

class CyberFormView extends StatefulWidget {
  final CyberForm Function() formBuilder;
  final String title;
  final String cp_name;
  final String strparameter;
  final bool hideAppBar;
  const CyberFormView({
    super.key,
    required this.title,
    required this.formBuilder,
    required this.cp_name,
    required this.strparameter,
    this.hideAppBar = false,
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
    _form.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _form._context = context;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: widget.hideAppBar
            ? null
            : AppBar(
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                title: Text(widget.title),
              ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    // Show loading
    if (_isLoading) {
      return _form.buildLoadingWidget() ??
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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

abstract class CyberForm {
  late BuildContext _context;
  late CyberFormView _widget;
  late VoidCallback _setState;

  BuildContext get context => _context;
  CyberFormView get widget => _widget;

  // ============================================================================
  // LIFECYCLE METHODS - Theo thứ tự thực thi
  // ============================================================================

  /// 1. onInit - Khởi tạo cơ bản (sync)
  /// Được gọi đầu tiên, dùng để khởi tạo biến, controller...
  /// Không nên call API ở đây
  void onInit() {}

  /// 2. onBeforeLoad - Chuẩn bị trước khi load (async)
  /// Dùng để validate, check permission, prepare data...
  Future<void> onBeforeLoad() async {}

  /// 3. onLoadData - Load data từ API (async)
  /// **ĐÂY LÀ NƠI CALL API ĐỂ LOAD DATA**
  /// Màn hình sẽ chờ method này chạy xong mới hiển thị
  Future<void> onLoadData() async {}

  /// 4. onAfterLoad - Xử lý sau khi load xong (async)
  /// Dùng để process data, set default values...
  Future<void> onAfterLoad() async {}

  /// 5. onLoadError - Xử lý lỗi khi load (sync)
  /// Được gọi khi có exception trong quá trình load
  void onLoadError(dynamic error) {
    debugPrint('Load error: $error');
  }

  /// 6. onDispose - Cleanup (sync)
  /// Được gọi khi form bị dispose
  void onDispose() {}

  // ============================================================================
  // BUILD METHODS
  // ============================================================================

  /// Build nội dung chính của form (REQUIRED)
  Widget buildBody(BuildContext context);

  /// Build loading widget (OPTIONAL)
  /// Override để custom loading UI
  Widget? buildLoadingWidget() {
    return null; // Sẽ dùng default loading
  }

  /// Build error widget (OPTIONAL)
  /// Override để custom error UI
  Widget? buildErrorWidget(String error) {
    return null; // Sẽ dùng default error
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Navigate đến form khác
  void V_Call(String strfrm, String title, String cpName, String strparameter) {
    var frm = V_getScreen(strfrm, title, cpName, strparameter);
    if (frm == null) return;
    Navigator.push(_context, MaterialPageRoute(builder: (context) => frm));
  }

  /// Rebuild form
  void rebuild() {
    _setState();
  }

  /// Show loading dialog
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

  /// Hide loading dialog
  void hideLoading() {
    if (_context.mounted) {
      Navigator.of(_context).pop();
    }
  }
}
