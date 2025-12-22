# CyberLookup - Hướng Dẫn Sử Dụng

## Giới Thiệu

`CyberLookup` là search & select control với API integration, hỗ trợ search server-side, multi-select, và data binding.

## Properties

| Property | Type | Mô tả |
|----------|------|-------|
| `text` | `dynamic` | Value binding (ID được chọn) |
| `display` | `dynamic` | Display binding (text hiển thị) |
| `tbName` | `dynamic` | Tên table/API endpoint |
| `strFilter` | `dynamic` | Filter string cho API |
| `displayField` | `dynamic` | Field name để hiển thị |
| `displayValue` | `dynamic` | Field name cho giá trị (ID) |
| `label` | `String?` | Label hiển thị phía trên |
| `hint` | `String?` | Placeholder |
| `labelStyle` | `TextStyle?` | Style cho label |
| `textStyle` | `TextStyle?` | Style cho display text |
| `icon` | `IconData?` | Icon |
| `enabled` | `bool` | Bật/tắt |
| `isVisible` | `dynamic` | Điều khiển hiển thị |
| `isShowLabel` | `bool` | Hiển thị label |
| `backgroundColor` | `Color?` | Màu nền |
| `onLeaver` | `Function(dynamic)?` | Callback khi chọn item |
| `onChanged` | `ValueChanged<dynamic>?` | Callback khi value thay đổi |

## Ví Dụ Cơ Bản

### 1. Lookup Đơn Giản

```dart
final CyberDataRow row = CyberDataRow();
row['customerId'] = null;      // Value (ID)
row['customerName'] = '';      // Display text

CyberLookup(
  text: row.bind('customerId'),
  display: row.bind('customerName'),
  tbName: 'DM_Customer',
  strFilter: '',
  displayField: 'custname',     // Hiển thị tên
  displayValue: 'custid',       // Giá trị là ID
  label: 'Khách hàng',
  hint: 'Chọn khách hàng...',
  icon: Icons.person,
)
```

### 2. Lookup Với Filter

```dart
// Filter theo type
CyberLookup(
  text: row.bind('productId'),
  display: row.bind('productName'),
  tbName: 'DM_Product',
  strFilter: 'type=1',  // Static filter
  displayField: 'name',
  displayValue: 'id',
  label: 'Sản phẩm',
)

// Filter dynamic binding
row['category'] = 'Electronics';

CyberLookup(
  text: row.bind('productId'),
  display: row.bind('productName'),
  tbName: 'DM_Product',
  strFilter: row.bind('category'),  // ✅ Dynamic filter
  displayField: 'name',
  displayValue: 'id',
  label: 'Sản phẩm',
)
```

### 3. Multi-Select Lookup

```dart
// Nếu API trả về có field 'ischon', tự động bật multi-select
CyberLookup(
  text: row.bind('selectedIds'),      // "1;2;3"
  display: row.bind('selectedNames'), // "Item 1;Item 2;Item 3"
  tbName: 'DM_Items',
  strFilter: '',
  displayField: 'name',
  displayValue: 'id',
  label: 'Chọn nhiều mục',
  // ✅ Tự động hiện checkbox nếu có 'ischon' field
)
```

### 4. Form Hoàn Chỉnh

```dart
class OrderForm extends StatefulWidget {
  @override
  State<OrderForm> createState() => _OrderFormState();
}

class _OrderFormState extends State<OrderForm> {
  final CyberDataRow row = CyberDataRow();

  @override
  void initState() {
    super.initState();
    row['customerId'] = null;
    row['customerName'] = '';
    row['productId'] = null;
    row['productName'] = '';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberLookup(
          text: row.bind('customerId'),
          display: row.bind('customerName'),
          tbName: 'DM_Customer',
          strFilter: '',
          displayField: 'name',
          displayValue: 'id',
          label: 'Khách hàng',
          icon: Icons.person,
          onLeaver: (selectedRow) {
            if (selectedRow is CyberDataRow) {
              print('Selected customer: ${selectedRow['name']}');
            }
          },
        ),
        
        SizedBox(height: 16),
        
        CyberLookup(
          text: row.bind('productId'),
          display: row.bind('productName'),
          tbName: 'DM_Product',
          strFilter: '',
          displayField: 'name',
          displayValue: 'id',
          label: 'Sản phẩm',
          icon: Icons.shopping_bag,
        ),
        
        SizedBox(height: 24),
        
        ElevatedButton(
          onPressed: () {
            print('Customer ID: ${row['customerId']}');
            print('Customer Name: ${row['customerName']}');
            print('Product ID: ${row['productId']}');
            print('Product Name: ${row['productName']}');
          },
          child: Text('Tạo đơn hàng'),
        ),
      ],
    );
  }
}
```

## API Integration

### Request Format

```dart
// Gọi API với parameters:
context.callApi(
  functionName: "CP_W10SysListoDir",
  parameter: "1#0#$searchText#$strFilter#$tbName#01#dungnt",
)
```

### Response Format

API cần trả về `CyberDataset` với structure:

```json
{
  "Tables": [
    {
      "Rows": [
        {
          "id": "001",
          "name": "Customer A",
          "phone": "0123456789",
          "ischon": false  // Optional: enable checkbox
        },
        {
          "id": "002",
          "name": "Customer B",
          "phone": "0987654321",
          "ischon": false
        }
      ]
    }
  ]
}
```

## Search Functionality

### Auto Search

```dart
// Search tự động trigger sau 800ms khi:
// - Nhập ít nhất 4 ký tự
// - Hoặc xóa hết (empty string)

CyberLookup(
  text: row.bind('customerId'),
  display: row.bind('customerName'),
  tbName: 'DM_Customer',
  displayField: 'name',
  displayValue: 'id',
  // ✅ Type để search
)
```

### Search Debounce

```dart
// Debounce: 800ms
// Minimum characters: 4 (hoặc empty)

void _onSearch(String value) {
  Future.delayed(Duration(milliseconds: 800), () {
    if (_searchController.text == value && 
        (value == "" || value.length > 3)) {
      _loadData(searchText: value);
    }
  });
}
```

## Multi-Select Mode

### Kích Hoạt

Multi-select tự động kích hoạt khi API response có field `ischon`:

```json
{
  "Rows": [
    {
      "id": "1",
      "name": "Item 1",
      "ischon": false  // ✅ Enable multi-select
    }
  ]
}
```

### Value Format

```dart
// Single select
row['id'] = "001";
row['name'] = "Customer A";

// Multi-select (separated by semicolon)
row['ids'] = "001;002;003";
row['names'] = "Customer A;Customer B;Customer C";
```

### Confirm Button

```dart
// Multi-select mode hiển thị nút "Xác nhận"
// với count: "Xác nhận (3)"
```

## Use Cases

### 1. Customer Selection

```dart
CyberLookup(
  text: row.bind('customerId'),
  display: row.bind('customerName'),
  tbName: 'DM_Customer',
  strFilter: 'active=1',  // Only active customers
  displayField: 'fullname',
  displayValue: 'custid',
  label: 'Khách hàng',
  icon: Icons.person_search,
)
```

### 2. Product Lookup With Category Filter

```dart
// Category dropdown
CyberComboBox(
  text: row.bind('categoryId'),
  displayMember: 'name',
  valueMember: 'id',
  dataSource: categoryTable,
  label: 'Danh mục',
)

// Product lookup filtered by category
CyberLookup(
  text: row.bind('productId'),
  display: row.bind('productName'),
  tbName: 'DM_Product',
  strFilter: row.bind('categoryId'),  // ✅ Dynamic filter
  displayField: 'name',
  displayValue: 'id',
  label: 'Sản phẩm',
)
```

### 3. Employee Search

```dart
CyberLookup(
  text: row.bind('employeeId'),
  display: row.bind('employeeName'),
  tbName: 'DM_Employee',
  strFilter: 'department=Sales',
  displayField: 'fullname',
  displayValue: 'empid',
  label: 'Nhân viên',
  icon: Icons.badge,
  onLeaver: (selectedRow) {
    if (selectedRow is CyberDataRow) {
      row['employeeEmail'] = selectedRow['email'];
      row['employeePhone'] = selectedRow['phone'];
    }
  },
)
```

### 4. Multi-Select Tags

```dart
CyberLookup(
  text: row.bind('tagIds'),
  display: row.bind('tagNames'),
  tbName: 'DM_Tags',
  strFilter: '',
  displayField: 'tagname',
  displayValue: 'tagid',
  label: 'Tags',
  hint: 'Chọn nhiều tags...',
  // ✅ API có 'ischon' field → multi-select
)
```

## Tips & Best Practices

### ✅ DO

```dart
// ✅ Use meaningful field names
CyberLookup(
  displayField: 'customer_name',  // Clear
  displayValue: 'customer_id',
)

// ✅ Add filter for better UX
CyberLookup(
  strFilter: 'active=1 AND deleted=0',
)

// ✅ Handle onLeaver for extra data
CyberLookup(
  onLeaver: (row) {
    // Extract additional fields from selected row
    extraData = row['extra_field'];
  },
)
```

### ❌ DON'T

```dart
// ❌ Don't use wrong API endpoint
CyberLookup(
  tbName: 'NonExistentTable',  // Will fail
)

// ❌ Don't forget displayField & displayValue
CyberLookup(
  // Missing displayField/displayValue!
)
```

## Troubleshooting

### Vấn đề: Không load data

**Giải pháp**: Kiểm tra API response

```dart
// Debug trong _LookupBottomSheetState
print('Table name: $tbName');
print('Filter: $strFilter');
print('Response: ${response.toCyberDataset()}');
```

### Vấn đề: Multi-select không hoạt động

**Giải pháp**: Kiểm tra API response có field `ischon`

```json
{
  "Rows": [
    {
      "id": "1",
      "name": "Item 1",
      "ischon": false  // ✅ Required for multi-select
    }
  ]
}
```

### Vấn đề: Search không trigger

**Giải pháp**: Nhập ít nhất 4 ký tự hoặc xóa hết

```dart
// ✅ Will trigger search
searchText = "abcd"  // 4+ characters
searchText = ""      // Empty

// ❌ Won't trigger
searchText = "abc"   // < 4 characters
```

---

## Xem Thêm

- [CyberComboBox](./CyberComboBox.md) - Combo box control
- [CyberListView](./CyberListView.md) - List view với search
- [CyberDataRow](./CyberDataRow.md) - Data binding system
