# CyberCamera - Hướng dẫn sử dụng

## Tổng quan

- **CyberCamera**: Control có thể add vào màn hình, tap để chụp ảnh
- **CyberCameraView**: Màn hình camera full screen, show/hide như dialog

---

## Permissions Setup

### Android (android/app/src/main/AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>

<application>
    <!-- ... -->
</application>
```

### iOS (ios/Runner/Info.plist)

```xml
<key>NSCameraUsageDescription</key>
<string>Ứng dụng cần quyền truy cập camera để chụp ảnh</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Ứng dụng cần quyền lưu ảnh vào thư viện</string>
```

---

## 1. CyberCamera - Inline Control

### Basic Usage

```dart
class ProductPhotoScreen extends StatefulWidget {
  @override
  State<ProductPhotoScreen> createState() => _ProductPhotoScreenState();
}

class _ProductPhotoScreenState extends State<ProductPhotoScreen> {
  File? _capturedImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chụp ảnh sản phẩm')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Camera control
            CyberCamera(
              height: 300,
              onCapture: (result) {
                setState(() {
                  _capturedImage = result.file;
                });

                print('Photo captured: ${result.fileName}');
                print('File size: ${result.fileSize} bytes');
                print('Compressed: ${result.isCompressed}');

                // Upload to API
                _uploadToAPI(result);
              },
              onError: (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $error')),
                );
              },
            ),

            SizedBox(height: 16),

            // Preview captured image
            if (_capturedImage != null)
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Ảnh đã chụp:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Expanded(
                      child: Image.file(
                        _capturedImage!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadToAPI(CyberCameraResult result) async {
    // Upload logic here
  }
}
```

### Custom Compression Settings

```dart
CyberCamera(
  height: 400,
  enableCompression: true,
  compressionQuality: 90, // 0-100
  maxWidth: 2560,
  maxHeight: 2560,
  onCapture: (result) {
    print('High quality photo: ${result.fileSize} bytes');
  },
)
```

### No Compression (Original Quality)

```dart
CyberCamera(
  height: 300,
  enableCompression: false,
  onCapture: (result) {
    print('Original photo');
  },
)
```

### Custom Styling

```dart
CyberCamera(
  height: 350,
  borderRadius: 20.0,
  hintText: "👆 Tap để chụp ảnh",
  showTapOverlay: true,
  defaultCamera: CameraLensDirection.front, // Front camera
  onCapture: (result) {
    // Handle capture
  },
)
```

### Without Tap Overlay (Manual Button)

```dart
CyberCamera(
  height: 300,
  showTapOverlay: false, // Hiện nút chụp thay vì tap overlay
  onCapture: (result) {
    // Handle capture
  },
)
```

---

## 2. CyberCameraView - Full Screen Camera

### Basic Usage

```dart
class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _avatarImage;

  Future<void> _openCamera() async {
    final camera = CyberCameraView(
      context: context,
      title: "Chụp ảnh đại diện",
      enableCompression: true,
      compressionQuality: 85,
      maxWidth: 800,
      maxHeight: 800,
    );

    // Show camera và đợi result
    final result = await camera.show();

    if (result != null) {
      setState(() {
        _avatarImage = result.file;
      });

      print('Photo captured: ${result.fileName}');
      print('Size: ${result.fileSize} bytes');

      // Upload to API
      await _uploadAvatar(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Hồ sơ')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar preview
            CircleAvatar(
              radius: 80,
              backgroundImage: _avatarImage != null
                  ? FileImage(_avatarImage!)
                  : null,
              child: _avatarImage == null
                  ? Icon(Icons.person, size: 80)
                  : null,
            ),

            SizedBox(height: 24),

            // Button to open camera
            ElevatedButton.icon(
              onPressed: _openCamera,
              icon: Icon(Icons.camera_alt),
              label: Text('Chụp ảnh đại diện'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadAvatar(CyberCameraResult result) async {
    // Upload logic
  }
}
```

### Short Syntax

```dart
// One-liner
final result = await CyberCameraView(
  context: context,
  title: "Chụp ảnh",
).show();

if (result != null) {
  print('Photo: ${result.fileName}');
}
```

### Front Camera Default

```dart
final result = await CyberCameraView(
  context: context,
  title: "Selfie",
  defaultCamera: CameraLensDirection.front,
  compressionQuality: 90,
).show();
```

### Custom Quality Settings

```dart
final camera = CyberCameraView(
  context: context,
  title: "Chụp chứng từ",
  enableCompression: true,
  compressionQuality: 95, // High quality
  maxWidth: 3000,
  maxHeight: 3000,
  onError: (error) {
    print('Camera error: $error');
  },
);

final result = await camera.show();
```

---

## 3. Upload to API

### Option 1: FormData (Multipart)

```dart
Future<void> _uploadToAPI(CyberCameraResult result) async {
  FormData formData = FormData.fromMap({
    'file': await MultipartFile.fromFile(
      result.file.path,
      filename: result.fileName,
    ),
  });

  final response = await dio.post('/upload', data: formData);

  if (response.statusCode == 200) {
    print('Upload success!');
  }
}
```

### Option 2: Base64

```dart
Future<void> _uploadToAPI(CyberCameraResult result) async {
  final base64 = await result.getBase64();

  final response = await context.callApi(
    functionName: "UploadPhoto",
    parameter: "userid#$base64#${result.fileName}",
  );

  if (response.isValid()) {
    await context.showSuccess("Upload thành công!");
  }
}
```

### Option 3: Bytes

```dart
Future<void> _uploadToAPI(CyberCameraResult result) async {
  final bytes = await result.getBytes();

  var request = http.MultipartRequest(
    'POST',
    Uri.parse('https://api.example.com/upload'),
  );

  request.files.add(
    http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: result.fileName,
    ),
  );

  var response = await request.send();
}
```

---

## 4. Integration with CyberForm

### Complete Form Example

```dart
class ProductForm extends CyberContentViewForm {
  late CyberDataTable dt;
  late CyberDataRow row;
  File? _productImage;

  @override
  void onInit() {
    dt = CyberDataTable(tableName: "Products");
    dt.addColumn("id", CyberDataType.text);
    dt.addColumn("name", CyberDataType.text);
    dt.addColumn("price", CyberDataType.numeric);
    dt.addColumn("imageUrl", CyberDataType.text);

    row = dt.newRow();
    row["name"] = "";
    row["price"] = 0.0;
  }

  Future<void> _openCamera() async {
    final camera = CyberCameraView(
      context: context,
      title: "Chụp ảnh sản phẩm",
      enableCompression: true,
      compressionQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );

    final result = await camera.show();

    if (result != null) {
      setState(() {
        _productImage = result.file;
      });

      // Auto upload
      await _uploadProductImage(result);
    }
  }

  Future<void> _uploadProductImage(CyberCameraResult result) async {
    showLoading("Đang upload ảnh...");

    try {
      final base64 = await result.getBase64();

      final response = await context.callApi(
        functionName: "UploadProductImage",
        parameter: "product#$base64#${result.fileName}",
      );

      hideLoading();

      if (response.isValid()) {
        row["imageUrl"] = response.data["imageUrl"];
        await context.showSuccess("Upload ảnh thành công!");
      } else {
        await context.showErrorMsg(response.message);
      }
    } catch (e) {
      hideLoading();
      await context.showErrorMsg("Lỗi: $e");
    }
  }

  Future<void> _saveProduct() async {
    if (row["name"].toString().isEmpty) {
      await context.showErrorMsg("Vui lòng nhập tên sản phẩm!");
      return;
    }

    if (_productImage == null) {
      await context.showErrorMsg("Vui lòng chụp ảnh sản phẩm!");
      return;
    }

    showLoading("Đang lưu...");

    try {
      final response = await context.callApi(
        functionName: "SaveProduct",
        parameter: "${row['name']}#${row['price']}#${row['imageUrl']}",
      );

      hideLoading();

      if (response.isValid()) {
        await context.showSuccess("Lưu sản phẩm thành công!");
        closePopup(context, true);
      }
    } catch (e) {
      hideLoading();
      await context.showErrorMsg("Lỗi: $e");
    }
  }

  @override
  Widget buildBody(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            "Thêm sản phẩm mới",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 24),

          // Product image
          GestureDetector(
            onTap: _openCamera,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[400]!),
              ),
              child: _productImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _productImage!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          "Nhấn để chụp ảnh sản phẩm",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
            ),
          ),

          SizedBox(height: 16),

          CyberText(
            text: row.bind("name"),
            label: "Tên sản phẩm",
            hint: "Nhập tên sản phẩm",
          ),

          SizedBox(height: 16),

          CyberNumeric(
            text: row.bind("price"),
            label: "Giá bán",
            hint: "Nhập giá",
            format: "### ### ### ###.##",
          ),

          SizedBox(height: 24),

          CyberButton(
            label: "Lưu sản phẩm",
            onClick: _saveProduct,
          ),
        ],
      ),
    );
  }
}
```

---

## 5. Multiple Photos Example

### Capture Multiple Photos

```dart
class MultiplePhotosScreen extends StatefulWidget {
  @override
  State<MultiplePhotosScreen> createState() => _MultiplePhotosScreenState();
}

class _MultiplePhotosScreenState extends State<MultiplePhotosScreen> {
  List<File> _photos = [];

  Future<void> _capturePhoto() async {
    final camera = CyberCameraView(
      context: context,
      title: "Chụp ảnh ${_photos.length + 1}",
    );

    final result = await camera.show();

    if (result != null) {
      setState(() {
        _photos.add(result.file);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Album ảnh')),
      body: Column(
        children: [
          // Photo grid
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _photos.length,
              itemBuilder: (context, index) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(_photos[index], fit: BoxFit.cover),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _photos.removeAt(index);
                          });
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Add photo button
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _capturePhoto,
              icon: Icon(Icons.add_a_photo),
              label: Text('Thêm ảnh'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 6. Comparison: Control vs View

### Use CyberCamera (Control) when:

✅ Cần embed camera vào form/screen
✅ Muốn preview camera luôn hiển thị
✅ Workflow đơn giản, chụp ngay tại chỗ
✅ Không cần full screen

### Use CyberCameraView (View) when:

✅ Muốn camera full screen như native app
✅ Cần modal/dialog experience
✅ Workflow: open → capture → close → process
✅ Tối ưu UX với full screen preview

---

## 7. Advanced Examples

### Document Scanner

```dart
class DocumentScannerScreen extends StatelessWidget {
  Future<void> _scanDocument(BuildContext context) async {
    final camera = CyberCameraView(
      context: context,
      title: "Quét tài liệu",
      enableCompression: true,
      compressionQuality: 95, // High quality cho OCR
      maxWidth: 3000,
      maxHeight: 3000,
    );

    final result = await camera.show();

    if (result != null) {
      // Process with OCR
      await _processDocument(result);
    }
  }

  Future<void> _processDocument(CyberCameraResult result) async {
    // OCR processing
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quét tài liệu')),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () => _scanDocument(context),
          icon: Icon(Icons.document_scanner),
          label: Text('Quét tài liệu'),
        ),
      ),
    );
  }
}
```

### ID Card Scanner

```dart
Future<void> _scanIDCard() async {
  final camera = CyberCameraView(
    context: context,
    title: "Chụp CMND/CCCD",
    enableCompression: true,
    compressionQuality: 90,
    maxWidth: 2000,
    maxHeight: 2000,
  );

  final result = await camera.show();

  if (result != null) {
    showLoading("Đang xử lý...");

    try {
      final base64 = await result.getBase64();

      // Call OCR API
      final response = await context.callApi(
        functionName: "ScanIDCard",
        parameter: base64,
      );

      hideLoading();

      if (response.isValid()) {
        // Extract data
        final idData = response.toCyberDataset()?[0]?[0];

        if (idData != null) {
          row["idNumber"] = idData["idNumber"];
          row["fullName"] = idData["fullName"];
          row["dob"] = idData["dob"];

          await context.showSuccess("Quét thành công!");
        }
      }
    } catch (e) {
      hideLoading();
      await context.showErrorMsg("Lỗi: $e");
    }
  }
}
```

### Quality Comparison

```dart
class QualityComparisonScreen extends StatefulWidget {
  @override
  State<QualityComparisonScreen> createState() => _QualityComparisonScreenState();
}

class _QualityComparisonScreenState extends State<QualityComparisonScreen> {
  Map<String, File?> _photos = {
    'Low': null,
    'Medium': null,
    'High': null,
  };

  Future<void> _captureWithQuality(String quality, int compressionQuality) async {
    final camera = CyberCameraView(
      context: context,
      title: "Chụp $quality Quality",
      enableCompression: true,
      compressionQuality: compressionQuality,
    );

    final result = await camera.show();

    if (result != null) {
      setState(() {
        _photos[quality] = result.file;
      });

      print('$quality - Size: ${result.fileSize} bytes');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('So sánh chất lượng')),
      body: Column(
        children: [
          _buildQualityRow('Low', 60),
          _buildQualityRow('Medium', 80),
          _buildQualityRow('High', 95),
        ],
      ),
    );
  }

  Widget _buildQualityRow(String quality, int compressionQuality) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: _photos[quality] != null
                  ? Image.file(_photos[quality]!, fit: BoxFit.cover)
                  : Container(color: Colors.grey[300]),
            ),
            SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _captureWithQuality(quality, compressionQuality),
              child: Text('$quality\n($compressionQuality%)'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 8. Tips & Best Practices

### ✅ DO - Nên làm

```dart
// ✅ Validate trước khi upload
if (result.fileSize > 5 * 1024 * 1024) {
  await context.showErrorMsg("File quá lớn (max 5MB)!");
  return;
}

// ✅ Show loading khi upload
showLoading("Đang upload...");
await _uploadToAPI(result);
hideLoading();

// ✅ Chọn compression phù hợp với use case
// Avatar: 80-85%
// Product: 85-90%
// Document: 90-95%

// ✅ Handle errors gracefully
onError: (error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Lỗi: $error')),
  );
}

// ✅ Dispose camera khi không dùng
@override
void dispose() {
  _controller?.dispose();
  super.dispose();
}
```

### ❌ DON'T - Không nên làm

```dart
// ❌ Không validate file size
await _uploadToAPI(result); // Có thể quá lớn

// ❌ Không handle null result
final result = await camera.show();
_uploadToAPI(result); // Crash nếu user cancel

// ❌ Compression quá thấp
compressionQuality: 30, // Quá thấp, ảnh xấu

// ❌ Max size quá lớn
maxWidth: 5000,
maxHeight: 5000, // Không cần thiết, tốn RAM
```

---

## 9. Troubleshooting

### Camera không khởi tạo

```dart
// Check permissions
await Permission.camera.request();

// Check available cameras
final cameras = await availableCameras();
if (cameras.isEmpty) {
  print('No cameras found!');
}
```

### Ảnh bị xoay sai

```dart
// Camera plugin tự động handle orientation
// Nếu vẫn bị lỗi, check platform-specific settings
```

### Memory issues với ảnh lớn

```dart
// Giảm compression quality và max size
CyberCamera(
  compressionQuality: 70,
  maxWidth: 1280,
  maxHeight: 1280,
  // ...
)
```

---

## Feature Summary

✅ **CyberCamera** - Inline camera control
✅ **CyberCameraView** - Full screen camera view
✅ **Image compression** với quality và size tùy chỉnh
✅ **Tap to capture** (CyberCamera)
✅ **Auto close** sau khi chụp (CyberCameraView)
✅ **Switch camera** (front/back)
✅ **Callbacks** với CyberCameraResult
✅ **Base64** và **bytes** export
✅ **Error handling**
✅ **Custom styling**
✅ **iOS-style UI**
