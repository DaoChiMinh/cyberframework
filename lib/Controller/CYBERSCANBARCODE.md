# Cyberscanbarcode - Hướng Dẫn Sử Dụng Đầy Đủ

## 📖 Giới Thiệu

`Cyberscanbarcode` là widget quét mã vạch/QR code chuyên nghiệp cho CyberFramework với nhiều tính năng nâng cao:

- ✅ Quét mọi loại mã vạch (QR, Code 128, EAN, v.v.)
- ✅ Quét liên tục hoặc một lần
- ✅ Click để bật/tắt quét thủ công
- ✅ Hiển thị trạng thái và thông báo động
- ✅ Binding trực tiếp từ CyberDataRow
- ✅ Tùy chỉnh giao diện đầy đủ
- ✅ Tối ưu hiệu suất và quản lý vòng đời tự động

---

## 📦 Cài Đặt

### 1. Thêm Dependency

```yaml
# pubspec.yaml
dependencies:
  mobile_scanner: ^5.0.0  # hoặc version mới nhất
```

### 2. Cấu Hình Quyền

**Android** - `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" />
<uses-feature android:name="android.hardware.camera.autofocus" />
```

**iOS** - `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>App cần quyền camera để quét mã vạch</string>
```

### 3. Import Widget

```dart
import 'package:your_package/cyberscanbarcode.dart';
```

---

## 🚀 Sử Dụng Cơ Bản

### Ví Dụ Đơn Giản Nhất

```dart
Scaffold(
  body: Cyberscanbarcode(
    height: 300,
    onCapture: (value) {
      print('Đã quét: $value');
    },
  ),
)
```

Chỉ cần 4 dòng code, bạn đã có một scanner hoàn chỉnh!

---

## 📋 Tất Cả Thuộc Tính

### Thuộc Tính Cơ Bản

| Thuộc tính | Kiểu | Mặc định | Mô tả |
|------------|------|----------|-------|
| `onCapture` | `Function(String)?` | `null` | Callback khi quét thành công |
| `height` | `double?` | `null` | Chiều cao widget |
| `borderRadius` | `double?` | `12.0` | Độ bo góc |

### Cấu Hình Scanner

| Thuộc tính | Kiểu | Mặc định | Mô tả |
|------------|------|----------|-------|
| `debounceMs` | `int` | `1000` | Thời gian chờ giữa các lần quét (ms) |
| `torchEnabled` | `bool` | `false` | Bật đèn flash |
| `autoZoom` | `bool` | `false` | Tự động zoom (tắt để tăng hiệu suất) |

### Điều Khiển Quét

| Thuộc tính | Kiểu | Mặc định | Mô tả |
|------------|------|----------|-------|
| `clickScan` | `bool` | `false` | Click màn hình để bật/tắt quét |
| `continuousScan` | `bool` | `true` | `true`: Quét liên tục<br>`false`: Quét 1 lần rồi dừng |

### Hiển Thị Trạng Thái

| Thuộc tính | Kiểu | Mặc định | Mô tả |
|------------|------|----------|-------|
| `showStatus` | `bool` | `true` | Hiện "Đang quét / Dừng quét" |
| `statusTextColor` | `Color` | `Colors.white` | Màu chữ trạng thái |
| `statusBackgroundColor` | `Color` | `Colors.black54` | Màu nền trạng thái |

### Thông Báo Runtime (Message)

| Thuộc tính | Kiểu | Mặc định | Mô tả |
|------------|------|----------|-------|
| `message` | `String?` | `null` | Thông báo tĩnh |
| `messageGetter` | `String Function()?` | `null` | Thông báo động (binding) |
| `showMessage` | `bool` | `true` | Hiển thị message |
| `messageTextColor` | `Color` | `Colors.white` | Màu chữ message |
| `messageBackgroundColor` | `Color` | `Colors.blue` | Màu nền message |
| `messagePosition` | `String` | `'bottom'` | Vị trí: `'top'`, `'center'`, `'bottom'` |
| `messageFontSize` | `double` | `16.0` | Kích thước font |
| `messageIcon` | `IconData?` | `null` | Icon cho message |
| `messageUpdateInterval` | `int` | `500` | Tần suất update message (ms) |

---

## 🎯 Các Chế Độ Quét

### 1. Chế Độ Liên Tục (Mặc Định)

Scanner quét mãi không dừng - thích hợp cho kiểm kho, inventory.

```dart
Cyberscanbarcode(
  height: 300,
  continuousScan: true, // ← Quét liên tục (mặc định)
  onCapture: (value) {
    print('Quét: $value');
  },
)
```

**Đặc điểm:**
- ✅ Quét liên tục không dừng
- ✅ Tự động reset sau debounce time
- ✅ Thích hợp: Inventory, warehouse, kiểm kho

---

### 2. Chế Độ Một Lần

Scanner dừng sau khi quét được 1 mã - thích hợp cho check-in, quét vé.

```dart
Cyberscanbarcode(
  height: 300,
  continuousScan: false, // ← Quét 1 lần rồi dừng
  onCapture: (value) {
    print('Đã quét: $value');
  },
)
```

**Đặc điểm:**
- ✅ Quét 1 mã rồi dừng hẳn
- ✅ Phải reset để quét lại
- ✅ Thích hợp: Check-in, quét vé, product lookup

---

### 3. Chế Độ Click Để Quét

Người dùng click để bật/tắt scanner thủ công.

```dart
Cyberscanbarcode(
  height: 300,
  clickScan: true, // ← Cho phép click
  continuousScan: true, // Có thể kết hợp với continuous
  onCapture: (value) {
    print('Quét: $value');
  },
)
```

**Đặc điểm:**
- ✅ Click vào màn hình → Bật quét
- ✅ Click lại → Tắt quét
- ✅ Hiện icon pause khi dừng
- ✅ Thích hợp: Người dùng muốn kiểm soát

---

## 💬 Hiển Thị Thông Báo (Message)

### 1. Thông Báo Tĩnh (Static)

Hiển thị text cố định.

```dart
Cyberscanbarcode(
  height: 300,
  message: 'Quét mã sản phẩm để xem giá',
  messageIcon: Icons.shopping_cart,
  messageBackgroundColor: Colors.blue,
  onCapture: (value) {
    // Xử lý...
  },
)
```

---

### 2. Thông Báo Động (Dynamic - Từ State)

Message tự động update khi state thay đổi.

```dart
class ScanPage extends StatefulWidget {
  @override
  _ScanPageState createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  String _productName = 'Chưa quét sản phẩm';
  double _price = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Cyberscanbarcode(
        height: 300,
        // ✅ Binding từ state
        messageGetter: () => '$_productName - ${_price.toStringAsFixed(0)} đ',
        messageIcon: Icons.inventory,
        onCapture: (barcode) async {
          // Load product
          final product = await loadProduct(barcode);
          
          // Update state → Message tự động update
          setState(() {
            _productName = product.name;
            _price = product.price;
          });
        },
      ),
    );
  }
}
```

---

### 3. Binding Từ CyberDataRow (Recommended)

Tích hợp hoàn hảo với CyberFramework.

```dart
class ProductScanner extends StatefulWidget {
  @override
  _ProductScannerState createState() => _ProductScannerState();
}

class _ProductScannerState extends State<ProductScanner> {
  late CyberDataRow productRow;

  @override
  void initState() {
    super.initState();
    
    // Khởi tạo CyberDataRow
    productRow = CyberDataRow();
    productRow["ProductName"] = "Chưa quét";
    productRow["Price"] = 0.0;
    productRow["Stock"] = 0;
    
    // Lắng nghe thay đổi để rebuild widget
    productRow.addListener(() {
      setState(() {}); // Trigger rebuild
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Scanner với binding
          Container(
            height: 300,
            child: Cyberscanbarcode(
              // ✅ Binding trực tiếp từ CyberDataRow
              messageGetter: () {
                final name = productRow["ProductName"]?.toString() ?? "";
                final price = productRow["Price"] ?? 0.0;
                return "$name - ${price.toStringAsFixed(0)} đ";
              },
              messageIcon: Icons.store,
              messageBackgroundColor: Colors.green[700]!,
              onCapture: (barcode) async {
                // Load product từ API
                final product = await loadProduct(barcode);
                
                // Update CyberDataRow → Message tự động update
                productRow["ProductName"] = product.name;
                productRow["Price"] = product.price;
                productRow["Stock"] = product.stock;
              },
            ),
          ),
          
          // Hiển thị chi tiết
          Expanded(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sản phẩm: ${productRow["ProductName"]}'),
                    Text('Giá: ${productRow["Price"]} đ'),
                    Text('Tồn kho: ${productRow["Stock"]}'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

**Ưu điểm:**
- ✅ Tích hợp sẵn với CyberFramework
- ✅ Tự động update khi data thay đổi
- ✅ Code sạch và dễ maintain
- ✅ Support multiple fields

---

## 🎨 Tùy Chỉnh Giao Diện

### Vị Trí Message

```dart
// Message ở trên
Cyberscanbarcode(
  message: 'Thông báo ở trên',
  messagePosition: 'top',
)

// Message ở giữa
Cyberscanbarcode(
  message: 'Thông báo ở giữa',
  messagePosition: 'center',
)

// Message ở dưới (mặc định)
Cyberscanbarcode(
  message: 'Thông báo ở dưới',
  messagePosition: 'bottom',
)
```

### Theme Màu Sắc

```dart
// Green Success Theme
Cyberscanbarcode(
  message: 'Sẵn sàng quét',
  messageBackgroundColor: Colors.green[700]!,
  messageTextColor: Colors.white,
  messageIcon: Icons.check_circle,
)

// Orange Warning Theme
Cyberscanbarcode(
  message: 'Cảnh báo',
  messageBackgroundColor: Colors.orange[700]!,
  messageIcon: Icons.warning,
)

// Red Error Theme
Cyberscanbarcode(
  message: 'Lỗi',
  messageBackgroundColor: Colors.red[700]!,
  messageIcon: Icons.error,
)

// Purple Premium Theme
Cyberscanbarcode(
  message: 'VIP Scanner',
  messageBackgroundColor: Colors.purple[700]!,
  messageIcon: Icons.star,
)
```

### Ẩn/Hiện Elements

```dart
// Ẩn status, chỉ hiện message
Cyberscanbarcode(
  showStatus: false,
  message: 'Only message',
)

// Ẩn message, chỉ hiện status
Cyberscanbarcode(
  showMessage: false,
)

// Ẩn tất cả - UI minimal
Cyberscanbarcode(
  showStatus: false,
  showMessage: false,
  borderRadius: 0, // Full screen
)
```

---

## 💼 Use Cases Thực Tế

### 1. Check-in Sự Kiện

Quét vé, hiển thị thông tin người tham dự.

```dart
class EventCheckIn extends StatefulWidget {
  @override
  _EventCheckInState createState() => _EventCheckInState();
}

class _EventCheckInState extends State<EventCheckIn> {
  late CyberDataRow attendeeRow;
  int _checkInCount = 0;

  @override
  void initState() {
    super.initState();
    
    attendeeRow = CyberDataRow();
    attendeeRow["Name"] = "";
    attendeeRow["TicketType"] = "";
    attendeeRow.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Check-in'),
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.only(right: 16),
              child: Chip(
                label: Text('Check-in: $_checkInCount'),
              ),
            ),
          ),
        ],
      ),
      body: Cyberscanbarcode(
        height: 400,
        continuousScan: false, // Quét 1 vé rồi dừng
        clickScan: true,       // Click để quét vé tiếp
        debounceMs: 500,       // Nhanh hơn cho check-in
        
        // Hiển thị thông tin người vừa check-in
        messageGetter: () {
          final name = attendeeRow["Name"]?.toString() ?? "";
          final type = attendeeRow["TicketType"]?.toString() ?? "";
          
          if (name.isEmpty) {
            return "Quét QR code để check-in";
          }
          
          return "✅ $name\n🎫 $type";
        },
        
        messageIcon: Icons.how_to_reg,
        messagePosition: 'center',
        messageBackgroundColor: Colors.green[600]!,
        messageFontSize: 18,
        
        onCapture: (qrCode) async {
          // Validate ticket qua API
          final attendee = await validateTicket(qrCode);
          
          if (attendee != null) {
            attendeeRow["Name"] = attendee.name;
            attendeeRow["TicketType"] = attendee.ticketType;
            _checkInCount++;
            
            // Hiệu ứng âm thanh
            playSuccessSound();
          } else {
            attendeeRow["Name"] = "❌ Vé không hợp lệ";
            attendeeRow["TicketType"] = "";
            playErrorSound();
          }
        },
      ),
    );
  }
}
```

---

### 2. Quầy Thu Ngân (POS)

Quét sản phẩm, hiển thị tổng giá tiền.

```dart
class POSSystem extends StatefulWidget {
  @override
  _POSSystemState createState() => _POSSystemState();
}

class _POSSystemState extends State<POSSystem> {
  late CyberDataRow cartRow;
  final List<Product> _items = [];

  @override
  void initState() {
    super.initState();
    
    cartRow = CyberDataRow();
    cartRow["ItemCount"] = 0;
    cartRow["Total"] = 0.0;
    cartRow["LastProduct"] = "";
    cartRow.addListener(() => setState(() {}));
  }

  void _addProduct(String barcode) async {
    // Tìm sản phẩm
    final product = await findProduct(barcode);
    
    if (product != null) {
      setState(() {
        _items.add(product);
      });
      
      // Update cart
      cartRow["ItemCount"] = _items.length;
      cartRow["Total"] = _items.fold(0.0, (sum, item) => sum + item.price);
      cartRow["LastProduct"] = product.name;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quầy Thu Ngân')),
      body: Column(
        children: [
          // Scanner ở trên
          Container(
            height: 200,
            margin: EdgeInsets.all(16),
            child: Cyberscanbarcode(
              continuousScan: true, // Quét liên tục
              
              // Hiển thị sản phẩm vừa quét + tổng tiền
              messageGetter: () {
                final lastProduct = cartRow["LastProduct"] ?? "";
                final total = cartRow["Total"] ?? 0.0;
                
                if (lastProduct.isEmpty) {
                  return "Quét sản phẩm để thêm vào giỏ";
                }
                
                return "➕ $lastProduct\nTổng: ${total.toStringAsFixed(0)} đ";
              },
              
              messageIcon: Icons.shopping_basket,
              messageBackgroundColor: Colors.green[700]!,
              onCapture: _addProduct,
            ),
          ),
          
          // Danh sách sản phẩm
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return ListTile(
                  title: Text(item.name),
                  trailing: Text('${item.price.toStringAsFixed(0)} đ'),
                );
              },
            ),
          ),
          
          // Thanh toán
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tổng: ${(cartRow["Total"] ?? 0.0).toStringAsFixed(0)} đ',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: _items.isEmpty ? null : _checkout,
                  child: Text('Thanh Toán'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _checkout() {
    // Xử lý thanh toán...
  }
}
```

---

### 3. Kiểm Kho (Warehouse)

Quét liên tục, hiển thị vị trí và số lượng.

```dart
class WarehouseInventory extends StatefulWidget {
  @override
  _WarehouseInventoryState createState() => _WarehouseInventoryState();
}

class _WarehouseInventoryState extends State<WarehouseInventory> {
  late CyberDataRow inventoryRow;
  final List<String> _locations = [
    'Kho A - Kệ 1',
    'Kho A - Kệ 2',
    'Kho B - Kệ 1',
    'Kho B - Kệ 2',
  ];

  @override
  void initState() {
    super.initState();
    
    inventoryRow = CyberDataRow();
    inventoryRow["CurrentLocation"] = _locations[0];
    inventoryRow["ScannedCount"] = 0;
    inventoryRow["LastItem"] = "";
    inventoryRow.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kiểm Kho')),
      body: Column(
        children: [
          // Chọn vị trí
          Padding(
            padding: EdgeInsets.all(16),
            child: DropdownButtonFormField<String>(
              value: inventoryRow["CurrentLocation"],
              decoration: InputDecoration(
                labelText: 'Vị trí kiểm kho',
                border: OutlineInputBorder(),
              ),
              items: _locations.map((location) {
                return DropdownMenuItem(
                  value: location,
                  child: Text(location),
                );
              }).toList(),
              onChanged: (value) {
                inventoryRow["CurrentLocation"] = value;
                inventoryRow["ScannedCount"] = 0; // Reset count
              },
            ),
          ),
          
          // Scanner
          Container(
            height: 300,
            margin: EdgeInsets.symmetric(horizontal: 16),
            child: Cyberscanbarcode(
              continuousScan: true, // Quét liên tục
              clickScan: true,      // Có thể pause khi nghỉ
              
              // Hiển thị location + count
              messageGetter: () {
                final location = inventoryRow["CurrentLocation"] ?? "";
                final count = inventoryRow["ScannedCount"] ?? 0;
                return "📍 $location\n✅ Đã quét: $count";
              },
              
              messageIcon: Icons.location_on,
              messagePosition: 'top',
              messageBackgroundColor: Colors.indigo[700]!,
              
              onCapture: (barcode) {
                inventoryRow["ScannedCount"] = 
                    (inventoryRow["ScannedCount"] ?? 0) + 1;
                inventoryRow["LastItem"] = barcode;
                
                // Lưu vào database
                saveToInventory(
                  location: inventoryRow["CurrentLocation"],
                  barcode: barcode,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

---

### 4. Kiểm Tra Chất Lượng (QC)

Quét và kiểm tra, hiển thị số lượng pass/fail.

```dart
class QualityControl extends StatefulWidget {
  @override
  _QualityControlState createState() => _QualityControlState();
}

class _QualityControlState extends State<QualityControl> {
  late CyberDataRow qcRow;

  @override
  void initState() {
    super.initState();
    
    qcRow = CyberDataRow();
    qcRow["BatchNumber"] = "";
    qcRow["TotalScanned"] = 0;
    qcRow["PassedCount"] = 0;
    qcRow["FailedCount"] = 0;
    qcRow["CurrentStatus"] = "Chưa bắt đầu";
    qcRow.addListener(() => setState(() {}));
  }

  String _getQCMessage() {
    final batch = qcRow["BatchNumber"] ?? "";
    final total = qcRow["TotalScanned"] ?? 0;
    final passed = qcRow["PassedCount"] ?? 0;
    final failed = qcRow["FailedCount"] ?? 0;
    final status = qcRow["CurrentStatus"] ?? "";
    
    if (batch.isEmpty) {
      return "Quét mã lô hàng để bắt đầu";
    }
    
    return "Lô: $batch\n✅ $passed | ❌ $failed | Tổng: $total\n$status";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Kiểm Tra Chất Lượng')),
      body: Cyberscanbarcode(
        height: double.infinity,
        borderRadius: 0,
        continuousScan: true,
        
        messageGetter: _getQCMessage,
        messageIcon: Icons.verified,
        messagePosition: 'bottom',
        messageBackgroundColor: Colors.blue[800]!,
        messageFontSize: 16,
        
        onCapture: (barcode) async {
          // Kiểm tra chất lượng
          final qcResult = await performQualityCheck(barcode);
          
          qcRow["TotalScanned"] = (qcRow["TotalScanned"] ?? 0) + 1;
          
          if (qcResult.passed) {
            qcRow["PassedCount"] = (qcRow["PassedCount"] ?? 0) + 1;
            qcRow["CurrentStatus"] = "✅ Đạt chất lượng";
          } else {
            qcRow["FailedCount"] = (qcRow["FailedCount"] ?? 0) + 1;
            qcRow["CurrentStatus"] = "❌ Không đạt: ${qcResult.reason}";
          }
          
          if (qcRow["BatchNumber"].toString().isEmpty) {
            qcRow["BatchNumber"] = qcResult.batchNumber;
          }
        },
      ),
    );
  }
}
```

---

## ⚙️ Cấu Hình Nâng Cao

### Debounce Time (Thời Gian Chờ Giữa Các Lần Quét)

```dart
// Quét nhanh (check-in)
Cyberscanbarcode(
  debounceMs: 500, // 0.5 giây
)

// Quét thông thường (mặc định)
Cyberscanbarcode(
  debounceMs: 1000, // 1 giây
)

// Quét chậm (tránh quét nhầm)
Cyberscanbarcode(
  debounceMs: 2000, // 2 giây
)
```

### Message Update Interval

```dart
// Update nhanh (realtime)
Cyberscanbarcode(
  messageGetter: () => stockPrice,
  messageUpdateInterval: 100, // Update mỗi 100ms
)

// Update bình thường (mặc định)
Cyberscanbarcode(
  messageGetter: () => productName,
  messageUpdateInterval: 500, // Update mỗi 500ms
)

// Update chậm (tiết kiệm pin)
Cyberscanbarcode(
  messageGetter: () => location,
  messageUpdateInterval: 1000, // Update mỗi 1 giây
)
```

### Torch/Flash

```dart
// Bật torch (môi trường tối)
Cyberscanbarcode(
  torchEnabled: true,
)

// Tắt torch (mặc định - tiết kiệm pin)
Cyberscanbarcode(
  torchEnabled: false,
)
```

### Auto Zoom

```dart
// Tắt auto zoom (mặc định - hiệu suất tốt)
Cyberscanbarcode(
  autoZoom: false,
)

// Bật auto zoom (dễ quét hơn nhưng tốn tài nguyên)
Cyberscanbarcode(
  autoZoom: true,
)
```

---

## 🎓 Best Practices

### 1. Chọn Chế Độ Quét Phù Hợp

```dart
// ✅ Check-in, quét vé → Quét 1 lần
continuousScan: false
clickScan: true

// ✅ Kiểm kho, inventory → Quét liên tục
continuousScan: true
clickScan: true

// ✅ Lookup sản phẩm → Quét 1 lần, không cần click
continuousScan: false
clickScan: false
```

### 2. Xử Lý Message Đúng Cách

```dart
// ✅ TỐT: Dùng messageGetter cho dynamic data
messageGetter: () => dataRow["ProductName"]?.toString() ?? "Chưa quét"

// ❌ TRÁNH: Dùng message cho dynamic data
message: productName // Phải setState mỗi lần thay đổi
```

### 3. Giữ Message Ngắn Gọn

```dart
// ✅ TỐT: Ngắn gọn, dễ đọc
messageGetter: () => "${items} items - ${total}đ"

// ❌ TRÁNH: Quá dài, khó đọc
messageGetter: () => "Bạn đã quét được $items sản phẩm với tổng giá trị là ${total} đồng và còn ${remaining} sản phẩm nữa"
```

### 4. Handle Null Safely

```dart
// ✅ TỐT: Có default value
messageGetter: () => dataRow["Name"]?.toString() ?? "Chưa có dữ liệu"

// ❌ TRÁNH: Có thể crash
messageGetter: () => dataRow["Name"].toString() // Crash nếu null
```

### 5. Tối Ưu Performance

```dart
// ✅ TỐT: Tối ưu cho production
Cyberscanbarcode(
  autoZoom: false,        // Tắt auto zoom
  torchEnabled: false,    // Tắt torch khi không cần
  debounceMs: 1000,       // Debounce hợp lý
  messageUpdateInterval: 500, // Update interval hợp lý
)

// ❌ TRÁNH: Tốn tài nguyên
Cyberscanbarcode(
  autoZoom: true,         // Auto zoom tốn CPU
  torchEnabled: true,     // Torch tốn pin
  debounceMs: 100,        // Quá nhanh, xử lý nhiều
  messageUpdateInterval: 50, // Update quá nhanh
)
```

---

## 🐛 Xử Lý Lỗi & Troubleshooting

### Lỗi: Camera không bật

**Nguyên nhân:** Chưa có quyền camera

**Giải pháp:**
1. Kiểm tra khai báo quyền trong `AndroidManifest.xml` / `Info.plist`
2. App sẽ tự động request quyền lần đầu
3. Nếu user từ chối → Hướng dẫn vào Settings để cấp quyền

### Lỗi: Quét trùng lặp

**Nguyên nhân:** `debounceMs` quá nhỏ

**Giải pháp:** Tăng `debounceMs` lên 1000-2000ms

### Lỗi: Message không update

**Nguyên nhân:** 
- Dùng `message` thay vì `messageGetter`
- Quên `addListener()` cho CyberDataRow
- Quên `setState()` khi update state

**Giải pháp:**
```dart
// ✅ Đúng cách
messageGetter: () => dataRow["Field"]
dataRow.addListener(() => setState(() {}));
```

### Lỗi: App crash khi dispose

**Nguyên nhân:** Version cũ của `mobile_scanner`

**Giải pháp:** Update lên version mới nhất
```yaml
mobile_scanner: ^5.0.0 # hoặc mới hơn
```

### Lỗi: Performance chậm

**Nguyên nhân:** Bật `autoZoom` hoặc `torchEnabled`

**Giải pháp:** Tắt các tính năng không cần thiết

---

## 📊 So Sánh Các Chế Độ

| Chế độ | `continuousScan` | `clickScan` | Khi nào dùng |
|--------|------------------|-------------|--------------|
| **Auto Continuous** | `true` | `false` | Inventory, warehouse, quét nhiều |
| **Manual Control** | `true` | `true` | User cần kiểm soát, có thể pause |
| **One-shot** | `false` | `false` | Product lookup đơn giản |
| **One-shot + Click** | `false` | `true` | Check-in, quét vé từng người |

---

## 🎯 Tóm Tắt

### Các Bước Sử Dụng Cơ Bản

1. ✅ Add dependency `mobile_scanner`
2. ✅ Cấu hình quyền camera
3. ✅ Import widget
4. ✅ Thêm `Cyberscanbarcode` vào UI
5. ✅ Implement `onCapture` callback
6. ✅ (Optional) Thêm message với binding

### Template Cơ Bản

```dart
class MyScanPage extends StatefulWidget {
  @override
  _MyScanPageState createState() => _MyScanPageState();
}

class _MyScanPageState extends State<MyScanPage> {
  late CyberDataRow dataRow;

  @override
  void initState() {
    super.initState();
    
    dataRow = CyberDataRow();
    dataRow["Info"] = "Ready to scan";
    dataRow.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scanner')),
      body: Cyberscanbarcode(
        height: 400,
        continuousScan: true,
        clickScan: true,
        messageGetter: () => dataRow["Info"]?.toString() ?? "",
        messageIcon: Icons.qr_code_scanner,
        onCapture: (value) async {
          // Xử lý mã vừa quét
          dataRow["Info"] = "Scanned: $value";
        },
      ),
    );
  }
}
```

---

## 📚 Tài Liệu Tham Khảo

- [mobile_scanner package](https://pub.dev/packages/mobile_scanner)
- [CyberFramework Documentation](https://docs.cyberframework.com)

---

## 📝 Changelog

**Version 2.1.0** (2025)
- ✅ Thêm message runtime với static/dynamic binding
- ✅ Hỗ trợ CyberDataRow binding
- ✅ Thêm message positions (top/center/bottom)
- ✅ Thêm message icons và tùy chỉnh style
- ✅ Auto-update message với interval

**Version 2.0.0** (2025)
- ✅ Thêm click scan feature
- ✅ Thêm continuous/one-shot modes
- ✅ Thêm status display
- ✅ Tối ưu performance

**Version 1.0.0** (2025)
- ✅ Release đầu tiên

---

**Author:** Cyber Corporation  
**License:** Proprietary  
**Support:** support@cyberframework.com
