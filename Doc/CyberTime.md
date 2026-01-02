# CyberTime - Internal Controller + Binding Pattern

## 📋 Tổng Quan

CyberTime được refactor theo triết lý **Internal Controller + Binding** của ERP/CyberFramework:
- ✅ Không cần khai báo controller bên ngoài
- ✅ Widget tự quản lý internal controller
- ✅ Binding dữ liệu qua thuộc tính `text`
- ✅ Controller là single source of truth bên trong

## 🎯 Triết Lý Thiết Kế

### Before (Old Pattern - External Controller)
```dart
// ❌ Phức tạp - phải tạo controller bên ngoài
final timeController = CyberTimeController();

CyberTime(
  controller: timeController,  // ← Phải truyền controller
  label: 'Giờ bắt đầu',
)
```

### After (New Pattern - Internal Controller + Binding)
```dart
// ✅ Đơn giản - chỉ cần binding
CyberTime(
  text: dr.bind("gio_bat_dau"),  // ← Direct binding
  label: 'Giờ bắt đầu',
)
```

## 📦 Kiến Trúc

```
┌─────────────────────────────────────────┐
│         CyberTime Widget                │
│  ┌───────────────────────────────────┐  │
│  │   Internal Controller             │  │
│  │   (Single Source of Truth)        │  │
│  └───────────┬───────────────────────┘  │
│              │                           │
│    ┌─────────┴─────────┐                │
│    │                   │                │
│    ▼                   ▼                │
│  Binding             UI Display         │
│  (2-way sync)        (TextField)        │
└────┬─────────────────────────────────────┘
     │
     ▼
  CyberDataRow
```

### Luồng Dữ Liệu (Unidirectional Data Flow)

1. **Initialization**: Props → Controller
2. **Binding Change**: Binding → Controller → UI
3. **User Input**: UI → Controller → Binding
4. **Controller Change**: Controller → UI + Binding

## 🚀 Cách Sử Dụng

### 1. Binding với CyberDataRow (Recommended)
```dart
// Tạo data row
final dr = CyberDataRow({
  'gio_bat_dau': '09:00',
  'gio_ket_thuc': '17:30',
});

// Sử dụng với binding
CyberTime(
  text: dr.bind("gio_bat_dau"),  // ✅ Two-way binding
  label: 'Giờ bắt đầu',
  onChanged: (time) => print('Changed: $time'),
)
```

### 2. Giá Trị Trực Tiếp
```dart
CyberTime(
  text: TimeOfDay(hour: 9, minute: 0),  // ✅ Direct value
  label: 'Giờ mặc định',
)

// Hoặc từ string
CyberTime(
  text: "09:30",  // ✅ Auto parse
  label: 'Giờ bắt đầu',
)
```

### 3. Initial Value (No Binding)
```dart
CyberTime(
  initialValue: TimeOfDay(hour: 8, minute: 30),
  label: 'Giờ vào làm',
)
```

### 4. DateTime Binding (Preserve Date)
```dart
final dr = CyberDataRow({
  'ngay_hop': DateTime(2024, 1, 15, 14, 30),  // Full datetime
});

CyberTime(
  text: dr.bind("ngay_hop"),  // ✅ Chỉ edit time, preserve date
  label: 'Giờ họp',
)

// Khi user chọn 16:00:
// dr['ngay_hop'] = DateTime(2024, 1, 15, 16, 0)  ← Date không thay đổi
```

## 🔧 Tính Năng

### Validation
```dart
CyberTime(
  text: dr.bind("gio_bat_dau"),
  label: 'Giờ bắt đầu',
  isCheckEmpty: true,  // Required field
  minTime: TimeOfDay(hour: 8, minute: 0),
  maxTime: TimeOfDay(hour: 18, minute: 0),
  validator: (time) {
    if (time == null) return 'Vui lòng chọn giờ';
    if (time.hour < 8) return 'Giờ bắt đầu phải sau 8:00';
    return null;
  },
)
```

### Visibility Binding
```dart
final dr = CyberDataRow({
  'loai': 'NGAY',  // 'NGAY' hoặc 'GIO'
  'gio_bat_dau': '09:00',
});

CyberTime(
  text: dr.bind("gio_bat_dau"),
  isVisible: dr.bind("loai"),  // Show when loai == 'GIO'
  label: 'Giờ bắt đầu',
)
```

### Callbacks
```dart
CyberTime(
  text: dr.bind("gio_bat_dau"),
  label: 'Giờ bắt đầu',
  
  // Called when value changes
  onChanged: (TimeOfDay time) {
    print('New time: ${time.hour}:${time.minute}');
  },
  
  // Called when picker closes
  onLeaver: (dynamic value) {
    // value is String or DateTime based on binding type
    print('Picker closed: $value');
  },
)
```

## 📊 So Sánh Pattern

| Feature | Old Pattern (External Controller) | New Pattern (Internal Controller) |
|---------|----------------------------------|-----------------------------------|
| Khai báo | Phải tạo controller bên ngoài | Tự động tạo internal |
| Binding | Manual sync | Auto sync 2-way |
| Complexity | Cao | Thấp |
| Boilerplate | Nhiều | Ít |
| Memory | Controller lifecycle riêng | Auto cleanup với widget |
| Use Case | Programmatic control cần thiết | 95% trường hợp thông thường |

## 🔍 Chi Tiết Kỹ Thuật

### Internal Controller Lifecycle
```dart
class _CyberTimeState extends State<CyberTime> {
  late CyberTimeController _controller;  // Internal controller
  
  @override
  void initState() {
    super.initState();
    _controller = CyberTimeController();  // ✅ Tự tạo
    _controller.addListener(_onControllerChanged);
    _loadInitialValue();  // Load từ props
  }
  
  @override
  void dispose() {
    _controller.dispose();  // ✅ Tự cleanup
    super.dispose();
  }
}
```

### Value Synchronization
```dart
// Binding → Controller
void _onBindingChanged() {
  final value = _getValueFromProps();
  if (!_sameTime(_controller.value, value)) {
    _controller.setSilently(value);  // ✅ Không trigger listener
  }
}

// Controller → Binding
void _syncControllerToBinding() {
  if (_boundRow != null && _boundField != null) {
    final controllerValue = _controller.value;
    // ✅ Smart sync based on original type
    if (originalValue is DateTime) {
      // Preserve date part
    } else {
      // Sync as string
    }
  }
}

// UI → Controller
void _updateValue(TimeOfDay newTime) {
  _controller.value = newTime;  // ✅ Trigger listener
  // → Auto sync to binding
  // → Auto update UI
}
```

## 🎨 UI Customization

```dart
CyberTime(
  text: dr.bind("gio_bat_dau"),
  label: 'Giờ bắt đầu',
  
  // Appearance
  icon: Icons.schedule,
  backgroundColor: Colors.blue.shade50,
  labelStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  
  // Format
  format: "HH:mm:ss",
  showSeconds: true,
  
  // Behavior
  enabled: true,
  hint: 'Chọn thời gian',
)
```

## 🧪 Testing

```dart
void main() {
  testWidgets('CyberTime binding test', (tester) async {
    final dr = CyberDataRow({'gio': '09:00'});
    
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CyberTime(
          text: dr.bind('gio'),
          label: 'Giờ',
        ),
      ),
    ));
    
    // Tap to show picker
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    
    // Select time
    await tester.tap(find.text('Xong'));
    await tester.pumpAndSettle();
    
    // Verify binding updated
    expect(dr['gio'], isNotEmpty);
  });
}
```

## ⚠️ Migration Guide

### Từ Old Pattern sang New Pattern

**Before:**
```dart
final controller = CyberTimeController();

CyberTime(
  controller: controller,
  initialValue: TimeOfDay(hour: 9, minute: 0),
  onChanged: (time) => controller.value = time,
)

// Manual sync với binding
controller.value = parseTime(dr['gio_bat_dau']);
dr['gio_bat_dau'] = formatTime(controller.value);
```

**After:**
```dart
CyberTime(
  text: dr.bind("gio_bat_dau"),  // ✅ Đơn giản hơn nhiều
  // Auto sync - không cần manual code
)
```

## 🎯 Best Practices

1. **Luôn dùng binding khi làm việc với CyberDataRow**
   ```dart
   // ✅ Good
   CyberTime(text: dr.bind("gio_bat_dau"))
   
   // ❌ Avoid - manual sync
   CyberTime(
     text: dr['gio_bat_dau'],
     onChanged: (time) => dr['gio_bat_dau'] = time,
   )
   ```

2. **Dùng initialValue cho form không có data binding**
   ```dart
   CyberTime(
     initialValue: TimeOfDay.now(),
     onChanged: (time) => saveToPreferences(time),
   )
   ```

3. **Validation luôn kết hợp với isCheckEmpty**
   ```dart
   CyberTime(
     text: dr.bind("gio_bat_dau"),
     isCheckEmpty: true,  // Show * indicator
     validator: (time) => time == null ? 'Required' : null,
   )
   ```

## 📝 Notes

- Controller được tạo và dispose tự động theo lifecycle của widget
- Binding sync là 2-way và automatic
- DateTime binding preserve date part khi chỉ edit time
- Validation chạy tự động khi value thay đổi
- UI reactive qua ListenableBuilder của controller

## 🔗 Related Components

- `CyberTimeController` - Internal state management
- `CyberDataRow` - Data binding source
- `CyberBindingExpression` - Binding expression wrapper
