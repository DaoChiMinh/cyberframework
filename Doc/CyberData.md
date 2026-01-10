# CyberData Classes - Data Management System

## Mục Lục
1. [Giới Thiệu](#giới-thiệu)
2. [CyberDataRow](#cyberdatarow)
3. [CyberDataTable](#cyberdatatable)
4. [CyberDataset](#cyberdataset)
5. [ReturnData](#returndata)
6. [Ví Dụ Sử Dụng](#ví-dụ-sử-dụng)
7. [Best Practices](#best-practices)
8. [Troubleshooting](#troubleshooting)

---

## Giới Thiệu

CyberData classes là **data management system** tương tự ADO.NET trong .NET Framework. Chúng cung cấp **two-way binding**, **change tracking**, và **XML serialization** cho business applications.

### Đặc Điểm Chính

- ✅ **ADO.NET-like**: DataRow, DataTable, Dataset pattern
- ✅ **Two-Way Binding**: Auto sync với UI widgets
- ✅ **Change Tracking**: Track modified fields
- ✅ **Type Preservation**: Maintain original types
- ✅ **UUID Identity**: Stable unique identifiers
- ✅ **XML Serialization**: Backend integration
- ✅ **Memory Safe**: Auto cleanup & disposal
- ✅ **Batch Operations**: Performance optimization

### Architecture

```
CyberDataset
  ├─ CyberDataTable (Table1)
  │   ├─ CyberDataRow (row 0)
  │   ├─ CyberDataRow (row 1)
  │   └─ CyberDataRow (row 2)
  └─ CyberDataTable (Table2)
      ├─ CyberDataRow (row 0)
      └─ CyberDataRow (row 1)
```

### Import

```dart
import 'package:cyberframework/cyberframework.dart';
```

---

## CyberDataRow

### Overview

Represents a **single row** of data with field-level change tracking and two-way binding support.

### Constructor

```dart
CyberDataRow([Map<String, dynamic>? initialData])
```

### Core Methods

#### Data Access

```dart
// Get value
dynamic value = row['fieldName'];
dynamic value = row.get<String>('fieldName');

// Set value
row['fieldName'] = 'value';
row.setValue('fieldName', 'value');

// Check field exists
bool exists = row.hasField('fieldName');

// Get all field names
List<String> fields = row.fieldNames;
```

#### Typed Getters

```dart
String getString(String fieldName, [String defaultValue = ''])
int getInt(String fieldName, [int defaultValue = 0])
double getDouble(String fieldName, [double defaultValue = 0.0])
double getDecimal(String fieldName, [double defaultValue = 0.0])
DateTime getDateTime(String fieldName, [DateTime? defaultValue])
bool getBool(String fieldName, [bool defaultValue = false])
```

#### Typed Setters

```dart
void setString(String fieldName, String value)
void setInt(String fieldName, int value)
void setDouble(String fieldName, double value)
void setDateTime(String fieldName, DateTime value)
void setBool(String fieldName, bool value, {bool useNumeric = false})
```

#### Generic Methods

```dart
T getTyped<T>(String fieldName, [T? defaultValue])
void setTyped<T>(String fieldName, T value)
```

### Change Tracking

```dart
// Check if row has changes
bool isDirty = row.isDirty;

// Get changed fields
Set<String> changed = row.changedFields;

// Accept changes (mark as original)
row.acceptChanges();

// Reject changes (revert to original)
row.rejectChanges();

// Get original value
dynamic original = row.getOriginal('fieldName');

// Get changed values only
Map<String, dynamic> changes = row.getChangedValues();
```

### Data Binding

```dart
// Create binding expression
CyberBindingExpression expr = row.bind('fieldName');

// Short syntax
CyberBindingExpression expr = row.$('fieldName');

// Use in widgets
CyberText(
  text: row.bind('name'),  // Two-way binding
  label: 'Name',
)
```

### Row Operations

```dart
// Copy row (new UUID)
CyberDataRow newRow = row.copy();

// Copy data from another row
row.copyFrom(sourceRow);

// Merge changed fields from another row
row.mergeFrom(sourceRow);

// Update with options
row.updateRowToRow(
  sourceRow,
  onlyChangedFields: true,
  preserveOriginal: true,
  excludeFields: ['id', 'created_date'],
  includeFields: ['name', 'email'],
);
```

### Identity Management

```dart
// Get unique identity (UUID v4)
Object id = row.identityKey;

// Set custom identity
row.setIdentityKey('CUSTOMER_123');

// Lock identity (before UI binding)
row.lockIdentity();

// Check if locked
bool locked = row.isIdentityLocked;

// Get internal UUID
String uuid = row.internalId;
```

### String Formatting (C#-style)

```dart
// Number formatting
String formatted = row.toString2('amount', 'N2');      // 12,345.67
String currency = row.toString2('price', 'C');         // ₫12,345
String percent = row.toString2('rate', 'P2');          // 12.34%
String custom = row.toString2('qty', '### ### ##0');   // 12 345 678

// Date formatting
String date = row.toString2('created', 'dd/MM/yyyy');  // 09/01/2026
String time = row.toString2('time', 'HH:mm:ss');       // 14:30:45
String full = row.toString2('date', 'g');              // 09/01/2026 14:30
```

### Batch Operations

```dart
// Batch updates (single notification)
row.batch(() {
  row['name'] = 'John';
  row['email'] = 'john@example.com';
  row['age'] = 30;
  // Only 1 notifyListeners() call
});
```

### Validation

```dart
// Check if field is empty
bool valid = await row.checkEmpty(
  context,
  'name',
  'Tên không được trống',
  'Name is required',
);
```

### XML Serialization

```dart
// Convert to XML
String xml = row.toXml(
  'Customer',
  includeColumns: ['id', 'name', 'email'],
  excludeColumns: ['password'],
);

// Convert to Map
Map<String, dynamic> map = row.toMap();
```

### Disposal

```dart
// Dispose row
row.dispose();

// Check if disposed
bool disposed = row.isDisposed;
```

---

## CyberDataTable

### Overview

Represents a **table** (collection of rows) with column schema and batch operations.

### Constructor

```dart
CyberDataTable({required String tableName})
```

### Core Methods

#### Row Operations

```dart
// Add row
table.addRow(row);

// Add multiple rows (batch)
table.addRowsBatch([row1, row2, row3]);

// Create new row with defaults
CyberDataRow newRow = table.newRow();

// Remove row
table.removeRow(row);
table.removeAt(index);

// Clear all rows
table.clear();
```

#### Data Access

```dart
// Get row by index
CyberDataRow row = table[0];

// Get all rows
List<CyberDataRow> rows = table.rows;

// Row count
int count = table.rowCount;
```

#### Column Management

```dart
// Add column
table.addColumn('name', String);
table.addColumn('age', int);

// Check column exists
bool exists = table.containerColumn('name');

// Get columns
Map<String, Type> columns = table.columns;
```

#### Data Loading

```dart
// Load from list of maps
table.loadData([
  {'id': 1, 'name': 'John'},
  {'id': 2, 'name': 'Jane'},
]);

// Load from rows
table.loadDataFromRows(rows, copy: true);

// Load from another table
table.loadDatafromTb(sourceTable, copy: true);
```

#### Search & Filter

```dart
// Find rows
List<CyberDataRow> found = table.findRows(
  (row) => row['age'] > 18,
);

// Find single row
CyberDataRow? user = table.findRow(
  (row) => row['email'] == 'john@example.com',
);
```

#### Change Tracking

```dart
// Get changed rows
List<CyberDataRow> changed = table.getChangedRows();

// Check if has changes
bool hasChanges = table.hasChanges;

// Accept/reject all changes
table.acceptChanges();
table.rejectChanges();
```

#### Batch Operations

```dart
// Batch mode (better performance)
table.batch(() {
  for (int i = 0; i < 1000; i++) {
    final row = table.newRow();
    row['id'] = i;
    table.addRow(row);
  }
  // Single notifyListeners() call
});
```

#### Export

```dart
// To XML
String xml = table.toXml(
  tableNameOverride: 'Customers',
  includeColumns: ['id', 'name'],
  excludeColumns: ['password'],
);

// To List
List<Map<String, dynamic>> list = table.toList();

// Copy table
CyberDataTable newTable = table.copy();
```

---

## CyberDataset

### Overview

Represents a **dataset** (collection of tables) - equivalent to ADO.NET Dataset.

### Constructor

```dart
CyberDataset()
```

### Core Methods

#### Table Management

```dart
// Add table
dataset.addTable(table);

// Create table
CyberDataTable table = dataset.createTable('Customers');

// Remove table
dataset.removeTable('Customers');

// Clear all tables
dataset.clear();
```

#### Table Access

```dart
// By name
CyberDataTable? table = dataset['Customers'];
CyberDataTable? table = dataset.Table('Customers');

// By index
CyberDataTable? table = dataset.Table(0);

// Get all tables
Map<String, CyberDataTable> tables = dataset.tables;

// Table count
int count = dataset.tableCount;
```

#### Data Loading

```dart
// From JSON string
dataset.loadFromJson(jsonString);

// From Map
dataset.loadFromMap({
  'Customers': [
    {'id': 1, 'name': 'John'},
    {'id': 2, 'name': 'Jane'},
  ],
  'Orders': [
    {'id': 1, 'customer_id': 1},
  ],
});

// Load single table
dataset.loadTable('Customers', [
  {'id': 1, 'name': 'John'},
]);
```

#### Status Checking

```dart
// Check API status response
bool success = await dataset.checkStatus(
  context,
  isShowMsg: true,
);
// Checks for 'status' field in first row of each table
// Shows message if status == 'N'
```

#### Change Tracking

```dart
// Check if has changes
bool hasChanges = dataset.hasChanges;

// Get changed tables
List<CyberDataTable> changed = dataset.getChangedTables();

// Accept/reject all changes
dataset.acceptChanges();
dataset.rejectChanges();
```

#### Batch Operations

```dart
// Batch mode
dataset.batch(() {
  dataset.addTable(table1);
  dataset.addTable(table2);
  dataset.addTable(table3);
  // Single notifyListeners()
});
```

#### Export

```dart
// To XML (all tables)
String xml = dataset.toXml();

// To XML (specific tables)
String xml = dataset.toXml(
  tableNames: ['Customers', 'Orders'],
  tableIncludeColumns: {
    'Customers': ['id', 'name'],
  },
  tableExcludeColumns: {
    'Orders': ['deleted_at'],
  },
);

// To Map
Map<String, dynamic> map = dataset.toMap();

// To JSON
String json = dataset.toJson();

// Copy dataset
CyberDataset newDs = dataset.copy();
```

---

## ReturnData

### Overview

Represents **API response** with status, message, and data conversion.

### Constructor

```dart
ReturnData({
  this.status,
  this.message,
  this.data,
  this.noRow,
  this.isConnect,
  this.cyberObject,
})
```

### Properties

```dart
bool? status;          // Success/fail status
String? message;       // Response message
dynamic data;          // Response data
List<int>? noRow;      // Empty table indices
bool? isConnect;       // Connection status
dynamic cyberObject;   // Custom object
```

### Methods

```dart
// Create from JSON
ReturnData.fromJson(Map<String, dynamic> json)

// Check if valid response
bool isValid()

// Convert to CyberDataset
CyberDataset? toCyberDataset()
```

### Usage with API

```dart
// Call API
final result = await context.callApi(
  functionName: 'GetCustomers',
  parameter: 'status=active',
);

// Check status
if (!result.isValid()) {
  result.message?.V_MsgBox(context);
  return;
}

// Convert to dataset
final ds = result.toCyberDataset();
if (ds == null) {
  'No data'.V_MsgBox(context);
  return;
}

// Check dataset status
if (!await ds.checkStatus(context)) {
  return;
}

// Use data
final customers = ds['Customers'];
```

---

## Ví Dụ Sử Dụng

### 1. Basic Row Operations

```dart
// Create row
final row = CyberDataRow();
row['name'] = 'John Doe';
row['email'] = 'john@example.com';
row['age'] = 30;

// Get values
String name = row.getString('name');
int age = row.getInt('age');

// Check changes
print(row.isDirty);  // true
print(row.changedFields);  // {name, email, age}

// Accept changes
row.acceptChanges();
print(row.isDirty);  // false

// Modify
row['name'] = 'Jane Doe';
print(row.isDirty);  // true
print(row.changedFields);  // {name}

// Revert
row.rejectChanges();
print(row['name']);  // 'John Doe'
```

### 2. Data Binding

```dart
class UserForm extends StatefulWidget {
  @override
  State<UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  final drUser = CyberDataRow();

  @override
  void initState() {
    super.initState();
    
    // Initialize
    drUser['name'] = '';
    drUser['email'] = '';
    drUser['age'] = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Two-way binding
        CyberText(
          text: drUser.bind('name'),
          label: 'Name',
        ),
        
        CyberText(
          text: drUser.bind('email'),
          label: 'Email',
        ),
        
        CyberNumeric(
          text: drUser.bind('age'),
          label: 'Age',
        ),
        
        CyberButton(
          label: 'Save',
          onClick: () async {
            // Data automatically updated in drUser
            print(drUser['name']);
            print(drUser['email']);
            print(drUser['age']);
          },
        ),
      ],
    );
  }
}
```

### 3. Table Operations

```dart
// Create table
final table = CyberDataTable(tableName: 'Customers');

// Add columns
table.addColumn('id', int);
table.addColumn('name', String);
table.addColumn('email', String);

// Create and add rows
for (int i = 1; i <= 10; i++) {
  final row = table.newRow();
  row['id'] = i;
  row['name'] = 'Customer $i';
  row['email'] = 'customer$i@example.com';
  table.addRow(row);
}

// Search
final activeUsers = table.findRows(
  (row) => row['id'] > 5,
);

// Update
for (var row in activeUsers) {
  row['status'] = 'active';
}

// Check changes
print(table.hasChanges);  // true
print(table.getChangedRows().length);  // 5
```

### 4. Dataset with API

```dart
class CustomerList extends CyberForm {
  final dsCustomers = CyberDataset();
  CyberDataTable get dtCustomers => dsCustomers['Customers']!;

  @override
  Future<void> onLoadData() async {
    // Call API
    final result = await context.callApi(
      functionName: 'GetCustomers',
      parameter: 'status=active',
    );
    
    // Check and convert
    if (!result.isValid()) {
      result.message?.V_MsgBox(context);
      return;
    }
    
    final ds = result.toCyberDataset();
    if (ds == null) return;
    
    if (!await ds.checkStatus(context)) return;
    
    // Load data
    dsCustomers.loadFromMap(ds.toMap());
  }

  @override
  Widget buildBody(BuildContext context) {
    return ListView.builder(
      itemCount: dtCustomers.rowCount,
      itemBuilder: (context, index) {
        final row = dtCustomers[index];
        return ListTile(
          title: Text(row.getString('name')),
          subtitle: Text(row.getString('email')),
        );
      },
    );
  }
}
```

### 5. Save with XML

```dart
Future<void> saveCustomer() async {
  // Validate
  if (drCustomer['name'].toString().isEmpty) {
    'Name is required'.V_MsgBox(context);
    return;
  }
  
  showLoading('Saving...');
  
  try {
    // Create dataset
    final ds = CyberDataset();
    final table = ds.createTable('Customer');
    table.addRow(drCustomer);
    
    // Generate XML
    final xml = ds.toXml(tableNames: ['Customer']);
    
    // Call API
    final result = await context.callApi(
      functionName: 'SaveCustomer',
      parameter: xml,
    );
    
    hideLoading();
    
    if (result.isValid()) {
      'Saved successfully!'.V_MsgBox(context);
      close();
    } else {
      result.message?.V_MsgBox(context);
    }
  } catch (e) {
    hideLoading();
    'Error: $e'.V_MsgBox(context);
  }
}
```

### 6. Batch Operations

```dart
// Load 10,000 rows efficiently
final table = CyberDataTable(tableName: 'BigData');

table.batch(() {
  for (int i = 0; i < 10000; i++) {
    final row = table.newRow();
    row['id'] = i;
    row['data'] = 'Data $i';
    table.addRow(row);
  }
});
// Only 1 notifyListeners() call instead of 10,000!
```

### 7. String Formatting

```dart
final row = CyberDataRow();
row['amount'] = 12345.67;
row['created_date'] = DateTime(2026, 1, 9, 14, 30, 45);
row['rate'] = 0.1234;
row['quantity'] = 123456789;

// Number formatting
print(row.toString2('amount', 'N2'));      // 12,345.67
print(row.toString2('amount', 'C'));       // ₫12,346
print(row.toString2('rate', 'P2'));        // 12.34%
print(row.toString2('quantity', '### ### ### ##0'));  // 123 456 789

// Date formatting
print(row.toString2('created_date', 'dd/MM/yyyy'));  // 09/01/2026
print(row.toString2('created_date', 'HH:mm:ss'));    // 14:30:45
print(row.toString2('created_date', 'g'));           // 09/01/2026 14:30
```

### 8. Row Copy & Merge

```dart
// Source row
final source = CyberDataRow();
source['id'] = 1;
source['name'] = 'John';
source['email'] = 'john@example.com';

// Copy all data
final target = CyberDataRow();
target.copyFrom(source);
print(target['name']);  // 'John'

// Merge changed fields only
source['email'] = 'newemail@example.com';
final dest = CyberDataRow();
dest['id'] = 1;
dest['name'] = 'Jane';
dest.mergeFrom(source);  // Only updates 'email'
print(dest['name']);  // Still 'Jane'
print(dest['email']);  // 'newemail@example.com'
```

### 9. Identity Management

```dart
// Row with auto UUID
final row = CyberDataRow();
print(row.identityKey);  // "550e8400-e29b-41d4-a716-446655440000"

// Custom identity
row.setIdentityKey('CUSTOMER_123');
print(row.identityKey);  // "CUSTOMER_123"

// Lock before UI binding
row.lockIdentity();

// ListView with stable keys
ListView.builder(
  itemBuilder: (context, index) {
    final row = table[index];
    row.lockIdentity();  // Lock before using as key
    
    return ListTile(
      key: ValueKey(row.identityKey),  // Stable key
      title: Text(row.getString('name')),
    );
  },
)
```

### 10. Advanced Table Filtering

```dart
final customers = CyberDataTable(tableName: 'Customers');

// Load data
customers.loadData([
  {'id': 1, 'name': 'John', 'age': 25, 'city': 'Hanoi'},
  {'id': 2, 'name': 'Jane', 'age': 30, 'city': 'HCMC'},
  {'id': 3, 'name': 'Bob', 'age': 22, 'city': 'Hanoi'},
]);

// Complex filter
final result = customers.findRows((row) {
  return row.getInt('age') >= 25 && 
         row.getString('city') == 'Hanoi';
});

print(result.length);  // 1 (John)
```

---

## Best Practices

### 1. Initialize DataRow

```dart
// ✅ GOOD: Initialize all fields
@override
void onInit() {
  super.onInit();
  
  drUser['name'] = '';
  drUser['email'] = '';
  drUser['age'] = 0;
  drUser['active'] = false;
}

// ❌ BAD: No initialization
// Fields will be null, causing issues
```

### 2. Use Typed Getters

```dart
// ✅ GOOD: Type-safe
int age = row.getInt('age', 0);
String name = row.getString('name', '');

// ❌ BAD: Unsafe casting
int age = row['age'] as int;  // Crash if null or wrong type
```

### 3. Use Binding

```dart
// ✅ GOOD: Two-way binding
CyberText(
  text: drUser.bind('name'),
)

// ❌ BAD: Manual state management
String name = '';
CyberText(
  text: name,
  onChanged: (value) {
    setState(() {
      name = value;
    });
  },
)
```

### 4. Batch Operations

```dart
// ✅ GOOD: Batch for performance
table.batch(() {
  for (int i = 0; i < 1000; i++) {
    table.addRow(row);
  }
});

// ❌ BAD: 1000 notifications
for (int i = 0; i < 1000; i++) {
  table.addRow(row);  // notifyListeners() each time
}
```

### 5. Lock Identity in UI

```dart
// ✅ GOOD: Lock before UI binding
itemBuilder: (context, index) {
  final row = table[index];
  row.lockIdentity();
  
  return ListTile(
    key: ValueKey(row.identityKey),
  );
}

// ⚠️ OK: No lock for simple lists
// But may cause issues if identity changes
```

### 6. Proper Disposal

```dart
// ✅ GOOD: Dispose in onDispose
@override
void onDispose() {
  drUser.dispose();
  dtCustomers.dispose();
  dsData.dispose();
  super.onDispose();
}

// ❌ BAD: No disposal
// Memory leaks!
```

### 7. Check API Response

```dart
// ✅ GOOD: Proper error handling
final result = await context.callApi(...);

if (!result.isValid()) {
  result.message?.V_MsgBox(context);
  return;
}

final ds = result.toCyberDataset();
if (ds == null) {
  'No data'.V_MsgBox(context);
  return;
}

if (!await ds.checkStatus(context)) {
  return;
}

// ❌ BAD: No checking
final ds = result.toCyberDataset()!;  // Crash if null
```

---

## Troubleshooting

### DataRow không binding

**Nguyên nhân:** Chưa initialize field

**Giải pháp:**
```dart
// ✅ CORRECT
drUser['name'] = '';  // Initialize first
CyberText(text: drUser.bind('name'))

// ❌ WRONG
CyberText(text: drUser.bind('name'))  // Field doesn't exist
```

### UI không update

**Nguyên nhân:** Không dùng binding

**Giải pháp:**
```dart
// ✅ CORRECT: Use binding
CyberText(text: dr.bind('name'))

// ❌ WRONG: Direct value
CyberText(text: dr['name'])
```

### Identity changed error

**Nguyên nhân:** Identity modified after locking

**Giải pháp:**
```dart
// ✅ CORRECT: Set before locking
row.setIdentityKey('ID_123');
row.lockIdentity();

// ❌ WRONG: Set after locking
row.lockIdentity();
row.setIdentityKey('ID_123');  // Error!
```

### Slow performance

**Nguyên nhân:** Không dùng batch

**Giải pháp:**
```dart
// ✅ CORRECT: Use batch
table.batch(() {
  // Many operations
});

// ❌ WRONG: Individual notifications
// Many addRow() calls
```

### XML không đúng

**Nguyên nhân:** Wrong column names

**Giải pháp:**
```dart
// ✅ CORRECT: Specify columns
xml = table.toXml(
  includeColumns: ['id', 'name', 'email'],
)

// ❌ WRONG: Includes all fields
xml = table.toXml()  // May include unwanted fields
```

---

## Tips & Tricks

### 1. String Format Patterns

```dart
// Number patterns
'N2'  → 12,345.67 (2 decimals with separator)
'N0'  → 12,346 (no decimals)
'C'   → ₫12,346 (currency)
'P2'  → 12.34% (percent)
'F3'  → 12345.670 (fixed 3 decimals)
'### ### ##0' → 12 345 678 (custom pattern)

// Date patterns
'dd/MM/yyyy'  → 09/01/2026
'HH:mm:ss'    → 14:30:45
'g'           → 09/01/2026 14:30 (general short)
'G'           → 09/01/2026 14:30:45 (general long)
```

### 2. Quick Data Loading

```dart
// From API
final (ds, success) = await context.callApiAndCheck(
  functionName: 'GetData',
  parameter: '',
);

if (success && ds != null) {
  dsData.loadFromMap(ds.toMap());
}
```

### 3. newRow() Patterns

```dart
// Create with defaults
final row = table.newRow();
// All columns initialized with type defaults
// String → '', int → 0, double → 0.0, etc.

row['id'] = 123;
row['name'] = 'John';
table.addRow(row);
```

### 4. Field Name Caching

```dart
// Case-insensitive access
row['Name'] = 'John';
print(row['name']);  // 'John' (same field)
print(row['NAME']);  // 'John' (same field)

// Cached for performance
```

### 5. Change Detection

```dart
// Before save, check what changed
if (drCustomer.isDirty) {
  final changes = drCustomer.getChangedValues();
  print('Changed: ${changes.keys.join(", ")}');
  
  // Save only changes
  await saveChanges(changes);
}
```

---

## Performance Tips

1. **Use Batch Mode**: For multiple operations
2. **Lock Identity**: Only when needed (UI binding)
3. **Dispose Properly**: Prevent memory leaks
4. **Use Typed Getters**: Avoid runtime casting
5. **Cache Frequently**: Don't re-query unchanged data

---

## Common Patterns

### Master-Detail Pattern

```dart
final dsMaster = CyberDataset();
CyberDataTable get dtOrders => dsMaster['Orders']!;
CyberDataTable get dtItems => dsMaster['OrderItems']!;

void selectOrder(int orderId) {
  final items = dtItems.findRows(
    (row) => row.getInt('order_id') == orderId,
  );
}
```

### CRUD Pattern

```dart
// Create
final row = table.newRow();
row['name'] = 'New Item';
table.addRow(row);

// Read
final item = table.findRow((r) => r['id'] == 123);

// Update
item?['name'] = 'Updated Name';

// Delete
if (item != null) table.removeRow(item);
```

### Validation Pattern

```dart
bool validate() {
  if (!drUser.checkEmpty(context, 'name', 'Nhập tên', 'Enter name')) {
    return false;
  }
  
  if (drUser.getInt('age') < 18) {
    'Must be 18+'.V_MsgBox(context);
    return false;
  }
  
  return true;
}
```

---

## Version History

### 1.0.0
- CyberDataRow with UUID identity
- CyberDataTable with batch operations
- CyberDataset multi-table support
- ReturnData API response
- Two-way data binding
- Change tracking
- XML serialization
- String formatting (C#-style)
- Memory-safe disposal

---

## License

MIT License - CyberFramework
