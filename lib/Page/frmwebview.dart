import 'package:cyberframework/cyberframework.dart';

class Frmwebview extends CyberForm {
  // ignore: non_constant_identifier_names
  String? Url;

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
    debugPrint("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
    return CyberWebView(key: _webViewKey, url: Url, clearCacheOnDispose: true);
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
    debugPrint("bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb");
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
