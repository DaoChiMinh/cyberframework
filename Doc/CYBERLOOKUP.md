# CyberLookup - Lookup Control với Data Binding

## Mục Lục
1. [Giới Thiệu](#giới-thiệu)
2. [CyberLookup Widget](#cyberlookup-widget)
3. [CyberLookupController](#cyberlookupcontroller)
4. [Ví Dụ Sử Dụng](#ví-dụ-sử-dụng)
5. [Features](#features)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

---

## Giới Thiệu

`CyberLookup` là lookup control với **Internal Controller** và **Data Binding** hai chiều. Widget này kết nối với backend để load danh sách dữ liệu với paging, search, và multi-select support.

### Đặc Điểm Chính

- ✅ **Internal Controller**: Tự động quản lý state
- ✅ **Dual Binding**: Binding cả text value VÀ display value
- ✅ **Backend Integration**: Load data từ API với paging
- ✅ **Virtual Scrolling**: Load thêm data khi scroll
- ✅ **Search**: Debounced search với tối thiểu 4 ký tự
- ✅ **Multi-Select**: Hỗ trợ chọn nhiều items
- ✅ **Auto Reload**: Tự động reload khi filter thay đổi
- ✅ **Clear Button**: Xóa giá trị đã chọn

### Import

```dart
import 'package:cyberframework/cyberframework.dart';
```

---

## CyberLookup Widget

### Constructor

```dart
const CyberLookup({
  super.key,
  this.text,
  this.display,
  this.onChanged,
  this.tbName,
  this.strFilter,
  this.displayField,
  this.displayValue,
  this.lookupPageSize = 50,
  this.label,
  this.hint,
  this.labelStyle,
  this.textStyle,
  this.icon,
  this.enabled = true,
  this.readOnly = false,
  this.allowClear = false,
  this.isShowLabel = true,
  this.isVisible = true,
  this.isCheckEmpty = false,
  this.backgroundColor,
  this.borderColor,
  this.onLeaver,
})
```

### Properties

#### Data Binding

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `text` | `dynamic` | Text value binding (ma_kh) | null |
| `display` | `dynamic` | Display value binding (ten_kh) | null |
| `onChanged` | `ValueChanged<dynamic>?` | Callback khi value thay đổi | null |

**QUAN TRỌNG**: Cần binding CẢ `text` VÀ `display`

#### Lookup Parameters

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `tbName` | `dynamic` | Tên bảng (có thể binding) | null |
| `strFilter` | `dynamic` | Filter string (có thể binding) | null |
| `displayField` | `dynamic` | Tên field hiển thị | null |
| `displayValue` | `dynamic` | Tên field giá trị | null |
| `lookupPageSize` | `int` | Số record mỗi trang | 50 |

#### Display

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `label` | `String?` | Label hiển thị | null |
| `hint` | `String?` | Hint text | "Chọn..." |
| `labelStyle` | `TextStyle?` | Style cho label | null |
| `textStyle` | `TextStyle?` | Style cho text | null |
| `icon` | `IconData?` | Icon prefix | null |
| `allowClear` | `bool` | Hiển thị nút Clear | false |
| `isShowLabel` | `bool` | Hiển thị label | true |

#### State

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `enabled` | `bool` | Enable/disable | true |
| `readOnly` | `bool` | Read-only mode | false |
| `isVisible` | `dynamic` | Hiển thị/ẩn (có thể binding) | true |
| `isCheckEmpty` | `dynamic` | Required field | false |
| `backgroundColor` | `Color?` | Màu nền | Color(0xFFF5F5F5) |
| `borderColor` | `Color?` | Màu border | null |

#### Callbacks

| Property | Type | Mô Tả |
|----------|------|-------|
| `onLeaver` | `Function(dynamic)?` | Khi rời khỏi control |

---

## CyberLookupController

**NOTE**: Controller là **OPTIONAL**. Chỉ dùng cho advanced cases.

### Properties & Methods

```dart
final controller = CyberLookupController(
  initialTextValue: 'KH001',
  initialDisplayValue: 'Khách hàng A',
);

// Properties
dynamic textValue = controller.textValue;
String displayValue = controller.displayValue;
bool enabled = controller.enabled;
bool hasValue = controller.hasValue;

// Set values
controller.setValues(
  textValue: 'KH002',
  displayValue: 'Khách hàng B',
);
controller.clear();

// State
controller.setEnabled(true);
controller.validate();

// Binding
controller.bindText(drEdit, 'ma_kh');
controller.bindDisplay(drEdit, 'ten_kh');
controller.unbindText();
controller.unbindDisplay();

// Lookup params
controller.setLookupParams(
  tbName: 'dmkh',
  strFilter: 'trangthai=1',
);
```

---

## Ví Dụ Sử Dụng

### 1. Sử Dụng Cơ Bản (Recommended)

Simple customer lookup.

```dart
class OrderForm extends StatefulWidget {
  @override
  State<OrderForm> createState() => _OrderFormState();
}

class _OrderFormState extends State<OrderForm> {
  final drOrder = CyberDataRow();

  @override
  void initState() {
    super.initState();
    
    // Initialize empty
    drOrder['ma_kh'] = '';
    drOrder['ten_kh'] = '';
  }

  @override
  Widget build(BuildContext context) {
    return CyberLookup(
      // Dual binding - QUAN TRỌNG!
      text: drOrder.bind('ma_kh'),        // Mã khách hàng
      display: drOrder.bind('ten_kh'),    // Tên khách hàng
      
      // Lookup config
      tbName: 'dmkh',                     // Bảng khách hàng
      displayField: 'ten_kh',             // Field hiển thị
      displayValue: 'ma_kh',              // Field giá trị
      
      // UI
      label: 'Khách hàng',
      hint: 'Chọn khách hàng',
      allowClear: true,
      
      onChanged: (value) {
        print('Selected customer: $value');
      },
    );
  }
}
```

### 2. Với Filter

Lookup với điều kiện lọc.

```dart
class ProductLookup extends StatefulWidget {
  @override
  State<ProductLookup> createState() => _ProductLookupState();
}

class _ProductLookupState extends State<ProductLookup> {
  final drOrder = CyberDataRow();

  @override
  void initState() {
    super.initState();
    
    drOrder['ma_sp'] = '';
    drOrder['ten_sp'] = '';
  }

  @override
  Widget build(BuildContext context) {
    return CyberLookup(
      text: drOrder.bind('ma_sp'),
      display: drOrder.bind('ten_sp'),
      
      tbName: 'dmsanpham',
      displayField: 'ten_sp',
      displayValue: 'ma_sp',
      
      // Filter: Chỉ lấy sản phẩm còn hàng
      strFilter: 'ton_kho > 0 and trangthai = 1',
      
      label: 'Sản phẩm',
      allowClear: true,
    );
  }
}
```

### 3. Dynamic Filter (Master-Detail)

Filter thay đổi dựa trên field khác.

```dart
class LocationSelector extends StatefulWidget {
  @override
  State<LocationSelector> createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector> {
  final drAddress = CyberDataRow();

  @override
  void initState() {
    super.initState();
    
    drAddress['ma_tinh'] = '';
    drAddress['ten_tinh'] = '';
    drAddress['ma_quan'] = '';
    drAddress['ten_quan'] = '';
    drAddress['ma_phuong'] = '';
    drAddress['ten_phuong'] = '';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tỉnh/Thành phố
        CyberLookup(
          text: drAddress.bind('ma_tinh'),
          display: drAddress.bind('ten_tinh'),
          tbName: 'dmtinh',
          displayField: 'ten_tinh',
          displayValue: 'ma_tinh',
          label: 'Tỉnh/Thành phố',
          allowClear: true,
          onChanged: (value) {
            // Clear quận/huyện và phường/xã khi đổi tỉnh
            drAddress['ma_quan'] = '';
            drAddress['ten_quan'] = '';
            drAddress['ma_phuong'] = '';
            drAddress['ten_phuong'] = '';
          },
        ),
        
        SizedBox(height: 16),
        
        // Quận/Huyện - Filter theo tỉnh
        CyberLookup(
          text: drAddress.bind('ma_quan'),
          display: drAddress.bind('ten_quan'),
          tbName: 'dmquan',
          displayField: 'ten_quan',
          displayValue: 'ma_quan',
          
          // Dynamic filter - Binding!
          strFilter: drAddress.bind('ma_tinh').transform(
            (value) => value.isEmpty ? '' : "ma_tinh = '$value'",
          ),
          
          label: 'Quận/Huyện',
          allowClear: true,
          enabled: drAddress['ma_tinh'].toString().isNotEmpty,
          onChanged: (value) {
            // Clear phường/xã khi đổi quận
            drAddress['ma_phuong'] = '';
            drAddress['ten_phuong'] = '';
          },
        ),
        
        SizedBox(height: 16),
        
        // Phường/Xã - Filter theo quận
        CyberLookup(
          text: drAddress.bind('ma_phuong'),
          display: drAddress.bind('ten_phuong'),
          tbName: 'dmphuong',
          displayField: 'ten_phuong',
          displayValue: 'ma_phuong',
          
          // Dynamic filter
          strFilter: drAddress.bind('ma_quan').transform(
            (value) => value.isEmpty ? '' : "ma_quan = '$value'",
          ),
          
          label: 'Phường/Xã',
          allowClear: true,
          enabled: drAddress['ma_quan'].toString().isNotEmpty,
        ),
      ],
    );
  }
}
```

### 4. Multi-Select

Chọn nhiều items (backend hỗ trợ).

```dart
class PermissionSelector extends StatefulWidget {
  @override
  State<PermissionSelector> createState() => _PermissionSelectorState();
}

class _PermissionSelectorState extends State<PermissionSelector> {
  final drUser = CyberDataRow();

  @override
  void initState() {
    super.initState();
    
    // Multi-select values separated by ";"
    drUser['ma_quyen'] = '';        // "Q1;Q2;Q3"
    drUser['ten_quyen'] = '';       // "Quyền 1;Quyền 2;Quyền 3"
  }

  @override
  Widget build(BuildContext context) {
    return CyberLookup(
      text: drUser.bind('ma_quyen'),
      display: drUser.bind('ten_quyen'),
      
      // Backend table có column "ischon" → auto multi-select
      tbName: 'dmquyen',
      displayField: 'ten_quyen',
      displayValue: 'ma_quyen',
      
      label: 'Phân quyền',
      hint: 'Chọn quyền',
      allowClear: true,
      
      onChanged: (value) {
        // value là string "Q1;Q2;Q3"
        final permissions = value.toString().split(';');
        print('Selected ${permissions.length} permissions');
      },
    );
  }
}
```

### 5. Read-Only Mode

Hiển thị giá trị nhưng không cho chọn.

```dart
CyberLookup(
  text: drOrder.bind('ma_kh'),
  display: drOrder.bind('ten_kh'),
  
  tbName: 'dmkh',
  displayField: 'ten_kh',
  displayValue: 'ma_kh',
  
  label: 'Khách hàng',
  readOnly: true,  // Không cho chọn
  enabled: true,   // Vẫn hiển thị bình thường
)
```

### 6. Required Field

Field bắt buộc với validation.

```dart
class CustomerForm extends StatefulWidget {
  @override
  State<CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends State<CustomerForm> {
  final drOrder = CyberDataRow();

  bool validateForm() {
    if (drOrder['ma_kh'].toString().isEmpty) {
      showError('Vui lòng chọn khách hàng');
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberLookup(
          text: drOrder.bind('ma_kh'),
          display: drOrder.bind('ten_kh'),
          
          tbName: 'dmkh',
          displayField: 'ten_kh',
          displayValue: 'ma_kh',
          
          label: 'Khách hàng',
          isCheckEmpty: true,  // Hiển thị dấu *
          allowClear: true,
        ),
        
        SizedBox(height: 16),
        
        CyberButton(
          label: 'Lưu',
          onClick: () {
            if (validateForm()) {
              saveOrder();
            }
          },
        ),
      ],
    );
  }
}
```

### 7. Custom Page Size

Tùy chỉnh số records mỗi trang.

```dart
// Large dataset - load nhiều hơn
CyberLookup(
  text: drProduct.bind('ma_sp'),
  display: drProduct.bind('ten_sp'),
  
  tbName: 'dmsanpham',
  displayField: 'ten_sp',
  displayValue: 'ma_sp',
  
  lookupPageSize: 100,  // Load 100 records/page
  
  label: 'Sản phẩm',
)

// Small dataset - load ít
CyberLookup(
  text: drCategory.bind('ma_loai'),
  display: drCategory.bind('ten_loai'),
  
  tbName: 'dmloai',
  displayField: 'ten_loai',
  displayValue: 'ma_loai',
  
  lookupPageSize: 20,  // Load 20 records/page
  
  label: 'Loại sản phẩm',
)
```

### 8. With Icons

Thêm icon để phân biệt.

```dart
Row(
  children: [
    Expanded(
      child: CyberLookup(
        text: drOrder.bind('ma_kh'),
        display: drOrder.bind('ten_kh'),
        tbName: 'dmkh',
        displayField: 'ten_kh',
        displayValue: 'ma_kh',
        label: 'Khách hàng',
        icon: Icons.person,  // Person icon
      ),
    ),
    
    SizedBox(width: 16),
    
    Expanded(
      child: CyberLookup(
        text: drOrder.bind('ma_sp'),
        display: drOrder.bind('ten_sp'),
        tbName: 'dmsanpham',
        displayField: 'ten_sp',
        displayValue: 'ma_sp',
        label: 'Sản phẩm',
        icon: Icons.shopping_bag,  // Product icon
      ),
    ),
  ],
)
```

### 9. Conditional Visibility

Hiển thị/ẩn dựa trên điều kiện.

```dart
class ConditionalLookup extends StatefulWidget {
  @override
  State<ConditionalLookup> createState() => _ConditionalLookupState();
}

class _ConditionalLookupState extends State<ConditionalLookup> {
  final drOrder = CyberDataRow();

  @override
  void initState() {
    super.initState();
    
    drOrder['loai_don'] = 'retail';  // retail or wholesale
    drOrder['ma_kh'] = '';
    drOrder['ten_kh'] = '';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberComboBox(
          text: drOrder.bind('loai_don'),
          label: 'Loại đơn hàng',
          items: ['retail', 'wholesale'],
        ),
        
        SizedBox(height: 16),
        
        // Chỉ hiện khi loại_don = 'wholesale'
        CyberLookup(
          text: drOrder.bind('ma_kh'),
          display: drOrder.bind('ten_kh'),
          
          tbName: 'dmkh',
          displayField: 'ten_kh',
          displayValue: 'ma_kh',
          
          label: 'Đại lý bán buôn',
          
          // Visibility binding
          isVisible: drOrder.bind('loai_don').transform(
            (value) => value == 'wholesale',
          ),
        ),
      ],
    );
  }
}
```

### 10. Callback Usage

Xử lý sau khi chọn.

```dart
class SmartLookup extends StatefulWidget {
  @override
  State<SmartLookup> createState() => _SmartLookupState();
}

class _SmartLookupState extends State<SmartLookup> {
  final drOrder = CyberDataRow();

  Future<void> loadCustomerDetails(String customerId) async {
    // Load thêm thông tin khách hàng
    final response = await api.getCustomer(customerId);
    
    if (response.isValid()) {
      final data = response.data;
      
      // Auto-fill các field khác
      drOrder['dien_thoai'] = data['phone'];
      drOrder['dia_chi'] = data['address'];
      drOrder['email'] = data['email'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberLookup(
          text: drOrder.bind('ma_kh'),
          display: drOrder.bind('ten_kh'),
          
          tbName: 'dmkh',
          displayField: 'ten_kh',
          displayValue: 'ma_kh',
          
          label: 'Khách hàng',
          allowClear: true,
          
          onChanged: (value) async {
            if (value != null && value.toString().isNotEmpty) {
              await loadCustomerDetails(value.toString());
            }
          },
          
          onLeaver: (value) {
            print('Leaver event: $value');
          },
        ),
        
        SizedBox(height: 16),
        
        // Auto-filled fields
        CyberText(
          text: drOrder.bind('dien_thoai'),
          label: 'Điện thoại',
          enabled: false,
        ),
        
        CyberText(
          text: drOrder.bind('dia_chi'),
          label: 'Địa chỉ',
          enabled: false,
        ),
      ],
    );
  }
}
```

---

## Features

### 1. Dual Binding

Binding cả text value VÀ display value.

```dart
CyberLookup(
  text: dr.bind('ma_kh'),      // Value
  display: dr.bind('ten_kh'),  // Display
)
```

### 2. Virtual Paging

Load data theo trang, scroll để load thêm.

- Page size: 50 (default)
- Load more at 90% scroll
- Smooth scrolling

### 3. Search

Debounced search với điều kiện:

- Tối thiểu 4 ký tự
- Debounce 800ms
- Clear để reset

### 4. Multi-Select

Tự động phát hiện nếu backend table có column "ischon":

- Checkbox list
- Confirm button
- Return values separated by ";"

### 5. Auto Reload

Tự động reload khi:

- strFilter thay đổi (binding)
- tbName thay đổi (binding)
- Pull to refresh

### 6. Filter Binding

Filter có thể binding động:

```dart
strFilter: drFilter.bind('condition')
```

### 7. Clear Button

```dart
allowClear: true
```

---

## Best Practices

### 1. Dual Binding (REQUIRED)

```dart
// ✅ GOOD: Bind cả 2
CyberLookup(
  text: dr.bind('ma_kh'),
  display: dr.bind('ten_kh'),
  ...
)

// ❌ BAD: Chỉ bind 1
CyberLookup(
  text: dr.bind('ma_kh'),
  // Missing display binding!
)
```

### 2. Table Configuration

```dart
// ✅ GOOD: Rõ ràng
CyberLookup(
  tbName: 'dmkh',
  displayField: 'ten_kh',     // Tên cột hiển thị
  displayValue: 'ma_kh',      // Tên cột giá trị
)

// ❌ BAD: Không rõ
CyberLookup(
  tbName: 'dmkh',
  displayField: 'ten',  // Tên cột không chuẩn
  displayValue: 'ma',
)
```

### 3. Filter Syntax

```dart
// ✅ GOOD: SQL WHERE clause
strFilter: "trangthai = 1 and ton_kho > 0"

// ✅ GOOD: Dynamic
strFilter: drFilter.bind('condition')

// ❌ BAD: Invalid SQL
strFilter: "status is active"
```

### 4. Master-Detail Pattern

```dart
// ✅ GOOD: Clear child when parent changes
CyberLookup(
  text: dr.bind('ma_tinh'),
  display: dr.bind('ten_tinh'),
  onChanged: (value) {
    // Clear child
    dr['ma_quan'] = '';
    dr['ten_quan'] = '';
  },
)
```

### 5. Page Size

```dart
// ✅ GOOD: Appropriate size
lookupPageSize: 50   // Default

// ✅ GOOD: Large dataset
lookupPageSize: 100

// ❌ BAD: Too small (many requests)
lookupPageSize: 10

// ❌ BAD: Too large (slow)
lookupPageSize: 1000
```

---

## Troubleshooting

### Không load data

**Nguyên nhân:**
1. Sai tên bảng
2. Sai tên field
3. Backend API lỗi

**Giải pháp:**
```dart
// Check parameters
print('tbName: ${widget.tbName}');
print('displayField: ${widget.displayField}');
print('displayValue: ${widget.displayValue}');

// Check API response
// Function: CP_W10SysListoDir
// Parameter: "page#pageSize#search#filter#table##"
```

### Display value không update

**Nguyên nhân:** Không bind display

**Giải pháp:**
```dart
// ✅ MUST bind display
CyberLookup(
  text: dr.bind('ma_kh'),
  display: dr.bind('ten_kh'),  // Required!
)
```

### Filter không hoạt động

**Nguyên nhân:** Sai SQL syntax

**Giải pháp:**
```dart
// ✅ CORRECT SQL WHERE clause
strFilter: "status = 1"
strFilter: "created_date >= '2024-01-01'"
strFilter: "category_id in (1,2,3)"

// ❌ WRONG
strFilter: "status is 1"  // Not SQL!
```

### Multi-select không hiện

**Nguyên nhân:** Backend table không có column "ischon"

**Giải pháp:**
```sql
-- Add column to table
ALTER TABLE dmquyen ADD COLUMN ischon BIT DEFAULT 0;
```

### Search chậm

**Nguyên nhân:** Backend không index

**Giải pháp:**
```sql
-- Add index to search columns
CREATE INDEX idx_dmkh_ten ON dmkh(ten_kh);
```

---

## Tips & Tricks

### 1. Clear Related Fields

```dart
onChanged: (value) {
  // Clear related fields
  dr['field2'] = '';
  dr['field3'] = '';
}
```

### 2. Validate Before Submit

```dart
bool validate() {
  if (dr['ma_kh'].toString().isEmpty) {
    showError('Vui lòng chọn khách hàng');
    return false;
  }
  return true;
}
```

### 3. Split Multi-Select Values

```dart
String selectedIds = dr['ma_quyen'];  // "Q1;Q2;Q3"
List<String> ids = selectedIds.split(';');

print('Selected ${ids.length} permissions');
```

### 4. Dynamic Table Name

```dart
// Table name có thể binding
CyberLookup(
  tbName: drConfig.bind('lookup_table'),
  ...
)
```

### 5. Conditional Filter

```dart
String buildFilter() {
  List<String> conditions = [];
  
  if (includeActive) {
    conditions.add('status = 1');
  }
  
  if (categoryId.isNotEmpty) {
    conditions.add("category_id = '$categoryId'");
  }
  
  return conditions.join(' and ');
}

CyberLookup(
  strFilter: buildFilter(),
  ...
)
```

---

## Performance Tips

1. **Index Database**: Add indexes to searchable columns
2. **Appropriate Page Size**: 50-100 for most cases
3. **Filter Early**: Use strFilter to reduce data
4. **Cache Results**: Backend should cache common lookups
5. **Debounced Search**: 800ms delay reduces API calls

---

## Backend API

### Function: CP_W10SysListoDir

**Parameters:**
```
pageIndex#pageSize#searchText#filter#tableName##
```

**Example:**
```
0#50#nguyen#status=1#dmkh##
```

**Response:**
```dart
CyberDataset with:
- DataTable[0]: Records
  - Columns: All table columns + optional "ischon"
  - Rows: Paged data
```

**Multi-Select:**
```dart
// If table has "ischon" column → Multi-select mode
// Return: "value1;value2;value3"
```

---

## Version History

### 1.0.0
- Initial release
- Internal controller
- Dual binding (text + display)
- Virtual paging
- Search with debounce
- Multi-select support
- Dynamic filter binding
- Auto reload on filter change

---

## License

MIT License - CyberFramework
