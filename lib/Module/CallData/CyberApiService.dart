import 'package:cyberframework/cyberframework.dart';
import 'package:http/http.dart' as http;

/// CyberApiService - Service call API với internet checking được tối ưu
/// ✅ OPTIMIZED: Cache internet check, giảm thời gian check từ 10s xuống < 1s
class CyberApiService {
  static final CyberApiService _instance = CyberApiService._internal();
  factory CyberApiService() => _instance;
  CyberApiService._internal();

  String baseUrl = 'https://mauiapidms.cybersoft.com.vn/api/CyberAPI';
  Duration timeout = const Duration(seconds: 30);

  // ✅ Cấu hình internet checking
  bool enableInternetCheck = true;
  bool enableSpeedCheck = false; // ⚡ MẶC ĐỊNH TẮT speed check (chậm)
  double minimumSpeedKBps = 10.0;

  // ✅ Lưu trạng thái VPN ban đầu
  bool? _initialVPNState;

  // ⚡ CACHE INTERNET CHECK (tránh check lại liên tục)
  InternetCheckResult? _cachedCheckResult;
  DateTime? _cacheTime;
  final Duration _cacheDuration = const Duration(seconds: 30); // Cache 30s

  // ⚡ Đang thực hiện check (tránh check song song)
  bool _isChecking = false;

  Future<ReturnData> _callApi({
    required BuildContext context,
    required CyberDataPost dataPost,
    bool showLoading = true,
    bool showError = true,
  }) async {
    // ⚡ KIỂM TRA INTERNET VỚI CACHE
    if (enableInternetCheck) {
      final checkResult = await _performInternetCheckWithCache(context);
      if (!checkResult.isValid) {
        // ✅ Show error TẠI ĐÂY, không show ở cuối nữa
        if (showError && context.mounted) {
          _showError(context, checkResult.message, checkResult.errorType);
        }
        return ReturnData(
          status: false,
          message: checkResult.message,
          isConnect: false,
        );
      }

      // Lưu trạng thái VPN lần đầu
      _initialVPNState ??= checkResult.isUsingVPN;
    }

    if (showLoading && context.mounted) {
      showLoadingOverlay(context);
    }

    try {
      final requestStr = await dataPost.convertToRequestString();
      final url = Uri.parse(baseUrl);

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Cyber-cetificate': await DeviceInfo.cetificate,
              'Cyber-Mac': await DeviceInfo.macdevice,
              'Access-Control-Allow-Origin': '*',
            },
            body: jsonEncode(requestStr),
          )
          .timeout(timeout);

      if (showLoading && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (response.statusCode != 200) {
        final returnData = ReturnData(
          status: false,
          message: 'Lỗi HTTP ${response.statusCode}: ${response.reasonPhrase}',
          isConnect: true,
        );

        if (showError && context.mounted) {
          _showError(context, returnData.message!, InternetErrorType.none);
        }

        return returnData;
      }

      String encryptedData = response.body;

      if (encryptedData == "" || encryptedData.isEmpty) {
        final returnData = ReturnData(
          status: false,
          message: 'Response không hợp lệ',
          isConnect: true,
        );

        if (showError && context.mounted) {
          _showError(context, returnData.message!, InternetErrorType.none);
        }

        return returnData;
      }

      final returnData = parseResponse(encryptedData);

      return returnData;
    } on SocketException {
      if (showLoading && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // ⚡ Invalidate cache khi có lỗi mạng
      _invalidateCache();

      // ✅ Kiểm tra có phải VPN disconnect hoặc mất internet không
      String errorMessage = 'Không thể kết nối đến máy chủ';
      InternetErrorType errorType = InternetErrorType.noConnection;

      // Kiểm tra lại kết nối hiện tại (NHANH - không check speed)
      final connectivity = CyberConnectivityService();
      final currentResults = await connectivity.checkConnectivity();

      // Kiểm tra có kết nối không
      if (!connectivity.hasActiveConnection(currentResults)) {
        errorMessage =
            'Mất kết nối internet. Vui lòng kiểm tra ${connectivity.getConnectionType(currentResults)}.';
        errorType = InternetErrorType.noConnection;
      }
      // Kiểm tra VPN có bị ngắt không
      else if (_initialVPNState == true) {
        final isStillVPN = await connectivity.isUsingVPN();
        if (!isStillVPN) {
          errorMessage = 'VPN đã ngắt kết nối. Vui lòng kết nối lại VPN.';
          errorType = InternetErrorType.vpnDisconnected;
        }
      }

      final returnData = ReturnData(
        status: false,
        message: errorMessage,
        isConnect: false,
      );

      if (showError && context.mounted) {
        _showError(context, returnData.message!, errorType);
      }

      return returnData;
    } on TimeoutException {
      if (showLoading && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      // ⚡ Invalidate cache khi timeout
      _invalidateCache();

      // ✅ Check lại internet khi timeout (NHANH)
      final connectivity = CyberConnectivityService();
      final currentResults = await connectivity.checkConnectivity();

      String errorMessage = 'Timeout: Máy chủ không phản hồi';
      InternetErrorType errorType = InternetErrorType.none;

      if (!connectivity.hasActiveConnection(currentResults)) {
        errorMessage = 'Mất kết nối internet trong khi đang gọi API.';
        errorType = InternetErrorType.noConnection;
      }

      final returnData = ReturnData(
        status: false,
        message: errorMessage,
        isConnect: false,
      );

      if (showError && context.mounted) {
        _showError(context, returnData.message!, errorType);
      }

      return returnData;
    } catch (e) {
      if (showLoading && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      final returnData = ReturnData(
        status: false,
        message: 'Lỗi: $e',
        isConnect: false,
      );

      if (showError && context.mounted) {
        _showError(context, returnData.message!, InternetErrorType.none);
      }

      return returnData;
    }
  }

  /// ⚡ OPTIMIZED: Kiểm tra internet với cache (giảm từ 10s xuống ~100ms)
  Future<InternetCheckResult> _performInternetCheckWithCache(
    BuildContext context,
  ) async {
    // ✅ Kiểm tra cache còn hiệu lực không
    if (_cachedCheckResult != null && _cacheTime != null) {
      final elapsed = DateTime.now().difference(_cacheTime!);
      if (elapsed < _cacheDuration) {
        // ⚡ Trả về kết quả từ cache (~0ms)
        return _cachedCheckResult!;
      }
    }

    // ✅ Tránh check song song (nếu đang check thì chờ)
    if (_isChecking) {
      // Chờ tối đa 5s
      int waited = 0;
      while (_isChecking && waited < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        waited++;
      }

      // Nếu có cache sau khi chờ thì dùng
      if (_cachedCheckResult != null) {
        return _cachedCheckResult!;
      }
    }

    // ✅ Thực hiện check mới
    _isChecking = true;
    try {
      final connectivity = CyberConnectivityService();

      // ⚡ FAST CHECK: Chỉ check connectivity + ping (skip speed check)
      final result = await connectivity.performFastCheck(
        checkSpeed: enableSpeedCheck,
        minimumSpeedKBps: minimumSpeedKBps,
      );

      // Cache kết quả
      _cachedCheckResult = result;
      _cacheTime = DateTime.now();

      return result;
    } finally {
      _isChecking = false;
    }
  }

  /// ⚡ Xóa cache (gọi khi có lỗi mạng)
  void _invalidateCache() {
    _cachedCheckResult = null;
    _cacheTime = null;
  }

  Future<ReturnData> callApi({
    required BuildContext context,
    required CyberDataPost dataPost,
    bool showLoading = true,
    bool showError = true,
  }) async {
    ReturnData returnData = await _callApi(
      context: context,
      dataPost: dataPost,
      showLoading: showLoading,
      showError: showError,
    );

    // ✅ FIX: Chỉ show error nếu là lỗi từ SERVER (isConnect = true)
    // Nếu isConnect = false (lỗi mạng), đã show error ở trên rồi
    if (returnData.isValid() == false &&
        showError &&
        context.mounted &&
        returnData.isConnect == true) {
      // ← CHỈ show khi là lỗi server
      _showError(
        context,
        returnData.message ?? 'Lỗi từ máy chủ',
        InternetErrorType.none,
      );
    }

    return returnData;
  }

  /// ✅ Hiển thị lỗi với icon phù hợp và thông tin chi tiết
  void _showError(
    BuildContext context,
    String message,
    InternetErrorType errorType,
  ) {
    IconData icon;
    Color iconColor;
    String title;

    switch (errorType) {
      case InternetErrorType.noConnection:
      case InternetErrorType.noInternet:
        icon = Icons.wifi_off;
        iconColor = Colors.orange;
        title = 'Mất kết nối';
        break;
      case InternetErrorType.slowConnection:
        icon = Icons.network_check;
        iconColor = Colors.orange;
        title = 'Kết nối chậm';
        break;
      case InternetErrorType.vpnDisconnected:
        icon = Icons.vpn_key_off;
        iconColor = Colors.red;
        title = 'VPN ngắt kết nối';
        break;
      case InternetErrorType.speedTestFailed:
        icon = Icons.speed;
        iconColor = Colors.orange;
        title = 'Kiểm tra tốc độ thất bại';
        break;
      default:
        icon = Icons.error;
        iconColor = Colors.red;
        title = 'Lỗi';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  /// ✅ Reset cache & VPN state (gọi khi user reconnect VPN thủ công)
  void resetState() {
    _initialVPNState = null;
    _invalidateCache();
  }

  /// ⚡ Force refresh cache (gọi khi user pull-to-refresh)
  void forceRefresh() {
    _invalidateCache();
  }
}
