# CyberDate - Widget Chọn Ngày với Binding

## Triết lý ERP/CyberFramework

CyberDate được thiết kế theo triết lý **Internal Controller + Binding**:

✅ **Không cần khai báo controller** - widget tự động quản lý state  
✅ **Hỗ trợ binding tự động** - two-way binding với CyberDataRow  
✅ **Đơn giản hoá code** - giống WPF/XAML binding pattern  
✅ **Validation tự động** - min/max date, required field  

## Thuộc tính text

CyberDate sử dụng thuộc tính `text` (giống CyberNumeric) để nhất quán với triết lý binding:

```dart
// ✅ Dùng thuộc tính "text" 
CyberDate(
  text: dr.bind("ngay_sinh"),  
  label: "Ngày sinh",
)
```

## Cách sử dụng

### 1. Binding với CyberDataRow (Phổ biến nhất)

```dart
final dr = CyberDataRow({
  'ma_nv': 'NV001',
  'ten_nv': 'Nguyễn Văn A',
  'ngay_sinh': DateTime(1990, 5, 15),
  'ngay_vao_lam': DateTime(2020, 1, 10),
  'ngay_het_hop_dong': null,
});

// ✅ Binding đơn giản
CyberDate(
  text: dr.bind("ngay_sinh"),
  label: "Ngày sinh",
  format: "dd/MM/yyyy",
)

// ✅ Binding với min/max date
CyberDate(
  text: dr.bind("ngay_vao_lam"),
  label: "Ngày vào làm",
  format: "dd/MM/yyyy",
  minDate: DateTime(2000, 1, 1),
  maxDate: DateTime.now(),
  onChanged: (date) {
    // Tự động set ngày hết hợp đồng = ngày vào làm + 2 năm
    if (date != null) {
      dr["ngay_het_hop_dong"] = DateTime(
        date.year + 2,
        date.month,
        date.day,
      );
    }
  },
)

// ✅ Binding với required field
CyberDate(
  text: dr.bind("ngay_het_hop_dong"),
  label: "Ngày hết hợp đồng",
  format: "dd/MM/yyyy",
  isCheckEmpty: true, // Hiển thị dấu *
  validator: (date) {
    if (date == null) return "Vui lòng chọn ngày hết hợp đồng";
    
    final ngayVaoLam = dr["ngay_vao_lam"] as DateTime?;
    if (ngayVaoLam != null && date.isBefore(ngayVaoLam)) {
      return "Ngày hết hợp đồng phải sau ngày vào làm";
    }
    
    return null; // Valid
  },
)
```

### 2. Giá trị tĩnh (không binding)

```dart
// ✅ Giá trị cố định
CyberDate(
  text: DateTime(2024, 1, 1),
  label: "Ngày bắt đầu",
  format: "dd/MM/yyyy",
)

// ✅ Giá trị hiện tại
CyberDate(
  text: DateTime.now(),
  label: "Ngày hiện tại",
  enabled: false, // readonly
)

// ✅ Null/rỗng
CyberDate(
  text: null,
  label: "Chọn ngày",
)
```

### 3. External Controller (Advanced - ít dùng)

```dart
// ⚠️ Chỉ dùng khi cần điều khiển từ code
final fromDateController = CyberDateController();
final toDateController = CyberDateController();

CyberDate(
  controller: fromDateController,
  label: "Từ ngày",
)

CyberDate(
  controller: toDateController,
  label: "Đến ngày",
)

// Điều khiển từ code
void _setThisMonth() {
  fromDateController.setStartOfMonth();
  toDateController.setEndOfMonth();
}

void _setThisYear() {
  fromDateController.setStartOfYear();
  toDateController.setEndOfYear();
}

void _clear() {
  fromDateController.clear();
  toDateController.clear();
}
```

## Ưu điểm của cách mới

### 1. Không cần khai báo controller

**❌ Cách cũ (phức tạp)**
```dart
// Phải tạo controller thủ công
final ngaySinhController = CyberDateController();
final ngayVaoLamController = CyberDateController();

// Phải sync data thủ công
ngaySinhController.value = dr["ngay_sinh"];
ngayVaoLamController.value = dr["ngay_vao_lam"];

// Phải dispose thủ công
@override
void dispose() {
  ngaySinhController.dispose();
  ngayVaoLamController.dispose();
  super.dispose();
}
```

**✅ Cách mới (đơn giản)**
```dart
// Widget tự động quản lý tất cả
CyberDate(text: dr.bind("ngay_sinh"), label: "Ngày sinh")
CyberDate(text: dr.bind("ngay_vao_lam"), label: "Ngày vào làm")

// Không cần dispose - widget tự xử lý
```

### 2. Two-way binding tự động

```dart
// ✅ Thay đổi UI → tự động update data
CyberDate(
  text: dr.bind("ngay_sinh"),
  onChanged: (date) {
    print(dr["ngay_sinh"]); // ← Đã được update tự động!
  },
)

// ✅ Thay đổi data → tự động update UI
dr["ngay_sinh"] = DateTime(1995, 3, 20); // ← UI tự động refresh!
```

### 3. Code ngắn gọn hơn 90%

```dart
// ❌ Cách cũ: 15+ dòng
final controller = CyberDateController();
controller.value = dr["ngay_sinh"];
CyberDate(
  controller: controller,
  label: "Ngày sinh",
  onChanged: (v) => dr["ngay_sinh"] = v,
)
@override
void dispose() {
  controller.dispose();
  super.dispose();
}

// ✅ Cách mới: 1 dòng
CyberDate(text: dr.bind("ngay_sinh"), label: "Ngày sinh")
```

## Format Pattern

### Định dạng ngày phổ biến

```dart
format: "dd/MM/yyyy"       // 15/05/1990
format: "dd-MM-yyyy"       // 15-05-1990
format: "yyyy-MM-dd"       // 1990-05-15 (ISO format)
format: "dd/MM/yy"         // 15/05/90
format: "dd MMM yyyy"      // 15 May 1990
format: "dd MMMM yyyy"     // 15 Tháng 5 1990
format: "EEEE, dd/MM/yyyy" // Thứ Hai, 15/05/1990
```

### Custom formatter

```dart
// Sử dụng DateFormat từ intl package
import 'package:intl/intl.dart';

final customFormatter = DateFormat('dd/MM/yyyy', 'vi_VN');

CyberDate(
  text: dr.bind("ngay_sinh"),
  formatter: customFormatter,
)
```

## Validation

### 1. Built-in validation

```dart
CyberDate(
  text: dr.bind("ngay_sinh"),
  label: "Ngày sinh",
  
  // Required field
  isCheckEmpty: true,
  
  // Date range
  minDate: DateTime(1900, 1, 1),
  maxDate: DateTime.now(),
)
```

### 2. Custom validation

```dart
CyberDate(
  text: dr.bind("ngay_het_hop_dong"),
  label: "Ngày hết hợp đồng",
  validator: (date) {
    if (date == null) {
      return "Vui lòng chọn ngày";
    }
    
    final ngayVaoLam = dr["ngay_vao_lam"] as DateTime?;
    if (ngayVaoLam == null) {
      return "Vui lòng chọn ngày vào làm trước";
    }
    
    if (date.isBefore(ngayVaoLam)) {
      return "Ngày hết hợp đồng phải sau ngày vào làm";
    }
    
    final duration = date.difference(ngayVaoLam).inDays;
    if (duration < 365) {
      return "Hợp đồng tối thiểu 1 năm";
    }
    
    return null; // Valid
  },
)
```

### 3. External error text

```dart
String? _errorMessage;

CyberDate(
  text: dr.bind("ngay_sinh"),
  errorText: _errorMessage,
)

// Set error từ code
void _validateAge() {
  final ngaySinh = dr["ngay_sinh"] as DateTime?;
  if (ngaySinh != null) {
    final age = DateTime.now().difference(ngaySinh).inDays ~/ 365;
    if (age < 18) {
      setState(() {
        _errorMessage = "Phải đủ 18 tuổi";
      });
      return;
    }
  }
  
  setState(() {
    _errorMessage = null;
  });
}
```

## Callbacks

```dart
CyberDate(
  text: dr.bind("ngay_vao_lam"),
  
  // ✅ onChanged: gọi khi chọn ngày mới
  onChanged: (DateTime? date) {
    print("Ngày được chọn: $date");
    
    // Tự động tính ngày hết hợp đồng
    if (date != null) {
      dr["ngay_het_hop_dong"] = DateTime(
        date.year + 2,
        date.month,
        date.day,
      );
    }
  },
  
  // ✅ onLeaver: gọi khi đóng date picker
  onLeaver: (dynamic date) {
    print("Hoàn thành chọn ngày: $date");
    _validateContractDuration();
  },
)
```

## Visibility Binding

```dart
final dr = CyberDataRow({
  'loai_hop_dong': 'CO_DINH', // CO_DINH, THU_VIEC
  'ngay_vao_lam': DateTime.now(),
  'ngay_het_hop_dong': null,
});

CyberDate(
  text: dr.bind("ngay_het_hop_dong"),
  label: "Ngày hết hợp đồng",
  
  // ✅ Chỉ hiển thị với hợp đồng có định
  isVisible: dr["loai_hop_dong"] == "CO_DINH",
)
```

## Controller Methods (Advanced)

Khi dùng external controller, có các methods hữu ích:

```dart
final controller = CyberDateController();

// Set giá trị
controller.value = DateTime(2024, 1, 1);
controller.setSilently(DateTime(2024, 1, 1)); // Không trigger listener

// Quick setters
controller.setToday();              // Hôm nay
controller.setStartOfMonth();       // Đầu tháng
controller.setEndOfMonth();         // Cuối tháng
controller.setStartOfYear();        // Đầu năm
controller.setEndOfYear();          // Cuối năm
controller.setDate(2024, 6, 15);    // Custom date

// Date arithmetic
controller.addDays(7);              // Thêm 7 ngày
controller.subtractDays(3);         // Trừ 3 ngày
controller.addMonths(2);            // Thêm 2 tháng
controller.addYears(1);             // Thêm 1 năm

// Validation helpers
controller.isEmpty;                 // Kiểm tra null
controller.isNotEmpty;              // Kiểm tra not null
controller.isBefore(DateTime.now());
controller.isAfter(DateTime.now());

// Clear
controller.clear();                 // Set về null
```

## Best Practices

### ✅ DO - Nên làm

```dart
// 1. Dùng binding cho form nhập liệu
CyberDate(text: dr.bind("ngay_sinh"), label: "Ngày sinh")

// 2. Set min/max date hợp lý
CyberDate(
  text: dr.bind("ngay_sinh"),
  minDate: DateTime(1900, 1, 1),
  maxDate: DateTime.now(),
)

// 3. Dùng validator cho logic phức tạp
CyberDate(
  text: dr.bind("ngay_het_hd"),
  validator: (date) => _validateContractEnd(date),
)

// 4. Dùng onChanged cho tính toán liên quan
CyberDate(
  text: dr.bind("ngay_vao_lam"),
  onChanged: (_) => _calculateContractEnd(),
)
```

### ❌ DON'T - Không nên làm

```dart
// ❌ Không dùng cả text VÀ controller
CyberDate(
  text: dr.bind("ngay_sinh"),
  controller: myController, // LỖI!
)

// ❌ Không tạo controller không cần thiết
final ctrl = CyberDateController(); // Không cần!
CyberDate(text: dr.bind("ngay_sinh")) // ← Đủ rồi

// ❌ Không sync thủ công
onChanged: (date) {
  dr["ngay_sinh"] = date; // ← Không cần! Tự động rồi
}

// ❌ Không dùng format không phù hợp
format: "yyyy-dd-MM" // ← Sai! Ngày và tháng đảo
```

## Common Use Cases

### 1. Date Range Selector

```dart
final drFilter = CyberDataRow({
  'tu_ngay': DateTime.now().subtract(Duration(days: 30)),
  'den_ngay': DateTime.now(),
});

// Từ ngày
CyberDate(
  text: drFilter.bind("tu_ngay"),
  label: "Từ ngày",
  maxDate: drFilter["den_ngay"], // Không được sau "đến ngày"
  onChanged: (_) => setState(() {}),
)

// Đến ngày  
CyberDate(
  text: drFilter.bind("den_ngay"),
  label: "Đến ngày",
  minDate: drFilter["tu_ngay"], // Không được trước "từ ngày"
  maxDate: DateTime.now(),
)
```

### 2. Age Calculation

```dart
CyberDate(
  text: dr.bind("ngay_sinh"),
  label: "Ngày sinh",
  maxDate: DateTime.now(),
  onChanged: (date) {
    if (date != null) {
      final age = DateTime.now().difference(date).inDays ~/ 365;
      dr["tuoi"] = age;
    }
  },
)
```

### 3. Contract Duration

```dart
CyberDate(
  text: dr.bind("ngay_vao_lam"),
  label: "Ngày vào làm",
  onChanged: (date) {
    if (date != null) {
      // Hợp đồng 2 năm
      dr["ngay_het_hop_dong"] = DateTime(
        date.year + 2,
        date.month,
        date.day,
      );
    }
  },
)

CyberDate(
  text: dr.bind("ngay_het_hop_dong"),
  label: "Ngày hết hợp đồng",
  enabled: false, // Auto-calculated
)
```

### 4. Quick Date Buttons

```dart
final controller = CyberDateController();

Row(
  children: [
    ElevatedButton(
      onPressed: () => controller.setToday(),
      child: Text("Hôm nay"),
    ),
    ElevatedButton(
      onPressed: () => controller.setStartOfMonth(),
      child: Text("Đầu tháng"),
    ),
    ElevatedButton(
      onPressed: () => controller.setEndOfMonth(),
      child: Text("Cuối tháng"),
    ),
  ],
)

CyberDate(
  controller: controller,
  label: "Ngày chọn",
)
```

## Migration Guide

Nếu bạn đang dùng code cũ, thay đổi rất đơn giản:

### Từ initialValue/value

```dart
// ❌ Code cũ
CyberDate(
  initialValue: dr["ngay_sinh"],
  onChanged: (date) => dr["ngay_sinh"] = date,
)

// ✅ Code mới  
CyberDate(text: dr.bind("ngay_sinh"))
```

### Từ controller

```dart
// ❌ Code cũ - cần controller
final controller = CyberDateController();
controller.value = dr["ngay_sinh"];

CyberDate(
  controller: controller,
  onChanged: (date) => dr["ngay_sinh"] = date,
)

// Phải dispose
@override
void dispose() {
  controller.dispose();
  super.dispose();
}

// ✅ Code mới - không cần controller
CyberDate(text: dr.bind("ngay_sinh"))
```

## Khi nào dùng External Controller?

Chỉ dùng `controller` khi:

1. **Cần điều khiển programmatically**
   ```dart
   // Quick date selection
   _controller.setToday();
   _controller.setStartOfMonth();
   ```

2. **Cần date arithmetic**
   ```dart
   _controller.addDays(7);
   _controller.addMonths(1);
   ```

3. **Cần share state giữa nhiều widget**
   ```dart
   final sharedController = CyberDateController();
   CyberDate(controller: sharedController) // Widget 1
   CyberDate(controller: sharedController) // Widget 2
   ```

**Trong 95% trường hợp, chỉ cần dùng binding!**

## So sánh với các widget khác

| Widget | Thuộc tính binding | Kiểu dữ liệu | Format |
|--------|-------------------|--------------|--------|
| **CyberText** | `text: dr.bind("name")` | String? | N/A |
| **CyberNumeric** | `text: dr.bind("qty")` | num? | `#,##0.##` |
| **CyberDate** | `text: dr.bind("date")` | DateTime? | `dd/MM/yyyy` |
| **CyberCheckbox** | `value: dr.bind("flag")` | bool? | N/A |

## Tính năng đặc biệt

### 1. iOS-style Date Picker

CyberDate sử dụng iOS-style wheel picker thay vì Material DatePicker mặc định:

- Giao diện đẹp, mượt mà
- Dễ sử dụng hơn trên mobile
- Tùy chỉnh ngôn ngữ (Vietnamese)
- Hỗ trợ min/max date tự động

### 2. Smart Validation

- Auto-validation theo min/max date
- Custom validator support
- Error display tích hợp
- Required field marking (*)

### 3. Flexible Formatting

- Support DateFormat từ intl package
- Multiple format patterns
- Vietnamese month names
- Custom formatters

Tất cả đều **tự động hoạt động** với binding pattern!
