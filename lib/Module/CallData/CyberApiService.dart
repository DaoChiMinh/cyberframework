import 'package:cyberframework/cyberframework.dart';
import 'package:http/http.dart' as http;

/// CyberApiService - Service call API với internet checking
class CyberApiService {
  static final CyberApiService _instance = CyberApiService._internal();
  factory CyberApiService() => _instance;
  CyberApiService._internal();

  String baseUrl = 'https://mauiapidms.cybersoft.com.vn/api/CyberAPI';
  Duration timeout = const Duration(seconds: 30);

  // ✅ Cấu hình internet checking
  bool enableInternetCheck = true;
  bool enableSpeedCheck = true;
  double minimumSpeedKBps = 100.0;

  // ✅ Lưu trạng thái VPN ban đầu
  bool? _initialVPNState;

  Future<ReturnData> _callApi({
    required BuildContext context,
    required CyberDataPost dataPost,
    bool showLoading = true,
    bool showError = true,
  }) async {
    // ✅ KIỂM TRA INTERNET TRƯỚC KHI GỌI API
    if (enableInternetCheck) {
      final checkResult = await _performInternetCheck(context);
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

      // ✅ Kiểm tra có phải VPN disconnect hoặc mất internet không
      String errorMessage = 'Không thể kết nối đến máy chủ';
      InternetErrorType errorType = InternetErrorType.noConnection;

      // Kiểm tra lại kết nối hiện tại
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

      // ✅ Check lại internet khi timeout
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

  /// ✅ Kiểm tra internet trước khi call API
  Future<InternetCheckResult> _performInternetCheck(
    BuildContext context,
  ) async {
    final connectivity = CyberConnectivityService();

    final result = await connectivity.performFullCheck(
      minimumSpeedKBps: minimumSpeedKBps,
      checkSpeed: enableSpeedCheck,
    );

    return result;
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

    if (returnData.isValid() == false && showError && context.mounted) {
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

  /// ✅ Reset trạng thái VPN (gọi khi user reconnect VPN thủ công)
  void resetVPNState() {
    _initialVPNState = null;
  }
}
