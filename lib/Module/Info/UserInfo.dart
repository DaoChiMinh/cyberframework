// ignore: file_names
import 'package:cyberframework/cyberframework.dart';

class UserInfo {
  static Future<String> get strTokenId async =>
      await AppStorage.get("strTokenId");
  static Future<void> setstrTokenId(String value) async =>
      await AppStorage.set("strTokenId", value);

  static CyberDataTable? dtCommand;
  static CyberDataTable? dtPhanHe;

  // ignore: non_constant_identifier_names
  static String user_name = "";
  // ignore: non_constant_identifier_names
  static String ma_dvcs = "";
  static String comment = "";
  static String isOTP = "";
  // ignore: non_constant_identifier_names
  static String id_otp = "";
  static bool LoginOTP = false;
  // ignore: non_constant_identifier_names
  static Future<bool> V_LoginOTP(
    BuildContext contex, {
    String Ma_otp = "",
    bool isShowMsg = true,
    bool isShowloading = true,
  }) async {
    String _certificate = await DeviceInfo.cetificate;
    String _strTokenId = await strTokenId;
    ReturnData returnDatalogin = await contex.callApi(
      functionName: "CP_APPNBSysLoginCheckOTP",
      parameter: "$id_otp#$Ma_otp#$_strTokenId#$_certificate##",
      showError: isShowMsg,
      showLoading: isShowloading,
    );
    if (!returnDatalogin.isValid()) {
      return false;
    }
    CyberDataset? dslogin = returnDatalogin.toCyberDataset();
    if (dslogin == null) {
      return false;
    }
    if (!dslogin.checkStatus(contex, isShowMsg: isShowMsg)) return false;
    CyberDataTable? dtlogin = dslogin[0];
    if (dtlogin == null || dtlogin.rowCount == 0) {
      return false;
    }
    return true;
  }

  static Future<bool> V_Login(
    BuildContext contex, {
    String userName = "",
    String password = "",
    String maDvcs = "",
    bool isShowMsg = true,
    bool isShowloading = true,
  }) async {
    // ✅ Get certificate và token
    // ignore: unused_local_variable, no_leading_underscores_for_local_identifiers
    String _certificate = await DeviceInfo.cetificate;
    // ignore: no_leading_underscores_for_local_identifiers
    String _strTokenId = await strTokenId;
    // ignore: no_leading_underscores_for_local_identifiers
    String _pass = MD5(password);
    // ✅ Call API
    // ignore: use_build_context_synchronously
    ReturnData returnDatalogin = await contex.callApi(
      functionName: "CP_APPNBSysLogin",
      parameter: "$_strTokenId#$_certificate#$userName#$_pass#$maDvcs",
      showError: isShowMsg,
      showLoading: isShowloading,
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
    // ignore: use_build_context_synchronously
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

    // ✅ Handle id_otp
    if (dtlogin.containerColumn("loginotp")) {
      LoginOTP = loginRow["loginotp"] == null
          ? false
          : loginRow["loginotp"]!.toString() == "1";
    }

    if (dtlogin.containerColumn("id_otp")) {
      id_otp = loginRow["id_otp"]?.toString() ?? "";
    } else if (dtlogin.containerColumn("idotp")) {
      // ✅ Fallback cho lowercases
      id_otp = loginRow["idotp"]?.toString() ?? "";
    } else {
      id_otp = "";
    }

    // ✅ Cập nhật Language theo biến M_Lan từ server
    if (dtlogin.containerColumn("M_Lan")) {
      String languageCode = loginRow["M_Lan"]?.toString() ?? "";
      if (languageCode.isNotEmpty) {
        try {
          final language = CyberLanguage.fromCode(languageCode);
          // Cập nhật language (không pass context để không gọi API lại)
          await cyberLanguage.setLanguage(language);
        } catch (e) {
          //debugPrint('⚠️ Error updating language from server: $e');
        }
      }
    }
    dtPhanHe = dslogin[2];
    dtCommand = dslogin[3];

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
}
