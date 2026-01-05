# CyberFramework

Framework Flutter mạnh mẽ cho phát triển ứng dụng di động với kiến trúc MVVM và dependency injection.

## 📋 Mục lục

- [Giới thiệu](#giới-thiệu)
- [Tính năng](#tính-năng)
- [Cài đặt](#cài-đặt)
- [Hướng dẫn sử dụng](#hướng-dẫn-sử-dụng)
- [Ví dụ](#ví-dụ)
- [Đóng góp](#đóng-góp)
- [Liên kết](#liên-kết)

## 🎯 Giới thiệu

CyberFramework là một Flutter plugin framework cung cấp các công cụ và components để xây dựng ứng dụng mobile theo mô hình MVVM với dependency injection, giúp code dễ bảo trì và mở rộng.

## ✨ Tính năng

- ✅ MVVM Architecture Pattern
- ✅ Form Management với CyberForm
- ✅ Navigation Management
- ✅ Custom UI Controls (CyberText, CyberCheckbox, CyberComboBox, v.v.)
- ✅ Two-way Data Binding
- ✅ Lifecycle Management

## 📦 Cài đặt

Thêm dependency vào file `pubspec.yaml`:

```yaml
dependencies:
  cyberframework:
    git:
      url: https://github.com/DaoChiMinh/cyberframework.git
  injectable: ^2.7.1+2
  get_it: ^9.2.0

dev_dependencies:
  injectable_generator: ^2.11.1
  build_runner: ^2.10.4
```

Chạy lệnh:

```bash
flutter pub get
```

## 🚀 Hướng dẫn sử dụng

### Bước 1: Tạo file cấu hình Dependency Injection

Tạo file `spScreen.dart` tại thư mục root của project:

```dart
import 'package:cyberframework/cyberframework.dart';
import 'package:get_it/get_it.dart';
import 'spScreen.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
void configureDependencies() {
  getIt.init();
  buildFactoryMap();
}
```

### Bước 2: Generate code

Chạy lệnh build_runner để generate code:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

nếu bạn đang sử dụng VsCode hãy tạo thư mục .vscode trong project của bạn

- tạo file launch.json

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Cyber Flutter",
      "type": "dart",
      "request": "launch",
      "program": "lib/main.dart",
      "preLaunchTask": "build_runner_watch"
    },
    {
      "name": "Flutter",
      "type": "dart",
      "request": "launch",
      "program": "lib/main.dart"
    }
  ]
}
```

- tạo file tasks.json

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "build_runner_watch",
      "type": "shell",
      "command": "dart",
      "args": ["run", "build_runner", "watch", "--delete-conflicting-outputs"],
      "isBackground": true,
      "problemMatcher": [],
      "presentation": {
        "reveal": "always",
        "panel": "dedicated",
        "showReuseMessage": false,
        "clear": false
      }
    }
  ]
}
```

sau đó vào Run and debug chạy

### Bước 3: Khởi tạo trong main.dart

```dart
import 'spScreen.dart';
import 'package:cyberframework/cyberframework.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return V_MainScreen("MyHomePage");
  }
}

@Singleton(as: CyberForm)
@named
class MyHomePage extends CyberForm {
  @override
  Widget buildBody(BuildContext context) {
    return Center(child: Text("Hello World", style: TextStyle(fontSize: 24)));
  }
}
```

## 📱 Ví dụ

### Tạo một CyberForm cơ bản

```dart
import 'spScreen.dart';
import 'package:cyberframework/cyberframework.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return V_Root("FnLogin");
  }
}

@Singleton(as: CyberForm)
@named
class FnLogin extends CyberForm {
  CyberDataTable? dt;
  CyberDataRow? dr;
  @override
  Future<void> onLoadData() {
    dt = CyberDataTable(tableName: "tableName");
    dt!.loadData([
      {"password": "", "username": ""},
    ]);
    dr = dt![0];
    return super.onLoadData();
  }

  @override
  Widget buildBody(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.all(32),
      child: Column(
        children: [
          CyberText(
            label: "Tài khoản",
            hint: "tài khoản",
            text: dr!.bind("username"),
          ),
          CyberText(
            label: "xin chào",
            hint: "mật khẩu",
            text: dr!.bind('minhdc'),
            isPassword: true,
          ),
          ElevatedButton(
            onPressed: () => V_MainScreen(context, "FrmMain"),// FrmMain chuyển tới màn hình chính
            child: const Text("Đăng nhập"),
          ),
        ],
      ),
    );
  }
}

@Singleton(as: CyberForm)
@named
class FrmMain extends CyberForm {
  @override
  Widget buildBody(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () => V_Call("Hom01", "Đây là màn hình 01", "", ""),//  chuyển tới màn hình con
        child: const Text("Đăng xuất"),
      ),
    );
  }
}

@Singleton(as: CyberForm)
@named
class Hom01 extends CyberForm {
  @override
  Widget buildBody(BuildContext context) {
    return Center(
      child:Text("Hello"),
    );
  }
}

```

### Navigation giữa các màn hình

```dart
// Mở màn hình mới sự kiện tại Button
 ElevatedButton(
    onPressed: () => V_Call("Hom01", "Đây là màn hình 01", "", ""),
    child: const Text("Go to Home 01"),
),
```

## 🛠️ Công nghệ sử dụng

- Flutter
- MVVM Pattern

## 🤝 Đóng góp

Mọi đóng góp đều được chào đón! Vui lòng:

1. Fork repository
2. Tạo branch mới (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add some amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Tạo Pull Request

## 📞 Liên kết

- **Homepage**: [https://github.com/DaoChiMinh/cyberframework](https://github.com/DaoChiMinh/cyberframework)
- **Repository**: [https://github.com/DaoChiMinh/cyberframework](https://github.com/DaoChiMinh/cyberframework)
- **Issue Tracker**: [https://github.com/DaoChiMinh/cyberframework/issues](https://github.com/DaoChiMinh/cyberframework/issues)

## 📄 License

Dự án này được phân phối dưới giấy phép MIT. Xem file `LICENSE` để biết thêm chi tiết.
[Sponsor 💖](https://github.com/sponsors/DaoChiMinh)

---

**Phát triển bởi CyberSoft** 🇻🇳
