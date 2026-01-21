# Upload Object - Smart Auto-Detection

## 🎯 Tổng Quan

**Upload Object** là tính năng thông minh nhất của CyberFramework Upload API. Nó có thể **tự động nhận dạng** và xử lý nhiều loại input khác nhau mà không cần bạn phải chỉ định loại.

### 🚀 Tính Năng Chính

- ✅ **Auto-detection**: Tự động nhận dạng loại input
- ✅ **Multi-source**: Hỗ trợ 6+ loại nguồn khác nhau
- ✅ **Smart conversion**: Tự động convert sang base64
- ✅ **Flexible**: Mix nhiều loại trong 1 lần upload
- ✅ **Simple API**: Chỉ cần truyền object vào

## 📦 Các Loại Object Được Hỗ Trợ

| Loại | Ví Dụ | Auto-Detect |
|------|-------|-------------|
| **File Path** | `"/storage/photo.jpg"` | ✅ |
| **URL** | `"https://example.com/image.jpg"` | ✅ |
| **Base64** | `"iVBORw0KGgoAAAANSUhEUgAA..."` | ✅ |
| **File Object** | `File('/path/to/file.pdf')` | ✅ |
| **Bytes Array** | `Uint8List.fromList([...])` | ✅ |
| **XFile** | `XFile từ image_picker` | ✅ |

## 🔧 Cài Đặt

### 1. Thêm File Models

Copy `uploadobject.dart` vào `lib/Module/CallData/`

### 2. Thêm Methods vào CyberApiService

Thêm nội dung từ `cyberapiservice_uploadobject_methods.dart` vào `cyberapiservice.dart`

### 3. Thêm Extension Methods

Thêm nội dung từ `cyberapiuploadobject_extension.dart` vào `cyberapiextension.dart`

### 4. Export Classes

```dart
export 'Module/CallData/uploadobject.dart';
```

## 📱 Cách Sử Dụng

### Ví Dụ 1: Upload từ File Path

```dart
// File path string
const filePath = '/storage/photo.jpg';

await context.uploadSingleObject(
  object: filePath,  // Framework tự nhận dạng đây là file path
  filePath: '/photos/vacation.jpg',
);
```

### Ví Dụ 2: Upload từ URL

```dart
// URL string
const imageUrl = 'https://example.com/image.jpg';

await context.uploadSingleObject(
  object: imageUrl,  // Framework tự download và upload
  filePath: '/downloads/image.jpg',
);
```

### Ví Dụ 3: Upload từ Base64

```dart
// Base64 string
const base64 = 'iVBORw0KGgoAAAANSUhEUgAA...';

await context.uploadSingleObject(
  object: base64,  // Framework tự nhận dạng base64
  filePath: '/encoded/image.png',
);
```

### Ví Dụ 4: Upload từ File Object

```dart
// File object
final file = File('/path/to/document.pdf');

await context.uploadSingleObject(
  object: file,  // Framework tự đọc file
  filePath: '/documents/report.pdf',
);
```

### Ví Dụ 5: Upload từ Bytes

```dart
// Bytes array
final bytes = Uint8List.fromList([0, 1, 2, 3]);

await context.uploadSingleObject(
  object: bytes,  // Framework tự convert
  filePath: '/bytes/data.bin',
);
```

### Ví Dụ 6: Upload từ XFile

```dart
// XFile từ image_picker
final ImagePicker picker = ImagePicker();
final XFile? image = await picker.pickImage(source: ImageSource.gallery);

await context.uploadSingleObject(
  object: image,  // Truyền XFile trực tiếp!
  filePath: '/gallery/${image.name}',
);
```

## 🎨 Advanced Usage

### Mix Nhiều Loại

```dart
final ImagePicker picker = ImagePicker();
final XFile? xfile = await picker.pickImage(source: ImageSource.gallery);

// Mix tất cả các loại!
final objects = [
  '/storage/photo.jpg',                    // File path
  'https://example.com/image.jpg',         // URL
  'iVBORw0KGgoAAAANSUhEUg...',           // Base64
  File('/path/document.pdf'),              // File object
  Uint8List.fromList([1, 2, 3]),          // Bytes
  xfile,                                   // XFile
];

await context.uploadObjects(
  objects: objects,
  filePaths: [
    '/photos/1.jpg',
    '/downloads/2.jpg',
    '/encoded/3.png',
    '/docs/4.pdf',
    '/bytes/5.bin',
    '/gallery/${xfile?.name}',
  ],
);
```

### Upload và Parse Kết Quả

```dart
final (file, status) = await context.uploadSingleObjectAndCheck(
  object: anyObject,  // Bất kỳ loại nào
  filePath: '/uploads/file.jpg',
);

if (status && file != null) {
  print('URL: ${file.url}');
  print('ID: ${file.id}');
  print('Name: ${file.name}');
}
```

### Upload Nhiều và Lấy URLs

```dart
final (files, status) = await context.uploadObjectsAndCheck(
  objects: [object1, object2, object3],
);

if (status && files != null) {
  for (var file in files) {
    print('${file.name}: ${file.url}');
  }
  
  final urls = files.map((f) => f.url).toList();
}
```

### Auto Path Generation

```dart
// Không cần chỉ định filePath!
await context.uploadSingleObject(
  object: xfile,
  // Framework tự động:
  // - Lấy tên file từ XFile
  // - Detect extension
  // - Generate subfolder (GUID)
);
```

## 🔍 Auto-Detection Logic

Framework sử dụng các rule sau để detect loại object:

### 1. XFile Detection

```dart
if (object.runtimeType.toString().contains('XFile'))
  → UploadSourceType.xfile
```

### 2. File Object Detection

```dart
if (object is File)
  → UploadSourceType.fileObject
```

### 3. Bytes Detection

```dart
if (object is List<int> || object is Uint8List)
  → UploadSourceType.bytes
```

### 4. String Detection

```dart
if (object is String) {
  if (startsWith('http://') || startsWith('https://'))
    → UploadSourceType.url
  
  else if (length > 100 && no path separators)
    → Try base64 decode
    → UploadSourceType.base64 if valid
  
  else if (contains '/' or '\' or '.')
    → UploadSourceType.filePath
  
  else
    → UploadSourceType.base64
}
```

## 🎯 API Reference

### uploadObjects()

```dart
Future<ReturnData> uploadObjects({
  required List<dynamic> objects,
  List<String?>? filePaths,
  bool showLoading = true,
  bool showError = true,
})
```

Upload nhiều objects với auto-detection.

### uploadSingleObject()

```dart
Future<ReturnData> uploadSingleObject({
  required dynamic object,
  String? filePath,
  bool showLoading = true,
  bool showError = true,
})
```

Upload 1 object với auto-detection.

### uploadObjectsAndCheck()

```dart
Future<(List<CyberAPIFileReturn>?, bool)> uploadObjectsAndCheck({
  required List<dynamic> objects,
  List<String?>? filePaths,
  bool showLoading = true,
  bool showError = true,
})
```

Upload nhiều objects và parse kết quả.

### uploadSingleObjectAndCheck()

```dart
Future<(CyberAPIFileReturn?, bool)> uploadSingleObjectAndCheck({
  required dynamic object,
  String? filePath,
  bool showLoading = true,
  bool showError = true,
})
```

Upload 1 object và parse kết quả.

## 🏗️ UploadObject Class

### Constructors

```dart
// Specific constructors
UploadObject.fromPath(String path, {String? filePath})
UploadObject.fromUrl(String url, {String? filePath})
UploadObject.fromBase64(String base64, {String? filePath})
UploadObject.fromFile(File file, {String? filePath})
UploadObject.fromBytes(dynamic bytes, {String? filePath})
UploadObject.fromXFile(dynamic xfile, {String? filePath})

// Auto-detect constructor
UploadObject.auto(dynamic source, {String? filePath})
```

### Methods

```dart
// Convert to base64
Future<String> toBase64()

// Get or generate file path
Future<String> getFilePath()
```

### Properties

```dart
// Source data
final dynamic source

// Source type
final UploadSourceType sourceType

// Custom file path (optional)
final String? filePath

// Source type name
String get sourceTypeName
```

## 📝 Xử Lý Lỗi

```dart
try {
  final result = await context.uploadSingleObject(
    object: anyObject,
    filePath: '/uploads/file.jpg',
  );
  
  if (result.isValid()) {
    print('✅ Upload thành công!');
  } else {
    print('❌ Upload thất bại: ${result.message}');
  }
} catch (e) {
  print('❌ Error: $e');
}
```

### Common Errors

| Error | Nguyên Nhân | Giải Pháp |
|-------|-------------|-----------|
| File không tồn tại | File path sai | Kiểm tra path |
| Không thể download | URL không hợp lệ | Kiểm tra URL |
| Base64 decode lỗi | String không phải base64 | Kiểm tra format |
| Permission denied | Không có quyền đọc file | Cấp quyền |

## 🔒 Bảo Mật

- ✅ **URL Download**: Timeout 30s, tự động retry
- ✅ **File Access**: Check file exists trước khi đọc
- ✅ **Base64 Validation**: Validate trước khi decode
- ✅ **Token**: Tự động từ UserInfo.strTokenId
- ✅ **Encryption**: V_MaHoa() cho token

## ⚡ Performance

### Caching

```dart
// Base64 được cache sau lần convert đầu tiên
final obj = UploadObject.auto(source);
final base64_1 = await obj.toBase64();  // Convert
final base64_2 = await obj.toBase64();  // Return cached
```

### Memory Management

- File được đọc streaming (không load toàn bộ vào RAM)
- Auto cleanup sau khi upload
- Không store unnecessary data

## 🎓 Best Practices

### 1. Validate Trước Khi Upload

```dart
// Check file size
if (file.lengthSync() > 5 * 1024 * 1024) {
  print('File quá lớn!');
  return;
}

// Check file type
if (!file.path.endsWith('.jpg')) {
  print('Chỉ chấp nhận JPG!');
  return;
}
```

### 2. Sử dụng Custom FilePath

```dart
// ✅ Good - Structured path
final userId = UserInfo.user_name;
final timestamp = DateTime.now().millisecondsSinceEpoch;
filePath: '/users/$userId/photos/$timestamp.jpg'

// ❌ Bad - Random path
filePath: 'random_file.jpg'
```

### 3. Handle Errors Properly

```dart
final (file, status) = await context.uploadSingleObjectAndCheck(
  object: source,
  showError: false,  // Custom error handling
);

if (!status) {
  // Show custom error UI
  showCustomErrorDialog(context);
}
```

### 4. Use AndCheck Methods

```dart
// ✅ Good - Auto parse
final (file, status) = await context.uploadSingleObjectAndCheck(...);

// ❌ Bad - Manual parse
final result = await context.uploadSingleObject(...);
final file = CyberAPIFileReturn.fromJson(result.data);
```

## 🆚 So Sánh với Upload Files

| Feature | uploadFiles | uploadObjects |
|---------|-------------|---------------|
| Input | base64 + file paths | Any objects |
| Auto-detect | ❌ | ✅ |
| URL download | ❌ | ✅ |
| Mix types | ❌ | ✅ |
| Simplicity | 🟡 Medium | 🟢 Easy |

### Khi Nào Dùng uploadObjects?

✅ Có nhiều loại nguồn khác nhau  
✅ Muốn upload từ URL  
✅ Không muốn manually convert  
✅ Code đơn giản, dễ đọc  

### Khi Nào Dùng uploadFiles?

✅ Đã có sẵn base64  
✅ Performance critical  
✅ Full control cần thiết  

## 📊 Use Cases

### Case 1: User Profile

```dart
// Avatar từ gallery
final avatar = await picker.pickImage(source: ImageSource.gallery);

// Cover từ URL
const coverUrl = 'https://example.com/default-cover.jpg';

await context.uploadObjects(
  objects: [avatar, coverUrl],
  filePaths: ['/avatars/user.jpg', '/covers/user.jpg'],
);
```

### Case 2: Document Upload

```dart
// Multiple documents from different sources
final objects = [
  File('/storage/passport.pdf'),      // File object
  '/storage/license.jpg',              // File path
  base64Resume,                        // Base64
];

await context.uploadObjects(objects: objects);
```

### Case 3: Batch Image Upload

```dart
final images = await picker.pickMultiImage();

// Upload tất cả XFiles trực tiếp!
final (files, status) = await context.uploadObjectsAndCheck(
  objects: images,
);
```

---

**Version**: 2.0.0  
**Last Updated**: 2026-01-21  
**Author**: CyberFramework Team
