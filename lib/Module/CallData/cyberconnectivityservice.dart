import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
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

  /// Lấy địa chỉ IP public của client
  ///
  /// Thử lần lượt nhiều service để đảm bảo độ tin cậy:
  /// - api.ipify.org (plain text)
  /// - api4.my-ip.io (JSON)
  /// - ipinfo.io/ip (plain text)
  ///
  /// Trả về IP string nếu thành công, null nếu thất bại.
  ///
  /// Ví dụ:
  /// ```dart
  /// final ip = await CyberConnectivityService().getPublicIP();
  /// print('Public IP: $ip'); // "203.113.x.x"
  /// ```
  Future<String?> getPublicIP({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final services = [
      _IPService(url: 'https://api.ipify.org', parser: (body) => body.trim()),
      _IPService(
        url: 'https://api4.my-ip.io/ip.txt',
        parser: (body) => body.trim(),
      ),
      _IPService(url: 'https://ipinfo.io/ip', parser: (body) => body.trim()),
    ];

    for (final service in services) {
      try {
        final response = await http
            .get(Uri.parse(service.url))
            .timeout(timeout);

        if (response.statusCode == 200) {
          final ip = service.parser(response.body);
          // Validate IP format (basic check)
          if (_isValidIP(ip)) {
            return ip;
          }
        }
      } catch (_) {
        // Thử service tiếp theo
        continue;
      }
    }

    return null;
  }

  /// Validate định dạng IPv4 / IPv6 cơ bản
  bool _isValidIP(String ip) {
    if (ip.isEmpty) return false;
    // IPv4
    final ipv4 = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
    if (ipv4.hasMatch(ip)) {
      final parts = ip.split('.');
      return parts.every((p) => int.tryParse(p) != null && int.parse(p) <= 255);
    }
    // IPv6 (basic)
    final ipv6 = RegExp(r'^[0-9a-fA-F:]+$');
    return ipv6.hasMatch(ip) && ip.contains(':');
  }

  // ============================================================================
  // 📍 LOCATION - LẤY TỌA ĐỘ THIẾT BỊ
  // ============================================================================

  /// Lấy tọa độ hiện tại của thiết bị
  ///
  /// Tự động xử lý:
  /// - Kiểm tra service location có bật không
  /// - Xin quyền nếu chưa có
  /// - Lấy vị trí với độ chính xác tùy chỉnh
  ///
  /// [accuracy] : Độ chính xác (mặc định: high ~10m)
  /// [timeout]  : Thời gian chờ tối đa (mặc định: 10s)
  ///
  /// Ví dụ:
  /// ```dart
  /// final result = await CyberConnectivityService().getCurrentLocation();
  ///
  /// if (result.isSuccess) {
  ///   print('Lat: ${result.latitude}');
  ///   print('Lng: ${result.longitude}');
  ///   print('Accuracy: ${result.accuracy}m');
  /// } else {
  ///   print('Error: ${result.errorMessage}');
  /// }
  /// ```
  Future<LocationResult> getCurrentLocation({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      // 1. Kiểm tra GPS service có bật không
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationResult.failure(
          errorType: LocationErrorType.serviceDisabled,
          errorMessage: 'Dịch vụ vị trí đang tắt. Vui lòng bật GPS và thử lại.',
        );
      }

      // 2. Kiểm tra & xin quyền
      final permissionResult = await _checkAndRequestPermission();
      if (!permissionResult.isGranted) {
        return LocationResult.failure(
          errorType: permissionResult.errorType,
          errorMessage: permissionResult.errorMessage,
        );
      }

      // 3. Lấy vị trí
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: timeout,
        ),
      );

      return LocationResult.success(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        altitude: position.altitude,
        speed: position.speed,
        heading: position.heading,
        timestamp: position.timestamp,
      );
    } on TimeoutException {
      return LocationResult.failure(
        errorType: LocationErrorType.timeout,
        errorMessage: 'Không thể lấy vị trí. Vui lòng thử lại.',
      );
    } on LocationServiceDisabledException {
      return LocationResult.failure(
        errorType: LocationErrorType.serviceDisabled,
        errorMessage: 'Dịch vụ vị trí đang tắt. Vui lòng bật GPS.',
      );
    } catch (e) {
      return LocationResult.failure(
        errorType: LocationErrorType.unknown,
        errorMessage: 'Lỗi lấy vị trí: $e',
      );
    }
  }

  /// Lấy tọa độ nhanh (ưu tiên tốc độ, độ chính xác thấp hơn)
  ///
  /// Dùng khi cần tọa độ nhanh, không cần chính xác cao.
  /// Timeout ngắn hơn (5s), accuracy: medium (~100m).
  ///
  /// Ví dụ:
  /// ```dart
  /// final result = await CyberConnectivityService().getLastKnownLocation();
  /// ```
  Future<LocationResult> getLastKnownLocation() async {
    try {
      // Thử lấy vị trí cuối cùng đã biết (cực nhanh, không cần GPS fix)
      final position = await Geolocator.getLastKnownPosition();

      if (position != null) {
        return LocationResult.success(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          altitude: position.altitude,
          speed: position.speed,
          heading: position.heading,
          timestamp: position.timestamp,
          isLastKnown: true,
        );
      }

      // Fallback: lấy vị trí mới với accuracy thấp hơn
      return await getCurrentLocation(
        accuracy: LocationAccuracy.medium,
        timeout: const Duration(seconds: 5),
      );
    } catch (e) {
      return LocationResult.failure(
        errorType: LocationErrorType.unknown,
        errorMessage: 'Lỗi lấy vị trí: $e',
      );
    }
  }

  /// Mở cài đặt location của thiết bị
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Mở cài đặt app (để user cấp quyền thủ công)
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  /// Kiểm tra và xin quyền location
  Future<_PermissionResult> _checkAndRequestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        return _PermissionResult(
          isGranted: false,
          errorType: LocationErrorType.permissionDenied,
          errorMessage: 'Quyền truy cập vị trí bị từ chối.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return _PermissionResult(
        isGranted: false,
        errorType: LocationErrorType.permissionDeniedForever,
        errorMessage:
            'Quyền truy cập vị trí bị từ chối vĩnh viễn. '
            'Vui lòng vào Cài đặt để cấp quyền.',
      );
    }

    return _PermissionResult(isGranted: true);
  }
}

/// Helper class cho kết quả kiểm tra quyền
class _PermissionResult {
  final bool isGranted;
  final LocationErrorType errorType;
  final String errorMessage;

  _PermissionResult({
    required this.isGranted,
    this.errorType = LocationErrorType.none,
    this.errorMessage = '',
  });
}
// ============================================================================
// 📍 LOCATION MODELS
// ============================================================================

/// Kết quả lấy tọa độ
class LocationResult {
  final bool isSuccess;

  // Tọa độ
  final double? latitude;
  final double? longitude;
  final double? accuracy; // meters
  final double? altitude; // meters
  final double? speed; // m/s
  final double? heading; // degrees (0-360)
  final DateTime? timestamp;

  // Trạng thái
  final bool isLastKnown; // true nếu là vị trí cached
  final LocationErrorType errorType;
  final String errorMessage;

  const LocationResult._({
    required this.isSuccess,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
    this.timestamp,
    this.isLastKnown = false,
    this.errorType = LocationErrorType.none,
    this.errorMessage = '',
  });

  factory LocationResult.success({
    required double latitude,
    required double longitude,
    double? accuracy,
    double? altitude,
    double? speed,
    double? heading,
    DateTime? timestamp,
    bool isLastKnown = false,
  }) {
    return LocationResult._(
      isSuccess: true,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      altitude: altitude,
      speed: speed,
      heading: heading,
      timestamp: timestamp ?? DateTime.now(),
      isLastKnown: isLastKnown,
    );
  }

  factory LocationResult.failure({
    required LocationErrorType errorType,
    required String errorMessage,
  }) {
    return LocationResult._(
      isSuccess: false,
      errorType: errorType,
      errorMessage: errorMessage,
    );
  }

  /// Tọa độ dạng Map (tiện để gửi API)
  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'altitude': altitude,
    'speed': speed,
    'heading': heading,
    'timestamp': timestamp?.toIso8601String(),
    'isLastKnown': isLastKnown,
  };

  /// Google Maps URL
  String? get googleMapsUrl {
    if (latitude == null || longitude == null) return null;
    return 'https://www.google.com/maps?q=$latitude,$longitude';
  }

  @override
  String toString() {
    if (!isSuccess) return 'LocationResult(error: $errorMessage)';
    return 'LocationResult(lat: $latitude, lng: $longitude, accuracy: ${accuracy?.toStringAsFixed(1)}m)';
  }
}

/// Loại lỗi location
enum LocationErrorType {
  none,
  serviceDisabled, // GPS tắt
  permissionDenied, // User từ chối lần này
  permissionDeniedForever, // User từ chối vĩnh viễn
  timeout, // Quá thời gian chờ
  unknown, // Lỗi khác
}

/// Helper để cấu hình IP service endpoint
class _IPService {
  final String url;
  final String Function(String body) parser;

  _IPService({required this.url, required this.parser});
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
