# CyberDate - Hướng Dẫn Sử Dụng

## Giới Thiệu

`CyberDate` là date picker control với iOS-style wheel picker, hỗ trợ custom format và data binding hai chiều.

## Properties

| Property | Type | Mặc định | Mô tả |
|----------|------|----------|-------|
| `text` | `dynamic` | `null` | Giá trị date hoặc binding |
| `label` | `String?` | `null` | Label hiển thị phía trên |
| `hint` | `String?` | `null` | Placeholder |
| `format` | `String` | `"dd/MM/yyyy"` | Date format pattern |
| `icon` | `IconData?` | `null` | Icon bên trái |
| `minDate` | `DateTime?` | `now - 20 years` | Ngày tối thiểu |
| `maxDate` | `DateTime?` | `now + 20 years` | Ngày tối đa |
| `enabled` | `bool` | `true` | Bật/tắt |
| `isVisible` | `dynamic` | `true` | Điều khiển hiển thị |
| `isShowLabel` | `bool` | `true` | Hiển thị label |
| `backgroundColor` | `Color?` | `Color(0xFFF5F5F5)` | Màu nền |
| `style` | `TextStyle?` | `null` | Style cho date text |
| `labelStyle` | `TextStyle?` | `null` | Style cho label |
| `onChanged` | `ValueChanged<DateTime>?` | `null` | Callback khi date thay đổi |
| `onLeaver` | `Function(dynamic)?` | `null` | Callback khi mất focus |

## Date Format Patterns

| Pattern | Example Output |
|---------|----------------|
| `"dd/MM/yyyy"` | 19/12/2025 |
| `"MM/dd/yyyy"` | 12/19/2025 |
| `"yyyy-MM-dd"` | 2025-12-19 |
| `"dd-MM-yyyy"` | 19-12-2025 |
| `"dd MMM yyyy"` | 19 Dec 2025 |
| `"EEEE, dd MMMM yyyy"` | Friday, 19 December 2025 |

## Ví Dụ Cơ Bản

### 1. Date Picker Đơn Giản

```dart
CyberDate(
  label: 'Ngày sinh',
  hint: 'Chọn ngày sinh',
  format: "dd/MM/yyyy",
  icon: Icons.calendar_today,
)
```

### 2. Với Data Binding

```dart
final CyberDataRow row = CyberDataRow();
row['birthDate'] = DateTime(1990, 1, 1);

CyberDate(
  text: row.bind('birthDate'),
  label: 'Ngày sinh',
  format: "dd/MM/yyyy",
  icon: Icons.cake,
)
```

### 3. Với Min/Max Date

```dart
CyberDate(
  text: row.bind('appointmentDate'),
  label: 'Ngày hẹn',
  format: "dd/MM/yyyy",
  minDate: DateTime.now(), // Không cho chọn quá khứ
  maxDate: DateTime.now().add(Duration(days: 90)), // Tối đa 90 ngày
  icon: Icons.event,
)
```

### 4. Form Với Multiple Dates

```dart
class BookingForm extends StatefulWidget {
  @override
  State<BookingForm> createState() => _BookingFormState();
}

class _BookingFormState extends State<BookingForm> {
  final CyberDataRow row = CyberDataRow();

  @override
  void initState() {
    super.initState();
    row['checkInDate'] = DateTime.now();
    row['checkOutDate'] = DateTime.now().add(Duration(days: 1));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberDate(
          text: row.bind('checkInDate'),
          label: 'Ngày nhận phòng',
          format: "dd/MM/yyyy",
          minDate: DateTime.now(),
          icon: Icons.login,
          onChanged: (date) {
            // Auto adjust checkout date
            final checkOut = row['checkOutDate'] as DateTime?;
            if (checkOut != null && checkOut.isBefore(date)) {
              row['checkOutDate'] = date.add(Duration(days: 1));
            }
          },
        ),
        
        SizedBox(height: 16),
        
        CyberDate(
          text: row.bind('checkOutDate'),
          label: 'Ngày trả phòng',
          format: "dd/MM/yyyy",
          minDate: (row['checkInDate'] as DateTime).add(Duration(days: 1)),
          icon: Icons.logout,
        ),
        
        SizedBox(height: 24),
        
        ElevatedButton(
          onPressed: () {
            final checkIn = row['checkInDate'] as DateTime;
            final checkOut = row['checkOutDate'] as DateTime;
            final nights = checkOut.difference(checkIn).inDays;
            print('Số đêm: $nights');
          },
          child: Text('Đặt phòng'),
        ),
      ],
    );
  }
}
```

## iOS-Style Wheel Picker

Picker hiển thị 3 wheels:
- **Day**: 01-31 (tùy tháng)
- **Month**: Tháng 1 - Tháng 12
- **Year**: Theo minDate & maxDate

```dart
CyberDate(
  text: row.bind('date'),
  label: 'Chọn ngày',
  format: "dd/MM/yyyy",
  // ✅ Tap để mở wheel picker
)
```

### Auto-Adjust Days

Picker tự động điều chỉnh số ngày theo tháng:

```dart
// Tháng 2: 28/29 ngày
// Tháng 4,6,9,11: 30 ngày
// Các tháng còn lại: 31 ngày

// Nếu đang chọn 31/01 và đổi sang tháng 2
// → Tự động chuyển về 28/02 (hoặc 29/02)
```

## Date Conversion

### String → DateTime

```dart
// Tự động parse từ string
row['date'] = "2025-12-19"; // ISO format
row['date'] = "19/12/2025"; // Custom format

CyberDate(
  text: row.bind('date'),
  format: "dd/MM/yyyy",
  // ✅ Tự động convert string → DateTime
)
```

### DateTime Storage

```dart
// Luôn lưu dưới dạng DateTime trong binding
CyberDate(
  text: row.bind('date'),
  onChanged: (date) {
    print(date.runtimeType); // DateTime
  },
)
```

## Visibility & Disabled State

```dart
final CyberDataRow row = CyberDataRow();
row['showDatePicker'] = true;

CyberDate(
  text: row.bind('date'),
  label: 'Ngày sinh',
  isVisible: row.bind('showDatePicker'), // ✅ Conditional visibility
  enabled: true,
)
```

## Custom Styling

```dart
CyberDate(
  text: row.bind('weddingDate'),
  label: 'Ngày cưới',
  format: "dd/MM/yyyy",
  backgroundColor: Colors.pink.shade50,
  icon: Icons.favorite,
  labelStyle: TextStyle(
    fontSize: 16,
    color: Colors.pink.shade700,
    fontWeight: FontWeight.bold,
  ),
  style: TextStyle(
    fontSize: 16,
    color: Colors.pink.shade900,
    fontWeight: FontWeight.w600,
  ),
)
```

## Use Cases

### 1. Birth Date

```dart
CyberDate(
  text: row.bind('birthDate'),
  label: 'Ngày sinh',
  format: "dd/MM/yyyy",
  maxDate: DateTime.now(), // Không cho chọn tương lai
  minDate: DateTime(1900, 1, 1),
  icon: Icons.cake,
)
```

### 2. Appointment Booking

```dart
CyberDate(
  text: row.bind('appointmentDate'),
  label: 'Ngày hẹn khám',
  format: "EEEE, dd/MM/yyyy",
  minDate: DateTime.now(),
  maxDate: DateTime.now().add(Duration(days: 30)),
  icon: Icons.medical_services,
)
```

### 3. Event Date

```dart
CyberDate(
  text: row.bind('eventDate'),
  label: 'Ngày sự kiện',
  format: "dd MMM yyyy",
  minDate: DateTime.now(),
  icon: Icons.event,
  onChanged: (date) {
    print('Event scheduled for: $date');
  },
)
```

### 4. Date Range Filter

```dart
Column(
  children: [
    CyberDate(
      text: row.bind('fromDate'),
      label: 'Từ ngày',
      format: "dd/MM/yyyy",
      onChanged: (date) {
        // Adjust toDate if needed
      },
    ),
    
    SizedBox(height: 16),
    
    CyberDate(
      text: row.bind('toDate'),
      label: 'Đến ngày',
      format: "dd/MM/yyyy",
      minDate: row['fromDate'] as DateTime?,
    ),
  ],
)
```

## Age Calculation

```dart
CyberDate(
  text: row.bind('birthDate'),
  label: 'Ngày sinh',
  format: "dd/MM/yyyy",
  onLeaver: (date) {
    if (date is DateTime) {
      final age = DateTime.now().difference(date).inDays ~/ 365;
      print('Tuổi: $age');
    }
  },
)
```

## Tips & Best Practices

### ✅ DO

```dart
// ✅ Set appropriate date range
CyberDate(
  minDate: DateTime(1900, 1, 1),
  maxDate: DateTime.now(),
)

// ✅ Use meaningful format
CyberDate(format: "dd/MM/yyyy")  // For Vietnam
CyberDate(format: "MM/dd/yyyy")  // For US

// ✅ Validate date logic
CyberDate(
  onChanged: (date) {
    if (date.isAfter(maxAllowedDate)) {
      showError('Date too far in future');
    }
  },
)
```

### ❌ DON'T

```dart
// ❌ Don't use unrealistic date ranges
CyberDate(
  minDate: DateTime(1, 1, 1),  // Too far back
  maxDate: DateTime(9999, 12, 31),  // Too far ahead
)

// ❌ Don't forget to validate
// Always check min/max dates make sense
```

## Troubleshooting

### Vấn đề: Date không hiển thị đúng format

**Giải pháp**: Kiểm tra format string

```dart
// ✅ Valid formats
"dd/MM/yyyy"
"yyyy-MM-dd"
"EEEE, dd MMMM yyyy"

// ❌ Invalid
"dd/mm/yyyy"  // mm is minutes, not month!
```

### Vấn đề: Picker không mở

**Giải pháp**: Kiểm tra enabled state

```dart
CyberDate(
  text: row.bind('date'),
  enabled: true,  // ✅ Make sure it's enabled
)
```

### Vấn đề: Day bị reset

**Giải pháp**: Đã được handle tự động

```dart
// Nếu chọn 31/01 và đổi sang tháng 2
// → Tự động về 28/02 (auto-adjust)
```

---

## Xem Thêm

- [CyberText](./CyberText.md) - Text input control
- [CyberNumeric](./CyberNumeric.md) - Numeric input
- [CyberDataRow](./CyberDataRow.md) - Data binding system
