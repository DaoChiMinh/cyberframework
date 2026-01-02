# CyberComboBox - Internal Controller + Binding Architecture

## 📋 Tổng quan

CyberComboBox được refactor theo triết lý **Internal Controller + Binding**, đúng với tinh thần ERP/CyberFramework:

- ✅ **Không cần khai báo controller** - Widget tự quản lý state
- ✅ **Binding trực tiếp** qua thuộc tính `text`
- ✅ **Sync 2 chiều** tự động với CyberDataRow
- ✅ **Optional external controller** khi cần control phức tạp

---

## 🏗️ Kiến trúc

```
┌─────────────────────────────────────────────────────────────┐
│                     CyberComboBox Widget                     │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌───────────────────────────────────────────────────────┐  │
│  │          Internal Controller (Luôn tồn tại)           │  │
│  │  - Quản lý state nội bộ                                │  │
│  │  - Tự động tạo khi khởi tạo widget                    │  │
│  │  - Auto dispose khi widget dispose                     │  │
│  └───────────────────────────────────────────────────────┘  │
│                          ↕ sync                              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │         Text Binding (CyberBindingExpression)         │  │
│  │  - Binding vào CyberDataRow field                     │  │
│  │  - Sync 2 chiều tự động                               │  │
│  │  - Source of truth khi có binding                     │  │
│  └───────────────────────────────────────────────────────┘  │
│                          ↕ optional                          │
│  ┌───────────────────────────────────────────────────────┐  │
│  │       External Controller (Optional override)         │  │
│  │  - Khi cần control từ bên ngoài                       │  │
│  │  - Advanced use cases                                  │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔄 Luồng dữ liệu

### 1. Khởi tạo (Initialization)

```dart
// Bước 1: Parse binding expression
text: drEdit.bind('ma_kh')
  ↓
_boundRow = drEdit
_boundField = 'ma_kh'

// Bước 2: Tạo internal controller với initial value từ binding
_internalController = CyberComboBoxController(
  value: drEdit['ma_kh'],  // ← Đọc từ binding
  ...
)

// Bước 3: Đăng ký listeners
drEdit.addListener(_onBindingChanged)
_internalController.addListener(_onControllerChanged)
```

### 2. User chọn giá trị mới (User Selection)

```dart
User chọn item trong picker
  ↓
_updateValue(newValue)
  ↓
┌─────────────────────────────────────┐
│ 1. Update internal controller      │
│    _internalController.setValue()   │
│    ↓                                │
│ 2. Update binding (preserve type)   │
│    drEdit['ma_kh'] = newValue       │
│    ↓                                │
│ 3. Trigger callbacks                │
│    onChanged?.call(newValue)        │
└─────────────────────────────────────┘
```

### 3. Binding thay đổi từ bên ngoài (External Binding Change)

```dart
drEdit['ma_kh'] = '003'  // Code thay đổi từ bên ngoài
  ↓
drEdit.notifyListeners()
  ↓
_onBindingChanged()
  ↓
_syncFromBinding()
  ↓
┌─────────────────────────────────────┐
│ 1. Đọc giá trị mới từ binding       │
│    bindingValue = drEdit['ma_kh']   │
│    ↓                                │
│ 2. Update internal controller       │
│    _internalController.setValue()   │
│    ↓                                │
│ 3. Trigger rebuild                  │
│    setState(() {})                  │
└─────────────────────────────────────┘
```

### 4. Controller thay đổi (Controller Change)

```dart
_internalController.setValue('002')
  ↓
controller.notifyListeners()
  ↓
_onControllerChanged()
  ↓
_syncToBinding()
  ↓
┌─────────────────────────────────────┐
│ 1. Đọc giá trị từ controller        │
│    controllerValue = controller.value│
│    ↓                                │
│ 2. Update binding (preserve type)   │
│    drEdit['ma_kh'] = controllerValue│
│    ↓                                │
│ 3. Trigger rebuild                  │
│    setState(() {})                  │
└─────────────────────────────────────┘
```

---

## 🎯 Priority và Source of Truth

### Value Priority (Ưu tiên đọc giá trị)

```dart
_getCurrentValue() {
  // Priority 1: BINDING (source of truth khi có binding)
  if (_boundRow != null && _boundField != null) {
    return _boundRow![_boundField!];
  }

  // Priority 2: CONTROLLER
  return _controller.value;
}
```

### Tại sao Binding là Priority 1?

1. **ERP Philosophy**: Trong ERP, data row là trung tâm của form
2. **Consistency**: Form data luôn đồng bộ với UI
3. **Simplicity**: Không cần quan tâm controller khi dùng binding

---

## 💡 Cách sử dụng

### ✅ Cách 1: Binding (RECOMMENDED)

```dart
// Setup
final drEdit = CyberDataRow({'ma_kh': '001', 'ten_kh': ''});
final dtKhachHang = CyberDataTable();
// ... populate dtKhachHang

// Usage
CyberComboBox(
  text: drEdit.bind('ma_kh'),  // ← Chỉ cần bind!
  dataSource: dtKhachHang,
  valueMember: 'ma_kh',
  displayMember: 'ten_kh',
  label: 'Khách hàng',
)

// Auto sync - không cần code gì thêm!
drEdit['ma_kh'] = '002';  // ← UI tự động update
```

**Ưu điểm:**
- ✅ Ngắn gọn, dễ hiểu
- ✅ Tự động sync 2 chiều
- ✅ Không cần quản lý controller
- ✅ Đúng triết lý ERP

### ⚙️ Cách 2: External Controller (Advanced)

```dart
// Setup
final controller = CyberComboBoxController(
  value: '001',
  dataSource: dtKhachHang,
  valueMember: 'ma_kh',
  displayMember: 'ten_kh',
);

// Usage
CyberComboBox(
  controller: controller,
  label: 'Khách hàng',
)

// Control từ code
controller.setValue('002');
controller.clear();
controller.setEnabled(false);
```

**Ưu điểm:**
- ✅ Control phức tạp từ code
- ✅ Validate selection
- ✅ Programmatic operations

**Khi nào dùng:**
- Cần clear/reset nhiều lần
- Validate selection trước khi save
- Dynamic enable/disable based on logic
- Multiple combos phụ thuộc nhau

### 📝 Cách 3: Simple Value (Basic)

```dart
CyberComboBox(
  text: '001',  // Direct value
  dataSource: dtKhachHang,
  valueMember: 'ma_kh',
  displayMember: 'ten_kh',
  onChanged: (value) {
    print('Selected: $value');
  },
)
```

**Khi nào dùng:**
- Demo, prototype
- Không cần persist data
- One-time selection

---

## 🔧 Technical Details

### Infinite Loop Prevention

```dart
bool _isUpdating = false;  // ← Flag để prevent infinite loop

void _syncFromBinding() {
  if (_isUpdating) return;  // ← Guard
  
  _isUpdating = true;
  try {
    // ... sync logic
  } finally {
    _isUpdating = false;
  }
}
```

**Flow:**
```
User chọn value
  ↓
_updateValue() sets _isUpdating = true
  ↓
Update controller → trigger _onControllerChanged()
  ↓
_onControllerChanged() checks _isUpdating → SKIP
  ↓
Update binding → trigger _onBindingChanged()
  ↓
_onBindingChanged() checks _isUpdating → SKIP
  ↓
_isUpdating = false
  ↓
Done (no infinite loop!)
```

### Type Preservation

```dart
void _updateValue(dynamic newValue) {
  if (_boundRow != null && _boundField != null) {
    final originalValue = _boundRow![_boundField!];

    // ✅ Preserve original type
    if (originalValue is String && newValue != null) {
      _boundRow![_boundField!] = newValue.toString();
    } else if (originalValue is int && newValue is int) {
      _boundRow![_boundField!] = newValue;
    } else if (originalValue is double && newValue is num) {
      _boundRow![_boundField!] = newValue.toDouble();
    } else {
      _boundRow![_boundField!] = newValue;
    }
  }
}
```

**Tại sao cần preserve type?**
- Database schema đòi hỏi kiểu dữ liệu cụ thể
- Prevent runtime errors khi save
- Maintain data integrity

### ListenableBuilder Optimization

```dart
ListenableBuilder(
  listenable: Listenable.merge([
    _controller,
    if (dataSource != null) dataSource,
    if (_boundRow != null) _boundRow!,
    if (_visibilityBoundRow != null) _visibilityBoundRow!,
  ]),
  builder: (context, _) {
    // ✅ Widget rebuild khi BẤT KỲ listenable nào thay đổi
    return ...;
  },
)
```

**Smart rebuild:**
- Controller changes → Rebuild
- DataSource changes → Rebuild
- Binding row changes → Rebuild
- Visibility binding changes → Rebuild

---

## 🧪 Testing Scenarios

### Test 1: Basic Binding

```dart
test('binding sync 2 chiều', () {
  final drEdit = CyberDataRow({'ma_kh': '001'});
  
  // Create widget với binding
  final widget = CyberComboBox(
    text: drEdit.bind('ma_kh'),
    dataSource: dtKhachHang,
    valueMember: 'ma_kh',
    displayMember: 'ten_kh',
  );
  
  // Test 1: Binding → UI
  drEdit['ma_kh'] = '002';
  expect(widget.getCurrentValue(), equals('002'));
  
  // Test 2: UI → Binding
  widget.selectValue('003');
  expect(drEdit['ma_kh'], equals('003'));
});
```

### Test 2: External Controller Override

```dart
test('external controller override internal', () {
  final drEdit = CyberDataRow({'ma_kh': '001'});
  final controller = CyberComboBoxController(value: '002');
  
  final widget = CyberComboBox(
    text: drEdit.bind('ma_kh'),
    controller: controller,  // ← External override
  );
  
  // External controller có quyền cao hơn
  expect(widget.getCurrentValue(), equals('002'));
});
```

### Test 3: Infinite Loop Prevention

```dart
test('no infinite loop khi sync', () {
  final drEdit = CyberDataRow({'ma_kh': '001'});
  int notifyCount = 0;
  
  drEdit.addListener(() => notifyCount++);
  
  final widget = CyberComboBox(
    text: drEdit.bind('ma_kh'),
    ...
  );
  
  // User select
  widget.selectValue('002');
  
  // Should trigger exactly 1 notification (không infinite loop)
  expect(notifyCount, equals(1));
});
```

---

## 📊 So sánh với pattern cũ

### ❌ Pattern cũ (Assertion không dùng cả 2)

```dart
const CyberComboBox({
  this.text,
  this.controller,
  ...
}) : assert(
  controller == null || text == null,
  'Không được dùng cả text và controller!',
);
```

**Vấn đề:**
- ❌ User phải chọn 1 trong 2
- ❌ Không flexible
- ❌ Phức tạp khi cần cả binding và control

### ✅ Pattern mới (Internal + Binding)

```dart
const CyberComboBox({
  this.text,        // ← Có thể vừa là binding vừa là value
  this.controller,  // ← Optional override
  ...
});

// Internal controller luôn tồn tại
_internalController = CyberComboBoxController(...);

// Effective controller
_controller = widget.controller ?? _internalController;
```

**Ưu điểm:**
- ✅ Flexible: dùng binding, controller, hoặc cả 2
- ✅ Simple: không cần khai báo controller cho case đơn giản
- ✅ Powerful: vẫn có controller khi cần

---

## 🎓 Best Practices

### ✅ DO

```dart
// 1. Dùng binding cho form thông thường
CyberComboBox(
  text: drEdit.bind('ma_kh'),
  ...
)

// 2. Dùng controller khi cần programmatic control
final controller = CyberComboBoxController();
CyberComboBox(controller: controller, ...)
controller.clear();

// 3. Dùng onChanged để handle side effects
CyberComboBox(
  text: drEdit.bind('ma_kh'),
  onChanged: (value) {
    // Load related data
    _loadCustomerDetails(value);
  },
)
```

### ❌ DON'T

```dart
// ❌ Đừng dùng cả binding và external controller cho cùng mục đích
final controller = CyberComboBoxController();
CyberComboBox(
  text: drEdit.bind('ma_kh'),  // ← Binding
  controller: controller,       // ← Controller cũng set value
)
// Conflict! Controller sẽ override binding

// ❌ Đừng manually sync khi dùng binding
CyberComboBox(
  text: drEdit.bind('ma_kh'),
  onChanged: (value) {
    drEdit['ma_kh'] = value;  // ← KHÔNG CẦN! Tự động sync rồi
  },
)

// ❌ Đừng dispose external controller khi widget còn dùng
controller.dispose();  // ← Widget sẽ crash!
```

---

## 🔍 Debugging Tips

### Check Binding

```dart
// Add listener để debug
drEdit.addListener(() {
  print('drEdit changed: ma_kh = ${drEdit["ma_kh"]}');
});
```

### Check Controller

```dart
// Add listener để debug
controller.addListener(() {
  print('Controller: ${controller.value}');
  print('DisplayText: ${controller.getDisplayText()}');
});
```

### Check Sync Direction

```dart
void _syncFromBinding() {
  print('SYNC FROM BINDING: ${_boundRow![_boundField!]}');
  ...
}

void _syncToBinding() {
  print('SYNC TO BINDING: ${_controller.value}');
  ...
}
```

---

## 📚 Related Components

CyberComboBox follows the same pattern as:

- ✅ CyberTextField
- ✅ CyberNumeric
- ✅ CyberDate
- ✅ CyberCheckbox
- ✅ CyberLookup

All use **Internal Controller + Binding** architecture!

---

## 🚀 Migration Guide

### From old pattern → new pattern

```dart
// ❌ Old: Phải chọn 1 trong 2
CyberComboBox(
  text: '001',  // ← Hoặc
  controller: controller,  // ← Hoặc
)

// ✅ New: Flexible, có thể dùng cả 2
CyberComboBox(
  text: drEdit.bind('ma_kh'),  // ← Binding
  // controller tự động tạo internal
)

// hoặc

CyberComboBox(
  text: drEdit.bind('ma_kh'),  // ← Binding
  controller: externalController,  // ← Override khi cần
)
```

No breaking changes - backward compatible!

---

## 📝 Summary

**CyberComboBox refactored:**

1. ✅ **Internal Controller** - Luôn tồn tại, tự động quản lý
2. ✅ **Binding Support** - Sync 2 chiều với CyberDataRow
3. ✅ **External Controller** - Optional override khi cần
4. ✅ **No Assertion** - Flexible, không ép buộc chọn 1
5. ✅ **ERP Philosophy** - Data row là trung tâm
6. ✅ **Type Safe** - Preserve type khi sync
7. ✅ **No Infinite Loop** - Smart guard với `_isUpdating` flag
8. ✅ **Auto Dispose** - Memory leak safe

**Recommended usage:**

```dart
CyberComboBox(
  text: drEdit.bind('ma_kh'),  // ← Just this!
  dataSource: dtKhachHang,
  valueMember: 'ma_kh',
  displayMember: 'ten_kh',
)
```

Simple. Clean. Powerful. 🚀
