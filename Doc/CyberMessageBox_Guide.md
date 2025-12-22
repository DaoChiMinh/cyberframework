# CyberMessageBox - Hướng Dẫn Sử Dụng

## Giới Thiệu

`CyberMessageBox` là dialog/alert widget với 3 types: Default, Warning, Error.

## Types

| Type | Icon | Color | Buttons |
|------|------|-------|---------|
| `defaultType` | ✓ check | Green | OK |
| `warning` | ? question | Orange | OK, Cancel |
| `error` | ! error | Red | OK |

## Extension Methods

### V_MsgBox

```dart
bool result = await "Message content".V_MsgBox(
  context,
  title: "Title",
  type: CyberMsgBoxType.warning,
);
```

### Context Extensions

```dart
// Success message
await context.showSuccess("Lưu thành công!");

// Warning message
bool confirm = await context.showWarning(
  "Bạn có chắc muốn xóa?",
  cancelText: "Hủy",
);

// Error message
await context.showErrorMsg("Đã xảy ra lỗi!");
```

## Ví Dụ Cơ Bản

### 1. Success Message

```dart
await context.showSuccess("Cập nhật thành công!");
```

### 2. Confirmation Dialog

```dart
bool confirm = await context.showWarning(
  "Bạn có chắc muốn xóa mục này?",
  confirmText: "Xóa",
  cancelText: "Hủy",
);

if (confirm) {
  deleteItem();
}
```

### 3. Error Message

```dart
await context.showErrorMsg(
  "Không thể kết nối đến server",
  confirmText: "Thử lại",
);
```

### 4. Custom MessageBox

```dart
final msgBox = CyberMessageBox(
  message: "Bạn có muốn tiếp tục?",
  title: "Xác nhận",
  type: CyberMsgBoxType.warning,
  confirmText: "Có",
  cancelText: "Không",
);

bool result = await msgBox.show(context);
```

## Use Cases

### 1. Delete Confirmation

```dart
Future<void> deleteProduct(int id) async {
  bool confirm = await context.showWarning(
    "Xóa sản phẩm này sẽ không thể hoàn tác. Bạn có chắc chắn?",
    confirmText: "Xóa",
    cancelText: "Hủy",
  );
  
  if (confirm) {
    await api.deleteProduct(id);
    await context.showSuccess("Đã xóa sản phẩm!");
  }
}
```

### 2. Save Confirmation

```dart
Future<void> saveForm() async {
  try {
    await api.save(data);
    await context.showSuccess("Lưu thành công!");
  } catch (e) {
    await context.showErrorMsg("Lỗi: ${e.toString()}");
  }
}
```

### 3. Exit Confirmation

```dart
Future<bool> onWillPop() async {
  return await context.showWarning(
    "Có thay đổi chưa lưu. Bạn có muốn thoát?",
  );
}
```

---

## Xem Thêm

- [CyberPopup](./CyberPopup.md) - Popup system
- [CyberContentView](./CyberContentView.md) - Content view
