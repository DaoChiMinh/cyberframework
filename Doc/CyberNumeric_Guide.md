# CyberNumeric - Hướng Dẫn Sử Dụng

## Giới Thiệu

`CyberNumeric` là TextField chuyên cho nhập số với auto-formatting, validation, và data binding hai chiều.

## Properties

| Property | Type | Mặc định | Mô tả |
|----------|------|----------|-------|
| `text` | `dynamic` | `null` | Giá trị số hoặc binding |
| `label` | `String?` | `null` | Label hiển thị phía trên |
| `hint` | `String?` | `null` | Placeholder |
| `format` | `String?` | `"### ### ### ###.##"` | Pattern format số |
| `icon` | `IconData?` | `null` | Icon bên trái |
| `min` | `double?` | `null` | Giá trị tối thiểu |
| `max` | `double?` | `null` | Giá trị tối đa |
| `enabled` | `bool` | `true` | Bật/tắt |
| `isVisible` | `dynamic` | `true` | Điều khiển hiển thị |
| `isShowLabel` | `bool` | `true` | Hiển thị label |
| `backgroundColor` | `Color?` | `Color(0xFFF5F5F5)` | Màu nền |
| `style` | `TextStyle?` | `null` | Style cho số |
| `labelStyle` | `TextStyle?` | `null` | Style cho label |
| `onChanged` | `ValueChanged<double>?` | `null` | Callback khi giá trị thay đổi |
| `onLeaver` | `Function(dynamic)?` | `null` | Callback khi mất focus |

## Format Patterns

| Pattern | Example Input | Display |
|---------|---------------|---------|
| `"###,###,##0.##"` | 1234567.89 | 1,234,567.89 |
| `"### ### ### ###.##"` | 1234567.89 | 1 234 567.89 |
| `"#,##0.00"` | 1234.5 | 1,234.50 |
| `"### ### ###"` | 123456 | 123 456 |

## Ví Dụ Cơ Bản

### 1. Numeric Field Đơn Giản

```dart
CyberNumeric(
  label: 'Số lượng',
  hint: '0',
  format: "###,###,##0",
  icon: Icons.shopping_cart,
)
```

### 2. Với Data Binding

```dart
final CyberDataRow row = CyberDataRow();
row['price'] = 1000000.0;

CyberNumeric(
  text: row.bind('price'),
  label: 'Giá bán',
  hint: '0',
  format: "###,###,##0.##",
  icon: Icons.attach_money,
)
```

### 3. Với Min/Max Validation

```dart
CyberNumeric(
  text: row.bind('quantity'),
  label: 'Số lượng',
  min: 1.0,
  max: 100.0,
  format: "###,###,##0",
  onChanged: (value) {
    print('Quantity: $value');
  },
)
```

### 4. Form Tính Toán

```dart
class InvoiceForm extends StatefulWidget {
  @override
  State<InvoiceForm> createState() => _InvoiceFormState();
}

class _InvoiceFormState extends State<InvoiceForm> {
  final CyberDataRow row = CyberDataRow();

  @override
  void initState() {
    super.initState();
    row['quantity'] = 1.0;
    row['unitPrice'] = 100000.0;
    row['discount'] = 0.0;
    row['total'] = 0.0;
    
    // Auto calculate total
    row.addListener(_calculateTotal);
  }

  void _calculateTotal() {
    final qty = row['quantity'] as double? ?? 0;
    final price = row['unitPrice'] as double? ?? 0;
    final discount = row['discount'] as double? ?? 0;
    
    row['total'] = (qty * price) - discount;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberNumeric(
          text: row.bind('quantity'),
          label: 'Số lượng',
          format: "###,###,##0",
          min: 1,
          icon: Icons.shopping_cart,
        ),
        
        SizedBox(height: 16),
        
        CyberNumeric(
          text: row.bind('unitPrice'),
          label: 'Đơn giá',
          format: "###,###,##0.##",
          icon: Icons.attach_money,
        ),
        
        SizedBox(height: 16),
        
        CyberNumeric(
          text: row.bind('discount'),
          label: 'Giảm giá',
          format: "###,###,##0.##",
          icon: Icons.discount,
        ),
        
        SizedBox(height: 24),
        
        CyberNumeric(
          text: row.bind('total'),
          label: 'Tổng tiền',
          format: "###,###,##0.##",
          enabled: false,  // Read-only
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ],
    );
  }
}
```

## Real-time Formatting

Số tự động format trong khi gõ:

```dart
// User types: 1234567
// Display: 1,234,567 (với format "###,###,##0")

// User types: 1234.56
// Display: 1,234.56 (với format "###,###,##0.##")
```

## Decimal Handling

### Overwrite Mode

Khi nhập số thập phân, các chữ số mới sẽ ghi đè:

```dart
// Format: "###,###,##0.00"
// Current: 123.45
// User types 6: 123.65 (6 ghi đè lên 4)
// User types 7: 123.67 (7 ghi đè lên 5)
```

### Auto Padding

```dart
// Format: "###,###,##0.00"
// Input: 123
// Display: 123.00 (auto pad 2 decimals)
```

## Validation

### Min/Max Validation

```dart
CyberNumeric(
  text: row.bind('age'),
  label: 'Tuổi',
  min: 18,
  max: 100,
  onLeaver: (value) {
    if (value < 18) {
      showError('Tuổi phải từ 18 trở lên');
    }
  },
)
```

### Custom Validation

```dart
CyberNumeric(
  text: row.bind('amount'),
  label: 'Số tiền',
  onChanged: (value) {
    if (value > balance) {
      showError('Số tiền vượt quá số dư');
    }
  },
)
```

## Use Cases

### 1. Price Input

```dart
CyberNumeric(
  text: row.bind('price'),
  label: 'Giá sản phẩm',
  format: "###,###,##0.##",
  hint: '0',
  icon: Icons.attach_money,
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.green.shade700,
  ),
)
```

### 2. Percentage Input

```dart
CyberNumeric(
  text: row.bind('taxRate'),
  label: 'Thuế VAT (%)',
  format: "##0.##",
  min: 0,
  max: 100,
  icon: Icons.percent,
)
```

### 3. Phone Number

```dart
CyberNumeric(
  text: row.bind('phone'),
  label: 'Số điện thoại',
  format: "### ### ####",  // Format: 090 123 4567
  icon: Icons.phone,
)
```

### 4. Weight/Distance

```dart
CyberNumeric(
  text: row.bind('weight'),
  label: 'Cân nặng (kg)',
  format: "###,##0.0",
  min: 0,
  icon: Icons.monitor_weight,
)
```

## Tips & Best Practices

### ✅ DO

```dart
// ✅ Use appropriate format
CyberNumeric(format: "###,###,##0.##")  // For money
CyberNumeric(format: "###,###,##0")     // For integer

// ✅ Set min/max for validation
CyberNumeric(min: 0, max: 999999)

// ✅ Use right-aligned for numbers
// (Already default in CyberNumeric)
```

### ❌ DON'T

```dart
// ❌ Don't use CyberText for numbers
CyberText(keyboardType: TextInputType.number)  // Use CyberNumeric instead

// ❌ Don't forget decimal places in format
CyberNumeric(format: "###,###,##0")  // Won't show .50 properly
```

## Troubleshooting

### Vấn đề: Format không đúng

**Giải pháp**: Kiểm tra pattern

```dart
// ✅ Correct patterns
"###,###,##0.##"   // Comma separator, 2 decimals
"### ### ### ###.##" // Space separator, 2 decimals

// ❌ Wrong
"#,###"  // Missing leading zeros
```

### Vấn đề: Cursor jumping

**Giải pháp**: Đã được handle tự động trong code

```dart
// CyberNumeric tự động điều chỉnh cursor position
// khi format thay đổi length
```

---

## Xem Thêm

- [CyberText](./CyberText.md) - Text input control
- [CyberDate](./CyberDate.md) - Date picker control
- [CyberDataRow](./CyberDataRow.md) - Data binding system
