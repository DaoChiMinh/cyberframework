# CyberImage - Image Widget với Data Binding

## Mục Lục
1. [Giới Thiệu](#giới-thiệu)
2. [CyberImage Widget](#cyberimage-widget)
3. [CyberImageController](#cyberimagecontroller)
4. [Ví Dụ Sử Dụng](#ví-dụ-sử-dụng)
5. [Features](#features)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

---

## Giới Thiệu

`CyberImage` là image widget với **Internal Controller** và **Data Binding** hai chiều. Widget hỗ trợ nhiều image sources (URL, Base64, Asset, File) và cung cấp Upload/View/Delete actions.

### Đặc Điểm Chính

- ✅ **Internal Controller**: Tự động quản lý state
- ✅ **Two-Way Binding**: Tự động sync với CyberDataRow
- ✅ **Multi-Source**: URL, Base64, Asset, Local File
- ✅ **Actions**: Upload (Camera/Gallery), View, Delete
- ✅ **Auto Compression**: Tự động compress ảnh khi upload
- ✅ **Fullscreen Viewer**: Xem ảnh toàn màn hình
- ✅ **Cache Manager**: Cache Base64 images
- ✅ **Flexible Fit**: Hỗ trợ nhiều BoxFit modes

### Dependencies

```yaml
dependencies:
  cached_network_image: ^3.0.0
  image_picker: ^1.0.0
```

### Import

```dart
import 'package:cyberframework/cyberframework.dart';
```

---

## CyberImage Widget

### Constructor

```dart
const CyberImage({
  super.key,
  this.controller,
  this.text,
  this.label,
  this.isUpload = false,
  this.isView = true,
  this.isDelete = false,
  this.width,
  this.height = 200,
  this.fit = "cover",
  this.borderRadius = 12.0,
  this.placeholder,
  this.errorWidget,
  this.labelStyle,
  this.isShowLabel = true,
  this.onChanged,
  this.onLeaver,
  this.onUploadRequested,
  this.onViewRequested,
  this.onDeleteRequested,
  this.backgroundColor,
  this.borderColor,
  this.borderWidth = 2.0,
  this.enabled = true,
  this.isVisible = true,
  this.enableCompression = true,
  this.compressionQuality = 85,
  this.maxWidth = 1920,
  this.maxHeight = 1920,
  this.uploadIcon,
  this.viewIcon,
  this.deleteIcon,
  this.isCircle = false,
})
```

### Properties

#### Data Binding

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `text` | `dynamic` | Image URL/Base64 (có thể binding) | null |
| `controller` | `CyberImageController?` | External controller (optional) | null |

#### Display

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `label` | `String?` | Label hiển thị phía trên | null |
| `width` | `double?` | Chiều rộng | double.infinity |
| `height` | `double?` | Chiều cao | 200 |
| `fit` | `dynamic` | BoxFit mode (có thể binding) | "cover" |
| `borderRadius` | `double` | Bo góc | 12.0 |
| `isCircle` | `bool` | Hình tròn | false |
| `placeholder` | `Widget?` | Custom placeholder | null |
| `errorWidget` | `Widget?` | Custom error widget | null |
| `labelStyle` | `TextStyle?` | Style cho label | null |
| `isShowLabel` | `bool` | Hiển thị label | true |

#### Actions

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `isUpload` | `dynamic` | Cho phép upload (có thể binding) | false |
| `isView` | `dynamic` | Cho phép xem (có thể binding) | true |
| `isDelete` | `dynamic` | Cho phép xóa (có thể binding) | false |
| `uploadIcon` | `IconData?` | Custom upload icon | null |
| `viewIcon` | `IconData?` | Custom view icon | null |
| `deleteIcon` | `IconData?` | Custom delete icon | null |

#### Compression

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `enableCompression` | `bool` | Bật compression | true |
| `compressionQuality` | `int` | Chất lượng (0-100) | 85 |
| `maxWidth` | `int?` | Chiều rộng tối đa | 1920 |
| `maxHeight` | `int?` | Chiều cao tối đa | 1920 |

#### Callbacks

| Property | Type | Mô Tả |
|----------|------|-------|
| `onChanged` | `ValueChanged<String>?` | Khi image URL thay đổi |
| `onLeaver` | `Function(dynamic)?` | Khi rời khỏi widget |
| `onUploadRequested` | `VoidCallback?` | Khi bắt đầu upload |
| `onViewRequested` | `VoidCallback?` | Khi xem ảnh |
| `onDeleteRequested` | `VoidCallback?` | Khi xóa ảnh |

#### Styling

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `backgroundColor` | `Color?` | Màu nền | Colors.grey[100] |
| `borderColor` | `Color?` | Màu border | null |
| `borderWidth` | `double` | Độ dày border | 2.0 |
| `enabled` | `bool` | Enable/disable | true |
| `isVisible` | `dynamic` | Hiển thị/ẩn (có thể binding) | true |

### BoxFit Modes

Hỗ trợ String hoặc BoxFit enum:

```dart
"fill"       → BoxFit.fill
"contain"    → BoxFit.contain
"cover"      → BoxFit.cover (default)
"fitwidth"   → BoxFit.fitWidth
"fitheight"  → BoxFit.fitHeight
"center"     → BoxFit.none
"scaledown"  → BoxFit.scaleDown
```

---

## CyberImageController

**NOTE**: Controller là **OPTIONAL**. Widget tự tạo internal controller.

### Properties & Methods

```dart
final controller = CyberImageController();

// Properties
String? imageUrl = controller.imageUrl;
bool enabled = controller.enabled;
bool hasImage = controller.hasImage;

// Load image
controller.loadUrl('https://...');
controller.loadBase64('data:image/jpeg;base64,...');
controller.clear();

// State
controller.setEnabled(true);

// Actions (trigger từ code)
controller.triggerUpload();
controller.triggerView();
controller.triggerDelete();

// Internal sync (framework use)
controller.syncFromBinding(url);
```

---

## Ví Dụ Sử Dụng

### 1. Sử Dụng Cơ Bản (Recommended)

Simple binding với upload action.

```dart
class ProfileForm extends StatefulWidget {
  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final drUser = CyberDataRow();

  @override
  void initState() {
    super.initState();
    drUser['avatar'] = ''; // Empty initially
  }

  @override
  Widget build(BuildContext context) {
    return CyberImage(
      text: drUser.bind('avatar'),
      label: 'Ảnh đại diện',
      isUpload: true,
      isView: true,
      isDelete: true,
      height: 200,
      onChanged: (url) {
        print('Avatar changed: ${url.length} chars');
      },
    );
  }
}
```

### 2. Network Image

Hiển thị ảnh từ URL.

```dart
class ProductImage extends StatelessWidget {
  final drProduct = CyberDataRow();

  ProductImage() {
    drProduct['image_url'] = 'https://example.com/product.jpg';
  }

  @override
  Widget build(BuildContext context) {
    return CyberImage(
      text: drProduct.bind('image_url'),
      label: 'Ảnh sản phẩm',
      isView: true, // Chỉ xem, không upload/delete
      fit: 'contain',
    );
  }
}
```

### 3. Base64 Image

Upload và lưu dưới dạng Base64.

```dart
class Base64ImageForm extends StatefulWidget {
  @override
  State<Base64ImageForm> createState() => _Base64ImageFormState();
}

class _Base64ImageFormState extends State<Base64ImageForm> {
  final drEmployee = CyberDataRow();

  @override
  void initState() {
    super.initState();
    drEmployee['photo_base64'] = '';
  }

  Future<void> saveEmployee() async {
    final base64 = drEmployee['photo_base64'].toString();
    
    if (base64.isEmpty) {
      showError('Vui lòng chọn ảnh');
      return;
    }

    await api.createEmployee({
      'name': drEmployee['name'],
      'photo': base64,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberImage(
          text: drEmployee.bind('photo_base64'),
          label: 'Ảnh nhân viên',
          isUpload: true,
          isDelete: true,
          enableCompression: true,
          compressionQuality: 85,
        ),
        
        SizedBox(height: 16),
        
        CyberButton(
          label: 'Lưu',
          onClick: saveEmployee,
        ),
      ],
    );
  }
}
```

### 4. Custom Compression

Tùy chỉnh compression settings.

```dart
// Thumbnail - Low quality
CyberImage(
  text: drProduct.bind('thumbnail'),
  isUpload: true,
  enableCompression: true,
  compressionQuality: 60,
  maxWidth: 512,
  maxHeight: 512,
)

// High quality - Documents
CyberImage(
  text: drDoc.bind('scan'),
  isUpload: true,
  enableCompression: true,
  compressionQuality: 95,
  maxWidth: 2560,
  maxHeight: 2560,
)
```

### 5. Circle Avatar

Ảnh đại diện hình tròn.

```dart
CyberImage(
  text: drUser.bind('avatar'),
  label: 'Avatar',
  isCircle: true,
  width: 120,
  height: 120,
  isUpload: true,
  isDelete: true,
)
```

### 6. Different Fit Modes

Các chế độ fit khác nhau.

```dart
Column(
  children: [
    // Cover - Phủ toàn bộ (default)
    CyberImage(
      text: drProduct.bind('image'),
      fit: 'cover',
      height: 200,
    ),
    
    // Contain - Fit trong khung
    CyberImage(
      text: drProduct.bind('image'),
      fit: 'contain',
      height: 200,
    ),
    
    // Fill - Kéo giãn
    CyberImage(
      text: drProduct.bind('image'),
      fit: 'fill',
      height: 200,
    ),
  ],
)
```

### 7. Với Controller (Advanced)

Programmatic control.

```dart
class AdvancedImageForm extends StatefulWidget {
  @override
  State<AdvancedImageForm> createState() => _AdvancedImageFormState();
}

class _AdvancedImageFormState extends State<AdvancedImageForm> {
  final imageController = CyberImageController();
  final drProduct = CyberDataRow();

  @override
  void dispose() {
    imageController.dispose();
    super.dispose();
  }

  void loadSampleImage() {
    imageController.loadUrl('https://example.com/sample.jpg');
  }

  void clearImage() {
    imageController.clear();
  }

  void openCamera() {
    imageController.triggerUpload(); // Mở upload dialog
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberImage(
          controller: imageController,
          text: drProduct.bind('image_url'),
          label: 'Ảnh sản phẩm',
          isUpload: true,
        ),
        
        SizedBox(height: 16),
        
        Wrap(
          spacing: 8,
          children: [
            ElevatedButton(
              onPressed: loadSampleImage,
              child: Text('Load Sample'),
            ),
            ElevatedButton(
              onPressed: openCamera,
              child: Text('Open Camera'),
            ),
            ElevatedButton(
              onPressed: clearImage,
              child: Text('Clear'),
            ),
          ],
        ),
      ],
    );
  }
}
```

### 8. Conditional Actions

Actions dựa trên permissions.

```dart
class ConditionalImage extends StatefulWidget {
  @override
  State<ConditionalImage> createState() => _ConditionalImageState();
}

class _ConditionalImageState extends State<ConditionalImage> {
  final drProduct = CyberDataRow();
  final drPermissions = CyberDataRow();

  @override
  void initState() {
    super.initState();
    
    drProduct['image'] = '';
    
    // Permissions
    drPermissions['can_upload'] = true;
    drPermissions['can_delete'] = false; // No delete permission
  }

  @override
  Widget build(BuildContext context) {
    return CyberImage(
      text: drProduct.bind('image'),
      label: 'Ảnh sản phẩm',
      
      // Bind permissions
      isUpload: drPermissions.bind('can_upload'),
      isDelete: drPermissions.bind('can_delete'),
      isView: true, // Always allow view
    );
  }
}
```

### 9. Custom Placeholder & Error

Tùy chỉnh placeholder và error widget.

```dart
CyberImage(
  text: drProduct.bind('image'),
  placeholder: Container(
    color: Colors.grey[200],
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 64, color: Colors.blue),
        SizedBox(height: 8),
        Text('Thêm ảnh sản phẩm'),
      ],
    ),
  ),
  errorWidget: Container(
    color: Colors.red[50],
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error, size: 64, color: Colors.red),
        SizedBox(height: 8),
        Text('Lỗi tải ảnh', style: TextStyle(color: Colors.red)),
      ],
    ),
  ),
)
```

### 10. Multiple Images

Form với nhiều ảnh.

```dart
class ProductGallery extends StatefulWidget {
  @override
  State<ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<ProductGallery> {
  final drProduct = CyberDataRow();

  @override
  void initState() {
    super.initState();
    
    drProduct['main_image'] = '';
    drProduct['image_1'] = '';
    drProduct['image_2'] = '';
    drProduct['image_3'] = '';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Main image - larger
        CyberImage(
          text: drProduct.bind('main_image'),
          label: 'Ảnh chính',
          height: 300,
          isUpload: true,
          isDelete: true,
        ),
        
        SizedBox(height: 16),
        
        Text('Ảnh phụ'),
        SizedBox(height: 8),
        
        // Sub images - smaller, in row
        Row(
          children: [
            Expanded(
              child: CyberImage(
                text: drProduct.bind('image_1'),
                height: 100,
                isUpload: true,
                isDelete: true,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: CyberImage(
                text: drProduct.bind('image_2'),
                height: 100,
                isUpload: true,
                isDelete: true,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: CyberImage(
                text: drProduct.bind('image_3'),
                height: 100,
                isUpload: true,
                isDelete: true,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
```

### 11. Asset Images

Hiển thị ảnh từ assets.

```dart
class AssetImageDemo extends StatelessWidget {
  final drDemo = CyberDataRow();

  AssetImageDemo() {
    drDemo['logo'] = 'assets/images/logo.png';
  }

  @override
  Widget build(BuildContext context) {
    return CyberImage(
      text: drDemo.bind('logo'),
      label: 'Logo',
      height: 150,
      fit: 'contain',
      isView: true,
    );
  }
}
```

### 12. Callbacks

Xử lý các callbacks.

```dart
CyberImage(
  text: drProduct.bind('image'),
  label: 'Ảnh sản phẩm',
  isUpload: true,
  
  onUploadRequested: () {
    print('User requested upload');
  },
  
  onChanged: (url) {
    print('Image changed: ${url.length} chars');
    // Auto-save to backend
    saveImage(url);
  },
  
  onViewRequested: () {
    print('User viewing image');
  },
  
  onDeleteRequested: () {
    print('User deleting image');
    // Confirm with user
  },
)
```

---

## Features

### 1. Internal Controller

Widget tự động quản lý state.

```dart
// ✅ GOOD: Simple binding
CyberImage(
  text: drUser.bind('avatar'),
  isUpload: true,
)
```

### 2. Multi-Source Support

Hỗ trợ nhiều loại image source:

```dart
// Network URL
'https://example.com/image.jpg'

// Base64
'data:image/jpeg;base64,/9j/4AAQSkZJRg...'

// Asset
'assets/images/logo.png'

// Local file
'/data/user/0/.../image.jpg'
```

### 3. Actions System

Bottom sheet với các actions:

- 📷 **Camera**: Chụp ảnh mới
- 🖼️ **Gallery**: Chọn từ thư viện
- 👁️ **View**: Xem toàn màn hình
- 🗑️ **Delete**: Xóa ảnh

### 4. Auto Compression

Tự động compress khi upload:

```dart
enableCompression: true
compressionQuality: 85  // 0-100
maxWidth: 1920
maxHeight: 1920
```

### 5. Fullscreen Viewer

Xem ảnh toàn màn hình với:
- Pinch to zoom
- Pan to move
- Double tap to zoom
- Swipe to dismiss

### 6. Cache Manager

Cache Base64 images để tránh decode lại.

### 7. Flexible BoxFit

Nhiều chế độ fit:
- cover, contain, fill
- fitWidth, fitHeight
- none, scaleDown

### 8. Circle Avatar

```dart
isCircle: true
```

### 9. Responsive Placeholder

Placeholder tự động scale theo kích thước.

---

## Best Practices

### 1. Sử Dụng Binding (Recommended)

```dart
// ✅ GOOD
CyberImage(
  text: drUser.bind('avatar'),
  isUpload: true,
)

// ❌ BAD: Manual state
String? imageUrl;
CyberImage(
  text: imageUrl,
  onChanged: (url) {
    setState(() {
      imageUrl = url;
      drUser['avatar'] = url;
    });
  },
)
```

### 2. Compression Settings

```dart
// ✅ GOOD: Appropriate compression
CyberImage(
  enableCompression: true,
  compressionQuality: 85,
  maxWidth: 1920,
  maxHeight: 1920,
)

// ❌ BAD: Too aggressive
CyberImage(
  compressionQuality: 10,  // Too low!
)

// ❌ BAD: No compression
CyberImage(
  enableCompression: false,  // Large files!
)
```

### 3. Actions Configuration

```dart
// ✅ GOOD: Clear permissions
CyberImage(
  isUpload: true,  // Allow upload
  isView: true,    // Allow view
  isDelete: false, // No delete
)

// ✅ GOOD: Conditional
CyberImage(
  isUpload: drPermissions.bind('can_edit'),
  isDelete: drPermissions.bind('can_delete'),
)
```

### 4. Sizing

```dart
// ✅ GOOD: Fixed height
CyberImage(
  height: 200,
  width: double.infinity,
)

// ✅ GOOD: Square
CyberImage(
  width: 200,
  height: 200,
)

// ✅ GOOD: Circle avatar
CyberImage(
  isCircle: true,
  width: 120,
  height: 120,
)
```

### 5. Error Handling

```dart
// ✅ GOOD: Custom error widget
CyberImage(
  errorWidget: Container(
    child: Text('Lỗi tải ảnh'),
  ),
)

// ✅ GOOD: Fallback
CyberImage(
  text: drUser.bind('avatar'),
  placeholder: Image.asset('assets/default_avatar.png'),
)
```

---

## Troubleshooting

### Image không hiển thị

**Nguyên nhân:**
1. URL/Base64 không hợp lệ
2. Network issue
3. Permissions

**Giải pháp:**
```dart
// Check value
print('Image URL: ${drUser['avatar']}');

// Add error widget
CyberImage(
  errorWidget: Text('Error loading image'),
)
```

### Upload không hoạt động

**Nguyên nhân:** Permissions chưa được cấp

**Giải pháp:**
```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>

<!-- Info.plist -->
<key>NSCameraUsageDescription</key>
<string>Need camera for photos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Need library for photos</string>
```

### Base64 quá dài

**Nguyên nhân:** Không compress

**Giải pháp:**
```dart
CyberImage(
  enableCompression: true,
  compressionQuality: 70,
  maxWidth: 1024,
  maxHeight: 1024,
)
```

### Memory issues

**Nguyên nhân:** Ảnh gốc quá lớn

**Giải pháp:**
```dart
// Set cache dimensions
CyberImage(
  maxWidth: 1920,
  maxHeight: 1920,
)
```

### Actions không hiển thị

**Nguyên nhân:** Tất cả actions đều false

**Giải pháp:**
```dart
// Enable at least one action
CyberImage(
  isView: true,  // At minimum
)
```

---

## Tips & Tricks

### 1. Lazy Loading

```dart
String? imageUrl;

@override
void initState() {
  super.initState();
  loadImageUrl();
}

Future<void> loadImageUrl() async {
  final url = await api.getUserAvatar();
  drUser['avatar'] = url;
}
```

### 2. Validation

```dart
bool isValidImage(String? url) {
  if (url == null || url.isEmpty) return false;
  
  // Check Base64
  if (url.startsWith('data:image/')) return true;
  
  // Check URL
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return true;
  }
  
  return false;
}
```

### 3. Compress Before Save

```dart
onChanged: (url) async {
  // Save compressed version
  await saveToDatabase({
    'avatar': url,
    'avatar_size': url.length,
  });
}
```

### 4. Loading Indicator

```dart
class ImageWithLoader extends StatefulWidget {
  @override
  State<ImageWithLoader> createState() => _ImageWithLoaderState();
}

class _ImageWithLoaderState extends State<ImageWithLoader> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CyberImage(
          text: drProduct.bind('image'),
          isUpload: true,
          onUploadRequested: () {
            setState(() => isLoading = true);
          },
          onChanged: (url) {
            setState(() => isLoading = false);
          },
        ),
        
        if (isLoading)
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

### 5. Preview Before Upload

```dart
Future<void> confirmUpload(String base64) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Xác nhận'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.memory(
            base64Decode(base64.split(',')[1]),
            height: 200,
          ),
          SizedBox(height: 8),
          Text('Sử dụng ảnh này?'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Hủy'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('OK'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    drUser['avatar'] = base64;
  }
}
```

---

## Performance Tips

1. **Enable Compression**: Always compress uploaded images
2. **Set Max Dimensions**: Limit maxWidth/maxHeight
3. **Cache Base64**: Use built-in cache manager
4. **Network Images**: Use CachedNetworkImage (built-in)
5. **Dispose Controller**: Prevent memory leaks

---

## Image Sources

### Supported Formats

```dart
// 1. Network URL
'https://example.com/image.jpg'

// 2. Base64 (with header)
'data:image/jpeg;base64,/9j/4AAQSkZJRg...'

// 3. Base64 (without header)
'/9j/4AAQSkZJRg...'

// 4. Asset
'assets/images/logo.png'

// 5. Local file path
'/data/user/0/.../image.jpg'
```

---

## Version History

### 1.0.0
- Initial release
- Internal controller
- Two-way binding
- Multi-source support
- Upload/View/Delete actions
- Auto compression
- Fullscreen viewer
- Cache manager
- Circle avatar
- Flexible BoxFit

---

## License

MIT License - CyberFramework
