# CyberDate - Date Picker với Data Binding

## Mục Lục
1. [Giới Thiệu](#giới-thiệu)
2. [CyberDate Widget](#cyberdate-widget)
3. [CyberDateController](#cyberdatecontroller)
4. [Ví Dụ Sử Dụng](#ví-dụ-sử-dụng)
5. [Features](#features)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

---

## Giới Thiệu

`CyberDate` là một date picker widget theo ERP style với **Internal Controller** và **Data Binding** hai chiều. Widget này cung cấp iOS-style picker với khả năng format ngày tháng linh hoạt và null value handling.

### Đặc Điểm Chính

- ✅ **Internal Controller**: Tự động quản lý state, không cần khai báo controller
- ✅ **Two-Way Binding**: Tự động sync với CyberDataRow
- ✅ **Null Value Handling**: Hỗ trợ null value (mặc định: 01/01/1900)
- ✅ **Custom Format**: Hỗ trợ nhiều format ngày tháng
- ✅ **iOS-Style Picker**: Bottom sheet với wheel picker
- ✅ **Date Range**: Min/max date validation
- ✅ **Clear Button**: Xóa giá trị về null value
- ✅ **Validation**: Built-in và custom validation

### Import

```dart
import 'package:cyberframework/cyberframework.dart';
import 'package:intl/intl.dart';
```

---

## CyberDate Widget

### Constructor

```dart
const CyberDate({
  super.key,
  this.text,
  this.controller,
  this.label,
  this.hint,
  this.format = "dd/MM/yyyy",
  this.prefixIcon,
  this.borderSize = 1,
  this.borderRadius,
  this.enabled = true,
  this.style,
  this.decoration,
  this.onChanged,
  this.onLeaver,
  this.minDate,
  this.maxDate,
  this.isShowLabel = true,
  this.backgroundColor,
  this.borderColor = Colors.transparent,
  this.focusColor,
  this.labelStyle,
  this.isVisible = true,
  this.isCheckEmpty = false,
  this.formatter,
  this.validator,
  this.errorText,
  this.nullValue,
  this.showClearButton = false,
})
```

### Properties

#### Data Binding

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `text` | `dynamic` | Binding hoặc static value | null |
| `controller` | `CyberDateController?` | External controller (optional) | null |

⚠️ **KHÔNG dùng cả text VÀ controller cùng lúc**

#### Display

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `label` | `String?` | Label hiển thị phía trên | null |
| `hint` | `String?` | Hint text khi chưa chọn | "Chọn ngày" |
| `format` | `String` | Date format pattern | "dd/MM/yyyy" |
| `formatter` | `DateFormat?` | Custom DateFormat object | null |
| `prefixIcon` | `String?` | Icon code bên trái | null |

#### Validation & Constraints

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `minDate` | `DateTime?` | Ngày tối thiểu | 100 năm trước |
| `maxDate` | `DateTime?` | Ngày tối đa | 100 năm sau |
| `validator` | `String? Function(DateTime?)?` | Custom validator | null |
| `errorText` | `String?` | Error message hiển thị | null |
| `isCheckEmpty` | `dynamic` | Hiển thị dấu * bắt buộc | false |

#### Null Value

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `nullValue` | `DateTime?` | Giá trị đại diện cho null | DateTime(1900, 1, 1) |
| `showClearButton` | `bool` | Hiển thị nút xóa | false |

**Null Value Concept:**
- Khi date = nullValue → hiển thị hint text
- Clear button → set về nullValue
- Default: `DateTime(1900, 1, 1)`

#### Callbacks

| Property | Type | Mô Tả |
|----------|------|-------|
| `onChanged` | `ValueChanged<DateTime?>?` | Khi giá trị thay đổi |
| `onLeaver` | `Function(dynamic)?` | Khi rời khỏi control |

#### Styling

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `style` | `TextStyle?` | Style cho text | null |
| `labelStyle` | `TextStyle?` | Style cho label | null |
| `decoration` | `InputDecoration?` | Custom decoration | null |
| `backgroundColor` | `Color?` | Màu nền | Color(0xFFF5F5F5) |
| `borderColor` | `Color?` | Màu border | Colors.transparent |
| `focusColor` | `Color?` | Màu khi focus | null |
| `borderSize` | `int?` | Độ dày border (px) | 1 |
| `borderRadius` | `int?` | Bo góc (px) | 4 |
| `enabled` | `bool` | Enable/disable | true |
| `isShowLabel` | `bool` | Hiển thị label | true |
| `isVisible` | `dynamic` | Hiển thị/ẩn (có thể binding) | true |

---

## CyberDateController

**NOTE**: Controller là **OPTIONAL**. Không cần khai báo trong hầu hết trường hợp.

### Properties & Methods

```dart
final controller = CyberDateController();

// Properties
DateTime? value = controller.value;
bool isEmpty = controller.isEmpty;
bool isNotEmpty = controller.isNotEmpty;

// Basic operations
controller.value = DateTime.now();
controller.clear();

// Quick setters
controller.setToday();
controller.setStartOfMonth();
controller.setEndOfMonth();
controller.setStartOfYear();
controller.setEndOfYear();
controller.setDate(2024, 12, 31);

// Date arithmetic
controller.addDays(7);
controller.subtractDays(3);
controller.addMonths(1);
controller.addYears(1);

// Comparisons
bool before = controller.isBefore(DateTime.now());
bool after = controller.isAfter(DateTime.now());

// Silent update (không notify)
controller.setSilently(DateTime.now());
```

---

## Ví Dụ Sử Dụng

### 1. Sử Dụng Cơ Bản (Recommended)

Simple binding với data row.

```dart
class EmployeeForm extends StatefulWidget {
  @override
  State<EmployeeForm> createState() => _EmployeeFormState();
}

class _EmployeeFormState extends State<EmployeeForm> {
  final drEmployee = CyberDataRow();

  @override
  void initState() {
    super.initState();
    
    // Initialize dates
    drEmployee['ngay_sinh'] = DateTime(1990, 1, 1);
    drEmployee['ngay_vao_lam'] = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberDate(
          text: drEmployee.bind('ngay_sinh'),
          label: 'Ngày sinh',
          hint: 'Chọn ngày sinh',
        ),
        
        SizedBox(height: 16),
        
        CyberDate(
          text: drEmployee.bind('ngay_vao_lam'),
          label: 'Ngày vào làm',
          maxDate: DateTime.now(), // Không cho chọn tương lai
        ),
      ],
    );
  }
}
```

### 2. Custom Format

Nhiều định dạng ngày tháng.

```dart
// dd/MM/yyyy - Mặc định
CyberDate(
  text: drOrder.bind('order_date'),
  label: 'Ngày đặt hàng',
  format: 'dd/MM/yyyy',
)

// yyyy-MM-dd - ISO format
CyberDate(
  text: drEvent.bind('event_date'),
  label: 'Ngày sự kiện',
  format: 'yyyy-MM-dd',
)

// dd MMM yyyy - With month name
CyberDate(
  text: drInvoice.bind('invoice_date'),
  label: 'Ngày hóa đơn',
  format: 'dd MMM yyyy', // 01 Jan 2024
)

// Custom formatter
CyberDate(
  text: drReport.bind('report_date'),
  label: 'Ngày báo cáo',
  formatter: DateFormat('EEEE, dd/MM/yyyy', 'vi_VN'), // Thứ Hai, 01/01/2024
)
```

### 3. Date Range Validation

Giới hạn khoảng ngày.

```dart
class BookingForm extends StatefulWidget {
  @override
  State<BookingForm> createState() => _BookingFormState();
}

class _BookingFormState extends State<BookingForm> {
  final drBooking = CyberDataRow();

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final tomorrow = today.add(Duration(days: 1));
    final maxDate = today.add(Duration(days: 90));

    return Column(
      children: [
        // Check-in: Từ ngày mai đến 90 ngày sau
        CyberDate(
          text: drBooking.bind('check_in'),
          label: 'Ngày nhận phòng',
          minDate: tomorrow,
          maxDate: maxDate,
        ),
        
        SizedBox(height: 16),
        
        // Check-out: Sau check-in
        ListenableBuilder(
          listenable: drBooking,
          builder: (context, _) {
            final checkIn = drBooking['check_in'] as DateTime?;
            final minCheckOut = checkIn?.add(Duration(days: 1)) ?? tomorrow;
            
            return CyberDate(
              text: drBooking.bind('check_out'),
              label: 'Ngày trả phòng',
              minDate: minCheckOut,
              maxDate: maxDate,
            );
          },
        ),
      ],
    );
  }
}
```

### 4. Null Value & Clear Button

Xử lý giá trị null.

```dart
class ContractForm extends StatefulWidget {
  @override
  State<ContractForm> createState() => _ContractFormState();
}

class _ContractFormState extends State<ContractForm> {
  final drContract = CyberDataRow();

  @override
  void initState() {
    super.initState();
    
    // Ngày bắt đầu bắt buộc
    drContract['start_date'] = DateTime.now();
    
    // Ngày kết thúc không bắt buộc (null)
    drContract['end_date'] = DateTime(1900, 1, 1); // nullValue
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberDate(
          text: drContract.bind('start_date'),
          label: 'Ngày bắt đầu',
          isCheckEmpty: true, // Required
        ),
        
        SizedBox(height: 16),
        
        // Có thể null - hiển thị nút Clear
        CyberDate(
          text: drContract.bind('end_date'),
          label: 'Ngày kết thúc',
          hint: 'Không xác định',
          showClearButton: true, // Hiển thị nút xóa
          nullValue: DateTime(1900, 1, 1), // Custom null value
        ),
      ],
    );
  }
}
```

### 5. Custom Validation

Validator tùy chỉnh.

```dart
class EventForm extends StatefulWidget {
  @override
  State<EventForm> createState() => _EventFormState();
}

class _EventFormState extends State<EventForm> {
  final drEvent = CyberDataRow();

  String? validateEventDate(DateTime? date) {
    if (date == null) {
      return 'Vui lòng chọn ngày';
    }
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Không cho chọn ngày quá khứ
    if (date.isBefore(today)) {
      return 'Ngày sự kiện không thể là quá khứ';
    }
    
    // Không cho chọn cuối tuần
    if (date.weekday == DateTime.saturday || 
        date.weekday == DateTime.sunday) {
      return 'Sự kiện không thể tổ chức vào cuối tuần';
    }
    
    return null; // Valid
  }

  @override
  Widget build(BuildContext context) {
    return CyberDate(
      text: drEvent.bind('event_date'),
      label: 'Ngày tổ chức sự kiện',
      validator: validateEventDate,
    );
  }
}
```

### 6. Với Controller (Advanced)

Programmatic control.

```dart
class ReportForm extends StatefulWidget {
  @override
  State<ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<ReportForm> {
  final dateController = CyberDateController();

  @override
  void initState() {
    super.initState();
    
    // Set initial date
    dateController.setToday();
    
    // Listen to changes
    dateController.addListener(() {
      print('Date changed: ${dateController.value}');
    });
  }

  @override
  void dispose() {
    dateController.dispose();
    super.dispose();
  }

  void setToday() {
    dateController.setToday();
  }

  void setStartOfMonth() {
    dateController.setStartOfMonth();
  }

  void setEndOfMonth() {
    dateController.setEndOfMonth();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberDate(
          controller: dateController,
          label: 'Ngày báo cáo',
        ),
        
        SizedBox(height: 16),
        
        // Quick actions
        Wrap(
          spacing: 8,
          children: [
            ElevatedButton(
              onPressed: setToday,
              child: Text('Hôm nay'),
            ),
            ElevatedButton(
              onPressed: setStartOfMonth,
              child: Text('Đầu tháng'),
            ),
            ElevatedButton(
              onPressed: setEndOfMonth,
              child: Text('Cuối tháng'),
            ),
          ],
        ),
      ],
    );
  }
}
```

### 7. Date Range Picker Pattern

Chọn khoảng ngày.

```dart
class DateRangePicker extends StatefulWidget {
  @override
  State<DateRangePicker> createState() => _DateRangePickerState();
}

class _DateRangePickerState extends State<DateRangePicker> {
  final drRange = CyberDataRow();

  @override
  void initState() {
    super.initState();
    
    // Default: This month
    final now = DateTime.now();
    drRange['from_date'] = DateTime(now.year, now.month, 1);
    drRange['to_date'] = DateTime(now.year, now.month + 1, 0);
  }

  void setThisWeek() {
    final now = DateTime.now();
    final weekday = now.weekday;
    final monday = now.subtract(Duration(days: weekday - 1));
    final sunday = monday.add(Duration(days: 6));
    
    drRange['from_date'] = DateTime(monday.year, monday.month, monday.day);
    drRange['to_date'] = DateTime(sunday.year, sunday.month, sunday.day);
  }

  void setThisMonth() {
    final now = DateTime.now();
    drRange['from_date'] = DateTime(now.year, now.month, 1);
    drRange['to_date'] = DateTime(now.year, now.month + 1, 0);
  }

  void setThisYear() {
    final now = DateTime.now();
    drRange['from_date'] = DateTime(now.year, 1, 1);
    drRange['to_date'] = DateTime(now.year, 12, 31);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberDate(
          text: drRange.bind('from_date'),
          label: 'Từ ngày',
        ),
        
        SizedBox(height: 16),
        
        ListenableBuilder(
          listenable: drRange,
          builder: (context, _) {
            final fromDate = drRange['from_date'] as DateTime?;
            
            return CyberDate(
              text: drRange.bind('to_date'),
              label: 'Đến ngày',
              minDate: fromDate?.add(Duration(days: 1)),
            );
          },
        ),
        
        SizedBox(height: 16),
        
        Wrap(
          spacing: 8,
          children: [
            ElevatedButton(
              onPressed: setThisWeek,
              child: Text('Tuần này'),
            ),
            ElevatedButton(
              onPressed: setThisMonth,
              child: Text('Tháng này'),
            ),
            ElevatedButton(
              onPressed: setThisYear,
              child: Text('Năm nay'),
            ),
          ],
        ),
      ],
    );
  }
}
```

### 8. Birthday Picker

Chọn ngày sinh với validation.

```dart
CyberDate(
  text: drUser.bind('birthday'),
  label: 'Ngày sinh',
  format: 'dd/MM/yyyy',
  minDate: DateTime(1900, 1, 1),
  maxDate: DateTime.now().subtract(Duration(days: 365 * 18)), // >= 18 tuổi
  validator: (date) {
    if (date == null) return 'Vui lòng chọn ngày sinh';
    
    final now = DateTime.now();
    final age = now.year - date.year;
    
    if (age < 18) {
      return 'Phải đủ 18 tuổi';
    }
    
    if (age > 100) {
      return 'Ngày sinh không hợp lệ';
    }
    
    return null;
  },
)
```

### 9. Expiry Date Picker

Chọn ngày hết hạn.

```dart
class ProductForm extends StatefulWidget {
  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final drProduct = CyberDataRow();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberDate(
          text: drProduct.bind('manufacture_date'),
          label: 'Ngày sản xuất',
          maxDate: DateTime.now(),
        ),
        
        SizedBox(height: 16),
        
        ListenableBuilder(
          listenable: drProduct,
          builder: (context, _) {
            final mfgDate = drProduct['manufacture_date'] as DateTime?;
            
            return CyberDate(
              text: drProduct.bind('expiry_date'),
              label: 'Ngày hết hạn',
              minDate: mfgDate?.add(Duration(days: 1)),
              validator: (date) {
                if (date == null) return null;
                if (mfgDate == null) return 'Chọn ngày sản xuất trước';
                
                final diff = date.difference(mfgDate).inDays;
                if (diff < 7) {
                  return 'Hạn sử dụng tối thiểu 7 ngày';
                }
                
                return null;
              },
            );
          },
        ),
      ],
    );
  }
}
```

### 10. Multiple Date Fields

Form với nhiều trường ngày.

```dart
class ProjectForm extends StatefulWidget {
  @override
  State<ProjectForm> createState() => _ProjectFormState();
}

class _ProjectFormState extends State<ProjectForm> {
  final drProject = CyberDataRow();

  @override
  void initState() {
    super.initState();
    
    final today = DateTime.now();
    drProject['start_date'] = today;
    drProject['planned_end_date'] = today.add(Duration(days: 30));
    drProject['actual_end_date'] = DateTime(1900, 1, 1); // null
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberDate(
          text: drProject.bind('start_date'),
          label: 'Ngày bắt đầu',
          isCheckEmpty: true,
        ),
        
        SizedBox(height: 16),
        
        CyberDate(
          text: drProject.bind('planned_end_date'),
          label: 'Ngày dự kiến hoàn thành',
          isCheckEmpty: true,
        ),
        
        SizedBox(height: 16),
        
        CyberDate(
          text: drProject.bind('actual_end_date'),
          label: 'Ngày hoàn thành thực tế',
          hint: 'Chưa hoàn thành',
          showClearButton: true,
          nullValue: DateTime(1900, 1, 1),
        ),
      ],
    );
  }
}
```

---

## Features

### 1. Internal Controller

Widget tự động quản lý state.

```dart
// ✅ GOOD: Simple binding
CyberDate(
  text: drOrder.bind('order_date'),
  label: 'Ngày đặt hàng',
)
```

### 2. Two-Way Binding

Tự động sync UI ↔ Data Row.

```dart
// Change in UI → Update data row
// Change in data row → Update UI

drOrder['order_date'] = DateTime.now(); // UI updates
// User selects date → drOrder['order_date'] updates
```

### 3. Null Value Handling

Giá trị đại diện cho null.

```dart
// Default null value: 01/01/1900
final nullVal = CyberDate.defaultNullValue;

// Custom null value
CyberDate(
  nullValue: DateTime(2000, 1, 1),
  showClearButton: true,
)
```

### 4. iOS-Style Picker

Bottom sheet với wheel scrolling.

- Day - Month - Year wheels
- Smooth scrolling
- Visual feedback
- "Hủy" / "Xong" buttons

### 5. Date Format

Linh hoạt với nhiều format.

```dart
'dd/MM/yyyy'      // 01/01/2024
'yyyy-MM-dd'      // 2024-01-01
'dd MMM yyyy'     // 01 Jan 2024
'EEEE, dd/MM/yy'  // Monday, 01/01/24
```

### 6. Validation

Built-in và custom validation.

```dart
// Built-in: min/max date
CyberDate(
  minDate: DateTime(2020, 1, 1),
  maxDate: DateTime(2030, 12, 31),
)

// Custom validator
CyberDate(
  validator: (date) {
    if (date == null) return 'Required';
    // Custom logic...
    return null;
  },
)
```

### 7. Clear Button

Xóa về null value.

```dart
CyberDate(
  showClearButton: true,
  // Shows clear icon when has value
)
```

---

## Best Practices

### 1. Sử Dụng Binding (Recommended)

```dart
// ✅ GOOD
CyberDate(
  text: drEmployee.bind('ngay_sinh'),
  label: 'Ngày sinh',
)

// ❌ BAD: Manual state
DateTime? selectedDate;
CyberDate(
  text: selectedDate,
  onChanged: (date) {
    setState(() {
      selectedDate = date;
      drEmployee['ngay_sinh'] = date;
    });
  },
)
```

### 2. Format Selection

```dart
// ✅ GOOD: dd/MM/yyyy cho Việt Nam
CyberDate(
  format: 'dd/MM/yyyy',
  ...
)

// ✅ GOOD: yyyy-MM-dd cho database
CyberDate(
  format: 'yyyy-MM-dd',
  ...
)
```

### 3. Date Range

```dart
// ✅ GOOD: Rõ ràng, có ý nghĩa
CyberDate(
  minDate: DateTime(1900, 1, 1),
  maxDate: DateTime.now(),
  ...
)

// ❌ BAD: Quá rộng, không hợp lý
CyberDate(
  minDate: DateTime(1, 1, 1),
  maxDate: DateTime(9999, 12, 31),
  ...
)
```

### 4. Validation Messages

```dart
// ✅ GOOD: Clear, helpful
validator: (date) {
  if (date == null) return 'Vui lòng chọn ngày';
  if (date.isBefore(minDate)) {
    return 'Ngày phải sau ${formatDate(minDate)}';
  }
  return null;
}

// ❌ BAD: Vague
validator: (date) {
  if (date == null) return 'Error';
  return null;
}
```

### 5. Null Values

```dart
// ✅ GOOD: Use default null value
CyberDate(
  showClearButton: true,
  // Uses DateTime(1900, 1, 1)
)

// ✅ GOOD: Custom null for specific case
CyberDate(
  nullValue: DateTime(1970, 1, 1),
  showClearButton: true,
)
```

---

## Troubleshooting

### Date không update vào binding

**Nguyên nhân:** Không dùng binding

**Giải pháp:**
```dart
// ✅ CORRECT
CyberDate(
  text: drOrder.bind('order_date'),
  ...
)

// ❌ WRONG
CyberDate(
  text: drOrder['order_date'],
  ...
)
```

### Format error

**Nguyên nhân:** Pattern không hợp lệ

**Giải pháp:**
```dart
// ✅ CORRECT
CyberDate(
  format: 'dd/MM/yyyy', // Valid
)

// ❌ WRONG
CyberDate(
  format: 'dd/mm/yyyy', // mm = minutes!
)
```

### Validation không chạy

**Nguyên nhân:** Validator return giá trị sai

**Giải pháp:**
```dart
// ✅ CORRECT
validator: (date) {
  if (invalid) return 'Error message';
  return null; // Valid!
}

// ❌ WRONG
validator: (date) {
  if (invalid) return 'Error';
  return ''; // Should be null!
}
```

### Null value không hoạt động

**Nguyên nhân:** So sánh sai

**Giải pháp:**
```dart
// Date được so sánh theo year, month, day
// Time component bị ignore

// ✅ Check null properly
if (date == null || date == nullValue) {
  // Handle null
}
```

### Min/max validation không chính xác

**Nguyên nhân:** Time component

**Giải pháp:**
```dart
// ✅ CORRECT: Only date part
final minDate = DateTime(2020, 1, 1);

// ❌ WRONG: With time
final minDate = DateTime.now(); // Has time!
```

---

## Tips & Tricks

### 1. Quick Date Setters

```dart
final controller = CyberDateController();

// Today
controller.setToday();

// First/last day of month
controller.setStartOfMonth();
controller.setEndOfMonth();

// First/last day of year
controller.setStartOfYear();
controller.setEndOfYear();

// Date arithmetic
controller.addDays(7);
controller.addMonths(1);
controller.addYears(1);
```

### 2. Compare Dates

```dart
final controller = CyberDateController();

if (controller.isBefore(deadline)) {
  print('Still have time');
}

if (controller.isAfter(startDate)) {
  print('Started');
}
```

### 3. Age Calculation

```dart
DateTime? birthday = drUser['birthday'];
if (birthday != null) {
  final now = DateTime.now();
  int age = now.year - birthday.year;
  
  // Adjust for birthday not yet occurred this year
  if (now.month < birthday.month ||
      (now.month == birthday.month && now.day < birthday.day)) {
    age--;
  }
  
  print('Age: $age');
}
```

### 4. Business Days

```dart
bool isWeekend(DateTime date) {
  return date.weekday == DateTime.saturday ||
         date.weekday == DateTime.sunday;
}

DateTime nextBusinessDay(DateTime date) {
  DateTime next = date.add(Duration(days: 1));
  while (isWeekend(next)) {
    next = next.add(Duration(days: 1));
  }
  return next;
}
```

### 5. Date Formatting Helper

```dart
String formatDate(DateTime? date, [String pattern = 'dd/MM/yyyy']) {
  if (date == null) return '';
  return DateFormat(pattern).format(date);
}

// Usage
Text('Ngày: ${formatDate(drOrder['order_date'])}')
```

---

## Performance Tips

1. **Reuse Controller**: Tạo một lần, reuse nhiều nơi
2. **Date Normalization**: Chỉ lưu date part, bỏ time
3. **Validation Cache**: Cache validation results nếu phức tạp
4. **Format Once**: Tạo DateFormat một lần, reuse
5. **Dispose**: Always dispose controllers

---

## Version History

### 1.0.0
- Initial release
- Internal controller
- Two-way binding
- Null value handling
- iOS-style picker
- Custom format support
- Date range validation

---

## License

MIT License - CyberFramework
