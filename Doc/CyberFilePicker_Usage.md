# CyberFilePicker - Hướng dẫn sử dụng

## Dependencies cần thêm vào pubspec.yaml

```yaml
dependencies:
  image_picker: ^1.0.7
  file_picker: ^6.1.1
  flutter_image_compress: ^2.1.0
  path_provider: ^2.1.2
  path: ^1.8.3
```

## Cài đặt permissions

### Android (android/app/src/main/AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>

<application>
    <!-- ... -->
</application>
```

### iOS (ios/Runner/Info.plist)
```xml
<key>NSCameraUsageDescription</key>
<string>Ứng dụng cần quyền truy cập camera để chụp ảnh</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Ứng dụng cần quyền truy cập thư viện ảnh</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Ứng dụng cần quyền lưu ảnh vào thư viện</string>
```

---

## 1. CyberFilePicker - Button đơn giản

### Basic Usage
```dart
CyberFilePicker(
  label: "Chọn ảnh",
  icon: Icons.image,
  onFileSelected: (result) {
    print('File selected: ${result.fileName}');
    print('File size: ${result.fileSize} bytes');
    print('Is compressed: ${result.isCompressed}');
    
    // Upload file
    _uploadToAPI(result);
  },
  onError: (error) {
    print('Error: $error');
  },
)
```

### Upload ảnh lên API
```dart
Future<void> _uploadToAPI(CyberFileResult result) async {
  // Option 1: Upload as File
  final file = result.file;
  
  // Option 2: Upload as bytes
  final bytes = await result.getBytes();
  
  // Option 3: Upload as base64
  final base64String = await result.getBase64();
  
  // Example with Dio
  FormData formData = FormData.fromMap({
    'file': await MultipartFile.fromFile(
      result.file.path,
      filename: result.fileName,
    ),
  });
  
  final response = await dio.post('/upload', data: formData);
}
```

---

## 2. Custom Compression Settings

### Nén ảnh với chất lượng cao
```dart
CyberFilePicker(
  label: "Chọn ảnh chất lượng cao",
  enableCompression: true,
  compressionQuality: 95, // 0-100
  maxWidth: 2560,
  maxHeight: 2560,
  onFileSelected: (result) {
    print('Compressed size: ${result.fileSize}');
  },
)
```

### Nén ảnh nhanh (file nhỏ)
```dart
CyberFilePicker(
  label: "Chọn ảnh (nén nhanh)",
  enableCompression: true,
  compressionQuality: 70,
  maxWidth: 1280,
  maxHeight: 1280,
  onFileSelected: (result) {
    print('Small file size: ${result.fileSize}');
  },
)
```

### Không nén (giữ nguyên)
```dart
CyberFilePicker(
  label: "Chọn ảnh gốc",
  enableCompression: false,
  onFileSelected: (result) {
    print('Original file');
  },
)
```

---

## 3. Giới hạn loại file

### Chỉ cho phép PDF và DOCX
```dart
CyberFilePicker(
  label: "Chọn tài liệu",
  icon: Icons.description,
  allowedExtensions: ['pdf', 'docx', 'doc'],
  onFileSelected: (result) {
    print('Document: ${result.fileName}');
  },
)
```

### Chỉ cho phép file Excel
```dart
CyberFilePicker(
  label: "Chọn file Excel",
  allowedExtensions: ['xlsx', 'xls', 'csv'],
  onFileSelected: (result) {
    // Process Excel file
  },
)
```

---

## 4. CyberFilePickerField - Field với preview

### Basic Field
```dart
CyberFilePickerField(
  label: "Ảnh đại diện",
  hint: "Chọn ảnh đại diện của bạn",
  onFileSelected: (result) {
    setState(() {
      _avatarFile = result;
    });
  },
)
```

### Field với compression tùy chỉnh
```dart
CyberFilePickerField(
  label: "Ảnh sản phẩm",
  hint: "Chọn ảnh sản phẩm (tối đa 5MB)",
  enableCompression: true,
  compressionQuality: 85,
  maxWidth: 1920,
  maxHeight: 1920,
  backgroundColor: Colors.grey[100],
  onFileSelected: (result) {
    if (result.fileSize > 5 * 1024 * 1024) {
      // Show error: File quá lớn
    } else {
      _uploadProductImage(result);
    }
  },
  onError: (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error)),
    );
  },
)
```

---

## 5. Complete Form Example

```dart
class UploadFormScreen extends StatefulWidget {
  @override
  State<UploadFormScreen> createState() => _UploadFormScreenState();
}

class _UploadFormScreenState extends State<UploadFormScreen> {
  CyberFileResult? _avatarFile;
  CyberFileResult? _documentFile;
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload Files')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar field
            CyberFilePickerField(
              label: "Ảnh đại diện",
              hint: "Chọn ảnh đại diện",
              enableCompression: true,
              compressionQuality: 85,
              maxWidth: 800,
              maxHeight: 800,
              onFileSelected: (result) {
                setState(() {
                  _avatarFile = result;
                });
              },
            ),

            SizedBox(height: 16),

            // Document field
            CyberFilePickerField(
              label: "Tài liệu đính kèm",
              hint: "Chọn file PDF hoặc Word",
              allowedExtensions: ['pdf', 'docx', 'doc'],
              enableCompression: false,
              onFileSelected: (result) {
                setState(() {
                  _documentFile = result;
                });
              },
            ),

            SizedBox(height: 24),

            // Upload button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _handleUpload,
                child: _isUploading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Upload'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleUpload() async {
    if (_avatarFile == null && _documentFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng chọn ít nhất 1 file')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Upload avatar
      if (_avatarFile != null) {
        await _uploadFile(
          file: _avatarFile!,
          fieldName: 'avatar',
        );
      }

      // Upload document
      if (_documentFile != null) {
        await _uploadFile(
          file: _documentFile!,
          fieldName: 'document',
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload thành công!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _uploadFile({
    required CyberFileResult file,
    required String fieldName,
  }) async {
    // Example với http package
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.example.com/upload'),
    );

    request.files.add(
      await http.MultipartFile.fromPath(
        fieldName,
        file.file.path,
        filename: file.fileName,
      ),
    );

    var response = await request.send();

    if (response.statusCode != 200) {
      throw Exception('Upload failed');
    }
  }
}
```

---

## 6. Advanced - Multiple Files

```dart
class MultipleFilePickerExample extends StatefulWidget {
  @override
  State<MultipleFilePickerExample> createState() => _MultipleFilePickerExampleState();
}

class _MultipleFilePickerExampleState extends State<MultipleFilePickerExample> {
  List<CyberFileResult> _files = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Add file button
        CyberFilePicker(
          label: "Thêm file",
          icon: Icons.add,
          onFileSelected: (result) {
            setState(() {
              _files.add(result);
            });
          },
        ),

        SizedBox(height: 16),

        // File list
        ListView.builder(
          shrinkWrap: true,
          itemCount: _files.length,
          itemBuilder: (context, index) {
            final file = _files[index];
            return ListTile(
              leading: file.fileType == CyberFileType.image
                  ? Image.file(file.file, width: 50, height: 50, fit: BoxFit.cover)
                  : Icon(Icons.insert_drive_file),
              title: Text(file.fileName),
              subtitle: Text(_formatFileSize(file.fileSize)),
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    _files.removeAt(index);
                  });
                },
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
```

---

## 7. Integration with CyberForm

```dart
class ProfileForm extends CyberContentViewForm {
  CyberFileResult? _avatarFile;

  @override
  Widget buildBody(BuildContext context) {
    return Column(
      children: [
        CyberFilePickerField(
          label: "Ảnh đại diện",
          hint: "Chọn ảnh đại diện",
          enableCompression: true,
          compressionQuality: 90,
          maxWidth: 800,
          maxHeight: 800,
          onFileSelected: (result) {
            _avatarFile = result;
          },
        ),

        SizedBox(height: 16),

        CyberButton(
          label: "Lưu",
          onClick: () async {
            if (_avatarFile != null) {
              await _uploadAvatar(_avatarFile!);
            }
          },
        ),
      ],
    );
  }

  Future<void> _uploadAvatar(CyberFileResult file) async {
    showLoading("Đang upload...");

    try {
      // Convert to base64
      final base64 = await file.getBase64();

      // Call API
      final response = await context.callApi(
        functionName: "UpdateAvatar",
        parameter: "userid#$base64#${file.fileName}",
      );

      hideLoading();

      if (response.isValid()) {
        await context.showSuccess("Upload thành công!");
      } else {
        await context.showErrorMsg(response.message);
      }
    } catch (e) {
      hideLoading();
      await context.showErrorMsg("Lỗi: $e");
    }
  }
}
```

---

## 8. Tips & Best Practices

### 1. Compression Settings
```dart
// ✅ GOOD: Avatar/Profile (chất lượng cao, file nhỏ)
compressionQuality: 90
maxWidth: 800
maxHeight: 800

// ✅ GOOD: Product images (cân bằng)
compressionQuality: 85
maxWidth: 1920
maxHeight: 1920

// ✅ GOOD: Thumbnail
compressionQuality: 70
maxWidth: 400
maxHeight: 400

// ❌ BAD: Quá lớn
maxWidth: 4000
maxHeight: 4000
```

### 2. Error Handling
```dart
CyberFilePicker(
  onFileSelected: (result) async {
    // Validate file size
    if (result.fileSize > 10 * 1024 * 1024) {
      await context.showErrorMsg("File không được vượt quá 10MB");
      return;
    }

    // Validate file type
    if (!['jpg', 'png', 'jpeg'].contains(result.extension)) {
      await context.showErrorMsg("Chỉ chấp nhận file JPG/PNG");
      return;
    }

    // Upload
    await _uploadFile(result);
  },
  onError: (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error)),
    );
  },
)
```

### 3. Loading States
```dart
bool _isUploading = false;

Future<void> _uploadFile(CyberFileResult file) async {
  setState(() {
    _isUploading = true;
  });

  try {
    // Upload logic
  } finally {
    setState(() {
      _isUploading = false;
    });
  }
}
```

---

## Features Summary

✅ 3 nguồn chọn file: Camera, Gallery, File Picker
✅ Image compression tự động với FlutterImageCompress
✅ Tùy chỉnh compression quality (0-100)
✅ Tùy chỉnh max width/height
✅ Giới hạn file extension
✅ Preview file đã chọn (CyberFilePickerField)
✅ Callback với CyberFileResult (File, bytes, base64)
✅ Error handling
✅ iOS-style bottom sheet
✅ Support cả ảnh và file documents
