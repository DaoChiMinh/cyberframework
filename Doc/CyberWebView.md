# CyberWebView - WebView Widget với Controller

## Mục Lục
1. [Giới Thiệu](#giới-thiệu)
2. [CyberWebView Widget](#cyberwebview-widget)
3. [CyberWebViewController](#cyberwebviewcontroller)
4. [Ví Dụ Sử Dụng](#ví-dụ-sử-dụng)
5. [Features](#features)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

---

## Giới Thiệu

`CyberWebView` là WebView widget với **Internal Controller**, cho phép hiển thị web content (URL hoặc HTML) trong Flutter app. Widget này wrap `webview_flutter` package với API đơn giản hơn.

### Đặc Điểm Chính

- ✅ **Internal Controller**: Tự động quản lý state
- ✅ **Dual Mode**: Load URL hoặc HTML string
- ✅ **JavaScript Support**: Enable/disable JavaScript
- ✅ **Zoom Control**: Enable/disable zoom
- ✅ **Auto Cleanup**: Clear cache on dispose
- ✅ **Navigation**: Back, forward, reload
- ✅ **Loading State**: Built-in loading indicator
- ✅ **Lifecycle**: App lifecycle awareness

### Import

```dart
import 'package:cyberframework/cyberframework.dart';
```

### Dependencies

Add to `pubspec.yaml`:
```yaml
dependencies:
  webview_flutter: ^4.0.0
```

---

## CyberWebView Widget

### Constructor

```dart
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
})
```

### Properties

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `controller` | `CyberWebViewController?` | External controller (optional) | null |
| `url` | `String?` | URL to load | null |
| `html` | `String?` | HTML string to load | null |
| `width` | `double?` | Chiều rộng | null (full width) |
| `height` | `double?` | Chiều cao | null (expand) |
| `enableJavaScript` | `bool` | Enable JavaScript | true |
| `enableZoom` | `bool` | Enable zoom gestures | true |
| `margin` | `EdgeInsets?` | Outer margin | null |
| `padding` | `EdgeInsets?` | Inner padding | null |
| `clearCacheOnDispose` | `bool` | Clear cache khi dispose | true |

⚠️ **KHÔNG dùng controller cùng với url/html trực tiếp**

---

## CyberWebViewController

### Properties & Methods

```dart
final controller = CyberWebViewController();

// Properties
String? url = controller.url;
String? html = controller.html;
bool enabled = controller.enabled;

// Load URL
controller.loadUrl('https://flutter.dev');

// Load HTML
controller.loadHtml('<h1>Hello World</h1>');

// Clear
controller.clear();

// Enable/Disable
controller.setEnabled(true);
```

---

## Ví Dụ Sử Dụng

### 1. Load URL (Simple)

Load website từ URL.

```dart
class WebBrowser extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CyberWebView(
      url: 'https://flutter.dev',
      height: 600,
    );
  }
}
```

### 2. Load HTML String

Load HTML content trực tiếp.

```dart
class HtmlViewer extends StatelessWidget {
  final String htmlContent = '''
    <!DOCTYPE html>
    <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body {
            font-family: Arial, sans-serif;
            padding: 20px;
          }
          h1 { color: #007AFF; }
        </style>
      </head>
      <body>
        <h1>Hello from HTML</h1>
        <p>This is rendered HTML content.</p>
      </body>
    </html>
  ''';

  @override
  Widget build(BuildContext context) {
    return CyberWebView(
      html: htmlContent,
      height: 400,
    );
  }
}
```

### 3. With Controller (Dynamic Loading)

Thay đổi content động.

```dart
class DynamicWebView extends StatefulWidget {
  @override
  State<DynamicWebView> createState() => _DynamicWebViewState();
}

class _DynamicWebViewState extends State<DynamicWebView> {
  final controller = CyberWebViewController();

  void loadFlutter() {
    controller.loadUrl('https://flutter.dev');
  }

  void loadDart() {
    controller.loadUrl('https://dart.dev');
  }

  void loadHTML() {
    controller.loadHtml('<h1>Local HTML Content</h1>');
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: loadFlutter,
              child: Text('Flutter'),
            ),
            ElevatedButton(
              onPressed: loadDart,
              child: Text('Dart'),
            ),
            ElevatedButton(
              onPressed: loadHTML,
              child: Text('HTML'),
            ),
          ],
        ),
        
        SizedBox(height: 16),
        
        Expanded(
          child: CyberWebView(
            controller: controller,
            height: 600,
          ),
        ),
      ],
    );
  }
}
```

### 4. Article Viewer

Hiển thị bài viết từ HTML.

```dart
class ArticleViewer extends StatelessWidget {
  final String articleHtml;

  ArticleViewer({required this.articleHtml});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bài viết')),
      body: CyberWebView(
        html: _wrapHTML(articleHtml),
        padding: EdgeInsets.all(16),
      ),
    );
  }

  String _wrapHTML(String content) {
    return '''
      <!DOCTYPE html>
      <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <style>
            body {
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
              line-height: 1.6;
              padding: 0;
              margin: 0;
            }
            img { max-width: 100%; height: auto; }
            code {
              background: #f5f5f5;
              padding: 2px 6px;
              border-radius: 3px;
            }
          </style>
        </head>
        <body>
          $content
        </body>
      </html>
    ''';
  }
}
```

### 5. Documentation Viewer

WebView với navigation controls.

```dart
class DocumentationViewer extends StatefulWidget {
  @override
  State<DocumentationViewer> createState() => _DocumentationViewerState();
}

class _DocumentationViewerState extends State<DocumentationViewer> {
  final GlobalKey<CyberWebViewState> _webViewKey = GlobalKey();
  bool _canGoBack = false;
  bool _canGoForward = false;

  Future<void> _updateNavigationState() async {
    final canBack = await _webViewKey.currentState?.canGoBack() ?? false;
    final canForward = await _webViewKey.currentState?.canGoForward() ?? false;
    
    setState(() {
      _canGoBack = canBack;
      _canGoForward = canForward;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Documentation'),
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: _canGoBack
                ? () async {
                    await _webViewKey.currentState?.goBack();
                    _updateNavigationState();
                  }
                : null,
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward),
            onPressed: _canGoForward
                ? () async {
                    await _webViewKey.currentState?.goForward();
                    _updateNavigationState();
                  }
                : null,
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => _webViewKey.currentState?.reload(),
          ),
        ],
      ),
      body: CyberWebView(
        key: _webViewKey,
        url: 'https://docs.flutter.dev',
      ),
    );
  }
}
```

### 6. No JavaScript

Disable JavaScript for security.

```dart
CyberWebView(
  url: 'https://example.com',
  enableJavaScript: false,  // Disable JS
  height: 600,
)
```

### 7. Disable Zoom

Prevent user from zooming.

```dart
CyberWebView(
  url: 'https://example.com',
  enableZoom: false,  // Disable zoom
  height: 600,
)
```

### 8. Custom Size

Fixed size WebView.

```dart
CyberWebView(
  url: 'https://example.com',
  width: 400,
  height: 300,
  margin: EdgeInsets.all(16),
  padding: EdgeInsets.all(8),
)
```

### 9. Terms & Conditions

Show T&C in WebView.

```dart
class TermsAndConditions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Điều khoản sử dụng')),
      body: Column(
        children: [
          Expanded(
            child: CyberWebView(
              url: 'https://example.com/terms',
            ),
          ),
          
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Từ chối'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text('Đồng ý'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### 10. Preview Link

Show link preview in bottom sheet.

```dart
Future<void> showLinkPreview(BuildContext context, String url) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.9,
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    url,
                    style: TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          Divider(height: 1),
          
          // WebView
          Expanded(
            child: CyberWebView(url: url),
          ),
        ],
      ),
    ),
  );
}
```

---

## Features

### 1. Internal Controller

Widget tự động quản lý WebViewController:

```dart
// ✅ GOOD: Simple URL
CyberWebView(url: 'https://flutter.dev')
```

### 2. Dual Mode

Load URL hoặc HTML:

```dart
// URL mode
CyberWebView(url: 'https://example.com')

// HTML mode
CyberWebView(html: '<h1>Hello</h1>')
```

### 3. Loading Indicator

Built-in loading state:

```dart
// Auto shows CircularProgressIndicator
// when page is loading
```

### 4. Navigation

```dart
final key = GlobalKey<CyberWebViewState>();

// Go back
await key.currentState?.goBack();

// Go forward
await key.currentState?.goForward();

// Reload
await key.currentState?.reload();

// Check navigation
bool canBack = await key.currentState?.canGoBack();
bool canForward = await key.currentState?.canGoForward();
```

### 5. Auto Cleanup

```dart
clearCacheOnDispose: true,
// Auto clears cache when widget disposed
```

### 6. Enable/Disable

```dart
controller.setEnabled(false);
// Disables interaction + opacity 0.5
```

---

## Best Practices

### 1. Use URL for External Sites

```dart
// ✅ GOOD: External sites
CyberWebView(url: 'https://flutter.dev')

// ❌ BAD: Don't load HTML from URL
final html = await http.get(...);
CyberWebView(html: html)  // Just use url!
```

### 2. Use HTML for Local Content

```dart
// ✅ GOOD: Local HTML
CyberWebView(html: '<h1>Local</h1>')

// ❌ BAD: Don't create local server
CyberWebView(url: 'http://localhost:8080')
```

### 3. Set Proper Size

```dart
// ✅ GOOD: Fixed height in Column
Column(
  children: [
    CyberWebView(
      url: 'https://example.com',
      height: 400,  // Fixed height
    ),
  ],
)

// ❌ BAD: Unbounded height
Column(
  children: [
    CyberWebView(url: '...'),  // Error!
  ],
)
```

### 4. Security Considerations

```dart
// ✅ GOOD: Disable JS for untrusted content
CyberWebView(
  url: userProvidedUrl,
  enableJavaScript: false,
)

// ❌ BAD: Enable JS for all content
CyberWebView(
  url: userProvidedUrl,
  enableJavaScript: true,  // Security risk!
)
```

### 5. Clear Cache

```dart
// ✅ GOOD: Clear on dispose
CyberWebView(
  clearCacheOnDispose: true,
)

// ✅ GOOD: Manual clear
await webViewKey.currentState?.clearCache();
```

---

## Troubleshooting

### WebView không hiển thị

**Nguyên nhân:** Không set height

**Giải pháp:**
```dart
// ✅ CORRECT
CyberWebView(
  url: 'https://example.com',
  height: 400,
)

// Or use Expanded
Expanded(
  child: CyberWebView(url: '...'),
)
```

### URL không load

**Nguyên nhân:** Missing https://

**Giải pháp:**
```dart
// ✅ CORRECT
url: 'https://flutter.dev'

// ❌ WRONG
url: 'flutter.dev'  // Missing protocol
```

### JavaScript không chạy

**Nguyên nhân:** enableJavaScript = false

**Giải pháp:**
```dart
// ✅ CORRECT
CyberWebView(
  url: '...',
  enableJavaScript: true,
)
```

### Navigation không hoạt động

**Nguyên nhân:** No GlobalKey

**Giải pháp:**
```dart
// ✅ CORRECT
final key = GlobalKey<CyberWebViewState>();

CyberWebView(
  key: key,
  url: '...',
)

// Use key
await key.currentState?.goBack();
```

### Memory leak

**Nguyên nhân:** Không clear cache

**Giải pháp:**
```dart
// ✅ CORRECT
CyberWebView(
  clearCacheOnDispose: true,
)
```

---

## Tips & Tricks

### 1. Responsive HTML

```dart
String wrapResponsiveHTML(String content) {
  return '''
    <!DOCTYPE html>
    <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          body {
            margin: 0;
            padding: 16px;
            font-family: -apple-system, sans-serif;
          }
          img { max-width: 100%; height: auto; }
        </style>
      </head>
      <body>
        $content
      </body>
    </html>
  ''';
}
```

### 2. Dark Mode HTML

```dart
String darkModeHTML(String content) {
  return '''
    <!DOCTYPE html>
    <html>
      <head>
        <style>
          @media (prefers-color-scheme: dark) {
            body {
              background: #1e1e1e;
              color: #ffffff;
            }
          }
        </style>
      </head>
      <body>$content</body>
    </html>
  ''';
}
```

### 3. Stop Loading

```dart
await webViewKey.currentState?.stopLoading();
```

### 4. Listen to URL Changes

Use `webview_flutter` directly for advanced features:

```dart
WebViewController()
  ..setNavigationDelegate(
    NavigationDelegate(
      onNavigationRequest: (request) {
        print('Navigating to: ${request.url}');
        return NavigationDecision.navigate;
      },
    ),
  );
```

### 5. Error Handling

```dart
NavigationDelegate(
  onWebResourceError: (error) {
    print('Error: ${error.description}');
    showError('Không thể tải trang');
  },
)
```

---

## Performance Tips

1. **Set Fixed Height**: Avoid layout thrashing
2. **Clear Cache**: Clear on dispose
3. **Disable Unnecessary Features**: Disable JS if not needed
4. **Lazy Load**: Don't load until needed
5. **Limit Instances**: Avoid multiple WebViews

---

## Common Patterns

### Terms Viewer

```dart
CyberWebView(
  url: 'https://example.com/terms',
  enableJavaScript: false,
  enableZoom: false,
)
```

### Article Reader

```dart
CyberWebView(
  html: wrapHTML(articleContent),
  padding: EdgeInsets.all(16),
)
```

### External Link

```dart
CyberWebView(
  url: externalUrl,
  height: 600,
)
```

### Preview Modal

```dart
showModalBottomSheet(
  builder: (context) => CyberWebView(url: url),
)
```

---

## Platform Support

### Android

- ✅ Supported
- Requires Android SDK 19+
- Uses Android WebView

### iOS

- ✅ Supported  
- Requires iOS 11+
- Uses WKWebView

### Web

- ⚠️ Limited support
- Uses platform view

### Desktop

- ⚠️ Limited support
- May require additional setup

---

## Security Notes

### JavaScript

```dart
// Disable for untrusted content
enableJavaScript: false
```

### HTTPS Only

```dart
// Prefer HTTPS
url: 'https://example.com'  // ✅
url: 'http://example.com'   // ⚠️
```

### Clear Cache

```dart
// Clear sensitive data
clearCacheOnDispose: true
```

---

## Version History

### 1.0.0
- Initial release
- Internal controller
- URL loading
- HTML loading
- JavaScript control
- Zoom control
- Auto cleanup
- Navigation methods
- Loading state
- Lifecycle management

---

## Dependencies

```yaml
webview_flutter: ^4.0.0
```

---

## License

MIT License - CyberFramework
