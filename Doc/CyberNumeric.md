# CyberNumeric - Numeric Input với Number Formatting

## Mục Lục
1. [Giới Thiệu](#giới-thiệu)
2. [CyberNumeric Widget](#cybernumeric-widget)
3. [CyberNumericController](#cybernumericcontroller)
4. [Ví Dụ Sử Dụng](#ví-dụ-sử-dụng)
5. [Features](#features)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

---

## Giới Thiệu

`CyberNumeric` là numeric input widget với **Internal Controller**, **Data Binding** hai chiều, và **Auto Formatting**. Widget này tự động format số với thousands separator và decimal places.

### Đặc Điểm Chính

- ✅ **Internal Controller**: Tự động quản lý state
- ✅ **Two-Way Binding**: Tự động sync với CyberDataRow
- ✅ **Auto Formatting**: Format số với separator (1,234,567.89)
- ✅ **Real-Time Format**: Format khi typing
- ✅ **Min/Max Validation**: Giới hạn giá trị
- ✅ **Type Safety**: Return `num?` (không phải String)
- ✅ **Decimal Support**: Hỗ trợ số thập phân
- ✅ **Cursor Management**: Giữ vị trí con trỏ khi format

### Import

```dart
import 'package:cyberframework/cyberframework.dart';
```

---

## CyberNumeric Widget

### Constructor

```dart
const CyberNumeric({
  super.key,
  this.text,
  this.controller,
  this.label,
  this.hint,
  this.format = "### ### ### ###.##",
  this.prefixIcon,
  this.borderSize = 1,
  this.borderRadius,
  this.enabled = true,
  this.isVisible = true,
  this.style,
  this.decoration,
  this.onChanged,
  this.onLeaver,
  this.min,
  this.max,
  this.isShowLabel = true,
  this.backgroundColor,
  this.borderColor = Colors.transparent,
  this.focusColor,
  this.labelStyle,
  this.isCheckEmpty = false,
})
```

### Properties

#### Data Binding

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `text` | `dynamic` | Binding hoặc static value | null |
| `controller` | `CyberNumericController?` | External controller (optional) | null |

⚠️ **KHÔNG dùng cả text VÀ controller cùng lúc**

#### Display

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `label` | `String?` | Label hiển thị | null |
| `hint` | `String?` | Hint text | null |
| `format` | `String?` | Number format pattern | "### ### ### ###.##" |
| `prefixIcon` | `String?` | Icon code bên trái | null |

#### Format Patterns

```dart
"### ### ### ###.##"  // Space separator: 1 234 567.89
"#,##0.##"            // Comma separator: 1,234,567.89
"#,##0.00"            // Fixed 2 decimals: 1,234,567.00
"###,###,##0"         // No decimals: 1,234,567
```

#### Validation

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `min` | `num?` | Giá trị tối thiểu | null |
| `max` | `num?` | Giá trị tối đa | null |
| `isCheckEmpty` | `dynamic` | Required field | false |

#### Callbacks

| Property | Type | Mô Tả |
|----------|------|-------|
| `onChanged` | `ValueChanged<num?>?` | Khi giá trị thay đổi (trả num!) |
| `onLeaver` | `Function(num?)?` | Khi rời khỏi control |

**QUAN TRỌNG**: Callbacks trả về `num?`, không phải `String`!

#### Styling

| Property | Type | Mô Tả | Mặc Định |
|----------|------|-------|----------|
| `style` | `TextStyle?` | Text style | null |
| `labelStyle` | `TextStyle?` | Label style | null |
| `decoration` | `InputDecoration?` | Custom decoration | null |
| `backgroundColor` | `Color?` | Màu nền | Color(0xFFF5F5F5) |
| `borderColor` | `Color?` | Màu border | Colors.transparent |
| `focusColor` | `Color?` | Màu khi focus | null |
| `borderSize` | `int?` | Độ dày border (px) | 1 |
| `borderRadius` | `int?` | Bo góc (px) | 4 |
| `enabled` | `bool` | Enable/disable | true |
| `isShowLabel` | `bool` | Hiển thị label | true |
| `isVisible` | `dynamic` | Hiển thị/ẩn (có thể binding) | true |

---

## CyberNumericController

**NOTE**: Controller là **OPTIONAL**. Không cần trong hầu hết trường hợp.

### Properties & Methods

```dart
final controller = CyberNumericController(
  value: 100,
  min: 0,
  max: 1000,
);

// Properties
num? value = controller.value;
bool enabled = controller.enabled;
num? min = controller.min;
num? max = controller.max;

// Set value (có validation)
controller.setValue(150);

// State
controller.setEnabled(true);
controller.setMinMax(min: 0, max: 2000);

// Clear
controller.clear();
controller.reset(100); // Reset về giá trị ban đầu
```

---

## Ví Dụ Sử Dụng

### 1. Sử Dụng Cơ Bản (Recommended)

Simple quantity input.

```dart
class OrderForm extends StatefulWidget {
  @override
  State<OrderForm> createState() => _OrderFormState();
}

class _OrderFormState extends State<OrderForm> {
  final drOrder = CyberDataRow();

  @override
  void initState() {
    super.initState();
    
    drOrder['so_luong'] = 1;
    drOrder['don_gia'] = 15000;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberNumeric(
          text: drOrder.bind('so_luong'),
          label: 'Số lượng',
          format: '#,##0',  // No decimals
          min: 1,
          onChanged: (value) {
            print('Quantity: $value');
          },
        ),
        
        SizedBox(height: 16),
        
        CyberNumeric(
          text: drOrder.bind('don_gia'),
          label: 'Đơn giá',
          format: '#,##0.00',  // Fixed 2 decimals
          min: 0,
          onChanged: (value) {
            print('Price: $value');
          },
        ),
      ],
    );
  }
}
```

### 2. Different Format Patterns

Các pattern format khác nhau.

```dart
Column(
  children: [
    // Integer - No decimals
    CyberNumeric(
      text: drProduct.bind('so_luong'),
      label: 'Số lượng',
      format: '#,##0',
    ),
    
    // Money - 2 decimals
    CyberNumeric(
      text: drProduct.bind('gia_ban'),
      label: 'Giá bán',
      format: '#,##0.00',
    ),
    
    // Flexible decimals (0-2)
    CyberNumeric(
      text: drProduct.bind('khoi_luong'),
      label: 'Khối lượng (kg)',
      format: '#,##0.##',
    ),
    
    // Space separator
    CyberNumeric(
      text: drProduct.bind('dien_tich'),
      label: 'Diện tích (m²)',
      format: '### ### ##0.00',
    ),
  ],
)
```

### 3. Min/Max Validation

Giới hạn giá trị.

```dart
class RangeInput extends StatelessWidget {
  final drSettings = CyberDataRow();

  RangeInput() {
    drSettings['discount_percent'] = 10;
    drSettings['quantity'] = 1;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Percentage: 0-100
        CyberNumeric(
          text: drSettings.bind('discount_percent'),
          label: 'Giảm giá (%)',
          format: '#,##0.##',
          min: 0,
          max: 100,
        ),
        
        // Quantity: Minimum 1
        CyberNumeric(
          text: drSettings.bind('quantity'),
          label: 'Số lượng',
          format: '#,##0',
          min: 1,
          max: 999,
        ),
      ],
    );
  }
}
```

### 4. Required Field

Field bắt buộc.

```dart
class PriceForm extends StatefulWidget {
  @override
  State<PriceForm> createState() => _PriceFormState();
}

class _PriceFormState extends State<PriceForm> {
  final drProduct = CyberDataRow();

  bool validate() {
    if (drProduct['gia_ban'] == null || drProduct['gia_ban'] <= 0) {
      showError('Vui lòng nhập giá bán');
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberNumeric(
          text: drProduct.bind('gia_ban'),
          label: 'Giá bán',
          format: '#,##0.00',
          min: 0,
          isCheckEmpty: true,  // Show *
        ),
        
        CyberButton(
          label: 'Lưu',
          onClick: () {
            if (validate()) {
              save();
            }
          },
        ),
      ],
    );
  }
}
```

### 5. Calculations

Tính toán từ các numeric inputs.

```dart
class CalculatorForm extends StatefulWidget {
  @override
  State<CalculatorForm> createState() => _CalculatorFormState();
}

class _CalculatorFormState extends State<CalculatorForm> {
  final drOrder = CyberDataRow();

  @override
  void initState() {
    super.initState();
    
    drOrder['so_luong'] = 1;
    drOrder['don_gia'] = 15000;
    drOrder['thanh_tien'] = 15000;
  }

  void calculateTotal() {
    final soLuong = drOrder['so_luong'] as num? ?? 0;
    final donGia = drOrder['don_gia'] as num? ?? 0;
    
    drOrder['thanh_tien'] = soLuong * donGia;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberNumeric(
          text: drOrder.bind('so_luong'),
          label: 'Số lượng',
          format: '#,##0',
          min: 1,
          onChanged: (value) => calculateTotal(),
        ),
        
        SizedBox(height: 16),
        
        CyberNumeric(
          text: drOrder.bind('don_gia'),
          label: 'Đơn giá',
          format: '#,##0.00',
          min: 0,
          onChanged: (value) => calculateTotal(),
        ),
        
        SizedBox(height: 16),
        
        // Read-only total
        CyberNumeric(
          text: drOrder.bind('thanh_tien'),
          label: 'Thành tiền',
          format: '#,##0.00',
          enabled: false,
        ),
      ],
    );
  }
}
```

### 6. With Icon

Thêm icon prefix.

```dart
Row(
  children: [
    Expanded(
      child: CyberNumeric(
        text: drProduct.bind('gia'),
        label: 'Giá',
        format: '#,##0.00',
        prefixIcon: 'e227',  // attach_money icon
      ),
    ),
    
    SizedBox(width: 16),
    
    Expanded(
      child: CyberNumeric(
        text: drProduct.bind('khoi_luong'),
        label: 'Khối lượng',
        format: '#,##0.##',
        prefixIcon: 'e3e8',  // scale icon
      ),
    ),
  ],
)
```

### 7. With Controller (Advanced)

Programmatic control.

```dart
class AdvancedNumeric extends StatefulWidget {
  @override
  State<AdvancedNumeric> createState() => _AdvancedNumericState();
}

class _AdvancedNumericState extends State<AdvancedNumeric> {
  final controller = CyberNumericController(
    value: 100,
    min: 0,
    max: 1000,
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void increment() {
    final current = controller.value ?? 0;
    controller.setValue(current + 1);
  }

  void decrement() {
    final current = controller.value ?? 0;
    controller.setValue(current - 1);
  }

  void reset() {
    controller.reset(100);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberNumeric(
          controller: controller,
          label: 'Giá trị',
          format: '#,##0',
        ),
        
        SizedBox(height: 16),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.remove),
              onPressed: decrement,
            ),
            SizedBox(width: 16),
            ElevatedButton(
              onPressed: reset,
              child: Text('Reset'),
            ),
            SizedBox(width: 16),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: increment,
            ),
          ],
        ),
      ],
    );
  }
}
```

### 8. Currency Input

Nhập tiền tệ.

```dart
class CurrencyInput extends StatelessWidget {
  final drPayment = CyberDataRow();

  CurrencyInput() {
    drPayment['amount'] = 1500000;
  }

  @override
  Widget build(BuildContext context) {
    return CyberNumeric(
      text: drPayment.bind('amount'),
      label: 'Số tiền (VNĐ)',
      format: '#,##0',  // No decimals for VND
      min: 0,
      hint: '0',
      onChanged: (value) {
        print('Amount: ${value} VNĐ');
      },
    );
  }
}
```

### 9. Percentage Input

Nhập phần trăm.

```dart
class PercentageInput extends StatelessWidget {
  final drDiscount = CyberDataRow();

  PercentageInput() {
    drDiscount['rate'] = 15.5;
  }

  @override
  Widget build(BuildContext context) {
    return CyberNumeric(
      text: drDiscount.bind('rate'),
      label: 'Tỷ lệ (%)',
      format: '#,##0.##',
      min: 0,
      max: 100,
      onChanged: (value) {
        if (value != null && value > 100) {
          showError('Tỷ lệ không được vượt quá 100%');
        }
      },
    );
  }
}
```

### 10. Measurement Input

Nhập đo lường.

```dart
class MeasurementForm extends StatelessWidget {
  final drProduct = CyberDataRow();

  MeasurementForm() {
    drProduct['dai'] = 120.5;
    drProduct['rong'] = 80.3;
    drProduct['cao'] = 45.0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberNumeric(
          text: drProduct.bind('dai'),
          label: 'Chiều dài (cm)',
          format: '#,##0.##',
          min: 0,
        ),
        
        SizedBox(height: 12),
        
        CyberNumeric(
          text: drProduct.bind('rong'),
          label: 'Chiều rộng (cm)',
          format: '#,##0.##',
          min: 0,
        ),
        
        SizedBox(height: 12),
        
        CyberNumeric(
          text: drProduct.bind('cao'),
          label: 'Chiều cao (cm)',
          format: '#,##0.##',
          min: 0,
        ),
      ],
    );
  }
}
```

---

## Features

### 1. Internal Controller

Widget tự động quản lý state.

```dart
// ✅ GOOD: Simple binding
CyberNumeric(
  text: drOrder.bind('so_luong'),
  label: 'Số lượng',
)
```

### 2. Auto Formatting

Tự động format khi typing:

```dart
// User types: 1234567
// Displays: 1,234,567

// User types: 1234.5
// Displays: 1,234.5
```

### 3. Type Safety

Callbacks trả num? thay vì String:

```dart
onChanged: (num? value) {
  // value is num?, not String!
  final total = value! * 2;
}
```

### 4. Format Patterns

Linh hoạt với nhiều patterns:

| Pattern | Example | Use Case |
|---------|---------|----------|
| `#,##0` | 1,234,567 | Integer |
| `#,##0.00` | 1,234.00 | Money (fixed) |
| `#,##0.##` | 1,234.5 | Flexible decimals |
| `### ### ##0` | 1 234 567 | Space separator |

### 5. Cursor Management

Giữ vị trí con trỏ khi format:

```dart
// User typing at position 3: "1,2|34"
// After format: "1,2|34" (cursor stays)
```

### 6. Min/Max Validation

Auto clamp values:

```dart
CyberNumeric(
  min: 0,
  max: 100,
)
// User enters 150 → Auto set to 100
// User enters -10 → Auto set to 0
```

### 7. Decimal Handling

Smart decimal input:

```dart
format: "#,##0.00"
// Typing "5" → "5.00"
// Typing "5.1" → "5.10"
// Typing "5.123" → "5.12" (truncate)
```

---

## Best Practices

### 1. Sử Dụng Binding (Recommended)

```dart
// ✅ GOOD
CyberNumeric(
  text: drOrder.bind('so_luong'),
  label: 'Số lượng',
)

// ❌ BAD: Manual state
num? soLuong;
CyberNumeric(
  text: soLuong,
  onChanged: (value) {
    setState(() {
      soLuong = value;
      drOrder['so_luong'] = value;
    });
  },
)
```

### 2. Appropriate Format

```dart
// ✅ GOOD: Match use case
CyberNumeric(
  format: '#,##0',  // Integer quantity
)

CyberNumeric(
  format: '#,##0.00',  // Money (VND)
)

// ❌ BAD: Wrong format
CyberNumeric(
  format: '#,##0.##########',  // Too many decimals
)
```

### 3. Set Min/Max

```dart
// ✅ GOOD: Reasonable limits
CyberNumeric(
  min: 0,
  max: 999999,
)

// ✅ GOOD: Percentage
CyberNumeric(
  min: 0,
  max: 100,
)

// ❌ BAD: No limits when needed
CyberNumeric(
  // Quantity should have min!
)
```

### 4. Use num? Type

```dart
// ✅ GOOD: Type-safe
onChanged: (num? value) {
  if (value != null) {
    final total = value * donGia;
  }
}

// ❌ BAD: String conversion
onChanged: (num? value) {
  final str = value.toString();
  final parsed = num.parse(str); // Unnecessary!
}
```

### 5. Validation

```dart
// ✅ GOOD: Check null
final soLuong = drOrder['so_luong'] as num?;
if (soLuong == null || soLuong <= 0) {
  showError('Số lượng phải > 0');
}

// ❌ BAD: No null check
final soLuong = drOrder['so_luong'] as num;
// May throw!
```

---

## Troubleshooting

### Giá trị không update vào binding

**Nguyên nhân:** Không dùng binding

**Giải pháp:**
```dart
// ✅ CORRECT
CyberNumeric(
  text: drOrder.bind('so_luong'),
)

// ❌ WRONG
CyberNumeric(
  text: drOrder['so_luong'],
)
```

### Format không đúng

**Nguyên nhân:** Sai pattern

**Giải pháp:**
```dart
// ✅ CORRECT
format: '#,##0.##'     // OK
format: '### ### ##0'  // OK

// ❌ WRONG
format: '###.###.###'  // Wrong!
```

### Min/max không hoạt động

**Nguyên nhân:** Set sau khi input

**Giải pháp:**
```dart
// ✅ CORRECT: Set in constructor
CyberNumeric(
  min: 0,
  max: 100,
)

// ❌ WRONG: Set after
final controller = CyberNumericController();
controller.setMinMax(min: 0, max: 100); // Too late!
```

### Decimal bị cắt

**Nguyên nhân:** Format không có decimal places

**Giải pháp:**
```dart
// ✅ CORRECT
format: '#,##0.##'  // Allows decimals

// ❌ WRONG
format: '#,##0'  // No decimals!
```

### Cursor nhảy

**Nguyên nhân:** Bug đã fix trong code

**Giải pháp:** Update lên version mới nhất

---

## Tips & Tricks

### 1. Format Helper

```dart
String formatNumber(num? value, {int decimals = 0}) {
  if (value == null) return '0';
  
  final formatter = NumberFormat('#,##0' + 
    (decimals > 0 ? '.' + '0' * decimals : ''));
  return formatter.format(value);
}

// Usage
Text('Total: ${formatNumber(total, decimals: 2)} VNĐ')
```

### 2. Parse Formatted String

```dart
num? parseFormatted(String formatted) {
  final cleaned = formatted.replaceAll(',', '').replaceAll(' ', '');
  return num.tryParse(cleaned);
}
```

### 3. Calculate Total

```dart
void updateTotal() {
  final qty = drOrder['so_luong'] as num? ?? 0;
  final price = drOrder['don_gia'] as num? ?? 0;
  final discount = drOrder['giam_gia'] as num? ?? 0;
  
  final subtotal = qty * price;
  final total = subtotal - (subtotal * discount / 100);
  
  drOrder['thanh_tien'] = total;
}
```

### 4. Step Increment

```dart
void increment(num step) {
  final current = controller.value ?? 0;
  controller.setValue(current + step);
}

// Usage
increment(1);    // +1
increment(10);   // +10
increment(0.5);  // +0.5
```

### 5. Round to Nearest

```dart
num roundToNearest(num value, num step) {
  return (value / step).round() * step;
}

// Usage
roundToNearest(1234, 100);  // 1200
roundToNearest(1267, 100);  // 1300
```

---

## Performance Tips

1. **Reuse Controller**: Tạo một lần, reuse nhiều nơi
2. **Debounce Calculations**: Debounce onChanged nếu có tính toán phức tạp
3. **Appropriate Decimals**: Không dùng quá nhiều decimal places
4. **Dispose Controller**: Always dispose
5. **Avoid setState in onChanged**: Chỉ update data row

---

## Format Examples

### Vietnamese Number Format

```dart
// Số nguyên
"#,##0"           → 1,234,567

// Tiền (VNĐ - no decimals)
"#,##0"           → 15,000

// Tiền (USD - 2 decimals)
"#,##0.00"        → 15,000.00

// Khối lượng
"#,##0.##"        → 123.45

// Space separator (European style)
"### ### ##0.00"  → 1 234 567.00
```

---

## Version History

### 1.0.0
- Initial release
- Internal controller
- Two-way binding
- Auto formatting với thousands separator
- Real-time format
- Min/max validation
- Decimal support
- Cursor management
- Type-safe callbacks (num?)

---

## License

MIT License - CyberFramework
