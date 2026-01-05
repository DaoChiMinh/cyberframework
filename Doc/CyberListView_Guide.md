# CyberListView - Hướng Dẫn Sử Dụng

## Giới Thiệu

`CyberListView` là powerful list widget với pagination, search, swipe actions, menu, và toolbar.

## Properties

| Property | Type | Mô tả |
|----------|------|-------|
| `dataSource` | `CyberDataTable?` | External data source |
| `onLoadData` | `FutureDataCallback?` | Load data function |
| `itemBuilder` | `ItemBuilder` | Build item UI |
| `isClickToScreen` | `bool` | Auto navigate on tap |
| `onItemTap` | `ItemTapCallback?` | Callback khi tap item |
| `onItemLongPress` | `ItemLongPressCallback?` | Callback khi long press |
| `menuDataTable` | `CyberDataTable?` | Menu items |
| `dtSwipeActions` | `CyberDataTable?` | Swipe actions |
| `dtToolbarActions` | `CyberDataTable?` | Toolbar buttons |
| `showSearchBox` | `bool` | Hiển thị search |
| `pageSize` | `int` | Items per page |

## Ví Dụ Cơ Bản

### 1. Simple List

```dart
final CyberDataTable dataTable = CyberDataTable(tableName: 'Products');

CyberListView(
  dataSource: dataTable,
  itemBuilder: (context, row, index) {
    return ListTile(
      title: Text(row['name']?.toString() ?? ''),
      subtitle: Text(row['price']?.toString() ?? ''),
    );
  },
)
```

### 2. List With Load Data

```dart
CyberListView(
  onLoadData: (pageIndex, pageSize, searchText) async {
    final response = await api.getProducts(
      page: pageIndex,
      size: pageSize,
      search: searchText,
    );
    return response.toCyberDataTable();
  },
  itemBuilder: (context, row, index) {
    return ProductCard(product: row);
  },
  pageSize: 20,
  showSearchBox: true,
)
```

### 3. List With External DataSource

```dart
class MyListView extends StatefulWidget {
  @override
  State<MyListView> createState() => _MyListViewState();
}

class _MyListViewState extends State<MyListView> {
  final CyberDataTable dataTable = CyberDataTable(tableName: 'Items');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final response = await api.getItems();
    final newData = response.toCyberDataTable();
    
    dataTable.clear();
    dataTable.loadDatafromTb(newData);
  }

  @override
  Widget build(BuildContext context) {
    return CyberListView(
      dataSource: dataTable,  // ✅ External source
      itemBuilder: (context, row, index) {
        return ItemCard(item: row);
      },
    );
  }
}
```

## Search Functionality

```dart
CyberListView(
  showSearchBox: true,
  searchDebounceTime: 500,  // ms
  onLoadData: (pageIndex, pageSize, searchText) async {
    // searchText được truyền từ search box
    return await api.search(searchText, pageIndex, pageSize);
  },
  itemBuilder: (context, row, index) {
    return ItemTile(item: row);
  },
)
```

## Swipe Actions

```dart
// Prepare swipe actions
final swipeActions = CyberDataTable(tableName: 'Actions');
swipeActions.addRow(CyberDataRow()..setValues({
  'bar': 'Sửa',
  'icon': 'edit',
  'backcolor': '#4CAF50',
  'textcolor': '#FFFFFF',
}));
swipeActions.addRow(CyberDataRow()..setValues({
  'bar': 'Xóa',
  'icon': 'delete',
  'backcolor': '#F44336',
  'textcolor': '#FFFFFF',
}));

CyberListView(
  dataSource: dataTable,
  dtSwipeActions: swipeActions,
  isSwipeActionClickToScreen: false,
  onSwipeActionTap: (swipeRow, sourceRow, index) {
    final action = swipeRow['bar'];
    if (action == 'Sửa') {
      editItem(sourceRow);
    } else if (action == 'Xóa') {
      deleteItem(sourceRow);
    }
  },
  itemBuilder: (context, row, index) {
    return ItemTile(item: row);
  },
)
```

## Long Press Menu

```dart
// Prepare menu
final menuTable = CyberDataTable(tableName: 'Menu');
menuTable.addRow(CyberDataRow()..setValues({
  'bar': 'Xem chi tiết',
  'icon': 'info',
  'pagename': 'ProductDetail',
}));
menuTable.addRow(CyberDataRow()..setValues({
  'bar': 'Chia sẻ',
  'icon': 'share',
}));

CyberListView(
  dataSource: dataTable,
  menuDataTable: menuTable,
  isMenuClickToScreen: true,  // Auto navigate
  onMenuItemTap: (menuRow, sourceRow, index) {
    final action = menuRow['bar'];
    print('Menu action: $action on item: ${sourceRow['name']}');
  },
  itemBuilder: (context, row, index) {
    return ItemTile(item: row);
  },
)
```

## Toolbar Actions

```dart
// Prepare toolbar
final toolbarActions = CyberDataTable(tableName: 'Toolbar');
toolbarActions.addRow(CyberDataRow()..setValues({
  'bar': 'Thêm',
  'icon': 'add',
  'backcolor': '#2196F3',
  'textcolor': '#FFFFFF',
  'showlabel': true,
}));
toolbarActions.addRow(CyberDataRow()..setValues({
  'bar': 'Lọc',
  'icon': 'filter',
  'backcolor': '#FF9800',
  'showlabel': false,  // Icon only
}));

CyberListView(
  showSearchBox: true,
  dataSource: dataTable,
  dtToolbarActions: toolbarActions,
  onToolbarActionTap: (actionRow) {
    final action = actionRow['bar'];
    if (action == 'Thêm') {
      addNewItem();
    } else if (action == 'Lọc') {
      showFilterDialog();
    }
  },
  itemBuilder: (context, row, index) {
    return ItemTile(item: row);
  },
)
```

## Auto Navigation

```dart
CyberListView(
  dataSource: dataTable,
  isClickToScreen: true,  // ✅ Auto call row.V_Call(context)
  onItemTap: (row, index) {
    // Still called after navigation
    print('Tapped item: ${row['name']}');
  },
  itemBuilder: (context, row, index) {
    return ItemTile(item: row);
  },
)
```

## Pagination & Load More

```dart
CyberListView(
  pageSize: 20,
  onLoadData: (pageIndex, pageSize, searchText) async {
    // pageIndex tự động tăng khi scroll đến cuối
    print('Loading page: $pageIndex');
    return await api.getItems(
      skip: pageIndex * pageSize,
      take: pageSize,
      search: searchText,
    );
  },
  itemBuilder: (context, row, index) {
    return ItemTile(item: row);
  },
)
```

## Pull to Refresh

```dart
// Tự động có RefreshIndicator
// Kéo xuống để refresh về page 0
CyberListView(
  onLoadData: (pageIndex, pageSize, searchText) async {
    // pageIndex = 0 khi refresh
    return await api.getItems(pageIndex, pageSize);
  },
  itemBuilder: (context, row, index) {
    return ItemTile(item: row);
  },
)
```

## Complete Example

```dart
class ProductListView extends StatefulWidget {
  @override
  State<ProductListView> createState() => _ProductListViewState();
}

class _ProductListViewState extends State<ProductListView> {
  final CyberDataTable dataTable = CyberDataTable(tableName: 'Products');
  late CyberDataTable swipeActions;
  late CyberDataTable menuActions;
  late CyberDataTable toolbarActions;

  @override
  void initState() {
    super.initState();
    _setupActions();
  }

  void _setupActions() {
    // Swipe actions
    swipeActions = CyberDataTable(tableName: 'Swipe');
    swipeActions.addRow(CyberDataRow()..setValues({
      'bar': 'Sửa', 'icon': 'edit',
      'backcolor': '#4CAF50', 'textcolor': '#FFFFFF',
    }));
    swipeActions.addRow(CyberDataRow()..setValues({
      'bar': 'Xóa', 'icon': 'delete',
      'backcolor': '#F44336', 'textcolor': '#FFFFFF',
    }));

    // Menu actions
    menuActions = CyberDataTable(tableName: 'Menu');
    menuActions.addRow(CyberDataRow()..setValues({
      'bar': 'Chi tiết', 'icon': 'info',
    }));
    menuActions.addRow(CyberDataRow()..setValues({
      'bar': 'Chia sẻ', 'icon': 'share',
    }));

    // Toolbar actions
    toolbarActions = CyberDataTable(tableName: 'Toolbar');
    toolbarActions.addRow(CyberDataRow()..setValues({
      'bar': 'Thêm', 'icon': 'add',
      'backcolor': '#2196F3', 'showlabel': true,
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sản phẩm')),
      body: CyberListView(
        showSearchBox: true,
        pageSize: 20,
        dataSource: dataTable,
        dtSwipeActions: swipeActions,
        menuDataTable: menuActions,
        dtToolbarActions: toolbarActions,
        onLoadData: (pageIndex, pageSize, searchText) async {
          final response = await api.getProducts(
            page: pageIndex,
            size: pageSize,
            search: searchText,
          );
          return response.toCyberDataTable();
        },
        onSwipeActionTap: (swipeRow, sourceRow, index) {
          if (swipeRow['bar'] == 'Sửa') {
            editProduct(sourceRow);
          } else if (swipeRow['bar'] == 'Xóa') {
            deleteProduct(sourceRow);
          }
        },
        onMenuItemTap: (menuRow, sourceRow, index) {
          print('Menu: ${menuRow['bar']}');
        },
        onToolbarActionTap: (actionRow) {
          if (actionRow['bar'] == 'Thêm') {
            addProduct();
          }
        },
        itemBuilder: (context, row, index) {
          return Card(
            child: ListTile(
              leading: Icon(Icons.shopping_bag),
              title: Text(row['name']?.toString() ?? ''),
              subtitle: Text('${row['price']} VNĐ'),
              trailing: Icon(Icons.chevron_right),
            ),
          );
        },
      ),
    );
  }
}
```

## Tips & Best Practices

### ✅ DO

```dart
// ✅ Use external dataSource for better control
final dataTable = CyberDataTable();
CyberListView(dataSource: dataTable)

// ✅ Provide meaningful icons
'edit', 'delete', 'info', 'share', 'add'

// ✅ Handle errors in onLoadData
onLoadData: (page, size, search) async {
  try {
    return await api.load();
  } catch (e) {
    return CyberDataTable();
  }
}
```

### ❌ DON'T

```dart
// ❌ Don't forget to return CyberDataTable
onLoadData: (page, size, search) async {
  await api.load();  // ❌ No return
}

// ❌ Don't use both dataSource and onLoadData
// Choose one approach
```

---

## Xem Thêm

- [CyberLookup](./CyberLookup.md) - Lookup control
- [CyberDataTable](./CyberDataTable.md) - Data table system
