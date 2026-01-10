# CyberComboBox - ComboBox với Data Binding

## Mục Lục
1. [Giới Thiệu](#giới-thiệu)
2. [CyberComboBox Widget](#cybercombobox-widget)
3. [CyberComboBoxController](#cybercomboboxcontroller)
4. [Ví Dụ Sử Dụng](#ví-dụ-sử-dụng)
5. [Features](#features)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

---

## Giới Thiệu

`CyberComboBox` là một dropdown selection widget theo ERP style với **Internal Controller** và **Data Binding** hai chiều. Widget này được thiết kế để làm việc seamlessly với `CyberDataTable` làm data source.

### Đặc Điểm Chính

- ✅ **Internal Controller**: Tự động quản lý state, không cần khai báo controller
- ✅ **Two-Way Binding**: Tự động sync với CyberDataRow
- ✅ **DataTable Integration**: Dùng CyberDataTable làm data source
- ✅ **Type Preservation**: Giữ nguyên kiểu dữ liệu khi update
- ✅ **iOS-Style Picker**: Bottom sheet picker với CupertinoPicker
- ✅ **Visibility Binding**: Hỗ trợ binding cho visibility
- ✅ **Optional Controller**: Controller cho advanced use cases

### Triết Lý Thiết Kế

```
DataSource (CyberDataTable) → Display/Value Members → Selected Value (Binding)
```

### Import

```dart
import 'package:cyberframework/cyberframework.dart';
```

---

## CyberComboBox Widget

### Constructor

```dart
const CyberComboBox({
  super.key,
  this.text,
  this.controller,
  this.displayMember,
  this.valueMember,
  this.dataSource,
  this.label,
  this.hint,
  this.labelStyle,
  this.textStyle,
  this.prefixIcon,
  this.borderSize = 1,
  this.borderRadius,
  this.enabled = true,
  this.onChanged,
  this.onLeaver,
  this.iconColor,
  this.backgroundColor,
  this.borderColor = Colors.transparent,
  this.isShowLabel = true,
  this.isVisible = true,
  this.isCheckEmpty = false,
})
```

### Properties

#### Data Binding

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `text` | `dynamic` | Binding đến field chứa giá trị (value binding) | null |
| `controller` | `CyberComboBoxController?` | External controller (optional) | null |
| `displayMember` | `dynamic` | Field name để hiển thị (có thể binding) | null |
| `valueMember` | `dynamic` | Field name cho giá trị (có thể binding) | null |
| `dataSource` | `CyberDataTable?` | DataTable chứa options | null |

#### Callbacks

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `onChanged` | `ValueChanged<dynamic>?` | Callback khi giá trị thay đổi | null |
| `onLeaver` | `Function(dynamic)?` | Callback khi rời khỏi control | null |

#### UI Properties

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `label` | `String?` | Label hiển thị phía trên | null |
| `hint` | `String?` | Hint text khi chưa chọn | null |
| `labelStyle` | `TextStyle?` | Style cho label | null |
| `textStyle` | `TextStyle?` | Style cho text được chọn | null |
| `prefixIcon` | `String?` | Icon code hiển thị bên trái | null |
| `borderSize` | `int?` | Kích thước border (pixel) | 1 |
| `borderRadius` | `int?` | Border radius (pixel) | 4 |
| `enabled` | `bool` | Enable/disable widget | true |
| `iconColor` | `Color?` | Màu icon | null |
| `backgroundColor` | `Color?` | Màu nền | Color(0xFFF5F5F5) |
| `borderColor` | `Color?` | Màu border | Colors.transparent |
| `isShowLabel` | `bool` | Hiển thị label | true |
| `isVisible` | `dynamic` | Hiển thị/ẩn widget (có thể binding) | true |
| `isCheckEmpty` | `bool` | Hiển thị dấu * bắt buộc | false |

---

## CyberComboBoxController

**NOTE**: Controller là **OPTIONAL**. Trong hầu hết trường hợp, bạn **KHÔNG CẦN** dùng controller. Widget đã có internal controller và hỗ trợ binding trực tiếp.

### Khi Nào Dùng Controller?

Chỉ dùng controller khi:
- Cần programmatic control phức tạp
- Cần validate selected value
- Cần share state giữa nhiều widgets

### Constructor

```dart
CyberComboBoxController({
  dynamic value,
  bool enabled = true,
  CyberDataTable? dataSource,
  String? displayMember,
  String? valueMember,
})
```

### Properties & Methods

```dart
final controller = CyberComboBoxController(
  dataSource: dtCustomers,
  displayMember: 'name',
  valueMember: 'id',
);

// Getters
dynamic value = controller.value;
bool enabled = controller.enabled;
CyberDataTable? dataSource = controller.dataSource;

// Setters
controller.setValue('001');
controller.setEnabled(true);
controller.setDataSource(dtCustomers);
controller.setDisplayMember('name');
controller.setValueMember('id');

// Utilities
controller.clear();
controller.reset(initialValue);
String? displayText = controller.getDisplayText();
bool isValid = controller.isValidValue();
CyberDataRow? row = controller.getSelectedRow();
```

---

## Ví Dụ Sử Dụng

### 1. Sử Dụng Cơ Bản (Recommended)

Simple binding với CyberDataTable.

```dart
class CustomerForm extends StatefulWidget {
  @override
  State<CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends State<CustomerForm> {
  final drOrder = CyberDataRow();
  final dtCustomers = CyberDataTable(
    columns: ['ma_kh', 'ten_kh'],
  );

  @override
  void initState() {
    super.initState();
    
    // Load data
    dtCustomers.addRow(['001', 'Nguyễn Văn A']);
    dtCustomers.addRow(['002', 'Trần Thị B']);
    dtCustomers.addRow(['003', 'Lê Văn C']);
    
    // Initial value
    drOrder['ma_kh'] = '001';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberComboBox(
          text: drOrder.bind('ma_kh'),
          dataSource: dtCustomers,
          valueMember: 'ma_kh',
          displayMember: 'ten_kh',
          label: 'Khách hàng',
          hint: 'Chọn khách hàng',
        ),
      ],
    );
  }
}
```

### 2. Với Icon và Custom Styling

Tùy chỉnh giao diện.

```dart
CyberComboBox(
  text: drProduct.bind('category_id'),
  dataSource: dtCategories,
  valueMember: 'id',
  displayMember: 'name',
  label: 'Danh mục',
  hint: 'Chọn danh mục sản phẩm',
  
  // Icon
  prefixIcon: 'e8b8', // category icon
  iconColor: Colors.blue,
  
  // Styling
  backgroundColor: Colors.blue.shade50,
  borderColor: Colors.blue.shade200,
  borderSize: 2,
  borderRadius: 8,
  
  // Text styles
  labelStyle: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Colors.blue.shade900,
  ),
  textStyle: TextStyle(
    fontSize: 16,
    color: Colors.blue.shade900,
  ),
)
```

### 3. Required Field (Bắt Buộc)

Hiển thị dấu * cho field bắt buộc.

```dart
CyberComboBox(
  text: drEmployee.bind('department_id'),
  dataSource: dtDepartments,
  valueMember: 'id',
  displayMember: 'name',
  label: 'Phòng ban',
  hint: 'Chọn phòng ban',
  isCheckEmpty: true, // Hiển thị dấu *
  onChanged: (value) {
    print('Department changed: $value');
  },
)
```

### 4. Disabled State

ComboBox ở trạng thái readonly.

```dart
class OrderForm extends StatefulWidget {
  @override
  State<OrderForm> createState() => _OrderFormState();
}

class _OrderFormState extends State<OrderForm> {
  final drOrder = CyberDataRow();
  final dtStatus = CyberDataTable(columns: ['id', 'name']);
  bool isEditing = false;

  @override
  void initState() {
    super.initState();
    
    dtStatus.addRow(['pending', 'Đang chờ']);
    dtStatus.addRow(['processing', 'Đang xử lý']);
    dtStatus.addRow(['completed', 'Hoàn thành']);
    
    drOrder['status'] = 'pending';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberComboBox(
          text: drOrder.bind('status'),
          dataSource: dtStatus,
          valueMember: 'id',
          displayMember: 'name',
          label: 'Trạng thái',
          enabled: isEditing, // Conditional enable
        ),
        
        SizedBox(height: 16),
        
        CyberButton(
          label: isEditing ? 'Lưu' : 'Chỉnh sửa',
          onClick: () {
            setState(() {
              isEditing = !isEditing;
            });
          },
        ),
      ],
    );
  }
}
```

### 5. Cascading ComboBoxes (Dependent Dropdowns)

ComboBox phụ thuộc vào ComboBox khác.

```dart
class LocationForm extends StatefulWidget {
  @override
  State<LocationForm> createState() => _LocationFormState();
}

class _LocationFormState extends State<LocationForm> {
  final drAddress = CyberDataRow();
  
  // Master data
  final dtProvinces = CyberDataTable(columns: ['id', 'name']);
  final dtDistricts = CyberDataTable(columns: ['id', 'province_id', 'name']);
  final dtWards = CyberDataTable(columns: ['id', 'district_id', 'name']);
  
  // Filtered data
  late CyberDataTable dtFilteredDistricts;
  late CyberDataTable dtFilteredWards;

  @override
  void initState() {
    super.initState();
    
    // Load master data
    loadProvinces();
    loadDistricts();
    loadWards();
    
    // Init filtered data
    dtFilteredDistricts = CyberDataTable(columns: ['id', 'province_id', 'name']);
    dtFilteredWards = CyberDataTable(columns: ['id', 'district_id', 'name']);
    
    // Listen to province changes
    drAddress.addListener(() {
      if (drAddress.isFieldChanged('province_id')) {
        onProvinceChanged();
      }
      if (drAddress.isFieldChanged('district_id')) {
        onDistrictChanged();
      }
    });
  }

  void loadProvinces() {
    dtProvinces.addRow(['01', 'Hà Nội']);
    dtProvinces.addRow(['02', 'Hồ Chí Minh']);
    dtProvinces.addRow(['03', 'Đà Nẵng']);
  }

  void loadDistricts() {
    dtDistricts.addRow(['0101', '01', 'Ba Đình']);
    dtDistricts.addRow(['0102', '01', 'Hoàn Kiếm']);
    dtDistricts.addRow(['0201', '02', 'Quận 1']);
    dtDistricts.addRow(['0202', '02', 'Quận 3']);
  }

  void loadWards() {
    dtWards.addRow(['010101', '0101', 'Phường Phúc Xá']);
    dtWards.addRow(['010102', '0101', 'Phường Trúc Bạch']);
    dtWards.addRow(['010201', '0102', 'Phường Hàng Trống']);
  }

  void onProvinceChanged() {
    final provinceId = drAddress['province_id'];
    
    // Clear dependent fields
    drAddress['district_id'] = null;
    drAddress['ward_id'] = null;
    
    // Filter districts
    dtFilteredDistricts.clear();
    for (int i = 0; i < dtDistricts.rowCount; i++) {
      final row = dtDistricts[i];
      if (row['province_id'] == provinceId) {
        dtFilteredDistricts.addRow([
          row['id'],
          row['province_id'],
          row['name'],
        ]);
      }
    }
    
    // Clear wards
    dtFilteredWards.clear();
    
    setState(() {});
  }

  void onDistrictChanged() {
    final districtId = drAddress['district_id'];
    
    // Clear ward
    drAddress['ward_id'] = null;
    
    // Filter wards
    dtFilteredWards.clear();
    for (int i = 0; i < dtWards.rowCount; i++) {
      final row = dtWards[i];
      if (row['district_id'] == districtId) {
        dtFilteredWards.addRow([
          row['id'],
          row['district_id'],
          row['name'],
        ]);
      }
    }
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tỉnh/Thành phố
        CyberComboBox(
          text: drAddress.bind('province_id'),
          dataSource: dtProvinces,
          valueMember: 'id',
          displayMember: 'name',
          label: 'Tỉnh/Thành phố',
          hint: 'Chọn tỉnh/thành phố',
        ),
        
        SizedBox(height: 16),
        
        // Quận/Huyện (dependent)
        CyberComboBox(
          text: drAddress.bind('district_id'),
          dataSource: dtFilteredDistricts,
          valueMember: 'id',
          displayMember: 'name',
          label: 'Quận/Huyện',
          hint: 'Chọn quận/huyện',
          enabled: drAddress['province_id'] != null,
        ),
        
        SizedBox(height: 16),
        
        // Phường/Xã (dependent)
        CyberComboBox(
          text: drAddress.bind('ward_id'),
          dataSource: dtFilteredWards,
          valueMember: 'id',
          displayMember: 'name',
          label: 'Phường/Xã',
          hint: 'Chọn phường/xã',
          enabled: drAddress['district_id'] != null,
        ),
      ],
    );
  }
}
```

### 6. Load Data From API

Async load data từ API.

```dart
class ProductForm extends StatefulWidget {
  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final drProduct = CyberDataRow();
  final dtCategories = CyberDataTable(columns: ['id', 'name']);
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  Future<void> loadCategories() async {
    setState(() => isLoading = true);
    
    try {
      // Call API
      final response = await api.getCategories();
      
      // Populate data table
      dtCategories.clear();
      for (final item in response.data) {
        dtCategories.addRow([item['id'], item['name']]);
      }
    } catch (e) {
      showError('Lỗi load dữ liệu: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return CyberComboBox(
      text: drProduct.bind('category_id'),
      dataSource: dtCategories,
      valueMember: 'id',
      displayMember: 'name',
      label: 'Danh mục',
      hint: 'Chọn danh mục',
    );
  }
}
```

### 7. Với Callback và Validation

Xử lý khi giá trị thay đổi.

```dart
CyberComboBox(
  text: drOrder.bind('payment_method'),
  dataSource: dtPaymentMethods,
  valueMember: 'id',
  displayMember: 'name',
  label: 'Phương thức thanh toán',
  
  onChanged: (value) {
    print('Payment method changed: $value');
    
    // Show/hide additional fields
    if (value == 'credit_card') {
      showCreditCardFields();
    } else if (value == 'bank_transfer') {
      showBankTransferFields();
    }
  },
  
  onLeaver: (value) {
    // Validate when user leaves the field
    if (value == null) {
      showError('Vui lòng chọn phương thức thanh toán');
    }
  },
)
```

### 8. Visibility Binding

Hiển thị/ẩn ComboBox dựa trên binding.

```dart
class ShippingForm extends StatefulWidget {
  @override
  State<ShippingForm> createState() => _ShippingFormState();
}

class _ShippingFormState extends State<ShippingForm> {
  final drOrder = CyberDataRow();
  final dtShippingMethods = CyberDataTable(columns: ['id', 'name']);

  @override
  void initState() {
    super.initState();
    
    drOrder['has_shipping'] = false;
    drOrder['shipping_method'] = null;
    
    dtShippingMethods.addRow(['standard', 'Giao hàng tiêu chuẩn']);
    dtShippingMethods.addRow(['express', 'Giao hàng nhanh']);
    dtShippingMethods.addRow(['same_day', 'Giao trong ngày']);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberCheckbox(
          text: drOrder.bind('has_shipping'),
          label: 'Giao hàng tận nơi',
        ),
        
        SizedBox(height: 16),
        
        // Only show when has_shipping = true
        CyberComboBox(
          text: drOrder.bind('shipping_method'),
          dataSource: dtShippingMethods,
          valueMember: 'id',
          displayMember: 'name',
          label: 'Phương thức giao hàng',
          hint: 'Chọn phương thức',
          isVisible: drOrder.bind('has_shipping'), // Visibility binding
        ),
      ],
    );
  }
}
```

### 9. Multiple ComboBoxes với Shared DataSource

Nhiều ComboBox dùng chung data source.

```dart
class EmployeeForm extends StatefulWidget {
  @override
  State<EmployeeForm> createState() => _EmployeeFormState();
}

class _EmployeeFormState extends State<EmployeeForm> {
  final drEmployee = CyberDataRow();
  final dtDepartments = CyberDataTable(columns: ['id', 'name']);

  @override
  void initState() {
    super.initState();
    
    // Shared data source
    dtDepartments.addRow(['it', 'Công nghệ thông tin']);
    dtDepartments.addRow(['hr', 'Nhân sự']);
    dtDepartments.addRow(['sales', 'Kinh doanh']);
    dtDepartments.addRow(['finance', 'Tài chính']);
    
    drEmployee['current_dept'] = 'it';
    drEmployee['previous_dept'] = null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberComboBox(
          text: drEmployee.bind('current_dept'),
          dataSource: dtDepartments, // Shared
          valueMember: 'id',
          displayMember: 'name',
          label: 'Phòng ban hiện tại',
        ),
        
        SizedBox(height: 16),
        
        CyberComboBox(
          text: drEmployee.bind('previous_dept'),
          dataSource: dtDepartments, // Shared
          valueMember: 'id',
          displayMember: 'name',
          label: 'Phòng ban trước đây',
          hint: 'Không có',
        ),
      ],
    );
  }
}
```

### 10. Sử Dụng Controller (Advanced)

Khi cần programmatic control.

```dart
class AdvancedComboForm extends StatefulWidget {
  @override
  State<AdvancedComboForm> createState() => _AdvancedComboFormState();
}

class _AdvancedComboFormState extends State<AdvancedComboForm> {
  final controller = CyberComboBoxController();
  final dtCountries = CyberDataTable(columns: ['code', 'name']);

  @override
  void initState() {
    super.initState();
    
    // Load data
    dtCountries.addRow(['VN', 'Việt Nam']);
    dtCountries.addRow(['US', 'Hoa Kỳ']);
    dtCountries.addRow(['JP', 'Nhật Bản']);
    
    // Configure controller
    controller.setDataSource(dtCountries);
    controller.setValueMember('code');
    controller.setDisplayMember('name');
    controller.setValue('VN');
    
    // Listen to changes
    controller.addListener(() {
      print('Country changed: ${controller.value}');
      print('Display text: ${controller.getDisplayText()}');
      
      // Get selected row
      final row = controller.getSelectedRow();
      if (row != null) {
        print('Selected: ${row['name']}');
      }
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void selectVietnam() {
    controller.setValue('VN');
  }

  void clearSelection() {
    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberComboBox(
          controller: controller,
          label: 'Quốc gia',
          hint: 'Chọn quốc gia',
        ),
        
        SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: CyberButton(
                label: 'Chọn Việt Nam',
                onClick: selectVietnam,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: CyberButton(
                label: 'Xóa',
                onClick: clearSelection,
                backgroundColor: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
```

---

## Features

### 1. Internal Controller

Widget tự động quản lý state.

```dart
// ✅ GOOD: Simple binding
CyberComboBox(
  text: drOrder.bind('customer_id'),
  dataSource: dtCustomers,
  valueMember: 'id',
  displayMember: 'name',
)
```

### 2. Two-Way Binding

Tự động sync UI ↔ Data Row.

```dart
// Change in UI → Update data row
// Change in data row → Update UI

drOrder['customer_id'] = '001'; // UI updates
// User selects → drOrder['customer_id'] updates
```

### 3. Type Preservation

Giữ nguyên kiểu dữ liệu.

```dart
// String
drOrder['customer_id'] = "001";
// → User selects → still String

// Integer
drProduct['category_id'] = 1;
// → User selects → still int
```

### 4. iOS-Style Picker

Bottom sheet với CupertinoPicker.

- Smooth scrolling
- Selected item highlighted
- "Hủy" / "Xong" buttons
- Keyboard safe area

### 5. Display/Value Members

Tách riêng giá trị và text hiển thị.

```dart
// Value: "001"
// Display: "Nguyễn Văn A"

dtCustomers.addRow(['001', 'Nguyễn Văn A']);

CyberComboBox(
  valueMember: 'ma_kh',    // "001"
  displayMember: 'ten_kh', // "Nguyễn Văn A"
)
```

### 6. DataTable Integration

Seamless với CyberDataTable.

```dart
final dt = CyberDataTable(columns: ['id', 'name']);
dt.addRow(['001', 'Option 1']);

// Auto update UI when data changes
dt[0]['name'] = 'Updated Option 1';
```

### 7. Visibility Binding

```dart
CyberComboBox(
  isVisible: drSettings.bind('show_advanced'),
  ...
)
```

---

## Best Practices

### 1. Sử Dụng Binding (Recommended)

```dart
// ✅ GOOD: Clean, auto-sync
CyberComboBox(
  text: drOrder.bind('customer_id'),
  dataSource: dtCustomers,
  valueMember: 'id',
  displayMember: 'name',
)

// ❌ BAD: Manual management
String? selectedId;
CyberComboBox(
  text: selectedId,
  onChanged: (value) {
    setState(() {
      selectedId = value;
      drOrder['customer_id'] = value;
    });
  },
)
```

### 2. DataSource Structure

```dart
// ✅ GOOD: Clear column names
final dtCustomers = CyberDataTable(
  columns: ['id', 'name', 'email'],
);

// ✅ GOOD: Consistent data types
dtCustomers.addRow(['001', 'John Doe', 'john@example.com']);
dtCustomers.addRow(['002', 'Jane Smith', 'jane@example.com']);

// ❌ BAD: Inconsistent types
dtCustomers.addRow([1, 'John', 'email']); // Mixed types
```

### 3. Label & Hint

```dart
// ✅ GOOD: Clear, helpful
CyberComboBox(
  label: 'Khách hàng',
  hint: 'Chọn khách hàng',
  ...
)

// ❌ BAD: Vague
CyberComboBox(
  label: 'Combo',
  hint: 'Chọn',
  ...
)
```

### 4. Validation

```dart
// ✅ GOOD: Validate on submit
void submit() {
  if (drOrder['customer_id'] == null) {
    showError('Vui lòng chọn khách hàng');
    return;
  }
  
  // Proceed
}

// ✅ GOOD: Validate on change
CyberComboBox(
  onChanged: (value) {
    if (value == 'special_option') {
      showWarning('Lựa chọn này cần phê duyệt');
    }
  },
)
```

### 5. Loading State

```dart
// ✅ GOOD: Show loading
if (isLoading) {
  return Center(child: CircularProgressIndicator());
}

return CyberComboBox(
  dataSource: dtCategories,
  ...
);

// ❌ BAD: No feedback
CyberComboBox(
  dataSource: dtCategories, // May be empty while loading
  ...
)
```

---

## Troubleshooting

### ComboBox không hiển thị options

**Nguyên nhân:**
1. DataSource null hoặc empty
2. displayMember/valueMember sai tên field
3. Data chưa load xong

**Giải pháp:**
```dart
// 1. Check dataSource
print('Rows: ${dtCustomers.rowCount}');

// 2. Verify field names
print('Columns: ${dtCustomers.columns}');

// 3. Wait for data
if (isLoading) return CircularProgressIndicator();
```

### Giá trị không update vào data row

**Nguyên nhân:** Không dùng binding

**Giải pháp:**
```dart
// ✅ CORRECT: Use binding
CyberComboBox(
  text: drOrder.bind('customer_id'),
  ...
)

// ❌ WRONG: Direct value
CyberComboBox(
  text: drOrder['customer_id'], // Won't sync
  ...
)
```

### Display text không đúng

**Nguyên nhân:** Sai displayMember hoặc valueMember

**Giải pháp:**
```dart
// Check data
for (int i = 0; i < dtCustomers.rowCount; i++) {
  print(dtCustomers[i]);
}

// Verify members
CyberComboBox(
  valueMember: 'id',    // Must match column name
  displayMember: 'name', // Must match column name
  ...
)
```

### Type mismatch error

**Nguyên nhân:** Inconsistent types trong DataTable

**Giải pháp:**
```dart
// ✅ CORRECT: Consistent types
dtCustomers.addRow(['001', 'John']);  // String, String
dtCustomers.addRow(['002', 'Jane']);  // String, String

// ❌ WRONG: Mixed types
dtCustomers.addRow([1, 'John']);   // int, String
dtCustomers.addRow(['002', 'Jane']); // String, String
```

### Picker không hiển thị

**Nguyên nhân:**
1. Widget disabled
2. DataSource empty
3. Context invalid

**Giải pháp:**
```dart
// Check enabled
CyberComboBox(
  enabled: true, // Make sure it's true
  ...
)

// Check data
if (dtCustomers.rowCount == 0) {
  print('No data!');
}
```

### Cascading combo không update

**Nguyên nhân:** Không clear child values

**Giải pháp:**
```dart
void onMasterChanged() {
  // Clear dependent fields
  drAddress['district_id'] = null;
  drAddress['ward_id'] = null;
  
  // Update child data sources
  updateChildDataSource();
  
  setState(() {});
}
```

---

## Tips & Tricks

### 1. Search/Filter Options

```dart
class SearchableCombo extends StatefulWidget {
  @override
  State<SearchableCombo> createState() => _SearchableComboState();
}

class _SearchableComboState extends State<SearchableCombo> {
  final dtAll = CyberDataTable(columns: ['id', 'name']);
  final dtFiltered = CyberDataTable(columns: ['id', 'name']);
  final searchController = TextEditingController();

  void filterData(String query) {
    dtFiltered.clear();
    
    for (int i = 0; i < dtAll.rowCount; i++) {
      final row = dtAll[i];
      final name = row['name'].toString().toLowerCase();
      
      if (name.contains(query.toLowerCase())) {
        dtFiltered.addRow([row['id'], row['name']]);
      }
    }
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: searchController,
          decoration: InputDecoration(
            labelText: 'Tìm kiếm',
            suffixIcon: Icon(Icons.search),
          ),
          onChanged: filterData,
        ),
        
        CyberComboBox(
          dataSource: dtFiltered,
          valueMember: 'id',
          displayMember: 'name',
        ),
      ],
    );
  }
}
```

### 2. Add "All" Option

```dart
void loadData() {
  dtCategories.clear();
  
  // Add "All" option
  dtCategories.addRow(['', 'Tất cả']);
  
  // Add regular options
  dtCategories.addRow(['001', 'Category 1']);
  dtCategories.addRow(['002', 'Category 2']);
}
```

### 3. Custom Empty Message

```dart
CyberComboBox(
  dataSource: dtCustomers,
  valueMember: 'id',
  displayMember: 'name',
  hint: dtCustomers.rowCount == 0 
    ? 'Không có dữ liệu'
    : 'Chọn khách hàng',
)
```

### 4. Reload Data

```dart
Future<void> reloadCustomers() async {
  setState(() => isLoading = true);
  
  try {
    final data = await api.getCustomers();
    
    dtCustomers.clear();
    for (final item in data) {
      dtCustomers.addRow([item['id'], item['name']]);
    }
  } finally {
    setState(() => isLoading = false);
  }
}

// In UI
IconButton(
  icon: Icon(Icons.refresh),
  onPressed: reloadCustomers,
)
```

### 5. Get Selected Row Details

```dart
CyberComboBox(
  text: drOrder.bind('customer_id'),
  dataSource: dtCustomers,
  valueMember: 'id',
  displayMember: 'name',
  onChanged: (value) {
    // Find selected row
    for (int i = 0; i < dtCustomers.rowCount; i++) {
      final row = dtCustomers[i];
      if (row['id'] == value) {
        print('Selected customer: ${row['name']}');
        print('Email: ${row['email']}');
        break;
      }
    }
  },
)
```

---

## Performance Tips

1. **Reuse DataTable**: Load once, reuse nhiều combo
2. **Limit Rows**: < 100 rows cho smooth scrolling
3. **Lazy Load**: Load data khi cần (on focus)
4. **Cache Data**: Cache API responses
5. **Dispose**: Dispose controllers khi không dùng

---

## Version History

### 1.0.0
- Initial release
- Internal controller
- Two-way binding
- DataTable integration
- iOS-style picker
- Type preservation
- Visibility binding

---

## License

MIT License - CyberFramework
