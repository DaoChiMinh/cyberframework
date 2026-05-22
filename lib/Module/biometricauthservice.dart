import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Loại sinh trắc học mà thiết bị hỗ trợ.
enum BiometricKind {
  /// FaceID (iOS) hoặc Face Unlock (Android)
  face,

  /// Touch ID (iOS) hoặc vân tay (Android)
  fingerprint,

  /// Quét mống mắt
  iris,

  /// Thiết bị có sinh trắc học nhưng không xác định rõ loại (Android strong/weak)
  unknown,

  /// Thiết bị không hỗ trợ / chưa đăng ký sinh trắc học
  none,
}

/// Kết quả của một lần xác thực.
class BiometricResult {
  final bool success;

  /// Mã lỗi có cấu trúc do local_auth 3.x trả về (null nếu không phải lỗi
  /// phát sinh từ quá trình authenticate, ví dụ khi thiết bị chưa hỗ trợ).
  final LocalAuthExceptionCode? errorCode;

  /// Thông điệp thân thiện để hiển thị cho người dùng.
  final String? message;

  const BiometricResult._({
    required this.success,
    this.errorCode,
    this.message,
  });

  factory BiometricResult.ok() => const BiometricResult._(success: true);

  factory BiometricResult.fail(
    String message, {
    LocalAuthExceptionCode? code,
  }) => BiometricResult._(success: false, errorCode: code, message: message);

  /// True nếu thất bại do người dùng/hệ thống chủ động hủy (không phải lỗi thật).
  bool get isCancelled =>
      errorCode == LocalAuthExceptionCode.userCanceled ||
      errorCode == LocalAuthExceptionCode.systemCanceled;

  @override
  String toString() =>
      'BiometricResult(success: $success, code: ${errorCode?.name}, '
      'message: $message)';
}

class BiometricAuthService {
  final LocalAuthentication _auth;

  BiometricAuthService({LocalAuthentication? localAuth})
    : _auth = localAuth ?? LocalAuthentication();

  /// Kiểm tra thiết bị có hỗ trợ sinh trắc học và đã đăng ký hay chưa.
  Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  /// Lấy danh sách tất cả loại sinh trắc học đã đăng ký trên thiết bị.
  Future<List<BiometricKind>> getAvailableBiometrics() async {
    try {
      final types = await _auth.getAvailableBiometrics();
      return types.map(_mapType).toSet().toList();
    } on PlatformException {
      return const [];
    }
  }

  /// Lấy loại sinh trắc học chính của thiết bị.
  ///
  /// Ưu tiên: FaceID > vân tay > iris. Dùng để hiển thị icon/label
  /// phù hợp (ví dụ: hiện icon mặt cười hay icon vân tay).
  Future<BiometricKind> getPrimaryBiometric() async {
    final available = await getAvailableBiometrics();
    if (available.isEmpty) return BiometricKind.none;
    if (available.contains(BiometricKind.face)) return BiometricKind.face;
    if (available.contains(BiometricKind.fingerprint)) {
      return BiometricKind.fingerprint;
    }
    if (available.contains(BiometricKind.iris)) return BiometricKind.iris;
    return BiometricKind.unknown;
  }

  /// Thực hiện xác thực sinh trắc học.
  ///
  /// [reason] — lý do hiển thị cho người dùng (bắt buộc, nên rõ nghĩa).
  /// [biometricOnly] — true thì chỉ cho phép sinh trắc học, false thì
  ///   cho phép fallback sang mã PIN/mật khẩu thiết bị.
  /// [persistAcrossBackgrounding] — true thì phiên xác thực được giữ khi app
  ///   bị đưa xuống nền (ví dụ khi người dùng chuyển sang app khác lấy OTP).
  ///   Đây là tham số thay thế cho `stickyAuth` của các phiên bản 2.x.
  Future<BiometricResult> authenticate({
    required String reason,
    bool biometricOnly = true,
    bool persistAcrossBackgrounding = true,
    bool sensitiveTransaction = true,
  }) async {
    try {
      final available = await isAvailable();
      if (!available && biometricOnly) {
        return BiometricResult.fail('Thiết bị chưa thiết lập FaceID/vân tay.');
      }

      // local_auth 3.x: các tùy chọn được truyền trực tiếp dưới dạng tham số,
      // không còn gói trong AuthenticationOptions nữa.
      final ok = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: biometricOnly,
        persistAcrossBackgrounding: persistAcrossBackgrounding,
        sensitiveTransaction: sensitiveTransaction,
      );

      return ok
          ? BiometricResult.ok()
          : BiometricResult.fail(
              'Xác thực không thành công.',
              code: LocalAuthExceptionCode.userCanceled,
            );
    } on LocalAuthException catch (e) {
      // local_auth 3.x ném LocalAuthException với mã lỗi có cấu trúc.
      return _handleAuthException(e);
    } on PlatformException catch (e) {
      return BiometricResult.fail(e.message ?? 'Xác thực thất bại.');
    }
  }

  /// Hủy phiên xác thực đang chạy (nếu có). Hữu ích khi đóng màn hình.
  Future<void> cancel() async {
    try {
      await _auth.stopAuthentication();
    } on PlatformException {
      // bỏ qua
    }
  }

  // ---- Helpers ----

  BiometricKind _mapType(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return BiometricKind.face;
      case BiometricType.fingerprint:
        return BiometricKind.fingerprint;
      case BiometricType.iris:
        return BiometricKind.iris;
      case BiometricType.strong:
      case BiometricType.weak:
        // Android trả về strong/weak khi không phân biệt rõ loại.
        return BiometricKind.unknown;
    }
  }

  BiometricResult _handleAuthException(LocalAuthException e) {
    final String message;
    switch (e.code) {
      case LocalAuthExceptionCode.userCanceled:
      case LocalAuthExceptionCode.systemCanceled:
        message = 'Đã hủy xác thực.';
        break;
      case LocalAuthExceptionCode.noBiometricHardware:
        message = 'Thiết bị không có cảm biến sinh trắc học.';
        break;
      case LocalAuthExceptionCode.temporaryLockout:
        message = 'Đã thử sai quá nhiều lần. Vui lòng thử lại sau ít phút.';
        break;
      case LocalAuthExceptionCode.biometricLockout:
        message =
            'Sinh trắc học bị khóa. Vui lòng mở khóa bằng mã PIN/mật '
            'khẩu thiết bị.';
        break;
      default:
        // Các mã còn lại (chưa đăng ký vân tay/khuôn mặt, chưa đặt mã khóa
        // màn hình, lỗi không xác định...). e.description chứa mô tả gốc.
        message = e.description ?? 'Xác thực thất bại (${e.code.name}).';
    }
    return BiometricResult.fail(message, code: e.code);
  }
}
