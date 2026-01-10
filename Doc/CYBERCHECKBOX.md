# CyberCheckbox - Checkbox với Data Binding

## Mục Lục
1. [Giới Thiệu](#giới-thiệu)
2. [CyberCheckbox Widget](#cybercheckbox-widget)
3. [CyberCheckboxController](#cybercheckboxcontroller)
4. [Ví Dụ Sử Dụng](#ví-dụ-sử-dụng)
5. [Features](#features)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

---

## Giới Thiệu

`CyberCheckbox` là một checkbox control với **Internal Controller** và hỗ trợ **Data Binding** hai chiều. Widget này được thiết kế theo ERP style, tự động sync với data row mà không cần quản lý state thủ công.

### Đặc Điểm Chính

- ✅ **Internal Controller**: Tự động quản lý state, không cần khai báo controller
- ✅ **Two-Way Binding**: Tự động sync với CyberDataRow
- ✅ **Type Preservation**: Giữ nguyên kiểu dữ liệu (bool, int, String)
- ✅ **Multi-Type Support**: Hỗ trợ bool, int (0/1), String ("0"/"1", "true"/"false")
- ✅ **iOS-Style UI**: Giao diện đẹp, animated, modern
- ✅ **Visibility Binding**: Hỗ trợ binding cho visibility
- ✅ **Optional Controller**: Controller cho advanced use cases

### Import

```dart
import 'package:cyberframework/cyberframework.dart';
```

---

## CyberCheckbox Widget

### Constructor

```dart
const CyberCheckbox({
  super.key,
  this.text,
  this.label,
  this.enabled = true,
  this.labelStyle,
  this.onChanged,
  this.onLeaver,
  this.activeColor,
  this.checkColor,
  this.size,
  this.isVisible = true,
})
```

### Properties

#### Data Binding

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `text` | `dynamic` | Value - có thể binding: `dr.bind('is_active')` | null |
| `onChanged` | `ValueChanged<bool>?` | Callback khi giá trị thay đổi | null |
| `onLeaver` | `Function(dynamic)?` | Callback khi rời khỏi control (blur) | null |

#### UI Properties

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `label` | `String?` | Label text hiển thị bên cạnh checkbox | null |
| `labelStyle` | `TextStyle?` | Style cho label text | null |
| `enabled` | `bool` | Enable/disable checkbox | true |
| `activeColor` | `Color?` | Màu khi checked | Color(0xFF00D287) |
| `checkColor` | `Color?` | Màu của icon check | Colors.white |
| `size` | `double?` | Kích thước checkbox | 24 |
| `isVisible` | `dynamic` | Hiển thị/ẩn widget (có thể binding) | true |

### Value Types Support

Checkbox hỗ trợ nhiều kiểu dữ liệu và tự động preserve type khi update:

```dart
// Boolean (recommended)
row['is_active'] = true;  // → true/false

// Integer (0/1)
row['is_enabled'] = 1;    // → 0/1

// String
row['is_visible'] = "1";  // → "0"/"1"
row['status'] = "true";   // → "true"/"false"
```

---

## CyberCheckboxController

**NOTE**: Controller là **OPTIONAL**. Trong hầu hết trường hợp, bạn **KHÔNG CẦN** dùng controller. Widget đã có internal controller và hỗ trợ binding trực tiếp.

### Khi Nào Dùng Controller?

Chỉ dùng controller khi:
- Cần programmatic control phức tạp
- Cần validation logic đặc biệt
- Cần share state giữa nhiều widgets

### Constructor

```dart
CyberCheckboxController({
  bool initialValue = false,
  bool enabled = true,
})
```

### Properties & Methods

```dart
final controller = CyberCheckboxController(initialValue: true);

// Getters
bool value = controller.value;
bool enabled = controller.enabled;

// Setters
controller.setValue(false);
controller.toggle();
controller.setEnabled(true);

// Binding (advanced)
controller.bind(drEdit, 'is_active');
controller.unbind();
```

---

## Ví Dụ Sử Dụng

### 1. Sử Dụng Cơ Bản (Recommended)

Binding trực tiếp với data row - **KHÔNG CẦN controller**.

```dart
class UserForm extends StatefulWidget {
  @override
  State<UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  final drUser = CyberDataRow();

  @override
  void initState() {
    super.initState();
    
    // Khởi tạo data
    drUser['is_active'] = true;
    drUser['is_admin'] = false;
    drUser['send_email'] = 1; // int type
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Simple binding
        CyberCheckbox(
          text: drUser.bind('is_active'),
          label: 'Kích hoạt tài khoản',
        ),
        
        // With callback
        CyberCheckbox(
          text: drUser.bind('is_admin'),
          label: 'Quyền Admin',
          onChanged: (value) {
            print('Admin changed to: $value');
          },
        ),
        
        // Integer type (0/1)
        CyberCheckbox(
          text: drUser.bind('send_email'),
          label: 'Nhận email thông báo',
        ),
      ],
    );
  }
}
```

### 2. Custom Styling

Tùy chỉnh màu sắc và kích thước.

```dart
CyberCheckbox(
  text: drUser.bind('is_premium'),
  label: 'Tài khoản Premium',
  activeColor: Colors.purple,
  checkColor: Colors.white,
  size: 28,
  labelStyle: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.purple,
  ),
)
```

### 3. Disabled State

Checkbox ở trạng thái readonly.

```dart
class EmployeeForm extends StatefulWidget {
  @override
  State<EmployeeForm> createState() => _EmployeeFormState();
}

class _EmployeeFormState extends State<EmployeeForm> {
  final drEmployee = CyberDataRow();
  bool isEditing = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberCheckbox(
          text: drEmployee.bind('is_permanent'),
          label: 'Nhân viên chính thức',
          enabled: isEditing, // Conditional enable
        ),
        
        SizedBox(height: 16),
        
        CyberButton(
          label: isEditing ? 'Lưu' : 'Chỉnh sửa',
          onClick: () {
            setState(() {
              isEditing = !isEditing;
            });
          },
        ),
      ],
    );
  }
}
```

### 4. Visibility Binding

Hiển thị/ẩn checkbox dựa trên binding.

```dart
class OrderForm extends StatefulWidget {
  @override
  State<OrderForm> createState() => _OrderFormState();
}

class _OrderFormState extends State<OrderForm> {
  final drOrder = CyberDataRow();

  @override
  void initState() {
    super.initState();
    
    drOrder['has_shipping'] = false;
    drOrder['use_gift_wrap'] = false;
    drOrder['add_gift_card'] = false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Master checkbox
        CyberCheckbox(
          text: drOrder.bind('has_shipping'),
          label: 'Giao hàng tận nơi',
        ),
        
        SizedBox(height: 8),
        
        // Child checkboxes - chỉ hiện khi has_shipping = true
        CyberCheckbox(
          text: drOrder.bind('use_gift_wrap'),
          label: 'Gói quà',
          isVisible: drOrder.bind('has_shipping'), // Visibility binding
        ),
        
        CyberCheckbox(
          text: drOrder.bind('add_gift_card'),
          label: 'Kèm thiệp',
          isVisible: drOrder.bind('has_shipping'),
        ),
      ],
    );
  }
}
```

### 5. Form With Multiple Checkboxes

Form phức tạp với nhiều checkboxes và validation.

```dart
class SettingsForm extends StatefulWidget {
  @override
  State<SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<SettingsForm> {
  final drSettings = CyberDataRow();

  @override
  void initState() {
    super.initState();
    
    // Load settings từ DB hoặc SharedPreferences
    drSettings['notifications'] = true;
    drSettings['push_notifications'] = true;
    drSettings['email_notifications'] = false;
    drSettings['sms_notifications'] = false;
    drSettings['dark_mode'] = false;
    drSettings['auto_update'] = true;
  }

  Future<void> saveSettings() async {
    // Validate
    if (drSettings['notifications'] == true) {
      final hasAnyNotification = 
        drSettings['push_notifications'] == true ||
        drSettings['email_notifications'] == true ||
        drSettings['sms_notifications'] == true;
      
      if (!hasAnyNotification) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Lỗi'),
            content: Text('Vui lòng chọn ít nhất một loại thông báo'),
          ),
        );
        return;
      }
    }

    // Save to DB
    await saveToDatabase(drSettings);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã lưu cài đặt')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cài đặt')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text(
            'Thông báo',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          
          CyberCheckbox(
            text: drSettings.bind('notifications'),
            label: 'Bật thông báo',
            activeColor: Colors.blue,
          ),
          
          // Sub-options (chỉ hiện khi notifications = true)
          Padding(
            padding: EdgeInsets.only(left: 32),
            child: Column(
              children: [
                CyberCheckbox(
                  text: drSettings.bind('push_notifications'),
                  label: 'Push notifications',
                  isVisible: drSettings.bind('notifications'),
                ),
                CyberCheckbox(
                  text: drSettings.bind('email_notifications'),
                  label: 'Email notifications',
                  isVisible: drSettings.bind('notifications'),
                ),
                CyberCheckbox(
                  text: drSettings.bind('sms_notifications'),
                  label: 'SMS notifications',
                  isVisible: drSettings.bind('notifications'),
                ),
              ],
            ),
          ),
          
          Divider(height: 32),
          
          Text(
            'Giao diện',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          
          CyberCheckbox(
            text: drSettings.bind('dark_mode'),
            label: 'Chế độ tối',
            activeColor: Colors.grey.shade800,
            onChanged: (value) {
              // Apply dark mode immediately
              applyTheme(value);
            },
          ),
          
          Divider(height: 32),
          
          Text(
            'Cập nhật',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          
          CyberCheckbox(
            text: drSettings.bind('auto_update'),
            label: 'Tự động cập nhật',
            activeColor: Colors.green,
          ),
          
          SizedBox(height: 24),
          
          CyberButton(
            label: 'Lưu cài đặt',
            onClick: saveSettings,
          ),
        ],
      ),
    );
  }
}
```

### 6. Checkbox List với Dynamic Data

Tạo danh sách checkboxes từ data động.

```dart
class PermissionsForm extends StatefulWidget {
  @override
  State<PermissionsForm> createState() => _PermissionsFormState();
}

class _PermissionsFormState extends State<PermissionsForm> {
  final dtPermissions = CyberDataTable(
    columns: ['id', 'name', 'is_granted'],
  );
  
  final drUser = CyberDataRow();

  @override
  void initState() {
    super.initState();
    
    // Load permissions
    dtPermissions.addRow(['read', 'Xem dữ liệu', true]);
    dtPermissions.addRow(['write', 'Chỉnh sửa', false]);
    dtPermissions.addRow(['delete', 'Xóa', false]);
    dtPermissions.addRow(['admin', 'Quản trị', false]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Phân quyền người dùng'),
        
        SizedBox(height: 16),
        
        // Danh sách checkboxes từ data table
        ...List.generate(
          dtPermissions.rowCount,
          (index) {
            final row = dtPermissions[index];
            
            return CyberCheckbox(
              text: row.bind('is_granted'),
              label: row['name'].toString(),
              onChanged: (value) {
                print('${row['id']}: $value');
              },
            );
          },
        ),
        
        SizedBox(height: 24),
        
        CyberButton(
          label: 'Lưu phân quyền',
          onClick: () => savePermissions(),
        ),
      ],
    );
  }
  
  void savePermissions() {
    final granted = <String>[];
    
    for (int i = 0; i < dtPermissions.rowCount; i++) {
      final row = dtPermissions[i];
      if (row['is_granted'] == true) {
        granted.add(row['id'].toString());
      }
    }
    
    print('Granted permissions: $granted');
  }
}
```

### 7. Sử Dụng Controller (Advanced)

Khi cần programmatic control phức tạp.

```dart
class AdvancedForm extends StatefulWidget {
  @override
  State<AdvancedForm> createState() => _AdvancedFormState();
}

class _AdvancedFormState extends State<AdvancedForm> {
  final controller = CyberCheckboxController(initialValue: false);
  final drUser = CyberDataRow();

  @override
  void initState() {
    super.initState();
    
    // Bind controller to data row
    drUser['agree_terms'] = false;
    controller.bind(drUser, 'agree_terms');
    
    // Listen to changes
    controller.addListener(() {
      print('Value changed: ${controller.value}');
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void acceptAll() {
    // Programmatically set value
    controller.setValue(true);
  }

  void toggleValue() {
    controller.toggle();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberCheckbox(
          text: drUser.bind('agree_terms'),
          label: 'Tôi đồng ý với điều khoản sử dụng',
        ),
        
        SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: CyberButton(
                label: 'Chấp nhận tất cả',
                onClick: acceptAll,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: CyberButton(
                label: 'Toggle',
                onClick: toggleValue,
                backgroundColor: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
```

### 8. Extension Helper

Tạo checkbox nhanh từ String.

```dart
// Sử dụng extension
Column(
  children: [
    'Gửi email thông báo'.toCheckbox(
      context,
      value: drSettings.bind('send_email'),
    ),
    
    'Hiển thị trên trang chủ'.toCheckbox(
      context,
      value: drProduct.bind('is_featured'),
      enabled: isEditing,
    ),
  ],
)
```

### 9. Type Preservation Example

Minh họa cách checkbox preserve type.

```dart
class TypePreservationDemo extends StatefulWidget {
  @override
  State<TypePreservationDemo> createState() => _TypePreservationDemoState();
}

class _TypePreservationDemoState extends State<TypePreservationDemo> {
  final drDemo = CyberDataRow();

  @override
  void initState() {
    super.initState();
    
    // Different types
    drDemo['bool_field'] = true;        // bool
    drDemo['int_field'] = 1;            // int
    drDemo['string_field'] = "1";       // String
    drDemo['string_bool'] = "true";     // String (true/false)
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberCheckbox(
          text: drDemo.bind('bool_field'),
          label: 'Boolean field',
          onChanged: (value) {
            print('bool_field: ${drDemo['bool_field']} (${drDemo['bool_field'].runtimeType})');
            // Output: true (bool)
          },
        ),
        
        CyberCheckbox(
          text: drDemo.bind('int_field'),
          label: 'Integer field (0/1)',
          onChanged: (value) {
            print('int_field: ${drDemo['int_field']} (${drDemo['int_field'].runtimeType})');
            // Output: 1 (int)
          },
        ),
        
        CyberCheckbox(
          text: drDemo.bind('string_field'),
          label: 'String field ("0"/"1")',
          onChanged: (value) {
            print('string_field: ${drDemo['string_field']} (${drDemo['string_field'].runtimeType})');
            // Output: "1" (String)
          },
        ),
        
        CyberCheckbox(
          text: drDemo.bind('string_bool'),
          label: 'String boolean',
          onChanged: (value) {
            print('string_bool: ${drDemo['string_bool']} (${drDemo['string_bool'].runtimeType})');
            // Output: "true" (String)
          },
        ),
      ],
    );
  }
}
```

### 10. Terms & Conditions Form

Form điều khoản với validation.

```dart
class TermsForm extends StatefulWidget {
  @override
  State<TermsForm> createState() => _TermsFormState();
}

class _TermsFormState extends State<TermsForm> {
  final drTerms = CyberDataRow();

  @override
  void initState() {
    super.initState();
    
    drTerms['agree_terms'] = false;
    drTerms['agree_privacy'] = false;
    drTerms['agree_newsletter'] = false;
    drTerms['confirm_age'] = false;
  }

  bool canProceed() {
    return drTerms['agree_terms'] == true &&
           drTerms['agree_privacy'] == true &&
           drTerms['confirm_age'] == true;
  }

  void handleSubmit() {
    if (!canProceed()) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Thông báo'),
          content: Text('Vui lòng đồng ý với các điều khoản bắt buộc'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Đóng'),
            ),
          ],
        ),
      );
      return;
    }

    // Proceed with registration
    register();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Điều khoản sử dụng')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vui lòng đọc và đồng ý với các điều khoản sau:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            
            SizedBox(height: 24),
            
            // Required checkboxes
            CyberCheckbox(
              text: drTerms.bind('agree_terms'),
              label: 'Tôi đồng ý với điều khoản sử dụng *',
              activeColor: Colors.blue,
            ),
            
            CyberCheckbox(
              text: drTerms.bind('agree_privacy'),
              label: 'Tôi đồng ý với chính sách bảo mật *',
              activeColor: Colors.blue,
            ),
            
            CyberCheckbox(
              text: drTerms.bind('confirm_age'),
              label: 'Tôi xác nhận đủ 18 tuổi *',
              activeColor: Colors.blue,
            ),
            
            Divider(height: 32),
            
            // Optional checkbox
            CyberCheckbox(
              text: drTerms.bind('agree_newsletter'),
              label: 'Nhận tin tức & khuyến mãi (không bắt buộc)',
              activeColor: Colors.green,
            ),
            
            Spacer(),
            
            // Submit button
            ListenableBuilder(
              listenable: drTerms,
              builder: (context, _) {
                final enabled = canProceed();
                
                return CyberButton(
                  label: 'Tiếp tục',
                  onClick: handleSubmit,
                  isReadOnly: !enabled,
                  backgroundColor: enabled ? Colors.blue : Colors.grey,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Features

### 1. Internal Controller

Widget tự động quản lý state, không cần khai báo controller.

```dart
// ✅ GOOD: Simple binding
CyberCheckbox(
  text: drUser.bind('is_active'),
  label: 'Kích hoạt',
)

// ❌ NOT NEEDED: Controller trong hầu hết cases
// final controller = CyberCheckboxController();
```

### 2. Two-Way Binding

Tự động sync giữa UI và data row.

```dart
// Change trong UI → Update data row
// Change trong data row → Update UI

drUser['is_active'] = true;  // UI tự động update
// User click checkbox → drUser['is_active'] tự động update
```

### 3. Type Preservation

Giữ nguyên kiểu dữ liệu gốc.

```dart
// Boolean
drUser['is_active'] = true;
// → Click checkbox → still bool (true/false)

// Integer
drUser['status'] = 1;
// → Click checkbox → still int (0/1)

// String
drUser['enabled'] = "1";
// → Click checkbox → still String ("0"/"1")
```

### 4. Multi-Type Support

Parse nhiều kiểu về boolean.

```dart
// Boolean
true → checked
false → unchecked

// Integer
1 → checked
0 → unchecked

// String
"1", "true", "TRUE" → checked
"0", "false", "FALSE" → unchecked
```

### 5. iOS-Style UI

Giao diện đẹp, animated, modern.

- Rounded corners (borderRadius = size * 0.25)
- Smooth animation (200ms)
- Check icon khi selected
- Border khi unselected
- Opacity khi disabled

### 6. Visibility Binding

```dart
CyberCheckbox(
  text: drOrder.bind('gift_wrap'),
  label: 'Gói quà',
  isVisible: drOrder.bind('has_shipping'), // Binding
)
```

### 7. Label Click Support

Click vào label cũng toggle checkbox.

```dart
// InkWell bao cả checkbox + label
CyberCheckbox(
  text: value,
  label: 'Click anywhere to toggle',
)
```

---

## Best Practices

### 1. Sử Dụng Binding (Recommended)

```dart
// ✅ GOOD: Simple, clean, auto-sync
CyberCheckbox(
  text: drUser.bind('is_active'),
  label: 'Kích hoạt',
)

// ❌ BAD: Manual state management
bool isActive = false;
CyberCheckbox(
  text: isActive,
  onChanged: (value) {
    setState(() {
      isActive = value;
      drUser['is_active'] = value;
    });
  },
)
```

### 2. Type Selection

```dart
// ✅ GOOD: Boolean (recommended)
drUser['is_active'] = true;

// ✅ ACCEPTABLE: Integer (database compatibility)
drUser['is_enabled'] = 1;

// ⚠️ CAREFUL: String (only if necessary)
drUser['status'] = "1";
```

### 3. Label Text

```dart
// ✅ GOOD: Clear, concise
CyberCheckbox(label: 'Nhận email thông báo', ...)

// ❌ BAD: Too long
CyberCheckbox(
  label: 'Bạn có muốn nhận email thông báo về các sản phẩm mới không?',
  ...
)
```

### 4. Validation

```dart
// ✅ GOOD: Validate before submit
void submit() {
  if (drTerms['agree_terms'] != true) {
    showError('Vui lòng đồng ý điều khoản');
    return;
  }
  
  // Proceed
}

// ❌ BAD: No validation
void submit() {
  // Assumes user checked everything
}
```

### 5. Callbacks

```dart
// ✅ GOOD: Use callbacks for side effects
CyberCheckbox(
  text: drSettings.bind('dark_mode'),
  label: 'Chế độ tối',
  onChanged: (value) {
    applyTheme(value); // Apply immediately
  },
)

// ✅ GOOD: Use onLeaver for blur actions
CyberCheckbox(
  text: drForm.bind('completed'),
  onLeaver: (value) {
    saveToDatabase(); // Save when focus lost
  },
)
```

---

## Troubleshooting

### Checkbox không update khi data row thay đổi

**Nguyên nhân:** Không dùng binding

**Giải pháp:**
```dart
// ✅ CORRECT: Dùng binding
CyberCheckbox(
  text: drUser.bind('is_active'),
  ...
)

// ❌ WRONG: Direct value
CyberCheckbox(
  text: drUser['is_active'], // Won't update
  ...
)
```

### Data row không update khi click checkbox

**Nguyên nhân:** Sai binding expression

**Giải pháp:**
```dart
// ✅ CORRECT
final drUser = CyberDataRow();
CyberCheckbox(
  text: drUser.bind('is_active'),
  ...
)

// ❌ WRONG: Typo in field name
CyberCheckbox(
  text: drUser.bind('isActive'), // Wrong field name
  ...
)
```

### Type không được preserve

**Nguyên nhân:** Field chưa được khởi tạo với đúng type

**Giải pháp:**
```dart
// ✅ CORRECT: Khởi tạo đúng type
drUser['int_field'] = 1;    // int
drUser['bool_field'] = true; // bool

// ❌ WRONG: Khởi tạo sai type
drUser['int_field'] = "1";  // String → sẽ preserve String
```

### Visibility binding không hoạt động

**Nguyên nhân:** Không dùng binding cho isVisible

**Giải pháp:**
```dart
// ✅ CORRECT
CyberCheckbox(
  isVisible: drRow.bind('is_visible'),
  ...
)

// ❌ WRONG
CyberCheckbox(
  isVisible: drRow['is_visible'], // Won't update
  ...
)
```

### Checkbox bị rebuild liên tục

**Nguyên nhân:** Tạo binding mới trong build method

**Giải pháp:**
```dart
// ✅ CORRECT: Binding ngoài build
final drUser = CyberDataRow();

@override
Widget build(BuildContext context) {
  return CyberCheckbox(
    text: drUser.bind('is_active'),
    ...
  );
}

// ❌ WRONG: Tạo mới mỗi lần build
@override
Widget build(BuildContext context) {
  final drUser = CyberDataRow(); // New instance every build!
  return CyberCheckbox(...);
}
```

---

## Tips & Tricks

### 1. Master-Child Checkboxes

```dart
// Master checkbox controls children
CyberCheckbox(
  text: drSettings.bind('notifications'),
  label: 'Bật thông báo',
  onChanged: (value) {
    if (!value) {
      // Uncheck all children
      drSettings['email_notifications'] = false;
      drSettings['push_notifications'] = false;
    }
  },
)

// Children
CyberCheckbox(
  text: drSettings.bind('email_notifications'),
  isVisible: drSettings.bind('notifications'),
  ...
)
```

### 2. Conditional Styling

```dart
ListenableBuilder(
  listenable: drUser,
  builder: (context, _) {
    final isActive = drUser['is_active'] == true;
    
    return CyberCheckbox(
      text: drUser.bind('is_active'),
      label: 'Kích hoạt',
      activeColor: isActive ? Colors.green : Colors.grey,
    );
  },
)
```

### 3. Checkbox Group Helper

```dart
class CheckboxGroup extends StatelessWidget {
  final List<String> fields;
  final List<String> labels;
  final CyberDataRow dataRow;
  
  const CheckboxGroup({
    required this.fields,
    required this.labels,
    required this.dataRow,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        fields.length,
        (index) => CyberCheckbox(
          text: dataRow.bind(fields[index]),
          label: labels[index],
        ),
      ),
    );
  }
}

// Usage
CheckboxGroup(
  dataRow: drPermissions,
  fields: ['read', 'write', 'delete'],
  labels: ['Xem', 'Sửa', 'Xóa'],
)
```

### 4. Select All/None

```dart
class SelectableList extends StatefulWidget {
  @override
  State<SelectableList> createState() => _SelectableListState();
}

class _SelectableListState extends State<SelectableList> {
  final dtItems = CyberDataTable(columns: ['name', 'selected']);

  void selectAll() {
    for (int i = 0; i < dtItems.rowCount; i++) {
      dtItems[i]['selected'] = true;
    }
  }

  void selectNone() {
    for (int i = 0; i < dtItems.rowCount; i++) {
      dtItems[i]['selected'] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            TextButton(
              onPressed: selectAll,
              child: Text('Chọn tất cả'),
            ),
            TextButton(
              onPressed: selectNone,
              child: Text('Bỏ chọn'),
            ),
          ],
        ),
        
        ...List.generate(
          dtItems.rowCount,
          (i) => CyberCheckbox(
            text: dtItems[i].bind('selected'),
            label: dtItems[i]['name'].toString(),
          ),
        ),
      ],
    );
  }
}
```

---

## Performance Tips

1. **Reuse DataRow**: Tạo CyberDataRow một lần, reuse nhiều checkboxes
2. **Avoid Rebuild**: Đặt binding ngoài build method
3. **Use const**: Dùng const cho labels, styles khi có thể
4. **Batch Updates**: Update nhiều fields cùng lúc thay vì từng cái một

---

## Version History

### 1.0.0
- Initial release
- Internal controller
- Two-way binding support
- Type preservation
- Multi-type support (bool, int, String)
- iOS-style UI
- Visibility binding

---

## License

MIT License - CyberFramework
