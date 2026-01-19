# CyberFramework Radio Buttons - Hướng Dẫn Sử Dụng

## Tổng Quan

CyberFramework cung cấp 2 cách để làm việc với Radio Buttons:

1. **CyberRadioBox** - Single radio button (Traditional Pattern)
   - Nhiều radio buttons chia sẻ 1 binding chung
   - Mỗi radio có value riêng
   - Khi chọn: field = value của radio được chọn

2. **CyberRadioGroup** - Radio group với multi-column binding
   - Mỗi radio item bind vào 1 column riêng
   - Khi chọn item: column của item đó = selectedValue (default: 1)
   - Các item khác: column = unselectedValue (default: 0)

---

## 1. CyberRadioBox - Traditional Pattern

### Triết Lý

- **Một binding cho cả group**: Tất cả radio buttons trong cùng một nhóm bind vào cùng một field
- **Mỗi radio có value riêng**: Mỗi radio button có giá trị riêng của nó
- **Khi chọn**: Field được set = value của radio button được chọn

### Cú Pháp Cơ Bản

```dart
CyberRadioBox(
  text: drEdit.bind("gender"),      // Binding chung cho cả group
  group: "gender_group",             // Tên nhóm để group các radio lại
  value: "male",                     // Giá trị của radio này
  label: "Nam",                      // Label hiển thị
)
```

### Ví Dụ Đầy Đủ - Chọn Giới Tính

```dart
// Trong CyberDataRow
final drEdit = CyberDataRow.fromMap({
  "gender": "male",  // Giá trị mặc định
});

// Trong UI
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    CyberRadioBox(
      text: drEdit.bind("gender"),
      group: "gender_group",
      value: "male",
      label: "Nam",
    ),
    CyberRadioBox(
      text: drEdit.bind("gender"),
      group: "gender_group",
      value: "female",
      label: "Nữ",
    ),
    CyberRadioBox(
      text: drEdit.bind("gender"),
      group: "gender_group",
      value: "other",
      label: "Khác",
    ),
  ],
)
```

### Ví Dụ - Chọn Phương Thức Thanh Toán

```dart
final drPayment = CyberDataRow.fromMap({
  "payment_method": "cash",
});

Row(
  children: [
    CyberRadioBox(
      text: drPayment.bind("payment_method"),
      group: "payment_group",
      value: "cash",
      label: "Tiền mặt",
      activeColor: Colors.green,
    ),
    const SizedBox(width: 20),
    CyberRadioBox(
      text: drPayment.bind("payment_method"),
      group: "payment_group",
      value: "card",
      label: "Thẻ tín dụng",
      activeColor: Colors.green,
    ),
    const SizedBox(width: 20),
    CyberRadioBox(
      text: drPayment.bind("payment_method"),
      group: "payment_group",
      value: "transfer",
      label: "Chuyển khoản",
      activeColor: Colors.green,
    ),
  ],
)
```

### Thuộc Tính (Properties)

| Thuộc tính | Kiểu | Mô tả | Mặc định |
|-----------|------|-------|----------|
| `text` | dynamic | Binding đến field chứa giá trị (bắt buộc) | - |
| `group` | dynamic | Tên nhóm để group các radio (bắt buộc) | - |
| `value` | dynamic | Giá trị của radio này (bắt buộc) | - |
| `label` | String? | Label hiển thị bên cạnh radio | null |
| `labelStyle` | TextStyle? | Style cho label | null |
| `enabled` | bool | Có enable hay không | true |
| `isVisible` | dynamic | Visible binding | true |
| `onChanged` | ValueChanged? | Callback khi value thay đổi | null |
| `onLeaver` | Function? | Callback khi rời khỏi control | null |
| `activeColor` | Color? | Màu khi được chọn | #007AFF |
| `fillColor` | Color? | Màu của dot bên trong | white |
| `size` | double? | Size của radio button | 24 |

### Tính Năng Nổi Bật

#### 1. iOS-Style Design
```dart
CyberRadioBox(
  text: drEdit.bind("option"),
  group: "option_group",
  value: "option1",
  label: "Option 1",
  size: 28,                    // Tùy chỉnh kích thước
  activeColor: Colors.blue,    // Màu khi chọn
)
```

#### 2. Binding Support
```dart
// Value có thể binding
CyberRadioBox(
  text: drEdit.bind("status"),
  group: "status_group",
  value: drValue.bind("status_value"),  // Dynamic value từ binding
  label: "Active",
)
```

#### 3. Visibility Binding
```dart
CyberRadioBox(
  text: drEdit.bind("type"),
  group: "type_group",
  value: "premium",
  label: "Premium",
  isVisible: drEdit.bind("show_premium"),  // Ẩn/hiện động
)
```

#### 4. Callbacks
```dart
CyberRadioBox(
  text: drEdit.bind("choice"),
  group: "choice_group",
  value: "yes",
  label: "Có",
  onChanged: (value) {
    print("Selected: $value");
  },
  onLeaver: (value) {
    print("Left radio with value: $value");
  },
)
```

---

## 2. CyberRadioGroup - Multi-Column Pattern

### Triết Lý

- **Mỗi item bind vào 1 column riêng**: Mỗi radio item có column binding riêng
- **Multi-column approach**: Thích hợp cho các trường hợp cần lưu multiple boolean flags
- **Tự động exclusive selection**: Khi chọn 1 item, các item khác tự động unselect

### Cú Pháp Cơ Bản

```dart
CyberRadioGroup(
  label: "Loại phương tiện",
  items: [
    CyberRadioItem(
      label: "Ô tô", 
      binding: drEdit.bind("is_car")
    ),
    CyberRadioItem(
      label: "Xe máy", 
      binding: drEdit.bind("is_motorcycle")
    ),
  ],
)
```

### Ví Dụ Đầy Đủ - Chọn Loại Phương Tiện

```dart
// Trong CyberDataRow - Mỗi loại xe có 1 column riêng
final drEdit = CyberDataRow.fromMap({
  "is_car": 0,
  "is_motorcycle": 1,  // Mặc định chọn xe máy
  "is_bicycle": 0,
  "is_other": 0,
});

// Trong UI
CyberRadioGroup(
  label: "Loại phương tiện",
  items: [
    CyberRadioItem(
      label: "Ô tô", 
      binding: drEdit.bind("is_car"),
      icon: "directions_car",
    ),
    CyberRadioItem(
      label: "Xe máy", 
      binding: drEdit.bind("is_motorcycle"),
      icon: "two_wheeler",
    ),
    CyberRadioItem(
      label: "Xe đạp", 
      binding: drEdit.bind("is_bicycle"),
      icon: "pedal_bike",
    ),
    CyberRadioItem(
      label: "Khác", 
      binding: drEdit.bind("is_other"),
      icon: "more_horiz",
    ),
  ],
  direction: Axis.horizontal,
  spacing: 16.0,
)
```

### Ví Dụ - Chọn Trạng Thái Đơn Hàng

```dart
final drOrder = CyberDataRow.fromMap({
  "is_pending": 1,
  "is_confirmed": 0,
  "is_shipping": 0,
  "is_delivered": 0,
  "is_cancelled": 0,
});

CyberRadioGroup(
  label: "Trạng thái đơn hàng",
  items: [
    CyberRadioItem(
      label: "Chờ xử lý",
      binding: drOrder.bind("is_pending"),
      icon: "schedule",
    ),
    CyberRadioItem(
      label: "Đã xác nhận",
      binding: drOrder.bind("is_confirmed"),
      icon: "check_circle",
    ),
    CyberRadioItem(
      label: "Đang giao",
      binding: drOrder.bind("is_shipping"),
      icon: "local_shipping",
    ),
    CyberRadioItem(
      label: "Đã giao",
      binding: drOrder.bind("is_delivered"),
      icon: "done_all",
    ),
    CyberRadioItem(
      label: "Đã hủy",
      binding: drOrder.bind("is_cancelled"),
      icon: "cancel",
    ),
  ],
  direction: Axis.vertical,
  spacing: 12.0,
  activeColor: Colors.green,
  onChanged: (index) {
    print("Selected index: $index");
  },
)
```

### Ví Dụ - Vertical Layout với Custom Style

```dart
CyberRadioGroup(
  label: "Chọn gói dịch vụ",
  direction: Axis.vertical,
  spacing: 16.0,
  items: [
    CyberRadioItem(
      label: "Gói Basic - 100.000đ/tháng",
      binding: drEdit.bind("is_basic"),
    ),
    CyberRadioItem(
      label: "Gói Standard - 200.000đ/tháng",
      binding: drEdit.bind("is_standard"),
    ),
    CyberRadioItem(
      label: "Gói Premium - 500.000đ/tháng",
      binding: drEdit.bind("is_premium"),
    ),
  ],
  labelStyle: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  ),
  selectedItemTextStyle: TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.blue,
  ),
  activeColor: Colors.blue,
)
```

### Thuộc Tính CyberRadioGroup

| Thuộc tính | Kiểu | Mô tả | Mặc định |
|-----------|------|-------|----------|
| `items` | List<CyberRadioItem> | Danh sách radio items (bắt buộc) | - |
| `label` | String? | Label hiển thị phía trên | null |
| `direction` | Axis | Hướng hiển thị (horizontal/vertical) | horizontal |
| `spacing` | double | Spacing giữa các items | 12.0 |
| `labelStyle` | TextStyle? | Style cho label chính | null |
| `itemTextStyle` | TextStyle? | Style cho text của item | null |
| `selectedItemTextStyle` | TextStyle? | Style cho item được chọn | null |
| `activeColor` | Color? | Màu của radio button | primaryColor |
| `onChanged` | ValueChanged<int>? | Callback trả về index được chọn | null |
| `isVisible` | dynamic | Visible binding | true |
| `isCheckEmpty` | dynamic | Hiển thị dấu * bắt buộc | false |
| `isShowLabel` | bool | Hiện/ẩn label | true |
| `enabled` | bool | Enable/disable toàn bộ group | true |

### Thuộc Tính CyberRadioItem

| Thuộc tính | Kiểu | Mô tả | Mặc định |
|-----------|------|-------|----------|
| `label` | String | Label hiển thị (bắt buộc) | - |
| `binding` | dynamic | Binding tới column (bắt buộc) | - |
| `icon` | String? | Icon code (Material Icons) | null |
| `enabled` | bool | Enable/disable item này | true |
| `selectedValue` | dynamic | Value khi được chọn | 1 |
| `unselectedValue` | dynamic | Value khi không được chọn | 0 |

### Tính Năng Nổi Bật

#### 1. Custom Selected/Unselected Values
```dart
CyberRadioItem(
  label: "Premium",
  binding: drEdit.bind("tier"),
  selectedValue: "PREMIUM",      // String thay vì 1
  unselectedValue: "NONE",       // String thay vì 0
)
```

#### 2. Icons Support
```dart
CyberRadioItem(
  label: "Thanh toán online",
  binding: drEdit.bind("is_online"),
  icon: "credit_card",           // Material Icons
)
```

#### 3. Individual Item Enable/Disable
```dart
CyberRadioItem(
  label: "VIP (Chưa đủ điều kiện)",
  binding: drEdit.bind("is_vip"),
  enabled: false,                // Disable item này
)
```

#### 4. Required Field Indicator
```dart
CyberRadioGroup(
  label: "Giới tính",
  isCheckEmpty: true,            // Hiển thị dấu * đỏ
  items: [...],
)
```

---

## So Sánh 2 Pattern

### CyberRadioBox (Traditional)

**Ưu điểm:**
- Đơn giản, dễ hiểu
- Tiết kiệm columns trong database
- Phù hợp cho các trường hợp chọn 1 trong nhiều options đơn giản

**Nhược điểm:**
- Cần parse/compare value khi check điều kiện
- Khó maintain khi số lượng options nhiều

**Khi nào dùng:**
- Chọn giới tính (Nam/Nữ/Khác)
- Chọn phương thức thanh toán
- Chọn loại tài khoản
- Bất kỳ trường hợp nào chỉ cần lưu 1 giá trị duy nhất

### CyberRadioGroup (Multi-Column)

**Ưu điểm:**
- Mỗi option có column riêng → dễ query
- Không cần parse value
- Dễ thêm logic phức tạp cho từng option
- Phù hợp với business logic phức tạp

**Nhược điểm:**
- Tốn nhiều columns trong database
- Cần define nhiều columns

**Khi nào dùng:**
- Loại phương tiện (is_car, is_motorcycle, is_bicycle)
- Trạng thái đơn hàng (is_pending, is_confirmed, is_shipping)
- Các trường hợp cần query riêng từng option
- Business logic phức tạp cho từng option

---

## Best Practices

### 1. Đặt Tên Group/Field Rõ Ràng

```dart
// ❌ Không tốt
CyberRadioBox(
  text: drEdit.bind("f1"),
  group: "g1",
  value: "v1",
)

// ✅ Tốt
CyberRadioBox(
  text: drEdit.bind("payment_method"),
  group: "payment_method_group",
  value: "cash",
)
```

### 2. Sử Dụng Const Cho Values

```dart
// Define constants
class PaymentMethods {
  static const cash = "cash";
  static const card = "card";
  static const transfer = "transfer";
}

// Sử dụng
CyberRadioBox(
  text: drEdit.bind("payment_method"),
  group: "payment_group",
  value: PaymentMethods.cash,
  label: "Tiền mặt",
)
```

### 3. Validation

```dart
// Kiểm tra đã chọn chưa
if (drEdit["gender"] == null || drEdit["gender"].toString().isEmpty) {
  Appinfo.toast("Vui lòng chọn giới tính");
  return;
}

// Hoặc dùng isCheckEmpty
CyberRadioGroup(
  label: "Giới tính",
  isCheckEmpty: true,  // Hiển thị dấu * bắt buộc
  items: [...],
)
```

### 4. Responsive Layout

```dart
// Tự động chuyển từ horizontal sang vertical trên màn hình nhỏ
CyberRadioGroup(
  label: "Options",
  direction: MediaQuery.of(context).size.width > 600 
    ? Axis.horizontal 
    : Axis.vertical,
  items: [...],
)
```

### 5. Accessibility

```dart
CyberRadioBox(
  text: drEdit.bind("option"),
  group: "option_group",
  value: "yes",
  label: "Có",  // Luôn cung cấp label rõ ràng
  size: 28,     // Đủ lớn để dễ tap (minimum 24)
)
```

---

## Migration Guide

### Từ CyberRadioBox sang CyberRadioGroup

```dart
// Before - CyberRadioBox
final drEdit = CyberDataRow.fromMap({
  "vehicle_type": "car",  // 1 field duy nhất
});

Column(
  children: [
    CyberRadioBox(
      text: drEdit.bind("vehicle_type"),
      group: "vehicle_group",
      value: "car",
      label: "Ô tô",
    ),
    CyberRadioBox(
      text: drEdit.bind("vehicle_type"),
      group: "vehicle_group",
      value: "motorcycle",
      label: "Xe máy",
    ),
  ],
)

// After - CyberRadioGroup
final drEdit = CyberDataRow.fromMap({
  "is_car": 1,         // Mỗi option có column riêng
  "is_motorcycle": 0,
  "is_bicycle": 0,
});

CyberRadioGroup(
  label: "Loại phương tiện",
  items: [
    CyberRadioItem(label: "Ô tô", binding: drEdit.bind("is_car")),
    CyberRadioItem(label: "Xe máy", binding: drEdit.bind("is_motorcycle")),
    CyberRadioItem(label: "Xe đạp", binding: drEdit.bind("is_bicycle")),
  ],
)
```

---

## Troubleshooting

### 1. Radio không update khi thay đổi data

**Nguyên nhân:** Binding không được setup đúng

**Giải pháp:**
```dart
// Đảm bảo sử dụng CyberBindingExpression
CyberRadioBox(
  text: drEdit.bind("field"),  // ✅ Đúng
  // text: drEdit["field"],    // ❌ Sai - không reactive
)
```

### 2. CyberRadioGroup không exclusive

**Nguyên nhân:** Các items không cùng được quản lý bởi CyberRadioGroup

**Giải pháp:**
```dart
// ✅ Tất cả items trong cùng 1 CyberRadioGroup
CyberRadioGroup(
  items: [
    CyberRadioItem(...),
    CyberRadioItem(...),
  ],
)

// ❌ Không nên tạo nhiều CyberRadioGroup riêng lẻ
```

### 3. Value bị sai type

**Nguyên nhân:** Type conversion không tự động

**Giải pháp:**
```dart
// Database field là int, đảm bảo value cũng là int
CyberRadioBox(
  text: drEdit.bind("status"),  // status là int field
  group: "status_group",
  value: 1,  // ✅ int
  // value: "1",  // ❌ String - có thể gây lỗi
)
```

### 4. onChanged không được gọi

**Nguyên nhân:** enabled = false hoặc item.enabled = false

**Giải pháp:**
```dart
CyberRadioBox(
  enabled: true,  // Đảm bảo enabled
  text: drEdit.bind("field"),
  onChanged: (value) {
    print("Changed: $value");
  },
)
```

---

## Kết Luận

CyberFramework cung cấp 2 pattern linh hoạt cho Radio Buttons:

- **CyberRadioBox**: Đơn giản, truyền thống, phù hợp cho most cases
- **CyberRadioGroup**: Multi-column, phức tạp hơn nhưng mạnh mẽ cho business logic

Chọn pattern phù hợp với yêu cầu của bạn và tuân thủ best practices để có code clean và maintainable!
