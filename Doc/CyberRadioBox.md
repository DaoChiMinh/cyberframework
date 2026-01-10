# CyberRadioBox/CyberRadioGroup - Radio Button với Data Binding

## Mục Lục
1. [Giới Thiệu](#giới-thiệu)
2. [CyberRadioBox](#cyberradiobox)
3. [CyberRadioGroup](#cyberradiogroup)
4. [Ví Dụ Sử Dụng](#ví-dụ-sử-dụng)
5. [Features](#features)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

---

## Giới Thiệu

`CyberRadioBox` và `CyberRadioGroup` là radio button widgets với **Data Binding** hai chiều, **iOS-style design**, và **Type Preservation**. Hai widgets này giúp tạo radio button groups dễ dàng và linh hoạt.

### Đặc Điểm Chính

- ✅ **Two-Way Binding**: Tự động sync với CyberDataRow
- ✅ **iOS-Style Design**: Giống native iOS radio buttons
- ✅ **Type Preservation**: Giữ nguyên kiểu dữ liệu (String, int, etc.)
- ✅ **2 Variants**: Individual (CyberRadioBox) và Group (CyberRadioGroup)
- ✅ **Flexible Layout**: Vertical hoặc Horizontal
- ✅ **Customizable**: Colors, sizes, styles
- ✅ **Dynamic Values**: Values/displays có thể binding

### Import

```dart
import 'package:cyberframework/cyberframework.dart';
```

---

## CyberRadioBox

### Constructor

```dart
const CyberRadioBox({
  super.key,
  required this.text,
  required this.group,
  required this.value,
  this.label,
  this.labelStyle,
  this.enabled = true,
  this.isVisible = true,
  this.onChanged,
  this.onLeaver,
  this.activeColor,
  this.fillColor,
  this.size,
})
```

### Properties

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `text` | `dynamic` | Binding đến selected value | Required |
| `group` | `dynamic` | Tên group (có thể binding) | Required |
| `value` | `dynamic` | Giá trị của radio này (có thể binding) | Required |
| `label` | `String?` | Label hiển thị | null |
| `labelStyle` | `TextStyle?` | Style cho label | null |
| `enabled` | `bool` | Enable/disable | true |
| `isVisible` | `dynamic` | Hiển thị/ẩn (có thể binding) | true |
| `onChanged` | `ValueChanged<dynamic>?` | Callback khi thay đổi | null |
| `onLeaver` | `Function(dynamic)?` | Callback khi rời khỏi | null |
| `activeColor` | `Color?` | Màu khi selected | Color(0xFF007AFF) |
| `fillColor` | `Color?` | Màu fill | Colors.white |
| `size` | `double?` | Kích thước | 24 |

---

## CyberRadioGroup

Widget tiện lợi hơn để tạo radio group với values/displays string.

### Constructor

```dart
const CyberRadioGroup({
  super.key,
  required this.text,
  required this.values,
  required this.displays,
  this.label,
  required this.group,
  this.direction = Axis.vertical,
  this.spacing = 8,
  this.enabled = true,
  this.onChanged,
  this.onLeaver,
  this.activeColor,
  this.fillColor,
  this.size,
  this.labelStyle,
  this.itemLabelStyle,
  this.isShowLabel = true,
  this.isVisible = true,
})
```

### Properties

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `text` | `dynamic` | Binding đến selected value | Required |
| `values` | `dynamic` | Values phân cách bởi ";" (có thể binding) | Required |
| `displays` | `dynamic` | Labels phân cách bởi ";" (có thể binding) | Required |
| `label` | `String?` | Label cho toàn bộ group | null |
| `group` | `String` | Tên group | Required |
| `direction` | `Axis` | Vertical hoặc Horizontal | vertical |
| `spacing` | `double` | Khoảng cách giữa các radio | 8 |
| `enabled` | `bool` | Enable/disable | true |
| `onChanged` | `ValueChanged<dynamic>?` | Callback khi thay đổi | null |
| `onLeaver` | `Function(dynamic)?` | Callback khi rời khỏi | null |
| `activeColor` | `Color?` | Màu khi selected | Color(0xFF007AFF) |
| `fillColor` | `Color?` | Màu fill | Colors.white |
| `size` | `double?` | Kích thước | 24 |
| `labelStyle` | `TextStyle?` | Style cho group label | null |
| `itemLabelStyle` | `TextStyle?` | Style cho item labels | null |
| `isShowLabel` | `bool` | Hiển thị group label | true |
| `isVisible` | `dynamic` | Hiển thị/ẩn (có thể binding) | true |

---

## Ví Dụ Sử Dụng

### 1. Sử Dụng CyberRadioGroup (Recommended)

Simple gender selection.

```dart
class GenderSelector extends StatefulWidget {
  @override
  State<GenderSelector> createState() => _GenderSelectorState();
}

class _GenderSelectorState extends State<GenderSelector> {
  final drUser = CyberDataRow();

  @override
  void initState() {
    super.initState();
    
    // Initialize with default value
    drUser['gender'] = '0';  // Male
  }

  @override
  Widget build(BuildContext context) {
    return CyberRadioGroup(
      text: drUser.bind('gender'),
      
      // Values (what gets stored)
      values: '0;1',
      
      // Displays (what user sees)
      displays: 'Nam;Nữ',
      
      label: 'Giới tính',
      group: 'gender_group',
      
      onChanged: (value) {
        print('Gender selected: $value');
      },
    );
  }
}
```

### 2. Horizontal Layout

Radio buttons in a row.

```dart
CyberRadioGroup(
  text: drOrder.bind('payment_method'),
  values: 'cash;card;transfer',
  displays: 'Tiền mặt;Thẻ;Chuyển khoản',
  label: 'Phương thức thanh toán',
  group: 'payment_group',
  
  direction: Axis.horizontal,  // Horizontal layout
  spacing: 16,
)
```

### 3. Integer Values

Using integer values.

```dart
class StatusSelector extends StatefulWidget {
  @override
  State<StatusSelector> createState() => _StatusSelectorState();
}

class _StatusSelectorState extends State<StatusSelector> {
  final drOrder = CyberDataRow();

  @override
  void initState() {
    super.initState();
    
    // Integer value
    drOrder['status'] = 0;  // Pending
  }

  @override
  Widget build(BuildContext context) {
    return CyberRadioGroup(
      text: drOrder.bind('status'),
      
      // Integer values as strings
      values: '0;1;2',
      displays: 'Chờ xử lý;Đang xử lý;Hoàn thành',
      
      label: 'Trạng thái',
      group: 'status_group',
    );
  }
}
```

### 4. Using Individual CyberRadioBox

Manual radio buttons.

```dart
class ManualRadioButtons extends StatefulWidget {
  @override
  State<ManualRadioButtons> createState() => _ManualRadioButtonsState();
}

class _ManualRadioButtonsState extends State<ManualRadioButtons> {
  final drSettings = CyberDataRow();

  @override
  void initState() {
    super.initState();
    drSettings['theme'] = 'light';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chế độ giao diện',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        
        CyberRadioBox(
          text: drSettings.bind('theme'),
          group: 'theme_group',
          value: 'light',
          label: 'Sáng',
        ),
        
        SizedBox(height: 8),
        
        CyberRadioBox(
          text: drSettings.bind('theme'),
          group: 'theme_group',
          value: 'dark',
          label: 'Tối',
        ),
        
        SizedBox(height: 8),
        
        CyberRadioBox(
          text: drSettings.bind('theme'),
          group: 'theme_group',
          value: 'auto',
          label: 'Tự động',
        ),
      ],
    );
  }
}
```

### 5. Dynamic Values (Binding)

Values và displays có thể binding.

```dart
class DynamicRadioGroup extends StatefulWidget {
  @override
  State<DynamicRadioGroup> createState() => _DynamicRadioGroupState();
}

class _DynamicRadioGroupState extends State<DynamicRadioGroup> {
  final drForm = CyberDataRow();
  final drConfig = CyberDataRow();

  @override
  void initState() {
    super.initState();
    
    drForm['selected'] = 'A';
    
    // Dynamic values from config
    drConfig['values'] = 'A;B;C';
    drConfig['displays'] = 'Option A;Option B;Option C';
  }

  @override
  Widget build(BuildContext context) {
    return CyberRadioGroup(
      text: drForm.bind('selected'),
      
      // Binding to dynamic values
      values: drConfig.bind('values'),
      displays: drConfig.bind('displays'),
      
      label: 'Chọn một tùy chọn',
      group: 'dynamic_group',
    );
  }
}
```

### 6. Custom Colors

Tùy chỉnh màu sắc.

```dart
CyberRadioGroup(
  text: drSettings.bind('priority'),
  values: 'low;medium;high',
  displays: 'Thấp;Trung bình;Cao',
  label: 'Độ ưu tiên',
  group: 'priority_group',
  
  // Custom colors
  activeColor: Colors.red,
  size: 28,
)
```

### 7. Disabled State

Disable radio buttons.

```dart
class ConditionalRadio extends StatefulWidget {
  @override
  State<ConditionalRadio> createState() => _ConditionalRadioState();
}

class _ConditionalRadioState extends State<ConditionalRadio> {
  final drOrder = CyberDataRow();
  bool _canChangePayment = true;

  @override
  void initState() {
    super.initState();
    drOrder['payment'] = 'cash';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberRadioGroup(
          text: drOrder.bind('payment'),
          values: 'cash;card',
          displays: 'Tiền mặt;Thẻ',
          label: 'Thanh toán',
          group: 'payment_group',
          
          enabled: _canChangePayment,  // Conditional enable
        ),
        
        SizedBox(height: 16),
        
        CheckboxListTile(
          title: Text('Cho phép thay đổi'),
          value: _canChangePayment,
          onChanged: (value) {
            setState(() {
              _canChangePayment = value ?? false;
            });
          },
        ),
      ],
    );
  }
}
```

### 8. With Validation

Validation cho radio group.

```dart
class ValidatedRadio extends StatefulWidget {
  @override
  State<ValidatedRadio> createState() => _ValidatedRadioState();
}

class _ValidatedRadioState extends State<ValidatedRadio> {
  final drOrder = CyberDataRow();
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    drOrder['shipping'] = '';  // No selection
  }

  bool validate() {
    if (drOrder['shipping'].toString().isEmpty) {
      setState(() {
        _errorMessage = 'Vui lòng chọn phương thức vận chuyển';
      });
      return false;
    }
    
    setState(() {
      _errorMessage = null;
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CyberRadioGroup(
          text: drOrder.bind('shipping'),
          values: 'standard;express;overnight',
          displays: 'Tiêu chuẩn;Nhanh;Hỏa tốc',
          label: 'Vận chuyển',
          group: 'shipping_group',
        ),
        
        if (_errorMessage != null)
          Padding(
            padding: EdgeInsets.only(left: 4, top: 8),
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
        
        SizedBox(height: 16),
        
        CyberButton(
          label: 'Tiếp tục',
          onClick: () {
            if (validate()) {
              // Proceed
            }
          },
        ),
      ],
    );
  }
}
```

### 9. Multi-Group (Different Groups)

Multiple radio groups on same screen.

```dart
class MultipleGroups extends StatefulWidget {
  @override
  State<MultipleGroups> createState() => _MultipleGroupsState();
}

class _MultipleGroupsState extends State<MultipleGroups> {
  final drForm = CyberDataRow();

  @override
  void initState() {
    super.initState();
    drForm['gender'] = 'male';
    drForm['age_range'] = '18-25';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Group 1: Gender
        CyberRadioGroup(
          text: drForm.bind('gender'),
          values: 'male;female;other',
          displays: 'Nam;Nữ;Khác',
          label: 'Giới tính',
          group: 'gender_group',  // Unique group name
        ),
        
        SizedBox(height: 24),
        
        // Group 2: Age Range
        CyberRadioGroup(
          text: drForm.bind('age_range'),
          values: '18-25;26-35;36-45;46+',
          displays: '18-25;26-35;36-45;Trên 46',
          label: 'Độ tuổi',
          group: 'age_group',  // Different group name
        ),
      ],
    );
  }
}
```

### 10. Form Example

Complete form với radio buttons.

```dart
class RegistrationForm extends StatefulWidget {
  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final drUser = CyberDataRow();

  @override
  void initState() {
    super.initState();
    
    drUser['name'] = '';
    drUser['gender'] = '0';
    drUser['subscription'] = 'free';
  }

  void submit() {
    print('Name: ${drUser['name']}');
    print('Gender: ${drUser['gender']}');
    print('Subscription: ${drUser['subscription']}');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CyberText(
          text: drUser.bind('name'),
          label: 'Họ tên',
        ),
        
        SizedBox(height: 16),
        
        CyberRadioGroup(
          text: drUser.bind('gender'),
          values: '0;1',
          displays: 'Nam;Nữ',
          label: 'Giới tính',
          group: 'gender_group',
        ),
        
        SizedBox(height: 16),
        
        CyberRadioGroup(
          text: drUser.bind('subscription'),
          values: 'free;premium;enterprise',
          displays: 'Miễn phí;Premium;Doanh nghiệp',
          label: 'Gói dịch vụ',
          group: 'subscription_group',
          direction: Axis.horizontal,
        ),
        
        SizedBox(height: 24),
        
        CyberButton(
          label: 'Đăng ký',
          onClick: submit,
        ),
      ],
    );
  }
}
```

---

## Features

### 1. Two-Way Binding

Tự động sync với CyberDataRow:

```dart
CyberRadioGroup(
  text: drUser.bind('gender'),
  ...
)

// When user selects:
// drUser['gender'] automatically updated
```

### 2. Type Preservation

Giữ nguyên kiểu dữ liệu:

```dart
// String values
drUser['gender'] = '0';  // Stays String

// Integer values
drUser['status'] = 0;    // Stays int
```

### 3. iOS-Style Design

```dart
// Circular radio button
// Animated selection
// iOS blue color (#007AFF)
```

### 4. Flexible Values

```dart
// Static
values: '0;1;2'

// Binding
values: drConfig.bind('available_values')
```

### 5. Layout Options

```dart
// Vertical (default)
direction: Axis.vertical

// Horizontal
direction: Axis.horizontal
```

---

## Best Practices

### 1. Use CyberRadioGroup

```dart
// ✅ GOOD: Simple and clean
CyberRadioGroup(
  text: dr.bind('field'),
  values: 'A;B;C',
  displays: 'Option A;Option B;Option C',
  group: 'my_group',
)

// ❌ BAD: Manual radio boxes
Column(
  children: [
    CyberRadioBox(...),
    CyberRadioBox(...),
    CyberRadioBox(...),
  ],
)
```

### 2. Match Values and Displays

```dart
// ✅ GOOD: Same count
values: 'A;B;C',
displays: 'Option A;Option B;Option C',  // 3 items

// ❌ BAD: Different count
values: 'A;B;C',
displays: 'Option A;Option B',  // Only 2 items!
```

### 3. Unique Group Names

```dart
// ✅ GOOD: Unique names
CyberRadioGroup(group: 'gender_group')
CyberRadioGroup(group: 'status_group')

// ❌ BAD: Same names
CyberRadioGroup(group: 'group')
CyberRadioGroup(group: 'group')  // Conflict!
```

### 4. Initialize Values

```dart
// ✅ GOOD: Set initial value
drUser['gender'] = '0';
CyberRadioGroup(...)

// ❌ BAD: No initial value
CyberRadioGroup(...)  // Nothing selected
```

### 5. Appropriate Layout

```dart
// ✅ GOOD: Few options → Horizontal
CyberRadioGroup(
  values: 'yes;no',
  direction: Axis.horizontal,
)

// ✅ GOOD: Many options → Vertical
CyberRadioGroup(
  values: 'A;B;C;D;E;F',
  direction: Axis.vertical,
)

// ❌ BAD: Many options horizontal
CyberRadioGroup(
  values: 'A;B;C;D;E;F',
  direction: Axis.horizontal,  // Too wide!
)
```

---

## Troubleshooting

### Giá trị không update

**Nguyên nhân:** Không dùng binding

**Giải pháp:**
```dart
// ✅ CORRECT
CyberRadioGroup(
  text: drUser.bind('gender'),
)

// ❌ WRONG
CyberRadioGroup(
  text: drUser['gender'],
)
```

### Không radio nào được chọn

**Nguyên nhân:** Initial value không match

**Giải pháp:**
```dart
// ✅ CORRECT: Value matches
drUser['gender'] = '0';  // Matches first value
CyberRadioGroup(values: '0;1')

// ❌ WRONG: No match
drUser['gender'] = 'male';  // Doesn't match
CyberRadioGroup(values: '0;1')
```

### Nhiều radio được chọn

**Nguyên nhân:** Duplicate group names

**Giải pháp:**
```dart
// ✅ CORRECT: Unique groups
CyberRadioGroup(group: 'gender')
CyberRadioGroup(group: 'status')

// ❌ WRONG: Same group
CyberRadioGroup(group: 'group')
CyberRadioGroup(group: 'group')
```

### Type mismatch error

**Nguyên nhân:** Value type khác field type

**Giải pháp:**
```dart
// ✅ CORRECT: Match types
drUser['status'] = 0;  // int
CyberRadioGroup(values: '0;1')  // Converts to int

// Better: Initialize with correct type
drUser['gender'] = '';  // String
CyberRadioGroup(values: 'A;B')  // String
```

### Displays không hiển thị

**Nguyên nhân:** Sai format

**Giải pháp:**
```dart
// ✅ CORRECT: Semicolon separator
displays: 'A;B;C'

// ❌ WRONG: Other separators
displays: 'A,B,C'  // Comma
displays: 'A B C'  // Space
```

---

## Tips & Tricks

### 1. Yes/No Questions

```dart
CyberRadioGroup(
  text: dr.bind('agreed'),
  values: 'yes;no',
  displays: 'Đồng ý;Không đồng ý',
  group: 'agree_group',
  direction: Axis.horizontal,
)
```

### 2. Priority Levels

```dart
CyberRadioGroup(
  text: dr.bind('priority'),
  values: '1;2;3',
  displays: 'Thấp;Trung bình;Cao',
  group: 'priority_group',
  activeColor: Colors.red,
)
```

### 3. Clear Selection

```dart
void clearSelection() {
  drUser['gender'] = '';  // Clear
}
```

### 4. Conditional Options

```dart
String getValues() {
  if (isPremium) {
    return 'basic;advanced;premium';
  } else {
    return 'basic;advanced';
  }
}

CyberRadioGroup(
  values: getValues(),
  ...
)
```

### 5. Get Selected Label

```dart
String getSelectedLabel() {
  final value = drUser['gender'];
  final values = '0;1'.split(';');
  final displays = 'Nam;Nữ'.split(';');
  
  final index = values.indexOf(value.toString());
  return index >= 0 ? displays[index] : '';
}
```

---

## Performance Tips

1. **Reuse DataRow**: Don't create new rows unnecessarily
2. **Static Values**: Prefer static strings over dynamic
3. **Group Names**: Use constants for group names
4. **Minimal Rebuilds**: Avoid setState in onChanged if possible
5. **ListenableBuilder**: Widget already optimized with ListenableBuilder

---

## Common Patterns

### Gender Selection

```dart
values: '0;1;2',
displays: 'Nam;Nữ;Khác',
group: 'gender_group',
```

### Yes/No

```dart
values: 'yes;no',
displays: 'Có;Không',
group: 'confirm_group',
direction: Axis.horizontal,
```

### Status

```dart
values: '0;1;2',
displays: 'Chờ;Đang xử lý;Hoàn thành',
group: 'status_group',
```

### Priority

```dart
values: 'low;medium;high',
displays: 'Thấp;Trung bình;Cao',
group: 'priority_group',
```

---

## Version History

### 1.0.0
- Initial release
- CyberRadioBox for individual radios
- CyberRadioGroup for groups
- Two-way binding
- Type preservation
- iOS-style design
- Vertical/Horizontal layouts
- Dynamic values/displays binding
- Custom colors and sizes

---

## License

MIT License - CyberFramework
