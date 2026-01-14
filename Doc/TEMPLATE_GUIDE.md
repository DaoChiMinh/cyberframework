# Text Template Parser - Documentation

## Tổng quan

Text Template Parser cho phép bạn định nghĩa template với các placeholder và tự động extract dữ liệu có cấu trúc từ text nhận diện được.

## Template Syntax

### Basic Syntax

```
Label: [<KEY,TYPE>]
```

- **Label**: Text hiển thị trước giá trị (ví dụ: "Họ và tên:", "Số CCCD:")
- **KEY**: Tên biến để lưu giá trị
- **TYPE**: Kiểu dữ liệu (C, N, B, D)

### Data Types

| Type | Ý nghĩa | Output Type | Ví dụ |
|------|---------|-------------|-------|
| C | String (Character) | String | "NGUYỄN VĂN A" |
| N | Number | double | 123.45 |
| B | Boolean | bool | true/false |
| D | Date | DateTime | DateTime(1990, 1, 1) |

### Advanced Syntax với Pattern

```
Label: [<KEY,TYPE,PATTERN>]
```

**PATTERN**: Regex pattern để validate/extract giá trị

## Ví dụ Templates

### 1. CCCD Template

```dart
final cccdTemplate = TextTemplate.fromString(
  'CCCD',
  '''
Cộng hòa xã hội chủ nghĩa việt nam
CĂN CƯỚC CÔNG DÂN
Số/NO: [<SO_CAN_CUOC,C>]
Họ và tên: [<HO_TEN,C>]
Ngày, tháng, năm sinh: [<NGAY_SINH,D>]
Giới tính: [<GIOI_TINH,C>]
Quốc tịch: [<QUOC_TICH,C>]
Quê quán: [<QUE_QUAN,C>]
Nơi thường trú: [<NOI_THUONG_TRU,C>]
''',
);
```

**Input text:**
```
Cộng hòa xã hội chủ nghĩa việt nam
CĂN CƯỚC CÔNG DÂN
Số/NO: 001234567890
Họ và tên: NGUYỄN VĂN A
Ngày, tháng, năm sinh: 01/01/1990
Giới tính: Nam
Quốc tịch: Việt Nam
Quê quán: Hà Nội
Nơi thường trú: 123 Đường ABC, Hà Nội
```

**Output:**
```dart
{
  'SO_CAN_CUOC': '001234567890',
  'HO_TEN': 'NGUYỄN VĂN A',
  'NGAY_SINH': DateTime(1990, 1, 1),
  'GIOI_TINH': 'Nam',
  'QUOC_TICH': 'Việt Nam',
  'QUE_QUAN': 'Hà Nội',
  'NOI_THUONG_TRU': '123 Đường ABC, Hà Nội',
}
```

### 2. Invoice Template

```dart
final invoiceTemplate = TextTemplate.fromString(
  'Invoice',
  '''
HÓA ĐƠN BÁN HÀNG
Số hóa đơn: [<SO_HOA_DON,C>]
Ngày: [<NGAY_HOA_DON,D>]
Khách hàng: [<TEN_KHACH_HANG,C>]
Số điện thoại: [<SO_DIEN_THOAI,C,0[3|5|7|8|9]\\d{8}>]
Tổng tiền: [<TONG_TIEN,N>]
Đã thanh toán: [<DA_THANH_TOAN,B>]
''',
);
```

**Input text:**
```
HÓA ĐƠN BÁN HÀNG
Số hóa đơn: HD-2024-001
Ngày: 14/01/2024
Khách hàng: Nguyễn Văn B
Số điện thoại: 0912345678
Tổng tiền: 1,500,000đ
Đã thanh toán: Có
```

**Output:**
```dart
{
  'SO_HOA_DON': 'HD-2024-001',
  'NGAY_HOA_DON': DateTime(2024, 1, 14),
  'TEN_KHACH_HANG': 'Nguyễn Văn B',
  'SO_DIEN_THOAI': '0912345678',
  'TONG_TIEN': 1500000.0,
  'DA_THANH_TOAN': true,
}
```

### 3. Business Card Template

```dart
final businessCardTemplate = TextTemplate.fromString(
  'Business Card',
  '''
Name: [<Name,C>]
Title: [<Title,C>]
Company: [<Company,C>]
Phone: [<Phone,C,0[3|5|7|8|9]\\d{8}>]
Email: [<Email,C,[\\w\\.-]+@[\\w\\.-]+\\.\\w+>]
Address: [<Address,C>]
''',
);
```

### 4. Medical Record Template

```dart
final medicalTemplate = TextTemplate.fromString(
  'Medical Record',
  '''
BỆNH ÁN
Số bệnh án: [<MA_BENH_AN,C>]
Họ tên bệnh nhân: [<HO_TEN,C>]
Tuổi: [<TUOI,N>]
Ngày khám: [<NGAY_KHAM,D>]
Chẩn đoán: [<CHAN_DOAN,C>]
Huyết áp: [<HUYET_AP,C>]
Nhiệt độ: [<NHIET_DO,N>]
''',
);
```

## Sử dụng với CyberCameraRecognitionText

### Basic Usage

```dart
// 1. Define template
final template = TextTemplate.fromString(
  'My Template',
  '''
Field 1: [<KEY1,C>]
Field 2: [<KEY2,N>]
  ''',
);

// 2. Create parser
final parser = TextTemplateParser(template);

// 3. Use with camera
CyberCameraRecognitionText(
  onTextRecognized: (result) {
    // Parse text với template
    final data = parser.parse(result.fullText);
    
    // Access values
    print('KEY1: ${data['KEY1']}');
    print('KEY2: ${data['KEY2']}');
    
    // Validate
    if (parser.validate(data)) {
      print('Valid data!');
    }
  },
)
```

### Advanced Usage

```dart
class MyTemplateScanner extends StatefulWidget {
  @override
  State<MyTemplateScanner> createState() => _MyTemplateScannerState();
}

class _MyTemplateScannerState extends State<MyTemplateScanner> {
  final _template = TextTemplate.fromString('CCCD', '''
Số: [<SO_CCCD,C>]
Họ tên: [<HO_TEN,C>]
Ngày sinh: [<NGAY_SINH,D>]
  ''');
  
  late final TextTemplateParser _parser;
  Map<String, dynamic>? _data;
  
  @override
  void initState() {
    super.initState();
    _parser = TextTemplateParser(_template, fuzzyThreshold: 0.7);
  }
  
  @override
  Widget build(BuildContext context) {
    return CyberCameraRecognitionText(
      onTextRecognized: (result) {
        final data = _parser.parse(result.fullText);
        
        if (_parser.validate(data)) {
          setState(() => _data = data);
          
          // Process valid data
          _saveToDatabase(data);
        }
      },
    );
  }
  
  void _saveToDatabase(Map<String, dynamic> data) {
    // Save to DB
  }
}
```

## Type Conversion Details

### String (C)

```dart
Input: "NGUYỄN VĂN A"
Output: "NGUYỄN VĂN A" (String)
```

Giữ nguyên text, chỉ trim whitespace.

### Number (N)

```dart
Input: "1,500,000"    → Output: 1500000.0
Input: "1.500.000"    → Output: 1500000.0
Input: "123.45"       → Output: 123.45
Input: "100"          → Output: 100.0
```

Auto remove separators (`,` và `.`), parse thành double.

### Boolean (B)

```dart
// True values
Input: "true", "yes", "1", "có", "x", "X"
Output: true

// False values
Input: "false", "no", "0", "không", ""
Output: false

// Other values
Output: null
```

### Date (D)

Supports multiple formats:

```dart
Input: "01/01/1990"     → DateTime(1990, 1, 1)  // DD/MM/YYYY
Input: "1/1/1990"       → DateTime(1990, 1, 1)  // D/M/YYYY
Input: "1990-01-01"     → DateTime(1990, 1, 1)  // YYYY-MM-DD
Input: "01/01/90"       → DateTime(1990, 1, 1)  // DD/MM/YY
```

## Pattern Matching

### Phone Number Pattern

```dart
[<PHONE,C,0[3|5|7|8|9]\\d{8}>]
```

Matches Vietnamese phone numbers: 0912345678

### Email Pattern

```dart
[<EMAIL,C,[\\w\\.-]+@[\\w\\.-]+\\.\\w+>]
```

Matches: user@example.com

### CCCD Number Pattern

```dart
[<CCCD,C,\\d{12}>]
```

Matches: 12 digits exactly

### Custom Pattern

```dart
[<INVOICE_NO,C,HD-\\d{4}-\\d{3}>]
```

Matches: HD-2024-001

## Fuzzy Matching

Template parser sử dụng fuzzy matching để handle OCR errors.

### Fuzzy Threshold

```dart
// Strict matching (0.9 = 90% similarity)
final parser = TextTemplateParser(template, fuzzyThreshold: 0.9);

// Lenient matching (0.6 = 60% similarity)
final parser = TextTemplateParser(template, fuzzyThreshold: 0.6);

// Default (0.7 = 70% similarity)
final parser = TextTemplateParser(template);
```

### Examples

Template: `Họ và tên: [<NAME,C>]`

```dart
// Exact match
Input: "Họ và tên: NGUYỄN VĂN A"  ✅ Match

// OCR error
Input: "Ho va ten: NGUYỄN VĂN A"  ✅ Match (fuzzy)
Input: "Họ và ten: NGUYỄN VĂN A"  ✅ Match (fuzzy)
Input: "Ho va: NGUYỄN VĂN A"      ❌ Too different
```

## Validation

```dart
final parser = TextTemplateParser(template);
final data = parser.parse(text);

// Validate
if (parser.validate(data)) {
  print('All required fields present');
} else {
  print('Missing or invalid fields');
}

// Manual validation
if (data.containsKey('SO_CCCD') && data['SO_CCCD'] != null) {
  final cccd = data['SO_CCCD'] as String;
  if (cccd.length == 12) {
    print('Valid CCCD');
  }
}
```

## Debugging

### Debug Parse

```dart
final parser = TextTemplateParser(template);
parser.debugParse(recognizedText);
```

Output:
```
╔═══════════════════════════════════════╗
║ Template: CCCD Template
╠═══════════════════════════════════════╣
║ SO_CAN_CUOC (TemplateFieldType.string):
║   Value: 001234567890
║   Type: String
║ HO_TEN (TemplateFieldType.string):
║   Value: NGUYỄN VĂN A
║   Type: String
║ NGAY_SINH (TemplateFieldType.date):
║   Value: 1990-01-01 00:00:00.000
║   Type: DateTime
╠═══════════════════════════════════════╣
║ Valid: true
╚═══════════════════════════════════════╝
```

### Debug Template

```dart
print('Template: ${template.name}');
print('Fields: ${template.fields.length}');

for (var field in template.fields) {
  print('${field.key}: ${field.type}');
}
```

## Best Practices

### 1. Label rõ ràng

```dart
// ✅ GOOD
"Số CCCD: [<SO_CCCD,C>]"
"Họ và tên: [<HO_TEN,C>]"

// ❌ BAD
"Số: [<SO_CCCD,C>]"  // Quá ngắn, dễ nhầm
"[<SO_CCCD,C>]"      // Không có label
```

### 2. Sử dụng pattern khi cần

```dart
// ✅ GOOD - Validate phone
[<PHONE,C,0[3|5|7|8|9]\\d{8}>]

// ✅ GOOD - Validate email
[<EMAIL,C,[\\w\\.-]+@[\\w\\.-]+\\.\\w+>]

// ❌ BAD - Không validate
[<PHONE,C>]  // Accept bất kỳ text nào
```

### 3. Type chính xác

```dart
// ✅ GOOD
"Tuổi: [<AGE,N>]"           // Number
"Ngày sinh: [<DOB,D>]"      // Date
"Đã kết hôn: [<MARRIED,B>]" // Boolean

// ❌ BAD
"Tuổi: [<AGE,C>]"           // String instead of Number
"Ngày sinh: [<DOB,C>]"      // String instead of Date
```

### 4. Fuzzy threshold hợp lý

```dart
// ✅ GOOD - Balance
fuzzyThreshold: 0.7  // Default

// ⚠️ Careful
fuzzyThreshold: 0.5  // Too lenient, many false positives
fuzzyThreshold: 0.95 // Too strict, miss OCR errors
```

### 5. Always validate

```dart
// ✅ GOOD
final data = parser.parse(text);
if (parser.validate(data)) {
  processData(data);
} else {
  showError('Incomplete data');
}

// ❌ BAD
final data = parser.parse(text);
processData(data);  // No validation!
```

## Performance Tips

### Tip 1: Reuse parser

```dart
// ✅ GOOD - Create once
final parser = TextTemplateParser(template);

onTextRecognized: (result) {
  final data = parser.parse(result.fullText);
}

// ❌ BAD - Create mỗi lần
onTextRecognized: (result) {
  final parser = TextTemplateParser(template);  // Slow!
  final data = parser.parse(result.fullText);
}
```

### Tip 2: Cache templates

```dart
class TemplateManager {
  static final Map<String, TextTemplate> _cache = {};
  
  static TextTemplate get(String name, String definition) {
    return _cache.putIfAbsent(
      name,
      () => TextTemplate.fromString(name, definition),
    );
  }
}
```

### Tip 3: Simple patterns

```dart
// ✅ GOOD - Simple pattern
[<PHONE,C,\\d{10}>]

// ❌ BAD - Complex pattern (slower)
[<PHONE,C,(?:(?:\\+|00)84|0)(?:3[2-9]|5[6|8|9]|7[0|6-9]|8[1-9]|9[0-9])[0-9]{7}>]
```

## Common Issues

### Issue 1: Không match được label

```dart
// Template
"Họ và tên: [<NAME,C>]"

// Text nhận diện
"Ho va ten: NGUYỄN VĂN A"  // OCR sai dấu

// Solution: Lower fuzzy threshold
final parser = TextTemplateParser(template, fuzzyThreshold: 0.6);
```

### Issue 2: Pattern không match

```dart
// Template
[<PHONE,C,0\\d{9}>]

// Text
"Phone: 0912 345 678"  // Có space

// Solution: Pre-process text
final cleaned = text.replaceAll(' ', '');
final data = parser.parse(cleaned);
```

### Issue 3: Date parse fail

```dart
// Text
"Ngày sinh: 1-1-1990"  // Format không chuẩn

// Solution: Normalize format trước
final normalized = text.replaceAll('-', '/');
final data = parser.parse(normalized);
```

## Example: Complete Flow

```dart
class CCCDScanner extends StatefulWidget {
  @override
  State<CCCDScanner> createState() => _CCCDScannerState();
}

class _CCCDScannerState extends State<CCCDScanner> {
  // 1. Define template
  final _template = TextTemplate.fromString('CCCD', '''
Số/NO: [<SO_CCCD,C,\\d{12}>]
Họ và tên: [<HO_TEN,C>]
Ngày sinh: [<NGAY_SINH,D>]
  ''');
  
  late final TextTemplateParser _parser;
  Map<String, dynamic>? _data;
  
  @override
  void initState() {
    super.initState();
    // 2. Create parser
    _parser = TextTemplateParser(_template);
  }
  
  void _onTextRecognized(RecognizedTextResult result) {
    // 3. Parse
    final data = _parser.parse(result.fullText);
    
    // 4. Validate
    if (!_parser.validate(data)) {
      print('Invalid data');
      return;
    }
    
    // 5. Process
    setState(() => _data = data);
    
    // 6. Save
    _saveCCCD(
      soCCCD: data['SO_CCCD'] as String,
      hoTen: data['HO_TEN'] as String,
      ngaySinh: data['NGAY_SINH'] as DateTime,
    );
  }
  
  void _saveCCCD({
    required String soCCCD,
    required String hoTen,
    required DateTime ngaySinh,
  }) {
    // Save to database
  }
  
  @override
  Widget build(BuildContext context) {
    return CyberCameraRecognitionText(
      onTextRecognized: _onTextRecognized,
    );
  }
}
```

## Summary

**Template Format:**
```
Label: [<KEY,TYPE>]
Label: [<KEY,TYPE,PATTERN>]
```

**Types:**
- C = String
- N = Number (double)
- B = Boolean
- D = Date (DateTime)

**Usage:**
1. Create template với `TextTemplate.fromString()`
2. Create parser với `TextTemplateParser(template)`
3. Parse text với `parser.parse(text)`
4. Validate với `parser.validate(data)`
5. Access data từ `Map<String, dynamic>`

**Features:**
- Fuzzy matching cho OCR errors
- Pattern matching với regex
- Type conversion tự động
- Validation built-in
