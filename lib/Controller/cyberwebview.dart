import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CyberWebView extends StatefulWidget {
  final String? url;
  final double? width;
  final double? height;
  final bool enableJavaScript;
  final bool enableZoom;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final bool clearCacheOnDispose; // Mới: tự động xóa cache khi dispose

  const CyberWebView({
    super.key,
    this.url,
    this.width,
    this.height,
    this.enableJavaScript = true,
    this.enableZoom = true,
    this.margin,
    this.padding,
    this.clearCacheOnDispose = true, // Mặc định xóa cache
  });

  @override
  State<CyberWebView> createState() => CyberWebViewState();
}

class CyberWebViewState extends State<CyberWebView>
    with WidgetsBindingObserver {
  WebViewController? _controller;
  bool _isLoading = true;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(
        widget.enableJavaScript
            ? JavaScriptMode.unrestricted
            : JavaScriptMode.disabled,
      )
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (!_isDisposed && mounted) {
              setState(() => _isLoading = true);
            }
          },
          onPageFinished: (String url) {
            if (!_isDisposed && mounted) {
              setState(() => _isLoading = false);
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      // Tối ưu bộ nhớ cache
      ..enableZoom(widget.enableZoom);

    _loadUrl(widget.url);
  }

  @override
  void didUpdateWidget(CyberWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _loadUrl(widget.url);
    }

    // Cập nhật JavaScript mode nếu thay đổi
    if (oldWidget.enableJavaScript != widget.enableJavaScript) {
      _controller?.setJavaScriptMode(
        widget.enableJavaScript
            ? JavaScriptMode.unrestricted
            : JavaScriptMode.disabled,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Tạm dừng web content khi app ở background để tiết kiệm RAM
    if (_controller != null && !_isDisposed) {
      switch (state) {
        case AppLifecycleState.paused:
        case AppLifecycleState.inactive:
          // WebView tự động pause khi app không active
          break;
        case AppLifecycleState.resumed:
          // WebView tự động resume
          break;
        case AppLifecycleState.detached:
        case AppLifecycleState.hidden:
          break;
      }
    }
  }

  void _loadUrl(String? url) {
    if (url == null || url.isEmpty || _isDisposed) return;

    String finalUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      finalUrl = 'https://$url';
    }

    _controller?.loadRequest(Uri.parse(finalUrl));
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);

    // Cleanup WebView để giải phóng bộ nhớ
    _cleanupWebView();

    super.dispose();
  }

  Future<void> _cleanupWebView() async {
    if (_controller != null) {
      try {
        // Dừng loading nếu đang load
        // Load blank page để giải phóng tài nguyên web content
        await _controller!.loadRequest(Uri.parse('about:blank'));

        // Xóa cache nếu được cấu hình
        if (widget.clearCacheOnDispose) {
          await _controller!.clearCache();
          await _controller!.clearLocalStorage();
        }
        await Future.delayed(Duration(milliseconds: 50));
      } catch (e) {
        debugPrint('Error cleaning up WebView: $e');
      }

      _controller = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.url == null || widget.url!.isEmpty) {
      return const Center(child: Text('No URL provided'));
    }

    if (_controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    Widget webView = Stack(
      children: [
        WebViewWidget(controller: _controller!),
        if (_isLoading)
          Container(
            color: Colors.white.withAlpha(80),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );

    if (widget.width != null || widget.height != null) {
      webView = SizedBox(
        width: widget.width,
        height: widget.height ?? 400,
        child: webView,
      );
    }

    if (widget.padding != null) {
      webView = Padding(padding: widget.padding!, child: webView);
    }

    if (widget.margin != null) {
      webView = Padding(padding: widget.margin!, child: webView);
    }

    return webView;
  }

  // Public methods
  Future<void> reload() async {
    if (_controller != null && !_isDisposed) {
      await _controller!.reload();
    }
  }

  Future<void> goBack() async {
    if (_controller != null && !_isDisposed) {
      await _controller!.goBack();
    }
  }

  Future<void> goForward() async {
    if (_controller != null && !_isDisposed) {
      await _controller!.goForward();
    }
  }

  Future<bool> canGoBack() async {
    if (_controller != null && !_isDisposed) {
      return await _controller!.canGoBack();
    }
    return false;
  }

  Future<bool> canGoForward() async {
    if (_controller != null && !_isDisposed) {
      return await _controller!.canGoForward();
    }
    return false;
  }

  void loadUrl(String url) {
    _loadUrl(url);
  }

  // Thêm method để clear cache thủ công
  Future<void> clearCache() async {
    if (_controller != null && !_isDisposed) {
      await _controller!.clearCache();
      await _controller!.clearLocalStorage();
    }
  }

  // Thêm method để stop loading
  Future<void> stopLoading() async {
    if (_controller != null && !_isDisposed) {
      await _controller!.loadRequest(Uri.parse('about:blank'));
    }
  }
}
