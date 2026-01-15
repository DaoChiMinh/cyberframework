import 'package:cyberframework/cyberframework.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

Future<void> initOneSignal(String AppId) async {
  OneSignal.initialize(AppId);

  OneSignal.Notifications.requestPermission(true);

  // Xử lý khi click notification (app đang chạy hoặc background)
  OneSignal.Notifications.addClickListener((event) {
    _handleNotificationOpened(event);
  });

  // Xử lý khi app được mở từ notification (app đã đóng hoàn toàn)
  OneSignal.Notifications.addForegroundWillDisplayListener((event) {
    // Có thể xử lý hiển thị notification khi app đang ở foreground
    event.notification;
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
  Future.delayed(const Duration(milliseconds: 500), () async {
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
