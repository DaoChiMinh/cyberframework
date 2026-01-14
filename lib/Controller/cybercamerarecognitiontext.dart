import 'package:cyberframework/cyberframework.dart';

/// Chế độ nhận diện text
enum TextRecognitionMode {
  auto, // Tự động nhận diện tất cả text
  manual, // Chỉ nhận diện khi tap
  continuous, // Nhận diện liên tục
}

/// Loại text cần nhận diện
enum TextFilterType {
  all, // Tất cả text
  numeric, // Chỉ số
  alphabetic, // Chỉ chữ
  alphanumeric, // Chữ và số
  custom, // Custom regex pattern
}

/// Kết quả nhận diện biển số xe
class LicensePlateResult {
  final String plateNumber;
  final String? province;
  final String? vehicleType;

  LicensePlateResult({
    required this.plateNumber,
    this.province,
    this.vehicleType,
  });

  @override
  String toString() {
    return 'LicensePlateResult(plate: $plateNumber, province: $province, type: $vehicleType)';
  }
}

class CyberCameraRecognitionText extends StatefulWidget {
  /// Callback khi nhận diện được text
  final Function(RecognizedTextResult)? onTextRecognized;

  /// Callback khi nhận diện được biển số (chỉ dùng khi isDocBienSo = true)
  final Function(LicensePlateResult)? onLicensePlateRecognized;

  /// Chiều cao của camera preview
  final double? height;

  /// Border radius
  final double? borderRadius;

  /// Debounce time (ms) giữa các lần nhận diện
  final int debounceMs;

  /// Bật flash/torch
  final bool torchEnabled;

  /// Chế độ nhận diện
  final TextRecognitionMode recognitionMode;

  /// Chế độ tap để scan
  final bool clickScan;

  /// Hiển thị status
  final bool showStatus;
  final Color statusTextColor;
  final Color statusBackgroundColor;

  /// Message configuration
  final String? message;
  final String Function()? messageGetter;
  final bool showMessage;
  final Color messageTextColor;
  final Color messageBackgroundColor;
  final String messagePosition;
  final double messageFontSize;
  final IconData? messageIcon;
  final int messageUpdateInterval;
  final int messageDuration;

  /// Sound configuration
  final bool playBeepSound;
  final double beepVolume;
  final SoundSourceType successSoundType;
  final String? successSoundPath;
  final SoundSourceType errorSoundType;
  final String? errorSoundPath;
  final SoundSourceType defaultSoundType;
  final String? defaultSoundPath;
  final String currentSoundMode;

  /// Text filter configuration
  final TextFilterType filterType;
  final String? customFilterPattern;

  /// Confidence threshold (0.0 - 1.0)
  /// Nếu null, sẽ tự động điều chỉnh theo device performance
  final double? confidenceThreshold;

  /// Frame skip - Bỏ qua N frames để tối ưu hiệu suất
  /// Nếu null, sẽ tự động điều chỉnh theo device performance
  /// High-end: 1, Medium: 3, Low-end: 5
  final int? frameSkipCount;

  /// Minimum text length để trigger callback
  final int minTextLength;

  /// Maximum text length để nhận diện
  final int? maxTextLength;

  /// Camera resolution preset
  /// Nếu null, sẽ tự động điều chỉnh theo device performance
  /// High-end: high, Medium: medium, Low-end: low
  final ResolutionPreset? resolutionPreset;

  /// Enable image stream optimization
  final bool enableImageStreamOptimization;

  /// Auto-detect device performance và điều chỉnh config
  /// Mặc định: true
  final bool autoDetectPerformance;

  /// Template để parse text thành structured data
  final TextTemplate? textTemplate;

  /// Callback với parsed data (nếu có template)
  /// Trả về cả RecognizedTextResult và Map<String, dynamic>
  final Function(RecognizedTextResult result, Map<String, dynamic>? parsedData)?
  onTextRecognizedWithTemplate;

  /// Fuzzy threshold cho template matching (0.0 - 1.0)
  final double templateFuzzyThreshold;

  /// Auto validate parsed data với template
  final bool autoValidateTemplate;

  /// Auto continue sau khi có kết quả
  /// true: tiếp tục quét sau khi có kết quả
  /// false: dừng lại sau khi có kết quả, click để tiếp tục
  final bool autoContinue;

  /// Chế độ đọc biển số xe
  /// true: Phân tích và trích xuất biển số xe Việt Nam
  /// false: Đọc text bình thường
  final bool isDocBienSo;

  const CyberCameraRecognitionText({
    super.key,
    this.onTextRecognized,
    this.onLicensePlateRecognized,
    this.textTemplate,
    this.onTextRecognizedWithTemplate,
    this.templateFuzzyThreshold = 0.7,
    this.autoValidateTemplate = true,
    this.height,
    this.borderRadius = 0,
    this.debounceMs = 1000,
    this.torchEnabled = false,
    this.recognitionMode = TextRecognitionMode.continuous,
    this.clickScan = true,
    this.showStatus = true,
    this.statusTextColor = Colors.white,
    this.statusBackgroundColor = Colors.black54,
    this.message,
    this.messageGetter,
    this.showMessage = true,
    this.messageTextColor = Colors.white,
    this.messageBackgroundColor = const Color(0xFF2196F3),
    this.messagePosition = 'bottom',
    this.messageFontSize = 16.0,
    this.messageIcon,
    this.messageUpdateInterval = 500,
    this.messageDuration = 2000,
    this.playBeepSound = true,
    this.beepVolume = 0.5,
    this.successSoundType = SoundSourceType.system,
    this.successSoundPath,
    this.errorSoundType = SoundSourceType.system,
    this.errorSoundPath,
    this.defaultSoundType = SoundSourceType.system,
    this.defaultSoundPath,
    this.currentSoundMode = 'default',
    this.filterType = TextFilterType.all,
    this.customFilterPattern,
    this.confidenceThreshold,
    this.frameSkipCount,
    this.minTextLength = 1,
    this.maxTextLength,
    this.resolutionPreset,
    this.enableImageStreamOptimization = true,
    this.autoDetectPerformance = true,
    this.autoContinue = true,
    this.isDocBienSo = false,
  });

  @override
  State<StatefulWidget> createState() => _CyberCameraRecognitionTextState();
}

class _CyberCameraRecognitionTextState extends State<CyberCameraRecognitionText>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  TextRecognizer? _textRecognizer;
  Timer? _debounceTimer;
  String? _lastRecognizedText;
  bool _isDisposed = false;
  bool _isRecognizing = false;
  bool _isProcessing = false;
  String _currentMessage = '';
  Timer? _messageUpdateTimer;
  String _temporaryMessage = '';
  Timer? _messageDurationTimer;
  bool _showTemporaryMessage = false;
  int _frameCount = 0;
  RecognizedTextResult? _lastResult;

  // Lưu parsed data cuối cùng để kiểm tra duplicate
  Map<String, dynamic>? _lastParsedData;

  // Auto-detected performance config
  late ResolutionPreset _effectiveResolution;
  late int _effectiveFrameSkip;
  late double _effectiveConfidence;
  late int _effectiveDebounce;
  bool _configInitialized = false;

  final AudioPlayer _audioPlayer = AudioPlayer();

  // Template parser (nếu có template)
  TextTemplateParser? _templateParser;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Initialize template parser nếu có
    if (widget.textTemplate != null) {
      _templateParser = TextTemplateParser(
        widget.textTemplate!,
        fuzzyThreshold: widget.templateFuzzyThreshold,
      );
    }

    _initializePerformanceConfig();
    _audioPlayer.setVolume(widget.beepVolume);
  }

  /// Initialize performance config (auto-detect hoặc use provided values)
  Future<void> _initializePerformanceConfig() async {
    if (widget.autoDetectPerformance) {
      // Auto-detect device performance
      final config = await DevicePerformanceDetector.getRecommendedConfig(
        resolutionPreset: widget.resolutionPreset,
        frameSkipCount: widget.frameSkipCount,
        confidenceThreshold: widget.confidenceThreshold,
        debounceMs: widget.debounceMs,
      );

      _effectiveResolution = config.resolutionPreset;
      _effectiveFrameSkip = config.frameSkipCount;
      _effectiveConfidence = config.confidenceThreshold;
      _effectiveDebounce = config.debounceMs;
    } else {
      // Use provided values or defaults
      _effectiveResolution = widget.resolutionPreset ?? ResolutionPreset.medium;
      _effectiveFrameSkip = widget.frameSkipCount ?? 3;
      _effectiveConfidence = widget.confidenceThreshold ?? 0.7;
      _effectiveDebounce = widget.debounceMs;
    }

    _configInitialized = true;

    // Initialize camera after config is ready
    await _initializeCamera();
    _initializeTextRecognizer();
    _updateMessage();
    if (widget.messageGetter != null) {
      _startMessageUpdateTimer();
    }
  }

  /// Initialize Camera với optimization
  Future<void> _initializeCamera() async {
    if (_isDisposed || !_configInitialized) return;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('No cameras available');
        return;
      }

      // Sử dụng camera sau (thường tốt hơn cho OCR)
      final camera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        _effectiveResolution,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420, // Tối ưu cho Android
      );

      // Khóa orientation thành portrait để tránh camera bị vỡ khi xoay ngang
      await _cameraController!.initialize();
      await _cameraController!.lockCaptureOrientation(
        DeviceOrientation.portraitUp,
      );

      if (_isDisposed) {
        await _cameraController?.dispose();
        return;
      }

      // Set flash mode
      if (widget.torchEnabled) {
        try {
          await _cameraController!.setFlashMode(FlashMode.torch);
        } catch (e) {
          debugPrint('Flash not supported: $e');
        }
      }

      // Start image stream nếu ở chế độ continuous
      if (widget.recognitionMode == TextRecognitionMode.continuous) {
        _startImageStream();
      }

      if (mounted) {
        setState(() {
          _isRecognizing =
              widget.recognitionMode == TextRecognitionMode.continuous;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  /// Initialize Text Recognizer
  /// Chỉ nhận diện tiếng Việt và tiếng Anh
  void _initializeTextRecognizer() {
    if (_isDisposed) return;

    try {
      // Sử dụng latin script để hỗ trợ tiếng Việt và tiếng Anh
      _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    } catch (e) {
      debugPrint('Error initializing text recognizer: $e');
    }
  }

  /// Start image stream với frame skipping để tối ưu performance
  void _startImageStream() {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isDisposed) {
      return;
    }

    try {
      _cameraController!.startImageStream((CameraImage image) {
        // Frame skipping để giảm tải CPU
        _frameCount++;
        if (_frameCount % (_effectiveFrameSkip + 1) != 0) {
          return;
        }

        // Chỉ xử lý nếu không đang xử lý frame khác
        if (!_isProcessing) {
          _processImage(image);
        }
      });
    } catch (e) {}
  }

  /// Stop image stream
  Future<void> _stopImageStream() async {
    if (_cameraController == null || _isDisposed) return;

    try {
      await _cameraController!.stopImageStream();
    } catch (e) {}
  }

  /// Process camera image để nhận diện text
  Future<void> _processImage(CameraImage image) async {
    if (_isDisposed || _isProcessing || _textRecognizer == null) return;

    _isProcessing = true;

    try {
      // Convert CameraImage to InputImage
      final inputImage = _convertCameraImageToInputImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      // Nhận diện text
      final recognizedText = await _textRecognizer!.processImage(inputImage);

      // Dispose inputImage để giải phóng bộ nhớ
      inputImage.metadata?.rotation;

      if (_isDisposed || !mounted) {
        _isProcessing = false;
        return;
      }

      // Xử lý kết quả
      _handleRecognizedText(recognizedText);
    } catch (e) {
    } finally {
      _isProcessing = false;
    }
  }

  /// Convert CameraImage sang InputImage
  InputImage? _convertCameraImageToInputImage(CameraImage image) {
    if (_cameraController == null) return null;

    try {
      final camera = _cameraController!.description;
      final sensorOrientation = camera.sensorOrientation;

      InputImageRotation? rotation;
      if (Platform.isIOS) {
        rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
      } else if (Platform.isAndroid) {
        var rotationCompensation = sensorOrientation;
        final orientations = {
          DeviceOrientation.portraitUp: 0,
          DeviceOrientation.landscapeLeft: 90,
          DeviceOrientation.portraitDown: 180,
          DeviceOrientation.landscapeRight: 270,
        };

        final orientation = _cameraController!.value.deviceOrientation;
        rotationCompensation =
            (rotationCompensation - (orientations[orientation] ?? 0) + 360) %
            360;
        rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
      }

      if (rotation == null) return null;

      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;

      final plane = image.planes.first;

      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  /// Xử lý text đã nhận diện
  void _handleRecognizedText(RecognizedText recognizedText) {
    if (_isDisposed) return;

    // Extract toàn bộ text
    final fullText = recognizedText.text.trim();

    if (fullText.isEmpty) return;

    // Nếu là chế độ đọc biển số
    if (widget.isDocBienSo) {
      _handleLicensePlateRecognition(fullText, recognizedText);
      return;
    }

    // Apply text filter cho chế độ bình thường
    final filteredText = _applyTextFilter(fullText);
    if (filteredText == null || filteredText.isEmpty) return;

    // Check length constraints
    if (filteredText.length < widget.minTextLength) return;
    if (widget.maxTextLength != null &&
        filteredText.length > widget.maxTextLength!) {
      return;
    }

    // Check debounce
    if (_lastRecognizedText == filteredText &&
        _debounceTimer?.isActive == true) {
      return;
    }

    _debounceTimer?.cancel();
    _lastRecognizedText = filteredText;

    // Calculate average confidence
    double totalConfidence = 0;
    int blockCount = 0;
    for (var block in recognizedText.blocks) {
      for (var line in block.lines) {
        // ML Kit không cung cấp confidence trực tiếp, sử dụng heuristic
        totalConfidence += 1.0; // Placeholder
        blockCount++;
      }
    }
    final avgConfidence = blockCount > 0 ? totalConfidence / blockCount : 0.0;

    // Check confidence threshold
    if (avgConfidence < _effectiveConfidence) return;

    // Create result
    final result = RecognizedTextResult(
      text: filteredText,
      fullText: fullText,
      confidence: avgConfidence,
      blocks: recognizedText.blocks,
      timestamp: DateTime.now(),
    );

    _lastResult = result;

    // Play sound
    _playBeep();

    // Show message
    if (widget.messageDuration > 0) {
      _displayTemporaryMessage(
        '✅ Nhận diện: ${filteredText.length > 30 ? '${filteredText.substring(0, 30)}...' : filteredText}',
      );
    }

    // Callback with template parsing
    bool shouldStopRecognition =
        false; // Flag để quyết định có dừng camera không

    if (_templateParser != null &&
        widget.onTextRecognizedWithTemplate != null) {
      // Parse với template
      final parsedData = _templateParser!.parse(result.fullText);

      // Validate nếu autoValidate enabled
      if (widget.autoValidateTemplate) {
        if (_templateParser!.validate(parsedData)) {
          // ✅ Template match thành công

          // Kiểm tra xem parsed data có giống với lần trước không
          if (_isParsedDataDifferent(parsedData, _lastParsedData)) {
            // Đây là kết quả MỚI, callback và lưu lại
            _lastParsedData = Map<String, dynamic>.from(parsedData);
            widget.onTextRecognizedWithTemplate!.call(result, parsedData);
            shouldStopRecognition = true; // Cho phép dừng camera
          } else {
            // Kết quả TRÙNG với lần trước, không callback
            debugPrint('Duplicate parsed data - Skipping callback');

            // Nếu autoContinue = false, vẫn dừng camera (đã tìm thấy rồi)
            shouldStopRecognition = true;
          }
        } else {
          // ❌ Template không match, KHÔNG dừng camera
          debugPrint('Template validation failed - Continuing to scan...');

          // Vẫn có thể gọi callback onTextRecognized nếu có (để debug)
          widget.onTextRecognized?.call(result);

          // Reset debounce ngay để tiếp tục scan
          _lastRecognizedText = null;
          return; // Không dừng camera, tiếp tục scan
        }
      } else {
        // Không validate, kiểm tra duplicate và trả về data
        if (_isParsedDataDifferent(parsedData, _lastParsedData)) {
          _lastParsedData = Map<String, dynamic>.from(parsedData);
          widget.onTextRecognizedWithTemplate!.call(result, parsedData);
        }
        shouldStopRecognition = true;
      }
    } else {
      // Normal callback (không có template), cho phép dừng
      widget.onTextRecognized?.call(result);
      shouldStopRecognition = true;
    }

    // Debounce timer
    _debounceTimer = Timer(Duration(milliseconds: _effectiveDebounce), () {
      if (widget.recognitionMode == TextRecognitionMode.continuous) {
        _lastRecognizedText = null;
      }
    });

    // Xử lý autoContinue - CHỈ dừng nếu shouldStopRecognition = true
    if (shouldStopRecognition && !widget.autoContinue) {
      // Dừng nhận diện sau khi có kết quả HỢP LỆ
      _stopRecognizing();
    }

    // Stop nếu là manual mode và có kết quả hợp lệ
    if (widget.recognitionMode == TextRecognitionMode.manual &&
        shouldStopRecognition) {
      _stopRecognizing();
    }
  }

  /// Kiểm tra xem parsed data có khác với lần trước không
  bool _isParsedDataDifferent(
    Map<String, dynamic>? newData,
    Map<String, dynamic>? oldData,
  ) {
    if (newData == null && oldData == null) return false;
    if (newData == null || oldData == null) return true;

    // So sánh từng key-value
    if (newData.length != oldData.length) return true;

    for (var key in newData.keys) {
      if (!oldData.containsKey(key)) return true;
      if (newData[key] != oldData[key]) return true;
    }

    return false;
  }

  /// Xử lý nhận diện biển số xe
  void _handleLicensePlateRecognition(
    String fullText,
    RecognizedText recognizedText,
  ) {
    // Lọc và chuẩn hóa text cho biển số
    final cleanedText = _cleanTextForLicensePlate(fullText);

    // Pattern cho biển số Việt Nam
    // Format: XX-YYY ZZZ.ZZ hoặc XX YYY.ZZ
    // XX: 2 số hoặc chữ (mã tỉnh)
    // YYY: 1 chữ hoặc 2 số
    // ZZZ.ZZ: 5-6 số
    final platePattern = RegExp(
      r'(\d{2})[\s-]?([A-Z]{1,2}|\d{1,3})[\s.-]?(\d{4,6})',
      caseSensitive: false,
    );

    final match = platePattern.firstMatch(cleanedText);

    if (match != null) {
      final provinceCode = match.group(1);
      final series = match.group(2);
      final number = match.group(3);

      final plateNumber = '$provinceCode-$series $number';

      // Xác định tỉnh thành
      final province = _getProvinceFromCode(provinceCode ?? '');

      // Xác định loại xe (dựa vào series)
      String? vehicleType;
      if (series != null) {
        if (RegExp(r'^[A-Z]$').hasMatch(series)) {
          vehicleType = 'Xe con';
        } else if (RegExp(r'^\d{2}$').hasMatch(series)) {
          vehicleType = 'Xe tải/Xe khách';
        }
      }

      // Check debounce
      if (_lastRecognizedText == plateNumber &&
          _debounceTimer?.isActive == true) {
        return;
      }

      _debounceTimer?.cancel();
      _lastRecognizedText = plateNumber;

      final result = LicensePlateResult(
        plateNumber: plateNumber,
        province: province,
        vehicleType: vehicleType,
      );

      // Play sound
      _playBeep();

      // Show message
      if (widget.messageDuration > 0) {
        _displayTemporaryMessage('✅ Biển số: $plateNumber');
      }

      // Callback
      widget.onLicensePlateRecognized?.call(result);

      // Debounce timer
      _debounceTimer = Timer(Duration(milliseconds: _effectiveDebounce), () {
        _lastRecognizedText = null;
      });

      // Auto continue logic
      if (!widget.autoContinue) {
        _stopRecognizing();
      }
    }
  }

  /// Clean text để phù hợp với format biển số
  String _cleanTextForLicensePlate(String text) {
    // Loại bỏ các ký tự không cần thiết
    // Giữ lại: số, chữ cái, dấu gạch ngang, dấu chấm, khoảng trắng
    return text
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9\s.\-]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Get province name from code
  String? _getProvinceFromCode(String code) {
    final provinces = {
      '11': 'Hà Nội',
      '12': 'Hà Giang',
      '14': 'Tuyên Quang',
      '15': 'Hải Phòng',
      '16': 'Hải Dương',
      '17': 'Thái Bình',
      '18': 'Nam Định',
      '19': 'Phú Thọ',
      '20': 'Thái Nguyên',
      '21': 'Yên Bái',
      '22': 'Tuyên Quang',
      '23': 'Hà Giang',
      '24': 'Lào Cai',
      '25': 'Lai Châu',
      '26': 'Sơn La',
      '27': 'Điện Biên',
      '28': 'Hòa Bình',
      '29': 'Thanh Hóa',
      '30': 'Hà Tĩnh',
      '31': 'Nghệ An',
      '32': 'Quảng Bình',
      '33': 'Quảng Trị',
      '34': 'Thừa Thiên Huế',
      '35': 'Đà Nẵng',
      '36': 'Quảng Nam',
      '37': 'Quảng Ngãi',
      '38': 'Bình Định',
      '39': 'Gia Lai',
      '40': 'Kon Tum',
      '41': 'Đắk Lắk',
      '42': 'Đắk Nông',
      '43': 'Phú Yên',
      '47': 'Đắk Lắk',
      '48': 'Đắk Nông',
      '49': 'Lâm Đồng',
      '50': 'TP.HCM',
      '51': 'TP.HCM',
      '52': 'TP.HCM',
      '53': 'TP.HCM',
      '54': 'TP.HCM',
      '55': 'TP.HCM',
      '56': 'TP.HCM',
      '57': 'TP.HCM',
      '58': 'TP.HCM',
      '59': 'TP.HCM',
      '60': 'Đồng Nai',
      '61': 'Bình Dương',
      '62': 'Long An',
      '63': 'Tiền Giang',
      '64': 'Vĩnh Long',
      '65': 'Cần Thơ',
      '66': 'Đồng Tháp',
      '67': 'An Giang',
      '68': 'Kiên Giang',
      '69': 'Cà Mau',
      '70': 'Tây Ninh',
      '71': 'Bến Tre',
      '72': 'Bà Rịa - Vũng Tàu',
      '73': 'Quảng Bình',
      '74': 'Trà Vinh',
      '75': 'Hậu Giang',
      '76': 'Bạc Liêu',
      '77': 'Ninh Thuận',
      '78': 'Bình Phước',
      '79': 'Bình Thuận',
      '80': 'TP.HCM (Ngoại thành)',
      '81': 'Bình Dương (Ngoại thành)',
      '82': 'Vĩnh Phúc',
      '83': 'Bắc Ninh',
      '84': 'Bắc Giang',
      '85': 'Sóc Trăng',
      '86': 'Cao Bằng',
      '88': 'Vĩnh Phúc',
      '89': 'Lạng Sơn',
      '90': 'Hà Nam',
      '92': 'Quảng Ninh',
      '93': 'Bắc Giang',
      '94': 'Bắc Kạn',
      '95': 'Thái Bình',
      '97': 'Bắc Ninh',
      '98': 'Hưng Yên',
      '99': 'Hải Dương',
    };

    return provinces[code];
  }

  /// Apply text filter dựa theo filterType
  String? _applyTextFilter(String text) {
    switch (widget.filterType) {
      case TextFilterType.numeric:
        // Chỉ giữ lại số
        return text.replaceAll(RegExp(r'[^\d]'), '');

      case TextFilterType.alphabetic:
        // Chỉ giữ lại chữ cái
        return text.replaceAll(RegExp(r'[^a-zA-Z\u00C0-\u1EF9]'), '');

      case TextFilterType.alphanumeric:
        // Chữ và số
        return text.replaceAll(RegExp(r'[^a-zA-Z0-9\u00C0-\u1EF9]'), '');

      case TextFilterType.custom:
        // Custom regex pattern
        if (widget.customFilterPattern != null) {
          try {
            final regex = RegExp(widget.customFilterPattern!);
            final matches = regex.allMatches(text);
            return matches.map((m) => m.group(0)).join('');
          } catch (e) {
            return text;
          }
        }
        return text;

      case TextFilterType.all:
      default:
        return text;
    }
  }

  /// Play beep sound
  Future<void> _playBeep() async {
    if (!widget.playBeepSound) return;

    try {
      String? soundPath;
      SoundSourceType sourceType = widget.defaultSoundType;

      // Determine sound based on mode
      switch (widget.currentSoundMode) {
        case 'success':
          soundPath = widget.successSoundPath;
          sourceType = widget.successSoundType;
          break;
        case 'error':
          soundPath = widget.errorSoundPath;
          sourceType = widget.errorSoundType;
          break;
        default:
          soundPath = widget.defaultSoundPath;
          sourceType = widget.defaultSoundType;
      }

      // Play sound
      if (soundPath != null) {
        if (sourceType == SoundSourceType.asset) {
          await _audioPlayer.play(AssetSource(soundPath));
        } else if (sourceType == SoundSourceType.file) {
          await _audioPlayer.play(DeviceFileSource(soundPath));
        } else {
          // System beep (fallback)
          await _audioPlayer.play(AssetSource('sounds/beep.mp3'));
        }
      } else {
        // Default system beep
        await _audioPlayer.play(AssetSource('sounds/beep.mp3'));
      }
    } catch (e) {
      // Ignore sound errors
    }
  }

  /// Update message
  void _updateMessage() {
    if (!mounted) return;

    setState(() {
      if (widget.messageGetter != null) {
        _currentMessage = widget.messageGetter!();
      } else if (widget.message != null) {
        _currentMessage = widget.message!;
      }
    });
  }

  /// Start message update timer
  void _startMessageUpdateTimer() {
    _messageUpdateTimer?.cancel();
    _messageUpdateTimer = Timer.periodic(
      Duration(milliseconds: widget.messageUpdateInterval),
      (_) => _updateMessage(),
    );
  }

  /// Display temporary message
  void _displayTemporaryMessage(String message) {
    if (!mounted) return;

    setState(() {
      _temporaryMessage = message;
      _showTemporaryMessage = true;
    });

    _messageDurationTimer?.cancel();
    _messageDurationTimer = Timer(
      Duration(milliseconds: widget.messageDuration),
      () {
        if (mounted) {
          setState(() {
            _showTemporaryMessage = false;
            _temporaryMessage = '';
          });
        }
      },
    );
  }

  /// Toggle recognizing state
  void _toggleRecognizing() {
    if (_isRecognizing) {
      _stopRecognizing();
    } else {
      _startRecognizing();
    }
  }

  /// Start recognizing
  void _startRecognizing() {
    if (!mounted || _isRecognizing) return;

    setState(() {
      _isRecognizing = true;
    });

    _startImageStream();
  }

  /// Stop recognizing
  void _stopRecognizing() {
    if (!mounted || !_isRecognizing) return;

    setState(() {
      _isRecognizing = false;
    });

    _stopImageStream();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _debounceTimer?.cancel();
    _messageUpdateTimer?.cancel();
    _messageDurationTimer?.cancel();
    _stopImageStream();
    _cameraController?.dispose();
    _textRecognizer?.close();
    _audioPlayer.dispose();
    super.dispose();
  }

  Widget _buildMessageWidget() {
    if (!widget.showMessage) return const SizedBox.shrink();

    String displayMessage = _showTemporaryMessage
        ? _temporaryMessage
        : _currentMessage;

    if (displayMessage.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.messageBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.messageIcon != null) ...[
            Icon(
              widget.messageIcon,
              color: widget.messageTextColor,
              size: widget.messageFontSize + 4,
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Text(
              displayMessage,
              style: TextStyle(
                color: widget.messageTextColor,
                fontSize: widget.messageFontSize,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionedMessage() {
    final messageWidget = _buildMessageWidget();
    switch (widget.messagePosition.toLowerCase()) {
      case 'top':
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Center(child: messageWidget),
        );
      case 'center':
        return Center(child: messageWidget);
      case 'bottom':
      default:
        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Center(child: messageWidget),
        );
    }
  }

  Widget _buildCameraPreview() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const SizedBox.shrink();
    }

    // Vì đã lock orientation ở portraitUp, camera sẽ luôn ổn định
    return CameraPreview(_cameraController!);
  }

  @override
  Widget build(BuildContext context) {
    // Show loading nếu config chưa init hoặc camera chưa ready
    if (!_configInitialized ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(widget.borderRadius!),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Đang khởi tạo camera...',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    Widget previewWidget = Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(widget.borderRadius!),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          _buildCameraPreview(),

          // Overlay khi không đang nhận diện
          if (!_isRecognizing)
            Container(
              color: Colors.black38,
              child: const Center(
                child: Icon(
                  Icons.pause_circle_outline,
                  size: 64,
                  color: Colors.white70,
                ),
              ),
            ),

          // Status indicator
          if (widget.showStatus)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: widget.statusBackgroundColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isRecognizing ? Icons.text_fields : Icons.pause,
                        color: widget.statusTextColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isRecognizing ? 'Đang nhận diện...' : 'Dừng nhận diện',
                        style: TextStyle(
                          color: widget.statusTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Message display
          _buildPositionedMessage(),

          // Tap to continue hint
          if (widget.clickScan && !_isRecognizing)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Chạm để tiếp tục nhận diện',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (widget.clickScan) {
      return GestureDetector(onTap: _toggleRecognizing, child: previewWidget);
    }

    return previewWidget;
  }
}

/// Kết quả nhận diện text
class RecognizedTextResult {
  final String text; // Filtered text
  final String fullText; // Full text trước khi filter
  final double confidence; // Độ tin cậy trung bình
  final List<TextBlock> blocks; // Text blocks từ ML Kit
  final DateTime timestamp;

  RecognizedTextResult({
    required this.text,
    required this.fullText,
    required this.confidence,
    required this.blocks,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'RecognizedTextResult(text: $text, confidence: $confidence, blocks: ${blocks.length})';
  }
}
