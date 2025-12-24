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

  const CyberWebView({
    super.key,
    this.url,
    this.width,
    this.height,
    this.enableJavaScript = true,
    this.enableZoom = true,
    this.margin,
    this.padding,
  });

  @override
  State<CyberWebView> createState() => CyberWebViewState();
}

class CyberWebViewState extends State<CyberWebView> {
  late WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(
        widget.enableJavaScript
            ? JavaScriptMode.unrestricted
            : JavaScriptMode.disabled,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
        ),
      );

    _loadUrl(widget.url);
  }

  @override
  void didUpdateWidget(CyberWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _loadUrl(widget.url);
    }
  }

  void _loadUrl(String? url) {
    if (url == null || url.isEmpty) return;

    String finalUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      finalUrl = 'https://$url';
    }

    _controller.loadRequest(Uri.parse(finalUrl));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.url == null || widget.url!.isEmpty) {
      return const Center(child: Text('No URL provided'));
    }

    Widget webView = Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_isLoading) const Center(child: CircularProgressIndicator()),
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
  Future<void> reload() => _controller.reload();
  Future<void> goBack() => _controller.goBack();
  Future<void> goForward() => _controller.goForward();
  Future<bool> canGoBack() => _controller.canGoBack();
  Future<bool> canGoForward() => _controller.canGoForward();

  void loadUrl(String url) {
    _loadUrl(url);
  }
}
