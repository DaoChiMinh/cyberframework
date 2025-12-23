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
  Color parseColor({Color defaultColor = Colors.black}) {
    if (isEmpty) return defaultColor;

    try {
      String hex = replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return defaultColor;
    }
  }

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
