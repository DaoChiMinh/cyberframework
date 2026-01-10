# CyberText - Text Input với Data Binding

## Mục Lục
1. [Giới Thiệu](#giới-thiệu)
2. [CyberText Widget](#cybertext-widget)
3. [CyberTextController](#cybertextcontroller)
4. [Ví Dụ Sử Dụng](#ví-dụ-sử-dụng)
5. [Features](#features)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

---

## Giới Thiệu

`CyberText` là text input widget với **Internal Controller**, **Data Binding** hai chiều, và **String Formatting**. Widget này là thành phần cơ bản nhất trong CyberFramework cho việc nhập liệu.

### Đặc Điểm Chính

- ✅ **Internal Controller**: Tự động quản lý state
- ✅ **Two-Way Binding**: Tự động sync với CyberDataRow
- ✅ **String Formatting**: Format với placeholder {0}
- ✅ **Password Mode**: Ẩn/hiện mật khẩu
- ✅ **Validation**: Required field với dấu *
- ✅ **Icon Support**: Prefix icon từ code
- ✅ **Customizable**: Border, colors, styles

### Import

```dart
import 'package:cyberframework/cyberframework.dart';
```

---

## CyberText Widget

### Constructor

```dart
const CyberText({
  super.key,
  this.text,
  this.onChanged,
  this.controller,
  this.isCheckEmpty = false,
  this.format,
  this.showFormatInField = false,
  this.label,
  this.hint,
  this.prefixIcon,
  this.borderSize = 1,
  this.borderRadius,
  this.keyboardType,
  this.inputFormatters,
  this.maxLines = 1,
  this.maxLength,
  this.enabled = true,
  this.isVisible = true,
  this.style,
  this.decoration,
  this.isPassword = false,
  this.isShowLabel = true,
  this.isHintEmpty = false,
  this.backgroundColor,
  this.borderColor = Colors.transparent,
  this.focusColor,
  this.labelStyle,
  this.onLeaver,
})
```

### Properties

#### Data Binding

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `text` | `dynamic` | Binding hoặc static value | null |
| `onChanged` | `ValueChanged<String>?` | Callback khi text thay đổi (static mode) | null |
| `controller` | `CyberTextController?` | External controller (optional) | null |

⚠️ **KHÔNG dùng cả text VÀ controller cùng lúc**

#### Validation & Format

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `isCheckEmpty` | `bool` | Required field (hiển thị *) | false |
| `format` | `String?` | Format string với {0} placeholder | null |
| `showFormatInField` | `bool` | Hiển thị format trong field | false |

**Format Examples:**
```dart
format: "Mã KH: {0}"         // → "Mã KH: ABC123"
format: "Tel: ({0})"         // → "Tel: (0123456789)"
format: "https://{0}.com"    // → "https://example.com"
```

#### Display

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `label` | `String?` | Label phía trên | null |
| `hint` | `String?` | Hint text | null |
| `prefixIcon` | `String?` | Icon code (hex) | null |
| `isShowLabel` | `bool` | Hiển thị label | true |
| `isHintEmpty` | `bool` | Cho phép hint rỗng | false |

#### Input Configuration

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `keyboardType` | `TextInputType?` | Loại bàn phím | null |
| `inputFormatters` | `List<TextInputFormatter>?` | Input formatters | null |
| `maxLines` | `int?` | Số dòng tối đa | 1 |
| `maxLength` | `int?` | Độ dài tối đa | null |
| `isPassword` | `bool` | Password field | false |

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
| `isVisible` | `bool` | Hiển thị/ẩn | true |

#### Callbacks

| Property | Type | Mô Tả |
|----------|------|-------|
| `onLeaver` | `VoidCallback?` | Khi rời khỏi field |

---

## CyberTextController

**NOTE**: Controller là **OPTIONAL**. Không cần trong hầu hết trường hợp.

### Properties & Methods

```dart
final controller = CyberTextController(
  initialValue: 'Hello',
  isCheckEmpty: true,
  format: 'Name: {0}',
);

// Properties
String? value = controller.value;
String? displayValue = controller.displayValue;
String? helperText = controller.helperText;
bool enabled = controller.enabled;
bool isValid = controller.isValid;

// Set value
controller.setValue('World');

// State
controller.setEnabled(true);
controller.setCheckEmpty(true);
controller.setFormat('ID: {0}');

// Clear
controller.clear();

// Validate
bool isValid = controller.validate();

// Binding
controller.bind(drUser, 'name');
controller.unbind();
```

---

## Ví Dụ Sử Dụng

### 1. Sử Dụng Cơ Bản (Recommended)

Simple text input with binding.

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
    
    drUser['name'] = '';
    drUser['email'] = '';
    drUser['phone'] = '';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberText(
          text: drUser.bind('name'),
          label: 'Họ tên',
          hint: 'Nhập họ tên',
        ),
        
        SizedBox(height: 16),
        
        CyberText(
          text: drUser.bind('email'),
          label: 'Email',
          keyboardType: TextInputType.emailAddress,
        ),
        
        SizedBox(height: 16),
        
        CyberText(
          text: drUser.bind('phone'),
          label: 'Số điện thoại',
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }
}
```

### 2. Password Field

Password input với show/hide.

```dart
CyberText(
  text: drAuth.bind('password'),
  label: 'Mật khẩu',
  isPassword: true,  // Show/hide button
  isCheckEmpty: true,  // Required
)
```

### 3. With Format String

Format với placeholder.

```dart
class FormattedInput extends StatefulWidget {
  @override
  State<FormattedInput> createState() => _FormattedInputState();
}

class _FormattedInputState extends State<FormattedInput> {
  final drCustomer = CyberDataRow();

  @override
  void initState() {
    super.initState();
    drCustomer['code'] = 'ABC123';
    drCustomer['website'] = 'example';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Format in field
        CyberText(
          text: drCustomer.bind('code'),
          label: 'Mã khách hàng',
          format: 'KH-{0}',
          showFormatInField: true,  // Display: KH-ABC123
        ),
        
        SizedBox(height: 16),
        
        // Format as helper text
        CyberText(
          text: drCustomer.bind('website'),
          label: 'Website',
          format: 'https://{0}.com',
          showFormatInField: false,  // Helper: https://example.com
        ),
      ],
    );
  }
}
```

### 4. Required Field

Field bắt buộc với validation.

```dart
class RequiredForm extends StatefulWidget {
  @override
  State<RequiredForm> createState() => _RequiredFormState();
}

class _RequiredFormState extends State<RequiredForm> {
  final drOrder = CyberDataRow();

  bool validate() {
    if (drOrder['customer_name'].toString().trim().isEmpty) {
      showError('Vui lòng nhập tên khách hàng');
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberText(
          text: drOrder.bind('customer_name'),
          label: 'Tên khách hàng',
          isCheckEmpty: true,  // Show * indicator
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

### 5. With Icon

Text field với icon prefix.

```dart
Column(
  children: [
    CyberText(
      text: drUser.bind('email'),
      label: 'Email',
      prefixIcon: 'e0be',  // email icon
      keyboardType: TextInputType.emailAddress,
    ),
    
    SizedBox(height: 16),
    
    CyberText(
      text: drUser.bind('phone'),
      label: 'Điện thoại',
      prefixIcon: 'e0cd',  // phone icon
      keyboardType: TextInputType.phone,
    ),
  ],
)
```

### 6. Multiline Text

Text area với nhiều dòng.

```dart
CyberText(
  text: drProduct.bind('description'),
  label: 'Mô tả sản phẩm',
  maxLines: 5,
  maxLength: 500,
  hint: 'Nhập mô tả chi tiết...',
)
```

### 7. Input Formatters

Custom input formatters.

```dart
CyberText(
  text: drOrder.bind('quantity'),
  label: 'Số lượng',
  keyboardType: TextInputType.number,
  inputFormatters: [
    FilteringTextInputFormatter.digitsOnly,
  ],
)
```

### 8. Custom Styling

Tùy chỉnh giao diện.

```dart
CyberText(
  text: drUser.bind('name'),
  label: 'Họ tên',
  
  // Border
  borderSize: 2,
  borderRadius: 12,
  borderColor: Colors.blue.shade200,
  
  // Colors
  backgroundColor: Colors.white,
  
  // Styles
  style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  ),
  labelStyle: TextStyle(
    fontSize: 14,
    color: Colors.blue,
    fontWeight: FontWeight.bold,
  ),
)
```

### 9. Read-Only Field

Hiển thị nhưng không cho sửa.

```dart
CyberText(
  text: drOrder.bind('order_id'),
  label: 'Mã đơn hàng',
  enabled: false,  // Read-only
)
```

### 10. With Controller (Advanced)

Programmatic control.

```dart
class AdvancedText extends StatefulWidget {
  @override
  State<AdvancedText> createState() => _AdvancedTextState();
}

class _AdvancedTextState extends State<AdvancedText> {
  final controller = CyberTextController(
    initialValue: 'Hello',
    isCheckEmpty: true,
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void setValue() {
    controller.setValue('New Value');
  }

  void clear() {
    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberText(
          controller: controller,
          label: 'Name',
        ),
        
        SizedBox(height: 16),
        
        Row(
          children: [
            ElevatedButton(
              onPressed: setValue,
              child: Text('Set Value'),
            ),
            SizedBox(width: 8),
            ElevatedButton(
              onPressed: clear,
              child: Text('Clear'),
            ),
          ],
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
CyberText(
  text: drUser.bind('name'),
  label: 'Name',
)
```

### 2. Two-Way Binding

Automatic sync:

```dart
// User types → drUser['name'] updated
// drUser['name'] = 'New' → UI updated
```

### 3. String Formatting

**In Field:**
```dart
format: "Code: {0}",
showFormatInField: true,
// User sees: "Code: ABC123"
// Raw value: "ABC123"
```

**As Helper:**
```dart
format: "URL: https://{0}.com",
showFormatInField: false,
// Field: "example"
// Helper text below: "URL: https://example.com"
```

### 4. Password Mode

```dart
isPassword: true,
// Auto show/hide button
```

### 5. Icon Support

```dart
prefixIcon: 'e0be',  // Hex icon code
```

### 6. Hint Fallback

```dart
// If isHintEmpty = false (default):
// - hint có giá trị → dùng hint
// - hint null/empty → dùng label làm hint

// If isHintEmpty = true:
// - giữ nguyên hint (có thể rỗng)
```

---

## Best Practices

### 1. Sử Dụng Binding (Recommended)

```dart
// ✅ GOOD
CyberText(
  text: drUser.bind('name'),
  label: 'Name',
)

// ❌ BAD: Manual state
String name = '';
CyberText(
  text: name,
  onChanged: (value) {
    setState(() {
      name = value;
      drUser['name'] = value;
    });
  },
)
```

### 2. Appropriate Keyboard Type

```dart
// ✅ GOOD
CyberText(
  keyboardType: TextInputType.emailAddress,  // For email
)
CyberText(
  keyboardType: TextInputType.phone,  // For phone
)
CyberText(
  keyboardType: TextInputType.number,  // For numbers
)

// ❌ BAD: Wrong keyboard
CyberText(
  keyboardType: TextInputType.text,  // For phone number
)
```

### 3. Format Usage

```dart
// ✅ GOOD: In field for short prefix
format: "KH-{0}",
showFormatInField: true,

// ✅ GOOD: Helper for long format
format: "https://{0}.example.com/api/v1",
showFormatInField: false,

// ❌ BAD: Long format in field
format: "Very long prefix: {0} and more text",
showFormatInField: true,  // Field too crowded
```

### 4. Validation

```dart
// ✅ GOOD: Mark required
CyberText(
  isCheckEmpty: true,
)

// ✅ GOOD: Validate on submit
if (drUser['name'].toString().trim().isEmpty) {
  showError('Name required');
}

// ❌ BAD: No validation
CyberText(
  // Missing isCheckEmpty
)
```

### 5. Hint vs Label

```dart
// ✅ GOOD: Different hint and label
CyberText(
  label: 'Email',
  hint: 'example@domain.com',
)

// ✅ GOOD: Auto-use label as hint
CyberText(
  label: 'Tên khách hàng',
  // hint auto = 'Tên khách hàng'
)

// ❌ BAD: Same text
CyberText(
  label: 'Name',
  hint: 'Name',  // Redundant
)
```

---

## Troubleshooting

### Giá trị không update vào binding

**Nguyên nhân:** Không dùng binding

**Giải pháp:**
```dart
// ✅ CORRECT
CyberText(
  text: drUser.bind('name'),
)

// ❌ WRONG
CyberText(
  text: drUser['name'],
)
```

### Format không hiển thị

**Nguyên nhân:** Thiếu {0} placeholder

**Giải pháp:**
```dart
// ✅ CORRECT
format: "Code: {0}"

// ❌ WRONG
format: "Code: "  // Missing {0}
```

### Password không ẩn

**Nguyên nhân:** Chưa set isPassword

**Giải pháp:**
```dart
// ✅ CORRECT
CyberText(
  isPassword: true,
)
```

### Icon không hiển thị

**Nguyên nhân:** Sai icon code

**Giải pháp:**
```dart
// ✅ CORRECT: Hex code
prefixIcon: 'e0be'

// ❌ WRONG: Decimal
prefixIcon: '1234'
```

### Cursor nhảy vị trí

**Nguyên nhân:** Bug đã fix trong code

**Giải pháp:** Update lên version mới nhất

---

## Tips & Tricks

### 1. Phone Number Format

```dart
CyberText(
  text: drUser.bind('phone'),
  label: 'Điện thoại',
  format: '(+84) {0}',
  showFormatInField: true,
  keyboardType: TextInputType.phone,
  inputFormatters: [
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(10),
  ],
)
```

### 2. Email Validation

```dart
bool isValidEmail(String email) {
  return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
      .hasMatch(email);
}

if (!isValidEmail(drUser['email'])) {
  showError('Email không hợp lệ');
}
```

### 3. Uppercase Input

```dart
CyberText(
  text: drProduct.bind('code'),
  label: 'Mã sản phẩm',
  inputFormatters: [
    UpperCaseTextFormatter(),  // Custom formatter
  ],
)

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
```

### 4. Auto-Complete

```dart
void handleTextChange(String value) {
  if (value.length >= 3) {
    // Search suggestions
    final suggestions = searchDatabase(value);
    showSuggestions(suggestions);
  }
}
```

### 5. Character Counter

```dart
CyberText(
  text: drPost.bind('content'),
  label: 'Nội dung',
  maxLength: 500,  // Auto shows counter
  maxLines: 5,
)
```

---

## Performance Tips

1. **Reuse DataRow**: Don't create new rows unnecessarily
2. **Avoid setState in onChanged**: Let binding handle updates
3. **Debounce Search**: Debounce for search-as-you-type
4. **Lazy Loading**: Don't load heavy data on every keystroke
5. **Dispose Controllers**: Always dispose external controllers

---

## Common Patterns

### Login Form

```dart
Column(
  children: [
    CyberText(
      text: drAuth.bind('username'),
      label: 'Tên đăng nhập',
      prefixIcon: 'e7fd',  // person icon
      isCheckEmpty: true,
    ),
    CyberText(
      text: drAuth.bind('password'),
      label: 'Mật khẩu',
      prefixIcon: 'e897',  // lock icon
      isPassword: true,
      isCheckEmpty: true,
    ),
  ],
)
```

### Search Field

```dart
CyberText(
  text: drFilter.bind('keyword'),
  hint: 'Tìm kiếm...',
  prefixIcon: 'e8b6',  // search icon
  onChanged: (value) {
    searchResults(value);
  },
)
```

### Comment Box

```dart
CyberText(
  text: drComment.bind('message'),
  label: 'Nhận xét',
  maxLines: 5,
  maxLength: 500,
  hint: 'Viết nhận xét của bạn...',
)
```

---

## Version History

### 1.0.0
- Initial release
- Internal controller
- Two-way binding
- String formatting với {0}
- Password mode
- Icon support
- Validation
- Customizable styling

---

## License

MIT License - CyberFramework
