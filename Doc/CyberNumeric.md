# CyberNumeric - Widget Nhập Số với Binding

## Triết lý ERP/CyberFramework

CyberNumeric được thiết kế theo triết lý **Internal Controller + Binding**:

✅ **Không cần khai báo controller** - widget tự động quản lý state  
✅ **Hỗ trợ binding tự động** - two-way binding với CyberDataRow  
✅ **Đơn giản hoá code** - giống WPF/XAML binding pattern  

## Thay đổi chính

### Trước (OLD)
```dart
// ❌ Dùng thuộc tính "value"
CyberNumeric(
  value: dr.bind("so_luong"),  
  label: "Số lượng",
)
```

### Sau (NEW) 
```dart
// ✅ Dùng thuộc tính "text" 
CyberNumeric(
  text: dr.bind("so_luong"),  
  label: "Số lượng",
)
```

## Cách sử dụng

### 1. Binding với CyberDataRow (Phổ biến nhất)

```dart
final dr = CyberDataRow({
  'ma_kh': 'KH001',
  'so_luong': 100,
  'don_gia': 15000.50,
  'thanh_tien': 1500050.00,
});

// ✅ Binding đơn giản
CyberNumeric(
  text: dr.bind("so_luong"),
  label: "Số lượng",
  format: "#,##0",
  min: 0,
  max: 9999,
)

// ✅ Binding với format tiền tệ
CyberNumeric(
  text: dr.bind("don_gia"),
  label: "Đơn giá",
  format: "#,##0.00",
  onChanged: (value) {
    // Tự động tính thành tiền
    dr["thanh_tien"] = (dr["so_luong"] ?? 0) * (value ?? 0);
  },
)

// ✅ Binding với readonly
CyberNumeric(
  text: dr.bind("thanh_tien"),
  label: "Thành tiền",
  format: "#,##0.00",
  enabled: false, // readonly
)
```

### 2. Giá trị tĩnh (không binding)

```dart
// ✅ Giá trị cố định
CyberNumeric(
  text: 12345.67,
  label: "Giá trị mặc định",
  format: "#,##0.00",
)

// ✅ Null/rỗng
CyberNumeric(
  text: null,
  label: "Nhập số",
)
```

### 3. External Controller (Advanced - ít dùng)

```dart
// ⚠️ Chỉ dùng khi cần điều khiển từ code
final controller = CyberNumericController(
  value: 100,
  min: 0,
  max: 1000,
);

CyberNumeric(
  controller: controller,
  label: "Số lượng",
)

// Điều khiển từ code
controller.setValue(200);
controller.setEnabled(false);
controller.clear();
```

## Ưu điểm của cách mới

### 1. Không cần khai báo controller

**❌ Cách cũ (phức tạp)**
```dart
// Phải tạo controller thủ công
final soLuongController = CyberNumericController();
final donGiaController = CyberNumericController();
final thanhTienController = CyberNumericController();

// Phải sync data thủ công
soLuongController.setValue(dr["so_luong"]);
donGiaController.setValue(dr["don_gia"]);

// Phải dispose thủ công
@override
void dispose() {
  soLuongController.dispose();
  donGiaController.dispose();
  thanhTienController.dispose();
  super.dispose();
}
```

**✅ Cách mới (đơn giản)**
```dart
// Widget tự động quản lý tất cả
CyberNumeric(text: dr.bind("so_luong"), label: "Số lượng")
CyberNumeric(text: dr.bind("don_gia"), label: "Đơn giá")
CyberNumeric(text: dr.bind("thanh_tien"), label: "Thành tiền")

// Không cần dispose - widget tự xử lý
```

### 2. Two-way binding tự động

```dart
// ✅ Thay đổi UI → tự động update data
CyberNumeric(
  text: dr.bind("so_luong"),
  onChanged: (value) {
    print(dr["so_luong"]); // ← Đã được update tự động!
  },
)

// ✅ Thay đổi data → tự động update UI
dr["so_luong"] = 200; // ← UI tự động refresh!
```

### 3. Code ngắn gọn hơn

```dart
// ❌ Cách cũ: 10+ dòng
final controller = CyberNumericController(value: dr["ma_sp"]);
CyberNumeric(
  controller: controller,
  label: "Mã SP",
  onChanged: (v) => dr["ma_sp"] = v,
)
@override
void dispose() {
  controller.dispose();
  super.dispose();
}

// ✅ Cách mới: 1 dòng
CyberNumeric(text: dr.bind("ma_sp"), label: "Mã SP")
```

## Format Pattern

### Số nguyên
```dart
format: "#,##0"          // 1,234,567
format: "### ### ###"    // 1 234 567
```

### Số thập phân
```dart
format: "#,##0.##"       // 1,234.56 (tự động làm tròn)
format: "#,##0.00"       // 1,234.00 (luôn hiển thị 2 số)
format: "### ### ###.##" // 1 234 567.89
```

## Validation

```dart
CyberNumeric(
  text: dr.bind("tuoi"),
  label: "Tuổi",
  min: 0,     // Tối thiểu 0
  max: 150,   // Tối đa 150
  onChanged: (value) {
    // value đã được validate tự động
    print("Tuổi hợp lệ: $value");
  },
)
```

## Callbacks

```dart
CyberNumeric(
  text: dr.bind("so_luong"),
  
  // ✅ onChanged: gọi khi đang gõ
  onChanged: (num? value) {
    print("Đang gõ: $value");
  },
  
  // ✅ onLeaver: gọi khi blur (mất focus)
  onLeaver: (num? value) {
    print("Hoàn thành nhập: $value");
    // Thường dùng để tính toán hoặc validate phức tạp
  },
)
```

## Visibility Binding

```dart
final dr = CyberDataRow({
  'loai_khach': 'VIP',
  'chiet_khau': 0,
});

CyberNumeric(
  text: dr.bind("chiet_khau"),
  label: "Chiết khấu (%)",
  
  // ✅ Chỉ hiển thị khi là khách VIP
  isVisible: dr.bind("loai_khach") == "VIP",
)
```

## So sánh với các widget khác

| Widget | Thuộc tính binding | Kiểu dữ liệu |
|--------|-------------------|--------------|
| **CyberText** | `text: dr.bind("name")` | String? |
| **CyberNumeric** | `text: dr.bind("qty")` | num? |
| **CyberDate** | `value: dr.bind("date")` | DateTime? |
| **CyberCheckbox** | `value: dr.bind("flag")` | bool? |

## Best Practices

### ✅ DO - Nên làm

```dart
// 1. Dùng binding cho form nhập liệu
CyberNumeric(text: dr.bind("so_luong"), label: "Số lượng")

// 2. Dùng format phù hợp
CyberNumeric(text: dr.bind("don_gia"), format: "#,##0.00") // Tiền

// 3. Set min/max khi cần
CyberNumeric(text: dr.bind("tuoi"), min: 0, max: 150)

// 4. Dùng onLeaver cho tính toán
CyberNumeric(
  text: dr.bind("so_luong"),
  onLeaver: (_) => _calculateTotal(),
)
```

### ❌ DON'T - Không nên làm

```dart
// ❌ Không dùng cả text VÀ controller
CyberNumeric(
  text: dr.bind("so_luong"),
  controller: myController, // LỖI!
)

// ❌ Không tạo controller không cần thiết
final ctrl = CyberNumericController(); // Không cần!
CyberNumeric(text: dr.bind("so_luong")) // ← Đủ rồi

// ❌ Không sync thủ công
onChanged: (value) {
  dr["so_luong"] = value; // ← Không cần! Tự động rồi
}
```

## Migration Guide

Nếu bạn đang dùng code cũ với `value`, chỉ cần đổi thành `text`:

```dart
// ❌ Code cũ
CyberNumeric(value: dr.bind("so_luong"))

// ✅ Code mới  
CyberNumeric(text: dr.bind("so_luong"))
```

Tất cả logic khác giữ nguyên!

## Khi nào dùng External Controller?

Chỉ dùng `controller` khi:

1. **Cần điều khiển programmatically**
   ```dart
   // Reset về 0 khi click button
   _controller.setValue(0);
   ```

2. **Cần share state giữa nhiều widget**
   ```dart
   final sharedController = CyberNumericController();
   CyberNumeric(controller: sharedController)
   // ... ở widget khác cũng dùng sharedController
   ```

3. **Cần listen changes từ code**
   ```dart
   _controller.addListener(() {
     print("Value changed: ${_controller.value}");
   });
   ```

**Trong 95% trường hợp, chỉ cần dùng binding!**
