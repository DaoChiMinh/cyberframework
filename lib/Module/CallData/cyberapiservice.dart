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

  String uploadFileUrl =
      'https://mauiapidms.cybersoft.com.vn/api/CyberAPIUploadFile';

  /// Upload files với list base64 và list file paths
  ///
  /// Tham số:
  /// - [base64List]: Danh sách string base64 của các file
  /// - [filePathList]: Danh sách file paths có cấu trúc: /SubFolder/FileName.FileType
  ///   + Nếu có subfolder: "/images/photo.jpg" => SubFolder: "images"
  ///   + Nếu không có subfolder: "photo.jpg" => SubFolder tự động sinh theo GUID
  ///
  /// Ví dụ:
  /// ```dart
  /// await context.uploadFiles(
  ///   base64List: [base64Image1, base64Image2],
  ///   filePathList: ['/images/photo1.jpg', 'document.pdf'],
  /// );
  /// ```
  Future<ReturnData> uploadFiles({
    required BuildContext context,
    required List<String> base64List,
    required List<String> filePathList,
    bool showLoading = true,
    bool showError = true,
  }) async {
    // Validate input
    if (base64List.length != filePathList.length) {
      return ReturnData(
        status: false,
        message: 'Số lượng base64 và file path không khớp',
        isConnect: false,
      );
    }

    if (base64List.isEmpty) {
      return ReturnData(
        status: false,
        message: 'Danh sách file trống',
        isConnect: false,
      );
    }

    // Tạo CyberApiFilePost từ lists
    final filePost = CyberApiFilePost.fromLists(
      base64List: base64List,
      filePathList: filePathList,
    );

    return await uploadFile(
      context: context,
      filePost: filePost,
      showLoading: showLoading,
      showError: showError,
    );
  }

  /// Upload file với CyberApiFilePost object
  Future<ReturnData> uploadFile({
    required BuildContext context,
    required CyberApiFilePost filePost,
    bool showLoading = true,
    bool showError = true,
  }) async {
    // ✅ Check if app is paused
    // if (_isAppPaused) {
    //   return ReturnData(
    //     status: false,
    //     message: 'App is in background',
    //     isConnect: false,
    //   );
    // }

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
      // Get server URL
      String serverUrl = await DeviceInfo.servername;
      if (serverUrl.isEmpty) {
        serverUrl = 'https://mauiapidms.cybersoft.com.vn/';
      }

      if (!serverUrl.endsWith("/")) {
        uploadFileUrl = "$serverUrl/api/CyberAPIUploadFile";
      } else {
        uploadFileUrl = "${serverUrl}api/CyberAPIUploadFile";
      }

      // Convert to request string
      final requestStr = await filePost.convertToRequestString();
      final url = Uri.parse(uploadFileUrl);

      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Cyber-cetificate': await DeviceInfo.cetificate,
              'Cyber-Mac': await DeviceInfo.macdevice,
              'Access-Control-Allow-Origin': '*',
            },
            body: requestStr,
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
      if (!returnData.isValid() && showError && context.mounted) {
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

  /// Upload 1 file đơn giản với file path
  ///
  /// Ví dụ:
  /// ```dart
  /// await context.uploadSingleFile(
  ///   base64Data: base64Image,
  ///   filePath: '/images/photo.jpg', // hoặc 'photo.jpg'
  /// );
  /// ```
  Future<ReturnData> uploadSingleFile({
    required BuildContext context,
    required String base64Data,
    required String filePath,
    bool showLoading = true,
    bool showError = true,
  }) async {
    return await uploadFiles(
      context: context,
      base64List: [base64Data],
      filePathList: [filePath],
      showLoading: showLoading,
      showError: showError,
    );
  }
  // ============================================================================
  // ✅ UPLOAD OBJECT - SMART AUTO-DETECTION
  // ============================================================================

  /// Upload nhiều objects với auto-detection
  ///
  /// Objects có thể là:
  /// - String file path: "/storage/photo.jpg"
  /// - String URL: "https://example.com/image.jpg"
  /// - String base64: "iVBORw0KGgoAAAANSUhEUgAA..."
  /// - File object: File('/path/to/file.jpg')
  /// - Uint8List / List<&gt;int&gt;>: bytes array
  /// - XFile: từ image_picker
  /// - UploadObject: custom wrapper
  ///
  /// Ví dụ:
  /// ```dart
  /// await context.uploadObjects(
  ///   objects: [
  ///     '/storage/photo1.jpg',                    // File path
  ///     'https://example.com/image.jpg',          // URL
  ///     base64String,                             // Base64
  ///     File('/path/file.pdf'),                   // File object
  ///     uint8List,                                // Bytes
  ///     xfileFromPicker,                          // XFile
  ///   ],
  ///   filePaths: [                                // Optional custom paths
  ///     '/photos/1.jpg',
  ///     '/downloads/image.jpg',
  ///     '/encoded/file.jpg',
  ///     '/files/document.pdf',
  ///     '/bytes/data.bin',
  ///     null,  // Auto generate
  ///   ],
  /// );
  /// ```
  Future<ReturnData> uploadObjects({
    required BuildContext context,
    required List<dynamic> objects,
    List<String?>? filePaths,
    bool showLoading = true,
    bool showError = true,
  }) async {
    // Validate input
    if (objects.isEmpty) {
      return ReturnData(
        status: false,
        message: 'Danh sách objects trống',
        isConnect: false,
      );
    }

    if (filePaths != null && filePaths.length != objects.length) {
      return ReturnData(
        status: false,
        message: 'Số lượng objects và filePaths không khớp',
        isConnect: false,
      );
    }

    try {
      // Convert objects sang UploadObject
      List<UploadObject> uploadObjects = [];

      for (int i = 0; i < objects.length; i++) {
        final obj = objects[i];
        final customPath = filePaths != null ? filePaths[i] : null;

        // Nếu đã là UploadObject thì dùng luôn
        if (obj is UploadObject) {
          uploadObjects.add(obj);
        } else {
          // Auto detect và tạo UploadObject
          uploadObjects.add(UploadObject.auto(obj, filePath: customPath));
        }
      }

      // Convert sang base64 và file paths
      List<String> base64List = [];
      List<String> filePathList = [];

      for (var uploadObj in uploadObjects) {
        try {
          // Convert sang base64
          final base64Data = await uploadObj.toBase64();
          base64List.add(base64Data);

          // Get file path
          final filePath = await uploadObj.getFilePath();
          filePathList.add(filePath);

          debugPrint('✅ Converted: ${uploadObj.sourceTypeName} → $filePath');
        } catch (e) {
          debugPrint('❌ Error converting ${uploadObj.sourceTypeName}: $e');

          if (showError && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi xử lý file: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }

          return ReturnData(
            status: false,
            message: 'Lỗi xử lý file: $e',
            isConnect: false,
          );
        }
      }

      // Upload using existing method
      return await uploadFiles(
        context: context,
        base64List: base64List,
        filePathList: filePathList,
        showLoading: showLoading,
        showError: showError,
      );
    } catch (e) {
      debugPrint('❌ Error in uploadObjects: $e');

      return ReturnData(status: false, message: 'Lỗi: $e', isConnect: false);
    }
  }

  /// Upload 1 object với auto-detection
  ///
  /// Object có thể là:
  /// - String file path
  /// - String URL
  /// - String base64
  /// - File object
  /// - Bytes array
  /// - XFile
  /// - UploadObject
  ///
  /// Ví dụ:
  /// ```dart
  /// // Upload từ file path
  /// await context.uploadSingleObject(
  ///   object: '/storage/photo.jpg',
  ///   filePath: '/photos/vacation.jpg',
  /// );
  ///
  /// // Upload từ URL
  /// await context.uploadSingleObject(
  ///   object: 'https://example.com/image.jpg',
  /// );
  ///
  /// // Upload từ base64
  /// await context.uploadSingleObject(
  ///   object: base64String,
  ///   filePath: '/encoded/file.jpg',
  /// );
  ///
  /// // Upload từ File object
  /// await context.uploadSingleObject(
  ///   object: File('/path/to/file.pdf'),
  /// );
  /// ```
  Future<ReturnData> uploadSingleObject({
    required BuildContext context,
    required dynamic object,
    String? filePath,
    bool showLoading = true,
    bool showError = true,
  }) async {
    return await uploadObjects(
      context: context,
      objects: [object],
      filePaths: filePath != null ? [filePath] : null,
      showLoading: showLoading,
      showError: showError,
    );
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
