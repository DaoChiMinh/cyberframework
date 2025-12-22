import 'package:cyberframework/Module/save_storage.dart';

class UserInfo {
  static Future<String?> get strTokenId async =>
      await CyberStorage.get("strTokenId");
  static Future<void> setstrTokenId(String value) async =>
      await CyberStorage.set("strTokenId", value);

  static String user_name = "";
  static String ma_dvcs = "";
  static String comment = "";
}
