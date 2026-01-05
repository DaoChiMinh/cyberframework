import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:io';

class CyberConnectivityService {
  static final CyberConnectivityService _instance =
      CyberConnectivityService._internal();
  factory CyberConnectivityService() => _instance;
  CyberConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();

  /// ✅ Kiểm tra có kết nối internet không
  Future<List<ConnectivityResult>> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result;
    } catch (e) {
      return [ConnectivityResult.none];
    }
  }

  /// ✅ Kiểm tra có kết nối active không
  bool hasActiveConnection(List<ConnectivityResult> results) {
    return results.any(
      (result) =>
          result != ConnectivityResult.none &&
          result != ConnectivityResult.bluetooth,
    );
  }

  /// Kiểm tra internet có hoạt động thực sự không (ping Google)
  Future<bool> hasInternetConnection({
    Duration timeout = const Duration(seconds: 3), // ⚡ Giảm timeout
  }) async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(timeout);
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Kiểm tra tốc độ internet (trả về KB/s)
  /// Returns null nếu không thể test được
  Future<double?> checkInternetSpeed({
    String testUrl =
        'https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png',
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final stopwatch = Stopwatch()..start();

      final response = await http.get(Uri.parse(testUrl)).timeout(timeout);

      stopwatch.stop();

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes.length;
        final seconds = stopwatch.elapsedMilliseconds / 1000.0;
        final speedKBps = (bytes / 1024) / seconds;

        return speedKBps;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Kiểm tra có đang sử dụng VPN không
  Future<bool> isUsingVPN() async {
    try {
      if (Platform.isAndroid) {
        return await _checkVPNAndroid();
      } else if (Platform.isIOS) {
        return await _checkVPNiOS();
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check VPN trên Android
  Future<bool> _checkVPNAndroid() async {
    try {
      // Kiểm tra interfaces có vpn không
      final interfaces = await NetworkInterface.list();

      for (var interface in interfaces) {
        final name = interface.name.toLowerCase();
        if (name.contains('tun') ||
            name.contains('ppp') ||
            name.contains('pptp') ||
            name.contains('vpn')) {
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check VPN trên iOS
  Future<bool> _checkVPNiOS() async {
    try {
      // iOS check network interfaces
      final interfaces = await NetworkInterface.list();

      for (var interface in interfaces) {
        final name = interface.name.toLowerCase();
        // iOS VPN interfaces thường là utun, ipsec
        if (name.contains('utun') ||
            name.contains('ipsec') ||
            name.contains('ppp')) {
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// ✅ Lấy thông tin loại kết nối hiện tại
  String getConnectionType(List<ConnectivityResult> results) {
    if (!hasActiveConnection(results)) {
      return 'Không có kết nối';
    }

    final types = <String>[];
    for (var result in results) {
      switch (result) {
        case ConnectivityResult.wifi:
          types.add('WiFi');
          break;
        case ConnectivityResult.mobile:
          types.add('Dữ liệu di động');
          break;
        case ConnectivityResult.ethernet:
          types.add('Ethernet');
          break;
        case ConnectivityResult.vpn:
          types.add('VPN');
          break;
        case ConnectivityResult.other:
          types.add('Khác');
          break;
        default:
          break;
      }
    }

    return types.isEmpty ? 'Không xác định' : types.join(', ');
  }

  /// ⚡ OPTIMIZED: Fast check - chỉ check cơ bản (connectivity + ping)
  /// Dùng cho API calls thường xuyên (với cache)
  /// Thời gian: ~100-500ms thay vì 10s+
  Future<InternetCheckResult> performFastCheck({
    bool checkSpeed = false,
    double minimumSpeedKBps = 10.0,
  }) async {
    // 1. ✅ Kiểm tra connectivity (nhanh ~100ms)
    final connectivityResults = await checkConnectivity();
    if (!hasActiveConnection(connectivityResults)) {
      return InternetCheckResult(
        isValid: false,
        message:
            'Không có kết nối internet. Vui lòng kiểm tra WiFi hoặc dữ liệu di động.',
        errorType: InternetErrorType.noConnection,
        connectionType: 'Không có kết nối',
      );
    }

    // 2. ⚡ Quick ping check (timeout 3s thay vì 5s)
    final hasInternet = await hasInternetConnection(
      timeout: const Duration(seconds: 3),
    );
    if (!hasInternet) {
      return InternetCheckResult(
        isValid: false,
        message:
            'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối internet.',
        errorType: InternetErrorType.noInternet,
        connectionType: getConnectionType(connectivityResults),
      );
    }

    // 3. ⚡ Kiểm tra VPN (nhanh ~100ms)
    final isVPN = await isUsingVPN();

    // 4. ⚠️ Kiểm tra tốc độ CHỈ KHI được yêu cầu (chậm ~5s)
    if (checkSpeed) {
      final speed = await checkInternetSpeed();

      if (speed == null) {
        return InternetCheckResult(
          isValid: false,
          message: 'Không thể kiểm tra tốc độ internet. Vui lòng thử lại.',
          errorType: InternetErrorType.speedTestFailed,
          isUsingVPN: isVPN,
          connectionType: getConnectionType(connectivityResults),
        );
      }

      if (speed < minimumSpeedKBps) {
        return InternetCheckResult(
          isValid: false,
          message:
              'Kết nối internet quá chậm (${speed.toStringAsFixed(1)} KB/s). Tốc độ tối thiểu: ${minimumSpeedKBps.toStringAsFixed(0)} KB/s.',
          errorType: InternetErrorType.slowConnection,
          speed: speed,
          isUsingVPN: isVPN,
          connectionType: getConnectionType(connectivityResults),
        );
      }
    }

    // 5. ✅ Tất cả OK
    return InternetCheckResult(
      isValid: true,
      message: 'Kết nối internet ổn định',
      errorType: InternetErrorType.none,
      isUsingVPN: isVPN,
      connectionType: getConnectionType(connectivityResults),
    );
  }

  /// Kiểm tra toàn diện trước khi call API (CHẬM - dùng cho lần đầu)
  /// ⚠️ CHỈ dùng khi cần kiểm tra đầy đủ (login, first load, manual refresh)
  Future<InternetCheckResult> performFullCheck({
    double minimumSpeedKBps = 100.0,
    bool checkSpeed = true,
  }) async {
    // 1. ✅ Kiểm tra connectivity (version 7.0.0)
    final connectivityResults = await checkConnectivity();
    if (!hasActiveConnection(connectivityResults)) {
      return InternetCheckResult(
        isValid: false,
        message:
            'Không có kết nối internet. Vui lòng kiểm tra WiFi hoặc dữ liệu di động.',
        errorType: InternetErrorType.noConnection,
        connectionType: 'Không có kết nối',
      );
    }

    // 2. Kiểm tra internet thực sự có hoạt động không
    final hasInternet = await hasInternetConnection();
    if (!hasInternet) {
      return InternetCheckResult(
        isValid: false,
        message:
            'Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối internet.',
        errorType: InternetErrorType.noInternet,
        connectionType: getConnectionType(connectivityResults),
      );
    }

    // 3. Kiểm tra VPN
    final isVPN = await isUsingVPN();

    // 4. Kiểm tra tốc độ (nếu yêu cầu)
    if (checkSpeed) {
      final speed = await checkInternetSpeed();

      if (speed == null) {
        return InternetCheckResult(
          isValid: false,
          message: 'Không thể kiểm tra tốc độ internet. Vui lòng thử lại.',
          errorType: InternetErrorType.speedTestFailed,
          isUsingVPN: isVPN,
          connectionType: getConnectionType(connectivityResults),
        );
      }

      if (speed < minimumSpeedKBps) {
        return InternetCheckResult(
          isValid: false,
          message:
              'Kết nối internet quá chậm (${speed.toStringAsFixed(1)} KB/s). Tốc độ tối thiểu: ${minimumSpeedKBps.toStringAsFixed(0)} KB/s.',
          errorType: InternetErrorType.slowConnection,
          speed: speed,
          isUsingVPN: isVPN,
          connectionType: getConnectionType(connectivityResults),
        );
      }
    }

    // 5. Tất cả OK
    return InternetCheckResult(
      isValid: true,
      message: 'Kết nối internet ổn định',
      errorType: InternetErrorType.none,
      isUsingVPN: isVPN,
      connectionType: getConnectionType(connectivityResults),
    );
  }

  /// ✅ Stream để lắng nghe thay đổi kết nối (version 7.0.0)
  Stream<List<ConnectivityResult>> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged;
  }
}

/// Kết quả kiểm tra internet
class InternetCheckResult {
  final bool isValid;
  final String message;
  final InternetErrorType errorType;
  final double? speed; // KB/s
  final bool? isUsingVPN;
  final String? connectionType;

  InternetCheckResult({
    required this.isValid,
    required this.message,
    required this.errorType,
    this.speed,
    this.isUsingVPN,
    this.connectionType,
  });
}

/// Loại lỗi internet
enum InternetErrorType {
  none,
  noConnection,
  noInternet,
  slowConnection,
  speedTestFailed,
  vpnDisconnected,
}
