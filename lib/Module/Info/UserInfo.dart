import 'package:cyberframework/cyberframework.dart';

class UserInfo {
  static Future<String?> get strTokenId async =>
      await CyberStorage.get("strTokenId");
  static Future<void> setstrTokenId(String value) async =>
      await CyberStorage.set("strTokenId", value);

  static String user_name = "";
  static String ma_dvcs = "";
  static String comment = "";
  static String isOTP = "";
  static String id_otp = "";

  static Future<bool> V_Login(
    BuildContext contex,
    String _userName,
    String _password,
    String _ma_Dvcs,
  ) async {
    String? cetificate = await DeviceInfo.cetificate;
    cetificate = cetificate ?? "";

    ReturnData returnDatalogin = await contex.callApi(
      functionName: "CP_APPNBSysLogin",
      parameter:
          "$strTokenId#$cetificate#$_userName#$_password#$MD5($_password)",
      showError: true,
      showLoading: true,
    );
    if (!returnDatalogin.isValid()) return false;
    CyberDataset? dslogin = returnDatalogin.toCyberDataset();
    CyberDataTable dtlogin = dslogin![0]!;
    await setstrTokenId(dtlogin[0]["tokenkey"]);
    user_name = dtlogin[0]["User_name"];
    comment = dtlogin[0]["Comment"];
    ma_dvcs = dtlogin[0]["ma_dvcs"];
    isOTP = dtlogin[0]["isOTP"];
    id_otp = dtlogin[0]["id_otp"];

    return true;
  }
}
