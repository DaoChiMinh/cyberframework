import 'package:cyberframework/cyberframework.dart';

class CyberFormView extends StatefulWidget {
  final CyberForm Function() formBuilder;
  final String title;
  // ignore: non_constant_identifier_names
  final String cp_name;
  final String strparameter;
  final dynamic objectdata; // ✅ THÊM objectdata
  final bool hideAppBar;

  const CyberFormView({
    super.key,
    required this.title,
    required this.formBuilder,
    // ignore: non_constant_identifier_names
    required this.cp_name,
    required this.strparameter,
    this.objectdata, // ✅ THÊM objectdata (optional)
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

    return CyberLanguageBuilder(
      builder: (context, language) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          appBar: (_form.hideAppBar ?? widget.hideAppBar)
              ? null
              : AppBar(
                  backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                  title: Text(_form.title ?? widget.title),
                ),
          backgroundColor: _form.backgroundColor ?? Colors.white,
          body: _buildBody(),
        ),
      ),
    );
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
                Text(ngonngu('Đang tải dữ liệu...', 'Loading data...')),
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
                Text('${ngonngu("Lỗi", "Error")}: $_errorMessage'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                    });
                    _initializeForm();
                  },
                  child: Text(ngonngu('Thử lại', 'Retry')),
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

  BuildContext get context => _context;
  CyberFormView get widget => _widget;

  // ============================================================================
  // ✅ THÊM GETTERS ĐỂ TRUY CẬP CÁC THAM SỐ
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

  // ============================================================================
  // LIFECYCLE METHODS
  // ============================================================================

  void onInit() {}
  Future<void> onBeforeLoad() async {}
  Future<void> onLoadData() async {}
  Future<void> onAfterLoad() async {}
  void onLoadError(dynamic error) {
    debugPrint('Load error: $error');
  }

  void onDispose() {}

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
    dynamic objectdata, // ✅ THÊM objectdata parameter
  }) {
    var frm = V_getScreen(
      strfrm,
      title,
      cpName,
      strparameter,
      hideAppBar: hideAppBar,
      objectdata: objectdata, // ✅ Truyền objectdata
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
