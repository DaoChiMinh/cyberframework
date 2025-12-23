import 'package:cyberframework/cyberframework.dart';

// ignore: non_constant_identifier_names
MaterialApp V_Root(
  String strfrm, {
  String title = "",
  // ignore: non_constant_identifier_names
  String cp_name = "",
  String strparameter = "",
  // ignore: non_constant_identifier_names
  bool ShowTitleBar = true,
}) {
  return MaterialApp(
    title: (ShowTitleBar || title == "") ? title : null,

    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
      useMaterial3: true,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    ),
    home:
        V_getScreen(strfrm, title, cp_name, strparameter, hideAppBar: true) ??
        const Scaffold(body: Center(child: Text('Không tìm thấy màn hình'))),
  );
}

// ignore: non_constant_identifier_names
void V_MainScreen(
  BuildContext context,
  String strfrm, {
  String title = "",
  // ignore: non_constant_identifier_names
  String cp_name = "",
  String strparameter = "",
  bool showAppBar = false,
}) {
  final screen = V_getScreen(
    strfrm,
    title,
    cp_name,
    strparameter,
    hideAppBar: !showAppBar,
  );

  if (screen == null) {
    debugPrint('⚠️ Không tìm thấy màn hình: $strfrm');
    return;
  }

  // Xóa toàn bộ navigation stack và chuyển sang màn hình mới
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (context) => screen),
    (route) => false, // ← false = XÓA TẤT CẢ
  );
}

// ignore: non_constant_identifier_names
Future<bool> V_callform(
  BuildContext context,
  String strfrm,
  String title,
  String cpName,
  String strparameter,
  String pagetype, {
  bool useHeroAnimation = false,
  bool clearAllStack = false,
}) async {
  switch (pagetype.toLowerCase()) {
    case 'exe':
      ReturnData? retData = await context.callApi(
        functionName: cpName,
        parameter: strparameter,
        showError: true,
        showLoading: true,
      );
      if (!retData.isValid()) return false;
      break;
    case 'aq':
      var isQuerySuccess = await strfrm.V_MsgBox(
        context,
        type: CyberMsgBoxType.warning,
        confirmText: "Đồng ý",
        cancelText: "Huỷ bỏ",
      );
      if (!isQuerySuccess) return false;
      if (cpName == "") return false;
      // ignore: use_build_context_synchronously
      ReturnData? retData = await context.callApi(
        functionName: cpName,
        parameter: strparameter,
        showError: true,
        showLoading: true,
      );
      if (!retData.isValid()) return false;
      break;
    case "a":
      await strfrm.V_MsgBox(
        context,
        title: title,
        type: CyberMsgBoxType.defaultType,
        confirmText: "Đồng ý",
      );
      break;
    case "ae":
      await strfrm.V_MsgBox(context, title: title, type: CyberMsgBoxType.error);
      break;
    case "aw":
      await strfrm.V_MsgBox(context, title: title, type: CyberMsgBoxType.error);
      break;
    default:
      final screen = V_getScreen(strfrm, title, cpName, strparameter);
      if (screen == null) {
        print("$strfrm không tìm thấy");
        return false;
      }
      if (clearAllStack) {
        Navigator.of(context).pushAndRemoveUntil(
          _buildPageRoute(screen, useHeroAnimation),
          (route) => false,
        );
      } else {
        // Navigate bình thường
        Navigator.push(context, _buildPageRoute(screen, useHeroAnimation));
      }

      break;
  }
  return true;
}

PageRoute _buildPageRoute(Widget screen, bool useHeroAnimation) {
  if (useHeroAnimation) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => screen,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 200),
    );
  } else {
    return MaterialPageRoute(builder: (context) => screen);
  }
}

/// Get ContentView widget để embed trong CyberForm
/// Usage trong CyberForm:
/// ```dart
/// @override
/// Widget buildBody(BuildContext context) {
///   return Column(
///     children: [
///       V_callView("contenview01",
///         cpName: "CP_GetData",
///         strParameter: "abc",
///         objectData: myData
///       ) ?? Text("View not found"),
///     ],
///   );
/// }
/// ```
// ignore: non_constant_identifier_names
Widget? V_callView(
  String viewName, {
  String cpName = "",
  String strParameter = "",
  dynamic objectData,
}) {
  return V_getView(
    viewName,
    cpName: cpName,
    strParameter: strParameter,
    objectData: objectData,
  );
}

// ignore: non_constant_identifier_names
Future<T?> V_callViewPopup<T>(
  BuildContext context,
  String viewName, {
  String cpName = "",
  String strParameter = "",
  dynamic objectData,
  PopupPosition position = PopupPosition.center,
  PopupAnimation animation = PopupAnimation.scale,
  bool barrierDismissible = true,
  Color? barrierColor,
  EdgeInsets? margin,
  EdgeInsets? padding,
  double? width,
  double? height,
  BorderRadius? borderRadius,
  Color? backgroundColor,
}) async {
  final view = V_getViewInstance(
    viewName,
    cpName: cpName,
    strParameter: strParameter,
    objectData: objectData,
  );

  if (view == null) return null;

  return await view.showPopup<T>(
    context,
    position: position,
    animation: animation,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    margin: margin,
    padding: padding,
    width: width,
    height: height,
    borderRadius: borderRadius,
    backgroundColor: backgroundColor,
  );
}

/// Show ContentView as bottom sheet
/// Usage:
/// ```dart
/// final result = await V_callViewBottom(
///   context,
///   "contenview01",
///   cpName: "CP_GetData",
/// );
/// ```
// ignore: non_constant_identifier_names
Future<T?> V_callViewBottom<T>(
  BuildContext context,
  String viewName, {
  String cpName = "",
  String strParameter = "",
  dynamic objectData,
  PopupAnimation animation = PopupAnimation.slideAndFade,
  bool barrierDismissible = true,
  Color? barrierColor,
  EdgeInsets? margin,
  EdgeInsets? padding,
  BorderRadius? borderRadius,
  Color? backgroundColor,
}) async {
  return await V_callViewPopup<T>(
    context,
    viewName,
    cpName: cpName,
    strParameter: strParameter,
    objectData: objectData,
    position: PopupPosition.bottom,
    animation: animation,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    margin: margin,
    padding: padding,
    borderRadius: borderRadius,
    backgroundColor: backgroundColor,
  );
}

/// Show ContentView as dialog (center, scale animation)
/// Usage:
/// ```dart
/// final result = await V_callViewDialog(
///   context,
///   "contenview01",
///   width: 400,
///   height: 300,
/// );
/// ```
// ignore: non_constant_identifier_names
Future<T?> V_callViewDialog<T>(
  BuildContext context,
  String viewName, {
  String cpName = "",
  String strParameter = "",
  dynamic objectData,
  bool barrierDismissible = true,
  Color? barrierColor,
  EdgeInsets? margin,
  EdgeInsets? padding,
  double? width,
  double? height,
  BorderRadius? borderRadius,
  Color? backgroundColor,
}) async {
  return await V_callViewPopup<T>(
    context,
    viewName,
    cpName: cpName,
    strParameter: strParameter,
    objectData: objectData,
    position: PopupPosition.center,
    animation: PopupAnimation.scale,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    margin: margin,
    padding: padding,
    width: width,
    height: height,
    borderRadius: borderRadius,
    backgroundColor: backgroundColor,
  );
}
