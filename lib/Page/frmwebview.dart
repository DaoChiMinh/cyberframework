import 'package:cyberframework/cyberframework.dart';

class Frmwebview extends CyberForm {
  // ignore: non_constant_identifier_names
  String? Url;
  // Tự động wrap PDF URL với Google Docs Viewer
  String? get _processedUrl {
    if (Url == null) return null;

    // Kiểm tra nếu là PDF URL
    if (Url!.toLowerCase().endsWith('.pdf')) {
      return "https://docs.google.com/gview?embedded=true&url=${Uri.encodeComponent(Url!)}";
    }
    return Url;
  }

  final GlobalKey<CyberWebViewState> _webViewKey =
      GlobalKey<CyberWebViewState>();

  @override
  bool? get hideAppBar => false;

  @override
  String? get title => Url ?? "WebView";

  @override
  Color? get backgroundColor => Colors.white;

  @override
  Widget buildBody(BuildContext context) {
    return CyberWebView(
      key: _webViewKey,
      url: _processedUrl,
      clearCacheOnDispose: true,
    );
  }

  // ✅ OVERRIDE onDispose() để cleanup WebView
  @override
  void onDispose() {
    // Clear cache trước khi dispose
    _webViewKey.currentState?.clearCache();
    Future.delayed(Duration(milliseconds: 100), () {
      // Trigger GC bằng cách clear các references
      Url = null;
    });

    // Gọi super để dispose resources khác
    super.onDispose();
  }

  // Các method tiện ích
  Future<void> refreshWebView() async {
    await _webViewKey.currentState?.reload();
  }

  Future<void> clearWebViewCache() async {
    await _webViewKey.currentState?.clearCache();
  }

  Future<void> goBack() async {
    await _webViewKey.currentState?.goBack();
  }

  Future<void> goForward() async {
    await _webViewKey.currentState?.goForward();
  }
}
