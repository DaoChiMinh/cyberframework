import 'package:cyberframework/cyberframework.dart';
import 'package:uuid/uuid.dart';

class DeviceInfo extends ChangeNotifier {
  static Future<String> get dnsName async => await AppStorage.get("DNS");
  static Future<void> setdnsName(String value) async =>
      await AppStorage.set("DNS", value);

  static Future<String> get servername async =>
      await AppStorage.get("servername");
  static Future<void> setservername(String value) async =>
      await AppStorage.set("servername", value);

  static Future<String> get tencty async => await AppStorage.get("tencty");
  static Future<void> settencty(String value) async =>
      await AppStorage.set("tencty", value);

  static Future<String> get urlBanner async =>
      await AppStorage.get("urlBanner");
  static Future<void> seturlBanner(String value) async =>
      await AppStorage.set("urlBanner", value);

  static Future<String> get macdevice async =>
      await AppStorage.get("macdevice");
  static Future<void> setmacdevice(String value) async =>
      await AppStorage.set("macdevice", value);

  static Future<String> get cetificate async {
    String cer = await AppStorage.get("cetificate");
    if (cer == "") {
      cer = manufacturer();
      if (cer == "") {
        var uuid = Uuid();
        cer = uuid.v1();
        await setcetificate(cer);
      }
    }
    return cer;
  }

  static Future<void> setcetificate(String value) async =>
      await AppStorage.set("cetificate", value);
  static String displayDeviceName() => CyberDeviceInfo().displayDeviceName;
  static String deviceName() => CyberDeviceInfo().deviceName;
  static String deviceId() => CyberDeviceInfo().deviceId;
  static String manufacturer() => CyberDeviceInfo().manufacturer;
}
