# CyberAction - Floating Action Menu

## Mục Lục
1. [Giới Thiệu](#giới-thiệu)
2. [Các Enum](#các-enum)
3. [CyberButtonAction](#cyberbuttonaction)
4. [CyberAction Widget](#cyberaction-widget)
5. [Ví Dụ Sử Dụng](#ví-dụ-sử-dụng)
6. [Features](#features)
7. [Best Practices](#best-practices)
8. [Troubleshooting](#troubleshooting)

---

## Giới Thiệu

`CyberAction` là một widget floating action menu với khả năng tự động ẩn/hiện, hỗ trợ nhiều kiểu hiển thị và tùy chỉnh linh hoạt. Widget này cung cấp trải nghiệm người dùng tốt trên cả desktop (hover) và mobile (tap).

### Import

```dart
import 'package:cyberframework/cyberframework.dart';
```

---

## Các Enum

### CyberActionType

Định nghĩa kiểu hiển thị của menu.

```dart
enum CyberActionType {
  /// Menu có main button, tự động ẩn/hiện khi hover hoặc click
  autoShow,

  /// Menu không có main button, items luôn hiển thị
  alwaysShow,
}
```

**Khi nào dùng:**
- `autoShow`: Khi cần tiết kiệm không gian màn hình, phù hợp cho quick actions
- `alwaysShow`: Khi muốn menu luôn visible, thích hợp cho navigation bar

### CyberActionDirection

Định nghĩa hướng mở rộng của menu.

```dart
enum CyberActionDirection {
  /// Mở rộng theo chiều dọc (top to bottom)
  vertical,

  /// Mở rộng theo chiều ngang (left to right)
  horizontal,
}
```

### LabelPosition

Định nghĩa vị trí label.

```dart
enum LabelPosition {
  /// Label ở bên phải icon (mặc định)
  right,

  /// Label ở bên trái icon
  left,

  /// Label ở bên dưới icon
  bottom,
}
```

---

## CyberButtonAction

Class định nghĩa một button action trong menu.

### Constructor

```dart
const CyberButtonAction({
  required this.label,
  required this.icon,
  this.onclick,
  this.styleLabel,
  this.styleIcon,
  this.backgroundColor,
  this.backgroundOpacity,
  this.iconColor,
  this.iconSize,
  this.visible = true,
  this.showLabel = false,
  this.labelPosition = LabelPosition.right,
})
```

### Properties

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `label` | `String` | Label hiển thị khi hover hoặc khi showLabel = true | Required |
| `icon` | `String` | Icon code (Material Icons unicode, ví dụ: "e145") | Required |
| `onclick` | `VoidCallback?` | Callback khi click vào button | null |
| `styleLabel` | `TextStyle?` | Style cho label text | null |
| `styleIcon` | `TextStyle?` | Style cho icon | null |
| `backgroundColor` | `Color?` | Màu nền của button | Color(255, 247, 247, 247) |
| `backgroundOpacity` | `double?` | Opacity của background (0.0 - 1.0) | 0.95 |
| `iconColor` | `Color?` | Màu icon (override styleIcon.color) | null |
| `iconSize` | `double?` | Kích thước icon | 20.0 |
| `visible` | `bool` | Hiển thị button hay không | true |
| `showLabel` | `bool` | Luôn hiển thị label (không cần hover) | false |
| `labelPosition` | `LabelPosition` | Vị trí của label | LabelPosition.right |

### Ví Dụ

```dart
// Button cơ bản
const CyberButtonAction(
  label: 'Thêm mới',
  icon: 'e145', // add icon
  onclick: () => print('Add clicked'),
)

// Button với custom styling
const CyberButtonAction(
  label: 'Xóa',
  icon: 'e872', // delete icon
  onclick: () => handleDelete(),
  iconColor: Colors.red,
  iconSize: 24.0,
  backgroundColor: Colors.red.shade50,
  showLabel: true,
  labelPosition: LabelPosition.right,
)

// Button với custom label style
CyberButtonAction(
  label: 'Settings',
  icon: 'e8b8',
  onclick: () => openSettings(),
  styleLabel: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Colors.blue,
  ),
)
```

### Các Icon Thường Dùng

```dart
// Common Material Icons codes
'e145' // add
'e3c9' // edit
'e872' // delete
'e161' // save
'e5cd' // close
'e8b6' // search
'e8b8' // settings
'e88a' // home
'e7f4' // notifications
'e7fd' // person
'e5d2' // add_circle
'e5c9' // remove_circle
'e5ca' // refresh
'e5cc' // share
'e5d4' // more_vert
```

---

## CyberAction Widget

### Constructor

```dart
const CyberAction({
  super.key,
  required this.children,
  this.type = CyberActionType.autoShow,
  this.top,
  this.left,
  this.bottom,
  this.right,
  this.isCenterVer = false,
  this.isCenterHor = false,
  this.direction = CyberActionDirection.vertical,
  this.spacing = 6.0,
  this.mainButtonColor,
  this.mainButtonIcon,
  this.mainButtonSize = 56.0,
  this.mainIconColor,
  this.animationDuration = 300,
  this.showBackdrop = false,
  this.backdropColor,
  this.isShowBackgroundColor = true,
  this.backgroundColor,
  this.backgroundOpacity = 0.85,
  this.borderRadius = 12.0,
  this.containerBorderWidth,
  this.containerBorderColor,
  this.containerPadding = const EdgeInsets.all(8),
})
```

### Properties

#### Required

| Property | Type | Mô Tả |
|----------|------|-------|
| `children` | `List<CyberButtonAction>` | Danh sách các button actions |

#### Positioning

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `top` | `double?` | Khoảng cách từ top | null |
| `left` | `double?` | Khoảng cách từ left | null |
| `bottom` | `double?` | Khoảng cách từ bottom | null |
| `right` | `double?` | Khoảng cách từ right | null |
| `isCenterVer` | `bool` | Căn giữa theo chiều dọc | false |
| `isCenterHor` | `bool` | Căn giữa theo chiều ngang | false |

#### Layout & Behavior

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `type` | `CyberActionType` | Kiểu hiển thị menu | autoShow |
| `direction` | `CyberActionDirection` | Hướng mở rộng menu | vertical |
| `spacing` | `double` | Khoảng cách giữa các items | 6.0 |

#### Main Button (chỉ cho autoShow)

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `mainButtonColor` | `Color?` | Màu nền main FAB | Theme.primaryColor |
| `mainButtonIcon` | `String?` | Icon của main FAB | "e5d4" |
| `mainButtonSize` | `double?` | Kích thước main FAB | 56.0 |
| `mainIconColor` | `Color?` | Màu icon của main FAB | Colors.white |

#### Animation & Backdrop

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `animationDuration` | `int` | Thời gian animation (ms) | 300 |
| `showBackdrop` | `bool` | Hiển thị backdrop khi mở | false |
| `backdropColor` | `Color?` | Màu backdrop | Colors.black (alpha: 0.3) |

#### Container Styling

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `isShowBackgroundColor` | `bool` | Hiển thị background container | true |
| `backgroundColor` | `Color?` | Màu nền container | Colors.white (alpha: 0.1) |
| `backgroundOpacity` | `double` | Opacity background (0.0 - 1.0) | 0.85 |
| `borderRadius` | `double` | Bo góc container | 12.0 |
| `containerBorderWidth` | `double?` | Độ dày border | null |
| `containerBorderColor` | `Color?` | Màu border | Colors.white (alpha: 0.3) |
| `containerPadding` | `EdgeInsets` | Padding của container | EdgeInsets.all(8) |

---

## Ví Dụ Sử Dụng

### 1. Menu Auto Show - Vertical (Classic FAB)

Menu nổi ở góc dưới phải, tự động ẩn/hiện.

```dart
Scaffold(
  body: Stack(
    children: [
      // Your main content
      Center(child: Text('Main Content')),
      
      // Floating action menu
      CyberAction(
        type: CyberActionType.autoShow,
        bottom: 16,
        right: 16,
        direction: CyberActionDirection.vertical,
        children: [
          CyberButtonAction(
            label: 'Thêm',
            icon: 'e145',
            onclick: () => print('Add'),
            iconColor: Colors.green,
          ),
          CyberButtonAction(
            label: 'Sửa',
            icon: 'e3c9',
            onclick: () => print('Edit'),
            iconColor: Colors.blue,
          ),
          CyberButtonAction(
            label: 'Xóa',
            icon: 'e872',
            onclick: () => print('Delete'),
            iconColor: Colors.red,
          ),
        ],
      ),
    ],
  ),
)
```

### 2. Menu Always Show - Horizontal (Navigation Bar)

Menu luôn hiển thị ở trên cùng, giữa màn hình.

```dart
Scaffold(
  body: Stack(
    children: [
      // Main content
      YourContent(),
      
      // Top navigation bar
      CyberAction(
        type: CyberActionType.alwaysShow,
        top: 16,
        isCenterHor: true,
        direction: CyberActionDirection.horizontal,
        isShowBackgroundColor: true,
        backgroundColor: Colors.blue.shade100,
        borderRadius: 20,
        children: [
          CyberButtonAction(
            label: 'Home',
            icon: 'e88a',
            showLabel: true,
            labelPosition: LabelPosition.bottom,
            onclick: () => navigateToHome(),
          ),
          CyberButtonAction(
            label: 'Search',
            icon: 'e8b6',
            showLabel: true,
            labelPosition: LabelPosition.bottom,
            onclick: () => navigateToSearch(),
          ),
          CyberButtonAction(
            label: 'Profile',
            icon: 'e7fd',
            showLabel: true,
            labelPosition: LabelPosition.bottom,
            onclick: () => navigateToProfile(),
          ),
        ],
      ),
    ],
  ),
)
```

### 3. Sử Dụng Extension Method

Cách ngắn gọn để tạo CyberAction từ List.

```dart
Stack(
  children: [
    YourContent(),
    
    // Tạo menu từ list
    [
      CyberButtonAction(
        label: 'Save',
        icon: 'e161',
        onclick: () => save(),
      ),
      CyberButtonAction(
        label: 'Cancel',
        icon: 'e5cd',
        onclick: () => cancel(),
      ),
    ].toCyberAction(
      type: CyberActionType.autoShow,
      bottom: 16,
      right: 16,
      mainButtonColor: Colors.purple,
      showBackdrop: true,
    ),
  ],
)
```

### 4. Menu Với Custom Styling (Dark Theme)

Menu với theme tối và frosted glass effect.

```dart
CyberAction(
  type: CyberActionType.autoShow,
  bottom: 80,
  right: 16,
  backgroundColor: Colors.black87,
  backgroundOpacity: 0.9,
  borderRadius: 20,
  containerBorderWidth: 2,
  containerBorderColor: Colors.white24,
  containerPadding: EdgeInsets.all(12),
  mainButtonColor: Colors.deepPurple,
  mainButtonIcon: 'e8b8', // settings icon
  children: [
    CyberButtonAction(
      label: 'Dark Mode',
      icon: 'e51c',
      iconColor: Colors.white,
      backgroundColor: Colors.transparent,
      onclick: () => toggleDarkMode(),
    ),
    CyberButtonAction(
      label: 'Notifications',
      icon: 'e7f4',
      iconColor: Colors.white,
      backgroundColor: Colors.transparent,
      onclick: () => openNotifications(),
    ),
    CyberButtonAction(
      label: 'Language',
      icon: 'e894',
      iconColor: Colors.white,
      backgroundColor: Colors.transparent,
      onclick: () => changeLanguage(),
    ),
  ],
)
```

### 5. Menu Căn Giữa Với Backdrop

Menu ở giữa màn hình với backdrop mờ.

```dart
CyberAction(
  type: CyberActionType.autoShow,
  isCenterVer: true,
  isCenterHor: true,
  showBackdrop: true,
  backdropColor: Colors.black54,
  mainButtonColor: Colors.teal,
  children: [
    CyberButtonAction(
      label: 'Camera',
      icon: 'e3af',
      onclick: () => openCamera(),
    ),
    CyberButtonAction(
      label: 'Gallery',
      icon: 'e410',
      onclick: () => openGallery(),
    ),
    CyberButtonAction(
      label: 'File',
      icon: 'e24d',
      onclick: () => pickFile(),
    ),
  ],
)
```

### 6. Menu Horizontal Ở Bottom (Bottom Navigation)

```dart
CyberAction(
  type: CyberActionType.alwaysShow,
  bottom: 0,
  isCenterHor: true,
  direction: CyberActionDirection.horizontal,
  backgroundColor: Colors.white,
  backgroundOpacity: 1.0,
  containerPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  spacing: 30,
  children: [
    CyberButtonAction(
      label: 'Home',
      icon: 'e88a',
      showLabel: true,
      labelPosition: LabelPosition.bottom,
      iconColor: Colors.blue,
      onclick: () => navigateToHome(),
    ),
    CyberButtonAction(
      label: 'Search',
      icon: 'e8b6',
      showLabel: true,
      labelPosition: LabelPosition.bottom,
      iconColor: Colors.grey,
      onclick: () => navigateToSearch(),
    ),
    CyberButtonAction(
      label: 'Cart',
      icon: 'e8cc',
      showLabel: true,
      labelPosition: LabelPosition.bottom,
      iconColor: Colors.grey,
      onclick: () => navigateToCart(),
    ),
    CyberButtonAction(
      label: 'Profile',
      icon: 'e7fd',
      showLabel: true,
      labelPosition: LabelPosition.bottom,
      iconColor: Colors.grey,
      onclick: () => navigateToProfile(),
    ),
  ],
)
```

### 7. Menu Với Items Có Label Bên Trái

```dart
CyberAction(
  type: CyberActionType.autoShow,
  bottom: 16,
  left: 16, // Đặt bên trái
  children: [
    CyberButtonAction(
      label: 'Quick Add',
      icon: 'e145',
      showLabel: true,
      labelPosition: LabelPosition.left, // Label bên trái icon
      onclick: () => quickAdd(),
    ),
    CyberButtonAction(
      label: 'Quick Edit',
      icon: 'e3c9',
      showLabel: true,
      labelPosition: LabelPosition.left,
      onclick: () => quickEdit(),
    ),
  ],
)
```

### 8. Menu Với Visibility Control

```dart
class MyPage extends StatefulWidget {
  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  bool canEdit = false;
  bool canDelete = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          YourContent(),
          
          CyberAction(
            bottom: 16,
            right: 16,
            children: [
              CyberButtonAction(
                label: 'View',
                icon: 'e8f4',
                visible: true, // Luôn hiển thị
                onclick: () => view(),
              ),
              CyberButtonAction(
                label: 'Edit',
                icon: 'e3c9',
                visible: canEdit, // Conditional visibility
                onclick: () => edit(),
              ),
              CyberButtonAction(
                label: 'Delete',
                icon: 'e872',
                visible: canDelete,
                onclick: () => delete(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

---

## Features

### 1. Auto Show/Hide

**Desktop (Mouse):**
- Hover vào main button → menu tự động mở
- Di chuột ra ngoài → menu tự động đóng
- Click vào main button → pin menu (giữ nguyên trạng thái mở)
- Click lại main button → unpin và đóng menu

**Mobile (Touch):**
- Tap vào main button → mở/đóng menu
- Tap vào backdrop (nếu có) → đóng menu
- Tap vào item → thực hiện action và tự động đóng menu

### 2. Always Show Mode

- Menu luôn hiển thị, không có main button
- Thích hợp cho:
  - Bottom navigation bar
  - Top toolbar
  - Side menu (khi expanded)
  - Quick action panel

### 3. Flexible Positioning

#### Absolute Positioning
```dart
// Bottom right
CyberAction(bottom: 16, right: 16, ...)

// Top left
CyberAction(top: 16, left: 16, ...)

// Custom position
CyberAction(top: 100, left: 50, ...)
```

#### Center Alignment
```dart
// Center both directions
CyberAction(isCenterVer: true, isCenterHor: true, ...)

// Center horizontal only
CyberAction(isCenterHor: true, top: 16, ...)

// Center vertical only
CyberAction(isCenterVer: true, left: 16, ...)
```

### 4. Scrollable Container

Menu tự động scroll khi items nhiều:
- Chiều dọc: Max 70% chiều cao màn hình
- Chiều ngang: Max 70% chiều rộng màn hình
- Smooth scrolling
- Maintain item spacing

### 5. Frosted Glass Effect

Background với blur effect và custom styling:
```dart
CyberAction(
  isShowBackgroundColor: true,
  backgroundColor: Colors.white.withOpacity(0.1),
  backgroundOpacity: 0.85, // Overall opacity
  borderRadius: 12.0,
  containerBorderWidth: 1,
  containerBorderColor: Colors.white.withOpacity(0.3),
  ...
)
```

### 6. Label Display Modes

#### Desktop (Mouse):
```dart
// Hover to show label (default)
CyberButtonAction(
  label: 'Add',
  icon: 'e145',
  showLabel: false, // Show on hover only
)

// Always show label
CyberButtonAction(
  label: 'Add',
  icon: 'e145',
  showLabel: true, // Always visible
)
```

#### Mobile (Touch):
```dart
// Tooltip on long press
CyberButtonAction(
  label: 'Add',
  icon: 'e145',
  showLabel: false, // Tooltip
)

// Always show label
CyberButtonAction(
  label: 'Add',
  icon: 'e145',
  showLabel: true, // Always visible
)
```

### 7. Animation

Smooth animation với customizable duration:
```dart
CyberAction(
  animationDuration: 300, // milliseconds
  ...
)
```

Animation effects:
- Scale and fade in/out
- Rotation của main button icon (45° khi mở)
- Smooth transitions

---

## Best Practices

### 1. Số Lượng Items

```dart
// ✅ GOOD: 3-7 items
CyberAction(
  children: [
    // 5 items - perfect for mobile
    item1, item2, item3, item4, item5,
  ],
)

// ⚠️ ACCEPTABLE: 8-12 items với scroll
CyberAction(
  children: [
    // Có scroll, nhưng UX không tối ưu
    item1, item2, ..., item12,
  ],
)

// ❌ BAD: Quá nhiều items
CyberAction(
  children: [
    // Quá nhiều, nên dùng menu khác hoặc nhóm lại
    item1, item2, ..., item20,
  ],
)
```

### 2. Icon Selection

```dart
// ✅ GOOD: Sử dụng Material Icons rõ ràng
CyberButtonAction(
  label: 'Thêm',
  icon: 'e145', // add - very clear
)

CyberButtonAction(
  label: 'Xóa',
  icon: 'e872', // delete - unmistakable
)

// ❌ BAD: Icon không rõ nghĩa
CyberButtonAction(
  label: 'Xóa',
  icon: 'e5cd', // close - có thể nhầm lẫn
)
```

### 3. Label Text

```dart
// ✅ GOOD: Ngắn gọn, rõ ràng
CyberButtonAction(label: 'Lưu', ...)
CyberButtonAction(label: 'Hủy', ...)
CyberButtonAction(label: 'Thêm', ...)

// ❌ BAD: Quá dài
CyberButtonAction(
  label: 'Lưu và tiếp tục chỉnh sửa',
  ...
)
```

### 4. Positioning

```dart
// ✅ GOOD: Bottom right cho quick actions (mobile-friendly)
CyberAction(
  bottom: 16,
  right: 16,
  children: quickActions,
)

// ✅ GOOD: Top center cho navigation
CyberAction(
  top: 0,
  isCenterHor: true,
  type: CyberActionType.alwaysShow,
  direction: CyberActionDirection.horizontal,
  children: navItems,
)

// ⚠️ CAREFUL: Top right có thể che các system buttons
CyberAction(
  top: 16, // Có thể che nút back/close
  right: 16,
  ...
)
```

### 5. Backdrop Usage

```dart
// ✅ GOOD: Dùng backdrop khi cần focus
CyberAction(
  showBackdrop: true,
  backdropColor: Colors.black54,
  children: [
    // Important actions need focus
  ],
)

// ❌ BAD: Backdrop cho menu thường xuyên dùng
CyberAction(
  showBackdrop: true, // Annoying nếu dùng thường xuyên
  bottom: 16,
  right: 16,
  children: commonActions,
)
```

### 6. Color Scheme

```dart
// ✅ GOOD: Màu có ý nghĩa
CyberButtonAction(
  label: 'Lưu',
  iconColor: Colors.green, // Positive action
  ...
)

CyberButtonAction(
  label: 'Xóa',
  iconColor: Colors.red, // Destructive action
  ...
)

CyberButtonAction(
  label: 'Sửa',
  iconColor: Colors.blue, // Neutral action
  ...
)

// ❌ BAD: Màu random không có ý nghĩa
CyberButtonAction(
  label: 'Xóa',
  iconColor: Colors.pink, // Confusing
  ...
)
```

### 7. Direction Choice

```dart
// ✅ GOOD: Vertical cho FAB
CyberAction(
  direction: CyberActionDirection.vertical,
  bottom: 16,
  right: 16,
  ...
)

// ✅ GOOD: Horizontal cho navigation
CyberAction(
  direction: CyberActionDirection.horizontal,
  type: CyberActionType.alwaysShow,
  bottom: 0,
  ...
)
```

---

## Troubleshooting

### Menu không hiển thị

**Nguyên nhân:**
1. Tất cả items có `visible = false`
2. Positioning conflicts
3. Parent widget không đủ space
4. Menu bị che bởi widget khác

**Giải pháp:**
```dart
// 1. Kiểm tra visibility
CyberAction(
  children: [
    CyberButtonAction(
      visible: true, // Đảm bảo = true
      ...
    ),
  ],
)

// 2. Kiểm tra positioning
CyberAction(
  bottom: 16, // Đảm bảo không overflow
  right: 16,
  ...
)

// 3. Đảm bảo trong Stack
Stack(
  children: [
    YourContent(),
    CyberAction(...), // Đặt sau để render trên cùng
  ],
)
```

### Animation giật lag

**Nguyên nhân:**
1. animationDuration quá dài
2. Widget tree phức tạp
3. Quá nhiều items

**Giải pháp:**
```dart
// 1. Giảm duration
CyberAction(
  animationDuration: 200, // Từ 300 → 200
  ...
)

// 2. Giảm số items
CyberAction(
  children: [
    // Max 7 items
  ],
)

// 3. Tắt frosted glass nếu cần
CyberAction(
  isShowBackgroundColor: false,
  ...
)
```

### Label không hiển thị trên mobile

**Nguyên nhân:**
- `showLabel = false` và không long press

**Giải pháp:**
```dart
// Option 1: Bật showLabel
CyberButtonAction(
  showLabel: true, // Always show
  ...
)

// Option 2: Hướng dẫn user long press
// Tooltip sẽ tự động hiển thị khi long press
```

### Main button không hoạt động

**Nguyên nhân:**
- Đang dùng `CyberActionType.alwaysShow`

**Giải pháp:**
```dart
// Dùng autoShow nếu cần main button
CyberAction(
  type: CyberActionType.autoShow,
  ...
)
```

### Menu bị overflow

**Nguyên nhân:**
- Quá nhiều items
- Items quá lớn

**Giải pháp:**
```dart
// Menu tự động scroll, nhưng nên giảm items
CyberAction(
  children: [
    // Limit to 7-10 items
  ],
)

// Hoặc giảm kích thước icon
CyberButtonAction(
  iconSize: 18, // Từ 20 → 18
  ...
)
```

---

## Tips & Tricks

### 1. Tạo Quick Action Menu

```dart
// Define actions một lần, reuse nhiều nơi
class QuickActions {
  static List<CyberButtonAction> get actions => [
    CyberButtonAction(
      label: 'Add',
      icon: 'e145',
      onclick: () => navigatorKey.currentState?.pushNamed('/add'),
    ),
    CyberButtonAction(
      label: 'Search',
      icon: 'e8b6',
      onclick: () => navigatorKey.currentState?.pushNamed('/search'),
    ),
  ];
}

// Use anywhere
CyberAction(
  bottom: 16,
  right: 16,
  children: QuickActions.actions,
)
```

### 2. Conditional Items

```dart
// Show different items based on state
CyberAction(
  children: [
    ...baseActions,
    if (isAdmin) adminAction,
    if (canEdit) editAction,
    if (canDelete) deleteAction,
  ],
)
```

### 3. Theme-aware Styling

```dart
// Auto adapt to theme
Widget build(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  return CyberAction(
    backgroundColor: isDark 
      ? Colors.black87 
      : Colors.white.withOpacity(0.1),
    mainButtonColor: Theme.of(context).primaryColor,
    children: actions,
  );
}
```

### 4. Responsive Positioning

```dart
// Different position for mobile/tablet
Widget build(BuildContext context) {
  final isSmallScreen = MediaQuery.of(context).size.width < 600;
  
  return CyberAction(
    bottom: isSmallScreen ? 16 : 32,
    right: isSmallScreen ? 16 : 32,
    children: actions,
  );
}
```

---

## Performance Tips

1. **Reuse CyberButtonAction**: Tạo actions một lần, reuse nhiều nơi
2. **Limit Items**: Giữ số lượng items ≤ 7 cho UX tốt nhất
3. **Optimize Callbacks**: Sử dụng named functions thay vì anonymous functions
4. **Conditional Rendering**: Dùng `visible` thay vì remove/add items

---

## Version History

### 1.0.0
- Initial release
- Auto show/always show modes
- Vertical/horizontal directions
- Frosted glass effect
- Label positioning
- Scrollable container
- Mobile/desktop adaptive

---

## License

MIT License - CyberFramework
