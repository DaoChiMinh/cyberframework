# CyberTime - Time Picker với iOS-Style Wheel

## Mục Lục
1. [Giới Thiệu](#giới-thiệu)
2. [CyberTime Widget](#cybertime-widget)
3. [CyberTimeController](#cybertimecontroller)
4. [Ví Dụ Sử Dụng](#ví-dụ-sử-dụng)
5. [Features](#features)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

---

## Giới Thiệu

`CyberTime` là time picker widget với **Internal Controller**, **Data Binding**, và **iOS-style wheel picker**. Widget này cung cấp trải nghiệm chọn giờ giống native iOS app.

### Đặc Điểm Chính

- ✅ **Internal Controller**: Tự động quản lý state
- ✅ **Two-Way Binding**: Sync với CyberDataRow
- ✅ **iOS-Style Picker**: Wheel picker trong bottom sheet
- ✅ **Multiple Formats**: HH:mm, HH:mm:ss
- ✅ **DateTime Support**: Preserve date part khi binding với DateTime
- ✅ **Validation**: Min/max time, required field
- ✅ **Custom Validator**: Flexible validation logic
- ✅ **Auto Focus**: Tap field → Show picker

### Import

```dart
import 'package:cyberframework/cyberframework.dart';
```

---

## CyberTime Widget

### Constructor

```dart
const CyberTime({
  super.key,
  this.text,
  this.initialValue,
  this.label,
  this.hint,
  this.format = "HH:mm",
  this.prefixIcon,
  this.borderSize = 1,
  this.borderRadius,
  this.enabled = true,
  this.style,
  this.decoration,
  this.isShowLabel = true,
  this.backgroundColor,
  this.borderColor = Colors.transparent,
  this.focusColor,
  this.labelStyle,
  this.isVisible = true,
  this.showSeconds = false,
  this.isCheckEmpty = false,
  this.onChanged,
  this.onLeaver,
  this.validator,
  this.errorText,
  this.minTime,
  this.maxTime,
})
```

### Properties

#### Data Binding

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `text` | `dynamic` | Binding, TimeOfDay, String, or null | null |
| `initialValue` | `TimeOfDay?` | Initial value (khi text = null) | null |

**Supported text types:**
```dart
text: drOrder.bind('start_time')     // CyberBindingExpression
text: TimeOfDay(hour: 14, minute: 30) // TimeOfDay
text: "14:30"                         // String
```

#### Display

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `label` | `String?` | Label hiển thị | null |
| `hint` | `String?` | Hint text | "Chọn giờ" |
| `format` | `String` | Time format | "HH:mm" |
| `showSeconds` | `bool` | Hiển thị giây | false |
| `prefixIcon` | `String?` | Icon code (hex) | null (auto clock icon) |
| `isShowLabel` | `bool` | Hiển thị label | true |

**Format options:**
- `"HH:mm"` → 14:30
- `"HH:mm:ss"` → 14:30:00

#### Validation

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `isCheckEmpty` | `dynamic` | Required field | false |
| `validator` | `String? Function(TimeOfDay?)?` | Custom validator | null |
| `errorText` | `String?` | Error message | null |
| `minTime` | `TimeOfDay?` | Minimum time | null |
| `maxTime` | `TimeOfDay?` | Maximum time | null |

#### Styling

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `style` | `TextStyle?` | Text style | null |
| `labelStyle` | `TextStyle?` | Label style | null |
| `decoration` | `InputDecoration?` | Custom decoration | null |
| `backgroundColor` | `Color?` | Màu nền | Color(0xFFF5F5F5) |
| `borderColor` | `Color?` | Màu border | Colors.transparent |
| `borderSize` | `int?` | Độ dày border (px) | 1 |
| `borderRadius` | `int?` | Bo góc (px) | 4 |

#### State

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `enabled` | `bool` | Enable/disable | true |
| `isVisible` | `dynamic` | Hiển thị/ẩn (có thể binding) | true |

#### Callbacks

| Property | Type | Mô Tả |
|----------|------|-------|
| `onChanged` | `ValueChanged<TimeOfDay>?` | Khi time thay đổi |
| `onLeaver` | `Function(dynamic)?` | Khi rời khỏi control |

---

## CyberTimeController

**NOTE**: Controller là **OPTIONAL**. Widget tự quản lý internal controller.

### Properties & Methods

```dart
final controller = CyberTimeController();

// Properties
TimeOfDay? value = controller.value;
bool isEmpty = controller.isEmpty;
bool isNotEmpty = controller.isNotEmpty;

// Set value
controller.value = TimeOfDay(hour: 14, minute: 30);

// Set silently (no notify)
controller.setSilently(TimeOfDay.now());

// Clear
controller.clear();
```

---

## Ví Dụ Sử Dụng

### 1. Sử Dụng Cơ Bản (Recommended)

Simple time picker.

```dart
class TimeSelector extends StatefulWidget {
  @override
  State<TimeSelector> createState() => _TimeSelectorState();
}

class _TimeSelectorState extends State<TimeSelector> {
  final drEvent = CyberDataRow();

  @override
  void initState() {
    super.initState();
    
    drEvent['start_time'] = '';
    drEvent['end_time'] = '';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberTime(
          text: drEvent.bind('start_time'),
          label: 'Giờ bắt đầu',
        ),
        
        SizedBox(height: 16),
        
        CyberTime(
          text: drEvent.bind('end_time'),
          label: 'Giờ kết thúc',
        ),
      ],
    );
  }
}
```

### 2. With Seconds

Time picker với giây.

```dart
CyberTime(
  text: drLog.bind('exact_time'),
  label: 'Thời gian chính xác',
  format: 'HH:mm:ss',
  showSeconds: true,
)
```

### 3. DateTime Binding

Binding với DateTime field (preserve date).

```dart
class AppointmentForm extends StatefulWidget {
  @override
  State<AppointmentForm> createState() => _AppointmentFormState();
}

class _AppointmentFormState extends State<AppointmentForm> {
  final drAppointment = CyberDataRow();

  @override
  void initState() {
    super.initState();
    
    // DateTime field
    drAppointment['appointment_datetime'] = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberDate(
          text: drAppointment.bind('appointment_datetime'),
          label: 'Ngày hẹn',
        ),
        
        SizedBox(height: 16),
        
        // Time picker preserves date part
        CyberTime(
          text: drAppointment.bind('appointment_datetime'),
          label: 'Giờ hẹn',
        ),
      ],
    );
  }
}
```

### 4. Min/Max Validation

Time range validation.

```dart
CyberTime(
  text: drShift.bind('shift_time'),
  label: 'Ca làm việc',
  
  // Must be between 8 AM and 6 PM
  minTime: TimeOfDay(hour: 8, minute: 0),
  maxTime: TimeOfDay(hour: 18, minute: 0),
)
```

### 5. Required Field

Time field bắt buộc.

```dart
class RequiredTime extends StatefulWidget {
  @override
  State<RequiredTime> createState() => _RequiredTimeState();
}

class _RequiredTimeState extends State<RequiredTime> {
  final drMeeting = CyberDataRow();

  bool validate() {
    if (drMeeting['meeting_time'].toString().isEmpty) {
      showError('Vui lòng chọn giờ họp');
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberTime(
          text: drMeeting.bind('meeting_time'),
          label: 'Giờ họp',
          isCheckEmpty: true,  // Show *
        ),
        
        SizedBox(height: 16),
        
        CyberButton(
          label: 'Lưu',
          onClick: () {
            if (validate()) {
              save();
            }
          },
        ),
      ],
    );
  }
}
```

### 6. Custom Validator

Validation logic tùy chỉnh.

```dart
CyberTime(
  text: drOrder.bind('delivery_time'),
  label: 'Giờ giao hàng',
  
  validator: (time) {
    if (time == null) {
      return 'Vui lòng chọn giờ giao hàng';
    }
    
    // Must be after 9 AM
    if (time.hour < 9) {
      return 'Giờ giao hàng phải sau 9:00 sáng';
    }
    
    // Must be before 10 PM
    if (time.hour >= 22) {
      return 'Giờ giao hàng phải trước 22:00';
    }
    
    return null;  // Valid
  },
)
```

### 7. Working Hours

Start time và end time validation.

```dart
class WorkingHours extends StatefulWidget {
  @override
  State<WorkingHours> createState() => _WorkingHoursState();
}

class _WorkingHoursState extends State<WorkingHours> {
  final drShift = CyberDataRow();

  @override
  void initState() {
    super.initState();
    
    drShift['start'] = '08:00';
    drShift['end'] = '17:00';
  }

  bool validate() {
    final start = _parseTime(drShift['start']);
    final end = _parseTime(drShift['end']);
    
    if (start == null || end == null) {
      showError('Vui lòng chọn giờ làm việc');
      return false;
    }
    
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    
    if (endMinutes <= startMinutes) {
      showError('Giờ kết thúc phải sau giờ bắt đầu');
      return false;
    }
    
    return true;
  }

  TimeOfDay? _parseTime(String value) {
    try {
      final parts = value.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberTime(
          text: drShift.bind('start'),
          label: 'Giờ bắt đầu',
        ),
        
        SizedBox(height: 16),
        
        CyberTime(
          text: drShift.bind('end'),
          label: 'Giờ kết thúc',
        ),
        
        SizedBox(height: 16),
        
        CyberButton(
          label: 'Lưu',
          onClick: () {
            if (validate()) {
              save();
            }
          },
        ),
      ],
    );
  }
}
```

### 8. With Icon

Custom icon prefix.

```dart
CyberTime(
  text: drReminder.bind('reminder_time'),
  label: 'Nhắc nhở lúc',
  prefixIcon: 'e855',  // alarm icon
)
```

### 9. Disabled State

Read-only time field.

```dart
CyberTime(
  text: drLog.bind('created_time'),
  label: 'Thời gian tạo',
  enabled: false,  // Read-only
)
```

### 10. Initial Value

Set initial time.

```dart
class DefaultTime extends StatefulWidget {
  @override
  State<DefaultTime> createState() => _DefaultTimeState();
}

class _DefaultTimeState extends State<DefaultTime> {
  final drSettings = CyberDataRow();

  @override
  Widget build(BuildContext context) {
    return CyberTime(
      text: drSettings.bind('default_start'),
      label: 'Giờ mặc định',
      
      // Initial value if field is empty
      initialValue: TimeOfDay(hour: 9, minute: 0),
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
CyberTime(
  text: drEvent.bind('start_time'),
  label: 'Giờ bắt đầu',
)
```

### 2. iOS-Style Picker

Wheel picker trong bottom sheet:

```dart
// - Hour wheel (0-23)
// - Minute wheel (0-59)
// - Second wheel (0-59) if showSeconds = true
// - Smooth scrolling
// - Current value highlighted
```

### 3. Multiple Input Types

```dart
// Binding
text: drOrder.bind('time')

// TimeOfDay
text: TimeOfDay(hour: 14, minute: 30)

// String
text: "14:30"

// Initial value
initialValue: TimeOfDay.now()
```

### 4. DateTime Preservation

Khi binding với DateTime:

```dart
// Original: 2024-01-15 10:30:00
// User picks: 14:00
// Result: 2024-01-15 14:00:00
// → Date preserved!
```

### 5. Validation

**Built-in:**
```dart
minTime: TimeOfDay(hour: 8, minute: 0)
maxTime: TimeOfDay(hour: 17, minute: 0)
isCheckEmpty: true
```

**Custom:**
```dart
validator: (time) {
  if (time == null) return 'Required';
  if (time.hour < 9) return 'Must be after 9 AM';
  return null;
}
```

### 6. Auto Focus

Tap field → Picker opens automatically.

---

## Best Practices

### 1. Sử Dụng Binding (Recommended)

```dart
// ✅ GOOD
CyberTime(
  text: drEvent.bind('start_time'),
  label: 'Start Time',
)

// ❌ BAD: Manual state
TimeOfDay? time;
CyberTime(
  text: time,
  onChanged: (value) {
    setState(() {
      time = value;
      drEvent['start_time'] = formatTime(value);
    });
  },
)
```

### 2. Set Min/Max Appropriately

```dart
// ✅ GOOD: Business hours
CyberTime(
  minTime: TimeOfDay(hour: 8, minute: 0),
  maxTime: TimeOfDay(hour: 18, minute: 0),
)

// ✅ GOOD: Night shift
CyberTime(
  minTime: TimeOfDay(hour: 22, minute: 0),
  maxTime: TimeOfDay(hour: 6, minute: 0),
)

// ❌ BAD: No limits when needed
CyberTime(
  // Should have business hour limits
)
```

### 3. Validate Time Ranges

```dart
// ✅ GOOD: Check start < end
bool validate() {
  final start = getTime(drShift['start']);
  final end = getTime(drShift['end']);
  
  if (end <= start) {
    showError('End must be after start');
    return false;
  }
  
  return true;
}

// ❌ BAD: No validation
save();  // May save invalid range
```

### 4. Format Consistently

```dart
// ✅ GOOD: Consistent format
CyberTime(format: 'HH:mm')
CyberTime(format: 'HH:mm')

// ❌ BAD: Different formats
CyberTime(format: 'HH:mm')
CyberTime(format: 'HH:mm:ss')  // Inconsistent
```

### 5. Show Seconds When Needed

```dart
// ✅ GOOD: Precise timestamp
CyberTime(
  label: 'Log Time',
  showSeconds: true,
)

// ✅ GOOD: Appointment (no seconds needed)
CyberTime(
  label: 'Meeting Time',
  showSeconds: false,
)

// ❌ BAD: Unnecessary precision
CyberTime(
  label: 'Lunch Break',
  showSeconds: true,  // Not needed
)
```

---

## Troubleshooting

### Time không update vào binding

**Nguyên nhân:** Không dùng binding

**Giải pháp:**
```dart
// ✅ CORRECT
CyberTime(
  text: drEvent.bind('start_time'),
)

// ❌ WRONG
CyberTime(
  text: drEvent['start_time'],
)
```

### Picker không mở

**Nguyên nhân:** enabled = false

**Giải pháp:**
```dart
// ✅ CORRECT
CyberTime(
  enabled: true,
)
```

### Validation không hoạt động

**Nguyên nhân:** Sai validator syntax

**Giải pháp:**
```dart
// ✅ CORRECT
validator: (time) {
  if (time == null) return 'Required';
  return null;  // Valid
}

// ❌ WRONG
validator: (time) {
  if (time == null) return 'Required';
  // Missing return null!
}
```

### DateTime date bị thay đổi

**Nguyên nhân:** Widget đã xử lý preserve date

**Giải pháp:** Đây không phải bug, widget tự động preserve date part.

### Format không đúng

**Nguyên nhân:** Sai format string

**Giải pháp:**
```dart
// ✅ CORRECT
format: 'HH:mm'
format: 'HH:mm:ss'

// ❌ WRONG
format: 'hh:mm'  // Lowercase h
format: 'H:m'    // Single H
```

---

## Tips & Tricks

### 1. Current Time

```dart
void setNow() {
  final now = TimeOfDay.now();
  drEvent['start_time'] = '${now.hour}:${now.minute}';
}
```

### 2. Add Duration

```dart
TimeOfDay addHours(TimeOfDay time, int hours) {
  int newHour = (time.hour + hours) % 24;
  return TimeOfDay(hour: newHour, minute: time.minute);
}

// Set end = start + 2 hours
final start = getTime(drShift['start']);
final end = addHours(start, 2);
drShift['end'] = formatTime(end);
```

### 3. Format Time

```dart
String formatTime(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}
```

### 4. Parse Time String

```dart
TimeOfDay? parseTime(String value) {
  try {
    final parts = value.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  } catch (e) {
    return null;
  }
}
```

### 5. Time Difference

```dart
int minutesDifference(TimeOfDay start, TimeOfDay end) {
  final startMinutes = start.hour * 60 + start.minute;
  final endMinutes = end.hour * 60 + end.minute;
  return endMinutes - startMinutes;
}

// Usage
final start = getTime(drShift['start']);
final end = getTime(drShift['end']);
final duration = minutesDifference(start, end);
print('Shift duration: $duration minutes');
```

---

## Performance Tips

1. **Reuse DataRow**: Don't create new rows unnecessarily
2. **Avoid Heavy Validators**: Keep validator logic simple
3. **Debounce Callbacks**: Debounce if onChanged has heavy logic
4. **Cache Parsed Values**: Parse time strings once
5. **Dispose Controllers**: Always dispose if using external controller

---

## Common Patterns

### Business Hours

```dart
CyberTime(
  minTime: TimeOfDay(hour: 8, minute: 0),
  maxTime: TimeOfDay(hour: 18, minute: 0),
)
```

### Appointment Scheduling

```dart
Column(
  children: [
    CyberDate(
      text: dr.bind('date'),
      label: 'Ngày',
    ),
    CyberTime(
      text: dr.bind('time'),
      label: 'Giờ',
      minTime: TimeOfDay(hour: 9, minute: 0),
      maxTime: TimeOfDay(hour: 17, minute: 0),
    ),
  ],
)
```

### Shift Management

```dart
Column(
  children: [
    CyberTime(
      text: drShift.bind('start'),
      label: 'Bắt đầu',
    ),
    CyberTime(
      text: drShift.bind('end'),
      label: 'Kết thúc',
    ),
  ],
)
```

---

## Version History

### 1.0.0
- Initial release
- Internal controller
- Two-way binding
- iOS-style wheel picker
- DateTime support (preserve date)
- Min/max validation
- Custom validator
- Seconds support
- Auto focus picker

---

## License

MIT License - CyberFramework
