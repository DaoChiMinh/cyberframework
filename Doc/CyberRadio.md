# Hướng Dẫn Sử Dụng CyberRadio Components

## Mục Lục

1. [Tổng Quan](#tổng-quan)
2. [CyberRadioBox - Traditional Pattern](#cyberradiobox---traditional-pattern)
3. [CyberRadioGroup - Modern Pattern](#cyberradiogroup---modern-pattern)
4. [So Sánh Hai Patterns](#so-sánh-hai-patterns)
5. [Advanced Usage](#advanced-usage)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

---

## Tổng Quan

CyberFramework cung cấp 3 components cho việc xử lý radio buttons:

- **CyberRadioBox**: Single radio button - Traditional pattern (giống HTML/WPF)
- **CyberRadioGroup**: Radio group với multi-column hoặc single-column binding
- **CyberRadioItem**: Model class cho items trong CyberRadioGroup

### Khi Nào Dùng Component Nào?

| Component | Khi Nào Dùng | Ví Dụ Use Case |
|-----------|--------------|----------------|
| **CyberRadioBox** | - Cần control chi tiết từng radio button<br>- Layout phức tạp, custom<br>- Ít options (2-3 choices) | Gender selection, Yes/No questions |
| **CyberRadioGroup** | - Có nhiều options (3+)<br>- Layout đơn giản (horizontal/vertical)<br>- Muốn code gọn gàng hơn | Vehicle type, Status selection, Categories |

---

## CyberRadioBox - Traditional Pattern

### Triết Lý

- **Một binding cho cả group** (text parameter)
- **Mỗi radio có value riêng**
- Khi chọn: `text = value` của radio được chọn

### Basic Usage

#### 1. Single Column Mode (Recommended)

Tất cả radio buttons bind vào **cùng một field**, mỗi radio có **value riêng**.

```dart
// Database: gender NVARCHAR(10)

CyberRadioBox(
  text: drEdit.bind("gender"),
  group: "gender_group",
  value: "male",
  label: "Nam",
)

CyberRadioBox(
  text: drEdit.bind("gender"),
  group: "gender_group",
  value: "female",
  label: "Nữ",
)

CyberRadioBox(
  text: drEdit.bind("gender"),
  group: "gender_group",
  value: "other",
  label: "Khác",
)
```

**Kết quả:**
- Chọn "Nam" → `gender = "male"`
- Chọn "Nữ" → `gender = "female"`
- Chọn "Khác" → `gender = "other"`

#### 2. Custom Layout Example

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text("Giới tính", style: TextStyle(fontWeight: FontWeight.bold)),
    SizedBox(height: 8),
    
    Row(
      children: [
        CyberRadioBox(
          text: drEdit.bind("gender"),
          group: "gender_group",
          value: "M",
          label: "Nam",
        ),
        SizedBox(width: 20),
        CyberRadioBox(
          text: drEdit.bind("gender"),
          group: "gender_group",
          value: "F",
          label: "Nữ",
        ),
      ],
    ),
  ],
)
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `text` | `dynamic` | ✅ | - | Binding đến field chứa giá trị được chọn |
| `group` | `dynamic` | ✅ | - | Tên nhóm để group các radio buttons |
| `value` | `dynamic` | ✅ | - | Giá trị của radio này |
| `label` | `String?` | ❌ | `null` | Label hiển thị bên cạnh radio |
| `enabled` | `bool` | ❌ | `true` | Enable/disable radio |
| `isVisible` | `dynamic` | ❌ | `true` | Hiển thị/ẩn radio (hỗ trợ binding) |
| `labelStyle` | `TextStyle?` | ❌ | `null` | Style cho label |
| `activeColor` | `Color?` | ❌ | `#007AFF` | Màu khi được chọn |
| `fillColor` | `Color?` | ❌ | `white` | Màu của dot bên trong |
| `size` | `double?` | ❌ | `24` | Size của radio button |
| `onChanged` | `ValueChanged?` | ❌ | `null` | Callback khi value thay đổi |
| `onLeaver` | `Function?` | ❌ | `null` | Callback khi rời khỏi control |

### Advanced Examples

#### Example 1: Conditional Visibility

```dart
CyberRadioBox(
  text: drEdit.bind("payment_method"),
  group: "payment_group",
  value: "cash",
  label: "Tiền mặt",
)

CyberRadioBox(
  text: drEdit.bind("payment_method"),
  group: "payment_group",
  value: "card",
  label: "Thẻ",
  isVisible: drEdit.bind("has_card"), // Chỉ hiện nếu has_card = true
)
```

#### Example 2: Custom Styling

```dart
CyberRadioBox(
  text: drEdit.bind("vehicle_type"),
  group: "vehicle_group",
  value: "car",
  label: "Ô tô",
  activeColor: Colors.blue,
  size: 28,
  labelStyle: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  ),
)
```

#### Example 3: With Callbacks

```dart
CyberRadioBox(
  text: drEdit.bind("status"),
  group: "status_group",
  value: "active",
  label: "Đang hoạt động",
  onChanged: (value) {
    print("Status changed to: $value");
    // Thực hiện logic khác...
  },
  onLeaver: (value) {
    print("Left radio with value: $value");
  },
)
```

---

## CyberRadioGroup - Modern Pattern

### Triết Lý

CyberRadioGroup hỗ trợ **2 modes**:

1. **Multi-column mode** (default): Mỗi item bind vào column riêng
2. **Single-column mode**: Tất cả items bind vào cùng 1 column

### Mode 1: Multi-Column (Default)

Mỗi radio item bind vào **một column riêng** trong CyberDataRow.

```dart
// Database:
// is_car       BIT
// is_motorcycle BIT
// is_bicycle   BIT

CyberRadioGroup(
  label: "Loại phương tiện",
  items: [
    CyberRadioItem(
      label: "Ô tô",
      binding: drEdit.bind("is_car"),
    ),
    CyberRadioItem(
      label: "Xe máy",
      binding: drEdit.bind("is_motorcycle"),
    ),
    CyberRadioItem(
      label: "Xe đạp",
      binding: drEdit.bind("is_bicycle"),
    ),
  ],
)
```

**Hoạt động:**
- Chọn "Ô tô" → `is_car = 1`, `is_motorcycle = 0`, `is_bicycle = 0`
- Chọn "Xe máy" → `is_car = 0`, `is_motorcycle = 1`, `is_bicycle = 0`

**Khi nào dùng:** Database có sẵn nhiều bit columns cho từng option.

### Mode 2: Single-Column (Recommended)

Tất cả items bind vào **cùng một column**, mỗi item có **value riêng**.

#### Cách 1: Set ở Group Level (RECOMMENDED)

```dart
// Database: vehicle_type NVARCHAR(20)

CyberRadioGroup(
  label: "Loại phương tiện",
  isSingleColumn: true,  // ⭐ Set 1 lần cho tất cả items
  items: [
    CyberRadioItem(
      label: "Ô tô",
      binding: drEdit.bind("vehicle_type"),
      value: "car",
    ),
    CyberRadioItem(
      label: "Xe máy",
      binding: drEdit.bind("vehicle_type"),
      value: "motorcycle",
    ),
    CyberRadioItem(
      label: "Xe đạp",
      binding: drEdit.bind("vehicle_type"),
      value: "bicycle",
    ),
  ],
)
```

#### Cách 2: Set ở Item Level

```dart
CyberRadioGroup(
  label: "Loại phương tiện",
  items: [
    CyberRadioItem(
      label: "Ô tô",
      binding: drEdit.bind("vehicle_type"),
      value: "car",
      isSingleColumn: true,  // Set cho từng item
    ),
    CyberRadioItem(
      label: "Xe máy",
      binding: drEdit.bind("vehicle_type"),
      value: "motorcycle",
      isSingleColumn: true,
    ),
  ],
)
```

**⚠️ Ưu tiên:** Group level `isSingleColumn` sẽ **override** item level nếu có.

### Parameters - CyberRadioGroup

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `items` | `List<CyberRadioItem>` | ✅ | - | Danh sách radio items |
| `label` | `String?` | ❌ | `null` | Label hiển thị phía trên |
| `direction` | `Axis` | ❌ | `horizontal` | Hướng hiển thị (horizontal/vertical) |
| `spacing` | `double` | ❌ | `12.0` | Spacing giữa các items |
| `enabled` | `bool` | ❌ | `true` | Enable/disable toàn bộ group |
| `isVisible` | `dynamic` | ❌ | `true` | Hiển thị/ẩn group (hỗ trợ binding) |
| `isCheckEmpty` | `dynamic` | ❌ | `false` | Hiện dấu * bắt buộc |
| `isShowLabel` | `bool` | ❌ | `true` | Hiện/ẩn label |
| `isSingleColumn` | `bool?` | ❌ | `null` | Single-column mode cho tất cả items |
| `activeColor` | `Color?` | ❌ | `primary` | Màu radio button khi chọn |
| `labelStyle` | `TextStyle?` | ❌ | `null` | Style cho label chính |
| `itemTextStyle` | `TextStyle?` | ❌ | `null` | Style cho text của items |
| `selectedItemTextStyle` | `TextStyle?` | ❌ | `null` | Style cho text của item được chọn |
| `onChanged` | `ValueChanged<int>?` | ❌ | `null` | Callback khi selection thay đổi (trả về index) |

### Parameters - CyberRadioItem

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `label` | `String` | ✅ | - | Label hiển thị |
| `binding` | `dynamic` | ✅ | - | Binding expression |
| `value` | `dynamic` | ❌ | `null` | Value (cho single-column mode) |
| `isSingleColumn` | `bool` | ❌ | `false` | Single-column mode |
| `selectedValue` | `dynamic` | ❌ | `1` | Value khi chọn (multi-column mode) |
| `unselectedValue` | `dynamic` | ❌ | `0` | Value khi bỏ chọn (multi-column mode) |
| `icon` | `String?` | ❌ | `null` | Icon code |
| `enabled` | `bool` | ❌ | `true` | Enable/disable item này |

### Advanced Examples

#### Example 1: Vertical Layout

```dart
CyberRadioGroup(
  label: "Trạng thái đơn hàng",
  direction: Axis.vertical,  // Hiển thị dọc
  spacing: 16.0,
  isSingleColumn: true,
  items: [
    CyberRadioItem(
      label: "Chờ xử lý",
      binding: drEdit.bind("order_status"),
      value: "pending",
    ),
    CyberRadioItem(
      label: "Đang giao",
      binding: drEdit.bind("order_status"),
      value: "shipping",
    ),
    CyberRadioItem(
      label: "Hoàn thành",
      binding: drEdit.bind("order_status"),
      value: "completed",
    ),
    CyberRadioItem(
      label: "Đã hủy",
      binding: drEdit.bind("order_status"),
      value: "cancelled",
    ),
  ],
)
```

#### Example 2: With Icons

```dart
CyberRadioGroup(
  label: "Phương thức thanh toán",
  isSingleColumn: true,
  items: [
    CyberRadioItem(
      label: "Tiền mặt",
      binding: drEdit.bind("payment_method"),
      value: "cash",
      icon: "money",  // Material icon code
    ),
    CyberRadioItem(
      label: "Thẻ ngân hàng",
      binding: drEdit.bind("payment_method"),
      value: "card",
      icon: "credit_card",
    ),
    CyberRadioItem(
      label: "Chuyển khoản",
      binding: drEdit.bind("payment_method"),
      value: "transfer",
      icon: "account_balance",
    ),
  ],
)
```

#### Example 3: Custom Styling

```dart
CyberRadioGroup(
  label: "Mức độ ưu tiên",
  isSingleColumn: true,
  activeColor: Colors.red,
  labelStyle: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.black87,
  ),
  selectedItemTextStyle: TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    color: Colors.red,
  ),
  items: [
    CyberRadioItem(
      label: "Cao",
      binding: drEdit.bind("priority"),
      value: 1,
    ),
    CyberRadioItem(
      label: "Trung bình",
      binding: drEdit.bind("priority"),
      value: 2,
    ),
    CyberRadioItem(
      label: "Thấp",
      binding: drEdit.bind("priority"),
      value: 3,
    ),
  ],
)
```

#### Example 4: Conditional Visibility & Required Field

```dart
CyberRadioGroup(
  label: "Loại hình kinh doanh",
  isSingleColumn: true,
  isVisible: drEdit.bind("is_company"), // Chỉ hiện nếu is_company = true
  isCheckEmpty: true,  // Hiện dấu * bắt buộc
  items: [
    CyberRadioItem(
      label: "TNHH",
      binding: drEdit.bind("business_type"),
      value: "LLC",
    ),
    CyberRadioItem(
      label: "Cổ phần",
      binding: drEdit.bind("business_type"),
      value: "JSC",
    ),
    CyberRadioItem(
      label: "Tư nhân",
      binding: drEdit.bind("business_type"),
      value: "PRIVATE",
    ),
  ],
)
```

#### Example 5: With OnChanged Callback

```dart
CyberRadioGroup(
  label: "Hình thức vận chuyển",
  isSingleColumn: true,
  onChanged: (index) {
    print("Selected index: $index");
    
    // Thực hiện logic dựa trên selection
    if (index == 0) {
      // Express shipping selected
      drEdit["shipping_fee"] = 50000;
    } else if (index == 1) {
      // Standard shipping selected
      drEdit["shipping_fee"] = 20000;
    } else {
      // Free shipping selected
      drEdit["shipping_fee"] = 0;
    }
  },
  items: [
    CyberRadioItem(
      label: "Giao hàng nhanh (50.000đ)",
      binding: drEdit.bind("shipping_type"),
      value: "express",
    ),
    CyberRadioItem(
      label: "Giao hàng tiêu chuẩn (20.000đ)",
      binding: drEdit.bind("shipping_type"),
      value: "standard",
    ),
    CyberRadioItem(
      label: "Miễn phí (3-5 ngày)",
      binding: drEdit.bind("shipping_type"),
      value: "free",
    ),
  ],
)
```

#### Example 6: Disable Individual Items

```dart
CyberRadioGroup(
  label: "Gói dịch vụ",
  isSingleColumn: true,
  items: [
    CyberRadioItem(
      label: "Miễn phí",
      binding: drEdit.bind("service_plan"),
      value: "free",
    ),
    CyberRadioItem(
      label: "Cơ bản (99.000đ/tháng)",
      binding: drEdit.bind("service_plan"),
      value: "basic",
    ),
    CyberRadioItem(
      label: "Pro (299.000đ/tháng)",
      binding: drEdit.bind("service_plan"),
      value: "pro",
      enabled: false,  // Disable item này
    ),
    CyberRadioItem(
      label: "Enterprise (Liên hệ)",
      binding: drEdit.bind("service_plan"),
      value: "enterprise",
      enabled: false,
    ),
  ],
)
```

#### Example 7: Multi-Column Mode với Custom Values

```dart
// Database: is_option1 BIT, is_option2 BIT, is_option3 BIT

CyberRadioGroup(
  label: "Tùy chọn",
  items: [
    CyberRadioItem(
      label: "Tùy chọn 1",
      binding: drEdit.bind("is_option1"),
      selectedValue: true,    // Khi chọn: is_option1 = true
      unselectedValue: false, // Khi bỏ chọn: is_option1 = false
    ),
    CyberRadioItem(
      label: "Tùy chọn 2",
      binding: drEdit.bind("is_option2"),
      selectedValue: true,
      unselectedValue: false,
    ),
    CyberRadioItem(
      label: "Tùy chọn 3",
      binding: drEdit.bind("is_option3"),
      selectedValue: true,
      unselectedValue: false,
    ),
  ],
)
```

---

## So Sánh Hai Patterns

### CyberRadioBox vs CyberRadioGroup

| Tiêu Chí | CyberRadioBox | CyberRadioGroup |
|----------|---------------|-----------------|
| **Code Length** | Dài hơn (phải viết từng radio) | Ngắn gọn hơn (dùng list) |
| **Layout Control** | Linh hoạt 100% | Giới hạn (horizontal/vertical) |
| **Số Lượng Options** | Tốt cho 2-3 options | Tốt cho 3+ options |
| **Styling** | Control riêng từng radio | Style chung cho cả group |
| **Complexity** | Đơn giản, dễ hiểu | Phức tạp hơn (2 modes) |
| **Use Case** | Custom layout, ít options | Standard layout, nhiều options |

### Single-Column vs Multi-Column

| Tiêu Chí | Single-Column | Multi-Column |
|----------|---------------|--------------|
| **Database** | 1 column (NVARCHAR/VARCHAR) | Nhiều columns (BIT/INT) |
| **Storage** | `"car"`, `"motorcycle"`, ... | `1`, `0`, `true`, `false` |
| **Scalability** | Dễ thêm options mới | Phải thêm column mới |
| **Query** | `WHERE vehicle_type = 'car'` | `WHERE is_car = 1` |
| **Recommended** | ✅ Khuyến nghị | ❌ Chỉ khi có sẵn |

**💡 Best Practice:** Dùng **Single-Column mode** trừ khi database đã có sẵn nhiều bit columns.

---

## Advanced Usage

### 1. Dynamic Radio Items

```dart
class VehicleFormScreen extends StatelessWidget {
  final CyberDataRow drEdit;
  
  List<CyberRadioItem> _buildVehicleTypes() {
    final types = ["car", "motorcycle", "bicycle", "truck", "bus"];
    final labels = ["Ô tô", "Xe máy", "Xe đạp", "Xe tải", "Xe buýt"];
    
    return List.generate(types.length, (index) {
      return CyberRadioItem(
        label: labels[index],
        binding: drEdit.bind("vehicle_type"),
        value: types[index],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return CyberRadioGroup(
      label: "Loại phương tiện",
      isSingleColumn: true,
      items: _buildVehicleTypes(),
    );
  }
}
```

### 2. Nested Conditional Logic

```dart
Column(
  children: [
    // Radio chính
    CyberRadioGroup(
      label: "Phương thức giao hàng",
      isSingleColumn: true,
      items: [
        CyberRadioItem(
          label: "Giao tận nơi",
          binding: drEdit.bind("delivery_method"),
          value: "home",
        ),
        CyberRadioItem(
          label: "Nhận tại cửa hàng",
          binding: drEdit.bind("delivery_method"),
          value: "store",
        ),
      ],
    ),
    
    SizedBox(height: 16),
    
    // Radio phụ - chỉ hiện khi chọn "Giao tận nơi"
    CyberRadioGroup(
      label: "Thời gian giao hàng",
      isSingleColumn: true,
      isVisible: drEdit.bind("delivery_method").value == "home",
      items: [
        CyberRadioItem(
          label: "Sáng (8h-12h)",
          binding: drEdit.bind("delivery_time"),
          value: "morning",
        ),
        CyberRadioItem(
          label: "Chiều (13h-17h)",
          binding: drEdit.bind("delivery_time"),
          value: "afternoon",
        ),
        CyberRadioItem(
          label: "Tối (18h-21h)",
          binding: drEdit.bind("delivery_time"),
          value: "evening",
        ),
      ],
    ),
  ],
)
```

### 3. Validation Example

```dart
class FormController {
  final CyberDataRow drEdit;
  
  FormController(this.drEdit);
  
  String? validateVehicleType() {
    final vehicleType = drEdit["vehicle_type"];
    
    if (vehicleType == null || vehicleType.toString().isEmpty) {
      return "Vui lòng chọn loại phương tiện";
    }
    
    return null; // Valid
  }
  
  bool validateForm() {
    final error = validateVehicleType();
    
    if (error != null) {
      // Show error
      showErrorDialog(error);
      return false;
    }
    
    return true;
  }
  
  Future<void> submitForm() async {
    if (!validateForm()) return;
    
    // Submit logic...
  }
}
```

### 4. Programmatically Set Value

```dart
// Đặt giá trị từ code
void setDefaultVehicle() {
  drEdit["vehicle_type"] = "car"; // Radio sẽ tự động update
}

// Multi-column mode
void setDefaultOptions() {
  drEdit["is_option1"] = 0;
  drEdit["is_option2"] = 1; // Option 2 sẽ được chọn
  drEdit["is_option3"] = 0;
}
```

### 5. Read Current Selection

```dart
// Single-column mode
void printCurrentVehicle() {
  final vehicle = drEdit["vehicle_type"];
  print("Current vehicle: $vehicle"); // "car", "motorcycle", ...
}

// Multi-column mode
void printCurrentOption() {
  if (drEdit["is_option1"] == 1) {
    print("Option 1 is selected");
  } else if (drEdit["is_option2"] == 1) {
    print("Option 2 is selected");
  } else if (drEdit["is_option3"] == 1) {
    print("Option 3 is selected");
  }
}
```

---

## Best Practices

### ✅ DO

1. **Dùng Single-Column Mode** cho hầu hết các trường hợp:
   ```dart
   CyberRadioGroup(
     isSingleColumn: true,  // Set ở group level
     items: [...],
   )
   ```

2. **Đặt tên field rõ ràng:**
   ```dart
   drEdit.bind("vehicle_type")     // ✅ Tốt
   drEdit.bind("gender")           // ✅ Tốt
   drEdit.bind("payment_method")   // ✅ Tốt
   ```

3. **Dùng value có ý nghĩa:**
   ```dart
   value: "car"          // ✅ Tốt
   value: "male"         // ✅ Tốt
   value: "credit_card"  // ✅ Tốt
   ```

4. **Group liên quan vào cùng một group:**
   ```dart
   // ✅ Tốt
   CyberRadioGroup(
     label: "Giới tính",
     items: [...],
   )
   ```

5. **Dùng isCheckEmpty cho required fields:**
   ```dart
   CyberRadioGroup(
     label: "Loại hình",
     isCheckEmpty: true,  // Hiện dấu *
     items: [...],
   )
   ```

### ❌ DON'T

1. **Không mix modes trong cùng group:**
   ```dart
   // ❌ Tránh
   CyberRadioGroup(
     items: [
       CyberRadioItem(binding: drEdit.bind("type"), value: "A", isSingleColumn: true),
       CyberRadioItem(binding: drEdit.bind("is_b")), // Multi-column
     ],
   )
   ```

2. **Không dùng value không rõ nghĩa:**
   ```dart
   value: "1"      // ❌ Tránh
   value: "opt1"   // ❌ Tránh
   value: "a"      // ❌ Tránh
   ```

3. **Không quên set `group` trong CyberRadioBox:**
   ```dart
   // ❌ Thiếu group
   CyberRadioBox(text: drEdit.bind("gender"), value: "M")
   ```

4. **Không dùng quá nhiều options trong horizontal layout:**
   ```dart
   // ❌ Quá nhiều options ngang
   CyberRadioGroup(
     direction: Axis.horizontal,
     items: [/* 10 items */],  // Dùng vertical thay vì
   )
   ```

5. **Không hardcode styling trong code:**
   ```dart
   // ❌ Tránh
   labelStyle: TextStyle(fontSize: 14, color: Colors.black)
   
   // ✅ Dùng theme hoặc constants
   labelStyle: AppTheme.radioLabelStyle
   ```

---

## Troubleshooting

### Vấn Đề 1: Radio không update khi data thay đổi

**Nguyên nhân:** Không dùng binding expression đúng cách.

```dart
// ❌ Sai
text: "gender"  // String thường

// ✅ Đúng
text: drEdit.bind("gender")  // CyberBindingExpression
```

### Vấn Đề 2: Chọn nhiều radio cùng lúc

**Nguyên nhân:** Mỗi radio có `group` khác nhau hoặc không set `group`.

```dart
// ❌ Sai - mỗi radio một group
CyberRadioBox(text: drEdit.bind("gender"), group: "group1", value: "M")
CyberRadioBox(text: drEdit.bind("gender"), group: "group2", value: "F")

// ✅ Đúng - cùng group
CyberRadioBox(text: drEdit.bind("gender"), group: "gender_group", value: "M")
CyberRadioBox(text: drEdit.bind("gender"), group: "gender_group", value: "F")
```

### Vấn Đề 3: Value không đúng type trong database

**Nguyên nhân:** Type mismatch giữa value và database column.

```dart
// Database: vehicle_type INT

// ❌ Sai
value: "1"  // String

// ✅ Đúng
value: 1    // int
```

**Giải pháp:** Components có type preservation, nhưng nên match type từ đầu:

```dart
// Database INT
CyberRadioItem(value: 1)

// Database STRING
CyberRadioItem(value: "car")

// Database BIT/BOOL
CyberRadioItem(selectedValue: true, unselectedValue: false)
```

### Vấn Đề 4: Single-column mode không hoạt động

**Nguyên nhân:** Quên set `isSingleColumn = true` hoặc quên set `value`.

```dart
// ❌ Sai
CyberRadioGroup(
  items: [
    CyberRadioItem(binding: drEdit.bind("type"), value: "A"),
    // Thiếu isSingleColumn
  ],
)

// ✅ Đúng
CyberRadioGroup(
  isSingleColumn: true,  // Set ở group level
  items: [
    CyberRadioItem(binding: drEdit.bind("type"), value: "A"),
    CyberRadioItem(binding: drEdit.bind("type"), value: "B"),
  ],
)
```

### Vấn Đề 5: onChanged không được gọi

**Nguyên nhân:** 
1. Radio bị disable (`enabled = false`)
2. Callback không được set đúng

```dart
// ✅ Đúng
CyberRadioGroup(
  enabled: true,  // Phải enable
  onChanged: (index) {
    print("Selected: $index");
  },
  items: [...],
)
```

### Vấn Đề 6: Visibility binding không hoạt động

**Nguyên nhân:** Dùng value thay vì binding expression.

```dart
// ❌ Sai
isVisible: true  // Static value

// ✅ Đúng
isVisible: drEdit.bind("is_visible")  // Binding
```

### Vấn Đề 7: Label không hiển thị

**Nguyên nhân:** Set `isShowLabel = false` hoặc `label = null`.

```dart
// ✅ Hiện label
CyberRadioGroup(
  label: "Loại phương tiện",
  isShowLabel: true,  // Default = true
  items: [...],
)
```

---

## Performance Tips

### 1. Tránh rebuild không cần thiết

```dart
// ✅ Tốt - Chỉ listen những row cần thiết
CyberRadioGroup(
  items: [
    CyberRadioItem(binding: drEdit.bind("type"), value: "A"),
    CyberRadioItem(binding: drEdit.bind("type"), value: "B"),
  ],
)

// ❌ Tránh - Bind vào nhiều rows khác nhau
CyberRadioGroup(
  items: [
    CyberRadioItem(binding: drEdit1.bind("type"), value: "A"),
    CyberRadioItem(binding: drEdit2.bind("type"), value: "B"),
  ],
)
```

### 2. Sử dụng const constructors khi có thể

```dart
// ✅ Tốt
const CyberRadioGroup(
  label: "Giới tính",
  isSingleColumn: true,
  items: const [
    CyberRadioItem(label: "Nam", value: "M", ...),
  ],
)
```

### 3. Tránh tạo items trong build()

```dart
// ❌ Tránh
@override
Widget build(BuildContext context) {
  return CyberRadioGroup(
    items: _buildItems(),  // Tạo mới mỗi lần build
  );
}

// ✅ Tốt
class MyWidget extends StatefulWidget {
  late final List<CyberRadioItem> _items;
  
  @override
  void initState() {
    super.initState();
    _items = _buildItems();  // Tạo 1 lần
  }
  
  @override
  Widget build(BuildContext context) {
    return CyberRadioGroup(items: _items);
  }
}
```

---

## Migration Guide

### Từ HTML/Web Forms

```html
<!-- HTML -->
<input type="radio" name="gender" value="M"> Nam
<input type="radio" name="gender" value="F"> Nữ
```

```dart
// CyberFramework
CyberRadioBox(
  text: drEdit.bind("gender"),
  group: "gender",
  value: "M",
  label: "Nam",
)
CyberRadioBox(
  text: drEdit.bind("gender"),
  group: "gender",
  value: "F",
  label: "Nữ",
)
```

### Từ Flutter Material RadioListTile

```dart
// Material
RadioListTile(
  title: Text("Nam"),
  value: "M",
  groupValue: _gender,
  onChanged: (value) => setState(() => _gender = value),
)

// CyberFramework
CyberRadioBox(
  text: drEdit.bind("gender"),
  group: "gender_group",
  value: "M",
  label: "Nam",
)
```

---

## Summary

### Quick Reference

| Scenario | Component | Mode | Example |
|----------|-----------|------|---------|
| 2-3 options, custom layout | `CyberRadioBox` | Single-column | Gender, Yes/No |
| 3+ options, standard layout | `CyberRadioGroup` | Single-column | Categories, Status |
| Database có sẵn bit columns | `CyberRadioGroup` | Multi-column | Feature flags |

### Key Takeaways

1. **CyberRadioBox**: Cho layout tùy chỉnh, ít options
2. **CyberRadioGroup**: Cho nhiều options, layout chuẩn
3. **Single-column mode**: Khuyến nghị cho hầu hết trường hợp
4. **Multi-column mode**: Chỉ khi database đã có sẵn
5. **Group level `isSingleColumn`**: Override item level (ưu tiên cao)

---

**📚 Related Documentation:**
- [CyberDataRow Guide](./CyberDataRow_UserGuide.md)
- [CyberBindingExpression Guide](./CyberBinding_UserGuide.md)
- [Form Validation Guide](./FormValidation_UserGuide.md)

**🔗 Support:**
- GitHub Issues: [CyberFramework Issues](https://github.com/your-repo/issues)
- Email: support@cyberframework.com

---

*Last updated: January 2026*
*Version: 1.0.0*