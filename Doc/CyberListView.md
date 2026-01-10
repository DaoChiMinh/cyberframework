# CyberListView - Advanced List & Grid Widget

## Mục Lục
1. [Giới Thiệu](#giới-thiệu)
2. [Core Properties](#core-properties)
3. [Data Loading](#data-loading)
4. [Layout Modes](#layout-modes)
5. [Item Interaction](#item-interaction)
6. [Swipe Actions](#swipe-actions)
7. [Search & Filter](#search--filter)
8. [CyberAction Integration](#cyberaction-integration)
9. [Ví Dụ Sử Dụng](#ví-dụ-sử-dụng)
10. [Best Practices](#best-practices)
11. [Troubleshooting](#troubleshooting)

---

## Giới Thiệu

CyberListView là **universal list widget** với hơn 50+ properties để tùy chỉnh hiển thị danh sách dữ liệu. Support ListView, GridView, Horizontal, pagination, swipe actions, search, và nhiều tính năng enterprise-grade khác.

### Đặc Điểm Chính

- ✅ **Multiple Layouts**: ListView, GridView, Horizontal scroll
- ✅ **Auto Pagination**: Load more khi scroll đến cuối
- ✅ **Pull to Refresh**: Swipe down để refresh
- ✅ **Search Box**: Built-in search với debounce
- ✅ **Swipe Actions**: Swipe để hiện actions (iOS style)
- ✅ **Delete Support**: Swipe to delete với confirmation
- ✅ **Long Press Menu**: Bottom sheet menu
- ✅ **Toolbar Actions**: Actions bên cạnh search
- ✅ **CyberAction**: Floating action button integration
- ✅ **Empty/Loading States**: Customizable placeholders
- ✅ **Height Control**: Fixed, expanded, shrink-wrap
- ✅ **Responsive**: Auto height items trong grid

### Import

```dart
import 'package:cyberframework/cyberframework.dart';
```

---

## Core Properties

### Required Properties

```dart
CyberListView(
  itemBuilder: (context, row, index) => Widget,  // REQUIRED
)
```

### Data Source

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `dataSource` | `CyberDataTable?` | null | Static data source |
| `onLoadData` | `FutureDataCallback?` | null | Dynamic data loading |

### Item Builder

| Property | Type | Description |
|----------|------|-------------|
| `itemBuilder` | `ItemBuilder` | Build UI cho mỗi item (REQUIRED) |

### Layout Options

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `columnCount` | `int` | 1 | Số cột (1=ListView, >1=GridView) |
| `horizontal` | `bool` | false | Cuộn ngang |
| `autoItemHeight` | `bool` | false | Tự động chiều cao item (grid) |
| `height` | `dynamic` | null | Chiều cao: null/double/"*" |
| `padding` | `EdgeInsets?` | EdgeInsets.all(8) | Padding |
| `separator` | `Widget?` | Divider | Separator giữa items |

### Pagination

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `pageSize` | `int` | 20 | Số items mỗi page |

### Search & Filter

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `showSearchBox` | `bool` | false | Hiện search box |
| `searchDebounceTime` | `int` | 500 | Debounce time (ms) |
| `columnsFilter` | `List<String>?` | null | Cột để search (local) |

### Item Interaction

| Property | Type | Description |
|----------|------|-------------|
| `onItemTap` | `ItemTapCallback?` | Callback khi tap item |
| `onItemLongPress` | `ItemLongPressCallback?` | Callback khi long press |
| `isClickToScreen` | `bool` | Auto navigate khi tap |

### Swipe Actions

| Property | Type | Description |
|----------|------|-------------|
| `dtSwipeActions` | `CyberDataTable?` | Swipe actions data |
| `onSwipeActionTap` | `SwipeActionCallback?` | Callback khi tap action |
| `isSwipeActionClickToScreen` | `bool` | Auto navigate |
| `isDelete` | `bool` | Enable swipe to delete |
| `onDelete` | `DeleteCallback?` | Delete callback |

### Long Press Menu

| Property | Type | Description |
|----------|------|-------------|
| `menuDataTable` | `CyberDataTable?` | Menu items data |
| `onMenuItemTap` | `MenuItemTapCallback?` | Callback khi tap menu |
| `isMenuClickToScreen` | `bool` | Auto navigate |

### Toolbar Actions

| Property | Type | Description |
|----------|------|-------------|
| `dtToolbarActions` | `CyberDataTable?` | Toolbar actions data |
| `onToolbarActionTap` | `ToolbarActionCallback?` | Callback khi tap |
| `isToolbarActionClickToScreen` | `bool` | Auto navigate |

### Empty/Loading States

| Property | Type | Description |
|----------|------|-------------|
| `emptyWidget` | `Widget?` | Widget khi không có data |
| `loadingWidget` | `Widget?` | Loading indicator |

### Item Styling

| Property | Type | Description |
|----------|------|-------------|
| `itemBorderRadius` | `BorderRadius?` | Border radius cho item |
| `itemBackgroundColor` | `Color?` | Background color cho item |

### Advanced

| Property | Type | Description |
|----------|------|-------------|
| `scrollController` | `ScrollController?` | Custom scroll controller |
| `refreshKey` | `Object?` | Key để force refresh |

---

## Data Loading

### Static Data

```dart
final dt = CyberDataTable();
// ... load data vào dt

CyberListView(
  dataSource: dt,
  itemBuilder: (context, row, index) => ListTile(
    title: Text(row.getString('name')),
  ),
)
```

### Dynamic Loading (Recommended)

```dart
Future<CyberDataTable> loadData(
  int pageIndex,
  int pageSize,
  String strSearch,
) async {
  final result = await context.callApi(
    functionName: 'CP_GetProducts',
    parameter: '$pageIndex#$pageSize#$strSearch',
  );
  
  return result.toCyberDataset()?[0] ?? CyberDataTable();
}

CyberListView(
  dataSource: dt,  // For storing loaded data
  onLoadData: loadData,
  itemBuilder: (context, row, index) => ProductCard(row),
)
```

**onLoadData Benefits:**
- Auto pagination
- Pull to refresh
- Server-side search
- Load more khi scroll

---

## Layout Modes

### ListView (Default)

```dart
CyberListView(
  columnCount: 1,  // Default
  dataSource: dt,
  itemBuilder: (context, row, index) => ListTile(...),
)
```

### GridView

```dart
CyberListView(
  columnCount: 2,  // 2 columns
  crossAxisSpacing: 8,
  mainAxisSpacing: 8,
  childAspectRatio: 1.0,  // Square items
  dataSource: dt,
  itemBuilder: (context, row, index) => ProductCard(row),
)
```

### GridView với Auto Height

```dart
CyberListView(
  columnCount: 2,
  autoItemHeight: true,  // Items có chiều cao khác nhau
  crossAxisSpacing: 8,
  mainAxisSpacing: 8,
  dataSource: dt,
  itemBuilder: (context, row, index) => ProductCard(row),
)
```

### Horizontal ListView

```dart
CyberListView(
  horizontal: true,
  height: 200,  // Fixed height cho horizontal
  dataSource: dt,
  itemBuilder: (context, row, index) => CategoryCard(row),
)
```

### Height Options

```dart
// 1. Expanded (default) - Chiếm hết không gian
CyberListView(
  height: null,  // Default
  itemBuilder: ...,
)

// 2. Fixed height
CyberListView(
  height: 400,
  itemBuilder: ...,
)

// 3. Shrink-wrap (theo nội dung)
CyberListView(
  height: "*",
  itemBuilder: ...,
)
```

---

## Item Interaction

### On Tap

```dart
CyberListView(
  dataSource: dt,
  onItemTap: (row, index) {
    print('Tapped: ${row.getString('name')}');
  },
  itemBuilder: ...,
)
```

### Auto Navigate

```dart
// row cần có field: pagename, cpname, strparameter
CyberListView(
  dataSource: dt,
  isClickToScreen: true,  // Auto V_Call
  itemBuilder: ...,
)
```

### Long Press

```dart
CyberListView(
  dataSource: dt,
  onItemLongPress: (row, index) {
    print('Long pressed: ${row.getString('name')}');
  },
  itemBuilder: ...,
)
```

### Long Press Menu

```dart
final menuTable = CyberDataTable();
menuTable.addColumn('bar');
menuTable.addColumn('iconname');
menuTable.addColumn('pagename');

final editRow = menuTable.newRow();
editRow['bar'] = 'Edit';
editRow['iconname'] = 'edit';
editRow['pagename'] = 'EditForm';
menuTable.addRow(editRow);

CyberListView(
  dataSource: dt,
  menuDataTable: menuTable,
  onMenuItemTap: (menuRow, sourceRow, index) {
    print('Menu: ${menuRow.getString('bar')}');
  },
  itemBuilder: ...,
)
```

---

## Swipe Actions

### Basic Swipe Actions

```dart
final swipeActions = CyberDataTable();
swipeActions.addColumn('bar');
swipeActions.addColumn('icon');
swipeActions.addColumn('backcolor');
swipeActions.addColumn('textcolor');

// Edit action
final edit = swipeActions.newRow();
edit['bar'] = 'Edit';
edit['icon'] = 'edit';
edit['backcolor'] = '#4CAF50';
edit['textcolor'] = '#FFFFFF';
swipeActions.addRow(edit);

// Share action
final share = swipeActions.newRow();
share['bar'] = 'Share';
share['icon'] = 'share';
share['backcolor'] = '#2196F3';
share['textcolor'] = '#FFFFFF';
swipeActions.addRow(share);

CyberListView(
  dataSource: dt,
  dtSwipeActions: swipeActions,
  onSwipeActionTap: (swipeRow, sourceRow, index) {
    final action = swipeRow.getString('bar');
    if (action == 'Edit') {
      // Handle edit
    } else if (action == 'Share') {
      // Handle share
    }
  },
  itemBuilder: ...,
)
```

### Swipe to Delete

```dart
CyberListView(
  dataSource: dt,
  isDelete: true,
  onDelete: (row, index) async {
    // Call API to delete
    final result = await context.callApi(
      functionName: 'CP_Delete',
      parameter: row.getString('id'),
    );
    
    // Return true để xóa khỏi list
    // Return false để giữ lại
    return result.isValid();
  },
  itemBuilder: ...,
)
```

### Swipe Actions + Delete

```dart
CyberListView(
  dataSource: dt,
  dtSwipeActions: swipeActions,  // Edit, Share
  isDelete: true,                 // + Delete action
  onSwipeActionTap: ...,
  onDelete: ...,
  itemBuilder: ...,
)
```

---

## Search & Filter

### Local Search

```dart
CyberListView(
  dataSource: dt,
  showSearchBox: true,
  columnsFilter: ['name', 'description', 'category'],
  searchDebounceTime: 500,
  itemBuilder: ...,
)
```

### Server-Side Search

```dart
Future<CyberDataTable> loadData(
  int pageIndex,
  int pageSize,
  String strSearch,  // Search text từ user
) async {
  // strSearch được truyền vào tự động
  final result = await context.callApi(
    functionName: 'CP_Search',
    parameter: '$pageIndex#$pageSize#$strSearch',
  );
  
  return result.toCyberDataset()?[0] ?? CyberDataTable();
}

CyberListView(
  dataSource: dt,
  onLoadData: loadData,  // Auto search qua API
  showSearchBox: true,
  itemBuilder: ...,
)
```

### Toolbar Actions

```dart
final toolbarActions = CyberDataTable();
toolbarActions.addColumn('bar');
toolbarActions.addColumn('icon');
toolbarActions.addColumn('showlabel');

final filter = toolbarActions.newRow();
filter['bar'] = 'Filter';
filter['icon'] = 'filter_list';
filter['showlabel'] = false;
toolbarActions.addRow(filter);

CyberListView(
  dataSource: dt,
  showSearchBox: true,
  dtToolbarActions: toolbarActions,
  onToolbarActionTap: (actionRow) {
    // Show filter dialog
  },
  itemBuilder: ...,
)
```

---

## CyberAction Integration

### Floating Action Button

```dart
final actions = [
  CyberButtonAction(
    icon: Icons.add,
    label: 'Add',
    backgroundColor: Colors.blue,
    onPressed: () {
      // Add new item
    },
  ),
  CyberButtonAction(
    icon: Icons.refresh,
    label: 'Refresh',
    backgroundColor: Colors.green,
    onPressed: () {
      // Refresh list
    },
  ),
];

CyberListView(
  dataSource: dt,
  cyberActions: actions,
  cyberActionType: CyberActionType.autoShow,
  cyberActionBottom: 16,
  cyberActionRight: 16,
  itemBuilder: ...,
)
```

---

## Ví Dụ Sử Dụng

### 1. Simple ListView

```dart
class ProductListScreen extends CyberForm {
  final dt = CyberDataTable();
  
  @override
  Future<void> onLoadData() async {
    final result = await context.callApi(
      functionName: 'CP_GetProducts',
    );
    
    final ds = result.toCyberDataset();
    if (ds != null) {
      dt.loadDatafromTb(ds[0]);
    }
  }
  
  @override
  Widget buildBody(BuildContext context) {
    return CyberListView(
      dataSource: dt,
      itemBuilder: (context, row, index) {
        return ListTile(
          leading: CircleAvatar(
            child: Text('${index + 1}'),
          ),
          title: Text(row.getString('name')),
          subtitle: Text(row.getString('price')),
          trailing: Icon(Icons.arrow_forward_ios, size: 16),
        );
      },
    );
  }
}
```

### 2. GridView với Card

```dart
CyberListView(
  dataSource: dt,
  columnCount: 2,
  crossAxisSpacing: 12,
  mainAxisSpacing: 12,
  padding: EdgeInsets.all(16),
  itemBorderRadius: BorderRadius.circular(12),
  itemBuilder: (context, row, index) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Icon(Icons.image, size: 64),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.getString('name'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  row.getString('price'),
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  },
)
```

### 3. Pagination List

```dart
Future<CyberDataTable> loadProducts(
  int pageIndex,
  int pageSize,
  String search,
) async {
  final result = await context.callApi(
    functionName: 'CP_GetProducts',
    parameter: '$pageIndex#$pageSize#$search',
  );
  
  return result.toCyberDataset()?[0] ?? CyberDataTable();
}

CyberListView(
  dataSource: dt,
  onLoadData: loadProducts,  // Auto pagination
  pageSize: 20,
  itemBuilder: (context, row, index) => ProductCard(row),
)
```

### 4. List với Search

```dart
CyberListView(
  dataSource: dt,
  onLoadData: loadProducts,
  showSearchBox: true,
  searchDebounceTime: 500,
  itemBuilder: (context, row, index) {
    return ListTile(
      title: Text(row.getString('name')),
      subtitle: Text(row.getString('category')),
    );
  },
)
```

### 5. Swipe Actions List

```dart
final dt = CyberDataTable();
final swipeActions = CyberDataTable();

void setupSwipeActions() {
  swipeActions.addColumn('bar');
  swipeActions.addColumn('icon');
  swipeActions.addColumn('backcolor');
  swipeActions.addColumn('textcolor');
  
  // Edit
  final edit = swipeActions.newRow();
  edit['bar'] = 'Edit';
  edit['icon'] = 'edit';
  edit['backcolor'] = '#4CAF50';
  edit['textcolor'] = '#FFFFFF';
  swipeActions.addRow(edit);
  
  // Share
  final share = swipeActions.newRow();
  share['bar'] = 'Share';
  share['icon'] = 'share';
  share['backcolor'] = '#2196F3';
  share['textcolor'] = '#FFFFFF';
  swipeActions.addRow(share);
}

@override
Widget buildBody(BuildContext context) {
  return CyberListView(
    dataSource: dt,
    dtSwipeActions: swipeActions,
    isDelete: true,
    onSwipeActionTap: (swipeRow, sourceRow, index) {
      final action = swipeRow.getString('bar');
      if (action == 'Edit') {
        // Navigate to edit
        V_callform(
          context,
          'EditForm',
          'Edit',
          'CP_GetDetail',
          sourceRow.getString('id'),
          '',
        );
      }
    },
    onDelete: (row, index) async {
      final result = await context.callApi(
        functionName: 'CP_Delete',
        parameter: row.getString('id'),
      );
      return result.isValid();
    },
    itemBuilder: (context, row, index) => ListTile(
      title: Text(row.getString('name')),
    ),
  );
}
```

### 6. Long Press Menu

```dart
final menuTable = CyberDataTable();

void setupMenu() {
  menuTable.addColumn('bar');
  menuTable.addColumn('iconname');
  menuTable.addColumn('backcolor');
  menuTable.addColumn('textcolor');
  
  final items = [
    {'bar': 'View Details', 'icon': 'info', 'color': '#2196F3'},
    {'bar': 'Edit', 'icon': 'edit', 'color': '#4CAF50'},
    {'bar': 'Delete', 'icon': 'delete', 'color': '#F44336'},
  ];
  
  for (var item in items) {
    final row = menuTable.newRow();
    row['bar'] = item['bar'];
    row['iconname'] = item['icon'];
    row['backcolor'] = item['color'];
    row['textcolor'] = '#FFFFFF';
    menuTable.addRow(row);
  }
}

CyberListView(
  dataSource: dt,
  menuDataTable: menuTable,
  onMenuItemTap: (menuRow, sourceRow, index) {
    final action = menuRow.getString('bar');
    switch (action) {
      case 'View Details':
        // Show details
        break;
      case 'Edit':
        // Edit item
        break;
      case 'Delete':
        // Delete item
        break;
    }
  },
  itemBuilder: ...,
)
```

### 7. Horizontal Category List

```dart
CyberListView(
  dataSource: dtCategories,
  horizontal: true,
  height: 120,
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  separator: SizedBox(width: 12),
  itemBuilder: (context, row, index) {
    return Container(
      width: 100,
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category, size: 40),
          SizedBox(height: 8),
          Text(
            row.getString('name'),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  },
)
```

### 8. With CyberAction

```dart
final actions = [
  CyberButtonAction(
    icon: Icons.add,
    label: 'Add Product',
    backgroundColor: Colors.blue,
    onPressed: () {
      V_callform(context, 'AddProductForm', 'Add', '', '', '');
    },
  ),
  CyberButtonAction(
    icon: Icons.refresh,
    label: 'Refresh',
    backgroundColor: Colors.green,
    onPressed: () async {
      await loadData();
    },
  ),
];

CyberListView(
  dataSource: dt,
  cyberActions: actions,
  cyberActionBottom: 16,
  cyberActionRight: 16,
  itemBuilder: ...,
)
```

### 9. Auto Height Grid

```dart
CyberListView(
  dataSource: dt,
  columnCount: 2,
  autoItemHeight: true,
  crossAxisSpacing: 12,
  mainAxisSpacing: 12,
  itemBuilder: (context, row, index) {
    // Items có chiều cao khác nhau
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              row.getString('name'),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              row.getString('description'),
              maxLines: index % 2 == 0 ? 2 : 4,
            ),
          ],
        ),
      ),
    );
  },
)
```

### 10. With Toolbar Actions

```dart
final toolbarActions = CyberDataTable();

void setupToolbar() {
  toolbarActions.addColumn('bar');
  toolbarActions.addColumn('icon');
  toolbarActions.addColumn('showlabel');
  
  final filter = toolbarActions.newRow();
  filter['bar'] = 'Filter';
  filter['icon'] = 'filter_list';
  filter['showlabel'] = false;
  toolbarActions.addRow(filter);
  
  final sort = toolbarActions.newRow();
  sort['bar'] = 'Sort';
  sort['icon'] = 'sort';
  sort['showlabel'] = false;
  toolbarActions.addRow(sort);
}

CyberListView(
  dataSource: dt,
  showSearchBox: true,
  dtToolbarActions: toolbarActions,
  onToolbarActionTap: (actionRow) {
    final action = actionRow.getString('bar');
    if (action == 'Filter') {
      showFilterDialog();
    } else if (action == 'Sort') {
      showSortDialog();
    }
  },
  itemBuilder: ...,
)
```

### 11. Shrink-Wrap List

```dart
// List trong ScrollView khác
SingleChildScrollView(
  child: Column(
    children: [
      Text('Header'),
      
      CyberListView(
        height: "*",  // Shrink to content
        dataSource: dt,
        itemBuilder: ...,
      ),
      
      Text('Footer'),
    ],
  ),
)
```

### 12. Custom Empty State

```dart
CyberListView(
  dataSource: dt,
  emptyWidget: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
      SizedBox(height: 16),
      Text(
        'No products yet',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      SizedBox(height: 8),
      Text('Add your first product to get started'),
      SizedBox(height: 24),
      ElevatedButton(
        onPressed: () {
          V_callform(context, 'AddProductForm', '', '', '', '');
        },
        child: Text('Add Product'),
      ),
    ],
  ),
  itemBuilder: ...,
)
```

### 13. Custom Loading

```dart
CyberListView(
  dataSource: dt,
  onLoadData: loadData,
  loadingWidget: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      CircularProgressIndicator(),
      SizedBox(height: 16),
      Text('Loading products...'),
    ],
  ),
  itemBuilder: ...,
)
```

### 14. Refresh on Tab Change

```dart
class MyTabView extends StatefulWidget {
  @override
  State<MyTabView> createState() => _MyTabViewState();
}

class _MyTabViewState extends State<MyTabView> {
  int currentTab = 0;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(...),
        
        Expanded(
          child: CyberListView(
            refreshKey: currentTab,  // Force refresh khi đổi tab
            dataSource: dt,
            onLoadData: loadData,
            itemBuilder: ...,
          ),
        ),
      ],
    );
  }
}
```

### 15. Complete Example

```dart
class ProductListForm extends CyberForm {
  final dt = CyberDataTable();
  final swipeActions = CyberDataTable();
  final menuTable = CyberDataTable();
  final toolbarActions = CyberDataTable();
  
  @override
  void onInit() {
    super.onInit();
    setupSwipeActions();
    setupMenu();
    setupToolbar();
  }
  
  void setupSwipeActions() {
    swipeActions.addColumn('bar');
    swipeActions.addColumn('icon');
    swipeActions.addColumn('backcolor');
    swipeActions.addColumn('textcolor');
    
    final edit = swipeActions.newRow();
    edit['bar'] = 'Edit';
    edit['icon'] = 'edit';
    edit['backcolor'] = '#4CAF50';
    edit['textcolor'] = '#FFFFFF';
    swipeActions.addRow(edit);
  }
  
  void setupMenu() {
    menuTable.addColumn('bar');
    menuTable.addColumn('iconname');
    
    final view = menuTable.newRow();
    view['bar'] = 'View Details';
    view['iconname'] = 'info';
    menuTable.addRow(view);
  }
  
  void setupToolbar() {
    toolbarActions.addColumn('bar');
    toolbarActions.addColumn('icon');
    toolbarActions.addColumn('showlabel');
    
    final filter = toolbarActions.newRow();
    filter['bar'] = 'Filter';
    filter['icon'] = 'filter_list';
    filter['showlabel'] = false;
    toolbarActions.addRow(filter);
  }
  
  Future<CyberDataTable> loadData(
    int pageIndex,
    int pageSize,
    String search,
  ) async {
    final result = await context.callApi(
      functionName: 'CP_GetProducts',
      parameter: '$pageIndex#$pageSize#$search',
    );
    
    return result.toCyberDataset()?[0] ?? CyberDataTable();
  }
  
  @override
  Widget buildBody(BuildContext context) {
    return CyberListView(
      dataSource: dt,
      onLoadData: loadData,
      pageSize: 20,
      showSearchBox: true,
      dtSwipeActions: swipeActions,
      menuDataTable: menuTable,
      dtToolbarActions: toolbarActions,
      isDelete: true,
      
      onSwipeActionTap: (swipeRow, sourceRow, index) {
        // Handle swipe action
      },
      
      onMenuItemTap: (menuRow, sourceRow, index) {
        // Handle menu
      },
      
      onToolbarActionTap: (actionRow) {
        // Handle toolbar
      },
      
      onDelete: (row, index) async {
        final result = await context.callApi(
          functionName: 'CP_Delete',
          parameter: row.getString('id'),
        );
        return result.isValid();
      },
      
      cyberActions: [
        CyberButtonAction(
          icon: Icons.add,
          label: 'Add',
          backgroundColor: Colors.blue,
          onPressed: () {
            V_callform(context, 'AddForm', '', '', '', '');
          },
        ),
      ],
      
      itemBuilder: (context, row, index) {
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text('${index + 1}'),
            ),
            title: Text(row.getString('name')),
            subtitle: Text(row.getString('price')),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
          ),
        );
      },
    );
  }
}
```

---

## Best Practices

### 1. Use onLoadData for Dynamic Data

```dart
// ✅ GOOD: Server pagination
CyberListView(
  dataSource: dt,
  onLoadData: loadData,  // Auto pagination
  itemBuilder: ...,
)

// ❌ BAD: Load all at once
final allData = await loadAllData();  // 10000+ items
dt.loadDatafromTb(allData);
```

### 2. Use Local Search for Small Data

```dart
// ✅ GOOD: < 1000 items
CyberListView(
  dataSource: dt,
  showSearchBox: true,
  columnsFilter: ['name', 'category'],
  itemBuilder: ...,
)

// ✅ GOOD: > 1000 items
CyberListView(
  dataSource: dt,
  onLoadData: loadData,  // Server-side search
  showSearchBox: true,
  itemBuilder: ...,
)
```

### 3. Use Identity Keys

```dart
// ✅ GOOD: Stable keys
for (var row in dt.rows) {
  row.lockIdentity();  // Lock UUID
}

// ❌ BAD: No identity
// Items may rebuild unnecessarily
```

### 4. Optimize Item Builder

```dart
// ✅ GOOD: Simple builder
itemBuilder: (context, row, index) {
  return ProductCard(row: row, index: index);
}

// ❌ BAD: Heavy computation
itemBuilder: (context, row, index) {
  final computed = heavyComputation(row);  // Every rebuild
  return Widget(...);
}
```

### 5. Use Appropriate Height

```dart
// ✅ GOOD: In Scaffold
CyberListView(
  height: null,  // Expanded
  itemBuilder: ...,
)

// ✅ GOOD: In Column
CyberListView(
  height: 400,  // Fixed
  itemBuilder: ...,
)

// ✅ GOOD: In ScrollView
CyberListView(
  height: "*",  // Shrink-wrap
  itemBuilder: ...,
)
```

---

## Troubleshooting

### List not loading

**Nguyên nhân:** dataSource null và không có onLoadData

**Giải pháp:**
```dart
// ✅ CORRECT: Provide data source
final dt = CyberDataTable();

CyberListView(
  dataSource: dt,
  onLoadData: loadData,
  itemBuilder: ...,
)
```

### Pagination not working

**Nguyên nhân:** Missing onLoadData

**Giải pháp:**
```dart
// ✅ CORRECT: Implement onLoadData
Future<CyberDataTable> loadData(int page, int size, String search) async {
  // Return data
}
```

### Search too slow

**Nguyên nhân:** Searching large dataset locally

**Giải pháp:**
```dart
// ✅ CORRECT: Use server search
CyberListView(
  onLoadData: loadData,  // Search on server
  showSearchBox: true,
  itemBuilder: ...,
)
```

### Swipe not working

**Nguyên nhân:** Missing dtSwipeActions

**Giải pháp:**
```dart
// ✅ CORRECT: Setup swipe actions
final swipeActions = CyberDataTable();
// ... setup actions

CyberListView(
  dtSwipeActions: swipeActions,
  itemBuilder: ...,
)
```

### Delete confirmation not showing

**Nguyên nhân:** Built-in confirmation

**Giải pháp:**
```dart
// Confirmation dialog tự động hiện
// Chỉ cần implement onDelete

CyberListView(
  isDelete: true,
  onDelete: (row, index) async {
    // Return true to delete
    return true;
  },
  itemBuilder: ...,
)
```

---

## Tips & Tricks

### 1. Refresh từ bên ngoài

```dart
final GlobalKey<_CyberListViewState> listKey = GlobalKey();

CyberListView(
  key: listKey,
  dataSource: dt,
  onLoadData: loadData,
  itemBuilder: ...,
)

// Refresh from outside
listKey.currentState?.refresh();
```

### 2. Custom Debounce Time

```dart
// Fast search
CyberListView(
  showSearchBox: true,
  searchDebounceTime: 300,  // 300ms
  itemBuilder: ...,
)

// Slow network
CyberListView(
  showSearchBox: true,
  searchDebounceTime: 1000,  // 1s
  itemBuilder: ...,
)
```

### 3. Grid Aspect Ratio

```dart
// Square items
childAspectRatio: 1.0

// Portrait
childAspectRatio: 0.7

// Landscape
childAspectRatio: 1.5
```

### 4. Conditional Swipe

```dart
// Only show swipe for certain items
itemBuilder: (context, row, index) {
  final canEdit = row.getBool('can_edit');
  
  if (!canEdit) {
    // No swipe
    return ListTile(...);
  }
  
  // Has swipe (handled by widget)
  return ListTile(...);
}
```

### 5. Empty State với Action

```dart
emptyWidget: Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    Icon(Icons.inbox, size: 80),
    SizedBox(height: 16),
    Text('No data'),
    SizedBox(height: 16),
    ElevatedButton(
      onPressed: () {
        // Load sample data
      },
      child: Text('Load Sample'),
    ),
  ],
)
```

---

## Performance Tips

1. **Use pagination**: Don't load all data at once
2. **Lock identity**: Stable keys prevent rebuilds
3. **Optimize itemBuilder**: Keep it simple
4. **Use const**: Const widgets when possible
5. **Lazy load images**: Load images on demand
6. **Debounce search**: Default 500ms is good
7. **Use shrinkWrap wisely**: Only when needed
8. **Cache computed values**: Don't recompute on every build

---

## Version History

### 1.0.0
- Multiple layout modes (List, Grid, Horizontal)
- Auto pagination với load more
- Pull to refresh
- Search box với debounce
- Swipe actions (iOS style)
- Swipe to delete
- Long press menu
- Toolbar actions
- CyberAction integration
- Custom empty/loading states
- Height control (fixed, expanded, shrink-wrap)
- Auto height grid items
- Item styling (border radius, background)
- Refresh key support

---

## License

MIT License - CyberFramework
