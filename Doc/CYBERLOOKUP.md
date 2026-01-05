# CyberLookup - Internal Controller + Binding Architecture

## 📋 Tổng quan

CyberLookup đã được refactor theo **Internal Controller + Binding** pattern, đúng triết lý ERP/CyberFramework:

- ✅ **KHÔNG cần khai báo controller bên ngoài** cho hầu hết use cases
- ✅ **Binding 2 chiều tự động** với CyberDataRow
- ✅ **Internal controller tự động quản lý state**
- ✅ **API đơn giản, dễ sử dụng**

## 🎯 Cách sử dụng

### 1. Basic Usage - Binding với CyberDataRow (RECOMMENDED)

```dart
// Trong form, có drEdit là CyberDataRow
final drEdit = CyberDataRow();

// Sử dụng CyberLookup với binding
CyberLookup(
  // Binding text value (ma_kh)
  text: drEdit.bind('ma_kh'),
  
  // Binding display value (ten_kh)
  display: drEdit.bind('ten_kh'),
  
  // Lookup parameters
  tbName: 'dmkh',
  strFilter: '',
  displayField: 'ten_kh',
  displayValue: 'ma_kh',
  
  // UI properties
  label: 'Khách hàng',
  hint: 'Chọn khách hàng...',
  icon: Icons.person,
  isCheckEmpty: true,
  
  // Callback khi thay đổi
  onChanged: (value) {
    print('Selected: $value');
  },
  
  // Callback khi rời khỏi field
  onLeaver: (value) {
    // Load related data, validate, etc.
  },
)
```

**Kết quả:**
- Khi user chọn lookup → `drEdit['ma_kh']` và `drEdit['ten_kh']` tự động update
- Khi code update `drEdit['ma_kh']` → UI tự động sync
- **2-way binding hoàn toàn tự động!**

### 2. Binding với nhiều fields khác nhau

```dart
CyberLookup(
  // Text và display có thể bind từ rows khác nhau
  text: drEdit.bind('ma_nv'),      // Bind từ drEdit
  display: drTemp.bind('ten_nv'),   // Bind từ drTemp (nếu cần)
  
  tbName: 'dmnv',
  displayField: 'ten_nv',
  displayValue: 'ma_nv',
  label: 'Nhân viên',
)
```

### 3. Static values (không binding)

```dart
CyberLookup(
  // Static initial values
  text: 'NV001',
  display: 'Nguyễn Văn A',
  
  tbName: 'dmnv',
  displayField: 'ten_nv',
  displayValue: 'ma_nv',
  
  // Nhận giá trị qua callback
  onChanged: (newValue) {
    setState(() {
      selectedEmployeeId = newValue;
    });
  },
)
```

### 4. Dynamic lookup parameters

```dart
// Lookup parameters cũng có thể binding
CyberLookup(
  text: drEdit.bind('ma_sp'),
  display: drEdit.bind('ten_sp'),
  
  // Dynamic table name
  tbName: drConfig.bind('lookup_table'),
  
  // Dynamic filter dựa trên field khác
  strFilter: drEdit.bind('filter_condition'),
  
  displayField: 'ten_sp',
  displayValue: 'ma_sp',
)
```

### 5. Visibility binding

```dart
CyberLookup(
  text: drEdit.bind('ma_kh'),
  display: drEdit.bind('ten_kh'),
  
  // Control visibility via binding
  isVisible: drConfig.bind('show_customer_lookup'),
  
  tbName: 'dmkh',
  displayField: 'ten_kh',
  displayValue: 'ma_kh',
)
```

## 🔧 Advanced Usage - External Controller (OPTIONAL)

Chỉ dùng external controller khi cần:
- Programmatic control phức tạp
- Validation logic đặc biệt
- Share state giữa nhiều widgets

```dart
class MyFormController {
  final lookupController = CyberLookupController(
    initialTextValue: 'KH001',
    initialDisplayValue: 'Khách hàng A',
    tbName: 'dmkh',
    displayFieldName: 'ten_kh',
    valueFieldName: 'ma_kh',
  );
  
  void init() {
    // Bind to data row
    lookupController.bindText(drEdit, 'ma_kh');
    lookupController.bindDisplay(drEdit, 'ten_kh');
  }
  
  void clearCustomer() {
    lookupController.clear();
  }
  
  void setCustomer(String id, String name) {
    lookupController.setValues(
      textValue: id,
      displayValue: name,
    );
  }
}

// Trong widget
CyberLookup(
  controller: lookupController,
  label: 'Khách hàng',
)
```

## 📊 Kiến trúc

```
┌─────────────────────────────────────────────────────────────┐
│                      CyberLookup Widget                      │
│  (UI Layer - Render và handle user interactions)            │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ manages
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              _InternalLookupController                       │
│  (Internal state management - không expose ra ngoài)        │
└────────────┬────────────────────────────┬───────────────────┘
             │                            │
             │ syncs                      │ syncs
             ▼                            ▼
┌────────────────────────┐    ┌────────────────────────────┐
│   Text Binding         │    │   Display Binding          │
│   (CyberDataRow)       │    │   (CyberDataRow)          │
└────────────────────────┘    └────────────────────────────┘
```

## 🔄 Data Flow

### User chọn lookup:
```
1. User tap lookup
2. Show modal bottom sheet
3. User select item
4. _syncToBindings() được gọi
5. Update internal controller
6. Update bound CyberDataRow fields
7. Trigger onChanged callback
8. UI auto rebuild
```

### Code update binding:
```
1. drEdit['ma_kh'] = 'KH002'
2. CyberDataRow notifyListeners()
3. _onTextBindingChanged() được gọi
4. Update internal controller
5. UI auto rebuild
```

## ⚡ Performance

- **Internal controller:** Lightweight, tự động dispose
- **Binding:** Chỉ listen khi có binding expression
- **Anti-loop protection:** `_isInternalUpdate` flag
- **Smart rebuild:** Chỉ rebuild khi cần

## 🎨 UI Customization

```dart
CyberLookup(
  text: drEdit.bind('ma_kh'),
  display: drEdit.bind('ten_kh'),
  
  // Label & hint
  label: 'Khách hàng',
  hint: 'Vui lòng chọn...',
  isShowLabel: true,
  
  // Styles
  labelStyle: TextStyle(fontSize: 14, color: Colors.blue),
  textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
  
  // Icon
  icon: Icons.person,
  
  // Colors
  backgroundColor: Color(0xFFF0F0F0),
  borderColor: Colors.blue,
  
  // Behavior
  enabled: true,
  readOnly: false,
  allowClear: true,
  
  // Validation
  isCheckEmpty: true, // Show required marker
  
  // Lookup config
  tbName: 'dmkh',
  displayField: 'ten_kh',
  displayValue: 'ma_kh',
  strFilter: '',
  lookupPageSize: 50,
)
```

## 🔍 Lookup Modal Features

- ✅ **Virtual scrolling** - Load dữ liệu theo trang
- ✅ **Search** - Debounced search (800ms)
- ✅ **Pull to refresh**
- ✅ **Multi-select mode** - Tự động detect từ API
- ✅ **Current value highlight**
- ✅ **Empty state**

## 📝 Migration Guide

### Từ Controller Mode sang Binding Mode:

**Before:**
```dart
final controller = CyberLookupController();
controller.bindText(drEdit, 'ma_kh');
controller.bindDisplay(drEdit, 'ten_kh');

CyberLookup(
  controller: controller,
  tbName: 'dmkh',
  displayField: 'ten_kh',
  displayValue: 'ma_kh',
)
```

**After:**
```dart
// KHÔNG cần controller nữa!
CyberLookup(
  text: drEdit.bind('ma_kh'),
  display: drEdit.bind('ten_kh'),
  tbName: 'dmkh',
  displayField: 'ten_kh',
  displayValue: 'ma_kh',
)
```

## ✅ Best Practices

1. **Dùng binding mode cho hầu hết use cases**
   ```dart
   text: drEdit.bind('ma_kh')  // ✅ Recommended
   ```

2. **Chỉ dùng controller khi thực sự cần programmatic control**
   ```dart
   final controller = CyberLookupController(); // ⚠️ Only when needed
   ```

3. **Luôn bind cả text và display**
   ```dart
   text: drEdit.bind('ma_kh'),      // Text value
   display: drEdit.bind('ten_kh'),   // Display value
   ```

4. **Dùng onLeaver cho side effects**
   ```dart
   onLeaver: (value) {
     // Load chi tiết khách hàng
     // Validate
     // Update related fields
   }
   ```

5. **Validation với isCheckEmpty**
   ```dart
   isCheckEmpty: true,  // Show required marker
   ```

## 🐛 Troubleshooting

### Binding không hoạt động?
- ✅ Check: Đã dùng `drEdit.bind('field')` chưa?
- ✅ Check: Field name có đúng không?
- ✅ Check: CyberDataRow có mounted không?

### UI không update?
- ✅ Check: CyberDataRow có notifyListeners() không?
- ✅ Check: Widget có mounted không?
- ✅ Check: Anti-loop flag có đang active không?

### Performance issues?
- ✅ Use virtual scrolling (built-in)
- ✅ Increase lookupPageSize nếu cần
- ✅ Optimize strFilter để giảm số records

## 📚 Related

- `CyberDataRow` - Data binding infrastructure
- `CyberBindingExpression` - Binding expression
- `CyberTextField` - Similar binding pattern
- `CyberNumeric` - Similar binding pattern
- `CyberComboBox` - Similar lookup pattern
