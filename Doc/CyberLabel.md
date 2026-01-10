# CyberLabel - Read-Only Text/Icon Widget

## Mục Lục
1. [Giới Thiệu](#giới-thiệu)
2. [CyberLabel Widget](#cyberlabel-widget)
3. [Ví Dụ Sử Dụng](#ví-dụ-sử-dụng)
4. [Features](#features)
5. [Extensions](#extensions)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

---

## Giới Thiệu

`CyberLabel` là widget để hiển thị **read-only text hoặc icon** với **Data Binding** support. Widget này là stateless và được thiết kế để hiển thị dữ liệu, không cho phép chỉnh sửa.

### Đặc Điểm Chính

- ✅ **Stateless**: Lightweight, không state management
- ✅ **Data Binding**: Tự động update khi data thay đổi
- ✅ **Dual Mode**: Text hoặc Icon
- ✅ **Visibility Binding**: Hiển thị/ẩn dựa trên binding
- ✅ **Clickable**: Optional tap event với ripple effect
- ✅ **Format Support**: Format text theo pattern
- ✅ **MaxLines & Overflow**: Kiểm soát text truncation

### Import

```dart
import 'package:cyberframework/cyberframework.dart';
```

---

## CyberLabel Widget

### Constructor

```dart
const CyberLabel({
  super.key,
  this.text,
  this.format,
  this.style,
  this.textalign,
  this.textcolor,
  this.backgroundColor,
  this.isVisible = true,
  this.isIcon = false,
  this.iconSpacing,
  this.iconSize,
  this.onLeaver,
  this.showRipple,
  this.rippleColor,
  this.rippleBorderRadius,
  this.tapPadding,
  this.maxLines,
  this.overflow,
})
```

### Properties

#### Data

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `text` | `dynamic` | Text hoặc icon code (có thể binding) | null |
| `format` | `String?` | Format pattern | null |

#### Display Mode

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `isIcon` | `bool` | Icon mode (vs Text mode) | false |
| `iconSize` | `double?` | Kích thước icon | 24 |
| `iconSpacing` | `double?` | Spacing (deprecated) | null |

#### Text Styling

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `style` | `TextStyle?` | Text style | null |
| `textcolor` | `Color?` | Màu chữ | null |
| `textalign` | `TextAlign?` | Text alignment | null |
| `maxLines` | `int?` | Số dòng tối đa | null |
| `overflow` | `TextOverflow?` | Overflow behavior | ellipsis (if maxLines) |
| `backgroundColor` | `Color?` | Màu nền | null |

#### Visibility

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `isVisible` | `dynamic` | Hiển thị/ẩn (có thể binding) | true |

#### Interaction

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `onLeaver` | `Function(dynamic)?` | Callback khi tap | null |
| `showRipple` | `bool?` | Hiển thị ripple effect | true |
| `rippleColor` | `Color?` | Màu ripple | primary color |
| `rippleBorderRadius` | `BorderRadius?` | Bo góc ripple | 4 |
| `tapPadding` | `EdgeInsets?` | Padding cho tap area | (4, 2) |

---

## Ví Dụ Sử Dụng

### 1. Text Mode - Cơ Bản

Simple read-only text.

```dart
class UserInfo extends StatelessWidget {
  final drUser = CyberDataRow();

  UserInfo() {
    drUser['name'] = 'Nguyễn Văn A';
    drUser['email'] = 'nva@example.com';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tên:', style: TextStyle(fontWeight: FontWeight.bold)),
        CyberLabel(
          text: drUser.bind('name'),
          style: TextStyle(fontSize: 16),
        ),
        
        SizedBox(height: 8),
        
        Text('Email:', style: TextStyle(fontWeight: FontWeight.bold)),
        CyberLabel(
          text: drUser.bind('email'),
          style: TextStyle(fontSize: 16),
          textcolor: Colors.blue,
        ),
      ],
    );
  }
}
```

### 2. Static Text

Không binding, giá trị cố định.

```dart
// Simple text
CyberLabel(
  text: 'Hello World',
  style: TextStyle(fontSize: 18),
)

// With styling
CyberLabel(
  text: 'Important Notice',
  style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  ),
  textcolor: Colors.red,
)
```

### 3. Icon Mode

Hiển thị icon từ icon code.

```dart
class IconDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Icon từ code point
        CyberLabel(
          text: 'e88a', // home icon
          isIcon: true,
          iconSize: 24,
          textcolor: Colors.blue,
        ),
        
        SizedBox(width: 8),
        
        // Star icon
        CyberLabel(
          text: 'e838',
          isIcon: true,
          iconSize: 24,
          textcolor: Colors.orange,
        ),
        
        SizedBox(width: 8),
        
        // Settings icon
        CyberLabel(
          text: 'e8b8',
          isIcon: true,
          iconSize: 24,
          textcolor: Colors.grey,
        ),
      ],
    );
  }
}
```

### 4. With Format

Format text theo pattern.

```dart
class FormattedLabel extends StatelessWidget {
  final drProduct = CyberDataRow();

  FormattedLabel() {
    drProduct['price'] = 1500000;
    drProduct['quantity'] = 5;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CyberLabel(
          text: drProduct.bind('price'),
          format: 'Giá: {0} VNĐ',
          style: TextStyle(fontSize: 16),
        ),
        
        CyberLabel(
          text: drProduct.bind('quantity'),
          format: 'Số lượng: {0} sản phẩm',
          style: TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}
```

### 5. Clickable Label

Label với tap event.

```dart
class ClickableDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CyberLabel(
          text: 'Nhấn để xem chi tiết',
          style: TextStyle(
            fontSize: 14,
            decoration: TextDecoration.underline,
          ),
          textcolor: Colors.blue,
          onLeaver: (value) {
            print('Label tapped');
            showDetails();
          },
        ),
        
        // With custom ripple
        CyberLabel(
          text: 'Xem thêm',
          textcolor: Colors.purple,
          onLeaver: (value) {
            loadMore();
          },
          showRipple: true,
          rippleColor: Colors.purple,
        ),
        
        // No ripple
        CyberLabel(
          text: 'Link (no ripple)',
          textcolor: Colors.blue,
          onLeaver: (value) {
            openLink();
          },
          showRipple: false,
        ),
      ],
    );
  }
}
```

### 6. Visibility Binding

Hiển thị/ẩn dựa trên binding.

```dart
class ConditionalLabel extends StatefulWidget {
  @override
  State<ConditionalLabel> createState() => _ConditionalLabelState();
}

class _ConditionalLabelState extends State<ConditionalLabel> {
  final drSettings = CyberDataRow();

  @override
  void initState() {
    super.initState();
    
    drSettings['show_price'] = true;
    drSettings['price'] = 1500000;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          title: Text('Hiển thị giá'),
          value: drSettings['show_price'],
          onChanged: (value) {
            drSettings['show_price'] = value;
          },
        ),
        
        // Label chỉ hiện khi show_price = true
        CyberLabel(
          text: drSettings.bind('price'),
          format: 'Giá: {0} VNĐ',
          isVisible: drSettings.bind('show_price'),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
```

### 7. MaxLines & Overflow

Truncate text dài.

```dart
class TruncatedLabel extends StatelessWidget {
  final drProduct = CyberDataRow();

  TruncatedLabel() {
    drProduct['description'] = 
      'Đây là một mô tả rất dài về sản phẩm. '
      'Nó có thể chứa nhiều thông tin chi tiết...';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Single line với ellipsis
        CyberLabel(
          text: drProduct.bind('description'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        
        SizedBox(height: 8),
        
        // 2 lines
        CyberLabel(
          text: drProduct.bind('description'),
          maxLines: 2,
        ),
        
        SizedBox(height: 8),
        
        // Fade overflow
        CyberLabel(
          text: drProduct.bind('description'),
          maxLines: 1,
          overflow: TextOverflow.fade,
        ),
      ],
    );
  }
}
```

### 8. List Item Labels

Sử dụng trong list.

```dart
class ProductList extends StatelessWidget {
  final dtProducts = CyberDataTable(
    columns: ['id', 'name', 'price', 'status'],
  );

  ProductList() {
    dtProducts.addRow(['1', 'Sản phẩm A', 1500000, 'active']);
    dtProducts.addRow(['2', 'Sản phẩm B', 2000000, 'inactive']);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: dtProducts.rowCount,
      itemBuilder: (context, index) {
        final row = dtProducts[index];
        
        return ListTile(
          title: CyberLabel(
            text: row.bind('name'),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          subtitle: CyberLabel(
            text: row.bind('price'),
            format: '{0} VNĐ',
            textcolor: Colors.green,
          ),
          trailing: CyberLabel(
            text: row.bind('status'),
            textcolor: row['status'] == 'active' 
              ? Colors.green 
              : Colors.red,
          ),
        );
      },
    );
  }
}
```

### 9. Styled Labels

Nhiều style khác nhau.

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    // Title
    CyberLabel(
      text: 'Tiêu đề chính',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    ),
    
    // Subtitle
    CyberLabel(
      text: 'Tiêu đề phụ',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      textcolor: Colors.grey[700],
    ),
    
    // Body
    CyberLabel(
      text: 'Nội dung thông thường',
      style: TextStyle(fontSize: 14),
    ),
    
    // Caption
    CyberLabel(
      text: 'Chú thích nhỏ',
      style: TextStyle(
        fontSize: 12,
        fontStyle: FontStyle.italic,
      ),
      textcolor: Colors.grey,
    ),
  ],
)
```

### 10. Dynamic Icon

Icon thay đổi dựa trên data.

```dart
class StatusIcon extends StatelessWidget {
  final drOrder = CyberDataRow();

  StatusIcon() {
    drOrder['status'] = 'completed';
  }

  String getIconCode(String status) {
    switch (status) {
      case 'pending': return 'e88e'; // schedule
      case 'processing': return 'e86a'; // autorenew
      case 'completed': return 'e876'; // check_circle
      case 'cancelled': return 'e5c9'; // cancel
      default: return 'e88f'; // help
    }
  }

  Color getIconColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'processing': return Colors.blue;
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: drOrder,
      builder: (context, _) {
        final status = drOrder['status'].toString();
        
        return Row(
          children: [
            CyberLabel(
              text: getIconCode(status),
              isIcon: true,
              iconSize: 24,
              textcolor: getIconColor(status),
            ),
            SizedBox(width: 8),
            CyberLabel(
              text: status,
              textcolor: getIconColor(status),
            ),
          ],
        );
      },
    );
  }
}
```

---

## Features

### 1. Data Binding

Tự động update khi data thay đổi.

```dart
CyberLabel(
  text: drUser.bind('name'),
)
// Updates automatically when drUser['name'] changes
```

### 2. Dual Mode

Text hoặc Icon mode.

```dart
// Text mode (default)
CyberLabel(text: 'Hello')

// Icon mode
CyberLabel(text: 'e88a', isIcon: true)
```

### 3. Format Support

Format text với placeholders.

```dart
CyberLabel(
  text: drProduct.bind('price'),
  format: 'Giá: {0} VNĐ',
)
```

### 4. Visibility Binding

```dart
CyberLabel(
  text: 'Secret data',
  isVisible: drUser.bind('is_admin'),
)
```

### 5. Clickable

Optional tap event.

```dart
CyberLabel(
  text: 'Click me',
  onLeaver: (value) {
    print('Tapped');
  },
)
```

### 6. Ripple Effect

Material ripple khi tap.

```dart
CyberLabel(
  text: 'Button',
  onLeaver: (value) {},
  showRipple: true,
  rippleColor: Colors.blue,
)
```

### 7. Text Truncation

MaxLines và overflow control.

```dart
CyberLabel(
  text: 'Very long text...',
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
)
```

---

## Extensions

### String Extensions

Quick helpers để tạo labels.

```dart
// Clickable label
'Xem chi tiết'.toClickableLabel(
  onTap: (value) {
    print('Tapped');
  },
  textcolor: Colors.blue,
)

// Icon label
'e88a'.toIconLabel(
  size: 24,
  color: Colors.red,
)

// With custom style
'Important'.toClickableLabel(
  style: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  ),
  rippleColor: Colors.red,
)
```

---

## Best Practices

### 1. Use For Read-Only Data

```dart
// ✅ GOOD: Read-only display
CyberLabel(
  text: drUser.bind('email'),
)

// ❌ BAD: Editable data (use CyberText)
// CyberLabel is read-only!
```

### 2. Binding vs Static

```dart
// ✅ GOOD: Binding for dynamic data
CyberLabel(
  text: drProduct.bind('name'),
)

// ✅ GOOD: Static for constant text
CyberLabel(
  text: 'Total:',
)
```

### 3. Icon Codes

```dart
// ✅ GOOD: Valid icon code
CyberLabel(
  text: 'e88a', // home
  isIcon: true,
)

// ❌ BAD: Invalid code
CyberLabel(
  text: 'home', // Not a code!
  isIcon: true,
)
```

### 4. MaxLines

```dart
// ✅ GOOD: Truncate long text
CyberLabel(
  text: longDescription,
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
)

// ❌ BAD: No truncation
CyberLabel(
  text: longDescription,
)
// May cause layout issues
```

### 5. Clickable Labels

```dart
// ✅ GOOD: Clear action
CyberLabel(
  text: 'View Details',
  textcolor: Colors.blue,
  onLeaver: (value) {
    navigateToDetails();
  },
)

// ❌ BAD: Looks clickable but isn't
CyberLabel(
  text: 'View Details',
  textcolor: Colors.blue,
  // No onLeaver!
)
```

---

## Troubleshooting

### Label không update

**Nguyên nhân:** Không dùng binding

**Giải pháp:**
```dart
// ✅ CORRECT
CyberLabel(
  text: drUser.bind('name'),
)

// ❌ WRONG
CyberLabel(
  text: drUser['name'],
)
```

### Icon không hiển thị

**Nguyên nhân:** 
1. Sai icon code
2. Quên set isIcon = true

**Giải pháp:**
```dart
// ✅ CORRECT
CyberLabel(
  text: 'e88a',
  isIcon: true,
)

// ❌ WRONG
CyberLabel(
  text: 'home', // Not a code
  isIcon: true,
)
```

### Format không hoạt động

**Nguyên nhân:** Sai placeholder syntax

**Giải pháp:**
```dart
// ✅ CORRECT
format: 'Price: {0} VND'

// ❌ WRONG
format: 'Price: %s VND' // Wrong syntax
```

### Visibility binding không hoạt động

**Nguyên nhân:** Không dùng binding

**Giải pháp:**
```dart
// ✅ CORRECT
CyberLabel(
  isVisible: drSettings.bind('show_label'),
)

// ❌ WRONG
CyberLabel(
  isVisible: drSettings['show_label'],
)
```

### Tap không hoạt động

**Nguyên nhân:** onLeaver = null

**Giải pháp:**
```dart
// ✅ CORRECT
CyberLabel(
  text: 'Click me',
  onLeaver: (value) {
    print('Tapped');
  },
)

// ❌ WRONG
CyberLabel(
  text: 'Click me',
  // No onLeaver
)
```

---

## Tips & Tricks

### 1. Conditional Styling

```dart
ListenableBuilder(
  listenable: drOrder,
  builder: (context, _) {
    final status = drOrder['status'].toString();
    
    return CyberLabel(
      text: status,
      textcolor: status == 'completed' 
        ? Colors.green 
        : Colors.orange,
    );
  },
)
```

### 2. Formatted Numbers

```dart
import 'package:intl/intl.dart';

final formatter = NumberFormat('#,###');

CyberLabel(
  text: formatter.format(drProduct['price']),
  format: '{0} VNĐ',
)
```

### 3. Multi-line Labels

```dart
CyberLabel(
  text: 'Line 1\nLine 2\nLine 3',
  maxLines: 3,
)
```

### 4. Icon + Text

```dart
Row(
  children: [
    CyberLabel(
      text: 'e88a',
      isIcon: true,
      iconSize: 20,
    ),
    SizedBox(width: 4),
    CyberLabel(
      text: drProduct.bind('name'),
    ),
  ],
)
```

### 5. Badge Label

```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(
    color: Colors.red,
    borderRadius: BorderRadius.circular(12),
  ),
  child: CyberLabel(
    text: '5',
    textcolor: Colors.white,
    style: TextStyle(fontSize: 12),
  ),
)
```

---

## Performance Tips

1. **Use Stateless**: CyberLabel is stateless, very efficient
2. **Avoid Rebuilds**: Only rebuild when data changes
3. **Cache Formatted Text**: Format once if possible
4. **const Constructors**: Use const when possible

---

## Common Patterns

### Status Badge

```dart
Widget statusBadge(String status) {
  Color color;
  switch (status) {
    case 'active': color = Colors.green; break;
    case 'inactive': color = Colors.red; break;
    default: color = Colors.grey;
  }
  
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.2),
      borderRadius: BorderRadius.circular(4),
    ),
    child: CyberLabel(
      text: status,
      textcolor: color,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
    ),
  );
}
```

### Link Label

```dart
Widget linkLabel(String text, VoidCallback onTap) {
  return CyberLabel(
    text: text,
    style: TextStyle(
      decoration: TextDecoration.underline,
    ),
    textcolor: Colors.blue,
    onLeaver: (value) => onTap(),
  );
}
```

### Currency Label

```dart
Widget currencyLabel(double amount) {
  final formatter = NumberFormat('#,###');
  
  return CyberLabel(
    text: formatter.format(amount),
    format: '{0} VNĐ',
    style: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
    textcolor: Colors.green,
  );
}
```

---

## Version History

### 1.0.0
- Initial release
- Data binding support
- Dual mode (Text/Icon)
- Visibility binding
- Clickable with ripple
- Format support
- MaxLines & overflow

---

## License

MIT License - CyberFramework
