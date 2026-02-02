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
  static String ten_cty = "";
  static String comment = "";
  static String chucvu = "";
  static String dienthoai = "";
  static String isOTP = "";
  // ignore: non_constant_identifier_names
  static String id_otp = "";
  static bool LoginOTP = false;
  static String isadmin = "0";
  static bool istantrang = false;
  static bool ischangpass = false;
  static String _strTokenKey = "";

  // ============================================================================
  // ✅ SL_Notify - Số lượng thông báo chưa đọc
  // ============================================================================

  /// Số lượng thông báo (static value)
  // ignore: non_constant_identifier_names
  static int SL_Notify = 0;

  /// ValueNotifier để UI có thể listen và tự động rebuild khi SL_Notify thay đổi
  /// Usage trong Widget:
  /// ```dart
  /// ValueListenableBuilder<int>(
  ///   valueListenable: UserInfo.notifyCountNotifier,
  ///   builder: (context, count, child) {
  ///     return Badge(
  ///       label: Text('$count'),
  ///       isLabelVisible: count > 0,
  ///       child: Icon(Icons.notifications),
  ///     );
  ///   },
  /// )
  /// ```
  static final ValueNotifier<int> notifyCountNotifier = ValueNotifier<int>(0);

  /// Cập nhật số lượng thông báo
  // ignore: non_constant_identifier_names
  static void updateSL_Notify(int count) {
    SL_Notify = count;
    notifyCountNotifier.value = count;
  }

  /// Tăng số lượng thông báo
  static void incrementNotify([int amount = 1]) {
    SL_Notify += amount;
    notifyCountNotifier.value = SL_Notify;
  }

  /// Giảm số lượng thông báo
  static void decrementNotify([int amount = 1]) {
    SL_Notify = (SL_Notify - amount).clamp(0, 999999);
    notifyCountNotifier.value = SL_Notify;
  }

  /// Đánh dấu đã đọc hết thông báo
  static void clearNotify() {
    SL_Notify = 0;
    notifyCountNotifier.value = 0;
  }

  /// Fetch số lượng thông báo từ server
  // ignore: non_constant_identifier_names
  static Future<bool> fetchSL_Notify(
    BuildContext context, {
    bool showLoading = false,
    bool showError = false,
  }) async {
    try {
      ReturnData? retData = await context.callApi(
        functionName: "CP_GetNotifyCount", // Tên API lấy số lượng notify
        parameter: "",
        showLoading: showLoading,
        showError: showError,
      );

      if (!retData.isValid()) return false;

      CyberDataset? ds = retData.toCyberDataset();
      if (ds == null) return false;

      CyberDataTable? dt = ds[0];
      if (dt == null || dt.rowCount == 0) return false;

      final row = dt[0];
      if (dt.containerColumn("SL_Notify")) {
        int count = _parseIntSafe(row["SL_Notify"]);
        updateSL_Notify(count);
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error fetching SL_Notify: $e');
      return false;
    }
  }

  /// Helper: Parse int an toàn
  static int _parseIntSafe(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // ============================================================================
  // LOGIN / LOGOUT
  // ============================================================================

  // ignore: non_constant_identifier_names
  static Future<bool> V_LoginOTP(
    BuildContext contex, {
    String Ma_otp = "",
    String Ma_Dvcs = "",
    String User_Name = "",
    bool isShowMsg = true,
    bool isShowloading = true,
  }) async {
    String _certificate = await DeviceInfo.cetificate;

    ReturnData returnDatalogin = await contex.callApi(
      functionName: "CP_APPNBSysLoginCheckOTP",
      parameter:
          "$id_otp#$Ma_otp#$_strTokenKey#$_certificate#$Ma_Dvcs#$User_Name",
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
    if (!await dslogin.checkStatus(contex, isShowMsg: isShowMsg)) return false;
    CyberDataTable? dtlogin = dslogin[0];
    if (dtlogin == null || dtlogin.rowCount == 0) {
      return false;
    }
    await setstrTokenId(_strTokenKey);
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
    if (!await dslogin.checkStatus(contex, isShowMsg: isShowMsg)) return false;
    CyberDataTable? dtlogin = dslogin[0];
    if (dtlogin == null || dtlogin.rowCount == 0) {
      return false;
    }

    // ✅ Get first row safely
    final loginRow = dtlogin[0];

    // ✅ Safe field extraction với null handling
    user_name = loginRow["User_name"]?.toString() ?? "";
    comment = loginRow["Comment"]?.toString() ?? "";
    ma_dvcs = loginRow["ma_dvcs"]?.toString() ?? "";
    ten_cty = loginRow["m_ten_cty"]?.toString() ?? "";
    isadmin = loginRow["is_admin"]?.toString() ?? "0";
    chucvu = loginRow["chuc_vu"]?.toString() ?? "";
    dienthoai = loginRow["telephone"]?.toString() ?? "";

    // ✅ Handle id_otp
    if (dtlogin.containerColumn("loginotp")) {
      LoginOTP = loginRow["loginotp"] == null
          ? false
          : loginRow["loginotp"]! == 1.0;
    }

    if (dtlogin.containerColumn("tamtrang")) {
      istantrang = loginRow["tamtrang"] == null
          ? false
          : loginRow["tamtrang"]! == 1.0 ||
                loginRow["tamtrang"].toString() == "1";
    }

    if (dtlogin.containerColumn("changepass")) {
      ischangpass = loginRow["changepass"] == null
          ? false
          : loginRow["changepass"]! == 1.0 ||
                loginRow["changepass"].toString() == "1";
    }

    if (dtlogin.containerColumn("id_otp")) {
      id_otp = loginRow["id_otp"]?.toString() ?? "";
    } else if (dtlogin.containerColumn("idotp")) {
      // ✅ Fallback cho lowercases
      id_otp = loginRow["idotp"]?.toString() ?? "";
    } else {
      id_otp = "";
    }

    // ✅ Handle SL_Notify - Số lượng thông báo
    if (dtlogin.containerColumn("SL_Notify")) {
      int count = _parseIntSafe(loginRow["SL_Notify"]);
      updateSL_Notify(count);
    } else if (dtlogin.containerColumn("sl_notify")) {
      // Fallback lowercase
      int count = _parseIntSafe(loginRow["sl_notify"]);
      updateSL_Notify(count);
    } else {
      // Reset nếu không có cột
      updateSL_Notify(0);
    }

    // ✅ Save token
    final tokenKey = loginRow["tokenkey"]?.toString();
    if (tokenKey != null && tokenKey.isNotEmpty) {
      _strTokenKey = tokenKey;

      // nếu không login bằng OTP thì lưu lại tokenkey
      if (!LoginOTP) {
        await setstrTokenId(tokenKey);
      }
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
    await LoginOnsinal(loginRow);
    return true;
  }

  /// ✅ Helper method: Clear session
  static Future<void> logout() async {
    await setstrTokenId("");
    await LogoutOnsinal();
    user_name = "";
    ma_dvcs = "";
    comment = "";
    isOTP = "";
    id_otp = "";

    // ✅ Reset SL_Notify khi logout
    clearNotify();
  }
}
