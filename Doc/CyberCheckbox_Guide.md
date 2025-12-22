# CyberCheckbox - Hướng Dẫn Sử Dụng

## Giới Thiệu

`CyberCheckbox` là iOS-style checkbox widget với data binding hai chiều, hỗ trợ nhiều định dạng dữ liệu (bool, int, string).

## Properties

| Property | Type | Mặc định | Mô tả |
|----------|------|----------|-------|
| `text` | `dynamic` | `null` | Giá trị checkbox hoặc `CyberBindingExpression` |
| `label` | `String?` | `null` | Label hiển thị bên cạnh checkbox |
| `enabled` | `bool` | `true` | Bật/tắt checkbox |
| `isVisible` | `dynamic` | `true` | Điều khiển hiển thị (có thể binding) |
| `labelStyle` | `TextStyle?` | `null` | Style cho label |
| `onChanged` | `ValueChanged<bool>?` | `null` | Callback khi giá trị thay đổi |
| `onLeaver` | `Function(dynamic)?` | `null` | Callback khi checkbox được toggle |
| `activeColor` | `Color?` | `Color(0xFF00D287)` | Màu khi được checked |
| `checkColor` | `Color?` | `Colors.white` | Màu của icon check |
| `size` | `double?` | `24` | Kích thước checkbox |

## Ví Dụ Cơ Bản

### 1. Checkbox Đơn Giản

```dart
CyberCheckbox(
  text: true, // Static value
  label: 'Đồng ý với điều khoản',
  onChanged: (value) {
    print('Checkbox changed: $value');
  },
)
```

### 2. Checkbox Với Data Binding

```dart
final CyberDataRow row = CyberDataRow();
row['isActive'] = true; // hoặc "1", 1

CyberCheckbox(
  text: row.bind('isActive'),
  label: 'Kích hoạt',
)
```

### 3. Checkbox Với Custom Style

```dart
CyberCheckbox(
  text: row.bind('isVIP'),
  label: 'Thành viên VIP',
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

### 4. Checkbox Group

```dart
class SettingsForm extends StatefulWidget {
  @override
  State<SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<SettingsForm> {
  final CyberDataRow row = CyberDataRow();

  @override
  void initState() {
    super.initState();
    row['enableNotifications'] = true;
    row['enableEmail'] = false;
    row['enableSMS'] = "1"; // String format
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cài đặt thông báo',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        
        CyberCheckbox(
          text: row.bind('enableNotifications'),
          label: 'Bật thông báo push',
        ),
        
        CyberCheckbox(
          text: row.bind('enableEmail'),
          label: 'Nhận email thông báo',
        ),
        
        CyberCheckbox(
          text: row.bind('enableSMS'),
          label: 'Nhận SMS thông báo',
        ),
        
        SizedBox(height: 24),
        
        ElevatedButton(
          onPressed: () {
            print('Notifications: ${row['enableNotifications']}');
            print('Email: ${row['enableEmail']}');
            print('SMS: ${row['enableSMS']}');
          },
          child: Text('Lưu cài đặt'),
        ),
      ],
    );
  }
}
```

## Type Conversion

Checkbox hỗ trợ tự động chuyển đổi giữa các kiểu dữ liệu:

### Bool ↔ Int

```dart
// Lưu dưới dạng int
row['isChecked'] = 1; // int

CyberCheckbox(
  text: row.bind('isChecked'),
  label: 'Check me',
  onChanged: (value) {
    // value = true/false (bool)
    // row['isChecked'] = 1/0 (int) - tự động convert
  },
)
```

### Bool ↔ String

```dart
// Lưu dưới dạng string
row['isActive'] = "1"; // string

CyberCheckbox(
  text: row.bind('isActive'),
  label: 'Active',
  onChanged: (value) {
    // value = true/false (bool)
    // row['isActive'] = "1"/"0" (string) - tự động convert
  },
)
```

### Parsing Rules

| Input Value | Result |
|-------------|--------|
| `true` | `true` |
| `false` | `false` |
| `1` (int) | `true` |
| `0` (int) | `false` |
| `"1"` | `true` |
| `"0"` | `false` |
| `"true"` | `true` |
| `"false"` | `false` |
| `null` | `false` |

## Visibility Binding

```dart
final CyberDataRow row = CyberDataRow();
row['showCheckbox'] = true;
row['isChecked'] = false;

CyberCheckbox(
  text: row.bind('isChecked'),
  label: 'Optional checkbox',
  isVisible: row.bind('showCheckbox'), // ✅ Conditional visibility
)

// Thay đổi visibility
row['showCheckbox'] = false; // Checkbox sẽ ẩn
```

## Disabled State

```dart
CyberCheckbox(
  text: row.bind('agreeTerms'),
  label: 'Tôi đồng ý với điều khoản',
  enabled: false, // ✅ Disabled, opacity giảm
)
```

## Extension Method

Sử dụng extension để tạo checkbox nhanh:

```dart
bool isChecked = true;

Widget checkbox = "Đồng ý với điều khoản".toCheckbox(
  context,
  value: isChecked,
  onChanged: (value) {
    print('Changed: $value');
  },
);
```

## Use Cases

### 1. Terms & Conditions

```dart
CyberCheckbox(
  text: row.bind('agreeTerms'),
  label: 'Tôi đã đọc và đồng ý với điều khoản sử dụng',
  activeColor: Colors.green,
  onChanged: (value) {
    if (value) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Cảm ơn'),
          content: Text('Bạn đã đồng ý với điều khoản.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  },
)
```

### 2. Feature Toggles

```dart
Column(
  children: [
    CyberCheckbox(
      text: row.bind('enableDarkMode'),
      label: 'Chế độ tối',
      activeColor: Colors.purple,
    ),
    
    CyberCheckbox(
      text: row.bind('enableAutoSave'),
      label: 'Tự động lưu',
      activeColor: Colors.blue,
    ),
    
    CyberCheckbox(
      text: row.bind('enableOfflineMode'),
      label: 'Chế độ offline',
      activeColor: Colors.orange,
    ),
  ],
)
```

### 3. Multi-Select List

```dart
class TodoList extends StatefulWidget {
  @override
  State<TodoList> createState() => _TodoListState();
}

class _TodoListState extends State<TodoList> {
  final List<Map<String, dynamic>> todos = [
    {'title': 'Mua sữa', 'completed': false},
    {'title': 'Đi chợ', 'completed': true},
    {'title': 'Học Flutter', 'completed': false},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: todos.length,
      itemBuilder: (context, index) {
        final todo = todos[index];
        return CyberCheckbox(
          text: todo['completed'],
          label: todo['title'],
          onChanged: (value) {
            setState(() {
              todo['completed'] = value;
            });
          },
        );
      },
    );
  }
}
```

## Tips & Best Practices

### ✅ DO

```dart
// ✅ Sử dụng binding cho form
CyberCheckbox(text: row.bind('fieldName'))

// ✅ Validation trong onChanged
CyberCheckbox(
  text: row.bind('agreeTerms'),
  onChanged: (value) {
    if (!value) {
      showWarning('Bạn phải đồng ý để tiếp tục');
    }
  },
)

// ✅ Preserve original type
row['isActive'] = 1; // int
// Sau khi toggle, vẫn là int (1/0)
```

### ❌ DON'T

```dart
// ❌ Không quên handle null
CyberCheckbox(
  text: null, // Sẽ hiển thị unchecked
)

// ❌ Không mix types trong cùng field
row['status'] = 1;
row['status'] = "true"; // ❌ Inconsistent
```

## Troubleshooting

### Vấn đề: Checkbox không update UI

**Giải pháp**: Kiểm tra binding

```dart
// ✅ Correct
row['checked'] = true;
CyberCheckbox(text: row.bind('checked'))

// ❌ Wrong - Không có binding
bool checked = true;
CyberCheckbox(text: checked) // Won't update
```

### Vấn đề: Value không đúng kiểu

**Giải pháp**: Checkbox tự động convert, kiểm tra console log

```dart
CyberCheckbox(
  text: row.bind('status'),
  onChanged: (value) {
    print('Type: ${row['status'].runtimeType}');
    print('Value: ${row['status']}');
  },
)
```

---

## Xem Thêm

- [CyberRadioBox](./CyberRadioBox.md) - Radio button control
- [CyberText](./CyberText.md) - Text input control
- [CyberDataRow](./CyberDataRow.md) - Data binding system
