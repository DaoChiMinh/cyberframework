# CyberComboBox - Hướng Dẫn Sử Dụng

## Giới Thiệu

`CyberComboBox` là iOS-style dropdown select với data binding hai chiều, hiển thị picker sheet khi chọn.

## Properties

| Property | Type | Mặc định | Mô tả |
|----------|------|----------|-------|
| `text` | `dynamic` | `null` | Value binding (giá trị được chọn) |
| `displayMember` | `dynamic` | `null` | Field name để hiển thị |
| `valueMember` | `dynamic` | `null` | Field name cho giá trị |
| `dataSource` | `CyberDataTable?` | `null` | Nguồn dữ liệu danh sách |
| `label` | `String?` | `null` | Label hiển thị phía trên |
| `hint` | `String?` | `null` | Placeholder khi chưa chọn |
| `labelStyle` | `TextStyle?` | `null` | Style cho label |
| `textStyle` | `TextStyle?` | `null` | Style cho text được chọn |
| `icon` | `IconData?` | `null` | Icon hiển thị bên trái |
| `enabled` | `bool` | `true` | Bật/tắt combo box |
| `isVisible` | `dynamic` | `true` | Điều khiển hiển thị |
| `onChanged` | `ValueChanged<dynamic>?` | `null` | Callback khi value thay đổi |
| `onLeaver` | `Function(dynamic)?` | `null` | Callback khi mất focus |
| `iconColor` | `Color?` | `null` | Màu icon |
| `backgroundColor` | `Color?` | `Color(0xFFF5F5F5)` | Màu nền |
| `borderColor` | `Color?` | `null` | Màu viền (deprecated) |
| `isShowLabel` | `bool` | `true` | Hiển thị label |

## Ví Dụ Cơ Bản

### 1. ComboBox Đơn Giản

```dart
final CyberDataRow row = CyberDataRow();
final CyberDataTable cityTable = CyberDataTable(tableName: 'Cities');

@override
void initState() {
  super.initState();
  
  // Setup data
  row['cityId'] = 1;
  
  // Add cities
  cityTable.addRow(CyberDataRow()..setValues({'id': 1, 'name': 'Hà Nội'}));
  cityTable.addRow(CyberDataRow()..setValues({'id': 2, 'name': 'TP.HCM'}));
  cityTable.addRow(CyberDataRow()..setValues({'id': 3, 'name': 'Đà Nẵng'}));
}

CyberComboBox(
  text: row.bind('cityId'),
  displayMember: 'name',    // Hiển thị tên thành phố
  valueMember: 'id',        // Giá trị là ID
  dataSource: cityTable,
  label: 'Thành phố',
  hint: 'Chọn thành phố',
)
```

### 2. ComboBox Với Icon

```dart
CyberComboBox(
  text: row.bind('gender'),
  displayMember: 'label',
  valueMember: 'value',
  dataSource: genderTable,
  label: 'Giới tính',
  icon: Icons.person,
  iconColor: Colors.blue,
)
```

### 3. Dynamic DisplayMember & ValueMember

```dart
final CyberDataRow config = CyberDataRow();
config['displayField'] = 'name';
config['valueField'] = 'id';

CyberComboBox(
  text: row.bind('selectedValue'),
  displayMember: config.bind('displayField'), // ✅ Binding
  valueMember: config.bind('valueField'),     // ✅ Binding
  dataSource: dataTable,
  label: 'Chọn mục',
)
```

### 4. Form Hoàn Chỉnh

```dart
class UserForm extends StatefulWidget {
  @override
  State<UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  final CyberDataRow row = CyberDataRow();
  late CyberDataTable cityTable;
  late CyberDataTable districtTable;

  @override
  void initState() {
    super.initState();
    
    row['cityId'] = null;
    row['districtId'] = null;
    
    // Setup cities
    cityTable = CyberDataTable(tableName: 'Cities');
    cityTable.addRow(CyberDataRow()..setValues({'id': 1, 'name': 'Hà Nội'}));
    cityTable.addRow(CyberDataRow()..setValues({'id': 2, 'name': 'TP.HCM'}));
    
    // Setup districts
    districtTable = CyberDataTable(tableName: 'Districts');
    _loadDistricts(null);
  }

  void _loadDistricts(int? cityId) {
    districtTable.clear();
    if (cityId == 1) {
      districtTable.addRow(CyberDataRow()..setValues({
        'id': 11, 'name': 'Ba Đình', 'cityId': 1
      }));
      districtTable.addRow(CyberDataRow()..setValues({
        'id': 12, 'name': 'Hoàn Kiếm', 'cityId': 1
      }));
    } else if (cityId == 2) {
      districtTable.addRow(CyberDataRow()..setValues({
        'id': 21, 'name': 'Quận 1', 'cityId': 2
      }));
      districtTable.addRow(CyberDataRow()..setValues({
        'id': 22, 'name': 'Quận 3', 'cityId': 2
      }));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberComboBox(
          text: row.bind('cityId'),
          displayMember: 'name',
          valueMember: 'id',
          dataSource: cityTable,
          label: 'Thành phố',
          icon: Icons.location_city,
          onChanged: (value) {
            // Reset district khi đổi city
            setState(() {
              row['districtId'] = null;
              _loadDistricts(value);
            });
          },
        ),
        
        SizedBox(height: 16),
        
        CyberComboBox(
          text: row.bind('districtId'),
          displayMember: 'name',
          valueMember: 'id',
          dataSource: districtTable,
          label: 'Quận/Huyện',
          icon: Icons.location_on,
          enabled: row['cityId'] != null, // ✅ Disable nếu chưa chọn city
        ),
        
        SizedBox(height: 24),
        
        ElevatedButton(
          onPressed: () {
            print('City: ${row['cityId']}');
            print('District: ${row['districtId']}');
          },
          child: Text('Submit'),
        ),
      ],
    );
  }
}
```

## Type Preservation

ComboBox tự động giữ nguyên kiểu dữ liệu:

```dart
// Int value
row['status'] = 1; // int
CyberComboBox(
  text: row.bind('status'),
  valueMember: 'value',  // dataSource có value là int
  // ...
)
// Sau khi chọn: row['status'] vẫn là int

// String value
row['code'] = "A01"; // string
CyberComboBox(
  text: row.bind('code'),
  valueMember: 'code',  // dataSource có code là string
  // ...
)
// Sau khi chọn: row['code'] vẫn là string
```

## iOS Picker Sheet

ComboBox hiển thị picker sheet iOS-style với:

- Scroll wheel picker
- Header với nút "Hủy" và "Xong"
- Highlight item được chọn
- Smooth animation

```dart
// Picker tự động mở khi tap vào combo box
CyberComboBox(
  text: row.bind('month'),
  displayMember: 'name',
  valueMember: 'value',
  dataSource: monthTable,
  label: 'Chọn tháng',
)
```

## Visibility & Disabled State

```dart
final CyberDataRow row = CyberDataRow();
row['showCombo'] = true;
row['enableCombo'] = true;

CyberComboBox(
  text: row.bind('value'),
  dataSource: dataTable,
  displayMember: 'name',
  valueMember: 'id',
  isVisible: row.bind('showCombo'),  // ✅ Conditional visibility
  enabled: row['enableCombo'] as bool,
)
```

## Custom Styling

```dart
CyberComboBox(
  text: row.bind('category'),
  displayMember: 'name',
  valueMember: 'id',
  dataSource: categoryTable,
  label: 'Danh mục',
  backgroundColor: Colors.blue.shade50,
  iconColor: Colors.blue,
  labelStyle: TextStyle(
    fontSize: 16,
    color: Colors.blue.shade700,
    fontWeight: FontWeight.bold,
  ),
  textStyle: TextStyle(
    fontSize: 16,
    color: Colors.blue.shade900,
    fontWeight: FontWeight.w600,
  ),
)
```

## DataSource Changes

ComboBox tự động cập nhật khi dataSource thay đổi:

```dart
CyberDataTable productTable = CyberDataTable(tableName: 'Products');

// Initial load
productTable.addRow(CyberDataRow()..setValues({'id': 1, 'name': 'Product 1'}));

CyberComboBox(
  text: row.bind('productId'),
  displayMember: 'name',
  valueMember: 'id',
  dataSource: productTable, // ✅ Listens to changes
  label: 'Sản phẩm',
)

// Add more products later
productTable.addRow(CyberDataRow()..setValues({'id': 2, 'name': 'Product 2'}));
// ComboBox tự động cập nhật danh sách
```

## Use Cases

### 1. Country & State Selection

```dart
CyberComboBox(
  text: row.bind('countryId'),
  displayMember: 'name',
  valueMember: 'id',
  dataSource: countryTable,
  label: 'Quốc gia',
  icon: Icons.flag,
  onChanged: (value) {
    loadStates(value);
  },
)
```

### 2. Category Filter

```dart
CyberComboBox(
  text: row.bind('categoryFilter'),
  displayMember: 'label',
  valueMember: 'value',
  dataSource: filterTable,
  hint: 'Tất cả danh mục',
  onChanged: (value) {
    filterProducts(value);
  },
)
```

### 3. Status Selection

```dart
final statusTable = CyberDataTable(tableName: 'Status');
statusTable.addRow(CyberDataRow()..setValues({'id': 0, 'name': 'Chờ xử lý'}));
statusTable.addRow(CyberDataRow()..setValues({'id': 1, 'name': 'Đang xử lý'}));
statusTable.addRow(CyberDataRow()..setValues({'id': 2, 'name': 'Hoàn thành'}));

CyberComboBox(
  text: row.bind('status'),
  displayMember: 'name',
  valueMember: 'id',
  dataSource: statusTable,
  label: 'Trạng thái',
)
```

## Tips & Best Practices

### ✅ DO

```dart
// ✅ Always provide displayMember & valueMember
CyberComboBox(
  displayMember: 'name',
  valueMember: 'id',
  // ...
)

// ✅ Use meaningful field names
dataRow.setValues({
  'id': 1,           // valueMember
  'name': 'Item 1',  // displayMember
});

// ✅ Handle null selection
row['selectedId'] = null; // OK, hiển thị hint
```

### ❌ DON'T

```dart
// ❌ Không quên set displayMember & valueMember
CyberComboBox(
  dataSource: table,
  // Missing displayMember & valueMember!
)

// ❌ Không dùng field không tồn tại
CyberComboBox(
  displayMember: 'wrongField', // Field không có trong table
  valueMember: 'id',
  dataSource: table,
)
```

## Troubleshooting

### Vấn đề: ComboBox không hiển thị text

**Giải pháp**: Kiểm tra displayMember & valueMember

```dart
// ✅ Debug
print('DataSource rows: ${table.rowCount}');
print('First row: ${table[0].values}');
print('DisplayMember: $displayMember');
print('ValueMember: $valueMember');
```

### Vấn đề: Value không update

**Giải pháp**: Kiểm tra binding

```dart
// ✅ Correct
CyberComboBox(text: row.bind('field'))

// ❌ Wrong
CyberComboBox(text: someVariable)
```

### Vấn đề: Picker không mở

**Giải pháp**: Kiểm tra dataSource và members

```dart
// DataSource phải có dữ liệu
// displayMember và valueMember phải hợp lệ
if (table.rowCount == 0) {
  print('DataSource is empty!');
}
```

---

## Xem Thêm

- [CyberLookup](./CyberLookup.md) - Lookup control với search
- [CyberDataTable](./CyberDataTable.md) - Data table system
- [CyberDataRow](./CyberDataRow.md) - Data binding system
