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

  static Future<String> get macdevice async =>
      await AppStorage.get("macdevice");
  static Future<void> setmacdevice(String value) async =>
      await AppStorage.set("macdevice", value);

  static Future<String> get cetificate async {
    String cer = await AppStorage.get("cetificate");
    if (cer == "") {
      var uuid = Uuid();
      cer = uuid.v1();
      await setcetificate(cer);
    }

    return cer;
  }

  static Future<void> setcetificate(String value) async =>
      await AppStorage.set("cetificate", value);
  //cetificate
}
