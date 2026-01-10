# CyberPopup - Custom Popup/Modal System

## Mục Lục
1. [Giới Thiệu](#giới-thiệu)
2. [CyberPopup Class](#cyberpopup-class)
3. [Ví Dụ Sử Dụng](#ví-dụ-sử-dụng)
4. [Features](#features)
5. [Best Practices](#best-practices)
6. [Troubleshooting](#troubleshooting)

---

## Giới Thiệu

`CyberPopup` là hệ thống popup/modal tùy biến với nhiều **positions**, **animations**, và **layouts**. Widget này cung cấp API thống nhất cho dialog, bottom sheet, và full screen modal.

### Đặc Điểm Chính

- ✅ **4 Positions**: Top, Center, Bottom, Full Screen
- ✅ **5 Animations**: Slide, Fade, Scale, SlideAndFade, None
- ✅ **Return Values**: Async/await với generic types
- ✅ **Customizable**: Size, colors, borders, shadows
- ✅ **Callbacks**: onShow, onClose
- ✅ **Barrier Control**: Dismissible, color customization
- ✅ **Helper Methods**: Static close() method

### Import

```dart
import 'package:cyberframework/cyberframework.dart';
```

---

## CyberPopup Class

### Enums

#### PopupPosition

```dart
enum PopupPosition {
  top,          // Top of screen
  center,       // Center (dialog)
  bottom,       // Bottom sheet
  fullScreen,   // Full screen modal
}
```

#### PopupAnimation

```dart
enum PopupAnimation {
  slide,         // Slide in
  fade,          // Fade in
  scale,         // Scale up
  slideAndFade,  // Slide + Fade
  none,          // No animation
}
```

### Constructor

```dart
CyberPopup({
  required this.context,
  required this.child,
  this.position = PopupPosition.center,
  this.animation = PopupAnimation.slideAndFade,
  this.barrierDismissible = true,
  this.barrierColor,
  this.margin,
  this.padding,
  this.width,
  this.height,
  this.borderRadius,
  this.backgroundColor,
  this.boxShadow,
  this.onClose,
  this.onShow,
  this.transitionDuration = const Duration(milliseconds: 100),
  this.isScrollControlled = true,
})
```

### Properties

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `context` | `BuildContext` | Build context | Required |
| `child` | `Widget` | Content widget | Required |
| `position` | `PopupPosition` | Vị trí hiển thị | center |
| `animation` | `PopupAnimation` | Kiểu animation | slideAndFade |
| `barrierDismissible` | `bool` | Cho phép dismiss khi tap ngoài | true |
| `barrierColor` | `Color?` | Màu barrier | Colors.black54 |
| `margin` | `EdgeInsets?` | Margin bên ngoài | EdgeInsets.symmetric(horizontal: 20) |
| `padding` | `EdgeInsets?` | Padding bên trong | null (auto) |
| `width` | `double?` | Chiều rộng | null (auto) |
| `height` | `double?` | Chiều cao | null (auto) |
| `borderRadius` | `BorderRadius?` | Bo góc | BorderRadius.circular(12) |
| `backgroundColor` | `Color?` | Màu nền | Colors.white |
| `boxShadow` | `BoxShadow?` | Đổ bóng | Auto |
| `onClose` | `Function(dynamic)?` | Callback khi đóng | null |
| `onShow` | `Function()?` | Callback khi mở | null |
| `transitionDuration` | `Duration` | Thời gian animation | 100ms |
| `isScrollControlled` | `bool` | Scroll behavior | true |

### Methods

#### show<T>()

```dart
Future<T?> show<T>()
```

Hiển thị popup và trả về kết quả.

#### showBotton<T>()

```dart
Future<T?> showBotton<T>()
```

Force hiển thị như bottom sheet.

#### showFullScreen<T>()

```dart
Future<T?> showFullScreen<T>()
```

Force hiển thị full screen.

#### close() (Static)

```dart
static void close<T>(BuildContext context, [T? result])
```

Helper method để đóng popup từ bên trong.

---

## Ví Dụ Sử Dụng

### 1. Simple Center Dialog

Basic confirmation dialog.

```dart
class ConfirmDialog extends StatelessWidget {
  Future<void> showConfirmation(BuildContext context) async {
    final popup = CyberPopup(
      context: context,
      child: _buildConfirmContent(),
      position: PopupPosition.center,
      width: 300,
    );

    final confirmed = await popup.show<bool>();
    
    if (confirmed == true) {
      print('User confirmed');
    }
  }

  Widget _buildConfirmContent() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Xác nhận',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Text('Bạn có chắc muốn thực hiện?'),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => CyberPopup.close(context, false),
                child: Text('Hủy'),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => CyberPopup.close(context, true),
                child: Text('Xác nhận'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

### 2. Bottom Sheet

Sliding bottom sheet.

```dart
class FilterBottomSheet extends StatelessWidget {
  Future<Map<String, dynamic>?> showFilters(BuildContext context) async {
    final popup = CyberPopup(
      context: context,
      position: PopupPosition.bottom,
      child: _buildFilterContent(),
      height: 400,
    );

    return await popup.show<Map<String, dynamic>>();
  }

  Widget _buildFilterContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Handle bar
        Center(
          child: Container(
            margin: EdgeInsets.only(top: 8, bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        
        // Title
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Bộ lọc',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        SizedBox(height: 16),
        
        // Filter options
        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 20),
            children: [
              CheckboxListTile(
                title: Text('Đang hoạt động'),
                value: true,
                onChanged: (value) {},
              ),
              CheckboxListTile(
                title: Text('Tạm dừng'),
                value: false,
                onChanged: (value) {},
              ),
            ],
          ),
        ),
        
        // Actions
        Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => CyberPopup.close(context),
                  child: Text('Hủy'),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    CyberPopup.close(context, {
                      'active': true,
                      'paused': false,
                    });
                  },
                  child: Text('Áp dụng'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
```

### 3. Full Screen Modal

Full screen form.

```dart
class AddItemScreen extends StatelessWidget {
  Future<void> showAddItem(BuildContext context) async {
    final popup = CyberPopup(
      context: context,
      position: PopupPosition.fullScreen,
      child: _buildAddItemScreen(),
    );

    final item = await popup.show<Map<String, dynamic>>();
    
    if (item != null) {
      print('Item added: $item');
    }
  }

  Widget _buildAddItemScreen() {
    return Scaffold(
      appBar: AppBar(
        title: Text('Thêm mới'),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => CyberPopup.close(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              CyberPopup.close(context, {
                'name': 'New Item',
                'price': 100000,
              });
            },
            child: Text('Lưu'),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Tên sản phẩm',
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Giá',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }
}
```

### 4. Different Animations

Các kiểu animation khác nhau.

```dart
// Fade animation
final popup1 = CyberPopup(
  context: context,
  child: MyContent(),
  animation: PopupAnimation.fade,
);

// Scale animation
final popup2 = CyberPopup(
  context: context,
  child: MyContent(),
  animation: PopupAnimation.scale,
);

// Slide animation
final popup3 = CyberPopup(
  context: context,
  child: MyContent(),
  animation: PopupAnimation.slide,
);

// Slide and fade
final popup4 = CyberPopup(
  context: context,
  child: MyContent(),
  animation: PopupAnimation.slideAndFade,
);

// No animation
final popup5 = CyberPopup(
  context: context,
  child: MyContent(),
  animation: PopupAnimation.none,
);
```

### 5. Custom Styling

Tùy chỉnh màu sắc và kích thước.

```dart
final popup = CyberPopup(
  context: context,
  child: MyContent(),
  
  // Size
  width: 350,
  height: 250,
  
  // Spacing
  margin: EdgeInsets.all(24),
  padding: EdgeInsets.all(20),
  
  // Appearance
  backgroundColor: Colors.white,
  borderRadius: BorderRadius.circular(16),
  
  // Shadow
  boxShadow: BoxShadow(
    color: Colors.black.withOpacity(0.3),
    blurRadius: 20,
    offset: Offset(0, 10),
  ),
  
  // Barrier
  barrierColor: Colors.black.withOpacity(0.7),
  barrierDismissible: true,
);

await popup.show();
```

### 6. With Callbacks

Sử dụng callbacks.

```dart
final popup = CyberPopup(
  context: context,
  child: MyContent(),
  
  onShow: () {
    print('Popup opened');
    // Load data, start animation, etc.
  },
  
  onClose: (result) {
    print('Popup closed with result: $result');
    // Save state, cleanup, etc.
  },
);

await popup.show();
```

### 7. Non-Dismissible Popup

Không cho phép dismiss bằng tap ngoài.

```dart
final popup = CyberPopup(
  context: context,
  child: LoadingWidget(),
  
  barrierDismissible: false,  // Can't dismiss by tapping outside
  
  // User MUST use close() to dismiss
);

await popup.show();

// Later...
CyberPopup.close(context);
```

### 8. Top Notification

Thông báo từ trên xuống.

```dart
class TopNotification extends StatelessWidget {
  Future<void> showNotification(BuildContext context, String message) async {
    final popup = CyberPopup(
      context: context,
      position: PopupPosition.top,
      animation: PopupAnimation.slide,
      child: _buildNotificationContent(message),
      width: double.infinity,
      margin: EdgeInsets.zero,
      borderRadius: BorderRadius.zero,
    );

    await popup.show();
    
    // Auto dismiss after 3 seconds
    Future.delayed(Duration(seconds: 3), () {
      if (context.mounted) {
        CyberPopup.close(context);
      }
    });
  }

  Widget _buildNotificationContent(String message) {
    return Container(
      padding: EdgeInsets.all(16),
      color: Colors.green,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 9. Image Viewer

Full screen image viewer.

```dart
class ImageViewerPopup extends StatelessWidget {
  Future<void> showImage(BuildContext context, String imageUrl) async {
    final popup = CyberPopup(
      context: context,
      position: PopupPosition.fullScreen,
      animation: PopupAnimation.fade,
      backgroundColor: Colors.black,
      child: _buildImageViewer(imageUrl),
    );

    await popup.show();
  }

  Widget _buildImageViewer(String imageUrl) {
    return Stack(
      children: [
        // Image
        Center(
          child: InteractiveViewer(
            child: Image.network(imageUrl),
          ),
        ),
        
        // Close button
        Positioned(
          top: 40,
          right: 20,
          child: IconButton(
            icon: Icon(Icons.close, color: Colors.white, size: 30),
            onPressed: () => CyberPopup.close(context),
          ),
        ),
      ],
    );
  }
}
```

### 10. Selection Popup

Popup để chọn từ danh sách.

```dart
class SelectionPopup extends StatelessWidget {
  Future<String?> showSelection(
    BuildContext context,
    List<String> items,
  ) async {
    final popup = CyberPopup(
      context: context,
      position: PopupPosition.center,
      child: _buildSelectionList(items),
      width: 300,
    );

    return await popup.show<String>();
  }

  Widget _buildSelectionList(List<String> items) {
    return Container(
      constraints: BoxConstraints(maxHeight: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Chọn một mục',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Divider(),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(items[index]),
                  onTap: () => CyberPopup.close(context, items[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Features

### 1. Multiple Positions

**Top**: Notification-style
```dart
position: PopupPosition.top
```

**Center**: Dialog-style
```dart
position: PopupPosition.center
```

**Bottom**: Bottom sheet-style
```dart
position: PopupPosition.bottom
```

**Full Screen**: Modal screen
```dart
position: PopupPosition.fullScreen
```

### 2. Rich Animations

- **Slide**: Slide from top/bottom
- **Fade**: Fade in/out
- **Scale**: Scale up/down
- **SlideAndFade**: Combined
- **None**: Instant

### 3. Return Values

Type-safe return values:

```dart
final result = await popup.show<bool>();
final data = await popup.show<Map<String, dynamic>>();
final selected = await popup.show<String>();
```

### 4. Barrier Control

```dart
barrierDismissible: true,      // Allow dismiss
barrierColor: Colors.black54,   // Custom color
```

### 5. Lifecycle Callbacks

```dart
onShow: () => print('Opened'),
onClose: (result) => print('Closed: $result'),
```

### 6. Keyboard Aware

Bottom sheet auto-adjusts for keyboard:

```dart
isScrollControlled: true,  // Respects keyboard
```

---

## Best Practices

### 1. Position Selection

```dart
// ✅ GOOD: Use appropriate position
position: PopupPosition.center,   // For dialogs
position: PopupPosition.bottom,   // For options/filters
position: PopupPosition.fullScreen, // For forms

// ❌ BAD: Wrong position
position: PopupPosition.top,  // For form (should be fullScreen)
```

### 2. Size Constraints

```dart
// ✅ GOOD: Reasonable sizes
width: 300,
height: 400,

// ✅ GOOD: Responsive
width: MediaQuery.of(context).size.width * 0.9,

// ❌ BAD: Too large
width: 1000,  // Bigger than screen!
```

### 3. Return Values

```dart
// ✅ GOOD: Type-safe
final result = await popup.show<bool>();
if (result == true) { ... }

// ❌ BAD: No type
final result = await popup.show();
if (result) { ... }  // May crash!
```

### 4. Dismissible Control

```dart
// ✅ GOOD: Loading popup
barrierDismissible: false,  // Can't dismiss

// ✅ GOOD: Selection popup
barrierDismissible: true,   // Can dismiss

// ❌ BAD: Important form
barrierDismissible: true,   // User might lose data!
```

### 5. Close Properly

```dart
// ✅ GOOD: With result
CyberPopup.close(context, result);

// ✅ GOOD: No result
CyberPopup.close(context);

// ❌ BAD: Using Navigator directly
Navigator.pop(context);  // Less clear
```

---

## Troubleshooting

### Popup không hiển thị

**Nguyên nhân:** Context không valid

**Giải pháp:**
```dart
// ✅ Use correct context
final popup = CyberPopup(
  context: context,  // From build method
  child: MyContent(),
);
```

### Bottom sheet bị keyboard che

**Nguyên nhân:** Chưa set isScrollControlled

**Giải pháp:**
```dart
// ✅ CORRECT
CyberPopup(
  position: PopupPosition.bottom,
  isScrollControlled: true,  // Important!
)
```

### Animation giật

**Nguyên nhân:** transitionDuration quá ngắn

**Giải pháp:**
```dart
// ✅ CORRECT
transitionDuration: Duration(milliseconds: 300),

// ❌ WRONG
transitionDuration: Duration(milliseconds: 50),
```

### Close không hoạt động

**Nguyên nhân:** Sai context

**Giải pháp:**
```dart
// ✅ CORRECT: Use Builder
Builder(
  builder: (context) {
    return ElevatedButton(
      onPressed: () => CyberPopup.close(context),
      child: Text('Close'),
    );
  },
)

// ❌ WRONG: Wrong context
ElevatedButton(
  onPressed: () => CyberPopup.close(outerContext),
)
```

### Result = null

**Nguyên nhân:** User dismissed without result

**Giải pháp:**
```dart
// ✅ CORRECT: Check null
final result = await popup.show<String>();
if (result != null) {
  process(result);
}

// ❌ WRONG: No null check
final result = await popup.show<String>();
process(result!);  // May crash!
```

---

## Tips & Tricks

### 1. Reusable Popup

```dart
class MyPopup {
  static Future<bool?> showConfirm(
    BuildContext context,
    String message,
  ) async {
    final popup = CyberPopup(
      context: context,
      child: ConfirmWidget(message),
      position: PopupPosition.center,
      width: 300,
    );
    
    return await popup.show<bool>();
  }
}

// Usage
final confirmed = await MyPopup.showConfirm(context, 'Delete?');
```

### 2. Auto Dismiss

```dart
void showAutoClose(BuildContext context) async {
  final popup = CyberPopup(
    context: context,
    child: SuccessMessage(),
  );
  
  popup.show();
  
  // Auto close after 2 seconds
  Future.delayed(Duration(seconds: 2), () {
    if (context.mounted) {
      CyberPopup.close(context);
    }
  });
}
```

### 3. Loading Popup

```dart
void showLoading(BuildContext context) {
  CyberPopup(
    context: context,
    child: Center(
      child: CircularProgressIndicator(),
    ),
    barrierDismissible: false,
    width: 100,
    height: 100,
  ).show();
}

void hideLoading(BuildContext context) {
  CyberPopup.close(context);
}
```

### 4. Confirm Before Close

```dart
Widget _buildFormContent() {
  return WillPopScope(
    onWillPop: () async {
      final leave = await showConfirm();
      return leave;
    },
    child: MyForm(),
  );
}
```

### 5. Chain Popups

```dart
Future<void> showChainedPopups(BuildContext context) async {
  final step1 = await showStep1(context);
  if (step1 == null) return;
  
  final step2 = await showStep2(context, step1);
  if (step2 == null) return;
  
  final step3 = await showStep3(context, step2);
  // Process final result
}
```

---

## Performance Tips

1. **Reuse Widgets**: Don't recreate child widgets
2. **Lazy Loading**: Build content only when needed
3. **Animation Duration**: Keep 100-300ms
4. **Barrier Color**: Use semi-transparent (0.5-0.7 opacity)
5. **Clean Up**: Always dispose resources in onClose

---

## Common Patterns

### Confirmation Dialog

```dart
position: PopupPosition.center,
width: 300,
animation: PopupAnimation.scale,
```

### Options Sheet

```dart
position: PopupPosition.bottom,
animation: PopupAnimation.slide,
```

### Form Screen

```dart
position: PopupPosition.fullScreen,
animation: PopupAnimation.fade,
```

### Notification

```dart
position: PopupPosition.top,
animation: PopupAnimation.slide,
barrierDismissible: false,
```

---

## Version History

### 1.0.0
- Initial release
- 4 positions support
- 5 animation types
- Generic return values
- onShow/onClose callbacks
- Barrier customization
- Static close() helper
- Keyboard aware bottom sheets

---

## License

MIT License - CyberFramework
