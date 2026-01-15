import 'package:cyberframework/Module/file_handler.dart';
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
    navigatorKey: AppNavigator.navigatorKey,
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
        V_getScreen(
          strfrm,
          title,
          cp_name,
          strparameter,
          hideAppBar: true,
          isMainScreen: true,
        ) ??
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
    isMainScreen: true,
  );

  if (screen == null) {
    //debugPrint('⚠️ Không tìm thấy màn hình: $strfrm');
    return;
  }

  // Xóa toàn bộ navigation stack và chuyển sang màn hình mới
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (context) => screen),
    (route) => false, // ← false = XÓA TẤT CẢ
  );
}

// ignore: non_constant_identifier_names
Future<ReturnFormData> V_callform(
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
      if (!retData.isValid()) return ReturnFormData(isOk: false);
      break;
    case 'aq':
      var isQuerySuccess = await strfrm.V_MsgBox(
        context,
        type: CyberMsgBoxType.warning,
        confirmText: "Đồng ý",
        cancelText: "Huỷ bỏ",
      );
      if (!isQuerySuccess) return ReturnFormData(isOk: false);
      if (cpName == "") return ReturnFormData(isOk: false);
      // ignore: use_build_context_synchronously
      ReturnData? retData = await context.callApi(
        functionName: cpName,
        parameter: strparameter,
        showError: true,
        showLoading: true,
      );
      if (!retData.isValid()) return ReturnFormData(isOk: false);
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
    case "w":
    case "wb":
    case "web":
      Frmwebview wb = Frmwebview();
      wb.Url = strfrm;

      Navigator.push(
        context,
        _buildPageRoute(
          CyberFormView(
            title: title,
            formBuilder: () => wb,
            cp_name: "cp_name",
            strparameter: strparameter,
          ),
          useHeroAnimation,
        ),
      );
      break;
    case "pdf":
    case "pdfview":
      FrmPdfView pdfViewer = FrmPdfView();

      // strfrm có thể là URL hoặc đường dẫn file local
      if (strfrm.startsWith('http://') || strfrm.startsWith('https://')) {
        pdfViewer.pdfUrl = strfrm; // URL
      } else {
        pdfViewer.pdfPath = strfrm; // Local path
      }

      pdfViewer.showToolbar = false;

      Navigator.push(
        context,
        _buildPageRoute(
          CyberFormView(
            title: title.isEmpty ? setText('Xem PDF', 'PDF Viewer') : title,
            formBuilder: () => pdfViewer,
            cp_name: cpName,
            strparameter: strparameter,
          ),
          useHeroAnimation,
        ),
      );
      break;
    case "img":
    case "image":
      FrmImageView imageViewer = FrmImageView();
      imageViewer.text = strfrm; // base64, path, or URL
      imageViewer.showToolbar = false;

      Navigator.push(
        context,
        _buildPageRoute(
          CyberFormView(
            title: title.isEmpty ? setText('Xem ảnh', 'Image Viewer') : title,
            formBuilder: () => imageViewer,
            cp_name: cpName,
            strparameter: strparameter,
          ),
          useHeroAnimation,
        ),
      );
      break;

    // ============================================================================
    // TEXT VIEWER
    // ============================================================================
    case "txt":
    case "text":
      FrmTextView textViewer = FrmTextView();
      textViewer.text = strfrm;
      textViewer.showToolbar = false;

      Navigator.push(
        context,
        _buildPageRoute(
          CyberFormView(
            title: title.isEmpty
                ? setText('Xem văn bản', 'Text Viewer')
                : title,
            formBuilder: () => textViewer,
            cp_name: cpName,
            strparameter: strparameter,
          ),
          useHeroAnimation,
        ),
      );
      break;

    // ============================================================================
    // WORD DOCUMENT VIEWER
    // ============================================================================
    case "doc":
    case "docx":
    case "word":
      FrmDocView docViewer = FrmDocView();
      docViewer.text = strfrm;
      docViewer.showToolbar = false;

      Navigator.push(
        context,
        _buildPageRoute(
          CyberFormView(
            title: title.isEmpty
                ? setText('Xem tài liệu', 'Document Viewer')
                : title,
            formBuilder: () => docViewer,
            cp_name: cpName,
            strparameter: strparameter,
          ),
          useHeroAnimation,
        ),
      );
      break;

    // ============================================================================
    // EXCEL VIEWER
    // ============================================================================
    case "xls":
    case "xlsx":
    case "excel":
      FrmExcelView excelViewer = FrmExcelView();
      excelViewer.text = strfrm;
      excelViewer.showToolbar = false;

      Navigator.push(
        context,
        _buildPageRoute(
          CyberFormView(
            title: title.isEmpty ? setText('Xem Excel', 'Excel Viewer') : title,
            formBuilder: () => excelViewer,
            cp_name: cpName,
            strparameter: strparameter,
          ),
          useHeroAnimation,
        ),
      );
      break;

    case "share":
      await FileHandler.shareFile(
        source: strfrm,
        fileExtension: cpName,
        fileName: title,
        subject: title,
        context: context,
      );
      break;
    case "download":
      await FileHandler.downloadFile(
        source: strfrm,
        fileExtension: cpName,
        customFileName: strparameter,
        context: context,
      );
      break;
    case "print":
      await FileHandler.printFile(
        source: strfrm,
        fileType: cpName == "pdf"
            ? "pdf"
            : (cpName == "text" ? "text" : "image"),
        documentName: title,
        context: context,
      );
      break;
    case "callconfirm":
    case "call":
      // Gọi điện thoại với dialog xác nhận
      String phoneNumber = strparameter;
      if (phoneNumber == "") {
        phoneNumber = strfrm;
      }

      await PhoneHandler.makePhoneCall(
        phoneNumber,
        context: context,
        showConfirmation: true,
      );
      break;
    case "sms":
    case "message":
      // Gửi SMS
      // strfrm = số điện thoại
      // strparameter = nội dung tin nhắn (optional)
      await PhoneHandler.sendSMS(
        strfrm,
        message: strparameter,
        context: context,
      );
      break;
    case "whatsapp":
    case "wa":
      // Mở WhatsApp chat
      // strfrm = số điện thoại
      // strparameter = tin nhắn mặc định (optional)
      await PhoneHandler.openWhatsApp(
        strfrm,
        message: strparameter,
        context: context,
      );
      break;
    case "telegram":
    case "tg":
      // Mở Telegram chat
      await PhoneHandler.openTelegram(strfrm, context: context);
      break;
    case "viber":
      // Mở Viber chat
      await PhoneHandler.openViber(strfrm, context: context);
      break;

    case "contacts":
    case "phonebook":
      // Mở ứng dụng Danh bạ
      await PhoneHandler.openContacts(context: context);
      break;

    case "savecontact":
      // Lưu số vào danh bạ
      // strfrm = số điện thoại
      // title = tên người (optional)
      // strparameter = email (optional)
      await PhoneHandler.saveToContacts(
        strfrm,
        name: title,
        email: strparameter,
        context: context,
      );
      break;
    case "zalo":
    case "zalochat":
      // Mở Zalo chat
      // strfrm = số điện thoại
      await PhoneHandler.openZaloChat(strfrm, context: context);
      break;

    case "zalocall":
      // Gọi điện qua Zalo
      // strfrm = số điện thoại
      await PhoneHandler.makeZaloCall(
        strfrm,
        context: context,
        showConfirmation: true,
      );
      break;

    case "zalocallconfirm":
      // Gọi Zalo với xác nhận
      await PhoneHandler.makeZaloCall(
        strfrm,
        context: context,
        showConfirmation: true,
      );
      break;

    case "zalomessage":
    case "zalomsg":
      // Gửi tin nhắn Zalo (thực chất là mở chat)
      // strfrm = số điện thoại
      // strparameter = tin nhắn gợi ý (chỉ hiện thông báo)
      await PhoneHandler.sendZaloMessage(
        strfrm,
        message: strparameter,
        context: context,
      );
      break;

    case "zalooa":
      // Mở Zalo Official Account
      // strfrm = OA ID
      await PhoneHandler.openZaloOA(strfrm, context: context);
      break;

    case "aw":
      await strfrm.V_MsgBox(context, title: title, type: CyberMsgBoxType.error);
      break;
    case "p":
    case "popup":
      await V_callViewPopup(
        context,
        strfrm,
        cpName: cpName,
        strParameter: strparameter,
      );
      break;
    case "pb":
    case "popupbotton":
    case "popup_botton":
      await V_callViewBottom(
        context,
        strfrm,
        cpName: cpName,
        strParameter: strparameter,
      );
      break;
    case "pd":
    case "popupdialog":
      await V_callViewDialog(
        context,
        strfrm,
        cpName: cpName,
        strParameter: strparameter,
      );
      break;
    default:
      final screen = V_getScreen(strfrm, title, cpName, strparameter);
      if (screen == null) {
        debugPrint('⚠️ Không tìm thấy màn hình: $strfrm');
        return ReturnFormData(isOk: false);
      }
      dynamic result;
      if (clearAllStack) {
        result = await Navigator.of(context).pushAndRemoveUntil(
          _buildPageRoute(screen, useHeroAnimation),
          (route) => false,
        );
      } else {
        // Navigate bình thường
        result = await Navigator.push(
          context,
          _buildPageRoute(screen, useHeroAnimation),
        );
      }
      if (result == null) return ReturnFormData(isOk: false);
      if (result is ReturnFormData) {
        return result;
      }
      return ReturnFormData(isOk: true, objectData: result);
  }
  return ReturnFormData(isOk: true);
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

class ReturnFormData {
  bool? isOk;
  Object? objectData;

  ReturnFormData({required this.isOk, this.objectData});
}
