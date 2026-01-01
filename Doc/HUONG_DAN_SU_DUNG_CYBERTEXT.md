# Hướng Dẫn Sử Dụng CyberText

## Giới Thiệu

`CyberText` là một text input widget trong CyberFramework, cung cấp 2 chế độ sử dụng:
- **Simple Mode**: Sử dụng trực tiếp với `text` và `onChanged`
- **Controller Mode**: Sử dụng với `CyberTextController` để có data binding và validation

## Cài Đặt

```dart
import 'package:cyberframework/cyberframework.dart';
```

## 2 Chế Độ Sử Dụng

### 1. Simple Mode (Không Controller)

Phù hợp cho các trường hợp đơn giản, không cần validation hay data binding.

```dart
String username = '';

CyberText(
  text: username,
  onChanged: (value) {
    setState(() {
      username = value;
    });
  },
  label: 'Tên đăng nhập',
  hint: 'Nhập tên đăng nhập',
)
```

### 2. Controller Mode (Có Controller)

Phù hợp khi cần data binding với model, validation, format hiển thị.

```dart
final controller = CyberTextController();

// Binding với data
controller.bindToField(dataRow, 'fieldName');

CyberText(
  controller: controller,
  label: 'Họ tên',
)
```

**⚠️ LƯU Ý QUAN TRỌNG**: Không được truyền đồng thời `text` và `controller`!

```dart
// ❌ SAI - Sẽ bị lỗi assert
CyberText(
  text: 'value',           // ❌
  controller: controller,  // ❌
)

// ✅ ĐÚNG - Chọn một trong hai
CyberText(text: 'value')              // Simple mode
CyberText(controller: controller)     // Controller mode
```

## Các Thuộc Tính Cơ Bản

### 1. Label và Hint

```dart
CyberText(
  label: 'Email',                    // Label hiển thị phía trên
  hint: 'example@email.com',         // Placeholder text
  isShowLabel: true,                 // Hiển thị label (mặc định true)
)
```

### 2. Icon

```dart
CyberText(
  label: 'Tìm kiếm',
  icon: Icons.search,                // Icon bên trái
  hint: 'Nhập từ khóa...',
)
```

### 3. Required Field (Với Controller)

```dart
final controller = CyberTextController(
  isCheckEmpty: true,                // Đánh dấu field bắt buộc
);

CyberText(
  controller: controller,
  label: 'Họ tên',                   // Sẽ hiển thị dấu * màu đỏ
)
```

### 4. Helper Text (Với Controller)

```dart
final controller = CyberTextController(
  helperText: 'Mật khẩu phải có ít nhất 8 ký tự',
);

CyberText(
  controller: controller,
  label: 'Mật khẩu',
)
```

## Các Loại Input Khác Nhau

### 1. Text Field Thông Thường

```dart
CyberText(
  text: username,
  onChanged: (value) => setState(() => username = value),
  label: 'Tên người dùng',
  hint: 'Nhập tên người dùng',
)
```

### 2. Password Field

```dart
CyberText(
  text: password,
  onChanged: (value) => setState(() => password = value),
  label: 'Mật khẩu',
  isPassword: true,                  // Ẩn nội dung, có nút show/hide
)
```

### 3. Email Field

```dart
CyberText(
  text: email,
  onChanged: (value) => setState(() => email = value),
  label: 'Email',
  icon: Icons.email,
  keyboardType: TextInputType.emailAddress,
  hint: 'example@email.com',
)
```

### 4. Phone Number Field

```dart
CyberText(
  text: phone,
  onChanged: (value) => setState(() => phone = value),
  label: 'Số điện thoại',
  icon: Icons.phone,
  keyboardType: TextInputType.phone,
  inputFormatters: [
    FilteringTextInputFormatter.digitsOnly,  // Chỉ cho phép số
    LengthLimitingTextInputFormatter(10),     // Giới hạn 10 số
  ],
)
```

### 5. Multiline Text Area

```dart
CyberText(
  text: description,
  onChanged: (value) => setState(() => description = value),
  label: 'Mô tả',
  hint: 'Nhập mô tả chi tiết...',
  maxLines: 5,                       // Cho phép nhiều dòng
)
```

### 6. Limited Length Field

```dart
CyberText(
  text: code,
  onChanged: (value) => setState(() => code = value),
  label: 'Mã xác nhận',
  maxLength: 6,                      // Giới hạn 6 ký tự, hiển thị counter
)
```

## Keyboard Types

```dart
// Text thông thường
keyboardType: TextInputType.text

// Số
keyboardType: TextInputType.number

// Số thập phân
keyboardType: TextInputType.numberWithOptions(decimal: true)

// Điện thoại
keyboardType: TextInputType.phone

// Email
keyboardType: TextInputType.emailAddress

// URL
keyboardType: TextInputType.url

// Multiline
keyboardType: TextInputType.multiline

// Password
keyboardType: TextInputType.visiblePassword
```

## Input Formatters

### 1. Chỉ Cho Phép Số

```dart
import 'package:flutter/services.dart';

CyberText(
  label: 'Số lượng',
  keyboardType: TextInputType.number,
  inputFormatters: [
    FilteringTextInputFormatter.digitsOnly,
  ],
)
```

### 2. Chỉ Cho Phép Chữ Cái

```dart
CyberText(
  label: 'Họ tên',
  inputFormatters: [
    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZÀ-ỹ\s]')),
  ],
)
```

### 3. Uppercase Tự Động

```dart
CyberText(
  label: 'Mã code',
  inputFormatters: [
    UpperCaseTextFormatter(),  // Custom formatter
  ],
)

// Custom formatter
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

### 4. Format Số Tiền

```dart
CyberText(
  label: 'Số tiền',
  keyboardType: TextInputType.number,
  inputFormatters: [
    FilteringTextInputFormatter.digitsOnly,
    CurrencyInputFormatter(),  // Custom formatter
  ],
)

// Custom formatter để format số tiền
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    
    final number = int.tryParse(newValue.text.replaceAll(',', '')) ?? 0;
    final formatted = NumberFormat('#,###').format(number);
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
```

## Styling

### 1. Custom Text Style

```dart
CyberText(
  label: 'Tiêu đề',
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.blue,
  ),
)
```

### 2. Custom Label Style

```dart
CyberText(
  label: 'Email',
  labelStyle: TextStyle(
    fontSize: 16,
    color: Colors.green,
    fontWeight: FontWeight.w600,
  ),
)
```

### 3. Custom Background Color

```dart
CyberText(
  label: 'Tên',
  backgroundColor: Colors.white,
  focusColor: Colors.blue.shade50,
)
```

### 4. Custom Decoration (Advanced)

```dart
CyberText(
  label: 'Custom Field',
  decoration: InputDecoration(
    hintText: 'Nhập giá trị',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.blue, width: 2),
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.all(16),
  ),
)
```

## Enabled/Disabled State

### 1. Disabled Field (Simple Mode)

```dart
CyberText(
  text: value,
  enabled: false,                    // Disable field
  label: 'Chỉ đọc',
)
```

### 2. Disabled Field (Controller Mode)

```dart
final controller = CyberTextController(
  enabled: false,                    // Disable từ controller
);

CyberText(
  controller: controller,
  label: 'Chỉ đọc',
)
```

## Visible/Invisible

```dart
bool showField = false;

CyberText(
  text: value,
  isVisible: showField,              // Ẩn/hiện field
  label: 'Optional Field',
)
```

## Callbacks

### 1. onChanged (Simple Mode)

```dart
CyberText(
  text: searchQuery,
  onChanged: (value) {
    print('Text changed: $value');
    setState(() => searchQuery = value);
    
    // Thực hiện search
    performSearch(value);
  },
  label: 'Tìm kiếm',
)
```

### 2. onLeaver (Focus Lost)

```dart
CyberText(
  text: value,
  onChanged: (val) => setState(() => value = val),
  onLeaver: () {
    print('Field lost focus');
    // Validate hoặc save data
    validateAndSave();
  },
  label: 'Email',
)
```

## Sử Dụng Với Controller

### 1. Tạo và Khởi Tạo Controller

```dart
class MyFormState extends State<MyForm> {
  final nameController = CyberTextController();
  final emailController = CyberTextController(
    isCheckEmpty: true,
    helperText: 'Email là bắt buộc',
  );
  
  @override
  void dispose() {
    // Dispose controllers khi không dùng
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberText(controller: nameController, label: 'Họ tên'),
        CyberText(controller: emailController, label: 'Email'),
      ],
    );
  }
}
```

### 2. Binding Với DataRow

```dart
final dataRow = CyberDataRow();
dataRow.addField('name', '');
dataRow.addField('email', '');

final nameController = CyberTextController();
final emailController = CyberTextController();

nameController.bindToField(dataRow, 'name');
emailController.bindToField(dataRow, 'email');

// UI sẽ tự động sync với data
CyberText(controller: nameController, label: 'Họ tên')
CyberText(controller: emailController, label: 'Email')

// Lấy giá trị
print(dataRow.getValue('name'));
print(dataRow.getValue('email'));
```

### 3. Set/Get Value Programmatically

```dart
final controller = CyberTextController();

// Set giá trị
controller.setValue('Nguyễn Văn A');

// Get giá trị
String value = controller.value;

// Get display value (có format nếu có)
String displayValue = controller.displayValue;
```

### 4. Format Display (Hiển Thị Có Định Dạng)

```dart
final priceController = CyberTextController(
  format: '{0} VNĐ',                 // Format hiển thị
  showFormatInField: true,            // Hiển thị format trong field
);

priceController.setValue('100000');
// Hiển thị: 100000 VNĐ

CyberText(
  controller: priceController,
  label: 'Giá tiền',
)

// Khi lấy value, sẽ tự động loại bỏ format
print(priceController.value);  // Output: 100000 (không có "VNĐ")
```

## Ví Dụ Thực Tế

### 1. Form Đăng Nhập

```dart
class LoginForm extends StatefulWidget {
  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  String username = '';
  String password = '';
  
  void login() {
    if (username.isEmpty || password.isEmpty) {
      // Show error
      return;
    }
    // Perform login
    print('Login: $username / $password');
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberText(
          text: username,
          onChanged: (value) => setState(() => username = value),
          label: 'Tên đăng nhập',
          hint: 'Nhập tên đăng nhập',
          icon: Icons.person,
        ),
        SizedBox(height: 16),
        CyberText(
          text: password,
          onChanged: (value) => setState(() => password = value),
          label: 'Mật khẩu',
          hint: 'Nhập mật khẩu',
          icon: Icons.lock,
          isPassword: true,
        ),
        SizedBox(height: 24),
        ElevatedButton(
          onPressed: login,
          child: Text('Đăng nhập'),
        ),
      ],
    );
  }
}
```

### 2. Form Đăng Ký (Với Controller)

```dart
class RegisterForm extends StatefulWidget {
  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final dataRow = CyberDataRow();
  
  final nameController = CyberTextController(isCheckEmpty: true);
  final emailController = CyberTextController(isCheckEmpty: true);
  final phoneController = CyberTextController();
  final passwordController = CyberTextController(isCheckEmpty: true);
  
  @override
  void initState() {
    super.initState();
    
    // Setup data
    dataRow.addField('name', '');
    dataRow.addField('email', '');
    dataRow.addField('phone', '');
    dataRow.addField('password', '');
    
    // Bind controllers
    nameController.bindToField(dataRow, 'name');
    emailController.bindToField(dataRow, 'email');
    phoneController.bindToField(dataRow, 'phone');
    passwordController.bindToField(dataRow, 'password');
  }
  
  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    super.dispose();
  }
  
  void register() {
    // Validate
    if (dataRow.getValue('name').isEmpty ||
        dataRow.getValue('email').isEmpty ||
        dataRow.getValue('password').isEmpty) {
      // Show error
      return;
    }
    
    // Submit data
    final userData = {
      'name': dataRow.getValue('name'),
      'email': dataRow.getValue('email'),
      'phone': dataRow.getValue('phone'),
      'password': dataRow.getValue('password'),
    };
    
    print('Register: $userData');
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberText(
          controller: nameController,
          label: 'Họ và tên',
          hint: 'Nhập họ và tên',
          icon: Icons.person,
        ),
        SizedBox(height: 16),
        CyberText(
          controller: emailController,
          label: 'Email',
          hint: 'example@email.com',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: 16),
        CyberText(
          controller: phoneController,
          label: 'Số điện thoại',
          hint: '0123456789',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
        ),
        SizedBox(height: 16),
        CyberText(
          controller: passwordController,
          label: 'Mật khẩu',
          hint: 'Nhập mật khẩu',
          icon: Icons.lock,
          isPassword: true,
        ),
        SizedBox(height: 24),
        ElevatedButton(
          onPressed: register,
          child: Text('Đăng ký'),
        ),
      ],
    );
  }
}
```

### 3. Search Field

```dart
class SearchField extends StatefulWidget {
  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  String searchQuery = '';
  Timer? _debounce;
  
  void onSearchChanged(String query) {
    // Debounce search
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(Duration(milliseconds: 500), () {
      // Perform search
      performSearch(query);
    });
  }
  
  void performSearch(String query) {
    print('Searching for: $query');
    // Call API or filter list
  }
  
  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return CyberText(
      text: searchQuery,
      onChanged: (value) {
        setState(() => searchQuery = value);
        onSearchChanged(value);
      },
      icon: Icons.search,
      hint: 'Tìm kiếm...',
      backgroundColor: Colors.white,
    );
  }
}
```

### 4. Price Input Field

```dart
class PriceField extends StatefulWidget {
  @override
  State<PriceField> createState() => _PriceFieldState();
}

class _PriceFieldState extends State<PriceField> {
  final controller = CyberTextController(
    format: '{0} VNĐ',
    showFormatInField: true,
  );
  
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberText(
          controller: controller,
          label: 'Giá sản phẩm',
          hint: 'Nhập giá',
          icon: Icons.attach_money,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
        ),
        SizedBox(height: 8),
        Text('Giá trị: ${controller.value}'),  // Giá trị raw (không format)
      ],
    );
  }
}
```

### 5. Multi-line Note Field

```dart
CyberText(
  text: note,
  onChanged: (value) => setState(() => note = value),
  label: 'Ghi chú',
  hint: 'Nhập ghi chú chi tiết...',
  maxLines: 5,
  maxLength: 500,
  backgroundColor: Colors.grey.shade50,
)
```

### 6. Read-only Field

```dart
final infoController = CyberTextController(
  enabled: false,
);

@override
void initState() {
  super.initState();
  infoController.setValue('Thông tin chỉ đọc');
}

@override
Widget build(BuildContext context) {
  return CyberText(
    controller: infoController,
    label: 'Mã đơn hàng',
    backgroundColor: Colors.grey.shade200,
  );
}
```

## Thuộc Tính Đầy Đủ

| Thuộc tính | Kiểu dữ liệu | Mặc định | Mô tả |
|-----------|-------------|----------|-------|
| `controller` | `CyberTextController?` | `null` | Controller để binding và validation |
| `text` | `String?` | `null` | Giá trị text (simple mode) |
| `onChanged` | `ValueChanged<String>?` | `null` | Callback khi text thay đổi |
| `label` | `String?` | `null` | Label hiển thị phía trên |
| `hint` | `String?` | `null` | Placeholder text |
| `icon` | `IconData?` | `null` | Icon prefix |
| `keyboardType` | `TextInputType?` | `null` | Loại bàn phím |
| `inputFormatters` | `List<TextInputFormatter>?` | `null` | Danh sách formatters |
| `maxLines` | `int?` | `1` | Số dòng tối đa |
| `maxLength` | `int?` | `null` | Độ dài tối đa |
| `enabled` | `bool` | `true` | Enable/disable field |
| `isVisible` | `bool` | `true` | Hiển thị/ẩn field |
| `style` | `TextStyle?` | `null` | Style cho text |
| `decoration` | `InputDecoration?` | `null` | Custom decoration |
| `isPassword` | `bool` | `false` | Kiểu password với toggle |
| `isShowLabel` | `bool` | `true` | Hiển thị label |
| `backgroundColor` | `Color?` | `Color(0xFFF5F5F5)` | Màu nền |
| `focusColor` | `Color?` | `null` | Màu nền khi focus |
| `labelStyle` | `TextStyle?` | `null` | Style cho label |
| `onLeaver` | `VoidCallback?` | `null` | Callback khi mất focus |

## CyberTextController Properties

| Thuộc tính | Kiểu dữ liệu | Mô tả |
|-----------|-------------|-------|
| `value` | `String` | Giá trị raw (không format) |
| `displayValue` | `String` | Giá trị hiển thị (có format) |
| `enabled` | `bool` | Enable/disable từ controller |
| `isCheckEmpty` | `bool` | Đánh dấu field required |
| `helperText` | `String?` | Text hướng dẫn |
| `format` | `String?` | Format hiển thị (VD: '{0} VNĐ') |
| `showFormatInField` | `bool` | Hiển thị format trong field |

## Tips & Best Practices

### 1. Khi Nào Dùng Simple Mode vs Controller Mode?

**Simple Mode:**
- Form đơn giản, không cần validation phức tạp
- Không cần data binding với model
- Chỉ cần lấy/set giá trị trực tiếp

**Controller Mode:**
- Cần binding với CyberDataRow/DataTable
- Cần validation, format hiển thị
- Form phức tạp với nhiều logic
- Cần quản lý state tập trung

### 2. Memory Management

```dart
// ✅ ĐÚNG: Dispose controllers
@override
void dispose() {
  controller.dispose();
  super.dispose();
}

// ❌ SAI: Quên dispose
// Gây memory leak!
```

### 3. Tránh Rebuild Không Cần Thiết

```dart
// ✅ ĐÚNG: Dùng controller, widget tự quản lý state
final controller = CyberTextController();

CyberText(controller: controller)  // Không cần setState

// ⚠️ CẨN THẬN: Simple mode cần setState
String text = '';

CyberText(
  text: text,
  onChanged: (value) {
    setState(() => text = value);  // Trigger rebuild
  },
)
```

### 4. Validation Pattern

```dart
// Tạo validation function
String? validateEmail(String value) {
  if (value.isEmpty) return 'Email không được để trống';
  if (!value.contains('@')) return 'Email không hợp lệ';
  return null;
}

// Validate trước khi submit
void submit() {
  final email = emailController.value;
  final error = validateEmail(email);
  
  if (error != null) {
    // Show error
    return;
  }
  
  // Submit
}
```

### 5. Format Pattern

```dart
// Format số tiền
final priceController = CyberTextController(
  format: '{0} VNĐ',
  showFormatInField: true,
);

// Format đơn vị
final weightController = CyberTextController(
  format: '{0} kg',
  showFormatInField: true,
);

// Format phần trăm
final percentController = CyberTextController(
  format: '{0}%',
  showFormatInField: true,
);
```

## Lưu Ý Quan Trọng

1. **Anti-Loop Mechanism**: CyberText có cơ chế chống loop khi sync giữa controller và TextEditingController để tránh cursor jump và lag.

2. **Auto Dispose**: Widget tự động dispose các listeners khi unmount, nhưng vẫn cần dispose controller manually.

3. **Text vs Controller**: Không được truyền đồng thời `text` và `controller`. Sẽ có assert error.

4. **Password Field**: Khi `isPassword = true`, tự động có nút toggle show/hide password.

5. **Format Display**: Khi dùng format, value sẽ tự động extract raw value (loại bỏ format) khi set vào controller.

## Kết Luận

CyberText là một text input widget mạnh mẽ với 2 chế độ sử dụng linh hoạt:
- **Simple Mode** cho các trường hợp đơn giản
- **Controller Mode** cho data binding và validation phức tạp

Widget tự động xử lý các vấn đề về sync, focus, keyboard type, và có sẵn nhiều tính năng như password toggle, format display, required indicator...

---

**Version**: 1.0  
**Last Updated**: 2025  
**CyberFramework** - Simplifying Flutter Development
