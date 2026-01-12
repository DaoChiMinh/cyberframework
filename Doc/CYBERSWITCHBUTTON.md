# CyberSwitchButton

## 📋 Mô tả

`CyberSwitchButton` là một segmented control/switch button widget với thiết kế hiện đại, smooth animation và dễ dàng tùy chỉnh. Khác với `CyberTabView`, control này không có child widgets mà chỉ tập trung vào việc chuyển đổi giữa các options và xử lý events.

## ✨ Tính năng chính

### 🎯 Core Features
- ✅ **Event-driven**: Chỉ xử lý sự kiện chọn, không quản lý child views
- ✅ **Smooth Animation**: Animation mượt mà khi chuyển đổi
- ✅ **Badge Support**: Hiển thị badge đếm số lượng
- ✅ **Icon Support**: Hỗ trợ icon cho mỗi option
- ✅ **Disabled State**: Có thể disable từng option riêng lẻ
- ✅ **Scrollable**: Hỗ trợ scroll khi có nhiều options
- ✅ **Responsive**: Auto scroll đến option được chọn

### 🎨 Styling
- ✅ Custom colors (background, selected, text)
- ✅ Border radius tùy chỉnh
- ✅ Shadow options
- ✅ Spacing và margin tùy chỉnh
- ✅ Height tùy chỉnh

### 📐 Layout
- ✅ Fixed width (expanded): Options chia đều không gian
- ✅ Dynamic width: Width tự động theo nội dung
- ✅ Scrollable: Scroll ngang khi có nhiều options

## 🚀 Sử dụng cơ bản

### 1. Simple Switch (Yes/No)

```dart
CyberSwitchButton(
  options: const [
    CyberSwitchOption(label: 'Có', value: true),
    CyberSwitchOption(label: 'Không', value: false),
  ],
  onChanged: (index, value, option) {
    print('Selected: ${option.label} - Value: $value');
  },
)
```

### 2. Switch với Icons

```dart
CyberSwitchButton(
  options: const [
    CyberSwitchOption(
      label: 'Grid',
      value: 'grid',
      icon: Icons.grid_view,
    ),
    CyberSwitchOption(
      label: 'List',
      value: 'list',
      icon: Icons.view_list,
    ),
    CyberSwitchOption(
      label: 'Card',
      value: 'card',
      icon: Icons.view_agenda,
    ),
  ],
  onChanged: (index, value, option) {
    // Handle view mode change
  },
)
```

### 3. Switch với Badge

```dart
CyberSwitchButton(
  options: [
    CyberSwitchOption(
      label: 'Inbox',
      value: 'inbox',
      icon: Icons.inbox,
      badgeCount: 25,
      badgeColor: Colors.red,
    ),
    CyberSwitchOption(
      label: 'Sent',
      value: 'sent',
      icon: Icons.send,
    ),
    CyberSwitchOption(
      label: 'Draft',
      value: 'draft',
      icon: Icons.drafts,
      badgeCount: 3,
      badgeColor: Colors.orange,
    ),
  ],
  onChanged: (index, value, option) {
    // Handle folder change
  },
)
```

### 4. Custom Colors

```dart
CyberSwitchButton(
  options: const [
    CyberSwitchOption(label: 'Ngày', value: 'day'),
    CyberSwitchOption(label: 'Tuần', value: 'week'),
    CyberSwitchOption(label: 'Tháng', value: 'month'),
  ],
  selectedColor: Colors.purple[700],
  selectedTextColor: Colors.white,
  textColor: Colors.purple[900],
  backgroundColor: Colors.purple[50],
  borderRadius: BorderRadius.circular(24),
  height: 50,
  onChanged: (index, value, option) {
    // Handle period change
  },
)
```

### 5. Scrollable Long List

```dart
CyberSwitchButton(
  options: List.generate(
    10,
    (index) => CyberSwitchOption(
      label: 'Tab ${index + 1}',
      value: index + 1,
    ),
  ),
  isScrollable: true,        // ✅ Enable scroll
  isExpanded: false,         // ✅ Dynamic width
  onChanged: (index, value, option) {
    // Handle tab change
  },
)
```

### 6. Disabled Options

```dart
CyberSwitchButton(
  options: const [
    CyberSwitchOption(
      label: 'Active',
      value: 'active',
      enabled: true,
    ),
    CyberSwitchOption(
      label: 'Disabled',
      value: 'disabled',
      enabled: false,         // ✅ Disabled
    ),
    CyberSwitchOption(
      label: 'Available',
      value: 'available',
      enabled: true,
    ),
  ],
  onChanged: (index, value, option) {
    // Only enabled options can be selected
  },
)
```

## 📦 API Reference

### CyberSwitchButton

#### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `options` | `List<CyberSwitchOption>` | **required** | Danh sách options |
| `initialIndex` | `int` | `0` | Index được chọn ban đầu |
| `onChanged` | `Function(int, dynamic, CyberSwitchOption)?` | `null` | Callback khi option được chọn |
| `backgroundColor` | `Color?` | `Color(0xFFE8F5E9)` | Màu nền |
| `selectedColor` | `Color?` | `Color.fromARGB(255, 224, 224, 224)` | Màu nền option được chọn |
| `textColor` | `Color?` | `Color(0xFF2E7D32)` | Màu chữ |
| `selectedTextColor` | `Color?` | `Colors.white` | Màu chữ option được chọn |
| `borderRadius` | `BorderRadius?` | `BorderRadius.circular(18)` | Bo góc |
| `spacing` | `double?` | `2.0` | Khoảng cách giữa các options |
| `padding` | `EdgeInsets?` | `EdgeInsets.all(4)` | Padding container |
| `margin` | `EdgeInsets?` | `EdgeInsets.symmetric(...)` | Margin container |
| `height` | `double?` | `null` | Chiều cao cố định |
| `isScrollable` | `bool` | `false` | Enable horizontal scroll |
| `isExpanded` | `bool` | `true` | Options chia đều không gian |
| `animationDuration` | `Duration?` | `Duration(milliseconds: 250)` | Thời gian animation |
| `animationCurve` | `Curve?` | `Curves.easeInOut` | Curve animation |
| `showShadow` | `bool` | `true` | Hiển thị shadow |
| `shadowBlurRadius` | `double?` | `8.0` | Shadow blur radius |
| `shadowOffset` | `Offset?` | `Offset(0, 2)` | Shadow offset |

### CyberSwitchOption

#### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `label` | `String` | **required** | Nhãn hiển thị |
| `value` | `dynamic` | `null` | Giá trị trả về khi chọn |
| `icon` | `IconData?` | `null` | Icon hiển thị |
| `badgeCount` | `int?` | `null` | Số đếm badge |
| `badgeColor` | `Color?` | `null` | Màu badge |
| `enabled` | `bool` | `true` | Enable/disable option |

## 🎨 Use Cases

### 1. Filter/Sort Control
```dart
CyberSwitchButton(
  options: const [
    CyberSwitchOption(label: 'Tất cả', value: 'all'),
    CyberSwitchOption(label: 'Đang xử lý', value: 'processing'),
    CyberSwitchOption(label: 'Hoàn thành', value: 'completed'),
  ],
  onChanged: (index, value, option) {
    // Filter data by selected value
    filterData(value);
  },
)
```

### 2. Theme Switcher
```dart
CyberSwitchButton(
  options: const [
    CyberSwitchOption(
      label: 'Sáng',
      value: ThemeMode.light,
      icon: Icons.wb_sunny,
    ),
    CyberSwitchOption(
      label: 'Tối',
      value: ThemeMode.dark,
      icon: Icons.nightlight,
    ),
    CyberSwitchOption(
      label: 'Auto',
      value: ThemeMode.system,
      icon: Icons.brightness_auto,
    ),
  ],
  onChanged: (index, value, option) {
    // Change app theme
    changeTheme(value as ThemeMode);
  },
)
```

### 3. Status Filter với State Management
```dart
class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberSwitchButton(
          options: const [
            CyberSwitchOption(label: 'Tất cả', value: 'all'),
            CyberSwitchOption(label: 'Đang xử lý', value: 'processing'),
            CyberSwitchOption(label: 'Hoàn thành', value: 'completed'),
          ],
          onChanged: (index, value, option) {
            setState(() {
              _selectedFilter = value;
            });
          },
        ),
        Expanded(
          child: _buildFilteredList(_selectedFilter),
        ),
      ],
    );
  }

  Widget _buildFilteredList(String filter) {
    // Build list based on filter
  }
}
```

### 4. Multi-criteria Filtering
```dart
class FilterState {
  String status = 'all';
  String priority = 'all';
  String assignee = 'all';
}

CyberSwitchButton(
  options: const [
    CyberSwitchOption(label: 'Tất cả', value: 'all'),
    CyberSwitchOption(label: 'Cao', value: 'high', badgeCount: 5),
    CyberSwitchOption(label: 'Trung bình', value: 'medium', badgeCount: 12),
    CyberSwitchOption(label: 'Thấp', value: 'low', badgeCount: 3),
  ],
  onChanged: (index, value, option) {
    filterState.priority = value;
    refreshData();
  },
)
```

## ⚡ Performance Tips

1. **Use ValueKey**: Options tự động có ValueKey để tránh rebuild không cần thiết
2. **Optimize callbacks**: Không thực hiện heavy operations trong `onChanged`, sử dụng debounce nếu cần
3. **Limit options**: Nếu có quá nhiều options (>20), xem xét sử dụng dropdown thay vì switch
4. **isScrollable**: Enable khi có nhiều hơn 5 options

## 🔄 So sánh với CyberTabView

| Feature | CyberSwitchButton | CyberTabView |
|---------|------------------|--------------|
| **Purpose** | Switch/Filter control | Tab navigation |
| **Child Views** | ❌ Không có | ✅ Có |
| **Event Handling** | ✅ Simple callback | ✅ Tab change callback |
| **Use Case** | Filter, toggle, switch | Multi-page navigation |
| **Performance** | 🚀 Lightweight | 🔄 View caching |
| **Complexity** | ⭐ Simple | ⭐⭐⭐ Complex |

## 🎯 Khi nào sử dụng?

### ✅ Sử dụng CyberSwitchButton khi:
- Chuyển đổi giữa các options/modes
- Filter/sort dữ liệu
- Toggle settings
- Status selection
- View mode switching
- Không cần hiển thị child widgets

### ❌ Không nên dùng khi:
- Cần hiển thị các view/screen khác nhau cho mỗi option → Dùng `CyberTabView`
- Quá nhiều options (>20) → Dùng Dropdown/Menu
- Cần hierachical navigation → Dùng Drawer/NavigationRail

## 📝 Notes

1. **Value Type**: `value` có thể là bất kỳ type nào (String, int, enum, object, etc.)
2. **Callback Parameters**: `onChanged` trả về 3 tham số:
   - `index`: Index của option được chọn
   - `value`: Value của option (hoặc index nếu value = null)
   - `option`: Object CyberSwitchOption đầy đủ
3. **Initial Selection**: Sử dụng `initialIndex` để set option được chọn ban đầu
4. **Disabled Options**: Options với `enabled: false` sẽ bị disable và không thể chọn

## 🐛 Troubleshooting

### Switch không hoạt động
```dart
// ❌ Sai: Không có callback
CyberSwitchButton(
  options: [...],
)

// ✅ Đúng: Có callback
CyberSwitchButton(
  options: [...],
  onChanged: (index, value, option) {
    // Handle change
  },
)
```

### Options bị cắt khi nhiều
```dart
// ✅ Enable scrollable
CyberSwitchButton(
  options: [...many options...],
  isScrollable: true,
  isExpanded: false,
  onChanged: (index, value, option) {},
)
```

### Animation không mượt
```dart
// ✅ Adjust animation settings
CyberSwitchButton(
  options: [...],
  animationDuration: Duration(milliseconds: 200),
  animationCurve: Curves.easeOut,
  onChanged: (index, value, option) {},
)
```

## 📚 Examples

Xem file `cyberswitchbutton_example.dart` để biết thêm chi tiết về các use cases khác nhau.

## 🤝 Contributing

Nếu bạn muốn thêm tính năng hoặc cải thiện control này, hãy tạo pull request hoặc issue trên repository.
