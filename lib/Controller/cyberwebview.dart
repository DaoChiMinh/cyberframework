import 'package:cyberframework/cyberframework.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CyberWebView extends StatefulWidget {
  final CyberWebViewController? controller;
  final String? url;
  final String? html;
  final double? width;
  final double? height;
  final bool enableJavaScript;
  final bool enableZoom;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final bool clearCacheOnDispose;

  const CyberWebView({
    super.key,
    this.controller,
    this.url,
    this.html,
    this.width,
    this.height,
    this.enableJavaScript = true,
    this.enableZoom = true,
    this.margin,
    this.padding,
    this.clearCacheOnDispose = true,
  }) : assert(
         controller == null || (url == null && html == null),
         'CyberWebView: không được dùng controller cùng với url/html trực tiếp',
       );

  @override
  State<CyberWebView> createState() => CyberWebViewState();
}

class CyberWebViewState extends State<CyberWebView>
    with WidgetsBindingObserver {
  WebViewController? _webViewController;
  CyberWebViewController? _internalController;

  bool _isLoading = true;
  bool _isDisposed = false;

  // Track để tránh reload không cần thiết (ở widget level)
  String? _lastLoadedUrl;
  String? _lastLoadedHtml;

  CyberWebViewController get _effectiveController =>
      widget.controller ?? _internalController!;

  @override
  void initState() {
    super.initState();

    // Tạo internal controller nếu cần
    if (widget.controller == null) {
      _internalController = CyberWebViewController();

      // Set initial value từ widget params
      if (widget.url != null) {
        _internalController!.setUrlInternal(widget.url);
      } else if (widget.html != null) {
        _internalController!.setHtmlInternal(widget.html);
      }
    }

    WidgetsBinding.instance.addObserver(this);
    _initializeWebView();
    _effectiveController.addListener(_onControllerChanged);
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
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
      ..enableZoom(widget.enableZoom);

    _loadFromController();
  }

  void _onControllerChanged() {
    if (!mounted || _isDisposed) return;

    // Chỉ reload nếu thực sự cần (check ở widget level)
    final url = _effectiveController.url;
    final html = _effectiveController.html;

    bool needsReload = false;
    if (url != null && _lastLoadedUrl != url) {
      needsReload = true;
    } else if (html != null && _lastLoadedHtml != html) {
      needsReload = true;
    } else if (url == null &&
        html == null &&
        (_lastLoadedUrl != null || _lastLoadedHtml != null)) {
      needsReload = true;
    }

    if (needsReload) {
      _loadFromController();
    }

    // Update enabled state
    if (mounted) {
      setState(() {}); // Rebuild để apply enabled state
    }
  }

  void _loadFromController() {
    final url = _effectiveController.url;
    final html = _effectiveController.html;

    // Guard: tránh reload nếu đã load rồi
    if (url != null) {
      if (_lastLoadedUrl == url) return;
      _loadUrl(url);
      _lastLoadedUrl = url;
      _lastLoadedHtml = null;
    } else if (html != null) {
      if (_lastLoadedHtml == html) return;
      _loadHtml(html);
      _lastLoadedHtml = html;
      _lastLoadedUrl = null;
    } else {
      // Clear
      if (_lastLoadedUrl == null && _lastLoadedHtml == null) return;
      _loadUrl('about:blank');
      _lastLoadedUrl = null;
      _lastLoadedHtml = null;
    }
  }

  @override
  void didUpdateWidget(CyberWebView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Nếu controller thay đổi
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerChanged);

      if (widget.controller == null && _internalController == null) {
        _internalController = CyberWebViewController();
        if (widget.url != null) {
          _internalController!.setUrlInternal(widget.url);
        } else if (widget.html != null) {
          _internalController!.setHtmlInternal(widget.html);
        }
      }

      _effectiveController.addListener(_onControllerChanged);
      _loadFromController();
    }

    // Nếu dùng internal controller, update từ widget params
    if (widget.controller == null) {
      bool needsReload = false;

      if (oldWidget.url != widget.url && widget.url != null) {
        _internalController!.setUrlInternal(widget.url);
        needsReload = true;
      }

      if (oldWidget.html != widget.html && widget.html != null) {
        _internalController!.setHtmlInternal(widget.html);
        needsReload = true;
      }

      if (needsReload) {
        _loadFromController();
      }
    }

    // Cập nhật JavaScript mode nếu thay đổi
    if (oldWidget.enableJavaScript != widget.enableJavaScript) {
      _webViewController?.setJavaScriptMode(
        widget.enableJavaScript
            ? JavaScriptMode.unrestricted
            : JavaScriptMode.disabled,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_webViewController != null && !_isDisposed) {
      switch (state) {
        case AppLifecycleState.paused:
        case AppLifecycleState.inactive:
        case AppLifecycleState.detached:
        case AppLifecycleState.hidden:
          break;
        case AppLifecycleState.resumed:
          break;
      }
    }
  }

  void _loadUrl(String url) {
    if (_isDisposed || _webViewController == null) return;
    if (url.isEmpty) return;

    String finalUrl = url;
    if (url != 'about:blank' &&
        !url.startsWith('http://') &&
        !url.startsWith('https://')) {
      finalUrl = 'https://$url';
    }

    _webViewController!.loadRequest(Uri.parse(finalUrl));
  }

  void _loadHtml(String html) {
    if (_isDisposed || _webViewController == null) return;
    if (html.isEmpty) return;

    _webViewController!.loadHtmlString(html);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _effectiveController.removeListener(_onControllerChanged);
    WidgetsBinding.instance.removeObserver(this);

    _cleanupWebView();
    _internalController?.dispose();

    super.dispose();
  }

  Future<void> _cleanupWebView() async {
    if (_webViewController != null) {
      try {
        await _webViewController!.loadRequest(Uri.parse('about:blank'));

        if (widget.clearCacheOnDispose) {
          await _webViewController!.clearCache();
          await _webViewController!.clearLocalStorage();
        }

        await Future.delayed(const Duration(milliseconds: 50));
      } catch (e) {
        debugPrint('Error cleaning up WebView: $e');
      }

      _webViewController = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = _effectiveController.url;
    final html = _effectiveController.html;
    final enabled = _effectiveController.enabled;

    if (url == null && html == null) {
      return const Center(child: Text('No content to display'));
    }

    if (_webViewController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    Widget webView = Stack(
      children: [
        AbsorbPointer(
          absorbing: !enabled,
          child: Opacity(
            opacity: enabled ? 1.0 : 0.5,
            child: WebViewWidget(controller: _webViewController!),
          ),
        ),
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
    if (_webViewController != null && !_isDisposed) {
      await _webViewController!.reload();
    }
  }

  Future<void> goBack() async {
    if (_webViewController != null && !_isDisposed) {
      await _webViewController!.goBack();
    }
  }

  Future<void> goForward() async {
    if (_webViewController != null && !_isDisposed) {
      await _webViewController!.goForward();
    }
  }

  Future<bool> canGoBack() async {
    if (_webViewController != null && !_isDisposed) {
      return await _webViewController!.canGoBack();
    }
    return false;
  }

  Future<bool> canGoForward() async {
    if (_webViewController != null && !_isDisposed) {
      return await _webViewController!.canGoForward();
    }
    return false;
  }

  @Deprecated('Use controller.loadUrl() instead')
  void loadUrl(String url) {
    _effectiveController.loadUrl(url);
  }

  Future<void> clearCache() async {
    if (_webViewController != null && !_isDisposed) {
      await _webViewController!.clearCache();
      await _webViewController!.clearLocalStorage();
    }
  }

  Future<void> stopLoading() async {
    if (_webViewController != null && !_isDisposed) {
      await _webViewController!.loadRequest(Uri.parse('about:blank'));
    }
  }
}
