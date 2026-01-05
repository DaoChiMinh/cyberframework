# 🎴 CyberContentViewForm - Quick Reference Card

## 📌 TL;DR (Too Long; Didn't Read)

```dart
// 1. Tạo class extend CyberContentViewForm
class MyPopup extends CyberContentViewForm {
  @override
  Widget buildBody(BuildContext context) => Text('Hello');
}

// 2. Show popup
await MyPopup().showAsDialog(context);

// 3. Done! ✅
```

---

## 🔨 Basic Template

```dart
class MyContentView extends CyberContentViewForm {
  // 1. Constructor (optional - nếu có parameters)
  MyContentView({String? title}) 
    : super(cpName: "MyContentView", strParameter: title ?? "");
  
  // 2. Properties
  List<Product> products = [];
  
  // 3. Lifecycle
  @override
  Future<void> onLoadData() async {
    products = await API.getProducts();
  }
  
  @override
  void onDispose() {
    // Cleanup resources
  }
  
  // 4. Build UI (REQUIRED)
  @override
  Widget buildBody(BuildContext context) {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) => ListTile(
        title: Text(products[index].name),
        onTap: () => closePopup(context, products[index]),
      ),
    );
  }
}
```

---

## 🎯 Common Use Cases

### ✅ Show Popup

```dart
// Center dialog
await MyView().showAsDialog(context);

// Bottom sheet
await MyView().showBottom(context);

// Custom position
await MyView().showPopup(context, position: PopupPosition.center);
```

### ✅ With Parameters

```dart
class DetailView extends CyberContentViewForm {
  final String id;
  DetailView({required this.id}) : super(strParameter: id);
}

await DetailView(id: "123").showAsDialog(context);
```

### ✅ Get Return Value

```dart
final result = await MyView().showAsDialog<Product>(context);
if (result != null) {
  print('Selected: ${result.name}');
}

// Trong ContentView
closePopup(context, selectedProduct);
```

### ✅ Embed in Form

```dart
class MyForm extends CyberForm {
  @override
  Widget buildBody(BuildContext context) {
    return Column(
      children: [
        V_callView("myview") ?? Text("Not found"),
      ],
    );
  }
}
```

---

## 🔄 Lifecycle Methods

```dart
onInit()              // Setup (sync)
onBeforeLoad()        // Prepare (async)  
onLoadData()          // Load data (async)
onAfterLoad()         // Process (async)
onLoadError(e)        // Handle error (sync)
onDispose()           // Cleanup (sync) - ⚠️ IMPORTANT!
```

**Call order:** onInit → onBeforeLoad → onLoadData → onAfterLoad

---

## 🛠️ Helper Methods

```dart
// Rebuild UI
rebuild();

// Show/hide loading
showLoading('Processing...');
hideLoading();

// Close popup with result
closePopup(context, myResult);

// Access properties
print(cpName);        // Component name
print(strParameter);  // String parameter
print(objectData);    // Object data
print(hasContext);    // Context available?
```

---

## 🎨 Customization

### Custom Loading

```dart
@override
Widget? buildLoadingWidget() {
  return Center(
    child: CircularProgressIndicator(color: Colors.blue),
  );
}
```

### Custom Error

```dart
@override
Widget? buildErrorWidget(String error) {
  return Center(
    child: Text('Error: $error', style: TextStyle(color: Colors.red)),
  );
}
```

---

## 🎭 Show Methods Cheat Sheet

```dart
// showAsDialog - Center dialog với scale animation
await view.showAsDialog(context, width: 400, height: 300);

// showBottom - Bottom sheet với slide animation  
await view.showBottom(context);

// showPopup - Full customization
await view.showPopup(
  context,
  position: PopupPosition.center,
  animation: PopupAnimation.scale,
  width: 400,
  barrierDismissible: true,
);
```

---

## 🎯 Parameters

### Position

```dart
PopupPosition.center    // Giữa màn hình
PopupPosition.bottom    // Dưới cùng
PopupPosition.top       // Trên cùng
PopupPosition.left      // Bên trái
PopupPosition.right     // Bên phải
```

### Animation

```dart
PopupAnimation.scale           // Phóng to/thu nhỏ
PopupAnimation.slideAndFade    // Trượt + mờ
PopupAnimation.slide           // Chỉ trượt
PopupAnimation.fade            // Chỉ mờ
```

---

## ⚠️ Common Mistakes

### ❌ DON'T

```dart
// ❌ Forget to dispose
class MyView extends CyberContentViewForm {
  final ctrl = TextEditingController();
  // Forgot onDispose!
}

// ❌ Access context in constructor
class MyView extends CyberContentViewForm {
  MyView() {
    print(context); // ❌ Error!
  }
}

// ❌ No rebuild after state change
void updateData() {
  myData = newData; // ❌ UI won't update
}
```

### ✅ DO

```dart
// ✅ Always dispose
@override
void onDispose() {
  ctrl.dispose();
}

// ✅ Access context in lifecycle
@override
void onInit() {
  print(context); // ✅ OK
}

// ✅ Rebuild after state change
void updateData() {
  myData = newData;
  rebuild(); // ✅ UI updates
}
```

---

## 🚀 V_callView Functions

```dart
// Embed in widget tree
V_callView("myview", cpName: "CP01", strParameter: "abc")

// Show as popup
V_callViewPopup(context, "myview", cpName: "CP01")

// Show as bottom sheet
V_callViewBottom(context, "myview")

// Show as dialog
V_callViewDialog(context, "myview", width: 400)
```

---

## 📝 Registration (GetIt)

```dart
// In main.dart or setup file
void registerContentViews() {
  GetIt.I.registerFactory<CyberContentViewForm>(
    () => MyContentView(),
  );
  GetIt.I.registerFactory<CyberContentViewForm>(
    () => AnotherView(),
  );
  
  // Build factory map
  buildFactoryMap();
}
```

---

## 💡 Pro Tips

### 1. Use Named Parameters
```dart
class MyView extends CyberContentViewForm {
  final String id;
  final String mode;
  
  MyView({required this.id, this.mode = "view"});
}
```

### 2. Generic Return Types
```dart
final product = await ProductListView().showBottom<Product>(context);
final confirmed = await ConfirmView().showAsDialog<bool>(context);
```

### 3. Reusable Components
```dart
class ConfirmDialog extends CyberContentViewForm {
  final String title, message;
  ConfirmDialog(this.title, this.message);
  // ...
}

// Reuse everywhere
await ConfirmDialog("Delete?", "Sure?").showAsDialog(context);
```

### 4. Loading Pattern
```dart
Future<void> saveData() async {
  showLoading('Saving...');
  try {
    await API.save(data);
    hideLoading();
    closePopup(context, true);
  } catch (e) {
    hideLoading();
    // Show error
  }
}
```

---

## 🎯 When to Use?

### ✅ Use CyberContentViewForm For:
- Popups/Dialogs
- Bottom sheets
- Modal forms
- Confirmation dialogs
- Selection lists
- Detail views in popup
- Any reusable view component

### ❌ Don't Use For:
- Full screens (use CyberForm)
- Static widgets (use StatelessWidget)
- Simple widgets without state (use Container/Column)

---

## 🔍 Debugging

### Check Context
```dart
if (hasContext) {
  print('Context is available');
}
```

### Log Lifecycle
```dart
@override
void onInit() {
  debugPrint('[$runtimeType] onInit');
}

@override
Future<void> onLoadData() async {
  debugPrint('[$runtimeType] onLoadData');
}
```

### Catch Errors
```dart
@override
void onLoadError(dynamic error) {
  debugPrint('[$runtimeType] Error: $error');
  // Optional: Show snackbar
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: $error')),
  );
}
```

---

## 📊 Performance Tips

1. ✅ Dispose all controllers/subscriptions
2. ✅ Use const widgets where possible
3. ✅ Avoid heavy computations in build
4. ✅ Use ListView.builder for long lists
5. ✅ Cache data when appropriate

---

## 🎓 Learning Path

1. **Beginner:** Read MIGRATION_GUIDE.md
2. **Intermediate:** Study contentview_examples.dart
3. **Advanced:** Create complex custom views
4. **Expert:** Contribute improvements

---

## 📚 Related Docs

- `MIGRATION_GUIDE.md` - Detailed migration guide
- `contentview_examples.dart` - 6 real-world examples
- `IMPLEMENTATION_SUMMARY.md` - Full implementation details

---

## 🆘 Need Help?

1. Check this quick reference
2. Check examples file
3. Check migration guide
4. Ask team lead
5. Review CyberForm docs (similar pattern)

---

## ✅ Checklist

Before creating ContentView:
- [ ] Need popup/dialog? → Use CyberContentViewForm
- [ ] Need parameters? → Add constructor
- [ ] Need load data? → Use onLoadData
- [ ] Have resources? → Dispose in onDispose
- [ ] Need return value? → Use closePopup(context, result)

---

**Print this card and keep it handy!** 📄

**Last Updated:** 2024-01-05  
**Version:** 2.0.0
