import 'package:cyberframework/cyberframework.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

Future<void> initOneSignal(String AppId) async {
  OneSignal.initialize(AppId);
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

  // Xử lý khi click notification (app đang chạy hoặc background)
  OneSignal.Notifications.addClickListener((event) {
    _handleNotificationOpened(event);
  });

  // Xử lý khi app được mở từ notification (app đã đóng hoàn toàn)
  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    if (event.notification.additionalData == null) return;

    // final data = event.notification.additionalData!;
    // int countbage = data["ios_badgeCount"] ?? 0;
    //updatebage(countbage);
  });
  final accepted = await OneSignal.Notifications.requestPermission(true);
  // print("permission accepted = $accepted");

  OneSignal.User.pushSubscription.addObserver((state) {
    // print("optedIn = ${state.current.optedIn}");
    // print("token   = ${state.current.token}");
    // print("sub id  = ${state.current.id}");
  });
}

Future<void> LogoutOnsinal() async {
  await OneSignal.logout();
}

Future<void> LoginOnsinal(CyberDataRow drLogin) async {
  await LogoutOnsinal();
  await Future.delayed(const Duration(milliseconds: 500));
  String tokenKey = drLogin["TOKENKEY"]?.toString().trim() ?? "";
  if (tokenKey.isEmpty) return;

  await OneSignal.login(tokenKey);
  await Future.delayed(const Duration(milliseconds: 500));

  OneSignal.User.addTags({
    "Comment": drLogin["comment"] ?? "",
    "User_name": drLogin["User_name"] ?? "",
    "M_Ten_CTy": drLogin["M_Ten_CTy"] ?? "",
    "Ma_So_Thue": drLogin["Ma_So_Thue"] ?? "",
    "Ma_Dvcs": drLogin["Ma_Dvcs"] ?? "",
    "tokenKey": tokenKey,
  });
}

void _handleNotificationOpened(OSNotificationClickEvent event) {
  if (event.notification.additionalData == null) return;

  final data = event.notification.additionalData!;

  if (!data.containsKey("PAGENAME")) return;

  String pageName = data["PAGENAME"]?.toString() ?? "";
  String cpName = data["CP_NAME"]?.toString() ?? "";
  String strParameter = data["STRPARAMETER"]?.toString() ?? "";
  String pagetype = data["TYPEPAGENAME"]?.toString() ?? "";

  if (pageName.isEmpty) return;

  // Delay một chút để đảm bảo app đã khởi động xong
  Future.delayed(const Duration(milliseconds: 800), () async {
    await V_callform(
      AppNavigator.context!,
      pageName,
      "",
      cpName,
      strParameter,
      pagetype,
    );
  });
}
