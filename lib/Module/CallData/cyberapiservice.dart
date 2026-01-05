// lib/Module/CallData/CyberApiService.dart

import 'package:cyberframework/cyberframework.dart';
import 'package:http/http.dart' as http;

class CyberApiService with WidgetsBindingObserver {
  static final CyberApiService _instance = CyberApiService._internal();
  factory CyberApiService() => _instance;

  CyberApiService._internal() {
    // ✅ Register lifecycle observer
    WidgetsBinding.instance.addObserver(this);
  }

  // ============================================================================
  // CONFIGURATION
  // ============================================================================

  String baseUrl = 'https://mauiapidms.cybersoft.com.vn/api/CyberAPI';
  Duration timeout = const Duration(seconds: 30);

  bool enableInternetCheck = true;
  bool enableSpeedCheck = false; // ⚡ Disabled by default (slow)
  double minimumSpeedKBps = 4.0;

  // ============================================================================
  // STATE MANAGEMENT
  // ============================================================================

  bool? _initialVPNState;
  InternetCheckResult? _cachedCheckResult;
  DateTime? _cacheTime;
  bool _isChecking = false;
  bool _isAppPaused = false; // ✅ Track app state

  final Duration _cacheDuration = const Duration(seconds: 30);
  Timer? _cacheCleanupTimer; // ✅ Timer to cleanup old cache

  // ============================================================================
  // ✅ LIFECYCLE MANAGEMENT
  // ============================================================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // ✅ App returned to foreground
        _isAppPaused = false;
        _invalidateCache(); // Refresh cache when app resumes
        _startCacheCleanupTimer();
        break;

      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // ✅ App in background
        _isAppPaused = true;
        _stopCacheCleanupTimer();
        break;
    }
  }

  /// ✅ Start cache cleanup timer
  void _startCacheCleanupTimer() {
    _stopCacheCleanupTimer();

    _cacheCleanupTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _cleanupExpiredCache(),
    );
  }

  /// ✅ Stop cache cleanup timer
  void _stopCacheCleanupTimer() {
    _cacheCleanupTimer?.cancel();
    _cacheCleanupTimer = null;
  }

  /// ✅ Clean up expired cache
  void _cleanupExpiredCache() {
    if (_cachedCheckResult != null && _cacheTime != null) {
      final elapsed = DateTime.now().difference(_cacheTime!);
      if (elapsed >= _cacheDuration) {
        _invalidateCache();
      }
    }
  }

  // ============================================================================
  // ✅ API CALL WITH PROPER ERROR HANDLING
  // ============================================================================

  Future<ReturnData> callApi({
    required BuildContext context,
    required CyberDataPost dataPost,
    bool showLoading = true,
    bool showError = true,
  }) async {
    // ✅ Check if app is paused
    if (_isAppPaused) {
      return ReturnData(
        status: false,
        message: 'App is in background',
        isConnect: false,
      );
    }

    return await _callApi(
      context: context,
      dataPost: dataPost,
      showLoading: showLoading,
      showError: showError,
    );
  }

  Future<ReturnData> _callApi({
    required BuildContext context,
    required CyberDataPost dataPost,
    bool showLoading = true,
    bool showError = true,
  }) async {
    // ⚡ Internet check with cache
    if (enableInternetCheck) {
      final checkResult = await _performInternetCheckWithCache(context);
      if (!checkResult.isValid) {
        if (showError && context.mounted) {
          _showError(context, checkResult.message, checkResult.errorType);
        }
        return ReturnData(
          status: false,
          message: checkResult.message,
          isConnect: false,
        );
      }

      _initialVPNState ??= checkResult.isUsingVPN;
    }

    if (showLoading && context.mounted) {
      showLoadingOverlay(context);
    }

    try {
      final requestStr = await dataPost.convertToRequestString();
      baseUrl = await DeviceInfo.servername;
      if (baseUrl == "") {
        baseUrl = 'https://mauiapidms.cybersoft.com.vn/';
      }

      if (!baseUrl.endsWith("/")) {
        baseUrl = "$baseUrl/api/CyberAPI";
      } else {
        baseUrl = "${baseUrl}api/CyberAPI";
      }

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
          message: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          isConnect: true,
        );

        if (showError && context.mounted) {
          _showError(context, returnData.message!, InternetErrorType.none);
        }

        return returnData;
      }

      final encryptedData = response.body;

      if (encryptedData.isEmpty) {
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

      // ✅ Show server error if needed
      if (!returnData.isValid() &&
          showError &&
          context.mounted &&
          returnData.isConnect == true) {
        _showError(
          context,
          returnData.message ?? 'Lỗi từ máy chủ',
          InternetErrorType.none,
        );
      }

      return returnData;
    } on SocketException {
      if (showLoading && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      _invalidateCache();

      final errorInfo = await _analyzeNetworkError();
      final returnData = ReturnData(
        status: false,
        message: errorInfo.message,
        isConnect: false,
      );

      if (showError && context.mounted) {
        _showError(context, errorInfo.message, errorInfo.errorType);
      }

      return returnData;
    } on TimeoutException {
      if (showLoading && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      _invalidateCache();

      final errorInfo = await _analyzeTimeoutError();
      final returnData = ReturnData(
        status: false,
        message: errorInfo.message,
        isConnect: false,
      );

      if (showError && context.mounted) {
        _showError(context, errorInfo.message, errorInfo.errorType);
      }

      return returnData;
    } catch (e) {
      if (showLoading && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      final returnData = ReturnData(
        status: false,
        message: 'Error: $e',
        isConnect: false,
      );

      if (showError && context.mounted) {
        _showError(context, returnData.message!, InternetErrorType.none);
      }

      return returnData;
    }
  }

  Future<InternetCheckResult> _performInternetCheckWithCache(
    BuildContext context,
  ) async {
    // ✅ Check cache validity
    if (_cachedCheckResult != null && _cacheTime != null) {
      final elapsed = DateTime.now().difference(_cacheTime!);
      if (elapsed < _cacheDuration) {
        return _cachedCheckResult!;
      }
    }

    // ✅ Avoid parallel checks
    if (_isChecking) {
      int waited = 0;
      while (_isChecking && waited < 50) {
        await Future.delayed(const Duration(milliseconds: 100));
        waited++;
      }

      if (_cachedCheckResult != null) {
        return _cachedCheckResult!;
      }
    }

    // ✅ Perform new check
    _isChecking = true;
    try {
      final connectivity = CyberConnectivityService();

      final result = await connectivity.performFastCheck(
        checkSpeed: enableSpeedCheck,
        minimumSpeedKBps: minimumSpeedKBps,
      );

      // Cache result
      _cachedCheckResult = result;
      _cacheTime = DateTime.now();

      // ✅ Start cleanup timer if not running
      if (_cacheCleanupTimer == null && !_isAppPaused) {
        _startCacheCleanupTimer();
      }

      return result;
    } finally {
      _isChecking = false;
    }
  }

  void _invalidateCache() {
    _cachedCheckResult = null;
    _cacheTime = null;
  }

  Future<_ErrorInfo> _analyzeNetworkError() async {
    final connectivity = CyberConnectivityService();
    final currentResults = await connectivity.checkConnectivity();

    if (!connectivity.hasActiveConnection(currentResults)) {
      return _ErrorInfo(
        message:
            'Mất kết nối internet. Vui lòng kiểm tra ${connectivity.getConnectionType(currentResults)}.',
        errorType: InternetErrorType.noConnection,
      );
    }

    if (_initialVPNState == true) {
      final isStillVPN = await connectivity.isUsingVPN();
      if (!isStillVPN) {
        return _ErrorInfo(
          message: 'VPN đã ngắt kết nối. Vui lòng kết nối lại VPN.',
          errorType: InternetErrorType.vpnDisconnected,
        );
      }
    }

    return _ErrorInfo(
      message: 'Không thể kết nối đến máy chủ',
      errorType: InternetErrorType.noConnection,
    );
  }

  Future<_ErrorInfo> _analyzeTimeoutError() async {
    final connectivity = CyberConnectivityService();
    final currentResults = await connectivity.checkConnectivity();

    if (!connectivity.hasActiveConnection(currentResults)) {
      return _ErrorInfo(
        message: 'Mất kết nối internet trong khi đang gọi API.',
        errorType: InternetErrorType.noConnection,
      );
    }

    return _ErrorInfo(
      message: 'Timeout: Máy chủ không phản hồi',
      errorType: InternetErrorType.none,
    );
  }

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

  void resetState() {
    _initialVPNState = null;
    _invalidateCache();
  }

  /// Force refresh cache
  void forceRefresh() {
    _invalidateCache();
  }

  String dnsUrl = 'https://mauiapisys.cybersoft.com.vn/api/DsDonVi';

  Future<ReturnData> v_dns({
    required BuildContext context,
    String dns = '',
    bool showLoading = true,
    bool showError = true,
  }) async {
    // ✅ Check if app is paused
    if (_isAppPaused) {
      return ReturnData(
        status: false,
        message: 'App is in background',
        isConnect: false,
      );
    }

    // ⚡ Internet check with cache
    if (enableInternetCheck) {
      final checkResult = await _performInternetCheckWithCache(context);
      if (!checkResult.isValid) {
        if (showError && context.mounted) {
          _showError(context, checkResult.message, checkResult.errorType);
        }
        return ReturnData(
          status: false,
          message: checkResult.message,
          isConnect: false,
        );
      }

      _initialVPNState ??= checkResult.isUsingVPN;
    }

    if (showLoading && context.mounted) {
      showLoadingOverlay(context);
    }

    try {
      final url = Uri.parse(dnsUrl);

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Cyber-cetificate': await DeviceInfo.cetificate,
              'Cyber-Mac': await DeviceInfo.macdevice,
              'Access-Control-Allow-Origin': '*',
            },
            body: jsonEncode(dns),
          )
          .timeout(timeout);

      if (showLoading && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (response.statusCode != 200) {
        final returnData = ReturnData(
          status: false,
          message: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          isConnect: true,
        );

        if (showError && context.mounted) {
          _showError(context, returnData.message!, InternetErrorType.none);
        }

        return returnData;
      }

      final encryptedData = response.body;

      if (encryptedData.isEmpty) {
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

      // ✅ Show server error if needed
      if (!returnData.isValid() &&
          showError &&
          context.mounted &&
          returnData.isConnect == true) {
        _showError(
          context,
          returnData.message ?? 'Lỗi từ máy chủ',
          InternetErrorType.none,
        );
      }

      return returnData;
    } on SocketException {
      if (showLoading && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      _invalidateCache();

      final errorInfo = await _analyzeNetworkError();
      final returnData = ReturnData(
        status: false,
        message: errorInfo.message,
        isConnect: false,
      );

      if (showError && context.mounted) {
        _showError(context, errorInfo.message, errorInfo.errorType);
      }

      return returnData;
    } on TimeoutException {
      if (showLoading && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      _invalidateCache();

      final errorInfo = await _analyzeTimeoutError();
      final returnData = ReturnData(
        status: false,
        message: errorInfo.message,
        isConnect: false,
      );

      if (showError && context.mounted) {
        _showError(context, errorInfo.message, errorInfo.errorType);
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

  /// ✅ Cleanup (call when app terminates)
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopCacheCleanupTimer();
    _invalidateCache();
  }
}

/// Helper class for error info
class _ErrorInfo {
  final String message;
  final InternetErrorType errorType;

  _ErrorInfo({required this.message, required this.errorType});
}
