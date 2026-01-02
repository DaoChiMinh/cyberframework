# CyberImage - Internal Controller + Binding Pattern

## 📋 Triết lý thiết kế

### 🎯 Mục tiêu
1. **Đơn giản hóa**: Không bắt buộc phải tạo controller
2. **Linh hoạt**: Vẫn có thể dùng controller khi cần
3. **Tương thích ERP**: Binding tự nhiên với CyberDataRow
4. **Sync tự động**: Dữ liệu luôn đồng bộ 2 chiều

### 🏗️ Kiến trúc

```
┌─────────────────────────────────────────────────────────┐
│                    CyberImage Widget                    │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────┐        ┌──────────────────┐      │
│  │ External         │        │ Internal         │      │
│  │ Controller       │   OR   │ Controller       │      │
│  │ (Optional)       │        │ (Auto-created)   │      │
│  └──────────────────┘        └──────────────────┘      │
│           │                           │                 │
│           └───────────┬───────────────┘                 │
│                       ▼                                 │
│          ┌─────────────────────┐                        │
│          │ Effective Controller│                        │
│          └─────────────────────┘                        │
│                       │                                 │
│          ┌────────────┴────────────┐                    │
│          ▼                         ▼                    │
│  ┌──────────────┐          ┌──────────────┐            │
│  │ text Binding │◄────────►│  UI State    │            │
│  │ (CyberDataRow│          │              │            │
│  └──────────────┘          └──────────────┘            │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## 🔄 Sync Flow Chi tiết

### Flow 1: User tương tác UI

```
User tap Upload → Chọn ảnh → _updateValue(newValue)
                                      ↓
                        ┌─────────────────────────┐
                        │ _isSyncing = true       │
                        └─────────────────────────┘
                                      ↓
                        ┌─────────────────────────┐
                        │ controller.loadUrl()    │
                        │ (không notify vì sync)  │
                        └─────────────────────────┘
                                      ↓
                        ┌─────────────────────────┐
                        │ Update binding:         │
                        │ drEdit["image"] = value │
                        └─────────────────────────┘
                                      ↓
                        ┌─────────────────────────┐
                        │ _isSyncing = false      │
                        └─────────────────────────┘
                                      ↓
                        ┌─────────────────────────┐
                        │ setState() → UI rebuild │
                        └─────────────────────────┘
```

### Flow 2: Code thay đổi binding

```
drEdit["image"] = "new_url"
         ↓
CyberDataRow.notifyListeners()
         ↓
_onBindingChanged()
         ↓
┌─────────────────────────────────┐
│ Check: _isSyncing? → return     │
└─────────────────────────────────┘
         ↓
┌─────────────────────────────────┐
│ Get new value from binding      │
└─────────────────────────────────┘
         ↓
┌─────────────────────────────────┐
│ _isSyncing = true               │
└─────────────────────────────────┘
         ↓
┌─────────────────────────────────┐
│ controller.syncFromBinding()    │
│ (internal update, no notify)    │
└─────────────────────────────────┘
         ↓
┌─────────────────────────────────┐
│ _isSyncing = false              │
└─────────────────────────────────┘
         ↓
┌─────────────────────────────────┐
│ setState() → UI rebuild         │
└─────────────────────────────────┘
```

### Flow 3: Controller method được gọi

```
imageController.loadUrl("https://...")
                ↓
Controller.loadUrl()
                ↓
┌────────────────────────────────────┐
│ Check: _isSyncing?                 │
│ - true: chỉ update _imageUrl       │
│ - false: update + notifyListeners()│
└────────────────────────────────────┘
                ↓
_onControllerChanged()
                ↓
┌────────────────────────────────────┐
│ Check: _isSyncing? → return        │
└────────────────────────────────────┘
                ↓
┌────────────────────────────────────┐
│ Get controller value               │
└────────────────────────────────────┘
                ↓
┌────────────────────────────────────┐
│ _isSyncing = true                  │
└────────────────────────────────────┘
                ↓
┌────────────────────────────────────┐
│ Update binding if exists:          │
│ drEdit["image"] = controller.url   │
└────────────────────────────────────┘
                ↓
┌────────────────────────────────────┐
│ _isSyncing = false                 │
└────────────────────────────────────┘
                ↓
┌────────────────────────────────────┐
│ setState() → UI rebuild            │
└────────────────────────────────────┘
```

## 📝 Cách sử dụng

### 1. Binding đơn giản (Khuyến nghị - 90% trường hợp)

```dart
// Tạo data row
final drEdit = CyberDataRow({
  'avatar_url': '',
  'signature': '',
});

// Sử dụng - KHÔNG CẦN CONTROLLER
CyberImage(
  text: drEdit.bind("avatar_url"),  // ← Binding trực tiếp
  label: "Ảnh đại diện",
  isUpload: true,
  isView: true,
  isDelete: true,
  onChanged: (value) {
    print('Image changed: $value');
  },
)
```

**Ưu điểm:**
- ✅ Đơn giản, ít code
- ✅ Widget tự quản lý controller
- ✅ Sync tự động 2 chiều
- ✅ Không cần dispose controller

### 2. Có Controller (Advanced - 10% trường hợp)

```dart
// Tạo controller khi cần điều khiển programmatically
final imageController = CyberImageController();

// Sử dụng - VẪN CÓ THỂ BINDING
CyberImage(
  controller: imageController,        // ← Controller
  text: drEdit.bind("avatar_url"),    // ← Vẫn binding được
  label: "Ảnh đại diện",
  isUpload: true,
)

// Điều khiển từ code
ElevatedButton(
  onPressed: () {
    imageController.triggerUpload();  // ← Mở dialog upload
  },
  child: Text('Upload'),
)

ElevatedButton(
  onPressed: () {
    imageController.loadUrl('https://example.com/image.jpg');
  },
  child: Text('Load URL'),
)

// ⚠️ QUAN TRỌNG: Phải dispose
@override
void dispose() {
  imageController.dispose();
  super.dispose();
}
```

**Khi nào dùng Controller:**
- ✅ Cần trigger actions từ code (upload, view, delete)
- ✅ Cần load image programmatically
- ✅ Cần enable/disable widget từ code
- ✅ Cần kiểm tra state (hasImage)

### 3. Dynamic Properties Binding

```dart
CyberImage(
  text: drProduct.bind("image_url"),
  label: "Ảnh sản phẩm",
  isUpload: drProduct.bind("can_upload"),   // ← Binding động
  isVisible: drProduct.bind("is_visible"),  // ← Binding động
  isDelete: drProduct.bind("can_delete"),
)

// Thay đổi từ code
drProduct["can_upload"] = false;  // → Upload button tự động ẩn
drProduct["is_visible"] = false;  // → Widget tự động ẩn
```

### 4. Static Value (Không binding)

```dart
CyberImage(
  text: 'https://example.com/image.jpg',  // ← Static URL
  label: "Ảnh tĩnh",
  isView: true,
)
```

## 🔧 Controller Methods

### Public Methods (Dành cho developer)

```dart
// Load image từ URL
controller.loadUrl(String? url)

// Load image từ base64
controller.loadBase64(String base64)

// Xóa image
controller.clear()

// Enable/disable widget
controller.setEnabled(bool value)

// Trigger actions
controller.triggerUpload()  // Mở dialog upload
controller.triggerView()    // Xem ảnh fullscreen
controller.triggerDelete()  // Xóa ảnh

// Check state
bool hasImage = controller.hasImage
bool isEnabled = controller.enabled
String? url = controller.imageUrl
```

### Internal Methods (Dành cho widget)

```dart
// Sync từ binding (không trigger notification loop)
controller.syncFromBinding(String? url)
```

## ⚙️ Internal Logic

### 1. Controller Creation

```dart
@override
void initState() {
  super.initState();
  
  // Tạo internal controller nếu chưa có
  if (widget.controller == null) {
    _internalController = CyberImageController();
  }
  
  // Sync initial value từ binding
  final initialValue = _getValueFromBinding();
  _effectiveController.syncFromBinding(initialValue);
  
  // Listen changes
  _effectiveController.addListener(_onControllerChanged);
}
```

### 2. Effective Controller

```dart
// Luôn trả về controller (external hoặc internal)
CyberImageController get _effectiveController =>
    widget.controller ?? _internalController!;
```

### 3. Sync Mechanism

```dart
void _updateValue(String? newValue) {
  if (_isSyncing) return;  // ← Tránh loop
  
  _isSyncing = true;
  
  // Update controller (không notify vì đang sync)
  _effectiveController.loadUrl(newValue);
  
  // Update binding
  if (_boundRow != null && _boundField != null) {
    _boundRow![_boundField!] = newValue ?? '';
  }
  
  _isSyncing = false;
  setState(() {});
}
```

## 🎨 So sánh với pattern cũ

### ❌ Pattern cũ (Bắt buộc controller)

```dart
// Phải tạo controller
final imageController = CyberImageController();

CyberImage(
  controller: imageController,
  // ❌ KHÔNG THỂ binding trực tiếp
)

// Phải load manual
imageController.loadUrl(drEdit["avatar_url"]);

// Phải listen binding change manual
drEdit.addListener(() {
  imageController.loadUrl(drEdit["avatar_url"]);
});

// Phải dispose
@override
void dispose() {
  imageController.dispose();
  drEdit.removeListener(...);
  super.dispose();
}
```

### ✅ Pattern mới (Internal Controller + Binding)

```dart
// Không cần tạo controller
CyberImage(
  text: drEdit.bind("avatar_url"),  // ← Tất cả tự động
  label: "Ảnh đại diện",
  isUpload: true,
)

// Sync tự động 2 chiều
// Không cần dispose controller
```

## 🚀 Best Practices

### ✅ DO

```dart
// 1. Dùng binding đơn giản khi có thể
CyberImage(
  text: drEdit.bind("avatar_url"),
  label: "Ảnh đại diện",
)

// 2. Dùng controller chỉ khi thực sự cần
final imageCtrl = CyberImageController();
CyberImage(
  controller: imageCtrl,
  text: drEdit.bind("avatar_url"),
)
imageCtrl.triggerUpload();

// 3. Binding dynamic properties
CyberImage(
  text: drEdit.bind("avatar"),
  isUpload: drEdit.bind("can_upload"),
  isVisible: drEdit.bind("is_visible"),
)
```

### ❌ DON'T

```dart
// ❌ Tạo controller không cần thiết
final ctrl = CyberImageController();
CyberImage(
  controller: ctrl,  // ← Không cần
  text: "static_url",
)

// ❌ Manual sync (widget đã tự động)
drEdit.addListener(() {
  ctrl.loadUrl(drEdit["avatar"]);
});

// ❌ Quên dispose controller
final ctrl = CyberImageController();
// ... không dispose trong dispose()
```

## 🔍 Debugging

### Log sync flow

```dart
void _onBindingChanged() {
  print('🔄 Binding changed');
  print('   Current: ${_effectiveController.imageUrl}');
  print('   New: ${_getValueFromBinding()}');
  // ... sync logic
}

void _onControllerChanged() {
  print('🎮 Controller changed');
  print('   URL: ${_effectiveController.imageUrl}');
  print('   Enabled: ${_effectiveController.enabled}');
  // ... sync logic
}

void _updateValue(String? newValue) {
  print('✏️ Update value: $newValue');
  // ... update logic
}
```

## 📊 Performance Notes

1. **Listener Management**: Widget tự động add/remove listeners
2. **Cache**: Visibility và Fit được cache để tránh re-parse
3. **Sync Flag**: `_isSyncing` tránh notification loop
4. **Memory**: Internal controller tự động dispose khi widget dispose

## 🎯 Kết luận

Pattern **Internal Controller + Binding** mang lại:

✅ **Đơn giản**: 90% trường hợp không cần controller  
✅ **Linh hoạt**: 10% trường hợp cần controller vẫn OK  
✅ **Tự động**: Sync 2 chiều tự động  
✅ **Sạch sẽ**: Không cần dispose controller thủ công  
✅ **Tương thích ERP**: Binding tự nhiên như các control khác  

Đây là pattern chuẩn cho tất cả CyberFramework controls!
