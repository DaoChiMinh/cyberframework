# CyberText - Hướng Dẫn Sử Dụng

## Giới Thiệu

`CyberText` là một custom TextField widget trong CyberFlutter framework, cung cấp khả năng data binding hai chiều với `CyberDataRow`, hỗ trợ format, visibility binding, và nhiều tính năng nâng cao khác.

## Properties

### Data & Binding

| Property | Type | Mặc định | Mô tả |
|----------|------|----------|-------|
| `text` | `dynamic` | `null` | Giá trị text hoặc `CyberBindingExpression` để bind với data |
| `isVisible` | `dynamic` | `true` | Điều khiển hiển thị, có thể bind với data |

### Display & Formatting

| Property | Type | Mặc định | Mô tả |
|----------|------|----------|-------|
| `label` | `String?` | `null` | Label hiển thị phía trên TextField |
| `hint` | `String?` | `null` | Placeholder text |
| `format` | `String?` | `null` | Format string với `{0}`, VD: `"Minhdc: {0}"` |
| `showFormatInField` | `bool` | `false` | Hiển thị format trong TextField hay ở helper text |
| `isShowLabel` | `bool` | `true` | Bật/tắt hiển thị label |

### Input Configuration

| Property | Type | Mặc định | Mô tả |
|----------|------|----------|-------|
| `keyboardType` | `TextInputType?` | `null` | Loại bàn phím (number, email, phone...) |
| `inputFormatters` | `List<TextInputFormatter>?` | `null` | Danh sách formatters để giới hạn input |
| `maxLines` | `int?` | `1` | Số dòng tối đa |
| `maxLength` | `int?` | `null` | Độ dài tối đa |
| `enabled` | `bool` | `true` | Bật/tắt chỉnh sửa |

### Security

| Property | Type | Mặc định | Mô tả |
|----------|------|----------|-------|
| `isPassword` | `bool` | `false` | Chế độ password với toggle visibility |

### Styling

| Property | Type | Mặc định | Mô tả |
|----------|------|----------|-------|
| `icon` | `IconData?` | `null` | Icon hiển thị bên trái |
| `backgroundColor` | `Color?` | `Color(0xFFF5F5F5)` | Màu nền khi enabled |
| `focusColor` | `Color?` | `null` | Màu nền khi focus (chưa implement) |
| `style` | `TextStyle?` | `null` | Style cho text |
| `labelStyle` | `TextStyle?` | `null` | Style cho label |
| `decoration` | `InputDecoration?` | `null` | Custom decoration (ghi đè tất cả) |

### Callbacks

| Property | Type | Mô tả |
|----------|------|-------|
| `onChanged` | `ValueChanged<String>?` | Callback khi text thay đổi |
| `onLeaver` | `Function(dynamic)?` | Callback khi mất focus |

## Ví Dụ Cơ Bản

### 1. TextField Đơn Giản

```dart
CyberText(
  label: 'Họ và tên',
  hint: 'Nhập họ tên của bạn',
  icon: Icons.person,
)
```

### 2. TextField Với Callback

```dart
CyberText(
  label: 'Email',
  hint: 'example@email.com',
  icon: Icons.email,
  keyboardType: TextInputType.emailAddress,
  onChanged: (value) {
    print('Email changed: $value');
  },
  onLeaver: (value) {
    print('Email finalized: $value');
  },
)
```

### 3. Password Field

```dart
CyberText(
  label: 'Mật khẩu',
  hint: 'Nhập mật khẩu',
  icon: Icons.lock,
  isPassword: true, // ✅ Tự động thêm nút toggle visibility
)
```

### 4. TextField Với Format

```dart
// Format hiển thị ở helper text
CyberText(
  label: 'Tên người dùng',
  hint: 'username',
  format: 'Tài khoản: {0}',
  showFormatInField: false, // Hiển thị ở helper text
)

// Format hiển thị trong TextField
CyberText(
  label: 'Tên người dùng',
  hint: 'username',
  format: 'User: {0}',
  showFormatInField: true, // Hiển thị trong field
)
```

### 5. Giới Hạn Input

```dart
CyberText(
  label: 'Số điện thoại',
  hint: '0123456789',
  keyboardType: TextInputType.phone,
  maxLength: 10,
  inputFormatters: [
    FilteringTextInputFormatter.digitsOnly,
  ],
)
```

### 6. Multi-line TextField

```dart
CyberText(
  label: 'Ghi chú',
  hint: 'Nhập ghi chú của bạn',
  maxLines: 5,
  maxLength: 500,
)
```

## Data Binding

### 1. Binding Cơ Bản

```dart
// Trong class của bạn
final CyberDataRow row = CyberDataRow();

// Thiết lập giá trị ban đầu
row['fullName'] = 'Nguyễn Văn A';

// Sử dụng binding
CyberText(
  text: row.bind('fullName'), // ✅ Two-way binding
  label: 'Họ và tên',
  hint: 'Nhập họ tên',
)
```

### 2. Binding Với Format

```dart
final CyberDataRow row = CyberDataRow();
row['username'] = 'minhdc';

CyberText(
  text: row.bind('username'),
  label: 'Tên đăng nhập',
  format: 'User: {0}',
  showFormatInField: true,
)
```

### 3. Visibility Binding

```dart
final CyberDataRow row = CyberDataRow();
row['showEmail'] = true; // hoặc "1", "true", 1

CyberText(
  text: row.bind('email'),
  label: 'Email',
  isVisible: row.bind('showEmail'), // ✅ Ẩn/hiện tự động
)
```

### 4. Form Hoàn Chỉnh Với Data Binding

```dart
class UserForm extends StatefulWidget {
  @override
  State<UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  final CyberDataRow row = CyberDataRow();

  @override
  void initState() {
    super.initState();
    // Khởi tạo dữ liệu
    row['fullName'] = 'Nguyễn Văn A';
    row['email'] = 'user@example.com';
    row['phone'] = '0123456789';
    row['isVIP'] = true;
    row['showPhone'] = true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberText(
          text: row.bind('fullName'),
          label: 'Họ và tên',
          icon: Icons.person,
          onLeaver: (value) {
            print('Name saved: $value');
          },
        ),
        
        SizedBox(height: 16),
        
        CyberText(
          text: row.bind('email'),
          label: 'Email',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
        ),
        
        SizedBox(height: 16),
        
        CyberText(
          text: row.bind('phone'),
          label: 'Số điện thoại',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          isVisible: row.bind('showPhone'), // ✅ Conditional visibility
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
        ),
        
        SizedBox(height: 24),
        
        ElevatedButton(
          onPressed: () {
            // Lấy dữ liệu từ row
            print('Full Name: ${row['fullName']}');
            print('Email: ${row['email']}');
            print('Phone: ${row['phone']}');
          },
          child: Text('Lưu'),
        ),
      ],
    );
  }
}
```

## Styling Nâng Cao

### 1. Custom Background & Label

```dart
CyberText(
  label: 'Tên sản phẩm',
  hint: 'Nhập tên sản phẩm',
  backgroundColor: Colors.blue.shade50,
  labelStyle: TextStyle(
    fontSize: 16,
    color: Colors.blue.shade700,
    fontWeight: FontWeight.bold,
  ),
)
```

### 2. Custom Text Style

```dart
CyberText(
  label: 'Giá tiền',
  hint: '0',
  keyboardType: TextInputType.number,
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.green.shade700,
  ),
)
```

### 3. Ẩn Label

```dart
CyberText(
  label: 'Tìm kiếm', // Label vẫn có thể set
  hint: 'Tìm kiếm...',
  isShowLabel: false, // ✅ Không hiển thị label
  icon: Icons.search,
)
```

### 4. Disabled State

```dart
CyberText(
  text: 'Giá trị không thể chỉnh sửa',
  label: 'Mã đơn hàng',
  enabled: false, // ✅ Tự động đổi màu nền sang gray
)
```

## Tips & Best Practices

### ✅ DO

```dart
// ✅ Sử dụng binding cho form có nhiều fields
CyberText(text: row.bind('fieldName'))

// ✅ Sử dụng onLeaver cho validation
CyberText(
  onLeaver: (value) {
    if (!isValidEmail(value)) {
      showError('Email không hợp lệ');
    }
  },
)

// ✅ Sử dụng format để hiển thị thông tin phụ
CyberText(
  format: 'Tài khoản: {0}',
  showFormatInField: false,
)
```

### ❌ DON'T

```dart
// ❌ Không ghi đè decoration nếu muốn giữ styling mặc định
CyberText(
  decoration: InputDecoration(...), // Sẽ ghi đè toàn bộ style
)

// ❌ Không quên dispose CyberDataRow khi không dùng
// Widget tự động dispose listeners, nhưng nên dispose row
@override
void dispose() {
  row.dispose();
  super.dispose();
}
```

## Các Tính Năng Đặc Biệt

### 1. Auto Format Extraction

Khi `showFormatInField = true`, widget tự động tách format ra khỏi giá trị:

```dart
// Format: "Mã: {0}"
// User nhập: "Mã: ABC123"
// Giá trị lưu: "ABC123" (tự động loại bỏ "Mã: ")
```

### 2. Flexible Visibility Values

`isVisible` chấp nhận nhiều kiểu dữ liệu:

```dart
isVisible: true          // bool
isVisible: 1             // int (0 = false, khác 0 = true)
isVisible: "true"        // String ("true"/"1" = true, "false"/"0" = false)
isVisible: row.bind('showField')  // CyberBindingExpression
```

### 3. Password Toggle

Khi `isPassword = true`, tự động thêm nút toggle ở suffixIcon:

```dart
CyberText(
  isPassword: true,
  // ✅ Tự động thêm eye icon để toggle visibility
)
```

### 4. Auto Keyboard Type

Password field tự động set `keyboardType` là `TextInputType.visiblePassword`:

```dart
CyberText(
  isPassword: true,
  // keyboardType tự động là visiblePassword
)
```

## Troubleshooting

### Vấn đề: Binding không cập nhật UI

**Giải pháp**: Đảm bảo CyberDataRow đang notify listeners

```dart
row['fieldName'] = newValue; // ✅ Tự động notify
```

### Vấn đề: TextField không mất focus

**Giải pháp**: Tap vào vùng trống hoặc dùng `FocusScope`

```dart
GestureDetector(
  onTap: () => FocusScope.of(context).unfocus(),
  child: YourForm(),
)
```

### Vấn đề: Format không hiển thị đúng

**Giải pháp**: Kiểm tra format string có chứa `{0}`

```dart
format: 'Prefix {0} Suffix' // ✅ Correct
format: 'Prefix $value Suffix' // ❌ Wrong
```

---

## Xem Thêm

- [CyberNumeric](./CyberNumeric.md) - TextField cho số
- [CyberDate](./CyberDate.md) - TextField cho ngày tháng
- [CyberLookup](./CyberLookup.md) - TextField với lookup dialog
- [CyberDataRow](./CyberDataRow.md) - Data binding system
