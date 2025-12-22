# CyberPopup, CyberContentView & CyberTabView - Hướng Dẫn Sử Dụng

## CyberPopup

### Giới Thiệu

`CyberPopup` là system hiển thị popup/modal với nhiều position và animation options.

### Properties

| Property | Type | Mô tả |
|----------|------|-------|
| `child` | `Widget` | Content widget |
| `position` | `PopupPosition` | top, center, bottom, fullScreen |
| `animation` | `PopupAnimation` | slide, fade, scale, slideAndFade, none |
| `barrierDismissible` | `bool` | Có thể đóng bằng tap outside |
| `width` | `double?` | Chiều rộng |
| `height` | `double?` | Chiều cao |

### Ví Dụ

```dart
// Center popup
final popup = CyberPopup(
  context: context,
  child: MyWidget(),
  position: PopupPosition.center,
  animation: PopupAnimation.scale,
  width: 400,
);

final result = await popup.show<String>();

// Bottom sheet
await popup.showBottom<bool>();

// Full screen
await popup.showFullScreen();

// Close popup
CyberPopup.close(context, result);
```

---

## CyberContentView

### Giới Thiệu

`CyberContentView` là base class cho màn hình với lifecycle management.

### Lifecycle Methods

```dart
class MyContentView extends CyberContentViewForm {
  @override
  void onInit() {
    // Initialize variables
  }

  @override
  Future<void> onBeforeLoad() async {
    // Prepare before loading
  }

  @override
  Future<void> onLoadData() async {
    // Load data from API
  }

  @override
  Future<void> onAfterLoad() async {
    // Process after load
  }

  @override
  void onLoadError(dynamic error) {
    // Handle errors
  }

  @override
  Widget buildBody(BuildContext context) {
    // Build UI - REQUIRED
    return Container();
  }

  @override
  void onDispose() {
    // Cleanup
  }
}
```

### Popup Methods

```dart
// Show as popup
final result = await myContentView.showPopup<String>(context);

// Show as bottom sheet
final result = await myContentView.showBottom<bool>(context);

// Show as dialog
final result = await myContentView.showAsDialog<int>(context);

// Close with result
closePopup(context, result);
```

### Ví Dụ

```dart
class ProductDetailView extends CyberContentViewForm {
  CyberDataRow row = CyberDataRow();

  @override
  Future<void> onLoadData() async {
    final response = await context.callApi(
      functionName: "GetProduct",
      parameter: cpName,
    );
    
    if (response.isValid()) {
      final ds = response.toCyberDataset();
      row = ds?[0][0] ?? CyberDataRow();
    }
  }

  @override
  Widget buildBody(BuildContext context) {
    return Column(
      children: [
        CyberText(text: row.bind('name'), label: 'Tên'),
        CyberNumeric(text: row.bind('price'), label: 'Giá'),
        ElevatedButton(
          onPressed: () => closePopup(context, row),
          child: Text('Lưu'),
        ),
      ],
    );
  }
}

// Usage
final view = ProductDetailView();
final result = await view.showPopup(context);
```

---

## CyberTabView

### Giới Thiệu

`CyberTabView` là tab navigation với lazy loading.

### Properties

| Property | Type | Mô tả |
|----------|------|-------|
| `tabs` | `List<CyberTab>` | Danh sách tabs |
| `initialIndex` | `int` | Tab ban đầu |
| `backColorTab` | `Color?` | Màu nền tab |
| `selectBackColorTab` | `Color?` | Màu nền tab được chọn |
| `keepAlive` | `bool` | Giữ state khi switch tab |

### Ví Dụ

```dart
CyberTabView(
  tabs: [
    CyberTab(
      label: "Tổng quan",
      viewName: "dashboard",
      icon: Icons.dashboard,
    ),
    CyberTab(
      label: "Báo cáo",
      viewName: "reports",
      cpName: "month=12",
      icon: Icons.analytics,
    ),
    CyberTab(
      label: "Cài đặt",
      viewName: "settings",
      icon: Icons.settings,
    ),
  ],
  initialIndex: 0,
  backColorTab: Colors.grey[200],
  selectBackColorTab: Colors.blue,
  keepAlive: false,  // Dispose views khi switch
  onTabChanged: (index) {
    print('Tab changed: $index');
  },
)
```

### Advanced Options

```dart
CyberTabViewAdvanced(
  tabs: [...],
  indicatorSize: TabBarIndicatorSize.label,
  tabBorderRadius: BorderRadius.circular(12),
  tabSpacing: 8,
  enableFeedback: true,
)
```

---

## Xem Thêm

- [CyberListView](./CyberListView.md) - List view control
- [CyberMessageBox](./CyberMessageBox.md) - Message box
