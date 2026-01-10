# CyberFilePicker - File & Image Picker

## Mục Lục
1. [Giới Thiệu](#giới-thiệu)
2. [CyberFilePicker Widget](#cyberfilepicker-widget)
3. [CyberFilePickerField Widget](#cyberfil epickerfield-widget)
4. [CyberFilePickerController](#cyberfilepickercontroller)
5. [Ví Dụ Sử Dụng](#ví-dụ-sử-dụng)
6. [Features](#features)
7. [Best Practices](#best-practices)
8. [Troubleshooting](#troubleshooting)

---

## Giới Thiệu

`CyberFilePicker` là widget để chọn file/ảnh với **Controller Pattern** và hỗ trợ compression tự động. Cung cấp 2 variants: Button style và Field style với preview.

### Đặc Điểm Chính

- ✅ **Controller Required**: Quản lý file state qua controller
- ✅ **Multi-Source**: Camera, Gallery, File Picker
- ✅ **Auto Compression**: Tự động compress ảnh
- ✅ **File Preview**: Hiển thị preview cho ảnh và file
- ✅ **Base64 Support**: Convert ảnh sang base64
- ✅ **Type Filtering**: Filter theo extension
- ✅ **Two Variants**: Button và Field với preview

### Dependencies

```yaml
dependencies:
  image_picker: ^1.0.0
  file_picker: ^6.0.0
  flutter_image_compress: ^2.0.0
  path_provider: ^2.0.0
  path: ^1.8.0
```

### Import

```dart
import 'package:cyberframework/cyberframework.dart';
```

---

## CyberFilePicker Widget

Widget dạng button để chọn file.

### Constructor

```dart
const CyberFilePicker({
  super.key,
  this.label = "Chọn file",
  this.icon,
  this.controller,
  this.onFileSelected,
  this.onError,
  this.backgroundColor,
  this.textColor,
  this.borderRadius = 8.0,
  this.padding,
  this.enabled,
  this.enableCompression = true,
  this.compressionQuality = 85,
  this.maxWidth = 1920,
  this.maxHeight = 1920,
  this.allowedExtensions,
  this.allowMultiple = false,
  this.buttonStyle,
})
```

### Properties

#### Required

| Property | Type | Mô Tả |
|----------|------|-------|
| `controller` hoặc `onFileSelected` | Một trong hai | Controller HOẶC callback |

⚠️ **Phải có controller HOẶC onFileSelected**

#### Display

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `label` | `String` | Text trên button | "Chọn file" |
| `icon` | `IconData?` | Icon hiển thị | null |
| `backgroundColor` | `Color?` | Màu nền button | Color(0xFF00D287) |
| `textColor` | `Color?` | Màu chữ | Colors.white |
| `borderRadius` | `double` | Bo góc | 8.0 |
| `padding` | `EdgeInsets?` | Padding | (24, 12) |
| `buttonStyle` | `ButtonStyle?` | Custom button style | null |

#### Compression

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `enableCompression` | `bool` | Bật compression | true |
| `compressionQuality` | `int` | Chất lượng (0-100) | 85 |
| `maxWidth` | `int?` | Chiều rộng tối đa | 1920 |
| `maxHeight` | `int?` | Chiều cao tối đa | 1920 |

#### File Filtering

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `allowedExtensions` | `List<String>?` | Extensions cho phép | null (all) |
| `allowMultiple` | `bool` | Cho phép chọn nhiều | false |

#### Callbacks

| Property | Type | Mô Tả |
|----------|------|-------|
| `onFileSelected` | `OnFileSelected?` | Khi file được chọn |
| `onError` | `OnFileError?` | Khi có lỗi |

---

## CyberFilePickerField Widget

Widget dạng field với preview.

### Constructor

```dart
const CyberFilePickerField({
  super.key,
  this.label = "Chọn file",
  this.hint,
  this.controller,
  this.onFileSelected,
  this.onError,
  this.enableCompression = true,
  this.compressionQuality = 85,
  this.maxWidth = 1920,
  this.maxHeight = 1920,
  this.allowedExtensions,
  this.isShowLabel = true,
  this.backgroundColor,
})
```

### Properties

Tương tự CyberFilePicker nhưng thêm:

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `hint` | `String?` | Hint text | null |
| `isShowLabel` | `bool` | Hiển thị label | true |

---

## CyberFilePickerController

### Properties & Methods

```dart
final controller = CyberFilePickerController();

// Properties
PlatformFile? file = controller.file;
bool enabled = controller.enabled;
bool hasFile = controller.hasFile;

// Methods
controller.setFile(file);
controller.clear();
controller.setEnabled(true);
controller.dispose();
```

---

## CyberFileResult

Kết quả khi chọn file.

```dart
class CyberFileResult {
  final File file;
  final String fileName;
  final String extension;
  final int fileSize;
  final CyberFileType fileType; // image, file
  final bool isCompressed;
  
  // Methods
  PlatformFile toPlatformFile();
  Future<List<int>> getBytes();
  Future<String> getBase64();
}
```

---

## Ví Dụ Sử Dụng

### 1. Button Style - Cơ Bản

Simple file picker button.

```dart
class UploadForm extends StatefulWidget {
  @override
  State<UploadForm> createState() => _UploadFormState();
}

class _UploadFormState extends State<UploadForm> {
  final fileController = CyberFilePickerController();

  @override
  void dispose() {
    fileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberFilePicker(
          label: 'Chọn file',
          icon: Icons.upload_file,
          controller: fileController,
          onFileSelected: (result) {
            print('File selected: ${result.fileName}');
            print('Size: ${result.fileSize} bytes');
          },
        ),
        
        // Display selected file
        ListenableBuilder(
          listenable: fileController,
          builder: (context, _) {
            if (!fileController.hasFile) {
              return Text('Chưa chọn file');
            }
            
            return Text('File: ${fileController.file!.name}');
          },
        ),
      ],
    );
  }
}
```

### 2. Field Style Với Preview

Field với image/file preview.

```dart
class ProfileForm extends StatefulWidget {
  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final avatarController = CyberFilePickerController();

  @override
  Widget build(BuildContext context) {
    return CyberFilePickerField(
      label: 'Ảnh đại diện',
      hint: 'Nhấn để chọn ảnh',
      controller: avatarController,
      allowedExtensions: ['jpg', 'jpeg', 'png'],
      onFileSelected: (result) {
        print('Avatar selected: ${result.fileName}');
      },
    );
  }
}
```

### 3. Image Compression

Tùy chỉnh compression settings.

```dart
CyberFilePicker(
  label: 'Chọn ảnh',
  controller: controller,
  
  // Compression settings
  enableCompression: true,
  compressionQuality: 70,  // 0-100
  maxWidth: 1024,
  maxHeight: 1024,
  
  onFileSelected: (result) {
    print('Original size: unknown');
    print('Compressed size: ${result.fileSize}');
    print('Is compressed: ${result.isCompressed}');
  },
)
```

### 4. File Type Filtering

Chỉ cho phép các file types nhất định.

```dart
class DocumentPicker extends StatelessWidget {
  final controller = CyberFilePickerController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // PDF only
        CyberFilePicker(
          label: 'Chọn PDF',
          controller: controller,
          allowedExtensions: ['pdf'],
          enableCompression: false, // No compression for PDF
        ),
        
        SizedBox(height: 16),
        
        // Images only
        CyberFilePicker(
          label: 'Chọn ảnh',
          controller: controller,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'gif'],
        ),
        
        SizedBox(height: 16),
        
        // Office documents
        CyberFilePicker(
          label: 'Chọn tài liệu',
          controller: controller,
          allowedExtensions: ['doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx'],
        ),
      ],
    );
  }
}
```

### 5. Upload Với Base64

Convert file sang base64 để upload.

```dart
class ImageUploadForm extends StatefulWidget {
  @override
  State<ImageUploadForm> createState() => _ImageUploadFormState();
}

class _ImageUploadFormState extends State<ImageUploadForm> {
  final imageController = CyberFilePickerController();
  String? base64Image;

  Future<void> uploadImage(CyberFileResult result) async {
    try {
      // Convert to base64
      final base64 = await result.getBase64();
      
      setState(() {
        base64Image = base64;
      });
      
      // Upload to server
      await api.uploadImage({
        'image': base64,
        'filename': result.fileName,
      });
      
      showSnackBar('Upload thành công');
    } catch (e) {
      showSnackBar('Lỗi upload: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberFilePickerField(
          label: 'Ảnh sản phẩm',
          controller: imageController,
          allowedExtensions: ['jpg', 'jpeg', 'png'],
          onFileSelected: uploadImage,
        ),
        
        if (base64Image != null)
          Text('Đã upload: ${base64Image!.length} characters'),
      ],
    );
  }
}
```

### 6. Multiple Files

Chọn nhiều files (chỉ lấy file đầu tiên).

```dart
CyberFilePicker(
  label: 'Chọn nhiều ảnh',
  controller: controller,
  allowMultiple: true, // Cho phép chọn nhiều
  onFileSelected: (result) {
    // Chỉ lấy file đầu tiên
    print('First file: ${result.fileName}');
  },
)
```

### 7. Error Handling

Xử lý lỗi khi chọn file.

```dart
class RobustFilePicker extends StatefulWidget {
  @override
  State<RobustFilePicker> createState() => _RobustFilePickerState();
}

class _RobustFilePickerState extends State<RobustFilePicker> {
  final controller = CyberFilePickerController();
  String? errorMessage;

  void handleError(String error) {
    setState(() {
      errorMessage = error;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Colors.red,
      ),
    );
  }

  void handleFileSelected(CyberFileResult result) {
    setState(() {
      errorMessage = null;
    });
    
    // Validate file size (max 5MB)
    if (result.fileSize > 5 * 1024 * 1024) {
      handleError('File quá lớn (tối đa 5MB)');
      controller.clear();
      return;
    }
    
    print('File OK: ${result.fileName}');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberFilePickerField(
          label: 'Chọn file (tối đa 5MB)',
          controller: controller,
          onFileSelected: handleFileSelected,
          onError: handleError,
        ),
        
        if (errorMessage != null)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              errorMessage!,
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
```

### 8. Custom Button Style

Tùy chỉnh button style.

```dart
CyberFilePicker(
  label: 'Upload ảnh',
  icon: Icons.cloud_upload,
  controller: controller,
  
  // Custom style
  buttonStyle: ElevatedButton.styleFrom(
    backgroundColor: Colors.purple,
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    elevation: 5,
  ),
)
```

### 9. Conditional Enable/Disable

Enable/disable dựa trên điều kiện.

```dart
class ConditionalPicker extends StatefulWidget {
  @override
  State<ConditionalPicker> createState() => _ConditionalPickerState();
}

class _ConditionalPickerState extends State<ConditionalPicker> {
  final controller = CyberFilePickerController();
  bool agreeTerms = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CheckboxListTile(
          title: Text('Tôi đồng ý với điều khoản'),
          value: agreeTerms,
          onChanged: (value) {
            setState(() {
              agreeTerms = value ?? false;
              controller.setEnabled(agreeTerms);
            });
          },
        ),
        
        CyberFilePicker(
          label: 'Chọn tài liệu',
          controller: controller,
        ),
      ],
    );
  }
}
```

### 10. Save To Database

Lưu file vào database.

```dart
class ProductForm extends StatefulWidget {
  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final drProduct = CyberDataRow();
  final imageController = CyberFilePickerController();

  @override
  void initState() {
    super.initState();
    drProduct['name'] = '';
    drProduct['image_base64'] = '';
  }

  Future<void> handleImageSelected(CyberFileResult result) async {
    try {
      // Convert to base64
      final base64 = await result.getBase64();
      
      // Save to data row
      drProduct['image_base64'] = base64;
      
      print('Image saved to data row');
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> saveProduct() async {
    if (drProduct['image_base64'].toString().isEmpty) {
      showError('Vui lòng chọn ảnh');
      return;
    }
    
    // Save to database
    await api.createProduct({
      'name': drProduct['name'],
      'image': drProduct['image_base64'],
    });
    
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberText(
          text: drProduct.bind('name'),
          label: 'Tên sản phẩm',
        ),
        
        SizedBox(height: 16),
        
        CyberFilePickerField(
          label: 'Ảnh sản phẩm',
          controller: imageController,
          allowedExtensions: ['jpg', 'jpeg', 'png'],
          onFileSelected: handleImageSelected,
        ),
        
        SizedBox(height: 24),
        
        CyberButton(
          label: 'Lưu sản phẩm',
          onClick: saveProduct,
        ),
      ],
    );
  }
}
```

---

## Features

### 1. Multi-Source Picker

Bottom sheet với 3 options:
- 📷 Camera
- 🖼️ Gallery
- 📁 File Picker

### 2. Auto Compression

Tự động compress ảnh:

```dart
// Quality levels
compressionQuality: 60  // Low (thumbnails)
compressionQuality: 85  // Recommended
compressionQuality: 95  // High (documents)
```

### 3. File Preview

Field variant hiển thị preview:
- ✅ Ảnh: Thumbnail preview
- ✅ File: Icon + tên + kích thước

### 4. Type Filtering

```dart
// Images only
allowedExtensions: ['jpg', 'jpeg', 'png']

// Documents only
allowedExtensions: ['pdf', 'doc', 'docx']

// All files
allowedExtensions: null
```

### 5. Base64 Conversion

```dart
final result = await controller.file;
final base64 = await result.getBase64();
```

### 6. File Info

```dart
CyberFileResult {
  file: File('/path/to/file')
  fileName: 'photo.jpg'
  extension: 'jpg'
  fileSize: 245760
  fileType: CyberFileType.image
  isCompressed: true
}
```

---

## Best Practices

### 1. Controller Management

```dart
// ✅ GOOD: Dispose controller
class MyForm extends StatefulWidget {
  @override
  State<MyForm> createState() => _MyFormState();
}

class _MyFormState extends State<MyForm> {
  final controller = CyberFilePickerController();

  @override
  void dispose() {
    controller.dispose(); // Important!
    super.dispose();
  }
}

// ❌ BAD: No dispose
class MyForm extends StatelessWidget {
  final controller = CyberFilePickerController();
  // Will leak memory!
}
```

### 2. Compression Settings

```dart
// ✅ GOOD: Appropriate compression
CyberFilePicker(
  enableCompression: true,
  compressionQuality: 85,  // Good balance
  maxWidth: 1920,
  maxHeight: 1920,
)

// ❌ BAD: Too aggressive
CyberFilePicker(
  compressionQuality: 10,  // Too low!
  maxWidth: 100,           // Too small!
)

// ❌ BAD: No compression for large images
CyberFilePicker(
  enableCompression: false,  // May cause memory issues
)
```

### 3. File Type Validation

```dart
// ✅ GOOD: Specific types
allowedExtensions: ['jpg', 'jpeg', 'png', 'gif']

// ✅ GOOD: Validate after selection
onFileSelected: (result) {
  if (result.fileSize > 5 * 1024 * 1024) {
    showError('File quá lớn');
    controller.clear();
  }
}

// ❌ BAD: No validation
allowedExtensions: null  // Accept anything
```

### 4. Error Handling

```dart
// ✅ GOOD: Handle errors
CyberFilePicker(
  controller: controller,
  onFileSelected: (result) {
    // Handle success
  },
  onError: (error) {
    // Handle error
    showSnackBar(error);
  },
)

// ❌ BAD: Ignore errors
CyberFilePicker(
  controller: controller,
  onFileSelected: (result) {
    // Only handle success
  },
  // No onError!
)
```

### 5. UI Feedback

```dart
// ✅ GOOD: Show file info
ListenableBuilder(
  listenable: controller,
  builder: (context, _) {
    if (controller.hasFile) {
      return Text('File: ${controller.file!.name}');
    }
    return Text('Chưa chọn file');
  },
)

// ❌ BAD: No feedback
CyberFilePicker(
  controller: controller,
)
// User doesn't know if file was selected
```

---

## Troubleshooting

### File không được chọn

**Nguyên nhân:**
1. Không có controller hoặc callback
2. Permissions không được cấp

**Giải pháp:**
```dart
// 1. Phải có controller HOẶC callback
CyberFilePicker(
  controller: controller,  // ✅ HOẶC
  onFileSelected: (result) {},  // ✅
)

// 2. Add permissions (AndroidManifest.xml, Info.plist)
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```

### Compression không hoạt động

**Nguyên nhân:** File không phải ảnh

**Giải pháp:**
```dart
// Compression chỉ áp dụng cho ảnh
if (result.fileType == CyberFileType.image) {
  print('Compressed: ${result.isCompressed}');
}
```

### Memory issues với ảnh lớn

**Nguyên nhân:** Không compress

**Giải pháp:**
```dart
// ✅ Enable compression
CyberFilePicker(
  enableCompression: true,
  compressionQuality: 85,
  maxWidth: 1920,
  maxHeight: 1920,
)
```

### Base64 string quá dài

**Nguyên nhân:** Ảnh gốc quá lớn

**Giải pháp:**
```dart
// Compress trước khi convert base64
CyberFilePicker(
  enableCompression: true,
  compressionQuality: 70,  // Lower quality
  maxWidth: 1024,          // Smaller size
  maxHeight: 1024,
)
```

### Preview không hiển thị

**Nguyên nhân:** Dùng CyberFilePicker thay vì CyberFilePickerField

**Giải pháp:**
```dart
// ✅ Use Field variant for preview
CyberFilePickerField(
  controller: controller,
)

// ❌ Button variant has no preview
CyberFilePicker(
  controller: controller,
)
```

---

## Tips & Tricks

### 1. Format File Size

```dart
String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

// Usage
onFileSelected: (result) {
  print('Size: ${formatFileSize(result.fileSize)}');
}
```

### 2. Validate Extension

```dart
bool isValidExtension(CyberFileResult result, List<String> allowed) {
  return allowed.contains(result.extension.toLowerCase());
}

// Usage
onFileSelected: (result) {
  if (!isValidExtension(result, ['jpg', 'png'])) {
    showError('Chỉ chấp nhận JPG/PNG');
    controller.clear();
  }
}
```

### 3. Progress Indicator

```dart
class ProgressPicker extends StatefulWidget {
  @override
  State<ProgressPicker> createState() => _ProgressPickerState();
}

class _ProgressPickerState extends State<ProgressPicker> {
  final controller = CyberFilePickerController();
  bool isUploading = false;

  Future<void> handleFile(CyberFileResult result) async {
    setState(() => isUploading = true);
    
    try {
      await uploadFile(result);
    } finally {
      setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CyberFilePickerField(
          controller: controller,
          onFileSelected: handleFile,
        ),
        
        if (isUploading)
          Positioned.fill(
            child: Container(
              color: Colors.black26,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
      ],
    );
  }
}
```

### 4. Preview Before Upload

```dart
Future<bool> confirmUpload(CyberFileResult result) async {
  return await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Xác nhận'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (result.fileType == CyberFileType.image)
            Image.file(result.file, height: 200),
          SizedBox(height: 8),
          Text('File: ${result.fileName}'),
          Text('Size: ${formatFileSize(result.fileSize)}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Hủy'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Upload'),
        ),
      ],
    ),
  ) ?? false;
}
```

### 5. Clear Button

```dart
Row(
  children: [
    Expanded(
      child: CyberFilePicker(
        controller: controller,
      ),
    ),
    SizedBox(width: 12),
    IconButton(
      icon: Icon(Icons.clear),
      onPressed: () => controller.clear(),
    ),
  ],
)
```

---

## Performance Tips

1. **Enable Compression**: Always enable for images
2. **Set Max Dimensions**: Limit maxWidth/maxHeight
3. **Dispose Controllers**: Prevent memory leaks
4. **Validate Size**: Check file size before processing
5. **Use Field Variant**: Better UX with preview

---

## Version History

### 1.0.0
- Initial release
- Multi-source picker (Camera, Gallery, Files)
- Auto compression
- Base64 conversion
- Two variants (Button, Field)
- File preview

---

## License

MIT License - CyberFramework
