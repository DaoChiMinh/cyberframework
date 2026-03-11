# CyberButtonUpload

Widget upload file cho CyberFramework. Sử dụng **CyberLabel** làm giao diện và **showFilePickerActionSheet** để xử lý chọn/upload file.

---

## Tổng quan

```
CyberButtonUpload
├── CyberLabel (label)          ← giao diện: text hoặc icon, hỗ trợ binding
│   └── onLeaver → _handleUpload()
├── showFilePickerActionSheet   ← ActionSheet chọn file
│   └── autoUpload → server
└── Text display (text)         ← hiển thị tên file sau upload, hỗ trợ binding
```

Luồng hoạt động:

1. User tap vào label → mở ActionSheet chọn loại file
2. User chọn file → upload lên server (nếu `autoUpload = true`)
3. Kết quả URL tự động ghi vào bound field qua `text: dr.bind('field')`
4. Tên file hiển thị bên dưới label, có thể tap để mở

---

## Cài đặt

Đặt file `cyberbuttonupload.dart` vào thư mục `lib/Controller/` và import:

```dart
import 'package:cyberframework/Controller/cyberbuttonupload.dart';
```

---

## Props

### Label (giao diện button)

Toàn bộ props được truyền thẳng vào `CyberLabel`.

| Prop | Kiểu | Mặc định | Mô tả |
|------|------|----------|-------|
| `label` | `dynamic` | `'Tải lên'` | Nội dung hiển thị. Hỗ trợ `String`, `CyberBindingExpression` |
| `isIcon` | `bool` | `false` | `true` = parse `label` như icon code point |
| `iconSize` | `double?` | `null` | Kích thước icon |
| `iconSpacing` | `double?` | `null` | Khoảng cách icon với text |
| `style` | `TextStyle?` | `null` | Style text label |
| `textalign` | `TextAlign?` | `null` | Căn chỉnh text |
| `textcolor` | `Color?` | `null` | Màu text / icon |
| `backgroundColor` | `Color?` | `null` | Màu nền label |
| `isVisible` | `dynamic` | `true` | Ẩn/hiện. Hỗ trợ `bool`, `int`, `String`, binding |
| `showRipple` | `bool?` | `true` | Hiện hiệu ứng ripple khi tap |
| `rippleColor` | `Color?` | `null` | Màu ripple |
| `rippleBorderRadius` | `BorderRadius?` | `null` | Bo góc vùng ripple |
| `tapPadding` | `EdgeInsets?` | `null` | Padding vùng tap |
| `maxLines` | `int?` | `null` | Số dòng tối đa |
| `overflow` | `TextOverflow?` | `null` | Xử lý tràn text |
| `format` | `String?` | `null` | Format hiển thị text (ví dụ: `'N0'`, `'dd/MM/yyyy'`) |

### Text (kết quả URL/base64)

| Prop | Kiểu | Mặc định | Mô tả |
|------|------|----------|-------|
| `text` | `dynamic` | `null` | Binding nhận URL sau upload. Hỗ trợ `CyberBindingExpression` hoặc `String` tĩnh |
| `showText` | `bool` | `true` | Hiện tên file bên dưới label |
| `textFormat` | `String?` | `null` | Format chuỗi hiển thị tên file |
| `onTextTap` | `Function(dynamic)?` | `null` | Callback khi tap vào tên file (nhận giá trị URL) |

### General

| Prop | Kiểu | Mặc định | Mô tả |
|------|------|----------|-------|
| `isReadOnly` | `bool` | `false` | Khi `true`: label không phản hồi tap, không mở picker |

### File Picker

| Prop | Kiểu | Mặc định | Mô tả |
|------|------|----------|-------|
| `actions` | `List<String>?` | `['Chọn ảnh', 'Chụp ảnh', 'Chọn file']` | Nhãn hiển thị trong ActionSheet |
| `types` | `List<FilePickerType>?` | `[image, camera, file]` | Loại file tương ứng với `actions` |
| `autoUpload` | `bool` | `true` | `true` = upload lên server và lấy URL. `false` = chỉ lấy base64 |
| `uploadFilePath` | `String?` | `null` | Thư mục lưu trên server (vd: `'/contracts/'`) |
| `pickerTitle` | `String?` | `null` | Tiêu đề ActionSheet |
| `isChangeName` | `bool` | `false` | Hiện dialog đổi tên file trước khi upload |

### Callbacks

| Prop | Kiểu | Mô tả |
|------|------|-------|
| `onUploaded` | `Function(CyberFilePickerResult?)?` | Gọi sau khi chọn/upload xong. `result` là `null` nếu user hủy |

#### CyberFilePickerResult

```dart
class CyberFilePickerResult {
  String fileName;     // Tên file
  String fileType;     // Phần mở rộng (pdf, jpg, ...)
  int fileSize;        // Kích thước bytes
  String? strBase64;   // Dữ liệu base64
  String? urlFile;     // URL sau khi upload (chỉ có khi autoUpload = true)
  File? fileObject;    // File object gốc
}
```

---

## Ví dụ

### 1. Upload PDF đơn giản

```dart
CyberButtonUpload(
  label: 'Tải lên hợp đồng',
  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
  textcolor: Colors.blue,
  text: dr.bind('contract_url'),
  actions: ['Chọn PDF'],
  types: [FilePickerType.pdf],
  uploadFilePath: '/contracts/',
  onUploaded: (result) {
    if (result?.urlFile != null) {
      'Upload thành công'.showToast(toastType: CyberToastType.success);
    }
  },
)
```

### 2. Upload ảnh đại diện dạng icon

```dart
CyberButtonUpload(
  label: 'e412',         // Icons.add_a_photo
  isIcon: true,
  iconSize: 28,
  textcolor: Colors.green,
  text: dr.bind('avatar_url'),
  actions: ['Thư viện ảnh', 'Chụp ảnh'],
  types: [FilePickerType.image, FilePickerType.camera],
  uploadFilePath: '/avatars/',
  onTextTap: (url) {
    V_callform(context, url, 'Ảnh đại diện', '', '', 'imgview');
  },
)
```

### 3. Không upload — chỉ lấy base64

```dart
CyberButtonUpload(
  label: 'Đính kèm chữ ký',
  textcolor: Colors.orange,
  text: dr.bind('signature_base64'),
  autoUpload: false,
  actions: ['Chụp chữ ký'],
  types: [FilePickerType.camera],
  onUploaded: (result) {
    dr['signature_base64'] = result?.strBase64 ?? '';
  },
)
```

### 4. Cho phép nhiều loại file + đổi tên

```dart
CyberButtonUpload(
  label: 'Đính kèm hồ sơ',
  style: const TextStyle(fontSize: 13),
  textcolor: const Color(0xFF145A4A),
  showRipple: true,
  rippleColor: Colors.teal,
  text: dr.bind('document_url'),
  actions: ['Chọn PDF', 'Chọn Word', 'Chọn ảnh', 'Chụp ảnh'],
  types: [
    FilePickerType.pdf,
    FilePickerType.doc,
    FilePickerType.image,
    FilePickerType.camera,
  ],
  uploadFilePath: '/documents/',
  isChangeName: true,
  pickerTitle: 'Chọn tài liệu đính kèm',
  showText: true,
  onTextTap: (url) {
    V_callform(context, url, 'Xem tài liệu', '', '', 'viewfile');
  },
)
```

### 5. ReadOnly — hiện file đã lưu, không cho upload thêm

```dart
CyberButtonUpload(
  label: 'Hợp đồng đã ký',
  textcolor: Colors.grey,
  isReadOnly: true,
  text: dr.bind('signed_url'),
  onTextTap: (url) {
    V_callform(context, url, 'Hợp đồng', '', '', 'pdfview');
  },
)
```

### 6. Label binding động

```dart
// label thay đổi theo dữ liệu trong CyberDataRow
CyberButtonUpload(
  label: dr.bind('button_label'),   // vd: 'Cập nhật ảnh' / 'Tải ảnh lên'
  textcolor: Colors.blue,
  text: dr.bind('photo_url'),
  types: [FilePickerType.image, FilePickerType.camera],
)
```

---

## Ghi chú

**`actions` và `types` phải có cùng số lượng phần tử.** Nếu truyền số lượng khác nhau sẽ throw `ArgumentError` từ `showFilePickerActionSheet`.

```dart
// ✅ Đúng
actions: ['Chọn ảnh', 'Chụp ảnh'],
types: [FilePickerType.image, FilePickerType.camera],

// ❌ Sai
actions: ['Chọn ảnh', 'Chụp ảnh', 'PDF'],
types: [FilePickerType.image, FilePickerType.camera],
```

**`text` binding tự động reactive.** Khi `_textBoundRow.setValue(...)` được gọi sau upload, phần hiển thị tên file bên dưới label tự cập nhật mà không cần `setState` thủ công.

**Khi `autoUpload = false`**, `text` binding sẽ nhận giá trị base64 thay vì URL. Phù hợp với các trường hợp cần xử lý dữ liệu trước khi gửi lên server (vd: submit cùng form).

**`onTextTap`** nhận giá trị raw từ bound field (URL hoặc base64). Dùng để mở viewer:

```dart
onTextTap: (url) => V_callform(context, url, '', '', '', 'viewfile'),
```
