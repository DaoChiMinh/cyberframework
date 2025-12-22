import 'dart:ui';

import 'package:cyberframework/cyberframework.dart';

class UserInfo {
  static Future<String> get strTokenId async =>
      await AppStorage.get("strTokenId");
  static Future<void> setstrTokenId(String value) async =>
      await AppStorage.set("strTokenId", value);

  static String user_name = "";
  static String ma_dvcs = "";
  static String comment = "";
  static String isOTP = "";
  static String id_otp = "";

  static Future<bool> V_Login(
    BuildContext contex,
    String _userName,
    String _password,
    String _ma_Dvcs, {
    bool isShowMsg = true,
  }) async {
    // ✅ Get certificate và token
    // ignore: unused_local_variable
    String _certificate = await DeviceInfo.cetificate;
    String _strTokenId = await strTokenId;

    String _pass = MD5(_password);
    print("$_strTokenId#$_certificate#$_userName#$_password#$_pass");
    // ✅ Call API
    ReturnData returnDatalogin = await contex.callApi(
      functionName: "CP_APPNBSysLogin",
      parameter: "$_strTokenId#$_certificate#$_userName#$_password#$_pass",
      showError: true,
      showLoading: true,
    );

    // ✅ Check response validity
    if (!returnDatalogin.isValid()) {
      return false;
    }

    // ✅ Safe null checks
    CyberDataset? dslogin = returnDatalogin.toCyberDataset();
    if (dslogin == null) {
      return false;
    }
    if (!dslogin.checkStatus(contex, isShowMsg: isShowMsg)) return false;
    CyberDataTable? dtlogin = dslogin[0];
    if (dtlogin == null || dtlogin.rowCount == 0) {
      return false;
    }

    // ✅ Get first row safely
    final loginRow = dtlogin[0];

    // ✅ Save token
    final tokenKey = loginRow["tokenkey"]?.toString();
    if (tokenKey != null && tokenKey.isNotEmpty) {
      await setstrTokenId(tokenKey);
    }

    // ✅ Safe field extraction với null handling
    user_name = loginRow["User_name"]?.toString() ?? "";
    comment = loginRow["Comment"]?.toString() ?? "";
    ma_dvcs = loginRow["ma_dvcs"]?.toString() ?? "";

    // ✅ Handle isOTP với nhiều format khác nhau
    if (dtlogin.containerColumn("isOTP")) {
      final otpValue = loginRow["isOTP"];
      if (otpValue is bool) {
        isOTP = otpValue ? "1" : "0";
      } else if (otpValue is String) {
        isOTP = otpValue;
      } else if (otpValue is int) {
        isOTP = otpValue.toString();
      } else {
        isOTP = "0";
      }
    } else if (dtlogin.containerColumn("isotp")) {
      // ✅ Fallback cho lowercase field
      final otpValue = loginRow["isotp"];
      if (otpValue is bool) {
        isOTP = otpValue ? "1" : "0";
      } else if (otpValue is String) {
        isOTP = otpValue;
      } else if (otpValue is int) {
        isOTP = otpValue.toString();
      } else {
        isOTP = "0";
      }
    } else {
      isOTP = "0";
    }

    // ✅ Handle id_otp
    if (dtlogin.containerColumn("id_otp")) {
      id_otp = loginRow["id_otp"]?.toString() ?? "";
    } else if (dtlogin.containerColumn("idotp")) {
      // ✅ Fallback cho lowercase
      id_otp = loginRow["idotp"]?.toString() ?? "";
    } else {
      id_otp = "";
    }

    return true;
  }

  /// ✅ Helper method: Clear session
  static Future<void> logout() async {
    await setstrTokenId("");
    user_name = "";
    ma_dvcs = "";
    comment = "";
    isOTP = "";
    id_otp = "";
  }

  /// ✅ Helper method: Check if logged in
  static Future<bool> isLoggedIn() async {
    final token = await strTokenId;
    return token != null && token.isNotEmpty;
  }
}
