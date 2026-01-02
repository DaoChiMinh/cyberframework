# CyberCheckbox - Internal Controller + Binding Architecture

## 📋 Tổng quan

CyberCheckbox đã được refactor theo **Internal Controller + Binding** pattern, đúng triết lý ERP/CyberFramework:

- ✅ **KHÔNG cần khai báo controller bên ngoài** cho hầu hết use cases
- ✅ **Binding 2 chiều tự động** với CyberDataRow
- ✅ **Internal controller tự động quản lý state**
- ✅ **Hỗ trợ nhiều kiểu dữ liệu:** bool, int (0/1), String ("0"/"1", "true"/"false")
- ✅ **Type preservation:** Tự động giữ nguyên kiểu dữ liệu gốc khi update

## 🎯 Cách sử dụng

### 1. Basic Usage - Binding với CyberDataRow (RECOMMENDED)

```dart
// Trong form, có drEdit là CyberDataRow
final drEdit = CyberDataRow({
  'is_active': true,
  'is_paid': 0,           // int: 0/1
  'is_approved': "1",     // String: "0"/"1"
});

// Sử dụng CyberCheckbox với binding
Column(
  children: [
    // Boolean field
    CyberCheckbox(
      text: drEdit.bind('is_active'),
      label: 'Kích hoạt',
    ),
    
    // Integer field (0/1)
    CyberCheckbox(
      text: drEdit.bind('is_paid'),
      label: 'Đã thanh toán',
      activeColor: Colors.green,
    ),
    
    // String field ("0"/"1")
    CyberCheckbox(
      text: drEdit.bind('is_approved'),
      label: 'Đã duyệt',
      onChanged: (value) {
        print('Approved: $value');
      },
    ),
  ],
)
```

**Kết quả:**
- Khi user click checkbox → `drEdit['is_active']` tự động update
- Khi code update `drEdit['is_active']` → UI tự động sync
- **Kiểu dữ liệu được giữ nguyên:** int vẫn là int, String vẫn là String
- **2-way binding hoàn toàn tự động!**

### 2. Type Preservation - Tự động giữ nguyên kiểu

```dart
final drEdit = CyberDataRow({
  'flag_bool': true,        // bool
  'flag_int': 1,            // int
  'flag_string': "1",       // String
});

// ✅ Checkbox tự động detect và preserve type
CyberCheckbox(
  text: drEdit.bind('flag_bool'),
  label: 'Boolean flag',
);
// User check → drEdit['flag_bool'] = true (bool)

CyberCheckbox(
  text: drEdit.bind('flag_int'),
  label: 'Integer flag',
);
// User check → drEdit['flag_int'] = 1 (int)

CyberCheckbox(
  text: drEdit.bind('flag_string'),
  label: 'String flag',
);
// User check → drEdit['flag_string'] = "1" (String)
```

### 3. Static values (không binding)

```dart
bool isChecked = false;

CyberCheckbox(
  text: isChecked,
  label: 'Đồng ý điều khoản',
  onChanged: (value) {
    setState(() {
      isChecked = value;
    });
  },
)
```

### 4. Conditional visibility

```dart
final drEdit = CyberDataRow({
  'is_customer': true,
  'show_customer_options': true,
  'require_invoice': false,
});

Column(
  children: [
    // Master checkbox
    CyberCheckbox(
      text: drEdit.bind('is_customer'),
      label: 'Là khách hàng',
    ),
    
    // Detail checkboxes - chỉ hiện khi is_customer = true
    CyberCheckbox(
      text: drEdit.bind('show_customer_options'),
      label: 'Hiện tùy chọn khách hàng',
      // ✅ Control visibility via binding
      isVisible: drEdit.bind('is_customer'),
    ),
    
    CyberCheckbox(
      text: drEdit.bind('require_invoice'),
      label: 'Yêu cầu hóa đơn',
      isVisible: drEdit.bind('is_customer'),
    ),
  ],
)
```

### 5. With callbacks

```dart
CyberCheckbox(
  text: drEdit.bind('agree_terms'),
  label: 'Tôi đồng ý với điều khoản sử dụng',
  
  onChanged: (value) {
    // Callback ngay khi click
    print('Changed: $value');
  },
  
  onLeaver: (value) {
    // Callback khi blur (giống onLeaver của các control khác)
    if (value == true) {
      // Enable submit button, etc.
    }
  },
)
```

### 6. Styling

```dart
CyberCheckbox(
  text: drEdit.bind('is_vip'),
  label: 'Khách hàng VIP',
  
  // Colors
  activeColor: Colors.amber,
  checkColor: Colors.white,
  
  // Size
  size: 28,
  
  // Label style
  labelStyle: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.amber,
  ),
  
  // Enabled state
  enabled: true,
)
```

### 7. Form validation

```dart
class CustomerForm extends StatefulWidget {
  @override
  State<CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends State<CustomerForm> {
  late CyberDataRow drEdit;

  @override
  void initState() {
    super.initState();
    drEdit = CyberDataRow({
      'agree_terms': false,
      'agree_policy': false,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberCheckbox(
          text: drEdit.bind('agree_terms'),
          label: 'Đồng ý điều khoản sử dụng',
        ),
        
        CyberCheckbox(
          text: drEdit.bind('agree_policy'),
          label: 'Đồng ý chính sách bảo mật',
        ),
        
        ElevatedButton(
          onPressed: _submit,
          child: Text('Đăng ký'),
        ),
      ],
    );
  }

  void _submit() {
    // Validate
    if (!drEdit['agree_terms']) {
      showError('Vui lòng đồng ý điều khoản sử dụng');
      return;
    }
    
    if (!drEdit['agree_policy']) {
      showError('Vui lòng đồng ý chính sách bảo mật');
      return;
    }
    
    // Submit...
  }

  @override
  void dispose() {
    drEdit.dispose();
    super.dispose();
  }
}
```

## 🔧 Advanced Usage - External Controller (OPTIONAL)

Chỉ dùng external controller khi cần:
- Programmatic control phức tạp
- Share state giữa nhiều widgets

```dart
class MyFormController {
  final agreeController = CyberCheckboxController(initialValue: false);
  
  void init() {
    // Bind to data row
    agreeController.bind(drEdit, 'agree_terms');
  }
  
  void acceptAll() {
    agreeController.setValue(true);
  }
  
  void reset() {
    agreeController.setValue(false);
  }
  
  void toggle() {
    agreeController.toggle();
  }
}

// Trong widget
CyberCheckbox(
  controller: agreeController,
  label: 'Đồng ý điều khoản',
)
```

## 📊 Kiến trúc

```
┌─────────────────────────────────────────────────────────────┐
│                    CyberCheckbox Widget                      │
│  (UI Layer - Render và handle user clicks)                  │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ manages
                     ▼
┌─────────────────────────────────────────────────────────────┐
│            _InternalCheckboxController                       │
│  (Internal state management - không expose ra ngoài)        │
└────────────────────┬───────────────────────────────────────┘
                     │
                     │ syncs
                     ▼
┌─────────────────────────────────────────────────────────────┐
│               Value Binding                                  │
│               (CyberDataRow)                                │
│  Type preservation: bool → bool, int → int, String → String │
└─────────────────────────────────────────────────────────────┘
```

## 🔄 Data Flow

### User clicks checkbox:
```
1. User click
2. _toggleValue() được gọi
3. _syncToBinding() update controller và binding
4. Preserve original type (bool/int/String)
5. Trigger onChanged callback
6. UI auto rebuild
```

### Code updates binding:
```
1. drEdit['is_active'] = true
2. CyberDataRow notifyListeners()
3. _onBindingChanged() được gọi
4. Update internal controller
5. UI auto rebuild
```

## 🎨 UI Customization

```dart
CyberCheckbox(
  text: drEdit.bind('is_premium'),
  label: 'Tài khoản Premium',
  
  // iOS-style checkbox (default)
  activeColor: Color(0xFF00D287),  // Checked color
  checkColor: Colors.white,         // Checkmark color
  size: 24,                         // Box size
  
  // Label
  labelStyle: TextStyle(
    fontSize: 16,
    color: Colors.black87,
  ),
  
  // Behavior
  enabled: true,
  isVisible: true,
)
```

## 📝 Type Support

CyberCheckbox hỗ trợ các kiểu dữ liệu:

### Boolean
```dart
drEdit['flag'] = true;  // → Checkbox checked
drEdit['flag'] = false; // → Checkbox unchecked
```

### Integer (0/1)
```dart
drEdit['flag'] = 1;  // → Checkbox checked
drEdit['flag'] = 0;  // → Checkbox unchecked
```

### String ("0"/"1", "true"/"false")
```dart
drEdit['flag'] = "1";     // → Checkbox checked
drEdit['flag'] = "0";     // → Checkbox unchecked
drEdit['flag'] = "true";  // → Checkbox checked
drEdit['flag'] = "false"; // → Checkbox unchecked
```

### Type Preservation

Khi user click checkbox, **kiểu dữ liệu gốc được giữ nguyên**:

```dart
// Original type: int
drEdit['flag'] = 0;
// User check → drEdit['flag'] = 1 (still int!)

// Original type: String
drEdit['flag'] = "0";
// User check → drEdit['flag'] = "1" (still String!)

// Original type: bool
drEdit['flag'] = false;
// User check → drEdit['flag'] = true (still bool!)
```

## ⚡ Performance

- **Internal controller:** Lightweight, tự động dispose
- **Binding:** Chỉ listen khi có binding expression
- **Anti-loop protection:** `_isInternalUpdate` flag
- **Smart rebuild:** Chỉ rebuild khi cần

## 🐛 Troubleshooting

### Checkbox không update khi click?
- ✅ Check: Đã dùng `drEdit.bind('field')` chưa?
- ✅ Check: Field name có đúng không?
- ✅ Check: enabled = true chưa?

### UI không sync với data?
- ✅ Check: CyberDataRow có notifyListeners() không?
- ✅ Check: Widget có mounted không?
- ✅ Check: Anti-loop flag có đang active không?

### Kiểu dữ liệu bị sai?
- ✅ CyberCheckbox tự động preserve type
- ✅ Check: Giá trị ban đầu trong CyberDataRow có đúng type không?

## 📚 Related

- `CyberDataRow` - Data binding infrastructure
- `CyberBindingExpression` - Binding expression
- `CyberTextField` - Similar binding pattern
- `CyberNumeric` - Similar binding pattern
- `CyberLookup` - Similar binding pattern

## 🎓 Best Practices

1. **Dùng binding mode cho hầu hết use cases**
   ```dart
   text: drEdit.bind('is_active')  // ✅ Recommended
   ```

2. **Chỉ dùng controller khi thực sự cần**
   ```dart
   final controller = CyberCheckboxController(); // ⚠️ Only when needed
   ```

3. **Preserve type trong CyberDataRow**
   ```dart
   // ✅ Good - rõ ràng về type
   drEdit['flag_bool'] = true;
   drEdit['flag_int'] = 1;
   drEdit['flag_string'] = "1";
   ```

4. **Dùng onChanged cho immediate feedback**
   ```dart
   onChanged: (value) {
     // Update UI ngay lập tức
   }
   ```

5. **Dùng onLeaver cho validation/side effects**
   ```dart
   onLeaver: (value) {
     // Validate, save, load related data
   }
   ```
