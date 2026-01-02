# CyberComboBox - Dropdown với Binding Expression

## 🎯 Overview

**CyberComboBox** là dropdown picker với iOS-style bottom sheet, hỗ trợ binding expression với CyberDataRow.

**Cú pháp:**
```dart
final productRow = CyberDataRow();
final categories = CyberDataTable(); // Danh sách categories

CyberComboBox(
  text: productRow.bind('categoryId'),  // ← Value binding
  displayMember: 'categoryName',        // Field hiển thị
  valueMember: 'categoryId',            // Field giá trị
  dataSource: categories,               // DataTable
  label: 'Danh mục',
)
```

---

## 🚀 Quick Start

### 1. Chuẩn bị Data

```dart
// Tạo DataTable cho categories
final categories = CyberDataTable();

// Thêm data vào table
final cat1 = CyberDataRow();
cat1['categoryId'] = 1;
cat1['categoryName'] = 'Điện thoại';
categories.add(cat1);

final cat2 = CyberDataRow();
cat2['categoryId'] = 2;
cat2['categoryName'] = 'Laptop';
categories.add(cat2);

final cat3 = CyberDataRow();
cat3['categoryId'] = 3;
cat3['categoryName'] = 'Tablet';
categories.add(cat3);

// Tạo product row
final productRow = CyberDataRow();
productRow['productName'] = 'iPhone 15';
productRow['categoryId'] = 1;  // Chọn "Điện thoại"
```

### 2. Sử dụng Widget

```dart
Column(
  children: [
    // Product name
    CyberText(
      text: productRow.bind('productName'),
      label: 'Tên sản phẩm',
    ),
    
    // Category ComboBox ⭐
    CyberComboBox(
      text: productRow.bind('categoryId'),  // Value binding
      displayMember: 'categoryName',
      valueMember: 'categoryId',
      dataSource: categories,
      label: 'Danh mục',
      hint: 'Chọn danh mục',
      icon: Icons.category,
    ),
  ],
)
```

### 3. Đọc/Ghi Data

```dart
// Đọc giá trị
print('Category ID: ${productRow['categoryId']}');

// Thay đổi category → UI tự động update!
productRow['categoryId'] = 2;  // Chuyển sang "Laptop"

// Lấy display text
String displayText = _getDisplayText(productRow['categoryId']);
```

---

## 📝 3 Modes Sử Dụng

### 1️⃣ **BINDING EXPRESSION MODE** (Khuyên dùng - 90% cases)

**Syntax:**
```dart
CyberComboBox(
  text: row.bind('fieldName'),  // ← Value binding
  displayMember: 'displayField',
  valueMember: 'valueField',
  dataSource: dataTable,
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
  late CyberDataTable categories;
  late CyberDataTable brands;

  @override
  void initState() {
    super.initState();
    
    // Tạo product row
    productRow = CyberDataRow();
    productRow['productName'] = '';
    productRow['categoryId'] = null;
    productRow['brandId'] = null;
    productRow['price'] = '';
    
    // Load categories
    categories = CyberDataTable();
    _loadCategories();
    
    // Load brands
    brands = CyberDataTable();
    _loadBrands();
  }

  void _loadCategories() {
    final data = [
      {'id': 1, 'name': 'Điện thoại'},
      {'id': 2, 'name': 'Laptop'},
      {'id': 3, 'name': 'Tablet'},
    ];
    
    for (var item in data) {
      final row = CyberDataRow();
      row['categoryId'] = item['id'];
      row['categoryName'] = item['name'];
      categories.add(row);
    }
  }

  void _loadBrands() {
    final data = [
      {'id': 1, 'name': 'Apple'},
      {'id': 2, 'name': 'Samsung'},
      {'id': 3, 'name': 'Dell'},
    ];
    
    for (var item in data) {
      final row = CyberDataRow();
      row['brandId'] = item['id'];
      row['brandName'] = item['name'];
      brands.add(row);
    }
  }

  void _handleSave() {
    // Validate
    if (productRow['categoryId'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng chọn danh mục!')),
      );
      return;
    }
    
    final data = productRow.toMap();
    print('Save: $data');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Product name
        CyberText(
          text: productRow.bind('productName'),
          label: 'Tên sản phẩm',
          isCheckEmpty: true,
        ),
        SizedBox(height: 16),
        
        // Category ⭐ BINDING
        CyberComboBox(
          text: productRow.bind('categoryId'),
          displayMember: 'categoryName',
          valueMember: 'categoryId',
          dataSource: categories,
          label: 'Danh mục',
          hint: 'Chọn danh mục',
          icon: Icons.category,
          isCheckEmpty: true,
        ),
        SizedBox(height: 16),
        
        // Brand ⭐ BINDING
        CyberComboBox(
          text: productRow.bind('brandId'),
          displayMember: 'brandName',
          valueMember: 'brandId',
          dataSource: brands,
          label: 'Thương hiệu',
          hint: 'Chọn thương hiệu',
          icon: Icons.business,
        ),
        SizedBox(height: 16),
        
        // Price
        CyberText(
          text: productRow.bind('price'),
          label: 'Giá bán',
          format: '{0} VNĐ',
          showFormatInField: false,
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 24),
        
        ElevatedButton(
          onPressed: _handleSave,
          child: Text('Lưu'),
        ),
      ],
    );
  }
}
```

**Lợi ích:**
- ✅ Gọn gàng - chỉ 1 property `text`
- ✅ Tự động sync 2 chiều: UI ↔ DataRow
- ✅ Không cần khai báo controller
- ✅ Không cần dispose

---

### 2️⃣ **STATIC MODE** (Đơn giản)

**Syntax:**
```dart
int? selectedValue = 1;

CyberComboBox(
  text: selectedValue,  // ← Static value
  onChanged: (value) {
    setState(() {
      selectedValue = value;
    });
  },
  displayMember: 'name',
  valueMember: 'id',
  dataSource: items,
  label: 'Chọn',
)
```

**Example:**
```dart
class SimpleForm extends StatefulWidget {
  @override
  State<SimpleForm> createState() => _SimpleFormState();
}

class _SimpleFormState extends State<SimpleForm> {
  int? selectedCategoryId;
  late CyberDataTable categories;

  @override
  void initState() {
    super.initState();
    
    categories = CyberDataTable();
    final cat1 = CyberDataRow();
    cat1['id'] = 1;
    cat1['name'] = 'Category A';
    categories.add(cat1);
    
    final cat2 = CyberDataRow();
    cat2['id'] = 2;
    cat2['name'] = 'Category B';
    categories.add(cat2);
  }

  @override
  Widget build(BuildContext context) {
    return CyberComboBox(
      text: selectedCategoryId,
      onChanged: (value) {
        setState(() {
          selectedCategoryId = value;
        });
        print('Selected: $value');
      },
      displayMember: 'name',
      valueMember: 'id',
      dataSource: categories,
      label: 'Category',
      hint: 'Select category',
    );
  }
}
```

---

### 3️⃣ **EXTERNAL CONTROLLER MODE** (Nâng cao)

**Syntax:**
```dart
final controller = CyberComboBoxController(
  dataSource: categories,
  displayMember: 'categoryName',
  valueMember: 'categoryId',
);

CyberComboBox(
  controller: controller,
  label: 'Category',
)

// Phải dispose
controller.dispose();
```

**Example:**
```dart
class AdvancedForm extends StatefulWidget {
  @override
  State<AdvancedForm> createState() => _AdvancedFormState();
}

class _AdvancedFormState extends State<AdvancedForm> {
  late CyberComboBoxController categoryController;
  late CyberComboBoxController brandController;
  late CyberDataTable categories;
  late CyberDataTable brands;

  @override
  void initState() {
    super.initState();
    
    categories = CyberDataTable();
    _loadCategories();
    
    brands = CyberDataTable();
    _loadBrands();
    
    categoryController = CyberComboBoxController(
      dataSource: categories,
      displayMember: 'categoryName',
      valueMember: 'categoryId',
    );
    
    brandController = CyberComboBoxController(
      dataSource: brands,
      displayMember: 'brandName',
      valueMember: 'brandId',
    );
    
    // Listen to category changes
    categoryController.addListener(_onCategoryChanged);
  }

  @override
  void dispose() {
    categoryController.dispose();
    brandController.dispose();
    super.dispose();
  }

  void _onCategoryChanged() {
    print('Category changed: ${categoryController.value}');
    print('Display: ${categoryController.getDisplayText()}');
    
    // Filter brands based on category...
  }

  void _handleClear() {
    categoryController.clear();
    brandController.clear();
  }

  void _handleValidate() {
    if (!categoryController.isValidValue()) {
      print('Invalid category!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberComboBox(
          controller: categoryController,
          label: 'Category',
        ),
        CyberComboBox(
          controller: brandController,
          label: 'Brand',
        ),
        Row(
          children: [
            ElevatedButton(onPressed: _handleClear, child: Text('Clear')),
            ElevatedButton(onPressed: _handleValidate, child: Text('Validate')),
          ],
        ),
      ],
    );
  }
}
```

---

## 🔧 API Reference

### CyberComboBox Properties

```dart
CyberComboBox(
  // === BINDING / STATIC MODE ===
  text: row.bind('field'),  // Value (CyberBindingExpression hoặc dynamic)
  onChanged: (value) {},    // Callback (chỉ dùng static mode)
  
  // === EXTERNAL CONTROLLER ===
  controller: myController,
  
  // === DATA SOURCE ===
  dataSource: myDataTable,     // CyberDataTable
  displayMember: 'nameField',  // Field name hiển thị
  valueMember: 'idField',      // Field name giá trị
  
  // === UI ===
  label: 'Label',
  hint: 'Chọn...',
  icon: Icons.category,
  iconColor: Colors.blue,
  backgroundColor: Colors.grey[100],
  labelStyle: TextStyle(...),
  textStyle: TextStyle(...),
  
  // === STATE ===
  enabled: true,
  isVisible: true,  // Có thể binding
  isShowLabel: true,
  isCheckEmpty: false,  // Required (hiển thị *)
  
  // === CALLBACKS ===
  onLeaver: (value) {},
)
```

### CyberComboBoxController API

```dart
// Tạo controller
final controller = CyberComboBoxController(
  value: initialValue,
  enabled: true,
  dataSource: myDataTable,
  displayMember: 'nameField',
  valueMember: 'idField',
);

// Getters (read-only)
dynamic value = controller.value;
bool enabled = controller.enabled;
CyberDataTable? dataSource = controller.dataSource;
String? displayMember = controller.displayMember;
String? valueMember = controller.valueMember;

// Setters
controller.setValue(newValue);
controller.setEnabled(false);
controller.setDataSource(newDataTable);
controller.setDisplayMember('newField');
controller.setValueMember('newField');

// Actions
controller.clear();
controller.reset(initialValue);

// Helpers
String? displayText = controller.getDisplayText();
bool isValid = controller.isValidValue();

// Binding
controller.bind(myRow, 'fieldName');
controller.unbind();

// Dispose
controller.dispose();
```

---

## 💡 Ví Dụ Thực Tế

### Form nhập hóa đơn với Cascading ComboBoxes

```dart
class InvoiceForm extends StatefulWidget {
  @override
  State<InvoiceForm> createState() => _InvoiceFormState();
}

class _InvoiceFormState extends State<InvoiceForm> {
  late CyberDataRow invoiceRow;
  late CyberDataTable customers;
  late CyberDataTable products;
  late CyberDataTable filteredProducts;

  @override
  void initState() {
    super.initState();
    
    // Invoice data
    invoiceRow = CyberDataRow();
    invoiceRow['invoiceNumber'] = 'INV001';
    invoiceRow['customerId'] = null;
    invoiceRow['categoryId'] = null;
    invoiceRow['productId'] = null;
    invoiceRow['quantity'] = '';
    
    // Load data
    customers = CyberDataTable();
    products = CyberDataTable();
    filteredProducts = CyberDataTable();
    
    _loadCustomers();
    _loadProducts();
    
    // Listen to category changes để filter products
    invoiceRow.addListener(_onInvoiceChanged);
  }

  @override
  void dispose() {
    invoiceRow.removeListener(_onInvoiceChanged);
    super.dispose();
  }

  void _loadCustomers() {
    final data = [
      {'id': 1, 'name': 'Nguyễn Văn A'},
      {'id': 2, 'name': 'Trần Thị B'},
    ];
    
    for (var item in data) {
      final row = CyberDataRow();
      row['customerId'] = item['id'];
      row['customerName'] = item['name'];
      customers.add(row);
    }
  }

  void _loadProducts() {
    final data = [
      {'id': 1, 'name': 'iPhone 15', 'categoryId': 1},
      {'id': 2, 'name': 'Samsung S24', 'categoryId': 1},
      {'id': 3, 'name': 'Dell XPS 15', 'categoryId': 2},
      {'id': 4, 'name': 'MacBook Pro', 'categoryId': 2},
    ];
    
    for (var item in data) {
      final row = CyberDataRow();
      row['productId'] = item['id'];
      row['productName'] = item['name'];
      row['categoryId'] = item['categoryId'];
      products.add(row);
    }
  }

  void _onInvoiceChanged() {
    // Filter products khi category thay đổi
    final categoryId = invoiceRow['categoryId'];
    
    if (categoryId == null) {
      filteredProducts.clear();
      setState(() {});
      return;
    }
    
    filteredProducts.clear();
    for (int i = 0; i < products.rowCount; i++) {
      final product = products[i];
      if (product['categoryId'] == categoryId) {
        filteredProducts.add(product);
      }
    }
    
    // Reset product selection
    invoiceRow['productId'] = null;
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Invoice Number
          CyberText(
            text: invoiceRow.bind('invoiceNumber'),
            label: 'Số hóa đơn',
            enabled: false,
            backgroundColor: Colors.grey[200],
          ),
          SizedBox(height: 16),
          
          // Customer ⭐
          CyberComboBox(
            text: invoiceRow.bind('customerId'),
            displayMember: 'customerName',
            valueMember: 'customerId',
            dataSource: customers,
            label: 'Khách hàng',
            hint: 'Chọn khách hàng',
            icon: Icons.person,
            isCheckEmpty: true,
          ),
          SizedBox(height: 16),
          
          // Category ⭐ (cascading)
          CyberComboBox(
            text: invoiceRow.bind('categoryId'),
            displayMember: 'categoryName',
            valueMember: 'categoryId',
            dataSource: _getCategoryDataTable(),
            label: 'Danh mục',
            hint: 'Chọn danh mục',
            icon: Icons.category,
            isCheckEmpty: true,
          ),
          SizedBox(height: 16),
          
          // Product ⭐ (filtered by category)
          CyberComboBox(
            text: invoiceRow.bind('productId'),
            displayMember: 'productName',
            valueMember: 'productId',
            dataSource: filteredProducts,
            label: 'Sản phẩm',
            hint: invoiceRow['categoryId'] == null
                ? 'Chọn danh mục trước'
                : 'Chọn sản phẩm',
            icon: Icons.shopping_bag,
            enabled: invoiceRow['categoryId'] != null,
          ),
          SizedBox(height: 16),
          
          // Quantity
          CyberText(
            text: invoiceRow.bind('quantity'),
            label: 'Số lượng',
            keyboardType: TextInputType.number,
            enabled: invoiceRow['productId'] != null,
          ),
          SizedBox(height: 24),
          
          ElevatedButton(
            onPressed: _handleSave,
            child: Text('Tạo hóa đơn'),
          ),
        ],
      ),
    );
  }

  CyberDataTable _getCategoryDataTable() {
    final table = CyberDataTable();
    
    final cat1 = CyberDataRow();
    cat1['categoryId'] = 1;
    cat1['categoryName'] = 'Điện thoại';
    table.add(cat1);
    
    final cat2 = CyberDataRow();
    cat2['categoryId'] = 2;
    cat2['categoryName'] = 'Laptop';
    table.add(cat2);
    
    return table;
  }

  void _handleSave() {
    // Validate
    if (invoiceRow['customerId'] == null) {
      _showError('Vui lòng chọn khách hàng!');
      return;
    }
    if (invoiceRow['categoryId'] == null) {
      _showError('Vui lòng chọn danh mục!');
      return;
    }
    
    final data = invoiceRow.toMap();
    print('Tạo hóa đơn: $data');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
```

---

## ✅ Best Practices

### DO

```dart
// ✅ Dùng Binding Expression
CyberComboBox(
  text: row.bind('categoryId'),
  displayMember: 'name',
  valueMember: 'id',
  dataSource: categories,
)

// ✅ Set required với isCheckEmpty
CyberComboBox(
  text: row.bind('categoryId'),
  isCheckEmpty: true,  // Hiển thị dấu *
  label: 'Category',
)

// ✅ Cascading dropdowns
void _onCategoryChanged() {
  final categoryId = row['categoryId'];
  // Filter dependent dropdown...
}
```

### DON'T

```dart
// ❌ Đừng mix text và controller
CyberComboBox(
  text: row.bind('categoryId'),
  controller: myController,  // ❌ Conflict!
)

// ❌ Đừng quên set displayMember và valueMember
CyberComboBox(
  text: row.bind('categoryId'),
  dataSource: categories,
  // displayMember: ???  // ❌ Missing!
  // valueMember: ???    // ❌ Missing!
)

// ❌ Đừng dùng onChanged với binding mode
CyberComboBox(
  text: row.bind('categoryId'),
  onChanged: (value) => ...,  // ❌ Không cần!
)
```

---

## 🎉 Kết Luận

**CyberComboBox với Binding Expression:**

✅ **Gọn gàng** - `text: row.bind('field')` thay vì khai báo controller  
✅ **Tự động sync** - 2-way binding với CyberDataRow  
✅ **iOS style** - Beautiful bottom sheet picker  
✅ **Cascading** - Dễ dàng tạo dependent dropdowns  
✅ **Type-safe** - Compile-time checking  

**Khuyến nghị:**
- 🎯 Dùng **Binding Expression** cho 90% cases
- 📝 Dùng **Static mode** cho simple forms
- 🎛️ Dùng **External controller** khi cần logic phức tạp

Happy coding! 🚀
