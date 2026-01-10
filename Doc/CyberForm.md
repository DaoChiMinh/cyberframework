# CyberForm & CyberBaseEdit - Base Form Classes

## Mục Lục
1. [Giới Thiệu](#giới-thiệu)
2. [CyberForm Base Class](#cyberform-base-class)
3. [CyberBaseEdit Class](#cyberbaseedit-class)
4. [Ví Dụ Sử Dụng](#ví-dụ-sử-dụng)
5. [Animation System](#animation-system)
6. [Best Practices](#best-practices)
7. [Troubleshooting](#troubleshooting)

---

## Giới Thiệu

`CyberForm` và `CyberBaseEdit` là **base classes** cho tất cả forms trong CyberFramework. Chúng cung cấp **lifecycle management**, **animation system**, **resource cleanup**, và **common utilities**.

### Đặc Điểm Chính

- ✅ **Lifecycle Management**: onInit, onLoad, onDispose
- ✅ **Animation System**: Implicit & Explicit animations
- ✅ **Resource Management**: Auto cleanup controllers, listeners
- ✅ **Loading States**: Built-in loading/error handling
- ✅ **Navigation**: Built-in navigation helpers
- ✅ **Tab Support**: CyberBaseEdit với tabs
- ✅ **Save Pattern**: Standard save workflow

### Import

```dart
import 'package:cyberframework/cyberframework.dart';
```

---

## CyberForm Base Class

### Overview

Abstract base class cho tất cả forms. Cung cấp foundation cho form lifecycle, animations, và resource management.

### Lifecycle Methods

```dart
abstract class CyberForm {
  // Called first - Initialize variables
  void onInit() {}
  
  // Called before loading data
  Future<void> onBeforeLoad() async {}
  
  // Main data loading
  Future<void> onLoadData() async {}
  
  // Called after successful load
  Future<void> onAfterLoad() async {}
  
  // Called if loading fails
  void onLoadError(dynamic error) {}
  
  // Called when form is disposed
  void onDispose() {}
}
```

### Properties

#### Form Configuration

```dart
// Title
String? title;

// Background color
Color? backgroundColor;

// Hide app bar
bool? hideAppBar;

// Show speed monitor
bool? showSpeedMonitor;

// Hide bottom navigation
bool? hideBottomNavigationBar;
```

#### Default Colors

```dart
Color? textColorDefault = Color(0xFF00D287);
Color? TextColorBlue = Color(0xFF145A4A);
Color? TextColorOrange = Color(0xFFFF6B35);
Color? TextColorGray = Color.fromARGB(255, 224, 224, 224);
```

### Build Methods

```dart
// Main body - REQUIRED
Widget buildBody(BuildContext context);

// Optional loading widget
Widget? buildLoadingWidget() => null;

// Optional error widget
Widget? buildErrorWidget(String error) => null;

// Optional bottom navigation
Widget? buildBottomNavigationBar(BuildContext context) => null;
```

### Helper Methods

```dart
// Navigate to another screen
void V_Call(String strfrm, {
  bool hideAppBar = false,
  String title = "",
  String cpName = "",
  String strparameter = "",
  dynamic objectdata,
});

// Rebuild UI
void rebuild();

// Show loading dialog
void showLoading([String? message]);

// Hide loading dialog
void hideLoading();

// Close form
void close({dynamic result});
```

---

## CyberBaseEdit Class

### Overview

Extends CyberForm với **tab support** và **save functionality**. Perfect cho edit forms với multiple sections.

### Properties

```dart
abstract class CyberBaseEdit extends CyberForm {
  // Required: List of tabs
  List<CyberTab> get tabs;
  
  // Initial tab index
  int get initialTabIndex => 0;
  
  // Mode (M/A/E)
  String mode = "M";
  
  // Save button label
  String get saveButtonLabel => setText("Lưu dữ liệu", "Save data");
  
  // Show save button
  bool get showSaveButton => true;
  
  // Save button padding
  EdgeInsets get saveButtonPadding => 
      EdgeInsets.symmetric(vertical: 24, horizontal: 16);
}
```

### Methods

```dart
// Called when tab changes
void onTabChanged(int index) {}

// Save data - Override this
Future<void> SaveData() async {}

// Generate XML from DataTables
String getXML(List<CyberDataTable> dts, List<String> names);

// Build and save XML to server
Future<bool> buildSaveXml({
  String Cp_Name = "",
  String StrParameter = "",
});
```

---

## Ví Dụ Sử Dụng

### 1. Simple Form

Basic form implementation.

```dart
class MySimpleForm extends CyberForm {
  final drData = CyberDataRow();

  @override
  void onInit() {
    super.onInit();
    
    // Initialize data
    drData['name'] = '';
    drData['email'] = '';
  }

  @override
  Future<void> onLoadData() async {
    // Load data from API
    final result = await context.callApi(
      functionName: 'GetUserData',
      parameter: '',
    );
    
    if (result.isValid()) {
      final ds = result.toCyberDataset();
      if (ds != null && ds.tables.isNotEmpty) {
        drData.copyFrom(ds.tables[0].rows[0]);
      }
    }
  }

  @override
  Widget buildBody(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          CyberText(
            text: drData.bind('name'),
            label: 'Name',
          ),
          
          SizedBox(height: 16),
          
          CyberText(
            text: drData.bind('email'),
            label: 'Email',
          ),
          
          SizedBox(height: 24),
          
          CyberButton(
            label: 'Save',
            onClick: _save,
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    showLoading('Saving...');
    
    try {
      // Save logic here
      await Future.delayed(Duration(seconds: 1));
      
      hideLoading();
      'Saved successfully!'.V_MsgBox();
      close();
    } catch (e) {
      hideLoading();
      'Error: $e'.V_MsgBox();
    }
  }
}
```

### 2. Edit Form with Tabs

Using CyberBaseEdit for tabbed forms.

```dart
class UserEditForm extends CyberBaseEdit {
  final drUser = CyberDataRow();
  final drAddress = CyberDataRow();
  
  @override
  List<CyberTab> get tabs => [
    CyberTab(
      label: 'General',
      icon: Icons.person,
      child: _buildGeneralTab(),
    ),
    CyberTab(
      label: 'Address',
      icon: Icons.home,
      child: _buildAddressTab(),
    ),
    CyberTab(
      label: 'Settings',
      icon: Icons.settings,
      child: _buildSettingsTab(),
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    
    title = 'Edit User';
    
    drUser['name'] = '';
    drUser['email'] = '';
    drAddress['street'] = '';
    drAddress['city'] = '';
  }

  @override
  Future<void> onLoadData() async {
    final userId = objectdata as String;
    
    final result = await context.callApi(
      functionName: 'GetUserDetail',
      parameter: 'userId=$userId',
    );
    
    if (result.isValid()) {
      final ds = result.toCyberDataset();
      if (ds != null && ds.tables.length >= 2) {
        drUser.copyFrom(ds.tables[0].rows[0]);
        drAddress.copyFrom(ds.tables[1].rows[0]);
      }
    }
  }

  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          CyberText(
            text: drUser.bind('name'),
            label: 'Full Name',
            isCheckEmpty: true,
          ),
          
          SizedBox(height: 16),
          
          CyberText(
            text: drUser.bind('email'),
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          CyberText(
            text: drAddress.bind('street'),
            label: 'Street',
          ),
          
          SizedBox(height: 16),
          
          CyberText(
            text: drAddress.bind('city'),
            label: 'City',
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab() {
    return Center(child: Text('Settings'));
  }

  @override
  void onTabChanged(int index) {
    print('Tab changed to: $index');
  }

  @override
  Future<void> SaveData() async {
    // Validate
    if (drUser['name'].toString().isEmpty) {
      'Name is required'.V_MsgBox();
      return;
    }
    
    showLoading('Saving...');
    
    try {
      // Prepare XML
      final xml = getXML(
        [dtUser, dtAddress],
        ['User', 'Address'],
      );
      
      // Call API
      final success = await buildSaveXml(
        Cp_Name: 'SaveUserData',
        StrParameter: xml,
      );
      
      hideLoading();
      
      if (success) {
        'Saved successfully!'.V_MsgBox();
        close();
      }
    } catch (e) {
      hideLoading();
      'Error saving: $e'.V_MsgBox();
    }
  }
}
```

### 3. Form with Loading State

Custom loading and error widgets.

```dart
class CustomLoadingForm extends CyberForm {
  @override
  Widget? buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading user data...'),
          SizedBox(height: 8),
          Text(
            'Please wait',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  @override
  Widget? buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text('Failed to load data'),
          SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          CyberButton(
            label: 'Retry',
            onClick: () {
              rebuild();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return Center(child: Text('Data loaded!'));
  }
}
```

### 4. Form with Custom AppBar

Hide default AppBar and build custom.

```dart
class CustomAppBarForm extends CyberForm {
  @override
  void onInit() {
    super.onInit();
    hideAppBar = true;
  }

  @override
  Widget buildBody(BuildContext context) {
    return Column(
      children: [
        // Custom AppBar
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.blue,
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => close(),
                ),
                Expanded(
                  child: Text(
                    'Custom AppBar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.save, color: Colors.white),
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
        
        // Body
        Expanded(
          child: Center(child: Text('Content')),
        ),
      ],
    );
  }

  void _save() {
    // Save logic
  }
}
```

### 5. Form with Navigation

Navigate between forms.

```dart
class MasterForm extends CyberForm {
  @override
  Widget buildBody(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CyberButton(
            label: 'Open Detail Form',
            onClick: () {
              V_Call(
                'DetailForm',
                title: 'Detail',
                cpName: 'DetailCP',
                strparameter: 'id=123',
              );
            },
          ),
          
          SizedBox(height: 16),
          
          CyberButton(
            label: 'Open Settings',
            onClick: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
```

---

## Animation System

### Implicit Animations (Recommended)

**Best performance** - No controllers needed.

```dart
class AnimatedForm extends CyberForm {
  bool _showContent = false;

  @override
  void onAfterLoad() {
    super.onAfterLoad();
    
    // Show content with animation
    Future.delayed(Duration(milliseconds: 100), () {
      _showContent = true;
      rebuild();
    });
  }

  @override
  Widget buildBody(BuildContext context) {
    return Column(
      children: [
        // Fade in
        fadeTransition(
          show: _showContent,
          child: Text('Hello'),
        ),
        
        // Slide and fade
        slideAndFade(
          show: _showContent,
          child: CyberButton(label: 'Click me'),
        ),
        
        // Animated container
        animatedBox(
          color: _showContent ? Colors.blue : Colors.grey,
          padding: EdgeInsets.all(_showContent ? 20 : 10),
          child: Text('Animated Box'),
        ),
      ],
    );
  }
}
```

### Explicit Animations (Advanced)

**Full control** - For complex animations.

```dart
class ExplicitAnimatedForm extends CyberForm {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void onInit() {
    super.onInit();
    
    // Create controller
    _controller = getController(
      'fade',
      duration: Duration(milliseconds: 500),
    );
    
    // Create animation
    _fadeAnimation = createFadeAnimation('fade');
  }

  @override
  void onAfterLoad() {
    super.onAfterLoad();
    
    // Start animation
    _controller.forward();
  }

  @override
  Widget buildBody(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(child: Text('Faded In')),
    );
  }
}
```

### Staggered Animations

```dart
class StaggeredForm extends CyberForm {
  @override
  void onAfterLoad() {
    super.onAfterLoad();
    
    // Animate elements in sequence
    playControllerSequence(
      ['header', 'content', 'footer'],
      delay: Duration(milliseconds: 150),
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return Column(
      children: [
        FadeTransition(
          opacity: createFadeAnimation('header'),
          child: Text('Header'),
        ),
        
        FadeTransition(
          opacity: createFadeAnimation('content'),
          child: Text('Content'),
        ),
        
        FadeTransition(
          opacity: createFadeAnimation('footer'),
          child: Text('Footer'),
        ),
      ],
    );
  }
}
```

---

## Best Practices

### 1. Always Call super

```dart
// ✅ GOOD
@override
void onInit() {
  super.onInit();
  // Your code
}

// ❌ BAD
@override
void onInit() {
  // Missing super.onInit()
}
```

### 2. Initialize Data in onInit

```dart
// ✅ GOOD
@override
void onInit() {
  super.onInit();
  
  drUser['name'] = '';
  drUser['email'] = '';
}

// ❌ BAD: Late initialization
@override
Widget buildBody(BuildContext context) {
  drUser['name'] = '';  // Too late!
}
```

### 3. Use onLoadData for API Calls

```dart
// ✅ GOOD
@override
Future<void> onLoadData() async {
  final result = await context.callApi(...);
  // Process result
}

// ❌ BAD: In onInit
@override
void onInit() {
  context.callApi(...);  // Sync method!
}
```

### 4. Clean Loading States

```dart
// ✅ GOOD
showLoading('Saving...');
try {
  await save();
  hideLoading();
} catch (e) {
  hideLoading();  // Always hide
  showError(e);
}

// ❌ BAD: Missing hideLoading
showLoading();
await save();
// Loading never hidden!
```

### 5. Use Implicit Animations

```dart
// ✅ GOOD: No controller needed
fadeTransition(
  show: _visible,
  child: MyWidget(),
)

// ❌ BAD: Unnecessary controller
final controller = getController('fade');
FadeTransition(...)
```

---

## Troubleshooting

### onLoadData không được gọi

**Nguyên nhân:** Error trong onBeforeLoad

**Giải pháp:**
```dart
// ✅ CORRECT: Handle errors
@override
Future<void> onBeforeLoad() async {
  try {
    await validateSomething();
  } catch (e) {
    print('Validation error: $e');
    // Don't rethrow if you want onLoadData to run
  }
}
```

### Animation không hoạt động

**Nguyên nhân:** Controller không tạo được

**Giải pháp:**
```dart
// ✅ CORRECT: Check canAnimate
if (canAnimate) {
  final controller = getController('myAnimation');
  controller.forward();
}
```

### Memory leak

**Nguyên nhân:** Không dispose resources

**Giải pháp:**
```dart
// ✅ CORRECT: Use registerDisposable
@override
void onInit() {
  super.onInit();
  
  final controller = TextEditingController();
  registerDisposable(controller);  // Auto cleanup
}
```

### Tabs không hiển thị

**Nguyên nhân:** Empty tabs list

**Giải pháp:**
```dart
// ✅ CORRECT: Return non-empty list
@override
List<CyberTab> get tabs => [
  CyberTab(label: 'Tab 1', child: Widget1()),
  CyberTab(label: 'Tab 2', child: Widget2()),
];

// ❌ WRONG: Empty list
@override
List<CyberTab> get tabs => [];
```

### SaveData không chạy

**Nguyên nhân:** Chưa override

**Giải pháp:**
```dart
// ✅ CORRECT: Override SaveData
@override
Future<void> SaveData() async {
  // Your save logic
  await saveTo API();
}
```

---

## Tips & Tricks

### 1. Lifecycle Order

```dart
// Execution order:
// 1. onInit()
// 2. onBeforeLoad()
// 3. onLoadData()
// 4. onAfterLoad()
// ... user interaction ...
// 5. onDispose()
```

### 2. Check If Disposed

```dart
if (!isDisposed) {
  rebuild();
}
```

### 3. Register Multiple Resources

```dart
@override
void onInit() {
  super.onInit();
  
  final controller1 = TextEditingController();
  final controller2 = ScrollController();
  final focusNode = FocusNode();
  
  registerDisposable(controller1);
  registerDisposable(controller2);
  registerDisposable(focusNode);
  // All auto-disposed
}
```

### 4. Animation Performance Metrics

```dart
@override
void onAfterLoad() {
  super.onAfterLoad();
  
  // Log animation metrics
  logAnimationMetrics();
}
```

### 5. Conditional Save Button

```dart
@override
bool get showSaveButton => mode == 'E';  // Only in edit mode
```

---

## Common Patterns

### Master-Detail Pattern

```dart
class MasterForm extends CyberForm {
  final dtList = CyberDataTable();

  void openDetail(String id) {
    V_Call(
      'DetailForm',
      title: 'Detail',
      objectdata: id,
    );
  }
}

class DetailForm extends CyberBaseEdit {
  @override
  void onInit() {
    super.onInit();
    
    final id = objectdata as String;
    // Load detail
  }
}
```

### Multi-Step Form

```dart
class MultiStepForm extends CyberBaseEdit {
  int _currentStep = 0;

  @override
  List<CyberTab> get tabs => [
    CyberTab(label: 'Step 1', child: Step1()),
    CyberTab(label: 'Step 2', child: Step2()),
    CyberTab(label: 'Step 3', child: Step3()),
  ];

  @override
  void onTabChanged(int index) {
    _currentStep = index;
  }

  @override
  String get saveButtonLabel =>
      _currentStep < 2 ? 'Next' : 'Finish';
}
```

---

## Version History

### 1.0.0
- Initial release
- CyberForm base class
- CyberBaseEdit with tabs
- Lifecycle management
- Animation system
- Resource management
- Loading states
- Navigation helpers

---

## License

MIT License - CyberFramework
