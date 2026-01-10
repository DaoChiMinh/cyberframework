# CyberContentView - Content View Form Pattern

## Mục Lục
1. [Giới Thiệu](#giới-thiệu)
2. [CyberContentViewForm](#cybercontentviewform)
3. [Lifecycle Methods](#lifecycle-methods)
4. [Ví Dụ Sử Dụng](#ví-dụ-sử-dụng)
5. [Popup Methods](#popup-methods)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

---

## Giới Thiệu

`CyberContentViewForm` là một abstract class cung cấp lifecycle management pattern tương tự CyberForm. Class này cho phép bạn tạo các content view có thể tái sử dụng với khả năng hiển thị dưới dạng popup, bottom sheet, hoặc embedded view.

### Đặc Điểm Chính

- ✅ **Lifecycle Management**: onInit → onBeforeLoad → onLoadData → onAfterLoad
- ✅ **Parameter Support**: Truyền parameters qua constructor
- ✅ **Popup Methods**: Dễ dàng hiển thị dưới dạng popup/dialog/bottom sheet
- ✅ **Loading/Error States**: Built-in loading và error handling
- ✅ **Context Safety**: Safe context access với validation
- ✅ **Rebuild Support**: Rebuild UI khi cần thiết

### Kiến Trúc

```
CyberContentViewForm (Abstract)
    ↓
Your View Class (extends CyberContentViewForm)
    ↓
CyberContentViewWidget (Internal Wrapper)
    ↓
Display as Popup/Embedded
```

### Import

```dart
import 'package:cyberframework/cyberframework.dart';
```

---

## CyberContentViewForm

### Constructor

```dart
CyberContentViewForm({
  String? cpName,
  String? strParameter,
  dynamic objectData,
})
```

### Properties

| Property | Type | Mô Tả | Access |
|----------|------|-------|--------|
| `context` | `BuildContext` | Context của view (throw nếu chưa mount) | Getter |
| `cpName` | `String` | Tên component | Getter/Setter |
| `strParameter` | `String` | String parameter | Getter/Setter |
| `objectData` | `dynamic` | Object data (dynamic) | Getter/Setter |
| `hasContext` | `bool` | Check context có sẵn sàng không | Getter |

### Abstract Methods (REQUIRED)

```dart
/// Build nội dung chính - BẮT BUỘC implement
Widget buildBody(BuildContext context);
```

### Optional Override Methods

```dart
/// Build loading widget (optional)
Widget? buildLoadingWidget() => null;

/// Build error widget (optional)
Widget? buildErrorWidget(String error) => null;
```

---

## Lifecycle Methods

### Thứ Tự Thực Thi

```
1. onInit()           → Khởi tạo cơ bản (sync)
2. onBeforeLoad()     → Chuẩn bị trước load (async)
3. onLoadData()       → Load data từ API (async)
4. onAfterLoad()      → Xử lý sau load (async)
[Nếu có lỗi] → onLoadError()
[Khi dispose] → onDispose()
```

### 1. onInit()

Khởi tạo cơ bản, sync.

```dart
@override
void onInit() {
  // Initialize variables
  // Setup listeners
  // Parse parameters
}
```

**Khi nào dùng:**
- Khởi tạo biến local
- Parse parameters từ constructor
- Setup listeners (không async)

### 2. onBeforeLoad()

Chuẩn bị trước khi load, async.

```dart
@override
Future<void> onBeforeLoad() async {
  // Validate parameters
  // Check permissions
  // Setup dependencies
}
```

**Khi nào dùng:**
- Validate parameters
- Check permissions
- Load dependencies cần thiết

### 3. onLoadData()

Load data chính từ API/Database, async.

```dart
@override
Future<void> onLoadData() async {
  // Load main data from API
  // Populate data tables
  // Setup data bindings
}
```

**Khi nào dùng:**
- Load data từ API
- Populate CyberDataTable
- Setup data bindings

### 4. onAfterLoad()

Xử lý sau khi load xong, async.

```dart
@override
Future<void> onAfterLoad() async {
  // Process loaded data
  // Calculate derived values
  // Setup initial state
}
```

**Khi nào dùng:**
- Process data đã load
- Calculate derived values
- Setup initial UI state

### 5. onLoadError()

Xử lý lỗi, sync.

```dart
@override
void onLoadError(dynamic error) {
  // Log error
  // Show error message
  // Cleanup if needed
}
```

**Khi nào dùng:**
- Log errors
- Show user-friendly messages
- Cleanup resources

### 6. onDispose()

Cleanup khi dispose, sync.

```dart
@override
void onDispose() {
  // Remove listeners
  // Close streams
  // Dispose controllers
}
```

**Khi nào dùng:**
- Remove listeners
- Close streams/subscriptions
- Dispose controllers

---

## Ví Dụ Sử Dụng

### 1. Simple Content View

View đơn giản không cần load data.

```dart
class HelloView extends CyberContentViewForm {
  final String name;
  
  HelloView({this.name = 'World'}) 
    : super(cpName: 'HelloView', strParameter: name);

  @override
  Widget buildBody(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Hello, $name!',
            style: TextStyle(fontSize: 24),
          ),
          SizedBox(height: 16),
          CyberButton(
            label: 'Close',
            onClick: () => closePopup(context),
          ),
        ],
      ),
    );
  }
}

// Usage
await HelloView(name: 'John').showAsDialog(context);
```

### 2. View Với Lifecycle

View load data từ API.

```dart
class ProductDetailView extends CyberContentViewForm {
  final String productId;
  
  // Data
  final drProduct = CyberDataRow();
  final dtImages = CyberDataTable(columns: ['url']);
  
  ProductDetailView({required this.productId})
    : super(
        cpName: 'ProductDetailView',
        strParameter: productId,
      );

  @override
  void onInit() {
    print('Init ProductDetailView for: $productId');
  }

  @override
  Future<void> onBeforeLoad() async {
    // Validate product ID
    if (productId.isEmpty) {
      throw Exception('Product ID is required');
    }
  }

  @override
  Future<void> onLoadData() async {
    // Load product data
    final response = await api.getProduct(productId);
    
    // Populate data row
    drProduct['id'] = response['id'];
    drProduct['name'] = response['name'];
    drProduct['price'] = response['price'];
    drProduct['description'] = response['description'];
    
    // Load images
    final images = response['images'] as List;
    for (final img in images) {
      dtImages.addRow([img['url']]);
    }
  }

  @override
  Future<void> onAfterLoad() async {
    print('Product loaded: ${drProduct['name']}');
  }

  @override
  void onLoadError(dynamic error) {
    print('Error loading product: $error');
  }

  @override
  void onDispose() {
    print('Disposing ProductDetailView');
  }

  @override
  Widget buildBody(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(drProduct['name']?.toString() ?? ''),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Images
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: dtImages.rowCount,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Image.network(
                      dtImages[index]['url'].toString(),
                      width: 200,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
            
            SizedBox(height: 16),
            
            // Name
            Text(
              drProduct['name']?.toString() ?? '',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            SizedBox(height: 8),
            
            // Price
            Text(
              '${drProduct['price']} VNĐ',
              style: TextStyle(
                fontSize: 20,
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            SizedBox(height: 16),
            
            // Description
            Text(drProduct['description']?.toString() ?? ''),
            
            SizedBox(height: 24),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: CyberButton(
                    label: 'Thêm vào giỏ',
                    onClick: () => addToCart(),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: CyberButton(
                    label: 'Mua ngay',
                    onClick: () => buyNow(),
                    backgroundColor: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void addToCart() {
    // Add to cart logic
    closePopup(context, 'added_to_cart');
  }
  
  void buyNow() {
    // Buy now logic
    closePopup(context, 'buy_now');
  }
}

// Usage
final result = await ProductDetailView(
  productId: '12345',
).showPopup(context);

if (result == 'added_to_cart') {
  print('Added to cart');
} else if (result == 'buy_now') {
  print('Proceed to checkout');
}
```

### 3. Form View Với Validation

Form nhập liệu với validation.

```dart
class AddCustomerView extends CyberContentViewForm {
  final drCustomer = CyberDataRow();
  
  AddCustomerView() : super(cpName: 'AddCustomerView');

  @override
  void onInit() {
    // Initialize empty customer
    drCustomer['name'] = '';
    drCustomer['email'] = '';
    drCustomer['phone'] = '';
  }

  @override
  Widget buildBody(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Thêm khách hàng')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            CyberText(
              text: drCustomer.bind('name'),
              label: 'Tên khách hàng',
              isCheckEmpty: true,
            ),
            
            SizedBox(height: 16),
            
            CyberText(
              text: drCustomer.bind('email'),
              label: 'Email',
              isCheckEmpty: true,
            ),
            
            SizedBox(height: 16),
            
            CyberText(
              text: drCustomer.bind('phone'),
              label: 'Số điện thoại',
            ),
            
            Spacer(),
            
            Row(
              children: [
                Expanded(
                  child: CyberButton(
                    label: 'Hủy',
                    onClick: () => closePopup(context),
                    backgroundColor: Colors.grey,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: CyberButton(
                    label: 'Lưu',
                    onClick: save,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> save() async {
    // Validate
    if (drCustomer['name']?.toString().isEmpty ?? true) {
      showError('Vui lòng nhập tên');
      return;
    }
    
    if (drCustomer['email']?.toString().isEmpty ?? true) {
      showError('Vui lòng nhập email');
      return;
    }
    
    // Show loading
    showLoading('Đang lưu...');
    
    try {
      // Save to API
      await api.createCustomer({
        'name': drCustomer['name'],
        'email': drCustomer['email'],
        'phone': drCustomer['phone'],
      });
      
      hideLoading();
      
      // Close with success result
      closePopup(context, drCustomer);
    } catch (e) {
      hideLoading();
      showError('Lỗi: $e');
    }
  }
  
  void showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Thông báo'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }
}

// Usage
final customer = await AddCustomerView().showAsDialog(context);

if (customer != null) {
  print('Customer added: ${customer['name']}');
}
```

### 4. Custom Loading & Error Widgets

Tùy chỉnh loading và error UI.

```dart
class CustomLoadingView extends CyberContentViewForm {
  CustomLoadingView() : super(cpName: 'CustomLoadingView');

  @override
  Future<void> onLoadData() async {
    // Simulate long loading
    await Future.delayed(Duration(seconds: 2));
    
    // Uncomment to test error
    // throw Exception('Test error');
  }

  @override
  Widget? buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blue),
          SizedBox(height: 16),
          Text(
            'Đang tải dữ liệu...',
            style: TextStyle(fontSize: 16, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  @override
  Widget? buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Có lỗi xảy ra',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(error),
          SizedBox(height: 24),
          CyberButton(
            label: 'Thử lại',
            onClick: () => rebuild(),
          ),
        ],
      ),
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return Center(
      child: Text('Data loaded successfully!'),
    );
  }
}
```

### 5. View Với Parameters

Truyền nhiều parameters.

```dart
class OrderDetailView extends CyberContentViewForm {
  final String orderId;
  final bool isEditable;
  
  OrderDetailView({
    required this.orderId,
    this.isEditable = false,
  }) : super(
    cpName: 'OrderDetailView',
    strParameter: orderId,
    objectData: {'isEditable': isEditable},
  );

  @override
  Future<void> onLoadData() async {
    final response = await api.getOrder(orderId);
    // Process data...
  }

  @override
  Widget buildBody(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order #$orderId'),
        actions: isEditable
          ? [
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () => editOrder(),
              ),
            ]
          : null,
      ),
      body: Container(
        // Order details...
      ),
    );
  }
}

// Usage
await OrderDetailView(
  orderId: 'ORD-12345',
  isEditable: true,
).showPopup(context);
```

### 6. Master-Detail Pattern

View cha mở view con.

```dart
class ProductListView extends CyberContentViewForm {
  final dtProducts = CyberDataTable(columns: ['id', 'name', 'price']);
  
  ProductListView() : super(cpName: 'ProductListView');

  @override
  Future<void> onLoadData() async {
    final products = await api.getProducts();
    
    for (final p in products) {
      dtProducts.addRow([p['id'], p['name'], p['price']]);
    }
  }

  @override
  Widget buildBody(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sản phẩm')),
      body: ListView.builder(
        itemCount: dtProducts.rowCount,
        itemBuilder: (context, index) {
          final product = dtProducts[index];
          
          return ListTile(
            title: Text(product['name'].toString()),
            subtitle: Text('${product['price']} VNĐ'),
            onTap: () => viewProductDetail(product['id'].toString()),
          );
        },
      ),
    );
  }
  
  Future<void> viewProductDetail(String productId) async {
    // Open detail view
    final result = await ProductDetailView(
      productId: productId,
    ).showPopup(context);
    
    if (result == 'added_to_cart') {
      showSnackBar('Đã thêm vào giỏ hàng');
    }
  }
  
  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
```

### 7. Bottom Sheet Usage

Hiển thị dưới dạng bottom sheet.

```dart
class FilterOptionsView extends CyberContentViewForm {
  final drFilter = CyberDataRow();
  
  FilterOptionsView() : super(cpName: 'FilterOptionsView') {
    drFilter['min_price'] = '';
    drFilter['max_price'] = '';
    drFilter['category'] = null;
    drFilter['in_stock'] = true;
  }

  @override
  Widget buildBody(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Lọc sản phẩm',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          
          SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: CyberNumeric(
                  text: drFilter.bind('min_price'),
                  label: 'Giá từ',
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: CyberNumeric(
                  text: drFilter.bind('max_price'),
                  label: 'Đến',
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          CyberCheckbox(
            text: drFilter.bind('in_stock'),
            label: 'Chỉ sản phẩm còn hàng',
          ),
          
          SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: CyberButton(
                  label: 'Đặt lại',
                  onClick: reset,
                  backgroundColor: Colors.grey,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: CyberButton(
                  label: 'Áp dụng',
                  onClick: () => closePopup(context, drFilter),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  void reset() {
    drFilter['min_price'] = '';
    drFilter['max_price'] = '';
    drFilter['in_stock'] = true;
    rebuild();
  }
}

// Usage
final filter = await FilterOptionsView().showBottom(context);

if (filter != null) {
  applyFilter(filter);
}
```

### 8. Rebuild Pattern

Sử dụng rebuild() để update UI.

```dart
class CounterView extends CyberContentViewForm {
  int counter = 0;
  
  CounterView() : super(cpName: 'CounterView');

  @override
  Widget buildBody(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Counter: $counter',
            style: TextStyle(fontSize: 48),
          ),
          
          SizedBox(height: 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CyberButton(
                label: '-',
                onClick: decrement,
                backgroundColor: Colors.red,
              ),
              SizedBox(width: 12),
              CyberButton(
                label: '+',
                onClick: increment,
                backgroundColor: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  void increment() {
    counter++;
    rebuild(); // Trigger rebuild
  }
  
  void decrement() {
    counter--;
    rebuild(); // Trigger rebuild
  }
}
```

### 9. Navigation Between Views

Chuyển đổi giữa các views.

```dart
class WizardStep1View extends CyberContentViewForm {
  final drData = CyberDataRow();
  
  WizardStep1View() : super(cpName: 'WizardStep1View');

  @override
  Widget buildBody(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bước 1/3')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            CyberText(
              text: drData.bind('name'),
              label: 'Tên',
            ),
            
            Spacer(),
            
            CyberButton(
              label: 'Tiếp theo',
              onClick: goToStep2,
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> goToStep2() async {
    if (drData['name']?.toString().isEmpty ?? true) {
      showError('Vui lòng nhập tên');
      return;
    }
    
    // Close current and open next
    closePopup(context);
    
    await WizardStep2View(
      previousData: drData,
    ).showAsDialog(context);
  }
}

class WizardStep2View extends CyberContentViewForm {
  final CyberDataRow previousData;
  final drData = CyberDataRow();
  
  WizardStep2View({required this.previousData})
    : super(cpName: 'WizardStep2View');

  @override
  void onInit() {
    // Copy data from previous step
    drData['name'] = previousData['name'];
  }

  @override
  Widget buildBody(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bước 2/3')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Tên: ${drData['name']}'),
            
            SizedBox(height: 16),
            
            CyberText(
              text: drData.bind('email'),
              label: 'Email',
            ),
            
            Spacer(),
            
            CyberButton(
              label: 'Tiếp theo',
              onClick: goToStep3,
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> goToStep3() async {
    // Validate and continue...
  }
}
```

### 10. Confirmation Dialog

Dialog xác nhận đơn giản.

```dart
class ConfirmDeleteView extends CyberContentViewForm {
  final String itemName;
  
  ConfirmDeleteView({required this.itemName})
    : super(cpName: 'ConfirmDeleteView', strParameter: itemName);

  @override
  Widget buildBody(BuildContext context) {
    return AlertDialog(
      title: Text('Xác nhận xóa'),
      content: Text('Bạn có chắc muốn xóa "$itemName"?'),
      actions: [
        TextButton(
          onPressed: () => closePopup(context, false),
          child: Text('Hủy'),
        ),
        TextButton(
          onPressed: () => closePopup(context, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: Text('Xóa'),
        ),
      ],
    );
  }
}

// Usage
final confirmed = await ConfirmDeleteView(
  itemName: 'Product ABC',
).showAsDialog(
  context,
  width: 300,
  height: 200,
);

if (confirmed == true) {
  deleteItem();
}
```

---

## Popup Methods

### 1. showPopup()

Hiển thị popup với tùy chỉnh đầy đủ.

```dart
Future<T?> showPopup<T>(
  BuildContext context, {
  PopupPosition position = PopupPosition.center,
  PopupAnimation animation = PopupAnimation.slideAndFade,
  bool barrierDismissible = true,
  Color? barrierColor,
  EdgeInsets? margin,
  EdgeInsets? padding,
  double? width,
  double? height,
  BorderRadius? borderRadius,
  Color? backgroundColor,
})
```

**Ví dụ:**
```dart
await myView.showPopup(
  context,
  position: PopupPosition.center,
  width: 400,
  height: 600,
  borderRadius: BorderRadius.circular(16),
);
```

### 2. showAsDialog()

Hiển thị dưới dạng center dialog.

```dart
Future<T?> showAsDialog<T>(
  BuildContext context, {
  PopupAnimation animation = PopupAnimation.scale,
  bool barrierDismissible = true,
  Color? barrierColor,
  EdgeInsets? margin,
  EdgeInsets? padding,
  double? width,
  double? height,
  BorderRadius? borderRadius,
  Color? backgroundColor,
})
```

**Ví dụ:**
```dart
final result = await myView.showAsDialog<String>(
  context,
  width: 400,
  height: 300,
);
```

### 3. showBottom()

Hiển thị dưới dạng bottom sheet.

```dart
Future<T?> showBottom<T>(
  BuildContext context, {
  PopupAnimation animation = PopupAnimation.slideAndFade,
  bool barrierDismissible = true,
  Color? barrierColor,
  EdgeInsets? margin,
  EdgeInsets? padding,
  BorderRadius? borderRadius,
  Color? backgroundColor,
})
```

**Ví dụ:**
```dart
final filter = await filterView.showBottom(context);
```

### 4. closePopup()

Đóng popup với kết quả.

```dart
void closePopup<T>(BuildContext context, [T? result])
```

**Ví dụ:**
```dart
CyberButton(
  label: 'Save',
  onClick: () => closePopup(context, myData),
)
```

---

## Best Practices

### 1. Lifecycle Usage

```dart
// ✅ GOOD: Proper lifecycle usage
class MyView extends CyberContentViewForm {
  @override
  void onInit() {
    // Sync initialization
  }
  
  @override
  Future<void> onLoadData() async {
    // Async data loading
  }
}

// ❌ BAD: Async in onInit
class MyView extends CyberContentViewForm {
  @override
  void onInit() async { // Wrong!
    await loadData();
  }
}
```

### 2. Parameter Passing

```dart
// ✅ GOOD: Clear parameters
class ProductView extends CyberContentViewForm {
  final String productId;
  final bool isEditable;
  
  ProductView({
    required this.productId,
    this.isEditable = false,
  }) : super(cpName: 'ProductView');
}

// ❌ BAD: Unclear parameters
class ProductView extends CyberContentViewForm {
  ProductView(String p1, bool p2) : super();
}
```

### 3. Context Safety

```dart
// ✅ GOOD: Check context before use
void showMessage() {
  if (hasContext) {
    ScaffoldMessenger.of(context).showSnackBar(...);
  }
}

// ❌ BAD: No check
void showMessage() {
  ScaffoldMessenger.of(context).showSnackBar(...); // May crash
}
```

### 4. Error Handling

```dart
// ✅ GOOD: Handle errors
@override
Future<void> onLoadData() async {
  try {
    final data = await api.getData();
    // Process...
  } catch (e) {
    throw Exception('Failed to load data: $e');
  }
}

@override
void onLoadError(dynamic error) {
  print('Error: $error');
  // Log to analytics
}

// ❌ BAD: Silent failures
@override
Future<void> onLoadData() async {
  try {
    await api.getData();
  } catch (e) {
    // Do nothing
  }
}
```

### 5. Cleanup

```dart
// ✅ GOOD: Proper cleanup
@override
void onDispose() {
  myController.dispose();
  mySubscription.cancel();
}

// ❌ BAD: No cleanup
@override
void onDispose() {
  // Nothing - may cause memory leaks
}
```

---

## Troubleshooting

### Context not available error

**Nguyên nhân:** Access context trước khi mount

**Giải pháp:**
```dart
// ✅ Check hasContext
if (hasContext) {
  Navigator.of(context).push(...);
}

// ✅ Use in buildBody
@override
Widget buildBody(BuildContext context) {
  // context is safe here
}
```

### Loading không hiển thị

**Nguyên nhân:** Không override buildLoadingWidget

**Giải pháp:**
```dart
@override
Widget? buildLoadingWidget() {
  return Center(
    child: CircularProgressIndicator(),
  );
}
```

### Data không load

**Nguyên nhân:** Không implement onLoadData

**Giải pháp:**
```dart
@override
Future<void> onLoadData() async {
  // Load your data here
  await loadMyData();
}
```

### Popup không đóng

**Nguyên nhân:** Context invalid hoặc wrong usage

**Giải pháp:**
```dart
// ✅ CORRECT: Use helper
closePopup(context, result);

// ❌ WRONG: Direct Navigator
Navigator.of(context).pop(); // May not work
```

### Rebuild không hoạt động

**Nguyên nhân:** Gọi rebuild() trước khi mount

**Giải pháp:**
```dart
void updateData() {
  myData = newData;
  
  if (hasContext) {
    rebuild();
  }
}
```

---

## Tips & Tricks

### 1. Reusable Views

Tạo views có thể tái sử dụng:

```dart
class ConfirmDialog extends CyberContentViewForm {
  final String title;
  final String message;
  
  ConfirmDialog({
    required this.title,
    required this.message,
  }) : super(cpName: 'ConfirmDialog');

  @override
  Widget buildBody(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => closePopup(context, false),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () => closePopup(context, true),
          child: Text('Confirm'),
        ),
      ],
    );
  }
}

// Reuse anywhere
final confirmed = await ConfirmDialog(
  title: 'Delete Item',
  message: 'Are you sure?',
).showAsDialog(context);
```

### 2. Loading Helper

```dart
Future<T> withLoading<T>(Future<T> Function() action) async {
  showLoading();
  try {
    return await action();
  } finally {
    hideLoading();
  }
}

// Usage
await withLoading(() async {
  return await api.saveData();
});
```

### 3. Result Types

```dart
enum DialogResult {
  save,
  cancel,
  delete,
}

// Return enum
closePopup(context, DialogResult.save);

// Check result
final result = await myView.showAsDialog(context);
if (result == DialogResult.save) {
  // Handle save
}
```

---

## Performance Tips

1. **Lazy Load**: Chỉ load data khi cần
2. **Cache Data**: Cache API responses
3. **Dispose**: Always dispose controllers
4. **Avoid Rebuilds**: Chỉ rebuild khi cần
5. **Use Keys**: Dùng keys cho nested views

---

## Version History

### 1.0.0
- Initial release
- Lifecycle management
- Parameter support
- Popup methods
- Loading/Error states
- Context safety

---

## License

MIT License - CyberFramework
