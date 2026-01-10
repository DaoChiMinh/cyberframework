# CyberCamera - Camera Widget với Binding

## Mục Lục
1. [Giới Thiệu](#giới-thiệu)
2. [Type Definitions](#type-definitions)
3. [CyberCamera Widget](#cybercamera-widget)
4. [CyberCameraController](#cybercameracontroller)
5. [CyberCameraView](#cybercameraview)
6. [Ví Dụ Sử Dụng](#ví-dụ-sử-dụng)
7. [Features](#features)
8. [Best Practices](#best-practices)
9. [Troubleshooting](#troubleshooting)

---

## Giới Thiệu

`CyberCamera` là một camera widget đầy đủ tính năng với khả năng chụp ảnh, hiển thị preview, nén ảnh tự động và data binding. Widget này được thiết kế để dễ sử dụng với internal controller, user không cần phải quản lý controller riêng.

### Đặc Điểm Chính

- ✅ **Internal Controller**: User không cần khai báo controller
- ✅ **Data Binding**: Hỗ trợ CyberBindingExpression và static string
- ✅ **Auto Compression**: Tự động nén ảnh sau khi chụp
- ✅ **Image Preview**: Hiển thị ảnh đã chụp với controls
- ✅ **Camera Switch**: Chuyển đổi giữa front/back camera
- ✅ **Responsive**: Tự động adapt cho mobile/tablet
- ✅ **Error Handling**: Callback cho mọi lỗi có thể xảy ra

### Dependencies

```yaml
dependencies:
  camera: ^latest_version
  flutter_image_compress: ^latest_version
  path: ^latest_version
```

### Import

```dart
import 'package:cyberframework/cyberframework.dart';
```

---

## Type Definitions

### Callbacks

```dart
/// Callback khi chụp ảnh thành công
typedef OnCaptureImage = void Function(CyberCameraResult result);

/// Callback khi có lỗi xảy ra
typedef OnCameraError = void Function(String error);
```

### CyberCameraResult

Class chứa kết quả sau khi chụp ảnh.

```dart
class CyberCameraResult {
  /// File ảnh đã chụp
  final File file;
  
  /// Tên file
  final String fileName;
  
  /// Kích thước file (bytes)
  final int fileSize;
  
  /// Ảnh đã được nén hay chưa
  final bool isCompressed;
  
  /// Chất lượng nén (0-100) nếu có
  final int? quality;
}
```

#### Properties Table

| Property | Type | Mô Tả |
|----------|------|-------|
| `file` | `File` | File object của ảnh đã chụp |
| `fileName` | `String` | Tên file (ví dụ: "compressed_1234567890.jpg") |
| `fileSize` | `int` | Kích thước file tính bằng bytes |
| `isCompressed` | `bool` | `true` nếu ảnh đã được nén |
| `quality` | `int?` | Chất lượng nén (0-100), null nếu không nén |

#### Ví Dụ

```dart
onCaptured: (CyberCameraResult result) {
  print('File path: ${result.file.path}');
  print('File name: ${result.fileName}');
  print('File size: ${result.fileSize} bytes');
  print('Is compressed: ${result.isCompressed}');
  if (result.isCompressed) {
    print('Quality: ${result.quality}%');
  }
}
```

---

## CyberCamera Widget

Widget chính để tích hợp camera vào UI.

### Constructor

```dart
const CyberCamera({
  super.key,
  this.imagePath,
  this.label,
  this.onCaptured,
  this.enabled = true,
  this.width,
  this.height,
  this.fit = BoxFit.cover,
  this.enableCompression = true,
  this.compressionQuality = 85,
  this.maxWidth = 1920,
  this.maxHeight = 1920,
  this.defaultCamera = CameraLensDirection.back,
  this.cameraTitle,
  this.placeholder,
  this.onError,
})
```

### Properties

#### Binding & Data

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `imagePath` | `dynamic` | Binding hoặc static string cho đường dẫn ảnh | null |
| `label` | `String?` | Label hiển thị phía trên widget | null |
| `onCaptured` | `OnCaptureImage?` | Callback khi chụp ảnh thành công | null |
| `onError` | `OnCameraError?` | Callback khi có lỗi | null |

#### Display Settings

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `enabled` | `bool` | Enable/disable widget | true |
| `width` | `double?` | Chiều rộng | double.infinity |
| `height` | `double?` | Chiều cao | 200 |
| `fit` | `BoxFit` | BoxFit cho image display | BoxFit.cover |
| `placeholder` | `Widget?` | Custom placeholder khi chưa có ảnh | null |

#### Camera Settings

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `enableCompression` | `bool` | Bật/tắt nén ảnh | true |
| `compressionQuality` | `int` | Chất lượng nén (0-100) | 85 |
| `maxWidth` | `int?` | Chiều rộng tối đa sau nén | 1920 |
| `maxHeight` | `int?` | Chiều cao tối đa sau nén | 1920 |
| `defaultCamera` | `CameraLensDirection` | Camera mặc định (back/front) | CameraLensDirection.back |
| `cameraTitle` | `String?` | Title cho camera screen | "Chụp ảnh" |

### imagePath Parameter

`imagePath` có thể là:

1. **Null**: Không binding, chỉ dùng callback
2. **String**: Static string path
3. **CyberBindingExpression**: Two-way binding với data row

```dart
// 1. Null - chỉ dùng callback
CyberCamera(
  imagePath: null,
  onCaptured: (result) {
    // Handle result manually
  },
)

// 2. Static string
String? myImagePath;
CyberCamera(
  imagePath: myImagePath,
  onCaptured: (result) {
    setState(() {
      myImagePath = result.file.path;
    });
  },
)

// 3. Binding expression
final row = CyberDataRow();
CyberCamera(
  imagePath: row.binding('avatar_path'),
  onCaptured: (result) {
    // Tự động update vào row
    print('Updated: ${row['avatar_path']}');
  },
)
```

---

## CyberCameraController

Controller nội bộ để điều khiển camera. **User không cần tạo controller**, widget tự động quản lý.

### Methods

```dart
final controller = CyberCameraController();

// Enable/disable camera
controller.setEnabled(true);

// Trigger capture
controller.capture();

// Switch camera
controller.switchCamera();

// Check state
bool isEnabled = controller.enabled;
CyberCameraAction pendingAction = controller.pendingAction;
```

### CyberCameraAction Enum

```dart
enum CyberCameraAction {
  none,         // Không có action
  capture,      // Chụp ảnh
  switchCamera, // Chuyển camera
}
```

**Lưu ý:** Controller được widget tự động quản lý, bạn chỉ cần truyền parameters vào widget.

---

## CyberCameraView

Full-screen camera view (được widget tự động gọi khi user tap vào camera button).

### Constructor

```dart
CyberCameraView({
  required this.context,
  this.controller,
  this.enableCompression = true,
  this.compressionQuality = 85,
  this.maxWidth = 1920,
  this.maxHeight = 1920,
  this.title,
  this.defaultCamera = CameraLensDirection.back,
  this.onError,
})
```

### Methods

```dart
final view = CyberCameraView(
  context: context,
  enableCompression: true,
  compressionQuality: 90,
  title: 'Chụp CMND',
  defaultCamera: CameraLensDirection.front,
  onError: (error) => print(error),
);

// Show camera screen
final CyberCameraResult? result = await view.show();

if (result != null) {
  print('Captured: ${result.file.path}');
}
```

**Lưu ý:** Thường không cần gọi trực tiếp, widget tự động handle.

---

## Ví Dụ Sử Dụng

### 1. Sử Dụng Cơ Bản

Camera đơn giản với state management.

```dart
class ProfilePage extends StatefulWidget {
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? avatarPath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            CyberCamera(
              imagePath: avatarPath,
              label: 'Ảnh đại diện',
              height: 300,
              onCaptured: (result) {
                setState(() {
                  avatarPath = result.file.path;
                });
                
                print('Image captured: ${result.fileName}');
                print('Size: ${result.fileSize} bytes');
              },
              onError: (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $error')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

### 2. Với Data Binding

Sử dụng CyberBindingExpression để tự động sync với data row.

```dart
class EmployeeForm extends StatefulWidget {
  @override
  State<EmployeeForm> createState() => _EmployeeFormState();
}

class _EmployeeFormState extends State<EmployeeForm> {
  final employeeRow = CyberDataRow();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Photo field với binding
          CyberCamera(
            imagePath: employeeRow.binding('photo_path'),
            label: 'Ảnh nhân viên',
            height: 250,
            onCaptured: (result) {
              print('Photo updated in row');
              print('Path: ${employeeRow['photo_path']}');
            },
          ),
          
          SizedBox(height: 16),
          
          // ID Card với binding
          CyberCamera(
            imagePath: employeeRow.binding('id_card_path'),
            label: 'CMND/CCCD',
            height: 200,
            onCaptured: (result) {
              print('ID card saved');
            },
          ),
          
          SizedBox(height: 24),
          
          CyberButton(
            label: 'Lưu',
            onClick: () {
              // Save data row
              print('Photo: ${employeeRow['photo_path']}');
              print('ID Card: ${employeeRow['id_card_path']}');
            },
          ),
        ],
      ),
    );
  }
}
```

### 3. Custom Configuration

Tùy chỉnh compression, camera, và UI.

```dart
CyberCamera(
  imagePath: imagePath,
  label: 'Chứng minh thư',
  
  // Display settings
  width: 400,
  height: 250,
  fit: BoxFit.contain,
  
  // Compression settings
  enableCompression: true,
  compressionQuality: 90,      // High quality
  maxWidth: 2048,
  maxHeight: 2048,
  
  // Camera settings
  defaultCamera: CameraLensDirection.back,
  cameraTitle: 'Chụp CMND',
  
  // Callbacks
  onCaptured: (result) {
    setState(() {
      imagePath = result.file.path;
    });
    
    if (result.isCompressed) {
      print('Compressed to: ${result.fileSize} bytes');
      print('Quality: ${result.quality}%');
    }
  },
  
  onError: (error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Lỗi Camera'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  },
)
```

### 4. Custom Placeholder

Tùy chỉnh giao diện khi chưa có ảnh.

```dart
CyberCamera(
  imagePath: productImagePath,
  label: 'Ảnh sản phẩm',
  height: 300,
  
  placeholder: Container(
    decoration: BoxDecoration(
      color: Colors.grey.shade100,
      border: Border.all(
        color: Colors.grey.shade300,
        width: 2,
        style: BorderStyle.solid,
      ),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 64,
          color: Colors.blue,
        ),
        SizedBox(height: 12),
        Text(
          'Chụp ảnh sản phẩm',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Tap để mở camera',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    ),
  ),
  
  onCaptured: (result) {
    // Handle capture
  },
)
```

### 5. Disabled State

Widget ở chế độ chỉ xem, không thể chụp/xóa ảnh.

```dart
class ImageViewer extends StatelessWidget {
  final String imagePath;
  
  const ImageViewer({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return CyberCamera(
      imagePath: imagePath,
      label: 'Ảnh (Chỉ xem)',
      enabled: false, // Disable all interactions
      height: 300,
    );
  }
}
```

### 6. Multiple Cameras

Nhiều camera trong một form.

```dart
class DocumentForm extends StatefulWidget {
  @override
  State<DocumentForm> createState() => _DocumentFormState();
}

class _DocumentFormState extends State<DocumentForm> {
  final dataRow = CyberDataRow();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Front ID
            CyberCamera(
              imagePath: dataRow.binding('id_front'),
              label: 'CMND/CCCD - Mặt trước',
              height: 200,
              cameraTitle: 'Chụp mặt trước',
              onCaptured: (result) {
                print('Front ID captured');
              },
            ),
            
            SizedBox(height: 16),
            
            // Back ID
            CyberCamera(
              imagePath: dataRow.binding('id_back'),
              label: 'CMND/CCCD - Mặt sau',
              height: 200,
              cameraTitle: 'Chụp mặt sau',
              onCaptured: (result) {
                print('Back ID captured');
              },
            ),
            
            SizedBox(height: 16),
            
            // Portrait
            CyberCamera(
              imagePath: dataRow.binding('portrait'),
              label: 'Ảnh chân dung',
              height: 300,
              defaultCamera: CameraLensDirection.front,
              cameraTitle: 'Chụp ảnh chân dung',
              onCaptured: (result) {
                print('Portrait captured');
              },
            ),
            
            SizedBox(height: 24),
            
            CyberButton(
              label: 'Hoàn thành',
              onClick: () {
                // Check all images
                if (dataRow['id_front'] == null) {
                  showError('Chưa chụp mặt trước CMND');
                  return;
                }
                if (dataRow['id_back'] == null) {
                  showError('Chưa chụp mặt sau CMND');
                  return;
                }
                if (dataRow['portrait'] == null) {
                  showError('Chưa chụp ảnh chân dung');
                  return;
                }
                
                // Submit
                submitDocuments();
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

### 7. Front Camera (Selfie)

```dart
CyberCamera(
  imagePath: selfiePath,
  label: 'Selfie',
  height: 400,
  defaultCamera: CameraLensDirection.front, // Front camera
  cameraTitle: 'Chụp ảnh selfie',
  onCaptured: (result) {
    setState(() {
      selfiePath = result.file.path;
    });
  },
)
```

### 8. High Quality Mode

Không nén ảnh, giữ nguyên chất lượng.

```dart
CyberCamera(
  imagePath: highQualityImagePath,
  label: 'Ảnh chất lượng cao',
  enableCompression: false, // Disable compression
  onCaptured: (result) {
    print('Original size: ${result.fileSize} bytes');
    print('Compressed: ${result.isCompressed}'); // false
  },
)
```

### 9. Upload After Capture

Tự động upload sau khi chụp.

```dart
class UploadImagePage extends StatefulWidget {
  @override
  State<UploadImagePage> createState() => _UploadImagePageState();
}

class _UploadImagePageState extends State<UploadImagePage> {
  String? imagePath;
  bool isUploading = false;

  Future<void> uploadImage(File imageFile) async {
    setState(() {
      isUploading = true;
    });

    try {
      // Upload to server
      final response = await uploadToServer(imageFile);
      
      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload thành công')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload thất bại: $e')),
      );
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              CyberCamera(
                imagePath: imagePath,
                label: 'Chọn ảnh để upload',
                enabled: !isUploading,
                onCaptured: (result) {
                  setState(() {
                    imagePath = result.file.path;
                  });
                  
                  // Auto upload
                  uploadImage(result.file);
                },
              ),
            ],
          ),
          
          if (isUploading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Đang upload...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
```

### 10. Validation

Validate ảnh trước khi cho phép tiếp tục.

```dart
class ValidatedCameraPage extends StatefulWidget {
  @override
  State<ValidatedCameraPage> createState() => _ValidatedCameraPageState();
}

class _ValidatedCameraPageState extends State<ValidatedCameraPage> {
  String? imagePath;
  String? validationError;

  Future<bool> validateImage(File imageFile) async {
    try {
      // Check file size
      final size = await imageFile.length();
      if (size > 5 * 1024 * 1024) { // 5MB
        setState(() {
          validationError = 'Ảnh quá lớn (max 5MB)';
        });
        return false;
      }

      // Check image dimensions
      final image = await decodeImageFromList(
        await imageFile.readAsBytes(),
      );
      
      if (image.width < 800 || image.height < 600) {
        setState(() {
          validationError = 'Ảnh quá nhỏ (min 800x600)';
        });
        return false;
      }

      setState(() {
        validationError = null;
      });
      return true;
    } catch (e) {
      setState(() {
        validationError = 'Lỗi validate ảnh';
      });
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CyberCamera(
            imagePath: imagePath,
            label: 'Ảnh (min 800x600, max 5MB)',
            onCaptured: (result) async {
              final isValid = await validateImage(result.file);
              
              if (isValid) {
                setState(() {
                  imagePath = result.file.path;
                });
              } else {
                // Clear invalid image
                setState(() {
                  imagePath = null;
                });
              }
            },
          ),
          
          if (validationError != null)
            Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                validationError!,
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }
}
```

---

## Features

### 1. Internal Controller

Widget tự động quản lý controller, user không cần khai báo.

```dart
// ✅ GOOD: Không cần controller
CyberCamera(
  imagePath: path,
  onCaptured: (result) {},
)

// ❌ OLD WAY: Cần quản lý controller
// final controller = CyberCameraController();
// CyberCamera(controller: controller, ...)
```

### 2. Data Binding

Hỗ trợ 3 modes:
- **Null**: Chỉ dùng callback
- **Static String**: Manual state management
- **Binding Expression**: Auto sync với data row

```dart
// Mode 1: Null + callback
CyberCamera(
  imagePath: null,
  onCaptured: (result) {
    uploadToServer(result.file);
  },
)

// Mode 2: Static string
String? path;
CyberCamera(
  imagePath: path,
  onCaptured: (result) {
    setState(() {
      path = result.file.path;
    });
  },
)

// Mode 3: Binding
CyberCamera(
  imagePath: row.binding('photo'),
  // Auto update row['photo']
)
```

### 3. Auto Compression

Tự động nén ảnh để tiết kiệm dung lượng và bandwidth.

```dart
CyberCamera(
  enableCompression: true,
  compressionQuality: 85,    // 0-100
  maxWidth: 1920,
  maxHeight: 1920,
  onCaptured: (result) {
    print('Original vs Compressed:');
    print('Compressed: ${result.isCompressed}');
    print('Quality: ${result.quality}%');
    print('Size: ${result.fileSize} bytes');
  },
)
```

**Compression Quality Guide:**
- **60-70**: Low quality, small size (cho thumbnails)
- **80-85**: Good quality, balanced size (recommended)
- **90-95**: High quality, larger size (cho documents)
- **100**: Max quality, largest size (không nên dùng)

### 4. Image Preview & Controls

Tự động hiển thị ảnh với controls:
- **Camera button**: Mở camera để chụp (hoặc chụp lại)
- **Delete button**: Xóa ảnh hiện tại
- **Image display**: Preview ảnh đã chụp

```dart
// Preview tự động
CyberCamera(
  imagePath: path,
  fit: BoxFit.cover, // cover, contain, fill, etc.
)
```

### 5. Camera Switch

Dễ dàng chuyển đổi giữa front/back camera.

```dart
// Back camera (default)
CyberCamera(
  defaultCamera: CameraLensDirection.back,
  ...
)

// Front camera (selfie)
CyberCamera(
  defaultCamera: CameraLensDirection.front,
  ...
)
```

Trong camera screen, user có thể tap icon để switch camera.

### 6. Error Handling

Comprehensive error handling với callback.

```dart
CyberCamera(
  onError: (error) {
    print('Camera error: $error');
    
    // Show to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error)),
    );
    
    // Log to analytics
    logError(error);
  },
)
```

**Các lỗi có thể xảy ra:**
- "Không tìm thấy camera"
- "Lỗi khởi tạo camera"
- "Lỗi khi chụp ảnh"
- "Lỗi xử lý ảnh"
- Permission denied (cần request trong AndroidManifest/Info.plist)

### 7. Responsive Design

Tự động adapt kích thước theo parent constraints.

```dart
// Full width, custom height
CyberCamera(
  width: double.infinity,
  height: 300,
  ...
)

// Fixed size
CyberCamera(
  width: 400,
  height: 300,
  ...
)

// Responsive trong Column
Column(
  children: [
    Expanded(
      child: CyberCamera(...),
    ),
  ],
)
```

### 8. Custom Styling

Tùy chỉnh placeholder và theme.

```dart
CyberCamera(
  placeholder: CustomPlaceholder(),
  // Widget tự động adapt theme
)
```

---

## Best Practices

### 1. Compression Settings

```dart
// ✅ GOOD: Profile photos
CyberCamera(
  enableCompression: true,
  compressionQuality: 85,
  maxWidth: 1920,
  maxHeight: 1920,
)

// ✅ GOOD: Documents (high quality)
CyberCamera(
  enableCompression: true,
  compressionQuality: 95,
  maxWidth: 2048,
  maxHeight: 2048,
)

// ✅ GOOD: Thumbnails
CyberCamera(
  enableCompression: true,
  compressionQuality: 70,
  maxWidth: 512,
  maxHeight: 512,
)

// ⚠️ CAREFUL: No compression (very large files)
CyberCamera(
  enableCompression: false,
  // Only for special cases
)
```

### 2. Error Handling

```dart
// ✅ GOOD: Always handle errors
CyberCamera(
  onError: (error) {
    // Show user-friendly message
    showErrorDialog(context, error);
    
    // Log for debugging
    debugPrint('Camera error: $error');
  },
)

// ❌ BAD: Ignore errors
CyberCamera(
  // No onError - user won't know what's wrong
)
```

### 3. Camera Selection

```dart
// ✅ GOOD: Back camera cho documents
CyberCamera(
  label: 'CMND/CCCD',
  defaultCamera: CameraLensDirection.back,
)

// ✅ GOOD: Front camera cho selfie
CyberCamera(
  label: 'Selfie',
  defaultCamera: CameraLensDirection.front,
)
```

### 4. Validation

```dart
// ✅ GOOD: Validate before proceeding
CyberCamera(
  onCaptured: (result) async {
    // Check size
    if (result.fileSize > 10 * 1024 * 1024) {
      showError('File too large');
      return;
    }
    
    // Check dimensions
    final valid = await validateImageDimensions(result.file);
    if (!valid) {
      showError('Invalid dimensions');
      return;
    }
    
    // Process
    processImage(result);
  },
)
```

### 5. Permissions

Nhớ request permissions trong manifest files:

**Android (android/app/src/main/AndroidManifest.xml):**
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" />
<uses-feature android:name="android.hardware.camera.autofocus" />
```

**iOS (ios/Runner/Info.plist):**
```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to take photos</string>
```

### 6. Label Usage

```dart
// ✅ GOOD: Clear, descriptive labels
CyberCamera(
  label: 'Ảnh đại diện',
  ...
)

CyberCamera(
  label: 'CMND/CCCD - Mặt trước',
  ...
)

// ❌ BAD: Vague labels
CyberCamera(
  label: 'Ảnh',
  ...
)
```

---

## Troubleshooting

### Camera không mở

**Nguyên nhân:**
1. Chưa request permissions
2. Device không có camera
3. Camera đang được app khác sử dụng

**Giải pháp:**
```dart
// 1. Check permissions in manifest
// 2. Add error handling
CyberCamera(
  onError: (error) {
    if (error.contains('permission')) {
      showPermissionDialog();
    } else if (error.contains('không tìm thấy')) {
      showNoCameraDialog();
    }
  },
)
```

### Ảnh bị mờ sau compression

**Nguyên nhân:**
- `compressionQuality` quá thấp
- `maxWidth`/`maxHeight` quá nhỏ

**Giải pháp:**
```dart
// Tăng quality
CyberCamera(
  compressionQuality: 90, // Từ 85 lên 90
  maxWidth: 2048,         // Từ 1920 lên 2048
  maxHeight: 2048,
)

// Hoặc tắt compression
CyberCamera(
  enableCompression: false,
)
```

### Binding không update

**Nguyên nhân:**
- Sai binding expression
- Data row chưa được khởi tạo
- Widget unmounted

**Giải pháp:**
```dart
// Verify binding
final row = CyberDataRow();

CyberCamera(
  imagePath: row.binding('photo'), // Đúng field name
  onCaptured: (result) {
    print('Updated: ${row['photo']}'); // Verify
  },
)
```

### File size quá lớn

**Nguyên nhân:**
- Compression bị tắt
- Quality quá cao

**Giải pháp:**
```dart
CyberCamera(
  enableCompression: true,
  compressionQuality: 85,  // Giảm từ 95
  maxWidth: 1920,          // Giảm từ 2048
  maxHeight: 1920,
)
```

### Widget bị overflow

**Nguyên nhân:**
- Parent không có constraints
- Height quá lớn

**Giải pháp:**
```dart
// Wrap in scrollable
SingleChildScrollView(
  child: CyberCamera(
    height: 300, // Fixed height
  ),
)

// Hoặc dùng Expanded
Column(
  children: [
    Expanded(
      flex: 1,
      child: CyberCamera(...),
    ),
  ],
)
```

### Camera bị xoay sai hướng

**Nguyên nhân:**
- Device orientation issues
- Camera plugin bug

**Giải pháp:**
```dart
// Lock orientation trong app
SystemChrome.setPreferredOrientations([
  DeviceOrientation.portraitUp,
]);
```

---

## Tips & Tricks

### 1. Custom Camera Button

Tạo button custom để mở camera:

```dart
class CustomCameraButton extends StatelessWidget {
  final Function(CyberCameraResult) onCaptured;
  
  const CustomCameraButton({required this.onCaptured});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(Icons.camera_alt),
      label: Text('Chụp ảnh'),
      onPressed: () async {
        final view = CyberCameraView(
          context: context,
          enableCompression: true,
          compressionQuality: 85,
        );
        
        final result = await view.show();
        if (result != null) {
          onCaptured(result);
        }
      },
    );
  }
}
```

### 2. Image Cropping

Thêm cropping sau khi chụp:

```dart
CyberCamera(
  onCaptured: (result) async {
    // Crop image
    final croppedFile = await cropImage(result.file);
    
    if (croppedFile != null) {
      setState(() {
        imagePath = croppedFile.path;
      });
    }
  },
)
```

### 3. Multiple Image Upload

Upload nhiều ảnh cùng lúc:

```dart
class MultiImageUpload extends StatefulWidget {
  @override
  State<MultiImageUpload> createState() => _MultiImageUploadState();
}

class _MultiImageUploadState extends State<MultiImageUpload> {
  List<String> imagePaths = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Show all images
        ...imagePaths.map((path) => Image.file(File(path))),
        
        // Add more button
        CyberCamera(
          imagePath: null,
          label: 'Thêm ảnh',
          onCaptured: (result) {
            setState(() {
              imagePaths.add(result.file.path);
            });
          },
        ),
      ],
    );
  }
}
```

### 4. Watermark

Thêm watermark vào ảnh:

```dart
CyberCamera(
  onCaptured: (result) async {
    // Add watermark
    final watermarkedFile = await addWatermark(
      result.file,
      text: 'Company Name',
    );
    
    setState(() {
      imagePath = watermarkedFile.path;
    });
  },
)
```

---

## Performance Tips

1. **Enable Compression**: Luôn bật compression trừ khi thực sự cần ảnh gốc
2. **Optimize Quality**: 85% là sweet spot cho most cases
3. **Limit Max Size**: Đặt maxWidth/maxHeight hợp lý (1920x1920 cho mobile)
4. **Dispose Properly**: Widget tự động dispose, không cần cleanup manual
5. **Async Upload**: Upload ảnh async, không block UI

---

## Version History

### 1.0.0
- Initial release
- Internal controller
- Data binding support
- Auto compression
- Image preview & controls
- Camera switch
- Error handling

---

## License

MIT License - CyberFramework
