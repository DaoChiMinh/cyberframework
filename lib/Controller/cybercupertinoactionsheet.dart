import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Model cho mỗi action sheet item
class CyberActionSheet {
  final String label;
  final IconData? icon;
  final Color? iconColor;
  final Color? labelColor;
  final VoidCallback? onclick;
  final bool isDestructive;
  final bool isDefaultAction;

  CyberActionSheet({
    required this.label,
    this.icon,
    this.iconColor,
    this.labelColor,
    this.onclick,
    this.isDestructive = false,
    this.isDefaultAction = false,
  });
}

/// Hiển thị CupertinoActionSheet với danh sách actions
Future<void> showCyberCupertinoActionSheet(
  BuildContext context,
  List<CyberActionSheet> actions, {
  String? title,
  String? message,
  String? cancelLabel,
  bool barrierDismissible = true,
}) async {
  return await showCupertinoModalPopup<void>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (BuildContext context) => CupertinoActionSheet(
      title: title != null
          ? Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: CupertinoColors.systemGrey,
              ),
            )
          : null,
      message: message != null
          ? Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: CupertinoColors.systemGrey,
              ),
            )
          : null,
      actions: actions
          .map(
            (action) => CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                if (action.onclick != null) {
                  action.onclick!();
                }
              },
              isDefaultAction: action.isDefaultAction,
              isDestructiveAction: action.isDestructive,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (action.icon != null) ...[
                    Icon(
                      action.icon,
                      color:
                          action.iconColor ??
                          (action.isDestructive
                              ? CupertinoColors.systemRed
                              : CupertinoColors.activeBlue),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    action.label,
                    style: TextStyle(
                      color:
                          action.labelColor ??
                          (action.isDestructive
                              ? CupertinoColors.systemRed
                              : CupertinoColors.activeBlue),
                      fontSize: 20,
                      fontWeight: action.isDefaultAction
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(context),
        child: Text(
          cancelLabel ?? 'Cancel',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
    ),
  );
}

/// Extension để gọi ngắn gọn hơn
extension CyberCupertinoActionSheetExtension on BuildContext {
  Future<void> showCyberActionSheet(
    List<CyberActionSheet> actions, {
    String? title,
    String? message,
    String? cancelLabel,
    bool barrierDismissible = true,
  }) {
    return showCyberCupertinoActionSheet(
      this,
      actions,
      title: title,
      message: message,
      cancelLabel: cancelLabel,
      barrierDismissible: barrierDismissible,
    );
  }
}
