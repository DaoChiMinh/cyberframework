import 'package:cyberframework/Module/save_storage.dart';
import 'package:flutter/material.dart';

class DeviceInfo extends ChangeNotifier {
  static Future<String?> get dnsName async => await CyberStorage.get("DNS");
  static Future<void> setdnsName(String value) async =>
      await CyberStorage.set("DNS", value);

  static Future<String?> get servername async =>
      await CyberStorage.get("servername");
  static Future<void> setservername(String value) async =>
      await CyberStorage.set("servername", value);

  static Future<String?> get macdevice async =>
      await CyberStorage.get("macdevice");
  static Future<void> setmacdevice(String value) async =>
      await CyberStorage.set("macdevice", value);

  static Future<String?> get cetificate async =>
      await CyberStorage.get("cetificate");
  static Future<void> setcetificate(String value) async =>
      await CyberStorage.set("cetificate", value);
  //cetificate
}
