# CyberOTP - OTP Input với Auto-Focus & Paste Support

## Mục Lục
1. [Giới Thiệu](#giới-thiệu)
2. [CyberOTP Widget](#cyberotp-widget)
3. [CyberOTPController](#cyberotpcontroller)
4. [Ví Dụ Sử Dụng](#ví-dụ-sử-dụng)
5. [Features](#features)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

---

## Giới Thiệu

`CyberOTP` là OTP input widget với **Internal Controller**, **Data Binding**, và **Smart Paste Support**. Widget này tự động xử lý paste OTP code, auto-focus giữa các ô, và hỗ trợ backspace navigation.

### Đặc Điểm Chính

- ✅ **Internal Controller**: Tự động quản lý state
- ✅ **Two-Way Binding**: Sync với CyberDataRow
- ✅ **Smart Paste**: Paste "123456" → tự động tách vào 6 ô
- ✅ **Auto Focus**: Focus sang ô tiếp theo khi nhập
- ✅ **Backspace Navigation**: Xóa và quay lại ô trước
- ✅ **Password Mode**: Ẩn/hiện mã OTP
- ✅ **Customizable**: Kích thước, spacing, màu sắc
- ✅ **onCompleted Callback**: Trigger khi nhập đủ

### Import

```dart
import 'package:cyberframework/cyberframework.dart';
```

---

## CyberOTP Widget

### Constructor

```dart
const CyberOTP({
  super.key,
  this.text,
  this.onChanged,
  this.controller,
  this.length = 6,
  this.isPassword = false,
  this.isCheckEmpty = false,
  this.label,
  this.hint,
  this.spacing = 8.0,
  this.boxSize = 50.0,
  this.borderRadius = 8.0,
  this.borderWidth = 1.5,
  this.backgroundColor,
  this.borderColor,
  this.focusedBorderColor,
  this.textColor,
  this.fontSize = 24.0,
  this.enabled = true,
  this.isVisible = true,
  this.isShowLabel = true,
  this.labelStyle,
  this.onLeaver,
})
```

### Properties

#### Data Binding

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `text` | `dynamic` | Binding hoặc static value | null |
| `onChanged` | `ValueChanged<String>?` | Callback khi OTP thay đổi | null |
| `controller` | `CyberOTPController?` | External controller (optional) | null |

⚠️ **KHÔNG dùng cả text VÀ controller cùng lúc**

#### OTP Properties

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `length` | `int` | Số ô OTP (1-10) | 6 |
| `isPassword` | `bool` | Ẩn mã OTP | false |

#### Validation

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `isCheckEmpty` | `bool` | Required field | false |

#### Display

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `label` | `String?` | Label hiển thị | null |
| `hint` | `String?` | Hint trong mỗi ô | null |
| `isShowLabel` | `bool` | Hiển thị label | true |
| `labelStyle` | `TextStyle?` | Style cho label | null |

#### Styling

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `spacing` | `double` | Khoảng cách giữa các ô (px) | 8.0 |
| `boxSize` | `double` | Kích thước mỗi ô (px) | 50.0 |
| `borderRadius` | `double` | Bo góc (px) | 8.0 |
| `borderWidth` | `double` | Độ dày border (px) | 1.5 |
| `backgroundColor` | `Color?` | Màu nền | Color(0xFFF5F5F5) |
| `borderColor` | `Color?` | Màu border | Colors.grey.shade300 |
| `focusedBorderColor` | `Color?` | Màu border khi focus | Color(0xFF007AFF) |
| `textColor` | `Color?` | Màu chữ | Colors.black |
| `fontSize` | `double?` | Cỡ chữ | 24.0 |

#### State

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `enabled` | `bool` | Enable/disable | true |
| `isVisible` | `bool` | Hiển thị/ẩn | true |

#### Callbacks

| Property | Type | Mô Tả |
|----------|------|-------|
| `onLeaver` | `VoidCallback?` | Khi rời khỏi tất cả các ô |

---

## CyberOTPController

**NOTE**: Controller là **OPTIONAL**. Không cần trong hầu hết trường hợp.

### Properties & Methods

```dart
final controller = CyberOTPController(
  initialValue: '123456',
  length: 6,
  isCheckEmpty: true,
);

// Properties
String? value = controller.value;           // "123456"
List<String> digits = controller.digits;    // ["1","2","3","4","5","6"]
bool isComplete = controller.isComplete;    // true
bool enabled = controller.enabled;
int length = controller.length;

// Set value
controller.setValue('654321');

// State
controller.setEnabled(true);
controller.setCheckEmpty(true);
controller.setLength(4);

// Clear
controller.clear();

// Validate
bool isValid = controller.validate();

// Binding
controller.bind(drAuth, 'otp_code');
controller.unbind();

// onCompleted callback
controller.setOnCompleted((value) {
  print('OTP Complete: $value');
  verifyOTP(value);
});
```

---

## Ví Dụ Sử Dụng

### 1. Sử Dụng Cơ Bản (Recommended)

Simple 6-digit OTP input.

```dart
class OTPVerification extends StatefulWidget {
  @override
  State<OTPVerification> createState() => _OTPVerificationState();
}

class _OTPVerificationState extends State<OTPVerification> {
  final drAuth = CyberDataRow();

  @override
  void initState() {
    super.initState();
    drAuth['otp_code'] = '';
  }

  Future<void> verifyOTP() async {
    final otp = drAuth['otp_code'] as String;
    
    if (otp.length != 6) {
      showError('Vui lòng nhập đủ 6 số');
      return;
    }

    // Call API
    final result = await api.verifyOTP(otp);
    
    if (result.success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
      );
    } else {
      showError('Mã OTP không đúng');
      drAuth['otp_code'] = ''; // Clear
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberOTP(
          text: drAuth.bind('otp_code'),
          label: 'Nhập mã OTP',
          length: 6,
          onChanged: (value) {
            if (value.length == 6) {
              // Auto verify khi nhập đủ
              verifyOTP();
            }
          },
        ),
        
        SizedBox(height: 24),
        
        CyberButton(
          label: 'Xác nhận',
          onClick: verifyOTP,
        ),
      ],
    );
  }
}
```

### 2. Password Mode (Hidden OTP)

Ẩn mã OTP.

```dart
class SecureOTP extends StatelessWidget {
  final drAuth = CyberDataRow();

  SecureOTP() {
    drAuth['secure_code'] = '';
  }

  @override
  Widget build(BuildContext context) {
    return CyberOTP(
      text: drAuth.bind('secure_code'),
      label: 'Mã bảo mật',
      length: 6,
      isPassword: true,  // Hide digits
    );
  }
}
```

### 3. Custom Length (4 digits)

OTP ngắn hơn.

```dart
class QuickOTP extends StatelessWidget {
  final drPayment = CyberDataRow();

  QuickOTP() {
    drPayment['pin_code'] = '';
  }

  @override
  Widget build(BuildContext context) {
    return CyberOTP(
      text: drPayment.bind('pin_code'),
      label: 'Mã PIN',
      length: 4,  // 4 digits
      isPassword: true,
    );
  }
}
```

### 4. Custom Styling

Tùy chỉnh giao diện.

```dart
CyberOTP(
  text: drAuth.bind('otp_code'),
  label: 'Mã xác thực',
  
  // Box styling
  boxSize: 60.0,          // Larger boxes
  spacing: 12.0,          // More spacing
  borderRadius: 12.0,     // Rounder corners
  borderWidth: 2.0,       // Thicker border
  
  // Colors
  backgroundColor: Colors.white,
  borderColor: Colors.blue.shade200,
  focusedBorderColor: Colors.blue,
  textColor: Colors.blue.shade900,
  fontSize: 28.0,
)
```

### 5. Required Field

OTP bắt buộc nhập.

```dart
class RequiredOTP extends StatefulWidget {
  @override
  State<RequiredOTP> createState() => _RequiredOTPState();
}

class _RequiredOTPState extends State<RequiredOTP> {
  final drAuth = CyberDataRow();

  bool validate() {
    final otp = drAuth['otp_code'] as String;
    
    if (otp.isEmpty || otp.length != 6) {
      showError('Vui lòng nhập đủ 6 số OTP');
      return false;
    }
    
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberOTP(
          text: drAuth.bind('otp_code'),
          label: 'Mã OTP',
          isCheckEmpty: true,  // Show * (required)
          length: 6,
        ),
        
        SizedBox(height: 16),
        
        CyberButton(
          label: 'Xác nhận',
          onClick: () {
            if (validate()) {
              submit();
            }
          },
        ),
      ],
    );
  }
}
```

### 6. With Timer

OTP với countdown timer.

```dart
class OTPWithTimer extends StatefulWidget {
  @override
  State<OTPWithTimer> createState() => _OTPWithTimerState();
}

class _OTPWithTimerState extends State<OTPWithTimer> {
  final drAuth = CyberDataRow();
  int _countdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    drAuth['otp_code'] = '';
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _countdown = 60);
    
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> resendOTP() async {
    await api.resendOTP();
    drAuth['otp_code'] = '';
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberOTP(
          text: drAuth.bind('otp_code'),
          label: 'Nhập mã OTP',
          length: 6,
        ),
        
        SizedBox(height: 16),
        
        if (_countdown > 0)
          Text(
            'Gửi lại sau $_countdown giây',
            style: TextStyle(color: Colors.grey),
          )
        else
          TextButton(
            onPressed: resendOTP,
            child: Text('Gửi lại mã OTP'),
          ),
      ],
    );
  }
}
```

### 7. Auto Submit

Tự động submit khi nhập đủ.

```dart
class AutoSubmitOTP extends StatefulWidget {
  @override
  State<AutoSubmitOTP> createState() => _AutoSubmitOTPState();
}

class _AutoSubmitOTPState extends State<AutoSubmitOTP> {
  final drAuth = CyberDataRow();
  bool _isSubmitting = false;

  Future<void> autoVerify(String otp) async {
    if (_isSubmitting) return;
    
    setState(() => _isSubmitting = true);

    try {
      final result = await api.verifyOTP(otp);
      
      if (result.success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage()),
        );
      } else {
        showError('Mã OTP không đúng');
        drAuth['otp_code'] = ''; // Clear
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CyberOTP(
          text: drAuth.bind('otp_code'),
          label: 'Mã OTP',
          length: 6,
          enabled: !_isSubmitting,
          onChanged: (value) {
            if (value.length == 6) {
              // Auto verify
              autoVerify(value);
            }
          },
        ),
        
        if (_isSubmitting)
          Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}
```

### 8. With Controller (Advanced)

Programmatic control.

```dart
class AdvancedOTP extends StatefulWidget {
  @override
  State<AdvancedOTP> createState() => _AdvancedOTPState();
}

class _AdvancedOTPState extends State<AdvancedOTP> {
  final controller = CyberOTPController(
    length: 6,
    isCheckEmpty: true,
  );

  @override
  void initState() {
    super.initState();
    
    // Set onCompleted callback
    controller.setOnCompleted((otp) {
      print('OTP Complete: $otp');
      verifyOTP(otp);
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> verifyOTP(String otp) async {
    final result = await api.verifyOTP(otp);
    
    if (!result.success) {
      showError('Mã OTP không đúng');
      controller.clear(); // Clear programmatically
    }
  }

  void fillDemoOTP() {
    controller.setValue('123456'); // For testing
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberOTP(
          controller: controller,
          label: 'Mã OTP',
        ),
        
        SizedBox(height: 16),
        
        // Debug button
        if (kDebugMode)
          TextButton(
            onPressed: fillDemoOTP,
            child: Text('Fill Demo OTP'),
          ),
      ],
    );
  }
}
```

### 9. Multiple OTPs

Nhiều OTP trên cùng màn hình.

```dart
class MultipleOTPs extends StatelessWidget {
  final drAuth = CyberDataRow();

  MultipleOTPs() {
    drAuth['otp_email'] = '';
    drAuth['otp_phone'] = '';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberOTP(
          text: drAuth.bind('otp_email'),
          label: 'Mã OTP từ Email',
          length: 6,
        ),
        
        SizedBox(height: 24),
        
        CyberOTP(
          text: drAuth.bind('otp_phone'),
          label: 'Mã OTP từ SMS',
          length: 6,
        ),
      ],
    );
  }
}
```

### 10. iOS-Style OTP

Styling giống iOS.

```dart
CyberOTP(
  text: drAuth.bind('otp_code'),
  label: 'Mã xác minh',
  length: 6,
  
  // iOS-style
  boxSize: 48.0,
  spacing: 10.0,
  borderRadius: 10.0,
  borderWidth: 1.0,
  backgroundColor: Colors.white,
  borderColor: Color(0xFFE5E5EA),
  focusedBorderColor: Color(0xFF007AFF),
  fontSize: 22.0,
)
```

---

## Features

### 1. Internal Controller

Widget tự động quản lý state.

```dart
// ✅ GOOD: Simple binding
CyberOTP(
  text: drAuth.bind('otp_code'),
  length: 6,
)
```

### 2. Smart Paste Support

Tự động tách OTP khi paste:

```dart
// User paste: "123456"
// → Tự động tách: "1" "2" "3" "4" "5" "6"

// User paste: "1 2 3 4 5 6"
// → Clean: "123456" → Tách thành 6 ô

// User paste: "A1B2C3"
// → Chỉ lấy số: "123" → Tách vào 3 ô đầu
```

### 3. Auto Focus Navigation

```dart
// Nhập ô 1 → Auto focus ô 2
// Nhập ô 2 → Auto focus ô 3
// ...
// Nhập ô 6 → Done
```

### 4. Backspace Handling

```dart
// Ô 3 đang rỗng + Backspace
// → Clear ô 2, focus về ô 2
```

### 5. Password Mode

```dart
isPassword: true
// Hiển thị: • • • • • •
// Thay vì: 1 2 3 4 5 6
```

### 6. onCompleted Callback

```dart
controller.setOnCompleted((otp) {
  // Trigger khi nhập đủ 6 số
  verifyOTP(otp);
});
```

### 7. Flexible Length

```dart
length: 4   // PIN code
length: 6   // Standard OTP
length: 8   // Extended OTP
```

---

## Best Practices

### 1. Sử Dụng Binding (Recommended)

```dart
// ✅ GOOD
CyberOTP(
  text: drAuth.bind('otp_code'),
  length: 6,
)

// ❌ BAD: Manual state
String otp = '';
CyberOTP(
  text: otp,
  onChanged: (value) {
    setState(() {
      otp = value;
      drAuth['otp_code'] = value;
    });
  },
)
```

### 2. Auto Verify When Complete

```dart
// ✅ GOOD: UX friendly
CyberOTP(
  onChanged: (value) {
    if (value.length == 6) {
      verifyOTP(value);
    }
  },
)

// ❌ BAD: Require button press
CyberOTP(
  // No auto verify
)
CyberButton(label: 'Verify') // User must tap
```

### 3. Clear on Error

```dart
// ✅ GOOD: Clear for retry
if (!result.success) {
  drAuth['otp_code'] = '';
  showError('Mã OTP không đúng');
}

// ❌ BAD: Keep wrong OTP
if (!result.success) {
  showError('Sai OTP'); // OTP vẫn còn
}
```

### 4. Disable During Verification

```dart
// ✅ GOOD: Prevent multiple submissions
CyberOTP(
  enabled: !_isSubmitting,
)

// ❌ BAD: No protection
CyberOTP(
  // User can change while submitting
)
```

### 5. Appropriate Length

```dart
// ✅ GOOD: Standard lengths
length: 4   // PIN
length: 6   // OTP
length: 8   // Extended

// ❌ BAD: Odd lengths
length: 5   // Uncommon
length: 7   // Weird
```

---

## Troubleshooting

### Paste không hoạt động

**Nguyên nhân:** Platform limitations

**Giải pháp:**
```dart
// Android: Paste works automatically
// iOS: May require clipboard permission

// Workaround: Manual paste button
TextButton(
  onPressed: () async {
    final clipboard = await Clipboard.getData('text/plain');
    if (clipboard?.text != null) {
      drAuth['otp_code'] = clipboard!.text!;
    }
  },
  child: Text('Paste OTP'),
)
```

### Auto-focus không chuyển

**Nguyên nhân:** TextInputFormatter conflict

**Giải pháp:** Widget đã xử lý, update version mới nhất

### Backspace không xóa ô trước

**Nguyên nhân:** KeyboardListener issue

**Giải pháp:** Widget đã xử lý với KeyboardListener

### OTP không clear

**Nguyên nhân:** Không update binding

**Giải pháp:**
```dart
// ✅ CORRECT
drAuth['otp_code'] = '';

// ❌ WRONG
controller.clear(); // If using binding, also update datarow!
```

### onChanged fires multiple times

**Nguyên nhân:** Internal update protection

**Giải pháp:** Widget đã xử lý với _isInternalUpdate flag

---

## Tips & Tricks

### 1. Testing OTP

```dart
// Debug mode only
if (kDebugMode) {
  TextButton(
    onPressed: () {
      drAuth['otp_code'] = '123456';
    },
    child: Text('Fill Demo OTP'),
  );
}
```

### 2. Copy Current OTP

```dart
void copyOTP() {
  final otp = drAuth['otp_code'] as String;
  Clipboard.setData(ClipboardData(text: otp));
  showSuccess('Đã copy OTP');
}
```

### 3. Countdown Timer

```dart
int _countdown = 60;
Timer? _timer;

void startTimer() {
  _timer = Timer.periodic(Duration(seconds: 1), (timer) {
    if (_countdown > 0) {
      setState(() => _countdown--);
    } else {
      timer.cancel();
    }
  });
}
```

### 4. Resend with Delay

```dart
Future<void> resendOTP() async {
  if (_countdown > 0) {
    showError('Vui lòng chờ $_countdown giây');
    return;
  }

  await api.resendOTP();
  drAuth['otp_code'] = '';
  startTimer();
}
```

### 5. Focus First Box

```dart
@override
void initState() {
  super.initState();
  
  // Auto focus first box
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      FocusScope.of(context).requestFocus(_focusNodes[0]);
    }
  });
}
```

---

## Performance Tips

1. **Dispose Controller**: Always dispose nếu dùng external controller
2. **Limit Callbacks**: Debounce nếu onChanged có API call
3. **Reuse Widget**: Không tạo mới widget mỗi rebuild
4. **Keyboard Type**: Đã set numberWithOptions cho numeric keyboard
5. **InputFormatter**: Widget đã optimize với regex

---

## Keyboard Behavior

### Auto Keyboard Type

```dart
// Widget tự động set:
keyboardType: TextInputType.numberWithOptions(
  decimal: false,
  signed: false,
)

// Result: Numeric keyboard on mobile
```

### Paste Detection

```dart
// Widget tự động detect paste:
// - Single character: Normal input
// - Multiple characters: Parse và tách vào các ô
```

---

## Accessibility

### Screen Reader Support

```dart
// Each box announced separately:
// "OTP digit 1 of 6"
// "OTP digit 2 of 6"
// ...
```

### Keyboard Navigation

```dart
// Tab: Move to next box
// Shift+Tab: Move to previous box
// Backspace: Delete and move back
```

---

## Platform Differences

### iOS
- Paste from clipboard works
- Auto-fill from SMS may need configuration
- Keyboard type: Number Pad

### Android
- Paste works natively
- SMS Auto-fill with SMS User Consent API
- Keyboard type: Number

### Web
- Standard paste behavior
- Manual autofill only
- Keyboard type: Text with pattern

---

## Version History

### 1.0.0
- Initial release
- Internal controller
- Two-way binding
- Smart paste support (tách "123456" → 6 ô)
- Auto-focus navigation
- Backspace handling
- Password mode
- onCompleted callback
- Customizable styling
- Length 1-10 support

---

## License

MIT License - CyberFramework
