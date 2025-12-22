# CyberRadioBox - Hướng Dẫn Sử Dụng

## Giới Thiệu

`CyberRadioBox` là iOS-style radio button với data binding, hỗ trợ group selection.

## Properties

| Property | Type | Mô tả |
|----------|------|-------|
| `text` | `dynamic` | Value binding (giá trị được chọn của group) |
| `group` | `dynamic` | Tên nhóm radio buttons |
| `value` | `dynamic` | Giá trị của radio này |
| `label` | `String?` | Label hiển thị |
| `enabled` | `bool` | Bật/tắt |
| `isVisible` | `dynamic` | Điều khiển hiển thị |
| `labelStyle` | `TextStyle?` | Style cho label |
| `onChanged` | `ValueChanged<dynamic>?` | Callback khi thay đổi |
| `onLeaver` | `Function(dynamic)?` | Callback khi chọn |
| `activeColor` | `Color?` | Màu khi selected |
| `fillColor` | `Color?` | Màu dot bên trong |
| `size` | `double?` | Kích thước radio |

## Ví Dụ Cơ Bản

### 1. Radio Group Đơn Giản

```dart
final CyberDataRow row = CyberDataRow();
row['gender'] = 'male';

Column(
  children: [
    CyberRadioBox(
      text: row.bind('gender'),
      group: 'genderGroup',
      value: 'male',
      label: 'Nam',
    ),
    
    CyberRadioBox(
      text: row.bind('gender'),
      group: 'genderGroup',
      value: 'female',
      label: 'Nữ',
    ),
  ],
)
```

### 2. Sử Dụng CyberRadioGroup

```dart
final CyberDataRow row = CyberDataRow();
row['paymentMethod'] = 'cash';

CyberRadioGroup(
  text: row.bind('paymentMethod'),
  group: 'payment',
  items: [
    CyberRadioItem(value: 'cash', label: 'Tiền mặt'),
    CyberRadioItem(value: 'card', label: 'Thẻ'),
    CyberRadioItem(value: 'transfer', label: 'Chuyển khoản'),
  ],
  direction: Axis.vertical,
  spacing: 8,
)
```

### 3. Horizontal Layout

```dart
CyberRadioGroup(
  text: row.bind('size'),
  group: 'sizeGroup',
  items: [
    CyberRadioItem(value: 'S', label: 'S'),
    CyberRadioItem(value: 'M', label: 'M'),
    CyberRadioItem(value: 'L', label: 'L'),
    CyberRadioItem(value: 'XL', label: 'XL'),
  ],
  direction: Axis.horizontal,
  spacing: 16,
)
```

### 4. Custom Styling

```dart
CyberRadioBox(
  text: row.bind('subscription'),
  group: 'plan',
  value: 'premium',
  label: 'Premium Plan',
  activeColor: Colors.purple,
  fillColor: Colors.white,
  size: 28,
  labelStyle: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  ),
)
```

## Type Preservation

RadioBox tự động giữ nguyên kiểu dữ liệu:

```dart
// Int values
row['status'] = 1;

CyberRadioBox(
  text: row.bind('status'),
  value: 1,  // int
  // ...
)
// Sau khi chọn: row['status'] vẫn là int

// String values
row['type'] = "A";

CyberRadioBox(
  text: row.bind('type'),
  value: "A",  // string
  // ...
)
// Sau khi chọn: row['type'] vẫn là string
```

## Use Cases

### 1. Gender Selection

```dart
CyberRadioGroup(
  text: row.bind('gender'),
  group: 'gender',
  items: [
    CyberRadioItem(value: 'M', label: 'Nam'),
    CyberRadioItem(value: 'F', label: 'Nữ'),
    CyberRadioItem(value: 'O', label: 'Khác'),
  ],
)
```

### 2. Payment Method

```dart
CyberRadioGroup(
  text: row.bind('paymentMethod'),
  group: 'payment',
  items: [
    CyberRadioItem(
      value: 'cash',
      label: 'Tiền mặt',
      activeColor: Colors.green,
    ),
    CyberRadioItem(
      value: 'card',
      label: 'Thẻ tín dụng',
      activeColor: Colors.blue,
    ),
    CyberRadioItem(
      value: 'ewallet',
      label: 'Ví điện tử',
      activeColor: Colors.orange,
    ),
  ],
  onChanged: (value) {
    print('Payment method: $value');
  },
)
```

### 3. Priority Selection

```dart
row['priority'] = 1; // int value

CyberRadioGroup(
  text: row.bind('priority'),
  group: 'priority',
  items: [
    CyberRadioItem(value: 1, label: 'Thấp'),
    CyberRadioItem(value: 2, label: 'Trung bình'),
    CyberRadioItem(value: 3, label: 'Cao'),
    CyberRadioItem(value: 4, label: 'Khẩn cấp'),
  ],
)
```

## Tips & Best Practices

### ✅ DO

```dart
// ✅ Same group for related options
CyberRadioBox(group: 'paymentGroup', ...)

// ✅ Use meaningful values
CyberRadioBox(value: 'premium', ...)
CyberRadioBox(value: 'basic', ...)
```

### ❌ DON'T

```dart
// ❌ Don't use different groups
CyberRadioBox(group: 'group1', ...)
CyberRadioBox(group: 'group2', ...)  // Won't work together
```

---

## Xem Thêm

- [CyberCheckbox](./CyberCheckbox.md) - Checkbox control
- [CyberComboBox](./CyberComboBox.md) - Combo box control
