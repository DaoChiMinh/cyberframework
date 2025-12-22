# CyberRadioGroup - Hướng dẫn sử dụng

## Tổng quan

`CyberRadioGroup` là widget radio button group đơn giản với cú pháp khai báo ngắn gọn, sử dụng string phân cách bằng ";" cho values và displays.

---

## 1. Basic Usage

### Simple Radio Group
```dart
CyberRadioGroup(
  text: row.bind("gender"),
  values: "0;1",
  displays: "Nam;Nữ",
  label: "Giới tính",
  group: "gender_group",
)
```

### Static Value (No Binding)
```dart
CyberRadioGroup(
  text: "1", // Default selected
  values: "0;1;2",
  displays: "Nhỏ;Vừa;Lớn",
  label: "Kích thước",
  group: "size_group",
)
```

---

## 2. With Data Binding

### Full Binding Example
```dart
class GenderForm extends StatefulWidget {
  @override
  State<GenderForm> createState() => _GenderFormState();
}

class _GenderFormState extends State<GenderForm> {
  late CyberDataTable dt;
  late CyberDataRow row;

  @override
  void initState() {
    super.initState();
    dt = CyberDataTable(tableName: "User");
    dt.addColumn("gender", CyberDataType.text);
    
    row = dt.newRow();
    row["gender"] = "1"; // Default: Nữ
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberRadioGroup(
          text: row.bind("gender"),
          values: "0;1",
          displays: "Nam;Nữ",
          label: "Giới tính",
          group: "gender_group",
        ),
        
        SizedBox(height: 16),
        
        // Display selected value
        Text("Đã chọn: ${row["gender"]}"),
      ],
    );
  }
}
```

---

## 3. Dynamic Values & Displays (Binding)

### Bind Values từ Database
```dart
class DynamicRadioExample extends StatefulWidget {
  @override
  State<DynamicRadioExample> createState() => _DynamicRadioExampleState();
}

class _DynamicRadioExampleState extends State<DynamicRadioExample> {
  late CyberDataTable dtUser;
  late CyberDataRow rowUser;
  late CyberDataTable dtConfig;
  late CyberDataRow rowConfig;

  @override
  void initState() {
    super.initState();
    
    // User data
    dtUser = CyberDataTable(tableName: "User");
    dtUser.addColumn("role", CyberDataType.text);
    rowUser = dtUser.newRow();
    rowUser["role"] = "1";
    
    // Config data (values và displays)
    dtConfig = CyberDataTable(tableName: "Config");
    dtConfig.addColumn("roleValues", CyberDataType.text);
    dtConfig.addColumn("roleDisplays", CyberDataType.text);
    rowConfig = dtConfig.newRow();
    rowConfig["roleValues"] = "0;1;2";
    rowConfig["roleDisplays"] = "Admin;User;Guest";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberRadioGroup(
          text: rowUser.bind("role"),
          values: rowConfig.bind("roleValues"), // Binding values
          displays: rowConfig.bind("roleDisplays"), // Binding displays
          label: "Vai trò",
          group: "role_group",
        ),
        
        SizedBox(height: 16),
        
        ElevatedButton(
          onPressed: () {
            // Change values dynamically
            setState(() {
              rowConfig["roleValues"] = "0;1;2;3";
              rowConfig["roleDisplays"] = "Admin;User;Guest;SuperAdmin";
            });
          },
          child: Text("Thêm role mới"),
        ),
      ],
    );
  }
}
```

---

## 4. Direction & Spacing

### Horizontal Layout
```dart
CyberRadioGroup(
  text: row.bind("size"),
  values: "S;M;L;XL",
  displays: "Nhỏ;Vừa;Lớn;Rất lớn",
  label: "Kích cỡ",
  group: "size_group",
  direction: Axis.horizontal, // Horizontal
  spacing: 16,
)
```

### Vertical Layout (Default)
```dart
CyberRadioGroup(
  text: row.bind("level"),
  values: "1;2;3",
  displays: "Cơ bản;Trung cấp;Nâng cao",
  label: "Trình độ",
  group: "level_group",
  direction: Axis.vertical, // Default
  spacing: 8,
)
```

---

## 5. Styling & Customization

### Custom Colors
```dart
CyberRadioGroup(
  text: row.bind("priority"),
  values: "1;2;3",
  displays: "Thấp;Trung bình;Cao",
  label: "Độ ưu tiên",
  group: "priority_group",
  activeColor: Colors.red,
  fillColor: Colors.white,
)
```

### Custom Size & Style
```dart
CyberRadioGroup(
  text: row.bind("status"),
  values: "0;1;2",
  displays: "Chờ;Đang xử lý;Hoàn thành",
  label: "Trạng thái",
  group: "status_group",
  size: 28, // Larger radio buttons
  labelStyle: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.blue[700],
  ),
  itemLabelStyle: TextStyle(
    fontSize: 15,
    color: Colors.black87,
  ),
)
```

### Hide Group Label
```dart
CyberRadioGroup(
  text: row.bind("option"),
  values: "A;B;C",
  displays: "Tùy chọn A;Tùy chọn B;Tùy chọn C",
  group: "option_group",
  isShowLabel: false, // No label
)
```

---

## 6. Callbacks

### onChange - Real-time Update
```dart
CyberRadioGroup(
  text: row.bind("payment"),
  values: "cash;card;transfer",
  displays: "Tiền mặt;Thẻ;Chuyển khoản",
  label: "Phương thức thanh toán",
  group: "payment_group",
  onChanged: (newValue) {
    print("Selected: $newValue");
    // Update UI real-time
  },
)
```

### onLeaver - When Complete Selection
```dart
CyberRadioGroup(
  text: row.bind("delivery"),
  values: "standard;express;same_day",
  displays: "Tiêu chuẩn;Nhanh;Trong ngày",
  label: "Phương thức giao hàng",
  group: "delivery_group",
  onLeaver: (finalValue) {
    print("User confirmed: $finalValue");
    // Trigger calculation, validation, etc.
    _calculateShippingFee(finalValue);
  },
)
```

---

## 7. Enabled/Disabled State

### Disabled Group
```dart
CyberRadioGroup(
  text: row.bind("type"),
  values: "1;2;3",
  displays: "Loại 1;Loại 2;Loại 3",
  label: "Loại sản phẩm",
  group: "type_group",
  enabled: false, // Disabled
)
```

### Conditional Enable
```dart
class ConditionalEnableExample extends StatefulWidget {
  @override
  State<ConditionalEnableExample> createState() => _ConditionalEnableExampleState();
}

class _ConditionalEnableExampleState extends State<ConditionalEnableExample> {
  late CyberDataTable dt;
  late CyberDataRow row;
  bool _isEnabled = true;

  @override
  void initState() {
    super.initState();
    dt = CyberDataTable(tableName: "Order");
    dt.addColumn("hasInsurance", CyberDataType.text);
    dt.addColumn("insuranceType", CyberDataType.text);
    
    row = dt.newRow();
    row["hasInsurance"] = "0";
    row["insuranceType"] = "";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CyberCheckbox(
          text: row.bind("hasInsurance"),
          label: "Có bảo hiểm",
          onChanged: (value) {
            setState(() {
              _isEnabled = value;
              if (!value) {
                row["insuranceType"] = ""; // Reset
              }
            });
          },
        ),
        
        SizedBox(height: 16),
        
        CyberRadioGroup(
          text: row.bind("insuranceType"),
          values: "basic;standard;premium",
          displays: "Cơ bản;Tiêu chuẩn;Cao cấp",
          label: "Loại bảo hiểm",
          group: "insurance_group",
          enabled: _isEnabled, // Conditional enable
        ),
      ],
    );
  }
}
```

---

## 8. Visibility Binding

### Show/Hide Based on Condition
```dart
// Setup
row["showOptions"] = "1"; // or true

// Widget
CyberRadioGroup(
  text: row.bind("option"),
  values: "A;B;C",
  displays: "Option A;Option B;Option C",
  label: "Tùy chọn",
  group: "option_group",
  isVisible: row.bind("showOptions"),
)
```

---

## 9. Integration with CyberForm

### Complete Registration Form
```dart
class RegistrationForm extends CyberContentViewForm {
  late CyberDataTable dt;
  late CyberDataRow row;

  @override
  void onInit() {
    dt = CyberDataTable(tableName: "Registration");
    dt.addColumn("fullName", CyberDataType.text);
    dt.addColumn("gender", CyberDataType.text);
    dt.addColumn("ageGroup", CyberDataType.text);
    dt.addColumn("interest", CyberDataType.text);
    
    row = dt.newRow();
    row["fullName"] = "";
    row["gender"] = "0";
    row["ageGroup"] = "2";
    row["interest"] = "tech";
  }

  Future<void> _submitRegistration() async {
    // Validate
    if (row["fullName"].toString().isEmpty) {
      await context.showErrorMsg("Vui lòng nhập họ tên!");
      return;
    }

    showLoading("Đang đăng ký...");

    try {
      final response = await context.callApi(
        functionName: "RegisterUser",
        parameter: "${row['fullName']}#${row['gender']}#${row['ageGroup']}#${row['interest']}",
      );

      hideLoading();

      if (response.isValid()) {
        await context.showSuccess("Đăng ký thành công!");
        closePopup(context, true);
      } else {
        await context.showErrorMsg(response.message);
      }
    } catch (e) {
      hideLoading();
      await context.showErrorMsg("Lỗi: $e");
    }
  }

  @override
  Widget buildBody(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            "Đăng ký thành viên",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          
          SizedBox(height: 24),
          
          CyberText(
            text: row.bind("fullName"),
            label: "Họ và tên",
            hint: "Nhập họ tên",
          ),
          
          SizedBox(height: 16),
          
          CyberRadioGroup(
            text: row.bind("gender"),
            values: "0;1",
            displays: "Nam;Nữ",
            label: "Giới tính",
            group: "gender_group",
            direction: Axis.horizontal,
          ),
          
          SizedBox(height: 16),
          
          CyberRadioGroup(
            text: row.bind("ageGroup"),
            values: "1;2;3;4",
            displays: "Dưới 18;18-30;31-50;Trên 50",
            label: "Độ tuổi",
            group: "age_group",
          ),
          
          SizedBox(height: 16),
          
          CyberRadioGroup(
            text: row.bind("interest"),
            values: "tech;sport;music;travel",
            displays: "Công nghệ;Thể thao;Âm nhạc;Du lịch",
            label: "Sở thích",
            group: "interest_group",
          ),
          
          SizedBox(height: 24),
          
          CyberButton(
            label: "Đăng ký",
            onClick: _submitRegistration,
          ),
        ],
      ),
    );
  }
}
```

---

## 10. Advanced Examples

### Survey Form
```dart
class SurveyForm extends StatefulWidget {
  @override
  State<SurveyForm> createState() => _SurveyFormState();
}

class _SurveyFormState extends State<SurveyForm> {
  late CyberDataTable dt;
  late CyberDataRow row;

  @override
  void initState() {
    super.initState();
    dt = CyberDataTable(tableName: "Survey");
    dt.addColumn("q1", CyberDataType.text);
    dt.addColumn("q2", CyberDataType.text);
    dt.addColumn("q3", CyberDataType.text);
    
    row = dt.newRow();
    row["q1"] = "";
    row["q2"] = "";
    row["q3"] = "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Khảo sát')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Khảo sát sự hài lòng",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            
            SizedBox(height: 24),
            
            // Question 1
            CyberRadioGroup(
              text: row.bind("q1"),
              values: "1;2;3;4;5",
              displays: "Rất không hài lòng;Không hài lòng;Bình thường;Hài lòng;Rất hài lòng",
              label: "1. Bạn đánh giá dịch vụ như thế nào?",
              group: "q1_group",
            ),
            
            SizedBox(height: 24),
            
            // Question 2
            CyberRadioGroup(
              text: row.bind("q2"),
              values: "yes;no",
              displays: "Có;Không",
              label: "2. Bạn có muốn sử dụng tiếp không?",
              group: "q2_group",
              direction: Axis.horizontal,
            ),
            
            SizedBox(height: 24),
            
            // Question 3
            CyberRadioGroup(
              text: row.bind("q3"),
              values: "1;2;3",
              displays: "Ít hơn 1 lần/tuần;1-3 lần/tuần;Hơn 3 lần/tuần",
              label: "3. Bạn sử dụng bao nhiêu lần mỗi tuần?",
              group: "q3_group",
            ),
            
            SizedBox(height: 24),
            
            CyberButton(
              label: "Gửi khảo sát",
              onClick: () {
                // Submit survey
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

### Dynamic Options from API
```dart
class DynamicOptionsForm extends CyberContentViewForm {
  late CyberDataTable dtUser;
  late CyberDataRow rowUser;
  late CyberDataTable dtCategories;
  late CyberDataRow rowCategories;

  @override
  void onInit() {
    dtUser = CyberDataTable(tableName: "User");
    dtUser.addColumn("category", CyberDataType.text);
    rowUser = dtUser.newRow();
    rowUser["category"] = "";
    
    dtCategories = CyberDataTable(tableName: "Categories");
    dtCategories.addColumn("values", CyberDataType.text);
    dtCategories.addColumn("displays", CyberDataType.text);
    rowCategories = dtCategories.newRow();
    rowCategories["values"] = "";
    rowCategories["displays"] = "";
  }

  @override
  Future<void> onLoadData() async {
    // Load categories from API
    final response = await context.callApi(
      functionName: "GetCategories",
      parameter: "",
    );

    if (response.isValid()) {
      final ds = response.toCyberDataset();
      if (ds != null && ds.tables.isNotEmpty) {
        final dtResult = ds[0];
        
        // Build values and displays strings
        List<String> values = [];
        List<String> displays = [];
        
        for (var row in dtResult!.rows) {
          values.add(row["id"].toString());
          displays.add(row["name"].toString());
        }
        
        rowCategories["values"] = values.join(";");
        rowCategories["displays"] = displays.join(";");
      }
    }
  }

  @override
  Widget buildBody(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          CyberRadioGroup(
            text: rowUser.bind("category"),
            values: rowCategories.bind("values"), // Dynamic from API
            displays: rowCategories.bind("displays"), // Dynamic from API
            label: "Chọn danh mục",
            group: "category_group",
          ),
          
          SizedBox(height: 16),
          
          CyberButton(
            label: "Lưu",
            onClick: () async {
              // Save
            },
          ),
        ],
      ),
    );
  }
}
```

---

## 11. Common Use Cases

### Gender Selection
```dart
CyberRadioGroup(
  text: row.bind("gender"),
  values: "0;1",
  displays: "Nam;Nữ",
  label: "Giới tính",
  group: "gender",
  direction: Axis.horizontal,
)
```

### Yes/No Question
```dart
CyberRadioGroup(
  text: row.bind("agree"),
  values: "0;1",
  displays: "Không đồng ý;Đồng ý",
  label: "Bạn có đồng ý với điều khoản?",
  group: "agree",
  direction: Axis.horizontal,
)
```

### Size Selection
```dart
CyberRadioGroup(
  text: row.bind("size"),
  values: "S;M;L;XL",
  displays: "Nhỏ;Vừa;Lớn;Rất lớn",
  label: "Kích cỡ",
  group: "size",
  direction: Axis.horizontal,
  spacing: 16,
)
```

### Priority Level
```dart
CyberRadioGroup(
  text: row.bind("priority"),
  values: "1;2;3",
  displays: "Thấp;Trung bình;Cao",
  label: "Độ ưu tiên",
  group: "priority",
  activeColor: Colors.red,
)
```

### Payment Method
```dart
CyberRadioGroup(
  text: row.bind("payment"),
  values: "cash;card;transfer;ewallet",
  displays: "Tiền mặt;Thẻ;Chuyển khoản;Ví điện tử",
  label: "Phương thức thanh toán",
  group: "payment",
)
```

---

## 12. Tips & Best Practices

### ✅ DO - Nên làm

```dart
// ✅ Đảm bảo số lượng values và displays khớp
CyberRadioGroup(
  values: "0;1;2",
  displays: "Option A;Option B;Option C", // 3 items
)

// ✅ Sử dụng binding cho dynamic data
CyberRadioGroup(
  text: row.bind("field"),
  values: configRow.bind("values"),
  displays: configRow.bind("displays"),
)

// ✅ Validate trong onLeaver
CyberRadioGroup(
  text: row.bind("required"),
  onLeaver: (value) {
    if (value == null || value.toString().isEmpty) {
      context.showErrorMsg("Vui lòng chọn!");
    }
  },
)

// ✅ Sử dụng horizontal cho options ngắn
CyberRadioGroup(
  values: "0;1",
  displays: "Có;Không",
  direction: Axis.horizontal,
)
```

### ❌ DON'T - Không nên làm

```dart
// ❌ Values và displays không khớp
CyberRadioGroup(
  values: "0;1;2",
  displays: "A;B", // Missing one!
)

// ❌ Quá nhiều options cho horizontal
CyberRadioGroup(
  values: "1;2;3;4;5;6;7;8",
  displays: "...",
  direction: Axis.horizontal, // Quá dài!
)

// ❌ Label quá dài
CyberRadioGroup(
  displays: "This is a very long label that should be shorter",
  // Nên rút gọn label
)
```

---

## 13. Comparison: Old vs New

### Old CyberRadioBox
```dart
CyberRadioBox(
  text: row.bind("gender"),
  group: "gender_group",
  value: "0",
  label: "Nam",
)

CyberRadioBox(
  text: row.bind("gender"),
  group: "gender_group",
  value: "1",
  label: "Nữ",
)
```

### New CyberRadioGroup
```dart
CyberRadioGroup(
  text: row.bind("gender"),
  values: "0;1",
  displays: "Nam;Nữ",
  group: "gender_group",
)
```

**Ưu điểm:**
- ✅ Ngắn gọn hơn
- ✅ Dễ maintain
- ✅ Hỗ trợ dynamic values/displays

---

## Feature Summary

✅ Khai báo đơn giản với string separator ";"
✅ Support binding cho text, values, displays
✅ 2-way data binding
✅ Horizontal/Vertical layout
✅ Custom spacing, colors, size
✅ Callbacks: onChanged, onLeaver
✅ Enabled/disabled state
✅ Visibility binding
✅ Type preservation
✅ iOS-style design
