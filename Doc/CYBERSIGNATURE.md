# CyberSignature - Signature Control

Control chữ ký cho phép người dùng vẽ và lưu chữ ký dưới dạng base64 image.

## Đặc điểm

✅ **Binding với CyberDataRow** - Tự động đồng bộ 2 chiều
✅ **Internal Controller** - Tự tạo controller nếu không truyền vào
✅ **Flexible Actions** - Ký, Xem, Xóa có thể bật/tắt độc lập
✅ **Base64 Output** - Lưu chữ ký dưới dạng base64 PNG
✅ **Responsive UI** - Tự động điều chỉnh theo kích thước
✅ **Customizable** - Tùy chỉnh màu bút, độ dày, màu nền

## Cấu trúc Files

```
lib/Controller/
├── cyber_signature_controller.dart      # Controller quản lý state
├── cyber_signature_pad.dart             # Dialog vẽ chữ ký
├── cyber_fullscreen_signature_viewer.dart # Viewer xem chữ ký
└── cybersignature.dart                  # Main widget
```

## Cách sử dụng

### 1. Sử dụng cơ bản với Binding

```dart
// Trong form
CyberSignature(
  text: drEdit.bind("signature"),
  label: "Chữ ký khách hàng",
  isSign: true,
  isView: true,
  isClear: true,
)
```

### 2. Sử dụng với Controller

```dart
final signatureCtrl = CyberSignatureController();

CyberSignature(
  controller: signatureCtrl,
  text: drEdit.bind("signature"),
  label: "Chữ ký",
  onSigned: (base64) {
    print('Đã ký: ${base64.substring(0, 50)}...');
  },
)

// Trigger actions từ code
signatureCtrl.triggerSign();  // Mở dialog ký
signatureCtrl.triggerView();  // Xem chữ ký
signatureCtrl.triggerClear(); // Xóa chữ ký
```

### 3. Tùy chỉnh giao diện

```dart
CyberSignature(
  text: drEdit.bind("signature"),
  label: "Chữ ký",
  height: 180,
  width: double.infinity,
  borderRadius: 16,
  backgroundColor: Colors.grey[50],
  borderColor: Colors.blue,
  borderWidth: 2,
  
  // Tùy chỉnh bút vẽ
  penColor: Colors.blue,
  penStrokeWidth: 4.0,
  signaturePadBackgroundColor: Colors.white,
  
  // Tùy chỉnh icons
  signIcon: Icons.create,
  viewIcon: Icons.remove_red_eye,
  clearIcon: Icons.clear,
)
```

### 4. Điều khiển hiển thị chức năng

```dart
CyberSignature(
  text: drEdit.bind("signature"),
  label: "Chữ ký",
  
  // Ẩn/hiện các chức năng
  isSign: true,   // Cho phép ký
  isView: true,   // Cho phép xem
  isClear: false, // Không cho xóa
  
  // Hoặc binding với CyberDataRow
  isSign: drEdit.bind("allow_sign"),
  isClear: drEdit.bind("allow_clear"),
)
```

### 5. Sử dụng Callbacks

```dart
CyberSignature(
  text: drEdit.bind("signature"),
  label: "Chữ ký",
  
  // Callback khi ký xong (nhận base64)
  onSigned: (String base64) {
    print('Đã ký thành công');
    // Lưu vào database, upload lên server, etc.
  },
  
  // Callback khi giá trị thay đổi
  onChanged: (String value) {
    print('Signature changed');
  },
  
  // Callback khi trigger các action
  onSignRequested: () => print('Mở dialog ký'),
  onViewRequested: () => print('Xem chữ ký'),
  onClearRequested: () => print('Xóa chữ ký'),
  
  // Callback onLeaver (khi mất focus)
  onLeaver: (value) => print('Leaver: $value'),
)
```

### 6. Điều khiển Visibility

```dart
CyberSignature(
  text: drEdit.bind("signature"),
  label: "Chữ ký",
  
  // Static visibility
  isVisible: true,
  
  // Hoặc binding với CyberDataRow
  isVisible: drEdit.bind("show_signature"),
)
```

### 7. Enabled/Disabled State

```dart
CyberSignature(
  text: drEdit.bind("signature"),
  label: "Chữ ký",
  enabled: false, // Disable control
)

// Hoặc dùng controller
signatureCtrl.setEnabled(false);
```

## Thuộc tính

### Core Properties

| Thuộc tính | Kiểu | Mặc định | Mô tả |
|-----------|------|----------|-------|
| `controller` | `CyberSignatureController?` | null | Controller để điều khiển từ bên ngoài |
| `text` | `dynamic` | null | Giá trị binding hoặc static (base64 string) |
| `label` | `String?` | null | Label hiển thị |
| `isShowLabel` | `bool` | true | Hiển thị label |
| `labelStyle` | `TextStyle?` | null | Style cho label |

### Action Control

| Thuộc tính | Kiểu | Mặc định | Mô tả |
|-----------|------|----------|-------|
| `isSign` | `dynamic` | true | Cho phép ký (bool hoặc binding) |
| `isView` | `dynamic` | true | Cho phép xem (bool hoặc binding) |
| `isClear` | `dynamic` | true | Cho phép xóa (bool hoặc binding) |

### UI Customization

| Thuộc tính | Kiểu | Mặc định | Mô tả |
|-----------|------|----------|-------|
| `width` | `double?` | null | Chiều rộng (null = full width) |
| `height` | `double?` | 200 | Chiều cao |
| `borderRadius` | `double` | 12.0 | Bo góc |
| `backgroundColor` | `Color?` | Colors.grey[100] | Màu nền |
| `borderColor` | `Color?` | null | Màu viền |
| `borderWidth` | `double` | 2.0 | Độ dày viền |
| `placeholder` | `Widget?` | null | Widget placeholder tùy chỉnh |
| `errorWidget` | `Widget?` | null | Widget error tùy chỉnh |

### Signature Pad Settings

| Thuộc tính | Kiểu | Mặc định | Mô tả |
|-----------|------|----------|-------|
| `penColor` | `Color` | Colors.black | Màu bút vẽ |
| `penStrokeWidth` | `double` | 3.0 | Độ dày nét vẽ |
| `signaturePadBackgroundColor` | `Color` | Colors.white | Màu nền pad ký |

### Icons

| Thuộc tính | Kiểu | Mặc định | Mô tả |
|-----------|------|----------|-------|
| `signIcon` | `IconData?` | Icons.edit | Icon nút ký |
| `viewIcon` | `IconData?` | Icons.visibility | Icon nút xem |
| `clearIcon` | `IconData?` | Icons.delete | Icon nút xóa |

### State Control

| Thuộc tính | Kiểu | Mặc định | Mô tả |
|-----------|------|----------|-------|
| `enabled` | `bool` | true | Bật/tắt control |
| `isVisible` | `dynamic` | true | Hiển thị/ẩn (bool hoặc binding) |

### Callbacks

| Callback | Signature | Mô tả |
|----------|-----------|-------|
| `onChanged` | `ValueChanged<String>?` | Khi giá trị thay đổi |
| `onLeaver` | `Function(dynamic)?` | Khi mất focus |
| `onSigned` | `ValueChanged<String>?` | Sau khi ký xong (nhận base64) |
| `onSignRequested` | `VoidCallback?` | Khi bắt đầu ký |
| `onViewRequested` | `VoidCallback?` | Khi xem chữ ký |
| `onClearRequested` | `VoidCallback?` | Khi xóa chữ ký |

## Controller Methods

```dart
final ctrl = CyberSignatureController();

// Load signature data
ctrl.loadSignature(base64String);

// Trigger actions
ctrl.triggerSign();   // Mở dialog ký
ctrl.triggerView();   // Xem chữ ký
ctrl.triggerClear();  // Xóa chữ ký

// Clear signature
ctrl.clear();

// Enable/disable
ctrl.setEnabled(true/false);

// Check state
bool hasSig = ctrl.hasSignature;
String? data = ctrl.signatureData;
bool isEnabled = ctrl.enabled;
```

## Ví dụ thực tế

### Ví dụ 1: Form đơn giản

```dart
class SignatureForm extends StatefulWidget {
  @override
  State<SignatureForm> createState() => _SignatureFormState();
}

class _SignatureFormState extends State<SignatureForm> {
  late CyberDataRow drEdit;
  
  @override
  void initState() {
    super.initState();
    drEdit = CyberDataRow();
    drEdit.addColumn("signature", "");
    drEdit.addColumn("customer_name", "");
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberText(
          text: drEdit.bind("customer_name"),
          label: "Tên khách hàng",
        ),
        SizedBox(height: 16),
        CyberSignature(
          text: drEdit.bind("signature"),
          label: "Chữ ký xác nhận",
          height: 180,
          onSigned: (base64) {
            print('Khách hàng đã ký');
          },
        ),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            // Lưu dữ liệu
            final signature = drEdit["signature"];
            if (signature != null && signature.isNotEmpty) {
              print('Lưu chữ ký thành công');
            } else {
              print('Chưa có chữ ký');
            }
          },
          child: Text('Lưu'),
        ),
      ],
    );
  }
}
```

### Ví dụ 2: Với Controller

```dart
class SignatureWithController extends StatefulWidget {
  @override
  State<SignatureWithController> createState() => _SignatureWithControllerState();
}

class _SignatureWithControllerState extends State<SignatureWithController> {
  late CyberDataRow drEdit;
  late CyberSignatureController signatureCtrl;
  
  @override
  void initState() {
    super.initState();
    drEdit = CyberDataRow();
    drEdit.addColumn("signature", "");
    
    signatureCtrl = CyberSignatureController();
  }
  
  @override
  void dispose() {
    signatureCtrl.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberSignature(
          controller: signatureCtrl,
          text: drEdit.bind("signature"),
          label: "Chữ ký",
          height: 180,
          onSigned: (base64) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Đã ký thành công')),
            );
          },
        ),
        SizedBox(height: 16),
        Row(
          children: [
            ElevatedButton(
              onPressed: () => signatureCtrl.triggerSign(),
              child: Text('Ký ngay'),
            ),
            SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                if (signatureCtrl.hasSignature) {
                  signatureCtrl.triggerView();
                }
              },
              child: Text('Xem'),
            ),
            SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => signatureCtrl.triggerClear(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text('Xóa'),
            ),
          ],
        ),
      ],
    );
  }
}
```

### Ví dụ 3: Điều khiển động

```dart
class DynamicSignature extends StatefulWidget {
  @override
  State<DynamicSignature> createState() => _DynamicSignatureState();
}

class _DynamicSignatureState extends State<DynamicSignature> {
  late CyberDataRow drEdit;
  bool allowEdit = true;
  
  @override
  void initState() {
    super.initState();
    drEdit = CyberDataRow();
    drEdit.addColumn("signature", "");
    drEdit.addColumn("is_approved", 0);
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          title: Text('Cho phép chỉnh sửa'),
          value: allowEdit,
          onChanged: (value) {
            setState(() => allowEdit = value);
          },
        ),
        CyberSignature(
          text: drEdit.bind("signature"),
          label: "Chữ ký",
          height: 180,
          enabled: allowEdit,
          isSign: allowEdit,
          isClear: allowEdit,
          isView: true, // Luôn cho xem
          onSigned: (base64) {
            // Tự động set approved khi ký
            drEdit["is_approved"] = 1;
          },
        ),
      ],
    );
  }
}
```

## Lưu ý

1. **Base64 Format**: Chữ ký được lưu dưới dạng `data:image/png;base64,...`
2. **File Size**: Mỗi chữ ký có kích thước khoảng 20-50KB tùy độ phức tạp
3. **Performance**: Sử dụng cache để decode base64, tránh decode lại nhiều lần
4. **Memory**: Dispose controller khi không dùng nữa
5. **Validation**: Kiểm tra `hasSignature` trước khi lưu dữ liệu

## So sánh với CyberImage

| Tính năng | CyberImage | CyberSignature |
|-----------|------------|----------------|
| Binding | ✅ | ✅ |
| Controller | ✅ | ✅ |
| Upload | ✅ Camera/Gallery | ✅ Drawing Pad |
| View | ✅ | ✅ |
| Delete/Clear | ✅ | ✅ |
| Network Image | ✅ | ❌ |
| Asset Image | ✅ | ❌ |
| File Image | ✅ | ❌ |
| Base64 | ✅ | ✅ |
| Compression | ✅ | ✅ (PNG) |
| Circle Shape | ✅ | ❌ |
| Fit Options | ✅ Multiple | ✅ Contain |

## Troubleshooting

### 1. Chữ ký không lưu

**Nguyên nhân**: Không binding đúng hoặc không gọi callback

**Giải pháp**:
```dart
CyberSignature(
  text: drEdit.bind("signature"), // ✅ Binding đúng
  onSigned: (base64) {
    print(base64); // ✅ Check giá trị
  },
)
```

### 2. Dialog không mở

**Nguyên nhân**: Control bị disabled hoặc `isSign = false`

**Giải pháp**:
```dart
CyberSignature(
  enabled: true,  // ✅
  isSign: true,   // ✅
  ...
)
```

### 3. Chữ ký bị mờ

**Nguyên nhân**: Kích thước canvas quá nhỏ

**Giải pháp**: CyberSignaturePad tự động render với `pixelRatio: 3.0`

### 4. Memory leak

**Nguyên nhân**: Không dispose controller

**Giải pháp**:
```dart
@override
void dispose() {
  signatureCtrl.dispose(); // ✅
  super.dispose();
}
```

## Best Practices

1. **Luôn dùng Binding** cho data persistence
2. **Dispose Controller** khi không dùng nữa
3. **Validate Signature** trước khi submit form
4. **Handle Callbacks** để update UI/state
5. **Custom Placeholder** cho UX tốt hơn
6. **Set Height Appropriate** (khuyến nghị 150-250)
7. **Use onSigned** để xử lý logic sau khi ký

## License

Part of CyberFramework - Internal use only
