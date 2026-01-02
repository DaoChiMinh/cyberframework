# CyberText - Binding Expression với CyberDataRow

## 🎯 Overview

CyberText được thiết kế để tương thích hoàn toàn với **CyberDataRow** và **CyberBindingExpression** hiện có trong CyberFramework.

**Cú pháp:**
```dart
final customerRow = CyberDataRow();
customerRow['customerName'] = 'Nguyễn Văn A';

// ⭐ BINDING EXPRESSION - Gọn gàng như WPF/XAML
CyberText(
  text: customerRow.bind('customerName'),
  label: 'Tên khách hàng',
  isCheckEmpty: true,
)
```

---

## 🚀 Quick Start

### 1. Chuẩn bị Data

```dart
// Tạo DataRow
final customerRow = CyberDataRow();
customerRow['customerName'] = 'Nguyễn Văn A';
customerRow['phone'] = '0901234567';
customerRow['email'] = 'nguyenvana@email.com';
customerRow['address'] = 'Hà Nội';
```

### 2. Binding với UI

```dart
Column(
  children: [
    // Tên khách hàng (required)
    CyberText(
      text: customerRow.bind('customerName'),
      label: 'Tên khách hàng',
      isCheckEmpty: true,
      icon: Icons.person,
    ),
    
    // Số điện thoại (với format)
    CyberText(
      text: customerRow.bind('phone'),
      label: 'Số điện thoại',
      format: 'SĐT: {0}',
      showFormatInField: false,
      keyboardType: TextInputType.phone,
      icon: Icons.phone,
    ),
    
    // Email
    CyberText(
      text: customerRow.bind('email'),
      label: 'Email',
      keyboardType: TextInputType.emailAddress,
      icon: Icons.email,
    ),
    
    // Địa chỉ (multiline)
    CyberText(
      text: customerRow.bind('address'),
      label: 'Địa chỉ',
      maxLines: 3,
      hint: 'Nhập địa chỉ chi tiết',
    ),
  ],
)
```

### 3. Đọc/Ghi Data

```dart
// Đọc data
print('Tên: ${customerRow['customerName']}');
print('Phone: ${customerRow['phone']}');

// Ghi data → UI tự động update!
customerRow['customerName'] = 'Trần Văn B';
customerRow['phone'] = '0987654321';

// Lấy toàn bộ data
Map<String, dynamic> data = customerRow.toMap();
print(data);
```

---

## 📝 3 Modes Sử Dụng

### 1️⃣ **BINDING EXPRESSION MODE** (Khuyên dùng - 90% cases)

**Syntax:**
```dart
CyberText(
  text: row.bind('fieldName'),  // ← CyberBindingExpression
  label: 'Label',
)
```

**Hoặc dùng shorthand:**
```dart
CyberText(
  text: row.$('fieldName'),  // ← Ngắn gọn hơn
  label: 'Label',
)
```

**Full Example:**
```dart
class ProductForm extends StatefulWidget {
  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  late CyberDataRow productRow;

  @override
  void initState() {
    super.initState();
    
    productRow = CyberDataRow();
    productRow['productCode'] = 'SP001';
    productRow['productName'] = '';
    productRow['price'] = '';
  }

  void handleSave() {
    final data = productRow.toMap();
    print('Save: $data');
    // TODO: Call API
  }

  void handleClear() {
    productRow['productName'] = '';
    productRow['price'] = '';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Mã sản phẩm (disabled)
        CyberText(
          text: productRow.bind('productCode'),
          label: 'Mã sản phẩm',
          enabled: false,
          backgroundColor: Colors.grey[100],
        ),
        
        // Tên sản phẩm (required)
        CyberText(
          text: productRow.bind('productName'),
          label: 'Tên sản phẩm',
          isCheckEmpty: true,
          hint: 'Nhập tên sản phẩm',
        ),
        
        // Giá (format)
        CyberText(
          text: productRow.bind('price'),
          label: 'Giá bán',
          format: 'Giá: {0} VNĐ',
          showFormatInField: false,
          keyboardType: TextInputType.number,
        ),
        
        // Action buttons
        Row(
          children: [
            ElevatedButton(onPressed: handleSave, child: Text('Lưu')),
            OutlinedButton(onPressed: handleClear, child: Text('Xóa')),
          ],
        ),
      ],
    );
  }
}
```

**Lợi ích:**
- ✅ Gọn gàng nhất
- ✅ Tự động sync 2 chiều: UI ↔ DataRow
- ✅ Không cần khai báo controller
- ✅ Không cần dispose
- ✅ Type-safe với `CyberBindingExpression`

---

### 2️⃣ **STATIC MODE** (Đơn giản)

**Syntax:**
```dart
CyberText(
  text: 'Static value',  // ← String literal
  onChanged: (value) => print(value),
  label: 'Label',
)
```

**Example:**
```dart
String searchQuery = '';

CyberText(
  text: searchQuery,
  onChanged: (value) {
    setState(() {
      searchQuery = value;
    });
  },
  hint: 'Tìm kiếm...',
  icon: Icons.search,
)
```

**Use cases:**
- Search box
- Login form (không cần persist data)
- Simple input field

---

### 3️⃣ **EXTERNAL CONTROLLER MODE** (Nâng cao)

**Syntax:**
```dart
final controller = CyberTextController(initialValue: 'Hello');

CyberText(
  controller: controller,  // ← External controller
  label: 'Label',
)

// Phải dispose
controller.dispose();
```

**Example - Calculator:**
```dart
class Calculator extends StatefulWidget {
  @override
  State<Calculator> createState() => _CalculatorState();
}

class _CalculatorState extends State<Calculator> {
  late CyberTextController amountCtrl;
  late CyberTextController discountCtrl;
  late CyberTextController finalCtrl;

  @override
  void initState() {
    super.initState();
    
    amountCtrl = CyberTextController(initialValue: '1000000');
    discountCtrl = CyberTextController(initialValue: '10');
    finalCtrl = CyberTextController(enabled: false);
    
    // Lắng nghe và tính toán
    amountCtrl.addListener(_calculate);
    discountCtrl.addListener(_calculate);
    
    _calculate();
  }

  @override
  void dispose() {
    amountCtrl.dispose();
    discountCtrl.dispose();
    finalCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    final amount = double.tryParse(amountCtrl.value ?? '0') ?? 0;
    final discount = double.tryParse(discountCtrl.value ?? '0') ?? 0;
    final result = amount * (1 - discount / 100);
    
    finalCtrl.setValue(result.toStringAsFixed(0));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberText(controller: amountCtrl, label: 'Số tiền'),
        CyberText(controller: discountCtrl, label: 'Giảm giá %'),
        CyberText(controller: finalCtrl, label: 'Thành tiền'),
      ],
    );
  }
}
```

**Use cases:**
- Real-time calculation
- Custom validation logic
- Shared controller giữa nhiều widgets

---

## 🔧 CyberDataRow API

### Tạo và thao tác data

```dart
// Tạo DataRow
final row = CyberDataRow();

// Hoặc với initial data
final row = CyberDataRow({
  'name': 'Nguyễn Văn A',
  'age': 25,
});

// Set/Get value
row['fieldName'] = 'value';
dynamic value = row['fieldName'];

// Type-safe get
String? name = row.get<String>('name');
int? age = row.get<int>('age');

// Check field exists
bool hasName = row.hasField('name');

// Get field names
List<String> fields = row.fieldNames;
```

### Binding expression

```dart
// ⭐ TẠO BINDING (2 cách)

// Cách 1: Method bind()
CyberBindingExpression binding = row.bind('fieldName');

// Cách 2: Shorthand $ (ngắn gọn)
CyberBindingExpression binding = row.$('fieldName');

// Sử dụng trong widget
CyberText(text: row.bind('name'))
CyberText(text: row.$('name'))  // ← Ngắn hơn
```

### Change tracking

```dart
// Check dirty
bool dirty = row.isDirty;

// Get changed fields
Set<String> changed = row.changedFields;

// Accept changes
row.acceptChanges();

// Reject changes (revert)
row.rejectChanges();

// Get original value
dynamic original = row.getOriginal('fieldName');
```

### Batch operations

```dart
// Batch mode - chỉ notify 1 lần
row.batch(() {
  row['field1'] = 'value1';
  row['field2'] = 'value2';
  row['field3'] = 'value3';
});

// Hoặc
row.beginBatch();
row['field1'] = 'value1';
row['field2'] = 'value2';
row.endBatch();  // Notify ở đây
```

### Export data

```dart
// To Map
Map<String, dynamic> map = row.toMap();

// To XML
String xml = row.toXml(
  'Customer',
  includeColumns: ['name', 'phone', 'email'],
);

// Get changed values only
Map<String, dynamic> changed = row.getChangedValues();
```

### Identity management

```dart
// Get identity key (UUID v4)
Object id = row.identityKey;

// Set custom identity
row.setIdentityKey('CUSTOMER_123');

// Lock identity (before binding to UI)
row.lockIdentity();

// Check
bool locked = row.isIdentityLocked;
bool hasCustom = row.hasCustomIdentity;
```

---

## 💡 Ví Dụ Thực Tế

### Form đăng ký khách hàng (Complete)

```dart
class CustomerRegistration extends StatefulWidget {
  @override
  State<CustomerRegistration> createState() => _CustomerRegistrationState();
}

class _CustomerRegistrationState extends State<CustomerRegistration> {
  late CyberDataRow customerRow;

  @override
  void initState() {
    super.initState();
    
    customerRow = CyberDataRow();
    _initData();
  }

  void _initData() {
    customerRow['customerCode'] = 'KH${DateTime.now().millisecondsSinceEpoch}';
    customerRow['fullName'] = '';
    customerRow['phone'] = '';
    customerRow['email'] = '';
    customerRow['address'] = '';
    customerRow['city'] = '';
    customerRow['notes'] = '';
  }

  void _handleSave() {
    // Validate
    if ((customerRow['fullName'] as String?)?.isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng nhập họ tên!')),
      );
      return;
    }

    // Get data
    final data = customerRow.toMap();
    print('Đăng ký: $data');
    
    // TODO: Call API
    // await api.registerCustomer(data);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã đăng ký: ${customerRow['fullName']}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _handleClear() {
    _initData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Đăng ký khách hàng')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Mã khách hàng (auto-gen, disabled)
            CyberText(
              text: customerRow.bind('customerCode'),
              label: 'Mã khách hàng',
              enabled: false,
              backgroundColor: Colors.grey[200],
            ),
            SizedBox(height: 16),

            // Họ tên (required) ⭐
            CyberText(
              text: customerRow.bind('fullName'),
              label: 'Họ và tên',
              isCheckEmpty: true,
              hint: 'Nhập họ tên đầy đủ',
              icon: Icons.person,
            ),
            SizedBox(height: 16),

            // Số điện thoại ⭐
            CyberText(
              text: customerRow.bind('phone'),
              label: 'Số điện thoại',
              format: 'SĐT: {0}',
              showFormatInField: false,
              keyboardType: TextInputType.phone,
              icon: Icons.phone,
            ),
            SizedBox(height: 16),

            // Email ⭐
            CyberText(
              text: customerRow.bind('email'),
              label: 'Email',
              hint: 'example@email.com',
              keyboardType: TextInputType.emailAddress,
              icon: Icons.email,
            ),
            SizedBox(height: 16),

            // Địa chỉ ⭐
            CyberText(
              text: customerRow.bind('address'),
              label: 'Địa chỉ',
              hint: 'Số nhà, tên đường',
              icon: Icons.home,
            ),
            SizedBox(height: 16),

            // Thành phố ⭐
            CyberText(
              text: customerRow.bind('city'),
              label: 'Thành phố',
              hint: 'Hà Nội, TP.HCM...',
              icon: Icons.location_city,
            ),
            SizedBox(height: 16),

            // Ghi chú (multiline) ⭐
            CyberText(
              text: customerRow.bind('notes'),
              label: 'Ghi chú',
              maxLines: 4,
              hint: 'Thông tin bổ sung...',
            ),
            SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _handleSave,
                    icon: Icon(Icons.save),
                    label: Text('Đăng ký'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.all(16),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _handleClear,
                    icon: Icon(Icons.clear),
                    label: Text('Xóa'),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            // Debug info
            Card(
              color: Colors.grey[100],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📊 Debug Info (Real-time)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Divider(),
                    ListenableBuilder(
                      listenable: customerRow,
                      builder: (context, _) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Code: ${customerRow['customerCode']}'),
                            Text('Name: ${customerRow['fullName']}'),
                            Text('Phone: ${customerRow['phone']}'),
                            Text('Email: ${customerRow['email']}'),
                            Text('Dirty: ${customerRow.isDirty}'),
                            if (customerRow.isDirty)
                              Text('Changed: ${customerRow.changedFields}'),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## ✅ Best Practices

### DO

```dart
// ✅ Dùng Binding Expression cho CRUD
CyberText(
  text: row.bind('fieldName'),
  label: 'Label',
)

// ✅ Dùng shorthand $ khi muốn ngắn gọn
CyberText(
  text: row.$('fieldName'),
  label: 'Label',
)

// ✅ Dùng batch khi update nhiều field
row.batch(() {
  row['field1'] = value1;
  row['field2'] = value2;
  row['field3'] = value3;
});

// ✅ Lock identity trước khi bind với ListView
row.lockIdentity();
ListView.builder(
  itemBuilder: (context, index) {
    final row = rows[index];
    return ListTile(key: ValueKey(row.identityKey));
  },
)
```

### DON'T

```dart
// ❌ Đừng mix text và controller
CyberText(
  text: row.bind('name'),
  controller: myController,  // ❌ Conflict!
)

// ❌ Đừng tạo DataRow trong build()
Widget build(BuildContext context) {
  final row = CyberDataRow();  // ❌ Tạo mới mỗi build!
  return CyberText(text: row.bind('name'));
}

// ❌ Đừng quên notifyListeners()
// (Nhưng CyberDataRow đã tự động notify rồi)

// ❌ Đừng dùng onChanged với binding mode
CyberText(
  text: row.bind('name'),
  onChanged: (value) => ...,  // ❌ Không cần!
)
```

---

## 🎉 Kết Luận

**CyberText với Binding Expression:**

✅ **Tương thích** - Hoạt động với CyberDataRow hiện có  
✅ **Gọn gàng** - `text: row.bind('field')` thay vì 2 properties  
✅ **Type-safe** - Dùng `CyberBindingExpression`  
✅ **Auto sync** - 2-way binding tự động  
✅ **Memory safe** - Auto dispose internal controller  

**Khuyến nghị:**
- 🎯 Dùng **Binding Expression** cho 90% cases (CRUD, forms)
- 📝 Dùng **Static mode** cho simple forms  
- 🎛️ Dùng **External controller** chỉ khi cần tính toán phức tạp

Happy coding với CyberFramework! 🚀
