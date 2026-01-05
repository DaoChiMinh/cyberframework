import 'package:cyberframework/cyberframework.dart';

/// Loại MessageBox
enum CyberMsgBoxType {
  /// Default: Màu xanh iOS, chỉ có nút OK
  defaultType,

  /// Warning: Có nút OK và Cancel
  warning,

  /// Error: Màu đỏ destructive, chỉ có nút OK
  error,
}

/// CyberMessageBox - MessageBox với iOS style
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
        confirmText: confirmText ?? config.defaultConfirmText,
        confirmColor: config.confirmColor,
        cancelText: type == CyberMsgBoxType.warning
            ? (cancelText ?? setText('Hủy', 'Cancel'))
            : null,
        cancelColor: config.cancelColor,
        isBold: config.isBold,
      ),
      width: 270, // iOS alert width
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
          confirmColor: const Color(0xFF007AFF), // iOS Blue
          defaultTitle: setText('Thông báo', 'Notification'),
          defaultConfirmText: 'OK',
          isBold: false,
        );

      case CyberMsgBoxType.warning:
        return _MessageBoxConfig(
          confirmColor: const Color(0xFF007AFF), // iOS Blue
          cancelColor: const Color(0xFF007AFF), // iOS Blue
          defaultTitle: setText('Cảnh báo', 'Warning'),
          defaultConfirmText: 'OK',
          isBold: true,
        );

      case CyberMsgBoxType.error:
        return _MessageBoxConfig(
          confirmColor: const Color(0xFFFF3B30), // iOS Red (Destructive)
          defaultTitle: setText('Lỗi', 'Error'),
          defaultConfirmText: 'OK',
          isBold: true,
        );
    }
  }
}

/// Cấu hình cho MessageBox
class _MessageBoxConfig {
  final Color confirmColor;
  final Color? cancelColor;
  final String defaultTitle;
  final String defaultConfirmText;
  final bool isBold;

  _MessageBoxConfig({
    required this.confirmColor,
    this.cancelColor,
    required this.defaultTitle,
    required this.defaultConfirmText,
    required this.isBold,
  });
}

/// Content của MessageBox - iOS Style
class _MessageBoxContent extends StatelessWidget {
  final String message;
  final String title;
  final String confirmText;
  final Color confirmColor;
  final String? cancelText;
  final Color? cancelColor;
  final bool isBold;

  const _MessageBoxContent({
    required this.message,
    required this.title,
    required this.confirmText,
    required this.confirmColor,
    this.cancelText,
    this.cancelColor,
    required this.isBold,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7), // iOS background
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title & Message
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            child: Column(
              children: [
                // Title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    letterSpacing: -0.41,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Message
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                    letterSpacing: -0.08,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Divider trước buttons
          Container(height: 0.5, color: const Color(0xFFBBBBC8)),

          // Buttons - iOS Style
          SizedBox(
            height: 44, // iOS button height
            child: Row(
              children: [
                // Cancel button (nếu có)
                if (cancelText != null) ...[
                  Expanded(
                    child: _IOSButton(
                      text: cancelText!,
                      color: cancelColor ?? const Color(0xFF007AFF),
                      onPressed: () => CyberPopup.close(context, false),
                      isBold: false,
                    ),
                  ),
                  // Divider giữa các nút
                  Container(width: 0.5, color: const Color(0xFFBBBBC8)),
                ],

                // Confirm button
                Expanded(
                  child: _IOSButton(
                    text: confirmText,
                    color: confirmColor,
                    onPressed: () => CyberPopup.close(context, true),
                    isBold: isBold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// iOS Style Button
class _IOSButton extends StatefulWidget {
  final String text;
  final Color color;
  final VoidCallback onPressed;
  final bool isBold;

  const _IOSButton({
    required this.text,
    required this.color,
    required this.onPressed,
    required this.isBold,
  });

  @override
  State<_IOSButton> createState() => _IOSButtonState();
}

class _IOSButtonState extends State<_IOSButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          color: _isPressed
              ? const Color(0xFFE5E5EA) // iOS pressed state
              : Colors.transparent,
        ),
        alignment: Alignment.center,
        child: Text(
          widget.text,
          style: TextStyle(
            fontSize: 17,
            fontWeight: widget.isBold ? FontWeight.w600 : FontWeight.w400,
            color: widget.color,
            letterSpacing: -0.41,
          ),
        ),
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
  Color parseColor({Color defaultColor = Colors.white}) {
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
          title = setText('Thông báo', 'Notification');
          break;
        case CyberMsgBoxType.warning:
          title = setText('Cảnh báo', 'Warning');
          break;
        case CyberMsgBoxType.error:
          title = setText('Lỗi', 'Error');
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
      title = setText('Thông báo', 'Notification');
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
      title = setText('Cảnh báo', 'Warning');
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
      title = setText('Lỗi', 'Error');
    }
    return await message.V_MsgBox(
      this,
      title: title,
      type: CyberMsgBoxType.error,
      confirmText: confirmText,
    );
  }
}
