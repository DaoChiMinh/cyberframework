# CyberGrid - Hướng dẫn sử dụng (Updated)

## Tổng quan

`CyberGrid` giờ hỗ trợ quản lý chiều cao rows với 2 thuộc tính mới:

- **height**: Chiều cao tổng của grid
- **heightRows**: Định nghĩa chiều cao cho từng row

---

## 1. Basic Usage (Không dùng height)

### Grid tự động theo content

```dart
CyberGrid(
  children: [
    GridRow(
      widthColumn: "*, *",
      columns: [
        CyberText(text: row.bind("field1"), label: "Field 1"),
        CyberText(text: row.bind("field2"), label: "Field 2"),
      ],
    ),
    GridRow(
      widthColumn: "*",
      columns: [
        CyberText(text: row.bind("field3"), label: "Field 3"),
      ],
    ),
  ],
)
```

---

## 2. Height Management

### Example 1: Chia đều 2 rows

```dart
CyberGrid(
  height: 400, // Tổng chiều cao
  heightRows: "*,*", // 2 rows, mỗi row 1/2 = 200px
  children: [
    GridRow(
      widthColumn: "*, *",
      columns: [
        Container(color: Colors.blue[100], child: Center(child: Text("Row 1"))),
        Container(color: Colors.green[100], child: Center(child: Text("Row 1"))),
      ],
    ),
    GridRow(
      widthColumn: "*",
      columns: [
        Container(color: Colors.red[100], child: Center(child: Text("Row 2"))),
      ],
    ),
  ],
)
```

**Kết quả:**

- Row 1: 200px (50%)
- Row 2: 200px (50%)

---

### Example 2: Row giữa Auto, 2 rows còn lại chia đều

```dart
CyberGrid(
  height: 500,
  heightRows: "*,Auto,*", // Row 2 auto, row 1 & 3 chia đều
  rowSpac: 0, // Không có spacing để dễ tính
  padding: EdgeInsets.zero,
  children: [
    GridRow(
      widthColumn: "*",
      columns: [
        Container(
          color: Colors.blue[100],
          child: Center(child: Text("Row 1 - Flexible")),
        ),
      ],
    ),
    GridRow(
      widthColumn: "*",
      columns: [
        Container(
          height: 80, // Auto sẽ lấy height này
          color: Colors.green[100],
          child: Center(child: Text("Row 2 - Auto (80px)")),
        ),
      ],
    ),
    GridRow(
      widthColumn: "*",
      columns: [
        Container(
          color: Colors.red[100],
          child: Center(child: Text("Row 3 - Flexible")),
        ),
      ],
    ),
  ],
)
```

**Kết quả:**

- Row 1: 210px (50% của 420px còn lại)
- Row 2: 80px (Auto)
- Row 3: 210px (50% của 420px còn lại)

---

### Example 3: Row giữa cố định 60px

```dart
CyberGrid(
  height: 500,
  heightRows: "*,60,*", // Row 2 cố định 60px
  rowSpac: 0,
  padding: EdgeInsets.zero,
  children: [
    GridRow(
      widthColumn: "*",
      columns: [
        Container(
          color: Colors.blue[100],
          child: Center(child: Text("Row 1 - Flexible")),
        ),
      ],
    ),
    GridRow(
      widthColumn: "*",
      columns: [
        Container(
          color: Colors.yellow[100],
          child: Center(child: Text("Row 2 - Fixed 60px")),
        ),
      ],
    ),
    GridRow(
      widthColumn: "*",
      columns: [
        Container(
          color: Colors.red[100],
          child: Center(child: Text("Row 3 - Flexible")),
        ),
      ],
    ),
  ],
)
```

**Kết quả:**

- Row 1: 220px (50% của 440px còn lại)
- Row 2: 60px (Fixed)
- Row 3: 220px (50% của 440px còn lại)

---

### Example 4: Tỷ lệ khác nhau (2*, *, \*)

```dart
CyberGrid(
  height: 600,
  heightRows: "2*,*,*", // Row 1 gấp đôi row 2 và 3
  rowSpac: 0,
  padding: EdgeInsets.zero,
  children: [
    GridRow(
      widthColumn: "*",
      columns: [
        Container(
          color: Colors.blue[100],
          child: Center(child: Text("Row 1 - 2*")),
        ),
      ],
    ),
    GridRow(
      widthColumn: "*",
      columns: [
        Container(
          color: Colors.green[100],
          child: Center(child: Text("Row 2 - *")),
        ),
      ],
    ),
    GridRow(
      widthColumn: "*",
      columns: [
        Container(
          color: Colors.red[100],
          child: Center(child: Text("Row 3 - *")),
        ),
      ],
    ),
  ],
)
```

**Kết quả:**

- Total multiplier: 2 + 1 + 1 = 4
- Row 1: 300px (2/4 = 50%)
- Row 2: 150px (1/4 = 25%)
- Row 3: 150px (1/4 = 25%)

---

## 3. Real-World Examples

### Example: Dashboard Layout

```dart
class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dashboard')),
      body: CyberGrid(
        height: MediaQuery.of(context).size.height - kToolbarHeight - 24,
        heightRows: "Auto,*,100", // Header auto, content flex, footer 100
        rowSpac: 8,
        padding: EdgeInsets.all(16),
        children: [
          // Header
          GridRow(
            widthColumn: "*",
            columns: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome back!",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text("Dashboard Overview"),
                  ],
                ),
              ),
            ],
          ),

          // Main content
          GridRow(
            widthColumn: "*, *",
            spacing: 8,
            columns: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(child: Text("Chart")),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(child: Text("Stats")),
              ),
            ],
          ),

          // Footer
          GridRow(
            widthColumn: "*",
            columns: [
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {},
                        child: Text("Action 1"),
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        child: Text("Action 2"),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

---

### Example: Form với Header/Content/Footer

```dart
class FormScreen extends StatefulWidget {
  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  late CyberDataTable dt;
  late CyberDataRow row;

  @override
  void initState() {
    super.initState();
    dt = CyberDataTable(tableName: "User");
    dt.addColumn("name", CyberDataType.text);
    dt.addColumn("email", CyberDataType.text);
    dt.addColumn("phone", CyberDataType.text);

    row = dt.newRow();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: SafeArea(
        child: CyberGrid(
          height: screenHeight - MediaQuery.of(context).padding.top,
          heightRows: "80,*,70", // Header 80, Content flex, Footer 70
          rowSpac: 0,
          padding: EdgeInsets.zero,
          children: [
            // Header
            GridRow(
              widthColumn: "*",
              columns: [
                Container(
                  color: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        "Thông tin cá nhân",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Content
            GridRow(
              widthColumn: "*",
              columns: [
                SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CyberText(
                        text: row.bind("name"),
                        label: "Họ và tên",
                        hint: "Nhập họ tên",
                      ),
                      SizedBox(height: 16),
                      CyberText(
                        text: row.bind("email"),
                        label: "Email",
                        hint: "Nhập email",
                      ),
                      SizedBox(height: 16),
                      CyberText(
                        text: row.bind("phone"),
                        label: "Số điện thoại",
                        hint: "Nhập số điện thoại",
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Footer
            GridRow(
              widthColumn: "*",
              columns: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.1),
                        blurRadius: 4,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: CyberButton(
                      label: "Lưu",
                      onClick: () {
                        // Save logic
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### Example: Split View (Master-Detail)

```dart
class SplitViewScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CyberGrid(
          height: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
          heightRows: "*", // Single row
          padding: EdgeInsets.zero,
          children: [
            GridRow(
              widthColumn: "300,*", // Master 300px, Detail flex
              spacing: 0,
              columns: [
                // Master (List)
                Container(
                  color: Colors.grey[200],
                  child: ListView.builder(
                    itemCount: 20,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text("Item $index"),
                        onTap: () {
                          // Select item
                        },
                      );
                    },
                  ),
                ),

                // Detail
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text("Select an item to view details"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 4. HeightRows Syntax Reference

### Basic Patterns

| Pattern     | Description            | Example (height=400) |
| ----------- | ---------------------- | -------------------- |
| `"*,*"`     | 2 rows, chia đều       | 200px, 200px         |
| `"*,*,*"`   | 3 rows, chia đều       | 133px, 133px, 133px  |
| `"2*,*"`    | Row 1 gấp đôi row 2    | 267px, 133px         |
| `"*,60"`    | Row 2 cố định 60       | 340px, 60px          |
| `"Auto,*"`  | Row 1 auto, row 2 flex | Auto, (400-auto)     |
| `"80,*,60"` | Header/Content/Footer  | 80px, 260px, 60px    |

### Complex Patterns

```dart
// 4 rows: Header, Toolbar, Content, Footer
heightRows: "60,40,*,80"
// Results: 60px, 40px, 220px, 80px (total=400)

// 3 rows với tỷ lệ 3:2:1
heightRows: "3*,2*,*"
// Results: 200px, 133px, 67px (total=400)

// Multiple fixed + flex
heightRows: "50,*,60,*,40"
// Results: 50px, 125px, 60px, 125px, 40px (total=400)
```

---

## 5. With Spacing

### Spacing ảnh hưởng tính toán

```dart
CyberGrid(
  height: 400,
  heightRows: "*,*",
  rowSpac: 20, // Spacing = 20
  padding: EdgeInsets.all(10), // Padding = 20 (top+bottom)
  children: [...],
)
```

**Tính toán:**

- Total height: 400
- Padding vertical: 20
- Spacing: 20
- Available for rows: 400 - 20 - 20 = 360
- Each row: 360 / 2 = 180px

---

## 6. Best Practices

### ✅ DO - Nên làm

```dart
// ✅ Sử dụng height + heightRows cho layout cố định
CyberGrid(
  height: 600,
  heightRows: "80,*,60",
  children: [...],
)

// ✅ Sử dụng Auto cho dynamic content
CyberGrid(
  height: 500,
  heightRows: "*,Auto,*",
  children: [...],
)

// ✅ Combine với MediaQuery
CyberGrid(
  height: MediaQuery.of(context).size.height - 100,
  heightRows: "*,100",
  children: [...],
)
```

### ❌ DON'T - Không nên làm

```dart
// ❌ Quên set height khi dùng heightRows
CyberGrid(
  heightRows: "*,*", // Không hoạt động!
  children: [...],
)

// ❌ heightRows không khớp số lượng children
CyberGrid(
  height: 400,
  heightRows: "*,*", // 2 definitions
  children: [
    GridRow(...), // Row 1
    GridRow(...), // Row 2
    GridRow(...), // Row 3 - Không có height!
  ],
)

// ❌ Sử dụng height quá nhỏ
CyberGrid(
  height: 100, // Quá nhỏ
  heightRows: "80,*,60", // Total fixed = 140 > 100!
  children: [...],
)
```

---

## 7. Migration Guide

### Old Code (No height management)

```dart
CyberGrid(
  children: [
    GridRow(widthColumn: "*", columns: [...]),
    GridRow(widthColumn: "*", columns: [...]),
  ],
)
```

### New Code (With height management)

```dart
CyberGrid(
  height: 400,
  heightRows: "*,*",
  children: [
    GridRow(widthColumn: "*", columns: [...]),
    GridRow(widthColumn: "*", columns: [...]),
  ],
)
```

---

## Feature Summary

✅ **height** - Set tổng chiều cao cho grid
✅ **heightRows** - Định nghĩa chiều cao từng row
✅ Support `*` (star/flex)
✅ Support `Auto` (theo content)
✅ Support `Number` (fixed height)
✅ Support multiplier (`2*`, `3*`)
✅ Tự động tính toán spacing và padding
✅ Backward compatible (không bắt buộc dùng height)
