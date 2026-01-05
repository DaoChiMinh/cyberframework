# Hướng Dẫn Sử Dụng CyberBox

## Giới Thiệu

`CyberBox` là một container widget linh hoạt trong CyberFramework, cho phép bạn tạo các layout phức tạp với nhiều widget con. Widget này kết hợp các tính năng của Container, Column và InkWell của Flutter vào một component duy nhất.

## Cài Đặt

```dart
import 'package:your_project/Controller/cyberbox.dart';
```

## Các Tính Năng Chính

### 1. Kích Thước (Width & Height)

CyberBox hỗ trợ 3 cách định nghĩa kích thước:

- **Giá trị cụ thể**: Số (double/int)
- **Fill parent**: Sử dụng `"*"` để chiếm toàn bộ không gian
- **Wrap content**: Sử dụng `null` để tự động điều chỉnh theo nội dung

```dart
// Ví dụ 1: Width cố định 200, height wrap content
CyberBox(
  width: 200,
  height: null,
  children: [Text('Hello')],
)

// Ví dụ 2: Width fill parent, height 100
CyberBox(
  width: '*',
  height: 100,
  children: [Text('Hello')],
)

// Ví dụ 3: Cả width và height đều wrap content
CyberBox(
  children: [Text('Hello')],
)
```

### 2. Màu Nền và Padding

```dart
CyberBox(
  backgroundColor: Colors.blue,
  padding: EdgeInsets.all(16),
  margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  children: [
    Text('Nội dung với padding'),
  ],
)
```

### 3. Border

#### Border Đơn Giản

```dart
CyberBox(
  border: CyberBoxBorder.createBorder(
    color: Colors.grey,
    width: 2.0,
  ),
  children: [Text('Box với border')],
)
```

#### Border Theo Từng Cạnh

```dart
CyberBox(
  border: CyberBoxBorder.createBorderSide(
    color: Colors.red,
    width: 2.0,
    top: true,
    bottom: true,
  ),
  children: [Text('Border trên và dưới')],
)
```

### 4. Bo Góc (Border Radius)

#### Cách 1: Sử dụng thuộc tính `radius` (bo đều 4 góc)

```dart
CyberBox(
  radius: 12,
  backgroundColor: Colors.blue,
  children: [Text('Bo góc 12px')],
)
```

#### Cách 2: Bo góc từng góc riêng biệt

```dart
CyberBox(
  topLeftRadius: 20,
  topRightRadius: 20,
  bottomLeftRadius: 0,
  bottomRightRadius: 0,
  backgroundColor: Colors.green,
  children: [Text('Bo góc trên')],
)
```

#### Cách 3: Sử dụng `borderRadius` với extensions

```dart
// Bo đều 4 góc
CyberBox(
  borderRadius: CyberBoxRadius.circular(16),
  children: [Text('Hello')],
)

// Chỉ bo góc trên
CyberBox(
  borderRadius: CyberBoxRadius.onlyTop(16),
  children: [Text('Hello')],
)

// Chỉ bo góc dưới
CyberBox(
  borderRadius: CyberBoxRadius.onlyBottom(16),
  children: [Text('Hello')],
)

// Bo góc tùy chỉnh
CyberBox(
  borderRadius: CyberBoxRadius.custom(
    topLeft: 20,
    topRight: 10,
    bottomLeft: 0,
    bottomRight: 15,
  ),
  children: [Text('Hello')],
)
```

### 5. Căn Chỉnh (Alignment)

CyberBox hỗ trợ căn chỉnh theo 2 chiều:
- `vAlign`: Căn chỉnh dọc (vertical)
- `hAlign`: Căn chỉnh ngang (horizontal)

Giá trị có thể: `CyberAlign.start`, `CyberAlign.center`, `CyberAlign.end`

```dart
// Căn giữa theo cả 2 chiều
CyberBox(
  width: '*',
  height: 200,
  vAlign: CyberAlign.center,
  hAlign: CyberAlign.center,
  children: [Text('Căn giữa')],
)

// Căn start-end
CyberBox(
  width: '*',
  height: 200,
  vAlign: CyberAlign.start,
  hAlign: CyberAlign.end,
  children: [Text('Góc phải trên')],
)
```

### 6. Nhiều Children với Spacing

```dart
CyberBox(
  spacing: 10, // Khoảng cách giữa các children
  children: [
    Text('Item 1'),
    Text('Item 2'),
    Text('Item 3'),
  ],
)
```

### 7. Xử Lý Click

#### Với Ripple Effect (Mặc Định)

```dart
CyberBox(
  onClick: () {
    print('Box được click!');
  },
  backgroundColor: Colors.blue,
  radius: 8,
  padding: EdgeInsets.all(16),
  children: [
    Text('Click me'),
  ],
)
```

#### Không Có Ripple Effect

```dart
CyberBox(
  onClick: () {
    print('Box được click!');
  },
  showRipple: false, // Tắt ripple effect
  backgroundColor: Colors.blue,
  children: [
    Text('Click me (no ripple)'),
  ],
)
```

### 8. Shadow (Đổ Bóng)

```dart
CyberBox(
  backgroundColor: Colors.white,
  radius: 12,
  shadows: [
    BoxShadow(
      color: Colors.grey.withOpacity(0.5),
      spreadRadius: 2,
      blurRadius: 5,
      offset: Offset(0, 3),
    ),
  ],
  children: [
    Text('Box với shadow'),
  ],
)
```

## Ví Dụ Thực Tế

### 1. Card Component

```dart
CyberBox(
  width: '*',
  backgroundColor: Colors.white,
  radius: 12,
  padding: EdgeInsets.all(16),
  margin: EdgeInsets.all(8),
  shadows: [
    BoxShadow(
      color: Colors.black12,
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ],
  children: [
    Text(
      'Tiêu đề',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
    SizedBox(height: 8),
    Text('Nội dung của card...'),
  ],
)
```

### 2. Button Component

```dart
CyberBox(
  onClick: () {
    print('Button clicked');
  },
  backgroundColor: Colors.blue,
  radius: 8,
  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  hAlign: CyberAlign.center,
  children: [
    Text(
      'Xác nhận',
      style: TextStyle(color: Colors.white, fontSize: 16),
    ),
  ],
)
```

### 3. List Item với Border

```dart
CyberBox(
  width: '*',
  padding: EdgeInsets.all(16),
  border: CyberBoxBorder.createBorderSide(
    color: Colors.grey.shade300,
    bottom: true,
  ),
  onClick: () {
    print('Item clicked');
  },
  children: [
    Text('Tên mục'),
    SizedBox(height: 4),
    Text(
      'Mô tả chi tiết',
      style: TextStyle(color: Colors.grey, fontSize: 12),
    ),
  ],
)
```

### 4. Form Container

```dart
CyberBox(
  width: '*',
  backgroundColor: Colors.grey.shade50,
  borderRadius: CyberBoxRadius.onlyTop(16),
  padding: EdgeInsets.all(20),
  spacing: 16,
  children: [
    Text(
      'Đăng nhập',
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    ),
    TextField(decoration: InputDecoration(labelText: 'Email')),
    TextField(
      decoration: InputDecoration(labelText: 'Mật khẩu'),
      obscureText: true,
    ),
    CyberBox(
      width: '*',
      onClick: () => print('Login'),
      backgroundColor: Colors.blue,
      radius: 8,
      padding: EdgeInsets.all(16),
      hAlign: CyberAlign.center,
      children: [
        Text('Đăng nhập', style: TextStyle(color: Colors.white)),
      ],
    ),
  ],
)
```

### 5. Header với Gradient (Kết hợp với Container)

```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [Colors.blue, Colors.purple],
    ),
  ),
  child: CyberBox(
    width: '*',
    padding: EdgeInsets.all(20),
    hAlign: CyberAlign.center,
    children: [
      Text(
        'Header',
        style: TextStyle(color: Colors.white, fontSize: 20),
      ),
    ],
  ),
)
```

### 6. Dialog/Modal Content

```dart
CyberBox(
  width: 300,
  backgroundColor: Colors.white,
  radius: 16,
  padding: EdgeInsets.all(24),
  spacing: 16,
  shadows: [
    BoxShadow(
      color: Colors.black26,
      blurRadius: 20,
      offset: Offset(0, 10),
    ),
  ],
  children: [
    Text(
      'Xác nhận',
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    ),
    Text('Bạn có chắc chắn muốn thực hiện hành động này?'),
    Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () {},
          child: Text('Hủy'),
        ),
        SizedBox(width: 8),
        CyberBox(
          onClick: () {},
          backgroundColor: Colors.blue,
          radius: 8,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            Text('Xác nhận', style: TextStyle(color: Colors.white)),
          ],
        ),
      ],
    ),
  ],
)
```

## Class Hỗ Trợ

### CyberSize

Sử dụng để parse kích thước một cách linh hoạt:

```dart
final size1 = CyberSize.fixed(100);      // Kích thước cố định
final size2 = CyberSize.fill();          // Fill parent
final size3 = CyberSize.wrap();          // Wrap content
final size4 = CyberSize.parse(200);      // Parse từ số
final size5 = CyberSize.parse('*');      // Parse từ string
```

### CyberAlign

Enum cho alignment:
- `CyberAlign.start` - Căn đầu
- `CyberAlign.center` - Căn giữa
- `CyberAlign.end` - Căn cuối

## Tips & Best Practices

### 1. Khi nào dùng `width: '*'` vs `width: null`?

- **`width: '*'`**: Khi muốn box chiếm toàn bộ chiều rộng có sẵn
- **`width: null`**: Khi muốn box tự điều chỉnh theo nội dung bên trong

### 2. Tối ưu Performance

- Tránh dùng quá nhiều shadow phức tạp
- Sử dụng `const` constructor khi có thể
- Nếu không cần ripple effect, set `showRipple: false`

### 3. Kết hợp với Các Widget Khác

CyberBox có thể chứa bất kỳ widget nào trong `children`:

```dart
CyberBox(
  children: [
    Image.network('url'),
    CyberText(text: 'Caption'),
    CyberButton(text: 'Action'),
  ],
)
```

### 4. Nested CyberBox

```dart
CyberBox(
  width: '*',
  children: [
    CyberBox(
      backgroundColor: Colors.blue,
      radius: 8,
      padding: EdgeInsets.all(8),
      children: [
        Text('Nested box'),
      ],
    ),
  ],
)
```

## Thuộc Tính Đầy Đủ

| Thuộc tính | Kiểu dữ liệu | Mặc định | Mô tả |
|-----------|-------------|----------|-------|
| `width` | `dynamic` | `null` | Chiều rộng (số, "*", null) |
| `height` | `dynamic` | `null` | Chiều cao (số, "*", null) |
| `backgroundColor` | `Color?` | `null` | Màu nền |
| `padding` | `EdgeInsets?` | `null` | Padding bên trong |
| `margin` | `EdgeInsets?` | `null` | Margin bên ngoài |
| `border` | `BoxBorder?` | `null` | Đường viền |
| `borderRadius` | `BorderRadius?` | `null` | Bo góc (ưu tiên) |
| `radius` | `double?` | `null` | Bo góc đều 4 góc |
| `topLeftRadius` | `double?` | `null` | Bo góc trên trái |
| `topRightRadius` | `double?` | `null` | Bo góc trên phải |
| `bottomLeftRadius` | `double?` | `null` | Bo góc dưới trái |
| `bottomRightRadius` | `double?` | `null` | Bo góc dưới phải |
| `children` | `List<Widget>` | `[]` | Danh sách widget con |
| `vAlign` | `CyberAlign` | `start` | Căn chỉnh dọc |
| `hAlign` | `CyberAlign` | `start` | Căn chỉnh ngang |
| `onClick` | `VoidCallback?` | `null` | Callback khi click |
| `spacing` | `double` | `0` | Khoảng cách giữa children |
| `showRipple` | `bool` | `true` | Hiển thị ripple effect |
| `shadows` | `List<BoxShadow>?` | `null` | Danh sách shadow |

## Lưu Ý Quan Trọng

1. **Thứ tự ưu tiên cho border radius**:
   - `borderRadius` (cao nhất)
   - `radius`
   - Các thuộc tính riêng lẻ (`topLeftRadius`, etc.)

2. **onClick với ripple**:
   - Khi `onClick != null` và `showRipple = true`: Sử dụng Material + InkWell
   - Khi `onClick != null` và `showRipple = false`: Sử dụng GestureDetector

3. **Layout**:
   - CyberBox luôn sử dụng Column cho children
   - Spacing chỉ áp dụng giữa các children, không có ở đầu hoặc cuối

## Kết Luận

CyberBox là một widget mạnh mẽ và linh hoạt giúp bạn tạo các layout nhanh chóng mà không cần phải lồng ghép nhiều widget Container, Column, Padding, InkWell... với nhau.

Để biết thêm thông tin về các widget khác trong CyberFramework, vui lòng tham khảo documentation của từng component.

---

**Version**: 1.0  
**Last Updated**: 2025  
**CyberFramework** - Simplifying Flutter Development
