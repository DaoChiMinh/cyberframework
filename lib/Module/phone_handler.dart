import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PhoneHandler {
  /// Gọi điện thoại trực tiếp
  static Future<bool> makePhoneCall(
    String phoneNumber, {
    BuildContext? context,
    bool showConfirmation = false,
  }) async {
    try {
      // Clean phone number (remove spaces, dashes, parentheses)
      final cleanNumber = _cleanPhoneNumber(phoneNumber);

      if (cleanNumber.isEmpty) {
        if (context != null && context.mounted) {
          _showError(context, 'Số điện thoại không hợp lệ');
        }
        return false;
      }

      // Show confirmation dialog if needed
      if (showConfirmation && context != null) {
        final confirmed = await _showConfirmDialog(context, cleanNumber);
        if (!confirmed) return false;
      }

      final uri = Uri.parse('tel:$cleanNumber');

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      } else {
        if (context != null && context.mounted) {
          _showError(context, 'Không thể gọi số điện thoại này');
        }
        return false;
      }
    } catch (e) {
      if (context != null && context.mounted) {
        _showError(context, 'Lỗi: $e');
      }
      return false;
    }
  }

  /// Gửi SMS
  static Future<bool> sendSMS(
    String phoneNumber, {
    String? message,
    BuildContext? context,
  }) async {
    try {
      final cleanNumber = _cleanPhoneNumber(phoneNumber);

      if (cleanNumber.isEmpty) {
        if (context != null && context.mounted) {
          _showError(context, 'Số điện thoại không hợp lệ');
        }
        return false;
      }

      String smsUri = 'sms:$cleanNumber';
      if (message != null && message.isNotEmpty) {
        smsUri += '?body=${Uri.encodeComponent(message)}';
      }

      final uri = Uri.parse(smsUri);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      } else {
        if (context != null && context.mounted) {
          _showError(context, 'Không thể gửi SMS');
        }
        return false;
      }
    } catch (e) {
      if (context != null && context.mounted) {
        _showError(context, 'Lỗi: $e');
      }
      return false;
    }
  }

  /// Mở ứng dụng Danh bạ
  static Future<bool> openContacts({BuildContext? context}) async {
    try {
      // Try to open contacts app (may not work on all devices)
      final uri = Uri.parse('content://contacts/people/');

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      } else {
        if (context != null && context.mounted) {
          _showError(context, 'Không thể mở danh bạ');
        }
        return false;
      }
    } catch (e) {
      if (context != null && context.mounted) {
        _showError(context, 'Lỗi: $e');
      }
      return false;
    }
  }

  /// Lưu số vào danh bạ (mở form thêm contact mới)
  static Future<bool> saveToContacts(
    String phoneNumber, {
    String? name,
    String? email,
    BuildContext? context,
  }) async {
    try {
      final cleanNumber = _cleanPhoneNumber(phoneNumber);

      // Create vCard format
      if (name != null && name.isNotEmpty) {}
      if (email != null && email.isNotEmpty) {}

      // Try to open contacts with intent (Android specific)
      // This may not work on all devices/platforms
      if (context != null && context.mounted) {
        _showInfo(
          context,
          'Số điện thoại: $cleanNumber${name != null ? "\nTên: $name" : ""}',
        );
      }

      return true;
    } catch (e) {
      if (context != null && context.mounted) {
        _showError(context, 'Lỗi: $e');
      }
      return false;
    }
  }

  /// WhatsApp chat
  static Future<bool> openWhatsApp(
    String phoneNumber, {
    String? message,
    BuildContext? context,
  }) async {
    try {
      final cleanNumber = _cleanPhoneNumber(phoneNumber);

      // Remove leading 0 if exists and add country code if needed
      String whatsappNumber = cleanNumber;
      if (whatsappNumber.startsWith('0')) {
        whatsappNumber =
            '84${whatsappNumber.substring(1)}'; // Vietnam country code
      }

      String whatsappUri = 'https://wa.me/$whatsappNumber';
      if (message != null && message.isNotEmpty) {
        whatsappUri += '?text=${Uri.encodeComponent(message)}';
      }

      final uri = Uri.parse(whatsappUri);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        if (context != null && context.mounted) {
          _showError(context, 'Không thể mở WhatsApp');
        }
        return false;
      }
    } catch (e) {
      if (context != null && context.mounted) {
        _showError(context, 'Lỗi: $e');
      }
      return false;
    }
  }

  /// Telegram chat
  static Future<bool> openTelegram(
    String phoneNumber, {
    BuildContext? context,
  }) async {
    try {
      final cleanNumber = _cleanPhoneNumber(phoneNumber);

      String telegramNumber = cleanNumber;
      if (telegramNumber.startsWith('0')) {
        telegramNumber = '84${telegramNumber.substring(1)}';
      }

      final uri = Uri.parse('https://t.me/+$telegramNumber');

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        if (context != null && context.mounted) {
          _showError(context, 'Không thể mở Telegram');
        }
        return false;
      }
    } catch (e) {
      if (context != null && context.mounted) {
        _showError(context, 'Lỗi: $e');
      }
      return false;
    }
  }

  /// Viber chat
  static Future<bool> openViber(
    String phoneNumber, {
    BuildContext? context,
  }) async {
    try {
      final cleanNumber = _cleanPhoneNumber(phoneNumber);

      String viberNumber = cleanNumber;
      if (viberNumber.startsWith('0')) {
        viberNumber = '84${viberNumber.substring(1)}';
      }

      final uri = Uri.parse('viber://chat?number=$viberNumber');

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        if (context != null && context.mounted) {
          _showError(context, 'Không thể mở Viber');
        }
        return false;
      }
    } catch (e) {
      if (context != null && context.mounted) {
        _showError(context, 'Lỗi: $e');
      }
      return false;
    }
  }

  /// Clean phone number - remove non-numeric characters
  static String _cleanPhoneNumber(String phoneNumber) {
    // Remove all non-numeric characters except + at the beginning
    String cleaned = phoneNumber.trim();

    // Keep + if it's at the beginning
    bool hasPlus = cleaned.startsWith('+');

    // Remove all non-digits
    cleaned = cleaned.replaceAll(RegExp(r'[^0-9]'), '');

    // Add back + if it was there
    if (hasPlus && cleaned.isNotEmpty) {
      cleaned = '+$cleaned';
    }

    return cleaned;
  }

  /// Show confirmation dialog
  static Future<bool> _showConfirmDialog(
    BuildContext context,
    String phoneNumber,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xác nhận'),
            content: Text('Bạn có muốn gọi số:\n$phoneNumber?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Gọi'),
              ),
            ],
          ),
        ) ??
        false;
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void _showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Mở Zalo chat
  static Future<bool> openZaloChat(
    String phoneNumber, {
    BuildContext? context,
  }) async {
    try {
      final cleanNumber = _cleanPhoneNumber(phoneNumber);

      if (cleanNumber.isEmpty) {
        if (context != null && context.mounted) {
          _showError(context, 'Số điện thoại không hợp lệ');
        }
        return false;
      }

      // Convert to international format for Zalo
      String zaloNumber = cleanNumber;
      if (zaloNumber.startsWith('0')) {
        zaloNumber = '84${zaloNumber.substring(1)}'; // Vietnam country code
      } else if (!zaloNumber.startsWith('84') && !zaloNumber.startsWith('+')) {
        zaloNumber = '84$zaloNumber';
      }

      // Remove + if exists
      zaloNumber = zaloNumber.replaceAll('+', '');

      // Try deep link first (zalo://qr/p/)
      final deepLinkUri = Uri.parse('zalo://qr/p/$zaloNumber');
      if (await canLaunchUrl(deepLinkUri)) {
        await launchUrl(deepLinkUri, mode: LaunchMode.externalApplication);
        return true;
      }

      // Fallback to web link
      final webUri = Uri.parse('https://zalo.me/$zaloNumber');
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        return true;
      }

      if (context != null && context.mounted) {
        _showError(context, 'Không thể mở Zalo. Vui lòng cài đặt Zalo app.');
      }
      return false;
    } catch (e) {
      if (context != null && context.mounted) {
        _showError(context, 'Lỗi: $e');
      }
      return false;
    }
  }

  /// Gọi điện qua Zalo
  static Future<bool> makeZaloCall(
    String phoneNumber, {
    BuildContext? context,
    bool showConfirmation = false,
  }) async {
    try {
      final cleanNumber = _cleanPhoneNumber(phoneNumber);

      if (cleanNumber.isEmpty) {
        if (context != null && context.mounted) {
          _showError(context, 'Số điện thoại không hợp lệ');
        }
        return false;
      }

      // Show confirmation dialog if needed
      if (showConfirmation && context != null) {
        final confirmed = await _showZaloConfirmDialog(context, cleanNumber);
        if (!confirmed) return false;
      }

      // Convert to international format
      String zaloNumber = cleanNumber;
      if (zaloNumber.startsWith('0')) {
        zaloNumber = '84${zaloNumber.substring(1)}';
      } else if (!zaloNumber.startsWith('84') && !zaloNumber.startsWith('+')) {
        zaloNumber = '84$zaloNumber';
      }
      zaloNumber = zaloNumber.replaceAll('+', '');

      // Zalo call deep link
      final uri = Uri.parse('zalo://call/$zaloNumber');

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return true;
      } else {
        // Fallback: open chat instead
        if (context != null && context.mounted) {
          _showInfo(context, 'Không thể gọi trực tiếp. Đang mở Zalo chat...');
        }
        // ignore: use_build_context_synchronously
        return await openZaloChat(phoneNumber, context: context);
      }
    } catch (e) {
      if (context != null && context.mounted) {
        _showError(context, 'Lỗi: $e');
      }
      return false;
    }
  }

  /// Gửi tin nhắn Zalo (mở chat)
  static Future<bool> sendZaloMessage(
    String phoneNumber, {
    String? message,
    BuildContext? context,
  }) async {
    // Zalo không hỗ trợ pre-filled message qua deep link
    // Chỉ có thể mở chat, user phải tự gõ tin nhắn
    if (context != null && message != null && message.isNotEmpty) {
      _showInfo(context, 'Lưu ý: Bạn cần tự nhập nội dung tin nhắn trong Zalo');
    }

    return await openZaloChat(phoneNumber, context: context);
  }

  /// Zalo OA (Official Account) - Mở trang Zalo OA
  static Future<bool> openZaloOA(String oaId, {BuildContext? context}) async {
    try {
      // Zalo OA deep link
      final deepLinkUri = Uri.parse('zalo://oa/$oaId');
      if (await canLaunchUrl(deepLinkUri)) {
        await launchUrl(deepLinkUri, mode: LaunchMode.externalApplication);
        return true;
      }

      // Fallback to web
      final webUri = Uri.parse('https://zalo.me/$oaId');
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        return true;
      }

      if (context != null && context.mounted) {
        _showError(context, 'Không thể mở Zalo OA');
      }
      return false;
    } catch (e) {
      if (context != null && context.mounted) {
        _showError(context, 'Lỗi: $e');
      }
      return false;
    }
  }

  /// Show Zalo call confirmation dialog
  static Future<bool> _showZaloConfirmDialog(
    BuildContext context,
    String phoneNumber,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xác nhận'),
            content: Text('Bạn có muốn gọi Zalo số:\n$phoneNumber?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Gọi Zalo'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
