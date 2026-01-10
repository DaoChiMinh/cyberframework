# CyberMessageBox - iOS-Style Message Boxes

## Mục Lục
1. [Giới Thiệu](#giới-thiệu)
2. [CyberMessageBox Class](#cybermessagebox-class)
3. [Extension Methods](#extension-methods)
4. [Ví Dụ Sử Dụng](#ví-dụ-sử-dụng)
5. [Features](#features)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

---

## Giới Thiệu

`CyberMessageBox` là hệ thống message box với **iOS-style design**, cung cấp 3 loại alert: Default (Success), Warning, và Error. Widget này tích hợp sẵn với CyberPopup và cung cấp extension methods tiện lợi.

### Đặc Điểm Chính

- ✅ **iOS-Style Design**: Giống native iOS alerts
- ✅ **3 Alert Types**: Default, Warning, Error
- ✅ **Extension Methods**: String và BuildContext extensions
- ✅ **Async/Await**: Return bool result
- ✅ **Validation Helpers**: Built-in validation support
- ✅ **Customizable**: Custom text, colors, buttons
- ✅ **Bilingual**: Tự động Tiếng Việt/English

### Import

```dart
import 'package:cyberframework/cyberframework.dart';
```

---

## CyberMessageBox Class

### Constructor

```dart
const CyberMessageBox({
  required this.message,
  this.title,
  this.type = CyberMsgBoxType.defaultType,
  this.confirmText,
  this.cancelText,
})
```

### Properties

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `message` | `String` | Nội dung message | Required |
| `title` | `String?` | Tiêu đề | Auto (theo type) |
| `type` | `CyberMsgBoxType` | Loại alert | defaultType |
| `confirmText` | `String?` | Text nút OK | "OK" |
| `cancelText` | `String?` | Text nút Cancel | "Hủy"/"Cancel" |

### CyberMsgBoxType

```dart
enum CyberMsgBoxType {
  defaultType,  // Blue, OK only
  warning,      // Blue, OK + Cancel
  error,        // Red, OK only
}
```

### Method

```dart
Future<bool> show(BuildContext context)
```

Returns:
- `true`: User pressed OK/Confirm
- `false`: User pressed Cancel or dismissed

---

## Extension Methods

### String Extensions

#### V_MsgBox

```dart
Future<bool> V_MsgBox(
  BuildContext context, {
  String? title,
  CyberMsgBoxType type = CyberMsgBoxType.defaultType,
  String? confirmText,
  String? cancelText,
})
```

**Example:**
```dart
bool result = await "Lưu thành công".V_MsgBox(context);

bool confirm = await "Bạn có chắc muốn xóa?".V_MsgBox(
  context,
  type: CyberMsgBoxType.warning,
);
```

### BuildContext Extensions

#### showSuccess

```dart
Future<bool> showSuccess(
  String message, {
  String? title,
  String? confirmText,
})
```

#### showWarning

```dart
Future<bool> showWarning(
  String message, {
  String? title,
  String? confirmText,
  String? cancelText,
})
```

#### showErrorMsg

```dart
Future<bool> showErrorMsg(
  String message, {
  String? title,
  String? confirmText,
})
```

#### validateFields

```dart
bool validateFields(Map<String, dynamic> fields)
```

#### showValidationError

```dart
Future<void> showValidationError(String fieldName, String message)
```

---

## Ví Dụ Sử Dụng

### 1. Success Message (Default Type)

Simple success notification.

```dart
class SaveForm extends StatelessWidget {
  Future<void> saveData(BuildContext context) async {
    // Save logic...
    
    // Show success
    await "Lưu dữ liệu thành công".V_MsgBox(context);
    
    // Or using extension
    await context.showSuccess("Lưu dữ liệu thành công");
    
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return CyberButton(
      label: 'Lưu',
      onClick: () => saveData(context),
    );
  }
}
```

### 2. Warning Message (Confirmation)

Confirmation dialog with Cancel button.

```dart
class DeleteButton extends StatelessWidget {
  Future<void> deleteItem(BuildContext context, String itemId) async {
    // Show confirmation
    final confirmed = await "Bạn có chắc muốn xóa mục này?".V_MsgBox(
      context,
      type: CyberMsgBoxType.warning,
      title: "Xác nhận xóa",
    );
    
    if (confirmed) {
      // Proceed with deletion
      await api.deleteItem(itemId);
      
      await context.showSuccess("Đã xóa thành công");
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CyberButton(
      label: 'Xóa',
      onClick: () => deleteItem(context, '123'),
      backgroundColor: Colors.red,
    );
  }
}
```

### 3. Error Message

Show error with red styling.

```dart
class LoginForm extends StatelessWidget {
  Future<void> login(BuildContext context) async {
    try {
      await api.login(username, password);
      
      await context.showSuccess("Đăng nhập thành công");
      
    } catch (e) {
      // Show error
      await "Đăng nhập thất bại: ${e.toString()}".V_MsgBox(
        context,
        type: CyberMsgBoxType.error,
      );
      
      // Or using extension
      await context.showErrorMsg(
        "Đăng nhập thất bại: ${e.toString()}",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CyberButton(
      label: 'Đăng nhập',
      onClick: () => login(context),
    );
  }
}
```

### 4. Custom Buttons

Custom button text.

```dart
final confirmed = await "Bạn muốn tiếp tục?".V_MsgBox(
  context,
  type: CyberMsgBoxType.warning,
  confirmText: "Tiếp tục",
  cancelText: "Quay lại",
);

if (confirmed) {
  // Continue...
}
```

### 5. Using CyberMessageBox Class

Direct class usage.

```dart
final msgBox = CyberMessageBox(
  message: "Thao tác hoàn tất",
  title: "Thành công",
  type: CyberMsgBoxType.defaultType,
  confirmText: "Đóng",
);

final result = await msgBox.show(context);
```

### 6. Validation Helper

Validate multiple fields.

```dart
class FormValidator extends StatefulWidget {
  @override
  State<FormValidator> createState() => _FormValidatorState();
}

class _FormValidatorState extends State<FormValidator> {
  final drForm = CyberDataRow();

  Future<void> submit() async {
    // Validate using helper
    final isValid = context.validateFields({
      'Tên khách hàng': drForm['ten_kh'],
      'Số điện thoại': drForm['dien_thoai'],
      'Email': drForm['email'],
    });

    if (!isValid) {
      return; // Validation errors shown automatically
    }

    // Proceed with submission
    await saveForm();
    await context.showSuccess("Lưu thành công");
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberText(
          text: drForm.bind('ten_kh'),
          label: 'Tên khách hàng',
        ),
        
        CyberText(
          text: drForm.bind('dien_thoai'),
          label: 'Số điện thoại',
        ),
        
        CyberText(
          text: drForm.bind('email'),
          label: 'Email',
        ),
        
        CyberButton(
          label: 'Lưu',
          onClick: submit,
        ),
      ],
    );
  }
}
```

### 7. Custom Validation Error

Show specific validation error.

```dart
Future<void> validateAndSave(BuildContext context) async {
  final email = drForm['email'].toString();
  
  if (!isValidEmail(email)) {
    await context.showValidationError(
      'Email',
      'Định dạng email không hợp lệ',
    );
    return;
  }

  // Continue...
}

bool isValidEmail(String email) {
  return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
}
```

### 8. Conditional Messages

Different messages based on result.

```dart
Future<void> processOrder(BuildContext context) async {
  final result = await api.processOrder(orderId);

  if (result.success) {
    await context.showSuccess(
      "Đơn hàng #${orderId} đã được xử lý thành công",
    );
  } else {
    await context.showErrorMsg(
      "Lỗi xử lý đơn hàng: ${result.error}",
    );
  }
}
```

### 9. Sequential Messages

Show multiple messages in sequence.

```dart
Future<void> multiStepProcess(BuildContext context) async {
  // Step 1
  await api.step1();
  await context.showSuccess("Bước 1 hoàn tất");

  // Step 2
  await api.step2();
  await context.showSuccess("Bước 2 hoàn tất");

  // Step 3
  await api.step3();
  await context.showSuccess("Hoàn tất tất cả các bước");
}
```

### 10. Warning Before Destructive Action

Multiple confirmations for critical actions.

```dart
Future<void> deleteAllData(BuildContext context) async {
  // First confirmation
  final confirm1 = await context.showWarning(
    "Bạn có chắc muốn xóa toàn bộ dữ liệu?",
    title: "Cảnh báo",
  );

  if (!confirm1) return;

  // Second confirmation
  final confirm2 = await context.showWarning(
    "Hành động này không thể hoàn tác. Tiếp tục?",
    title: "Xác nhận lần cuối",
    confirmText: "Xóa ngay",
    cancelText: "Hủy bỏ",
  );

  if (!confirm2) return;

  // Proceed with deletion
  await api.deleteAllData();
  
  await context.showSuccess("Đã xóa toàn bộ dữ liệu");
}
```

---

## Features

### 1. iOS-Style Design

Exact iOS alert styling:
- 270px width
- Rounded corners (14px)
- iOS colors (Blue #007AFF, Red #FF3B30)
- System font (SF Pro)
- Subtle animations

### 2. Three Alert Types

**Default (Success):**
- Blue confirm button
- Single OK button
- For success messages

**Warning:**
- Blue buttons
- OK + Cancel buttons
- For confirmations

**Error:**
- Red confirm button (destructive)
- Single OK button
- For error messages

### 3. Bilingual Support

Auto text based on language:
```dart
setText('Thông báo', 'Notification')
setText('Cảnh báo', 'Warning')
setText('Lỗi', 'Error')
```

### 4. Async/Await Pattern

```dart
final result = await message.V_MsgBox(context);

if (result) {
  // User confirmed
} else {
  // User cancelled
}
```

### 5. Extension Methods

Convenient shortcuts:
```dart
context.showSuccess("OK");
context.showWarning("Confirm?");
context.showErrorMsg("Error");
```

### 6. Validation Helpers

Built-in validation support:
```dart
context.validateFields({...});
context.showValidationError(...);
```

---

## Best Practices

### 1. Use Appropriate Type

```dart
// ✅ GOOD: Success
await context.showSuccess("Lưu thành công");

// ✅ GOOD: Confirmation
await context.showWarning("Xóa?");

// ✅ GOOD: Error
await context.showErrorMsg("Lỗi kết nối");

// ❌ BAD: Wrong type
await context.showSuccess("Lỗi!"); // Should be error
```

### 2. Await Results

```dart
// ✅ GOOD: Await and check
final confirmed = await context.showWarning("Delete?");
if (confirmed) {
  delete();
}

// ❌ BAD: Ignore result
context.showWarning("Delete?"); // No await!
delete(); // Runs immediately!
```

### 3. Clear Messages

```dart
// ✅ GOOD: Clear and concise
"Lưu thành công"
"Bạn có chắc muốn xóa?"
"Email không hợp lệ"

// ❌ BAD: Vague
"OK"
"Error"
"Something went wrong"
```

### 4. Error Details

```dart
// ✅ GOOD: Include details
await context.showErrorMsg(
  "Không thể kết nối đến server: ${e.message}"
);

// ❌ BAD: Generic
await context.showErrorMsg("Lỗi");
```

### 5. Validation Pattern

```dart
// ✅ GOOD: Validate before action
if (!context.validateFields({...})) {
  return; // Stop here
}
await saveData();

// ❌ BAD: No validation
await saveData(); // May fail
```

---

## Troubleshooting

### Message không hiển thị

**Nguyên nhân:** BuildContext không valid

**Giải pháp:**
```dart
// ✅ Use mounted check
if (mounted) {
  await context.showSuccess("OK");
}

// ✅ Use context from builder
Builder(
  builder: (context) {
    return CyberButton(
      onClick: () => context.showSuccess("OK"),
    );
  },
)
```

### Result luôn false

**Nguyên nhân:** Không await

**Giải pháp:**
```dart
// ✅ CORRECT
final result = await message.V_MsgBox(context);

// ❌ WRONG
final result = message.V_MsgBox(context); // No await
```

### Cancel button không hiện

**Nguyên nhân:** Sai type

**Giải pháp:**
```dart
// ✅ CORRECT - Warning has cancel
await message.V_MsgBox(
  context,
  type: CyberMsgBoxType.warning,
);

// ❌ WRONG - Default/Error no cancel
await message.V_MsgBox(
  context,
  type: CyberMsgBoxType.defaultType,
);
```

### Text bị cắt

**Nguyên nhân:** Message quá dài

**Giải pháp:**
```dart
// ✅ GOOD: Concise
"Email không hợp lệ"

// ❌ BAD: Too long
"The email address you entered is not in the correct format. Please enter a valid email address with @ symbol and domain name."

// Better: Use line breaks
"Email không hợp lệ.\n\nVui lòng nhập email có @ và tên miền."
```

### Multiple alerts stacking

**Nguyên nhân:** Không await

**Giải pháp:**
```dart
// ✅ GOOD: Sequential
await context.showSuccess("Step 1");
await context.showSuccess("Step 2");

// ❌ BAD: Parallel
context.showSuccess("Step 1"); // No await
context.showSuccess("Step 2"); // Both show at once!
```

---

## Tips & Tricks

### 1. Success After Action

```dart
Future<void> saveAndNotify() async {
  await saveData();
  await context.showSuccess("Lưu thành công");
  Navigator.pop(context);
}
```

### 2. Confirm Dangerous Actions

```dart
Future<void> deleteWithConfirm() async {
  final confirmed = await context.showWarning(
    "Hành động này không thể hoàn tác",
    confirmText: "Xóa",
  );

  if (confirmed) {
    await delete();
    await context.showSuccess("Đã xóa");
  }
}
```

### 3. Error with Retry

```dart
Future<void> loadDataWithRetry() async {
  try {
    await loadData();
  } catch (e) {
    final retry = await context.showWarning(
      "Lỗi tải dữ liệu. Thử lại?",
      confirmText: "Thử lại",
      cancelText: "Hủy",
    );

    if (retry) {
      await loadDataWithRetry(); // Recursive
    }
  }
}
```

### 4. Validation Chain

```dart
bool validateEmail() {
  if (email.isEmpty) {
    context.showValidationError('Email', 'Không được để trống');
    return false;
  }
  
  if (!isValidEmail(email)) {
    context.showValidationError('Email', 'Định dạng không hợp lệ');
    return false;
  }
  
  return true;
}
```

### 5. Dynamic Message

```dart
Future<void> processItems(int count) async {
  await process();
  
  await context.showSuccess(
    "Đã xử lý $count mục thành công",
  );
}
```

### 6. Custom Title Per Type

```dart
// Auto title by type
await "Message".V_MsgBox(context);

// Custom title
await "Message".V_MsgBox(
  context,
  title: "Custom Title",
);
```

### 7. Action Result Notification

```dart
Future<void> submit() async {
  final result = await api.submit();
  
  if (result.isSuccess) {
    await context.showSuccess(result.message);
  } else {
    await context.showErrorMsg(result.error);
  }
}
```

---

## Performance Tips

1. **Await Messages**: Always await to prevent stacking
2. **Short Messages**: Keep messages concise
3. **Mounted Check**: Check if widget is mounted
4. **Avoid Loops**: Don't show alerts in loops
5. **Sequential Flow**: Show one at a time

---

## Design Specifications

### iOS Alert Styling

```dart
// Width
270px (fixed)

// Corners
14px rounded

// Colors
Blue:   #007AFF (iOS System Blue)
Red:    #FF3B30 (iOS Destructive Red)
Gray:   #F2F2F7 (iOS Background)

// Typography
Title:   17pt, Semi-bold, -0.41 tracking
Message: 13pt, Regular, -0.08 tracking
Button:  17pt, Regular/Semi-bold, -0.41 tracking

// Button Height
44px (iOS standard)

// Divider
0.5px, #BBBBC8
```

---

## Comparison Table

| Type | Color | Buttons | Use Case |
|------|-------|---------|----------|
| **defaultType** | Blue | OK | Success notifications |
| **warning** | Blue | OK, Cancel | Confirmations |
| **error** | Red | OK | Error messages |

---

## Version History

### 1.0.0
- Initial release
- iOS-style design
- 3 alert types
- String extensions
- BuildContext extensions
- Validation helpers
- Bilingual support

---

## License

MIT License - CyberFramework
