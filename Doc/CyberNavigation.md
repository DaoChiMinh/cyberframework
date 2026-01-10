# CyberNavigation - Navigation & Routing System

## Mục Lục
1. [Giới Thiệu](#giới-thiệu)
2. [Core Functions](#core-functions)
3. [Page Types](#page-types)
4. [Popup System](#popup-system)
5. [Ví Dụ Sử Dụng](#ví-dụ-sử-dụng)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

---

## Giới Thiệu

CyberNavigation cung cấp **universal routing system** với support cho nhiều loại navigation: screens, popups, dialogs, bottom sheets, file viewers, và communication apps.

### Đặc Điểm Chính

- ✅ **Universal Routing**: Single function cho mọi navigation
- ✅ **20+ Page Types**: Screen, popup, PDF, image, document viewers
- ✅ **Popup Variants**: Center, bottom, full screen
- ✅ **File Viewers**: PDF, Word, Excel, image, text
- ✅ **Communication**: Phone, SMS, WhatsApp, Telegram, Zalo
- ✅ **File Actions**: Share, download, print
- ✅ **Hero Animations**: Optional smooth transitions
- ✅ **Type-Safe Returns**: Generic return types for popups

### Import

```dart
import 'package:cyberframework/cyberframework.dart';
```

---

## Core Functions

### V_Root()

Create MaterialApp root với initial screen.

```dart
MaterialApp V_Root(
  String strfrm, {
  String title = "",
  String cp_name = "",
  String strparameter = "",
  bool ShowTitleBar = true,
})
```

**Usage:**
```dart
void main() {
  runApp(
    V_Root(
      'LoginScreen',
      title: 'My App',
      ShowTitleBar: true,
    ),
  );
}
```

### V_MainScreen()

Navigate to main screen và clear navigation stack.

```dart
void V_MainScreen(
  BuildContext context,
  String strfrm, {
  String title = "",
  String cp_name = "",
  String strparameter = "",
  bool showAppBar = false,
})
```

**Usage:**
```dart
// After login, navigate to home
V_MainScreen(
  context,
  'HomeScreen',
  title: 'Home',
  showAppBar: false,
);
```

### V_callform()

**Universal navigation function** - Single entry point cho tất cả navigation types.

```dart
Future<bool> V_callform(
  BuildContext context,
  String strfrm,
  String title,
  String cpName,
  String strparameter,
  String pagetype, {
  bool useHeroAnimation = false,
  bool clearAllStack = false,
})
```

### V_callView()

Embed ContentView trong form (không navigate).

```dart
Widget? V_callView(
  String viewName, {
  String cpName = "",
  String strParameter = "",
  dynamic objectData,
})
```

### V_callViewPopup()

Show popup với customization options.

```dart
Future<T?> V_callViewPopup<T>(
  BuildContext context,
  String viewName, {
  String cpName = "",
  String strParameter = "",
  dynamic objectData,
  PopupPosition position = PopupPosition.center,
  PopupAnimation animation = PopupAnimation.scale,
  bool barrierDismissible = true,
  Color? barrierColor,
  EdgeInsets? margin,
  EdgeInsets? padding,
  double? width,
  double? height,
  BorderRadius? borderRadius,
  Color? backgroundColor,
})
```

### V_callViewBottom()

Show bottom sheet.

```dart
Future<T?> V_callViewBottom<T>(
  BuildContext context,
  String viewName, {
  // ... same parameters as popup
})
```

### V_callViewDialog()

Show center dialog.

```dart
Future<T?> V_callViewDialog<T>(
  BuildContext context,
  String viewName, {
  // ... same parameters as popup
})
```

---

## Page Types

### Screen Navigation

Navigate to form screens.

| Page Type | Description | Example |
|-----------|-------------|---------|
| (default) | Standard screen navigation | `V_callform(context, "DetailForm", "", "", "", "")` |
| `clearAllStack: true` | Clear all and navigate | `V_callform(..., clearAllStack: true)` |

### Popups & Dialogs

| Page Type | Description | Example |
|-----------|-------------|---------|
| `p`, `popup` | Center popup | `V_callform(context, "FilterView", "", "", "", "p")` |
| `pb`, `popup_botton` | Bottom sheet | `V_callform(context, "OptionsView", "", "", "", "pb")` |
| `pd`, `popupdialog` | Dialog | `V_callform(context, "ConfirmView", "", "", "", "pd")` |

### Messages & Alerts

| Page Type | Description | Example |
|-----------|-------------|---------|
| `a` | Alert message | `V_callform(context, "Success!", "Title", "", "", "a")` |
| `ae` | Error message | `V_callform(context, "Error!", "Title", "", "", "ae")` |
| `aw` | Warning message | `V_callform(context, "Warning!", "Title", "", "", "aw")` |
| `aq` | Confirm message + API call | `V_callform(context, "Delete?", "", "CP_Delete", "id=123", "aq")` |

### API Execution

| Page Type | Description | Example |
|-----------|-------------|---------|
| `exe` | Execute API without UI | `V_callform(context, "", "", "CP_SaveData", "xml", "exe")` |

### File Viewers

| Page Type | Description | Example |
|-----------|-------------|---------|
| `pdf`, `pdfview` | PDF viewer | `V_callform(context, "https://example.com/doc.pdf", "PDF", "", "", "pdf")` |
| `img`, `image` | Image viewer | `V_callform(context, "base64_or_url", "Image", "", "", "img")` |
| `txt`, `text` | Text viewer | `V_callform(context, "content", "Text", "", "", "txt")` |
| `doc`, `docx`, `word` | Word document viewer | `V_callform(context, "doc_path", "Document", "", "", "doc")` |
| `xls`, `xlsx`, `excel` | Excel viewer | `V_callform(context, "excel_path", "Excel", "", "", "xls")` |
| `w`, `wb`, `web` | Web browser | `V_callform(context, "https://example.com", "Web", "", "", "w")` |

### File Actions

| Page Type | Description | Example |
|-----------|-------------|---------|
| `share` | Share file | `V_callform(context, "file_path", "File.pdf", "pdf", "", "share")` |
| `download` | Download file | `V_callform(context, "url", "", "pdf", "custom_name", "download")` |
| `print` | Print file | `V_callform(context, "content", "Document", "pdf", "", "print")` |

### Communication

| Page Type | Description | Example |
|-----------|-------------|---------|
| `call`, `callconfirm` | Phone call with confirm | `V_callform(context, "0123456789", "", "", "", "call")` |
| `sms`, `message` | Send SMS | `V_callform(context, "0123456789", "", "", "Hello", "sms")` |
| `whatsapp`, `wa` | WhatsApp chat | `V_callform(context, "0123456789", "", "", "Hello", "whatsapp")` |
| `telegram`, `tg` | Telegram chat | `V_callform(context, "username", "", "", "", "telegram")` |
| `viber` | Viber chat | `V_callform(context, "0123456789", "", "", "", "viber")` |
| `zalo`, `zalochat` | Zalo chat | `V_callform(context, "0123456789", "", "", "", "zalo")` |
| `zalocall` | Zalo call | `V_callform(context, "0123456789", "", "", "", "zalocall")` |
| `zalomsg` | Zalo message | `V_callform(context, "0123456789", "", "", "Hello", "zalomsg")` |
| `zalooa` | Zalo Official Account | `V_callform(context, "oa_id", "", "", "", "zalooa")` |
| `contacts`, `phonebook` | Open contacts app | `V_callform(context, "", "", "", "", "contacts")` |
| `savecontact` | Save to contacts | `V_callform(context, "0123456789", "John Doe", "", "email@ex.com", "savecontact")` |

---

## Popup System

### Popup Positions

```dart
enum PopupPosition {
  top,
  center,
  bottom,
  fullScreen,
}
```

### Popup Animations

```dart
enum PopupAnimation {
  slide,
  fade,
  scale,
  slideAndFade,
  none,
}
```

### Type-Safe Returns

```dart
// Return specific type from popup
final result = await V_callViewPopup<bool>(
  context,
  'ConfirmView',
);

if (result == true) {
  print('Confirmed');
}

// Return custom object
final user = await V_callViewPopup<User>(
  context,
  'UserSelectView',
);

print(user?.name);
```

---

## Ví Dụ Sử Dụng

### 1. Basic Screen Navigation

```dart
// Navigate to detail screen
V_callform(
  context,
  'ProductDetailForm',
  'Product Detail',
  'CP_GetProduct',
  'id=123',
  '',  // Default page type = screen
);
```

### 2. Navigate with Animation

```dart
V_callform(
  context,
  'ProfileForm',
  'Profile',
  '',
  '',
  '',
  useHeroAnimation: true,
);
```

### 3. Clear Stack Navigation

```dart
// After login, clear stack and go home
V_callform(
  context,
  'HomeScreen',
  'Home',
  '',
  '',
  '',
  clearAllStack: true,
);

// Or use V_MainScreen
V_MainScreen(context, 'HomeScreen', title: 'Home');
```

### 4. Show Alert Messages

```dart
// Success message
V_callform(
  context,
  'Đã lưu thành công!',
  'Thành công',
  '',
  '',
  'a',  // Alert
);

// Error message
V_callform(
  context,
  'Không thể lưu dữ liệu',
  'Lỗi',
  '',
  '',
  'ae',  // Alert error
);

// Warning message
V_callform(
  context,
  'Dữ liệu có thể bị mất',
  'Cảnh báo',
  '',
  '',
  'aw',  // Alert warning
);
```

### 5. Confirm with API Call

```dart
// Show confirm, if yes → call API
V_callform(
  context,
  'Bạn có chắc muốn xóa?',
  'Xác nhận',
  'CP_DeleteItem',
  'id=123',
  'aq',  // Ask & execute
);
```

### 6. Execute API

```dart
// Call API without showing screen
bool success = await V_callform(
  context,
  '',
  '',
  'CP_SaveData',
  xmlData,
  'exe',  // Execute
);

if (success) {
  print('API call successful');
}
```

### 7. Show PDF

```dart
// From URL
V_callform(
  context,
  'https://example.com/document.pdf',
  'Contract Document',
  '',
  '',
  'pdf',
);

// From local file
V_callform(
  context,
  '/path/to/local/file.pdf',
  'Local Document',
  '',
  '',
  'pdf',
);
```

### 8. Show Image

```dart
// From URL
V_callform(
  context,
  'https://example.com/image.jpg',
  'Product Photo',
  '',
  '',
  'img',
);

// From base64
V_callform(
  context,
  'data:image/png;base64,iVBORw0KG...',
  'Image',
  '',
  '',
  'img',
);
```

### 9. Open WebView

```dart
V_callform(
  context,
  'https://www.google.com',
  'Google',
  '',
  '',
  'web',
);
```

### 10. Share File

```dart
V_callform(
  context,
  '/path/to/file.pdf',  // File path or base64
  'Document.pdf',        // File name
  'pdf',                 // File extension
  '',
  'share',
);
```

### 11. Download File

```dart
V_callform(
  context,
  'https://example.com/report.pdf',
  '',
  'pdf',
  'monthly_report',  // Custom file name
  'download',
);
```

### 12. Print File

```dart
// Print PDF
V_callform(
  context,
  pdfContent,
  'Invoice',
  'pdf',
  '',
  'print',
);

// Print text
V_callform(
  context,
  textContent,
  'Receipt',
  'text',
  '',
  'print',
);
```

### 13. Phone Call

```dart
V_callform(
  context,
  '0123456789',
  '',
  '',
  '',
  'call',  // Shows confirmation dialog
);
```

### 14. Send SMS

```dart
V_callform(
  context,
  '0123456789',        // Phone number
  '',
  '',
  'Hello, this is a test message',  // Message content
  'sms',
);
```

### 15. WhatsApp Message

```dart
V_callform(
  context,
  '0123456789',
  '',
  '',
  'Hello from my app!',
  'whatsapp',
);
```

### 16. Zalo Communication

```dart
// Zalo chat
V_callform(context, '0123456789', '', '', '', 'zalo');

// Zalo call
V_callform(context, '0123456789', '', '', '', 'zalocall');

// Zalo message
V_callform(context, '0123456789', '', '', 'Hello', 'zalomsg');

// Zalo OA
V_callform(context, 'oa_id_here', '', '', '', 'zalooa');
```

### 17. Save to Contacts

```dart
V_callform(
  context,
  '0123456789',      // Phone number
  'John Doe',        // Name
  '',
  'john@example.com',  // Email
  'savecontact',
);
```

### 18. Popup Dialog

```dart
// Center popup
final result = await V_callform(
  context,
  'FilterView',
  'Filter Options',
  '',
  '',
  'p',
);

// Bottom sheet
final selected = await V_callform(
  context,
  'OptionsView',
  'Select Option',
  '',
  '',
  'pb',
);

// Custom dialog
final confirmed = await V_callform(
  context,
  'ConfirmView',
  'Confirm Action',
  '',
  '',
  'pd',
);
```

### 19. Embed View in Form

```dart
class MyForm extends CyberForm {
  @override
  Widget buildBody(BuildContext context) {
    return Column(
      children: [
        // Embed ContentView
        V_callView(
          'CustomerInfoView',
          cpName: 'CP_GetCustomer',
          strParameter: 'id=123',
        ) ?? Text('View not found'),
        
        CyberButton(
          label: 'Save',
          onClick: save,
        ),
      ],
    );
  }
}
```

### 20. Advanced Popup with Custom Options

```dart
final result = await V_callViewPopup<Map<String, dynamic>>(
  context,
  'AdvancedFilterView',
  position: PopupPosition.bottom,
  animation: PopupAnimation.slideAndFade,
  barrierDismissible: true,
  barrierColor: Colors.black54,
  margin: EdgeInsets.all(16),
  padding: EdgeInsets.all(24),
  width: 400,
  height: 600,
  borderRadius: BorderRadius.circular(20),
  backgroundColor: Colors.white,
);

if (result != null) {
  print('Filter applied: $result');
}
```

---

## Best Practices

### 1. Use Appropriate Page Types

```dart
// ✅ GOOD: Specific page type
V_callform(context, "message", "Title", "", "", "a");

// ❌ BAD: Wrong type
Navigator.push(...);  // Use V_callform instead
```

### 2. Clear Stack When Needed

```dart
// ✅ GOOD: After login
V_MainScreen(context, 'HomeScreen');

// Or
V_callform(context, 'HomeScreen', '', '', '', '', clearAllStack: true);

// ❌ BAD: Stack keeps growing
V_callform(context, 'HomeScreen', '', '', '', '');
```

### 3. Type-Safe Popup Returns

```dart
// ✅ GOOD: Specify return type
final bool? confirmed = await V_callViewPopup<bool>(...);

// ❌ BAD: No type
final confirmed = await V_callViewPopup(...);
```

### 4. Use V_callView for Embedding

```dart
// ✅ GOOD: Embed in form
Widget buildBody(BuildContext context) {
  return V_callView('MyView') ?? Container();
}

// ❌ BAD: Navigate instead of embed
Widget buildBody(BuildContext context) {
  V_callform(context, 'MyView', '', '', '', '');
}
```

### 5. File Viewer URLs

```dart
// ✅ GOOD: Full URL for web files
V_callform(context, 'https://example.com/file.pdf', '', '', '', 'pdf');

// ✅ GOOD: Local path for device files
V_callform(context, '/storage/emulated/0/file.pdf', '', '', '', 'pdf');

// ❌ BAD: Relative path
V_callform(context, 'file.pdf', '', '', '', 'pdf');
```

---

## Troubleshooting

### Screen not found

**Nguyên nhân:** View name không tồn tại

**Giải pháp:**
```dart
// ✅ CORRECT: Check view exists
final screen = V_getScreen('MyScreen', '', '', '');
if (screen != null) {
  V_callform(context, 'MyScreen', '', '', '', '');
}

// Register view in registry first
```

### Popup doesn't close

**Nguyên nhân:** Không dùng Navigator.pop

**Giải pháp:**
```dart
// ✅ CORRECT: In popup view
CyberButton(
  label: 'Close',
  onClick: () {
    Navigator.pop(context, true);  // Return result
  },
)
```

### File viewer shows error

**Nguyên nhân:** File path không đúng

**Giải pháp:**
```dart
// ✅ CORRECT: Check file exists
if (await File(path).exists()) {
  V_callform(context, path, '', '', '', 'pdf');
}

// Or use full URL
V_callform(context, 'https://...', '', '', '', 'pdf');
```

### Phone call doesn't work

**Nguyên nhân:** Missing permissions

**Giải pháp:**
```dart
// Add to AndroidManifest.xml:
<uses-permission android:name="android.permission.CALL_PHONE" />

// Add to Info.plist (iOS):
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>tel</string>
</array>
```

### Share doesn't work

**Nguyên nhân:** Invalid file path

**Giải pháp:**
```dart
// ✅ CORRECT: Absolute path or base64
V_callform(context, '/full/path/to/file.pdf', 'File', 'pdf', '', 'share');

// Or base64
V_callform(context, 'base64_content', 'File', 'pdf', '', 'share');
```

---

## Tips & Tricks

### 1. Navigation Shortcuts

```dart
// Quick navigation
V_callform(context, 'Screen', 'Title', '', '', '');

// Equals to
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => V_getScreen('Screen', 'Title', '', ''),
  ),
);
```

### 2. Conditional Navigation

```dart
final canProceed = await checkPermission();

if (canProceed) {
  V_callform(context, 'NextScreen', '', '', '', '');
} else {
  V_callform(context, 'No permission', '', '', '', 'ae');
}
```

### 3. Sequential Popups

```dart
// Show confirmation
final confirmed = await V_callViewDialog<bool>(context, 'ConfirmView');

if (confirmed == true) {
  // Show success
  V_callform(context, 'Success!', '', '', '', 'a');
}
```

### 4. Multiple Return Values

```dart
// Return complex object
final filter = await V_callViewPopup<FilterOptions>(
  context,
  'FilterView',
);

if (filter != null) {
  applyFilter(
    filter.category,
    filter.priceRange,
    filter.sortBy,
  );
}
```

### 5. Page Type Aliases

```dart
// Same result, different aliases
'p' == 'popup'
'pb' == 'popup_botton' == 'popupbotton'
'pd' == 'popupdialog'
'w' == 'wb' == 'web'
'img' == 'image'
'doc' == 'docx' == 'word'
```

---

## Common Patterns

### Login Flow

```dart
// 1. Login
final success = await UserInfo.V_Login(context, ...);

if (success) {
  // 2. Clear stack and go home
  V_MainScreen(context, 'HomeScreen');
}
```

### Master-Detail Pattern

```dart
// Master screen
CyberButton(
  label: 'View Details',
  onClick: () {
    V_callform(
      context,
      'DetailForm',
      'Detail',
      'CP_GetDetail',
      'id=${row["id"]}',
      '',
    );
  },
)
```

### Filter Pattern

```dart
// Show filter popup
final filter = await V_callViewBottom<Map<String, dynamic>>(
  context,
  'FilterView',
);

if (filter != null) {
  // Apply filter and refresh
  applyFilter(filter);
  refresh();
}
```

### Confirm Delete Pattern

```dart
CyberButton(
  label: 'Delete',
  onClick: () async {
    final success = await V_callform(
      context,
      'Bạn có chắc muốn xóa?',
      'Xác nhận',
      'CP_Delete',
      'id=${id}',
      'aq',  // Ask & execute
    );
    
    if (success) {
      refresh();
    }
  },
)
```

---

## Performance Tips

1. **Use clearAllStack**: Prevent memory leaks
2. **Hero Animations**: Use sparingly (performance cost)
3. **Embed Views**: Use V_callView instead of navigation
4. **Cache Views**: Register in view registry
5. **Lazy Load**: Don't preload all screens

---

## Version History

### 1.0.0
- V_Root for app initialization
- V_MainScreen for main navigation
- V_callform universal routing
- V_callView for embedding
- V_callViewPopup system
- 20+ page types
- File viewers (PDF, Word, Excel, Image, Text)
- Communication integrations
- File actions (share, download, print)
- Hero animations
- Type-safe returns

---

## License

MIT License - CyberFramework
