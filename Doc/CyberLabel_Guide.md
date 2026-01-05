# CyberLabel - Hướng Dẫn Sử Dụng

## Giới Thiệu

`CyberLabel` là label/text display widget với data binding, format, icon support, và clickable events.

## Properties

| Property | Type | Mặc định | Mô tả |
|----------|------|----------|-------|
| `text` | `dynamic` | `null` | Text hoặc binding |
| `format` | `String?` | `null` | Format string với {0} |
| `style` | `TextStyle?` | `null` | Style cho text |
| `textalign` | `TextAlign?` | `null` | Text alignment |
| `textcolor` | `Color?` | `null` | Màu text |
| `backgroundColor` | `Color?` | `null` | Màu nền |
| `isVisible` | `dynamic` | `true` | Điều khiển hiển thị |
| `isIcon` | `bool` | `false` | Hiển thị như icon |
| `iconSize` | `double?` | `null` | Kích thước icon |
| `onLeaver` | `Function(dynamic)?` | `null` | Callback khi click |
| `showRipple` | `bool?` | `true` | Hiển thị ripple effect |
| `rippleColor` | `Color?` | `null` | Màu ripple |

## Ví Dụ Cơ Bản

### 1. Label Đơn Giản

```dart
CyberLabel(
  text: 'Hello World',
  style: TextStyle(fontSize: 16),
)
```

### 2. Label Với Data Binding

```dart
final CyberDataRow row = CyberDataRow();
row['userName'] = 'John Doe';

CyberLabel(
  text: row.bind('userName'),
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
)
```

### 3. Label Với Format

```dart
CyberLabel(
  text: row.bind('amount'),
  format: 'Tổng tiền: {0} VNĐ',
  style: TextStyle(fontSize: 16),
)
```

### 4. Clickable Label

```dart
CyberLabel(
  text: 'Nhấn vào đây',
  style: TextStyle(
    fontSize: 16,
    color: Colors.blue,
    decoration: TextDecoration.underline,
  ),
  onLeaver: (_) {
    print('Label clicked!');
  },
)
```

### 5. Icon Display

```dart
// Hiển thị icon từ code point
CyberLabel(
  text: '0xe047',  // Material Icon code
  isIcon: true,
  iconSize: 24,
  textcolor: Colors.blue,
  onLeaver: (_) {
    print('Icon tapped');
  },
)
```

## Icon Code Points

```dart
// Format hỗ trợ:
"0xe047"        // Hex with prefix
"e047"          // Hex without prefix
"57415"         // Decimal

// Example
CyberLabel(
  text: '0xe145',  // Icons.home
  isIcon: true,
  iconSize: 32,
)
```

## Extension Methods

### toClickableLabel

```dart
"Click me".toClickableLabel(
  onTap: (_) => print('Tapped'),
  style: TextStyle(color: Colors.blue),
  showRipple: true,
)
```

### toIconLabel

```dart
"0xe145".toIconLabel(
  size: 24,
  color: Colors.blue,
  onTap: (_) => print('Icon tapped'),
)
```

## Use Cases

### 1. Display Bound Data

```dart
CyberLabel(
  text: row.bind('totalAmount'),
  format: 'Total: {0}',
  style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.green,
  ),
)
```

### 2. Link/Button Style

```dart
CyberLabel(
  text: 'Xem chi tiết',
  textcolor: Colors.blue,
  style: TextStyle(
    decoration: TextDecoration.underline,
  ),
  onLeaver: (_) {
    Navigator.push(...);
  },
)
```

### 3. Status Display

```dart
CyberLabel(
  text: row.bind('status'),
  textcolor: row['status'] == 'Active' 
    ? Colors.green 
    : Colors.red,
  style: TextStyle(fontWeight: FontWeight.bold),
)
```

### 4. Icon Button

```dart
CyberLabel(
  text: '0xe3c9',  // Icons.delete
  isIcon: true,
  iconSize: 20,
  textcolor: Colors.red,
  onLeaver: (_) {
    deleteItem();
  },
  showRipple: true,
  rippleColor: Colors.red,
)
```

---

## Xem Thêm

- [CyberText](./CyberText.md) - Text input control
- [CyberDataRow](./CyberDataRow.md) - Data binding system
