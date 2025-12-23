import 'package:cyberframework/cyberframework.dart';
import 'package:http/http.dart' as http;

/// CyberApiService - Service call API
class CyberApiService {
  static final CyberApiService _instance = CyberApiService._internal();
  factory CyberApiService() => _instance;
  CyberApiService._internal();
  String baseUrl = 'https://mauiapidms.cybersoft.com.vn/api/CyberAPI';
  Duration timeout = const Duration(seconds: 30);

  Future<ReturnData> _callApi({
    required BuildContext context,
    required CyberDataPost dataPost,
    bool showLoading = true,
    bool showError = true,
  }) async {
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
          _showError(context, returnData.message!);
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
          _showError(context, returnData.message!);
        }

        return returnData;
      }

      final returnData = parseResponse(encryptedData);

      return returnData;
    } on SocketException {
      if (showLoading && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      final returnData = ReturnData(
        status: false,
        message: 'Không thể kết nối đến máy chủ',
        isConnect: false,
      );

      if (showError && context.mounted) {
        _showError(context, returnData.message!);
      }

      return returnData;
    } on TimeoutException {
      if (showLoading && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      final returnData = ReturnData(
        status: false,
        message: 'Timeout: Máy chủ không phản hồi',
        isConnect: false,
      );

      if (showError && context.mounted) {
        _showError(context, returnData.message!);
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
        _showError(context, returnData.message!);
      }

      return returnData;
    }
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
      _showError(context, returnData.message ?? 'Lỗi từ máy chủ');
    }

    return returnData;
  }

  void _showError(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Lỗi'),
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
}
