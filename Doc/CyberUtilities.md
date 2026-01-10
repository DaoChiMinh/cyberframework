# CyberUtilities - Device & User Management

## Mục Lục
1. [Giới Thiệu](#giới-thiệu)
2. [CyberDeviceInfo](#cyberdeviceinfo)
3. [DeviceInfo](#deviceinfo)
4. [UserInfo](#userinfo)
5. [Ví Dụ Sử Dụng](#ví-dụ-sử-dụng)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

---

## Giới Thiệu

CyberUtilities cung cấp **device information** và **user session management** cho business applications. Bao gồm device detection, app version, user authentication, và session persistence.

### Đặc Điểm Chính

- ✅ **Device Detection**: Platform, model, OS version
- ✅ **App Information**: Version, build number, package name
- ✅ **Screen Info**: Size, orientation, category (mobile/tablet/desktop)
- ✅ **User Session**: Login, logout, token management
- ✅ **Persistent Storage**: Auto save/load from AppStorage
- ✅ **Cross-Platform**: Android, iOS, Web, Desktop
- ✅ **Singleton Pattern**: Single instance throughout app

### Import

```dart
import 'package:cyberframework/cyberframework.dart';
```

---

## CyberDeviceInfo

### Overview

**Singleton class** cung cấp thông tin thiết bị và app. Tự động detect platform và load device information.

### Initialization

```dart
// Initialize at app start
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize device info
  await CyberDeviceInfo().initialize();
  
  runApp(MyApp());
}
```

### App Information

```dart
// Access singleton instance
final deviceInfo = CyberDeviceInfo();

// App info
String appName = deviceInfo.appName;              // "MyApp"
String packageName = deviceInfo.packageName;      // "com.example.myapp"
String appVersion = deviceInfo.appVersion;        // "1.0.0"
String buildNumber = deviceInfo.buildNumber;      // "1"
String fullVersion = deviceInfo.fullVersion;      // "1.0.0+1"
```

### Platform Detection

```dart
final deviceInfo = CyberDeviceInfo();

// Platform name
String platform = deviceInfo.platform;  // "Android", "iOS", "Web", etc.

// Platform checks
bool isMobile = deviceInfo.isMobile;    // Android or iOS
bool isDesktop = deviceInfo.isDesktop;  // Windows, macOS, Linux
bool isWeb = deviceInfo.isWeb;          // Web platform
```

### Android Device Information

```dart
// Available on Android only
String version = deviceInfo.androidVersion;      // "13"
int sdk = deviceInfo.androidSdkVersion;         // 33
String manufacturer = deviceInfo.manufacturer;   // "Samsung"
String model = deviceInfo.model;                // "SM-G998B"
String brand = deviceInfo.brand;                // "samsung"
String deviceName = deviceInfo.deviceName;       // "samsung SM-G998B"
String deviceId = deviceInfo.deviceId;          // Unique ID
bool isPhysical = deviceInfo.isPhysicalDevice;  // true/false
```

### iOS Device Information

```dart
// Available on iOS only
String version = deviceInfo.iosVersion;         // "16.5"
String model = deviceInfo.iosModel;            // "iPhone14,2"
String name = deviceInfo.iosDeviceName;        // "iPhone 13 Pro"
String systemName = deviceInfo.iosSystemName;  // "iOS"
```

### Web Browser Information

```dart
// Available on Web only
String browser = deviceInfo.browserName;       // "Chrome"
String version = deviceInfo.browserVersion;    // "120.0.0"
String userAgent = deviceInfo.userAgent;       // Full user agent string
```

### Screen Information

⚠️ **Requires BuildContext**

```dart
// Screen size
Size screenSize = deviceInfo.getScreenSize(context);
double width = deviceInfo.getScreenWidth(context);
double height = deviceInfo.getScreenHeight(context);

// Pixel ratio
double ratio = deviceInfo.getPixelRatio(context);

// Orientation
Orientation orientation = deviceInfo.getOrientation(context);
bool isPortrait = deviceInfo.isPortrait(context);
bool isLandscape = deviceInfo.isLandscape(context);
```

### Device Category

```dart
// Get category based on screen width
DeviceCategory category = deviceInfo.getDeviceCategory(context);
// Returns: mobile (<600px), tablet (600-900px), desktop (>900px)

// Category checks
bool isMobile = deviceInfo.isMobileSize(context);   // width < 600
bool isTablet = deviceInfo.isTabletSize(context);   // 600 <= width < 900
bool isDesktop = deviceInfo.isDesktopSize(context); // width >= 900
```

### User-Friendly Display

```dart
// Friendly device name
String displayName = deviceInfo.displayDeviceName;
// Android: "Samsung Galaxy S Series"
// iOS: "iPhone 13 Pro"
// Web: "Chrome Browser"

// OS version string
String osVersion = deviceInfo.osVersion;
// "Android 13", "iOS 16.5", or browser name
```

### Device Info Export

```dart
// Get all info as Map
Map<String, dynamic> info = deviceInfo.getDeviceInfoMap();
// Contains all app, platform, and device information

// Get formatted string
String infoString = deviceInfo.getDeviceInfoString();

// Print to console
deviceInfo.printDeviceInfo();
```

---

## DeviceInfo

### Overview

**Static wrapper** around CyberDeviceInfo với persistent storage support. Provides quick access to common device properties.

### Properties

```dart
// Device info (from CyberDeviceInfo)
String displayName = DeviceInfo.displayDeviceName;  // User-friendly name
String deviceName = DeviceInfo.deviceName;          // Technical name
String deviceId = DeviceInfo.deviceId;              // Unique ID
String manufacturer = DeviceInfo.manufacturer;       // Brand
String appVersion = DeviceInfo.appVersion;          // App version
String platform = DeviceInfo.platform;              // Platform name
```

### Persistent Storage

```dart
// DNS configuration
String dns = await DeviceInfo.dnsName;
await DeviceInfo.setdnsName('api.example.com');

// Server name
String server = await DeviceInfo.servername;
await DeviceInfo.setservername('Production Server');

// Company name
String company = await DeviceInfo.tencty;
await DeviceInfo.settencty('ACME Corporation');

// Banner URL
String banner = await DeviceInfo.urlBanner;
await DeviceInfo.seturlBanner('https://example.com/banner.png');

// API Icon
String icon = await DeviceInfo.apicon;
await DeviceInfo.setapicon('https://example.com/icon.png');

// MAC address
String mac = await DeviceInfo.macdevice;
await DeviceInfo.setmacdevice('00:11:22:33:44:55');

// Device certificate (auto-generated UUID if not set)
String cert = await DeviceInfo.cetificate;
await DeviceInfo.setcetificate('uuid-v1-string');
```

---

## UserInfo

### Overview

**Static class** quản lý user session, authentication, và user data. Provides login/logout functionality với token management.

### Login

```dart
bool success = await UserInfo.V_Login(
  context,
  userName: 'john.doe',
  password: 'password123',
  maDvcs: 'HQ001',
  isShowMsg: true,
  isShowloading: true,
);

if (success) {
  print('Logged in!');
  print('User: ${UserInfo.user_name}');
  print('Company: ${UserInfo.ten_cty}');
}
```

### Login with OTP

```dart
// Step 1: Login (returns id_otp)
bool loginSuccess = await UserInfo.V_Login(context, ...);

if (UserInfo.LoginOTP) {
  // OTP required
  
  // Step 2: Verify OTP
  bool otpSuccess = await UserInfo.V_LoginOTP(
    context,
    Ma_otp: '123456',      // OTP code
    Ma_Dvcs: 'HQ001',
    User_Name: 'john.doe',
    isShowMsg: true,
  );
  
  if (otpSuccess) {
    print('OTP verified!');
  }
}
```

### User Properties

After successful login:

```dart
// User info
String userName = UserInfo.user_name;      // Username
String comment = UserInfo.comment;         // User comment/note
String chucvu = UserInfo.chucvu;          // Position/title
String dienthoai = UserInfo.dienthoai;    // Phone number

// Company info
String maDvcs = UserInfo.ma_dvcs;         // Company code
String tenCty = UserInfo.ten_cty;         // Company name

// Permissions
String isAdmin = UserInfo.isadmin;        // "1" or "0"
bool isTamTrang = UserInfo.istantrang;    // Special flag
bool isChangePass = UserInfo.ischangpass; // Must change password

// OTP info
String idOtp = UserInfo.id_otp;           // OTP ID
bool loginOTP = UserInfo.LoginOTP;        // Requires OTP
```

### Token Management

```dart
// Get token
String token = await UserInfo.strTokenId;

// Set token (usually done automatically by V_Login)
await UserInfo.setstrTokenId('your-token-here');
```

### Command & Module Data

After login, these tables are available:

```dart
CyberDataTable? commands = UserInfo.dtCommand;  // User commands
CyberDataTable? modules = UserInfo.dtPhanHe;    // User modules
```

### Logout

```dart
await UserInfo.logout();
// Clears: token, user_name, ma_dvcs, comment, otp data
```

---

## Ví Dụ Sử Dụng

### 1. App Initialization

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize device info
  await CyberDeviceInfo().initialize();
  
  // Load saved DNS
  String dns = await DeviceInfo.dnsName;
  if (dns.isEmpty) {
    await DeviceInfo.setdnsName('api.example.com');
  }
  
  runApp(MyApp());
}
```

### 2. Login Screen

```dart
class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final drLogin = CyberDataRow();
  
  @override
  void initState() {
    super.initState();
    drLogin['username'] = '';
    drLogin['password'] = '';
    drLogin['ma_dvcs'] = '';
  }
  
  Future<void> _login() async {
    final username = drLogin.getString('username');
    final password = drLogin.getString('password');
    final maDvcs = drLogin.getString('ma_dvcs');
    
    if (username.isEmpty || password.isEmpty) {
      'Please enter username and password'.V_MsgBox(context);
      return;
    }
    
    final success = await UserInfo.V_Login(
      context,
      userName: username,
      password: password,
      maDvcs: maDvcs,
    );
    
    if (success) {
      if (UserInfo.LoginOTP) {
        // Navigate to OTP screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => OTPScreen()),
        );
      } else {
        // Navigate to home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            CyberText(
              text: drLogin.bind('username'),
              label: 'Username',
            ),
            
            SizedBox(height: 16),
            
            CyberText(
              text: drLogin.bind('password'),
              label: 'Password',
              isPassword: true,
            ),
            
            SizedBox(height: 16),
            
            CyberText(
              text: drLogin.bind('ma_dvcs'),
              label: 'Company Code',
            ),
            
            SizedBox(height: 24),
            
            CyberButton(
              label: 'Login',
              onClick: _login,
            ),
          ],
        ),
      ),
    );
  }
}
```

### 3. OTP Verification Screen

```dart
class OTPScreen extends StatefulWidget {
  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final drOTP = CyberDataRow();
  
  @override
  void initState() {
    super.initState();
    drOTP['otp'] = '';
  }
  
  Future<void> _verifyOTP() async {
    final otp = drOTP.getString('otp');
    
    if (otp.isEmpty) {
      'Please enter OTP code'.V_MsgBox(context);
      return;
    }
    
    final success = await UserInfo.V_LoginOTP(
      context,
      Ma_otp: otp,
      Ma_Dvcs: UserInfo.ma_dvcs,
      User_Name: UserInfo.user_name,
    );
    
    if (success) {
      // Navigate to home
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
        (route) => false,
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('OTP Verification')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Enter OTP sent to your device',
              style: TextStyle(fontSize: 16),
            ),
            
            SizedBox(height: 24),
            
            CyberOTP(
              text: drOTP.bind('otp'),
              length: 6,
            ),
            
            SizedBox(height: 24),
            
            CyberButton(
              label: 'Verify',
              onClick: _verifyOTP,
            ),
          ],
        ),
      ),
    );
  }
}
```

### 4. Device Info Display

```dart
class DeviceInfoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final deviceInfo = CyberDeviceInfo();
    
    return Scaffold(
      appBar: AppBar(title: Text('Device Information')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildSection('App Information', [
            _buildRow('App Name', deviceInfo.appName),
            _buildRow('Version', deviceInfo.fullVersion),
            _buildRow('Package', deviceInfo.packageName),
          ]),
          
          Divider(height: 32),
          
          _buildSection('Device Information', [
            _buildRow('Device', deviceInfo.displayDeviceName),
            _buildRow('Platform', deviceInfo.platform),
            _buildRow('OS Version', deviceInfo.osVersion),
            _buildRow('Device ID', deviceInfo.deviceId),
            _buildRow('Physical Device', 
              deviceInfo.isPhysicalDevice.toString()),
          ]),
          
          Divider(height: 32),
          
          _buildSection('Screen Information', [
            _buildRow('Size', 
              '${deviceInfo.getScreenWidth(context).toInt()} × ${deviceInfo.getScreenHeight(context).toInt()}'),
            _buildRow('Category', 
              deviceInfo.getDeviceCategory(context).name),
            _buildRow('Orientation', 
              deviceInfo.isPortrait(context) ? 'Portrait' : 'Landscape'),
            _buildRow('Pixel Ratio', 
              deviceInfo.getPixelRatio(context).toStringAsFixed(2)),
          ]),
        ],
      ),
    );
  }
  
  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        ...children,
      ],
    );
  }
  
  Widget _buildRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
```

### 5. Responsive Layout

```dart
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget tablet;
  final Widget desktop;
  
  const ResponsiveLayout({
    required this.mobile,
    required this.tablet,
    required this.desktop,
  });
  
  @override
  Widget build(BuildContext context) {
    final deviceInfo = CyberDeviceInfo();
    
    if (deviceInfo.isMobileSize(context)) {
      return mobile;
    } else if (deviceInfo.isTabletSize(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }
}

// Usage
ResponsiveLayout(
  mobile: MobileLayout(),
  tablet: TabletLayout(),
  desktop: DesktopLayout(),
)
```

### 6. User Profile Screen

```dart
class UserProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // User info
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Username'),
            subtitle: Text(UserInfo.user_name),
          ),
          
          ListTile(
            leading: Icon(Icons.business),
            title: Text('Company'),
            subtitle: Text(UserInfo.ten_cty),
          ),
          
          ListTile(
            leading: Icon(Icons.work),
            title: Text('Position'),
            subtitle: Text(UserInfo.chucvu),
          ),
          
          ListTile(
            leading: Icon(Icons.phone),
            title: Text('Phone'),
            subtitle: Text(UserInfo.dienthoai),
          ),
          
          ListTile(
            leading: Icon(Icons.location_city),
            title: Text('Branch'),
            subtitle: Text(UserInfo.ma_dvcs),
          ),
          
          Divider(),
          
          // Logout button
          CyberButton(
            label: 'Logout',
            onClick: () async {
              await UserInfo.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
```

### 7. Platform-Specific Code

```dart
class PlatformSpecificWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final deviceInfo = CyberDeviceInfo();
    
    if (deviceInfo.platform == 'Android') {
      return AndroidWidget();
    } else if (deviceInfo.platform == 'iOS') {
      return IOSWidget();
    } else if (deviceInfo.platform == 'Web') {
      return WebWidget();
    } else {
      return DesktopWidget();
    }
  }
}
```

### 8. Session Persistence

```dart
class SessionManager {
  static Future<bool> hasActiveSession() async {
    final token = await UserInfo.strTokenId;
    return token.isNotEmpty;
  }
  
  static Future<void> checkSession(BuildContext context) async {
    final hasSession = await hasActiveSession();
    
    if (hasSession) {
      // Has token, navigate to home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      // No token, navigate to login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }
}

// In main.dart
class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }
  
  Future<void> _init() async {
    // Initialize device info
    await CyberDeviceInfo().initialize();
    
    // Wait a bit for splash
    await Future.delayed(Duration(seconds: 2));
    
    // Check session
    await SessionManager.checkSession(context);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
```

---

## Best Practices

### 1. Initialize Early

```dart
// ✅ GOOD: Initialize in main()
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CyberDeviceInfo().initialize();
  runApp(MyApp());
}

// ❌ BAD: Initialize later
// Device info may not be ready
```

### 2. Check Login State

```dart
// ✅ GOOD: Check before accessing user data
if (await SessionManager.hasActiveSession()) {
  print(UserInfo.user_name);
}

// ❌ BAD: Assume logged in
print(UserInfo.user_name);  // May be empty
```

### 3. Use Display Names

```dart
// ✅ GOOD: User-friendly
String name = CyberDeviceInfo().displayDeviceName;  // "iPhone 13 Pro"

// ⚠️ OK: Technical name
String name = CyberDeviceInfo().deviceName;  // "iPhone14,2"
```

### 4. Handle OTP Flow

```dart
// ✅ GOOD: Check LoginOTP flag
if (UserInfo.LoginOTP) {
  // Show OTP screen
} else {
  // Go to home
}

// ❌ BAD: Always show OTP
// Some accounts don't require OTP
```

### 5. Logout Properly

```dart
// ✅ GOOD: Clear session
await UserInfo.logout();
Navigator.pushAndRemoveUntil(...);

// ❌ BAD: Just navigate
Navigator.pushAndRemoveUntil(...);  // Token still saved
```

---

## Troubleshooting

### Device info not available

**Nguyên nhân:** Not initialized

**Giải pháp:**
```dart
// ✅ CORRECT: Initialize first
await CyberDeviceInfo().initialize();
```

### Login fails silently

**Nguyên nhân:** Missing DNS configuration

**Giải pháp:**
```dart
// ✅ CORRECT: Set DNS first
await DeviceInfo.setdnsName('api.example.com');
await UserInfo.V_Login(...);
```

### Token not persisted

**Nguyên nhân:** Auto-saved by V_Login

**Giải pháp:**
```dart
// Token is automatically saved
// Just call V_Login, no manual save needed
```

### OTP not working

**Nguyên nhân:** Missing id_otp

**Giải pháp:**
```dart
// ✅ CORRECT: V_Login sets id_otp
await UserInfo.V_Login(...);

// Then use in OTP
await UserInfo.V_LoginOTP(
  Ma_otp: code,
  // id_otp is already set
);
```

### Screen size returns 0

**Nguyên nhân:** Called before build

**Giải pháp:**
```dart
// ✅ CORRECT: Call in build() or after
@override
Widget build(BuildContext context) {
  final width = CyberDeviceInfo().getScreenWidth(context);
}

// ❌ WRONG: Call in initState()
@override
void initState() {
  final width = CyberDeviceInfo().getScreenWidth(context);  // 0!
}
```

---

## Tips & Tricks

### 1. Certificate Auto-Generation

```dart
// First time: generates UUID
String cert = await DeviceInfo.cetificate;

// Subsequent calls: returns same UUID
// Saved in AppStorage
```

### 2. Responsive Breakpoints

```dart
// Mobile: < 600px
// Tablet: 600-900px
// Desktop: > 900px

if (CyberDeviceInfo().isMobileSize(context)) {
  // Mobile layout
}
```

### 3. Platform Detection

```dart
// Quick check
if (CyberDeviceInfo().isMobile) {
  // Android or iOS
}

// Specific platform
if (CyberDeviceInfo().platform == 'Android') {
  // Android only
}
```

### 4. User Permissions

```dart
// Check admin
if (UserInfo.isadmin == "1") {
  // Show admin features
}
```

### 5. Device Category Widget

```dart
Widget build(BuildContext context) {
  return CyberDeviceInfo().getDeviceCategory(context) == DeviceCategory.mobile
      ? MobileView()
      : DesktopView();
}
```

---

## Common Patterns

### Login Flow

```dart
1. User enters credentials
2. Call V_Login()
3. Check LoginOTP flag
4. If OTP: Show OTP screen → V_LoginOTP()
5. If no OTP: Navigate to home
6. Token auto-saved
```

### App Startup

```dart
1. Initialize CyberDeviceInfo
2. Load DeviceInfo settings (DNS, etc.)
3. Check UserInfo.strTokenId
4. If token exists: Validate & go to home
5. If no token: Show login
```

### Responsive Design

```dart
1. Get device category
2. Choose layout based on size
3. Adjust padding, font sizes
4. Show/hide features per device
```

---

## Version History

### 1.0.0
- CyberDeviceInfo singleton
- DeviceInfo static wrapper
- UserInfo authentication
- Platform detection
- Screen information
- Persistent storage
- OTP support
- Session management

---

## License

MIT License - CyberFramework
