# CyberButton - Custom Button Widget

## Mục Lục
1. [Giới Thiệu](#giới-thiệu)
2. [Properties](#properties)
3. [Ví Dụ Sử Dụng](#ví-dụ-sử-dụng)
4. [Use Cases](#use-cases)
5. [Best Practices](#best-practices)
6. [Customization](#customization)
7. [Troubleshooting](#troubleshooting)

---

## Giới Thiệu

`CyberButton` là một custom button widget được thiết kế để có styling nhất quán trong toàn bộ ứng dụng. Widget này cung cấp giao diện đẹp mắt, dễ sử dụng với hỗ trợ readonly state.

### Đặc Điểm Chính

- ✅ Full width button (chiếm toàn bộ chiều ngang)
- ✅ Consistent styling across app
- ✅ Readonly/disabled state support
- ✅ Customizable colors, padding, border radius
- ✅ Bold text với font size tối ưu
- ✅ Material Design ripple effect

### Import

```dart
import 'package:cyberframework/cyberframework.dart';
```

---

## Properties

### Constructor

```dart
const CyberButton({
  super.key,
  required this.label,
  this.onClick,
  this.backgroundColor = const Color(0xFF00D287),
  this.textColor = Colors.white,
  this.borderRadius = 30.0,
  this.paddingVertical = 12.0,
  this.paddingHorizontal = 10.0,
  this.isReadOnly = false,
})
```

### Properties Table

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `label` | `String` | Text hiển thị trên button | Required |
| `onClick` | `VoidCallback?` | Callback khi button được click | null |
| `backgroundColor` | `Color` | Màu nền của button | Color(0xFF00D287) (xanh lá) |
| `textColor` | `Color` | Màu chữ trên button | Colors.white |
| `borderRadius` | `double` | Độ bo góc của button | 30.0 |
| `paddingVertical` | `double` | Padding theo chiều dọc | 12.0 |
| `paddingHorizontal` | `double` | Padding theo chiều ngang | 10.0 |
| `isReadOnly` | `bool` | Button ở trạng thái disabled | false |

---

## Ví Dụ Sử Dụng

### 1. Button Cơ Bản

Button đơn giản với màu mặc định.

```dart
CyberButton(
  label: 'Đăng Nhập',
  onClick: () {
    print('Login button clicked');
    // Handle login logic
  },
)
```

### 2. Button Với Custom Colors

Tùy chỉnh màu nền và màu chữ.

```dart
// Blue button
CyberButton(
  label: 'Lưu',
  onClick: () => save(),
  backgroundColor: Colors.blue,
  textColor: Colors.white,
)

// Red button (destructive action)
CyberButton(
  label: 'Xóa',
  onClick: () => delete(),
  backgroundColor: Colors.red,
  textColor: Colors.white,
)

// Custom color
CyberButton(
  label: 'Gửi',
  onClick: () => submit(),
  backgroundColor: Color(0xFF6C63FF),
  textColor: Colors.white,
)
```

### 3. Button Với Custom Shape

Thay đổi border radius để có shape khác nhau.

```dart
// Rounded button (default)
CyberButton(
  label: 'Rounded',
  borderRadius: 30.0,
  onClick: () => action(),
)

// Slightly rounded
CyberButton(
  label: 'Slightly Rounded',
  borderRadius: 8.0,
  onClick: () => action(),
)

// Rectangle button
CyberButton(
  label: 'Rectangle',
  borderRadius: 0.0,
  onClick: () => action(),
)

// Pill shape
CyberButton(
  label: 'Pill',
  borderRadius: 50.0,
  onClick: () => action(),
)
```

### 4. Button Với Custom Padding

Điều chỉnh kích thước button thông qua padding.

```dart
// Large button
CyberButton(
  label: 'Large Button',
  paddingVertical: 20.0,
  paddingHorizontal: 30.0,
  onClick: () => action(),
)

// Small button
CyberButton(
  label: 'Small',
  paddingVertical: 8.0,
  paddingHorizontal: 12.0,
  onClick: () => action(),
)

// Extra wide button
CyberButton(
  label: 'Wide',
  paddingVertical: 12.0,
  paddingHorizontal: 50.0,
  onClick: () => action(),
)
```

### 5. Readonly/Disabled Button

Button ở trạng thái disabled.

```dart
class FormScreen extends StatefulWidget {
  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  bool isProcessing = false;

  Future<void> submit() async {
    setState(() {
      isProcessing = true;
    });

    // Simulate processing
    await Future.delayed(Duration(seconds: 2));
    
    setState(() {
      isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ... form fields
          
          CyberButton(
            label: isProcessing ? 'Đang xử lý...' : 'Gửi đơn',
            onClick: submit,
            isReadOnly: isProcessing, // Disable while processing
            backgroundColor: isProcessing ? Colors.grey : Colors.blue,
          ),
        ],
      ),
    );
  }
}
```

### 6. Form Buttons

Nhiều buttons trong một form.

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    // Form fields
    TextField(
      decoration: InputDecoration(labelText: 'Username'),
    ),
    SizedBox(height: 16),
    TextField(
      decoration: InputDecoration(labelText: 'Password'),
      obscureText: true,
    ),
    SizedBox(height: 24),
    
    // Primary action
    CyberButton(
      label: 'Đăng Nhập',
      onClick: () => login(),
      backgroundColor: Colors.green,
    ),
    SizedBox(height: 12),
    
    // Secondary action
    CyberButton(
      label: 'Quên mật khẩu?',
      onClick: () => forgotPassword(),
      backgroundColor: Colors.grey,
    ),
    SizedBox(height: 12),
    
    // Tertiary action
    CyberButton(
      label: 'Đăng ký',
      onClick: () => register(),
      backgroundColor: Colors.blue,
    ),
  ],
)
```

### 7. Button Trong Dialog

```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Xác nhận'),
    content: Text('Bạn có chắc muốn xóa item này?'),
    actions: [
      // Cancel button
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Hủy'),
      ),
      
      // Confirm button - full width in column
      SizedBox(
        width: double.infinity,
        child: CyberButton(
          label: 'Xóa',
          onClick: () {
            Navigator.pop(context);
            deleteItem();
          },
          backgroundColor: Colors.red,
        ),
      ),
    ],
  ),
);
```

### 8. Button Với Loading State

```dart
class SubmitButton extends StatefulWidget {
  final VoidCallback onSubmit;
  
  const SubmitButton({required this.onSubmit});

  @override
  State<SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<SubmitButton> {
  bool _isLoading = false;

  Future<void> _handleSubmit() async {
    setState(() => _isLoading = true);
    
    try {
      await widget.onSubmit();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CyberButton(
      label: _isLoading ? 'Đang xử lý...' : 'Gửi',
      onClick: _isLoading ? null : _handleSubmit,
      isReadOnly: _isLoading,
      backgroundColor: _isLoading ? Colors.grey : Colors.blue,
    );
  }
}
```

### 9. Icon + Text Button

Kết hợp với icon.

```dart
Row(
  children: [
    Expanded(
      child: CyberButton(
        label: '  Đăng nhập với Google', // Space for icon
        onClick: () => loginWithGoogle(),
        backgroundColor: Colors.white,
        textColor: Colors.black87,
      ),
    ),
  ],
)

// Hoặc tạo custom widget
class IconCyberButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onClick;
  final Color? backgroundColor;
  final Color? textColor;

  const IconCyberButton({
    required this.label,
    required this.icon,
    this.onClick,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onClick,
      icon: Icon(icon),
      label: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? Color(0xFF00D287),
        foregroundColor: textColor ?? Colors.white,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }
}
```

### 10. Gradient Button

Kết hợp với Container để tạo gradient.

```dart
class GradientCyberButton extends StatelessWidget {
  final String label;
  final VoidCallback? onClick;
  final Gradient gradient;
  final Color textColor;
  final double borderRadius;
  final bool isReadOnly;

  const GradientCyberButton({
    required this.label,
    this.onClick,
    required this.gradient,
    this.textColor = Colors.white,
    this.borderRadius = 30.0,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: isReadOnly ? null : gradient,
        color: isReadOnly ? Colors.grey : null,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isReadOnly ? null : onClick,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Usage
GradientCyberButton(
  label: 'Gradient Button',
  gradient: LinearGradient(
    colors: [Colors.purple, Colors.blue],
  ),
  onClick: () => action(),
)
```

---

## Use Cases

### 1. Form Submission

```dart
class LoginForm extends StatelessWidget {
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            decoration: InputDecoration(labelText: 'Email'),
            validator: (value) => 
              value?.isEmpty ?? true ? 'Required' : null,
          ),
          SizedBox(height: 16),
          TextFormField(
            decoration: InputDecoration(labelText: 'Password'),
            obscureText: true,
            validator: (value) => 
              value?.isEmpty ?? true ? 'Required' : null,
          ),
          SizedBox(height: 24),
          CyberButton(
            label: 'Login',
            onClick: () {
              if (formKey.currentState!.validate()) {
                // Submit form
              }
            },
          ),
        ],
      ),
    );
  }
}
```

### 2. Navigation

```dart
Column(
  children: [
    CyberButton(
      label: 'Go to Dashboard',
      onClick: () => Navigator.pushNamed(context, '/dashboard'),
      backgroundColor: Colors.blue,
    ),
    SizedBox(height: 12),
    CyberButton(
      label: 'Go Back',
      onClick: () => Navigator.pop(context),
      backgroundColor: Colors.grey,
    ),
  ],
)
```

### 3. CRUD Operations

```dart
Row(
  children: [
    Expanded(
      child: CyberButton(
        label: 'Save',
        onClick: () => save(),
        backgroundColor: Colors.green,
      ),
    ),
    SizedBox(width: 12),
    Expanded(
      child: CyberButton(
        label: 'Cancel',
        onClick: () => cancel(),
        backgroundColor: Colors.red,
      ),
    ),
  ],
)
```

### 4. Async Operations

```dart
class AsyncButton extends StatefulWidget {
  @override
  State<AsyncButton> createState() => _AsyncButtonState();
}

class _AsyncButtonState extends State<AsyncButton> {
  bool _loading = false;

  Future<void> _process() async {
    setState(() => _loading = true);
    
    try {
      await Future.delayed(Duration(seconds: 2));
      // Do something
    } catch (e) {
      showError(e);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CyberButton(
      label: _loading ? 'Processing...' : 'Process',
      onClick: _process,
      isReadOnly: _loading,
    );
  }
}
```

### 5. Multi-Step Forms

```dart
class MultiStepForm extends StatefulWidget {
  @override
  State<MultiStepForm> createState() => _MultiStepFormState();
}

class _MultiStepFormState extends State<MultiStepForm> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Steps content
        _buildStepContent(_currentStep),
        
        SizedBox(height: 24),
        
        // Navigation buttons
        Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: CyberButton(
                  label: 'Previous',
                  onClick: () {
                    setState(() => _currentStep--);
                  },
                  backgroundColor: Colors.grey,
                ),
              ),
            if (_currentStep > 0) SizedBox(width: 12),
            Expanded(
              child: CyberButton(
                label: _currentStep == 2 ? 'Submit' : 'Next',
                onClick: () {
                  if (_currentStep == 2) {
                    submit();
                  } else {
                    setState(() => _currentStep++);
                  }
                },
                backgroundColor: Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
```

---

## Best Practices

### 1. Button Labels

```dart
// ✅ GOOD: Clear, action-oriented
CyberButton(label: 'Lưu', ...)
CyberButton(label: 'Gửi', ...)
CyberButton(label: 'Xóa', ...)
CyberButton(label: 'Đăng nhập', ...)

// ❌ BAD: Vague, unclear
CyberButton(label: 'OK', ...)
CyberButton(label: 'Click here', ...)
CyberButton(label: 'Go', ...)
```

### 2. Color Scheme

```dart
// ✅ GOOD: Meaningful colors
CyberButton(
  label: 'Save',
  backgroundColor: Colors.green, // Positive action
)

CyberButton(
  label: 'Delete',
  backgroundColor: Colors.red, // Destructive action
)

CyberButton(
  label: 'Cancel',
  backgroundColor: Colors.grey, // Neutral action
)

// ❌ BAD: Random colors
CyberButton(
  label: 'Delete',
  backgroundColor: Colors.pink, // Confusing
)
```

### 3. Spacing

```dart
// ✅ GOOD: Proper spacing between buttons
Column(
  children: [
    CyberButton(label: 'Button 1', ...),
    SizedBox(height: 12), // Space between
    CyberButton(label: 'Button 2', ...),
  ],
)

// ❌ BAD: No spacing
Column(
  children: [
    CyberButton(label: 'Button 1', ...),
    CyberButton(label: 'Button 2', ...), // Too close
  ],
)
```

### 4. Loading States

```dart
// ✅ GOOD: Show loading state
CyberButton(
  label: isLoading ? 'Đang xử lý...' : 'Gửi',
  onClick: submit,
  isReadOnly: isLoading,
  backgroundColor: isLoading ? Colors.grey : Colors.blue,
)

// ❌ BAD: No feedback
CyberButton(
  label: 'Gửi',
  onClick: submit, // User can click multiple times
)
```

### 5. Disabled State

```dart
// ✅ GOOD: Visual feedback for disabled state
final canSubmit = formIsValid && !isLoading;

CyberButton(
  label: 'Submit',
  onClick: submit,
  isReadOnly: !canSubmit,
  backgroundColor: canSubmit ? Colors.blue : Colors.grey,
)

// ❌ BAD: onClick is null but button looks enabled
CyberButton(
  label: 'Submit',
  onClick: canSubmit ? submit : null, // No visual feedback
)
```

---

## Customization

### Theme Integration

```dart
// Create themed button variants
class AppButton {
  static CyberButton primary({
    required String label,
    required VoidCallback? onClick,
    bool isReadOnly = false,
  }) {
    return CyberButton(
      label: label,
      onClick: onClick,
      isReadOnly: isReadOnly,
      backgroundColor: Color(0xFF00D287),
      textColor: Colors.white,
    );
  }

  static CyberButton secondary({
    required String label,
    required VoidCallback? onClick,
    bool isReadOnly = false,
  }) {
    return CyberButton(
      label: label,
      onClick: onClick,
      isReadOnly: isReadOnly,
      backgroundColor: Colors.grey,
      textColor: Colors.white,
    );
  }

  static CyberButton danger({
    required String label,
    required VoidCallback? onClick,
    bool isReadOnly = false,
  }) {
    return CyberButton(
      label: label,
      onClick: onClick,
      isReadOnly: isReadOnly,
      backgroundColor: Colors.red,
      textColor: Colors.white,
    );
  }
}

// Usage
AppButton.primary(
  label: 'Save',
  onClick: () => save(),
)

AppButton.danger(
  label: 'Delete',
  onClick: () => delete(),
)
```

### Size Variants

```dart
class ButtonSize {
  static const small = _ButtonSize(
    vertical: 8.0,
    horizontal: 12.0,
    fontSize: 14.0,
  );
  
  static const medium = _ButtonSize(
    vertical: 12.0,
    horizontal: 16.0,
    fontSize: 16.0,
  );
  
  static const large = _ButtonSize(
    vertical: 16.0,
    horizontal: 24.0,
    fontSize: 18.0,
  );
}

class _ButtonSize {
  final double vertical;
  final double horizontal;
  final double fontSize;
  
  const _ButtonSize({
    required this.vertical,
    required this.horizontal,
    required this.fontSize,
  });
}

// Custom button with size
class SizedCyberButton extends StatelessWidget {
  final String label;
  final VoidCallback? onClick;
  final _ButtonSize size;
  final Color? backgroundColor;
  
  const SizedCyberButton({
    required this.label,
    this.onClick,
    this.size = ButtonSize.medium,
    this.backgroundColor,
  });
  
  @override
  Widget build(BuildContext context) {
    return CyberButton(
      label: label,
      onClick: onClick,
      backgroundColor: backgroundColor ?? Color(0xFF00D287),
      paddingVertical: size.vertical,
      paddingHorizontal: size.horizontal,
    );
  }
}

// Usage
SizedCyberButton(
  label: 'Small',
  size: ButtonSize.small,
  onClick: () {},
)
```

---

## Troubleshooting

### Button không full width

**Nguyên nhân:** Parent widget không có constraints

**Giải pháp:**
```dart
// ✅ Wrap in Column/Row với constraints
Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    CyberButton(label: 'Button', ...),
  ],
)

// ✅ Hoặc dùng SizedBox
SizedBox(
  width: double.infinity,
  child: CyberButton(label: 'Button', ...),
)
```

### onClick không hoạt động

**Nguyên nhân:** Button bị disabled hoặc onClick = null

**Giải pháp:**
```dart
// Kiểm tra isReadOnly
CyberButton(
  label: 'Click me',
  onClick: () => print('Clicked'),
  isReadOnly: false, // Phải là false
)

// Kiểm tra onClick không null
CyberButton(
  label: 'Click me',
  onClick: () => print('Clicked'), // Không được null
)
```

### Button bị overflow

**Nguyên nhân:** Label quá dài

**Giải pháp:**
```dart
// Option 1: Rút ngắn label
CyberButton(
  label: 'Submit', // Thay vì 'Submit Form Data'
  ...
)

// Option 2: Sử dụng text wrapping (need custom widget)
```

### Màu không thay đổi khi disabled

**Nguyên nhân:** Không update backgroundColor khi isReadOnly thay đổi

**Giải pháp:**
```dart
// Update backgroundColor based on state
CyberButton(
  label: 'Submit',
  onClick: submit,
  isReadOnly: isProcessing,
  backgroundColor: isProcessing ? Colors.grey : Colors.blue,
)
```

---

## Tips & Tricks

### 1. Reusable Button Components

Tạo button components có thể tái sử dụng:

```dart
class SaveButton extends StatelessWidget {
  final VoidCallback onSave;
  final bool isLoading;
  
  const SaveButton({
    required this.onSave,
    this.isLoading = false,
  });
  
  @override
  Widget build(BuildContext context) {
    return CyberButton(
      label: isLoading ? 'Saving...' : 'Save',
      onClick: isLoading ? null : onSave,
      isReadOnly: isLoading,
      backgroundColor: isLoading ? Colors.grey : Colors.green,
    );
  }
}
```

### 2. Button Group Helper

Tạo helper để group buttons:

```dart
class ButtonGroup extends StatelessWidget {
  final List<CyberButton> buttons;
  final double spacing;
  
  const ButtonGroup({
    required this.buttons,
    this.spacing = 12.0,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: buttons
        .map((button) => Padding(
          padding: EdgeInsets.only(bottom: spacing),
          child: button,
        ))
        .toList(),
    );
  }
}

// Usage
ButtonGroup(
  buttons: [
    CyberButton(label: 'Save', onClick: save),
    CyberButton(label: 'Cancel', onClick: cancel),
  ],
)
```

### 3. Confirmation Dialog Button

```dart
Future<void> showConfirmButton({
  required BuildContext context,
  required String title,
  required String message,
  required VoidCallback onConfirm,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel'),
        ),
        CyberButton(
          label: 'Confirm',
          onClick: () => Navigator.pop(context, true),
          backgroundColor: Colors.red,
        ),
      ],
    ),
  );
  
  if (result == true) {
    onConfirm();
  }
}
```

---

## Performance Tips

1. **Avoid Anonymous Functions**: Dùng named functions cho onClick
2. **Const Constructors**: Sử dụng const khi có thể
3. **Minimize Rebuilds**: Chỉ rebuild khi state thực sự thay đổi

```dart
// ✅ GOOD
class MyWidget extends StatelessWidget {
  void _handleClick() {
    print('Clicked');
  }
  
  @override
  Widget build(BuildContext context) {
    return CyberButton(
      label: 'Click',
      onClick: _handleClick, // Named function
    );
  }
}

// ❌ BAD
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CyberButton(
      label: 'Click',
      onClick: () => print('Clicked'), // Anonymous function
    );
  }
}
```

---

## Version History

### 1.0.0
- Initial release
- Full width button
- Readonly state support
- Customizable colors, padding, border radius
- Material Design ripple effect

---

## License

MIT License - CyberFramework
