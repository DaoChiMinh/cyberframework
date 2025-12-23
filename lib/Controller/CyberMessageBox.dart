import 'package:cyberframework/cyberframework.dart';

/// Loại MessageBox
enum CyberMsgBoxType {
  /// Default: Icon tích xanh, màu xanh, chỉ có nút OK
  defaultType,

  /// Warning: Icon hỏi vàng, màu vàng, có nút OK và Cancel
  warning,

  /// Error: Icon lỗi đỏ, màu đỏ, chỉ có nút OK
  error,
}

/// CyberMessageBox - MessageBox với các style khác nhau
class CyberMessageBox {
  final String message;
  final String? title;
  final CyberMsgBoxType type;
  final String? confirmText;
  final String? cancelText;

  const CyberMessageBox({
    required this.message,
    this.title,
    this.type = CyberMsgBoxType.defaultType,
    this.confirmText,
    this.cancelText,
  });

  /// Show MessageBox và trả về kết quả
  Future<bool> show(BuildContext context) async {
    final config = _getConfig();

    final popup = CyberPopup(
      context: context,
      child: _MessageBoxContent(
        message: message,
        title: title ?? config.defaultTitle,
        icon: config.icon,
        iconColor: config.iconColor,
        contentColor: config.contentColor,
        confirmText: confirmText ?? config.defaultConfirmText,
        confirmColor: config.confirmColor,
        cancelText: type == CyberMsgBoxType.warning
            ? (cancelText ?? 'Hủy')
            : null,
        cancelColor: config.cancelColor,
      ),
      width: 400,
      animation: PopupAnimation.scale,
      position: PopupPosition.center,
    );

    final result = await popup.show<bool>();
    return result ?? false;
  }

  /// Lấy cấu hình theo type
  _MessageBoxConfig _getConfig() {
    switch (type) {
      case CyberMsgBoxType.defaultType:
        return _MessageBoxConfig(
          icon: Icons.check_circle,
          iconColor: Colors.green,
          contentColor: Colors.green[700]!,
          confirmColor: Colors.green,
          defaultTitle: 'Thông báo',
          defaultConfirmText: 'Xác nhận',
        );

      case CyberMsgBoxType.warning:
        return _MessageBoxConfig(
          icon: Icons.help_outline,
          iconColor: Colors.orange[800]!,
          contentColor: Colors.orange[700]!,
          confirmColor: Colors.blue,
          cancelColor: Colors.red,
          defaultTitle: 'Cảnh báo',
          defaultConfirmText: 'Xác nhận',
        );

      case CyberMsgBoxType.error:
        return _MessageBoxConfig(
          icon: Icons.error_outline,
          iconColor: Colors.red,
          contentColor: Colors.red[700]!,
          confirmColor: Colors.red,
          defaultTitle: 'Lỗi',
          defaultConfirmText: 'Đóng',
        );
    }
  }
}

/// Cấu hình cho MessageBox
class _MessageBoxConfig {
  final IconData icon;
  final Color iconColor;
  final Color contentColor;
  final Color confirmColor;
  final Color? cancelColor;
  final String defaultTitle;
  final String defaultConfirmText;

  _MessageBoxConfig({
    required this.icon,
    required this.iconColor,
    required this.contentColor,
    required this.confirmColor,
    this.cancelColor,
    required this.defaultTitle,
    required this.defaultConfirmText,
  });
}

/// Content của MessageBox
class _MessageBoxContent extends StatelessWidget {
  final String message;
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color contentColor;
  final String confirmText;
  final Color confirmColor;
  final String? cancelText;
  final Color? cancelColor;

  const _MessageBoxContent({
    required this.message,
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.contentColor,
    required this.confirmText,
    required this.confirmColor,
    this.cancelText,
    this.cancelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Icon(icon, size: 64, color: iconColor),
          const SizedBox(height: 16),

          // Title
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Message
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: contentColor),
          ),
          const SizedBox(height: 24),

          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Cancel button (chỉ hiện khi có cancelText)
              if (cancelText != null) ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => CyberPopup.close(context, false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cancelColor ?? Colors.grey,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      cancelText!,
                      style: const TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],

              // Confirm button
              Expanded(
                child: ElevatedButton(
                  onPressed: () => CyberPopup.close(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: confirmColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    confirmText,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

extension CyberDynamicExtension on dynamic {
  /// Kiểm tra null hoặc empty - Main method
  bool checkEmptyIsNull(
    BuildContext? context,
    String fieldName, {
    bool isShowMsg = true,
  }) {
    // Check null
    if (this == null) {
      if (isShowMsg) {
        "$fieldName không được để trống".V_MsgBox(
          context,
          type: CyberMsgBoxType.error,
        );
      }
      return false;
    }

    // Check empty string
    if (this is String && (this as String).trim().isEmpty) {
      if (isShowMsg) {
        "$fieldName không được để trống".V_MsgBox(
          context,
          type: CyberMsgBoxType.error,
        );
      }
      return false;
    }

    // Check empty list
    if (this is List && (this as List).isEmpty) {
      if (isShowMsg) {
        "$fieldName không được để trống".V_MsgBox(
          context,
          type: CyberMsgBoxType.error,
        );
      }
      return false;
    }

    // Check empty map
    if (this is Map && (this as Map).isEmpty) {
      if (isShowMsg) {
        "$fieldName không được để trống".V_MsgBox(
          context,
          type: CyberMsgBoxType.error,
        );
      }
      return false;
    }

    return true;
  }

  /// Alias 1: checkEmptyorIsNull (với "or")
  bool checkEmptyorIsNull(
    BuildContext? context,
    String fieldName, {
    bool isShowMsg = true,
  }) {
    return checkEmptyIsNull(context, fieldName, isShowMsg: isShowMsg);
  }

  /// Alias 2: checkEmptyisnull (lowercase, không dấu)
  bool checkEmptyisnull(
    BuildContext context,
    String fieldName, {
    bool isShowMsg = true,
  }) {
    return checkEmptyIsNull(context, fieldName, isShowMsg: isShowMsg);
  }

  /// Kiểm tra null hoặc empty - Version ngắn gọn không show message
  bool get isNullOrEmpty {
    if (this == null) return true;
    if (this is String) return (this as String).trim().isEmpty;
    if (this is List) return (this as List).isEmpty;
    if (this is Map) return (this as Map).isEmpty;
    return false;
  }

  /// Kiểm tra có giá trị (ngược lại của isNullOrEmpty)
  bool get hasValue {
    return !isNullOrEmpty;
  }

  /// Validate email
  bool validateEmail(
    BuildContext context,
    String fieldName, {
    bool isShowMsg = true,
  }) {
    if (!checkEmptyIsNull(context, fieldName, isShowMsg: isShowMsg)) {
      return false;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (!emailRegex.hasMatch(this.toString())) {
      if (isShowMsg) {
        "$fieldName không đúng định dạng email".V_MsgBox(
          context,
          type: CyberMsgBoxType.error,
        );
      }
      return false;
    }

    return true;
  }

  /// Validate phone number (Vietnam format)
  bool validatePhone(
    BuildContext context,
    String fieldName, {
    bool isShowMsg = true,
  }) {
    if (!checkEmptyIsNull(context, fieldName, isShowMsg: isShowMsg)) {
      return false;
    }

    final phoneRegex = RegExp(r'^(0|\+84)[0-9]{9,10}$');

    if (!phoneRegex.hasMatch(this.toString().replaceAll(' ', ''))) {
      if (isShowMsg) {
        "$fieldName không đúng định dạng số điện thoại".V_MsgBox(
          context,
          type: CyberMsgBoxType.error,
        );
      }
      return false;
    }

    return true;
  }

  /// Validate minimum length
  bool validateMinLength(
    BuildContext context,
    String fieldName,
    int minLength, {
    bool isShowMsg = true,
  }) {
    if (!checkEmptyIsNull(context, fieldName, isShowMsg: isShowMsg)) {
      return false;
    }

    if (this.toString().length < minLength) {
      if (isShowMsg) {
        "$fieldName phải có ít nhất $minLength ký tự".V_MsgBox(
          context,
          type: CyberMsgBoxType.error,
        );
      }
      return false;
    }

    return true;
  }

  /// Validate maximum length
  bool validateMaxLength(
    BuildContext context,
    String fieldName,
    int maxLength, {
    bool isShowMsg = true,
  }) {
    if (!checkEmptyIsNull(context, fieldName, isShowMsg: isShowMsg)) {
      return false;
    }

    if (this.toString().length > maxLength) {
      if (isShowMsg) {
        "$fieldName không được vượt quá $maxLength ký tự".V_MsgBox(
          context,
          type: CyberMsgBoxType.error,
        );
      }
      return false;
    }

    return true;
  }

  /// Validate range length
  bool validateLengthRange(
    BuildContext context,
    String fieldName,
    int minLength,
    int maxLength, {
    bool isShowMsg = true,
  }) {
    if (!checkEmptyIsNull(context, fieldName, isShowMsg: isShowMsg)) {
      return false;
    }

    final length = this.toString().length;

    if (length < minLength || length > maxLength) {
      if (isShowMsg) {
        "$fieldName phải có từ $minLength đến $maxLength ký tự".V_MsgBox(
          context,
          type: CyberMsgBoxType.error,
        );
      }
      return false;
    }

    return true;
  }

  /// Validate number range
  bool validateNumberRange(
    BuildContext context,
    String fieldName,
    num min,
    num max, {
    bool isShowMsg = true,
  }) {
    if (!checkEmptyIsNull(context, fieldName, isShowMsg: isShowMsg)) {
      return false;
    }

    final number = num.tryParse(this.toString());
    if (number == null) {
      if (isShowMsg) {
        "$fieldName phải là số".V_MsgBox(context, type: CyberMsgBoxType.error);
      }
      return false;
    }

    if (number < min || number > max) {
      if (isShowMsg) {
        "$fieldName phải nằm trong khoảng $min đến $max".V_MsgBox(
          context,
          type: CyberMsgBoxType.error,
        );
      }
      return false;
    }

    return true;
  }

  /// Validate custom regex
  bool validateRegex(
    BuildContext context,
    String fieldName,
    String pattern, {
    String? errorMessage,
    bool isShowMsg = true,
  }) {
    if (!checkEmptyIsNull(context, fieldName, isShowMsg: isShowMsg)) {
      return false;
    }

    final regex = RegExp(pattern);

    if (!regex.hasMatch(this.toString())) {
      if (isShowMsg) {
        final message = errorMessage ?? "$fieldName không đúng định dạng";
        message.V_MsgBox(context, type: CyberMsgBoxType.error);
      }
      return false;
    }

    return true;
  }

  /// Parse to int safely
  int? toIntSafe() {
    if (this == null) return null;
    if (this is int) return this as int;
    if (this is double) return (this as double).toInt();
    if (this is String) return int.tryParse(this as String);
    return null;
  }

  /// Parse to double safely
  double? toDoubleSafe() {
    if (this == null) return null;
    if (this is double) return this as double;
    if (this is int) return (this as int).toDouble();
    if (this is String) return double.tryParse(this as String);
    return null;
  }

  /// Parse to bool safely
  bool toBoolSafe() {
    if (this == null) return false;
    if (this is bool) return this as bool;
    if (this is int) return this == 1;
    if (this is String) {
      final lower = (this as String).toLowerCase().trim();
      return lower == '1' || lower == 'true' || lower == 'yes';
    }
    return false;
  }

  /// Get value or default
  T valueOrDefault<T>(T defaultValue) {
    if (this == null) return defaultValue;
    if (this is T) return this as T;
    return defaultValue;
  }
}

/// Extension for BuildContext - Helper for validation
extension CyberValidationContext on BuildContext {
  /// Validate multiple fields
  bool validateFields(Map<String, dynamic> fields) {
    for (var entry in fields.entries) {
      if (!entry.value.checkEmptyIsNull(this, entry.key)) {
        return false;
      }
    }
    return true;
  }

  /// Show validation error
  Future<void> showValidationError(String fieldName, String message) async {
    await "$fieldName: $message".V_MsgBox(this, type: CyberMsgBoxType.error);
  }
}

/// Extension method cho String - giống MAUI
extension CyberMessageBoxExtension on String {
  /// Show MessageBox từ String
  ///
  /// Usage:
  /// ```dart
  /// bool result = await "Nội dung thông báo".V_MsgBox(
  ///   context,
  ///   title: "Tiêu đề",
  ///   type: CyberMsgBoxType.warning,
  /// );
  /// ```
  // ignore: non_constant_identifier_names
  Future<bool> V_MsgBox(
    BuildContext context, {
    String? title = "",
    CyberMsgBoxType type = CyberMsgBoxType.defaultType,
    String? confirmText,
    String? cancelText,
  }) async {
    if (title == "") {
      switch (type) {
        case CyberMsgBoxType.defaultType:
          title = 'Thông báo';
          break;
        case CyberMsgBoxType.warning:
          title = 'Cảnh báo';
          break;
        case CyberMsgBoxType.error:
          title = 'Lỗi';
          break;
      }
    }
    final msgBox = CyberMessageBox(
      message: this,
      title: title,
      type: type,
      confirmText: confirmText,
      cancelText: cancelText,
    );

    return await msgBox.show(context);
  }
}

/// Extension methods cho BuildContext
extension CyberMessageBoxContextExtension on BuildContext {
  /// Show Default MessageBox (Success)
  Future<bool> showSuccess(
    String message, {
    String? title = "",
    String? confirmText,
  }) async {
    if (title == "") {
      title = 'Thông báo';
    }
    return await message.V_MsgBox(
      this,
      title: title,
      type: CyberMsgBoxType.defaultType,
      confirmText: confirmText,
    );
  }

  /// Show Warning MessageBox
  Future<bool> showWarning(
    String message, {
    String? title = "",
    String? confirmText,
    String? cancelText,
  }) async {
    if (title == "") {
      title = 'Cảnh báo';
    }
    return await message.V_MsgBox(
      this,
      title: title,
      type: CyberMsgBoxType.warning,
      confirmText: confirmText,
      cancelText: cancelText,
    );
  }

  /// Show Error MessageBox
  Future<bool> showErrorMsg(
    String message, {
    String? title = "",
    String? confirmText,
  }) async {
    if (title == "") {
      title = 'Lỗi';
    }
    return await message.V_MsgBox(
      this,
      title: title,
      type: CyberMsgBoxType.error,
      confirmText: confirmText,
    );
  }
}
