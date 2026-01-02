# CyberCamera - Hướng Dẫn Sử Dụng

## 📋 Mục Lục

1. [Giới Thiệu](#giới-thiệu)
2. [Cài Đặt](#cài-đặt)
3. [Cú Pháp Cơ Bản](#cú-pháp-cơ-bản)
4. [Data Binding](#data-binding)
5. [Các Tính Năng](#các-tính-năng)
6. [Ví Dụ Thực Tế](#ví-dụ-thực-tế)
7. [API Reference](#api-reference)
8. [Best Practices](#best-practices)

---

## 🎯 Giới Thiệu

**CyberCamera** là widget chụp ảnh với khả năng data binding tự động trong CyberFramework. Widget này tuân theo triết lý **Internal Controller + Binding**, giúp developer không cần khai báo controller bên ngoài mà vẫn có đầy đủ tính năng binding dữ liệu.

### ✨ Đặc Điểm Nổi Bật

- ✅ **Internal Controller**: Tự động quản lý lifecycle
- ✅ **Two-way Data Binding**: Sync tự động với CyberDataRow
- ✅ **Compression**: Nén ảnh tự động, tiết kiệm dung lượng
- ✅ **Multiple Camera**: Hỗ trợ camera trước/sau
- ✅ **Custom UI**: Tùy chỉnh placeholder, button, style
- ✅ **Memory Safe**: Tự động cleanup, không memory leak

---

## 📦 Cài Đặt

### 1. Thêm Dependencies

Trong file `pubspec.yaml`:

```yaml
dependencies:
  camera: ^0.10.5+5
  flutter_image_compress: ^2.1.0
  path: ^1.8.3
  path_provider: ^2.1.1
```

### 2. Cấu Hình Platform

#### Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Camera permissions -->
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-feature android:name="android.hardware.camera" android:required="false"/>
    <uses-feature android:name="android.hardware.camera.autofocus" android:required="false"/>
    
    <application>
        <!-- ... -->
    </application>
</manifest>
```

#### iOS (`ios/Runner/Info.plist`)

```xml
<key>NSCameraUsageDescription</key>
<string>Ứng dụng cần quyền truy cập camera để chụp ảnh</string>
<key>NSMicrophoneUsageDescription</key>
<string>Ứng dụng cần quyền truy cập microphone</string>
```

### 3. Import

```dart
import 'package:cyberframework/cyberframework.dart';
```

---

## 🚀 Cú Pháp Cơ Bản

### 1. Sử Dụng Đơn Giản (Không Binding)

```dart
CyberCamera(
  label: "Chụp ảnh",
  height: 200,
  onCaptured: (result) {
    print('Đã chụp: ${result.fileName}');
    print('Đường dẫn: ${result.file.path}');
  },
)
```

### 2. Với Data Binding (RECOMMENDED)

```dart
// Khởi tạo data row
final drCustomer = CyberDataRow({
  'ma_kh': 'KH001',
  'anh_cmnd': '',
});

// Widget
CyberCamera(
  imagePath: drCustomer.bind("anh_cmnd"),  // ← Auto binding
  label: "Ảnh CMND",
  height: 200,
)
```

### 3. Syntax Ngắn Gọn

```dart
CyberCamera(
  imagePath: drCustomer.$("anh_cmnd"),  // ← Cú pháp $ ngắn gọn
  label: "Ảnh CMND",
)
```

---

## 🔗 Data Binding

### Cách Hoạt Động

```dart
class MyForm extends StatefulWidget {
  @override
  State<MyForm> createState() => _MyFormState();
}

class _MyFormState extends State<MyForm> {
  late CyberDataRow drEdit;

  @override
  void initState() {
    super.initState();
    drEdit = CyberDataRow({
      'anh_cmnd_truoc': '',
      'anh_cmnd_sau': '',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Binding tự động 2 chiều
        CyberCamera(
          imagePath: drEdit.bind("anh_cmnd_truoc"),
          label: "CMND mặt trước",
        ),
        
        CyberCamera(
          imagePath: drEdit.bind("anh_cmnd_sau"),
          label: "CMND mặt sau",
        ),
        
        // Khi chụp ảnh → drEdit["anh_cmnd_truoc"] tự động update
        // Khi drEdit["anh_cmnd_truoc"] thay đổi → UI tự động refresh
        
        ElevatedButton(
          onPressed: () {
            // Lấy dữ liệu đã binding
            print('CMND trước: ${drEdit["anh_cmnd_truoc"]}');
            print('CMND sau: ${drEdit["anh_cmnd_sau"]}');
            print('IsDirty: ${drEdit.isDirty}');
          },
          child: Text('Lưu'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    drEdit.dispose();  // ← QUAN TRỌNG: Cleanup memory
    super.dispose();
  }
}
```

### 3 Cách Binding

```dart
// Cách 1: Sử dụng bind()
CyberCamera(
  imagePath: drEdit.bind("field_name"),
)

// Cách 2: Sử dụng $ (ngắn gọn)
CyberCamera(
  imagePath: drEdit.$("field_name"),
)

// Cách 3: Helper function
CyberCamera(
  imagePath: bind(drEdit, "field_name"),
)
```

---

## 🎨 Các Tính Năng

### 1. Compression (Nén Ảnh)

```dart
CyberCamera(
  imagePath: dr.bind("photo"),
  enableCompression: true,        // Bật nén (default: true)
  compressionQuality: 85,         // Chất lượng 0-100 (default: 85)
  maxWidth: 1920,                 // Chiều rộng tối đa
  maxHeight: 1920,                // Chiều cao tối đa
)
```

**Kết quả:**
- Ảnh gốc: 4000x3000, 5.2MB
- Sau nén: 1920x1440, 800KB (giảm 84%)

### 2. Multiple Camera (Camera Trước/Sau)

```dart
CyberCamera(
  imagePath: dr.bind("selfie"),
  defaultCamera: CameraLensDirection.front,  // Camera trước
  // CameraLensDirection.back,                // Camera sau (default)
)
```

### 3. Custom Styling

```dart
CyberCamera(
  imagePath: dr.bind("photo"),
  width: double.infinity,  // Chiều rộng
  height: 250,            // Chiều cao
  fit: BoxFit.cover,      // Cách hiển thị ảnh
  // BoxFit.contain, BoxFit.fill, BoxFit.fitWidth, ...
)
```

### 4. Custom Placeholder

```dart
CyberCamera(
  imagePath: dr.bind("photo"),
  placeholder: Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.blue.shade100, Colors.blue.shade300],
      ),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.camera_alt, size: 64, color: Colors.white),
        SizedBox(height: 8),
        Text(
          'Nhấn để chụp ảnh',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ],
    ),
  ),
)
```

### 5. Callbacks

```dart
CyberCamera(
  imagePath: dr.bind("photo"),
  
  // Callback khi chụp ảnh thành công
  onCaptured: (result) async {
    print('File: ${result.fileName}');
    print('Size: ${result.fileSize} bytes');
    print('Path: ${result.file.path}');
    print('Compressed: ${result.isCompressed}');
    
    // Convert to Base64
    final base64 = await result.getBase64();
    
    // Upload to server
    // await uploadToServer(result.file);
  },
  
  // Callback khi có lỗi
  onError: (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lỗi: $error')),
    );
  },
)
```

### 6. Enable/Disable

```dart
bool _isEditable = true;

CyberCamera(
  imagePath: dr.bind("photo"),
  enabled: _isEditable,  // Vô hiệu hóa khi false
  label: "Ảnh (chỉ xem)",
)
```

### 7. Custom Camera Title

```dart
CyberCamera(
  imagePath: dr.bind("photo"),
  cameraTitle: "Chụp ảnh chất lượng cao",  // Title màn hình camera
)
```

---

## 💡 Ví Dụ Thực Tế

### 1. Form Đăng Ký Khách Hàng

```dart
class CustomerRegistrationForm extends StatefulWidget {
  @override
  State<CustomerRegistrationForm> createState() => _CustomerRegistrationFormState();
}

class _CustomerRegistrationFormState extends State<CustomerRegistrationForm> {
  late CyberDataRow drCustomer;

  @override
  void initState() {
    super.initState();
    drCustomer = CyberDataRow({
      'ma_kh': '',
      'ten_kh': '',
      'cmnd_truoc': '',
      'cmnd_sau': '',
      'chan_dung': '',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Đăng ký khách hàng')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Thông tin cơ bản
            CyberText(
              text: drCustomer.bind("ten_kh"),
              label: "Họ và tên",
            ),
            SizedBox(height: 16),
            
            // Ảnh CMND
            Text(
              'Chứng minh nhân dân',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: CyberCamera(
                    imagePath: drCustomer.bind("cmnd_truoc"),
                    label: "Mặt trước",
                    height: 150,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: CyberCamera(
                    imagePath: drCustomer.bind("cmnd_sau"),
                    label: "Mặt sau",
                    height: 150,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Ảnh chân dung
            CyberCamera(
              imagePath: drCustomer.bind("chan_dung"),
              label: "Ảnh chân dung",
              height: 200,
              defaultCamera: CameraLensDirection.front,
              compressionQuality: 90,
            ),
            
            SizedBox(height: 24),
            
            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.save),
                    label: Text('Lưu'),
                    onPressed: _saveCustomer,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.refresh),
                    label: Text('Reset'),
                    onPressed: () => drCustomer.rejectChanges(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCustomer() async {
    if (!drCustomer.isDirty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không có thay đổi')),
      );
      return;
    }

    // Validate
    if (drCustomer["ten_kh"]?.isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng nhập họ tên')),
      );
      return;
    }

    // Lưu dữ liệu
    final data = drCustomer.toMap();
    print('Saving data: $data');
    
    // Call API
    // await ApiService.saveCustomer(data);
    
    drCustomer.acceptChanges();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã lưu thành công')),
    );
  }

  @override
  void dispose() {
    drCustomer.dispose();
    super.dispose();
  }
}
```

### 2. ListView Nhiều Sản Phẩm

```dart
class ProductListScreen extends StatefulWidget {
  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late CyberDataTable dtProducts;

  @override
  void initState() {
    super.initState();
    
    // Load dữ liệu
    dtProducts = CyberDataTable();
    _loadProducts();
  }

  void _loadProducts() {
    for (int i = 1; i <= 10; i++) {
      dtProducts.add(CyberDataRow({
        'ma_sp': 'SP${i.toString().padLeft(3, '0')}',
        'ten_sp': 'Sản phẩm $i',
        'gia': 100000.0 * i,
        'anh_sp': '',
      }));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Danh sách sản phẩm'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveAll,
          ),
        ],
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: dtProducts.length,
        itemBuilder: (context, index) {
          final row = dtProducts[index];
          
          return Card(
            margin: EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${row["ma_sp"]} - ${row["ten_sp"]}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  
                  // Camera binding với từng row
                  CyberCamera(
                    imagePath: row.bind("anh_sp"),
                    label: "Ảnh sản phẩm",
                    height: 150,
                    onCaptured: (result) {
                      print('Chụp ảnh ${row["ma_sp"]}: ${result.fileName}');
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addProduct,
        child: Icon(Icons.add),
      ),
    );
  }

  void _addProduct() {
    final newRow = CyberDataRow({
      'ma_sp': 'SP${(dtProducts.length + 1).toString().padLeft(3, '0')}',
      'ten_sp': 'Sản phẩm mới',
      'gia': 0.0,
      'anh_sp': '',
    });
    
    setState(() {
      dtProducts.add(newRow);
    });
  }

  Future<void> _saveAll() async {
    final changedRows = dtProducts.rows.where((r) => r.isDirty).toList();
    
    if (changedRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không có thay đổi')),
      );
      return;
    }

    print('Saving ${changedRows.length} products...');
    
    for (var row in changedRows) {
      print('${row["ma_sp"]}: ${row["anh_sp"]}');
    }

    // Call API
    // await ApiService.saveProducts(changedRows.map((r) => r.toMap()).toList());
    
    dtProducts.acceptChanges();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã lưu ${changedRows.length} sản phẩm')),
    );
  }

  @override
  void dispose() {
    dtProducts.dispose();
    super.dispose();
  }
}
```

### 3. Upload Server với Base64

```dart
class UploadPhotoExample extends StatefulWidget {
  @override
  State<UploadPhotoExample> createState() => _UploadPhotoExampleState();
}

class _UploadPhotoExampleState extends State<UploadPhotoExample> {
  late CyberDataRow drPhoto;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    drPhoto = CyberDataRow({'photo_path': ''});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload ảnh')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            CyberCamera(
              imagePath: drPhoto.bind("photo_path"),
              label: "Chọn ảnh để upload",
              height: 300,
              enableCompression: true,
              compressionQuality: 80,
              onCaptured: (result) async {
                // Auto upload sau khi chụp
                await _uploadPhoto(result);
              },
            ),
            
            SizedBox(height: 16),
            
            if (_uploading)
              CircularProgressIndicator()
            else
              ElevatedButton.icon(
                icon: Icon(Icons.cloud_upload),
                label: Text('Upload lại'),
                onPressed: () async {
                  if (drPhoto["photo_path"]?.isEmpty ?? true) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Chưa có ảnh')),
                    );
                    return;
                  }
                  
                  final result = CyberCameraResult(
                    file: File(drPhoto["photo_path"]),
                    fileName: path.basename(drPhoto["photo_path"]),
                    fileSize: await File(drPhoto["photo_path"]).length(),
                  );
                  
                  await _uploadPhoto(result);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadPhoto(CyberCameraResult result) async {
    setState(() => _uploading = true);

    try {
      // Convert to Base64
      final base64 = await result.getBase64();
      
      print('Uploading...');
      print('File: ${result.fileName}');
      print('Size: ${result.fileSize} bytes');
      print('Base64 length: ${base64.length}');

      // Simulate API call
      await Future.delayed(Duration(seconds: 2));
      
      // Real API call
      // final response = await http.post(
      //   Uri.parse('https://api.example.com/upload'),
      //   headers: {'Content-Type': 'application/json'},
      //   body: jsonEncode({
      //     'file_name': result.fileName,
      //     'file_data': base64,
      //   }),
      // );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _uploading = false);
    }
  }

  @override
  void dispose() {
    drPhoto.dispose();
    super.dispose();
  }
}
```

---

## 📚 API Reference

### CyberCamera Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `imagePath` | `dynamic` | `null` | Binding hoặc static string |
| `label` | `String?` | `null` | Nhãn hiển thị |
| `enabled` | `bool` | `true` | Enable/disable widget |
| `width` | `double?` | `null` | Chiều rộng container |
| `height` | `double?` | `null` | Chiều cao container |
| `fit` | `BoxFit` | `BoxFit.cover` | Cách hiển thị ảnh |
| `enableCompression` | `bool` | `true` | Bật nén ảnh |
| `compressionQuality` | `int` | `85` | Chất lượng nén (0-100) |
| `maxWidth` | `int?` | `1920` | Chiều rộng tối đa sau nén |
| `maxHeight` | `int?` | `1920` | Chiều cao tối đa sau nén |
| `defaultCamera` | `CameraLensDirection` | `back` | Camera mặc định |
| `cameraTitle` | `String?` | `null` | Title màn hình camera |
| `placeholder` | `Widget?` | `null` | Custom placeholder |
| `onCaptured` | `OnCaptureImage?` | `null` | Callback khi chụp xong |
| `onError` | `OnCameraError?` | `null` | Callback khi có lỗi |

### CyberCameraResult Methods

```dart
class CyberCameraResult {
  final File file;                // File ảnh
  final String fileName;          // Tên file
  final int fileSize;             // Kích thước (bytes)
  final bool isCompressed;        // Đã nén?
  final int? quality;             // Chất lượng nén

  // Methods
  Future<List<int>> getBytes();         // Lấy bytes
  Future<String> getBase64();           // Lấy base64 string
  Future<String> getBase64DataUri();    // Lấy data URI
}
```

### CameraLensDirection

```dart
enum CameraLensDirection {
  front,    // Camera trước (selfie)
  back,     // Camera sau (default)
  external, // Camera ngoài
}
```

### BoxFit

```dart
enum BoxFit {
  fill,       // Kéo giãn fill toàn bộ
  contain,    // Fit vừa khung, giữ tỷ lệ
  cover,      // Cover toàn bộ, crop nếu cần
  fitWidth,   // Fit theo chiều rộng
  fitHeight,  // Fit theo chiều cao
  none,       // Kích thước gốc
  scaleDown,  // Scale down nếu lớn hơn
}
```

---

## ✅ Best Practices

### 1. Luôn Dispose CyberDataRow

```dart
@override
void dispose() {
  drEdit.dispose();  // ← QUAN TRỌNG!
  super.dispose();
}
```

### 2. Sử dụng Binding Thay Vì Callback

❌ **Không nên:**
```dart
String _imagePath = '';

CyberCamera(
  onCaptured: (result) {
    setState(() {
      _imagePath = result.file.path;
    });
  },
)
```

✅ **Nên:**
```dart
final drEdit = CyberDataRow({'image': ''});

CyberCamera(
  imagePath: drEdit.bind("image"),  // ← Tự động sync
)
```

### 3. Compression Cho Upload

```dart
// Ảnh upload server → nén chất lượng vừa
CyberCamera(
  imagePath: dr.bind("photo"),
  enableCompression: true,
  compressionQuality: 75,    // 75-85 là tối ưu
  maxWidth: 1080,            // HD là đủ
  maxHeight: 1080,
)

// Ảnh in ấn → chất lượng cao
CyberCamera(
  imagePath: dr.bind("print_photo"),
  enableCompression: true,
  compressionQuality: 95,
  maxWidth: 2048,
  maxHeight: 2048,
)
```

### 4. Validate Trước Khi Lưu

```dart
void _save() {
  // Check required fields
  if (drEdit["photo"]?.isEmpty ?? true) {
    showError('Vui lòng chụp ảnh');
    return;
  }

  // Check file exists
  final file = File(drEdit["photo"]);
  if (!file.existsSync()) {
    showError('File không tồn tại');
    return;
  }

  // Save
  saveData();
}
```

### 5. Error Handling

```dart
CyberCamera(
  imagePath: dr.bind("photo"),
  onCaptured: (result) async {
    try {
      await uploadToServer(result);
      showSuccess('Upload thành công');
    } catch (e) {
      showError('Upload thất bại: $e');
      // Rollback nếu cần
      dr["photo"] = '';
    }
  },
  onError: (error) {
    showError('Camera error: $error');
  },
)
```

### 6. ListView Performance

```dart
// ✅ Tốt: Lock identity khi bind vào ListView
ListView.builder(
  itemCount: dtProducts.length,
  itemBuilder: (context, index) {
    final row = dtProducts[index];
    row.lockIdentity();  // ← Prevent identity change
    
    return CyberCamera(
      key: ValueKey(row.identityKey),  // ← Stable key
      imagePath: row.bind("photo"),
    );
  },
)
```

### 7. Memory Management

```dart
// ✅ Cleanup temp files
@override
void dispose() {
  // Xóa ảnh tạm nếu không lưu
  if (!_isSaved && _tempImagePath != null) {
    try {
      File(_tempImagePath!).deleteSync();
    } catch (e) {
      debugPrint('Error deleting temp file: $e');
    }
  }
  
  drEdit.dispose();
  super.dispose();
}
```

### 8. Permission Handling

```dart
import 'package:permission_handler/permission_handler.dart';

Future<void> _openCamera() async {
  final status = await Permission.camera.request();
  
  if (status.isGranted) {
    // Open camera
  } else if (status.isDenied) {
    showError('Vui lòng cấp quyền camera');
  } else if (status.isPermanentlyDenied) {
    // Mở settings
    openAppSettings();
  }
}
```

---

## 🔧 Troubleshooting

### 1. Camera Không Khởi Động

**Nguyên nhân:**
- Chưa cấp quyền camera
- Thiếu cấu hình platform

**Giải pháp:**
```dart
// Check permissions
final cameras = await availableCameras();
if (cameras.isEmpty) {
  print('No camera available');
}
```

### 2. Ảnh Bị Xoay

**Nguyên nhân:**
- EXIF orientation không được xử lý

**Giải pháp:**
```dart
// Sử dụng package: flutter_native_image
import 'package:flutter_native_image/flutter_native_image.dart';

final correctedFile = await FlutterNativeImage.compressImage(
  imagePath,
  quality: 85,
  targetWidth: 1920,
  targetHeight: 1920,
);
```

### 3. Memory Leak

**Nguyên nhân:**
- Quên dispose CyberDataRow
- Listener không remove

**Giải pháp:**
```dart
@override
void dispose() {
  drEdit.dispose();  // ← Bắt buộc
  super.dispose();
}
```

### 4. Compression Không Hoạt Động

**Kiểm tra:**
```dart
onCaptured: (result) {
  print('Compressed: ${result.isCompressed}');
  print('Quality: ${result.quality}');
  print('Size: ${result.fileSize}');
}
```

---

## 📞 Support

- **Documentation**: [CyberFramework Docs](https://docs.cyberframework.com)
- **Issues**: [GitHub Issues](https://github.com/cyberframework/issues)
- **Email**: support@cyberframework.com

---

## 📄 License

MIT License - Copyright (c) 2024 CyberFramework

---

**Phiên bản:** 1.0.0  
**Cập nhật:** 2024-01-01
