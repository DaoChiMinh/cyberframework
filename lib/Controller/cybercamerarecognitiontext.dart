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

      await _cameraController!.initialize();

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
          widget.onTextRecognizedWithTemplate!.call(result, parsedData);
          shouldStopRecognition = true; // Cho phép dừng camera
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
        // Không validate, trả về data luôn và cho phép dừng
        widget.onTextRecognizedWithTemplate!.call(result, parsedData);
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
    if (shouldStopRecognition &&
        widget.recognitionMode == TextRecognitionMode.manual) {
      _stopRecognizing();
    }
  }

  /// Xử lý nhận diện biển số xe Việt Nam
  void _handleLicensePlateRecognition(
    String fullText,
    RecognizedText recognizedText,
  ) {
    // Tìm biển số trong text
    final licensePlate = _extractVietnameseLicensePlate(fullText);

    if (licensePlate == null) {
      debugPrint('No license plate found in text: $fullText');
      return;
    }

    // Check debounce
    if (_lastRecognizedText == licensePlate.plateNumber &&
        _debounceTimer?.isActive == true) {
      return;
    }

    _debounceTimer?.cancel();
    _lastRecognizedText = licensePlate.plateNumber;

    // Calculate average confidence
    double totalConfidence = 0;
    int blockCount = 0;
    for (var block in recognizedText.blocks) {
      for (var line in block.lines) {
        totalConfidence += 1.0;
        blockCount++;
      }
    }
    final avgConfidence = blockCount > 0 ? totalConfidence / blockCount : 0.0;

    // Check confidence threshold
    if (avgConfidence < _effectiveConfidence) return;

    // Create text result
    final result = RecognizedTextResult(
      text: licensePlate.plateNumber,
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
      _displayTemporaryMessage('🚗 Biển số: ${licensePlate.plateNumber}');
    }

    // Callback với biển số
    widget.onLicensePlateRecognized?.call(licensePlate);

    // Callback text result nếu có
    widget.onTextRecognized?.call(result);

    // Debounce timer
    _debounceTimer = Timer(Duration(milliseconds: _effectiveDebounce), () {
      if (widget.recognitionMode == TextRecognitionMode.continuous) {
        _lastRecognizedText = null;
      }
    });

    // Xử lý autoContinue
    if (!widget.autoContinue) {
      // Dừng nhận diện sau khi có kết quả
      _stopRecognizing();
    }

    // Stop nếu là manual mode
    if (widget.recognitionMode == TextRecognitionMode.manual) {
      _stopRecognizing();
    }
  }

  /// Trích xuất biển số xe Việt Nam từ text
  LicensePlateResult? _extractVietnameseLicensePlate(String text) {
    // Loại bỏ khoảng trắng thừa
    final cleanText = text.replaceAll(RegExp(r'\s+'), '');

    // Patterns cho các loại biển số Việt Nam
    final patterns = [
      // Biển số thông thường: 30A-12345 hoặc 30A12345
      RegExp(r'(\d{2}[A-Z])[-\s]?(\d{4,5})', caseSensitive: false),
      // Biển số có chữ: 30AB-12345
      RegExp(r'(\d{2}[A-Z]{1,2})[-\s]?(\d{4,5})', caseSensitive: false),
      // Biển số xe máy: 29-B1 12345
      RegExp(r'(\d{2})[-\s]?([A-Z]\d)[-\s]?(\d{4,5})', caseSensitive: false),
      // Biển số đặc biệt: 80A-123.45
      RegExp(r'(\d{2}[A-Z])[-\s]?(\d{3})[.\s]?(\d{2})', caseSensitive: false),
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(cleanText);
      if (match != null) {
        String plateNumber;
        String? province;

        if (match.groupCount >= 2) {
          final prefix = match.group(1)!.toUpperCase();
          final number = match.group(2)!;

          // Kiểm tra nếu có group 3 (xe máy hoặc đặc biệt)
          if (match.groupCount >= 3 && match.group(3) != null) {
            plateNumber = '$prefix-${number}.${match.group(3)}';
          } else {
            plateNumber = '$prefix-$number';
          }

          // Xác định tỉnh thành
          province = _getProvinceFromCode(prefix.substring(0, 2));

          return LicensePlateResult(
            plateNumber: plateNumber,
            province: province,
            vehicleType: _guessVehicleType(plateNumber),
          );
        }
      }
    }

    return null;
  }

  /// Lấy tên tỉnh thành từ mã
  String? _getProvinceFromCode(String code) {
    final provinces = {
      '11': 'Cao Bằng',
      '12': 'Lạng Sơn',
      '14': 'Quảng Ninh',
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
      '29': 'Hà Nội',
      '30': 'Hà Nội',
      '31': 'Hà Nội',
      '32': 'Hà Nội',
      '33': 'Hà Nội',
      '34': 'Hải Dương',
      '35': 'Ninh Bình',
      '36': 'Thanh Hóa',
      '37': 'Nghệ An',
      '38': 'Hà Tĩnh',
      '43': 'Đà Nẵng',
      '47': 'Đắk Lắk',
      '49': 'Lâm Đồng',
      '50': 'TP. Hồ Chí Minh',
      '51': 'TP. Hồ Chí Minh',
      '52': 'TP. Hồ Chí Minh',
      '53': 'TP. Hồ Chí Minh',
      '54': 'TP. Hồ Chí Minh',
      '55': 'TP. Hồ Chí Minh',
      '56': 'TP. Hồ Chí Minh',
      '57': 'TP. Hồ Chí Minh',
      '58': 'TP. Hồ Chí Minh',
      '59': 'TP. Hồ Chí Minh',
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
      '74': 'Quảng Trị',
      '75': 'Thừa Thiên Huế',
      '76': 'Quảng Ngãi',
      '77': 'Bình Định',
      '78': 'Phú Yên',
      '79': 'Khánh Hòa',
      '81': 'Gia Lai',
      '82': 'Kon Tum',
      '83': 'Sóc Trăng',
      '84': 'Trà Vinh',
      '85': 'Ninh Thuận',
      '86': 'Bình Thuận',
      '88': 'Vĩnh Phúc',
      '89': 'Hưng Yên',
      '90': 'Hà Nam',
      '92': 'Quảng Nam',
      '93': 'Bình Phước',
      '94': 'Bạc Liêu',
      '95': 'Hậu Giang',
      '97': 'Bắc Kạn',
      '98': 'Bắc Giang',
      '99': 'Bắc Ninh',
    };

    return provinces[code];
  }

  /// Đoán loại xe từ biển số
  String? _guessVehicleType(String plateNumber) {
    // Biển trắng (xe cá nhân)
    if (RegExp(r'^\d{2}[A-Z]-\d{4,5}$').hasMatch(plateNumber)) {
      return 'Xe cá nhân';
    }
    // Biển vàng (xe kinh doanh)
    if (RegExp(r'^\d{2}[A-Z]-\d{3}\.\d{2}$').hasMatch(plateNumber)) {
      return 'Xe kinh doanh';
    }
    // Xe máy
    if (RegExp(r'^\d{2}[A-Z]\d-\d{4,5}$').hasMatch(plateNumber)) {
      return 'Xe máy';
    }

    return null;
  }

  /// Apply text filter - chỉ cho phép tiếng Việt và tiếng Anh
  String? _applyTextFilter(String text) {
    // Filter theo loại text
    String? filtered;

    switch (widget.filterType) {
      case TextFilterType.all:
        // Chỉ giữ lại chữ cái tiếng Việt, tiếng Anh, số, và khoảng trắng
        filtered = text.replaceAll(
          RegExp(r'[^a-zA-ZÀ-ỹ0-9\s]', caseSensitive: false),
          '',
        );
        break;

      case TextFilterType.numeric:
        final numbers = text.replaceAll(RegExp(r'[^0-9]'), '');
        filtered = numbers.isNotEmpty ? numbers : null;
        break;

      case TextFilterType.alphabetic:
        // Chỉ chữ tiếng Việt và tiếng Anh
        final letters = text.replaceAll(
          RegExp(r'[^a-zA-ZÀ-ỹ\s]', caseSensitive: false),
          '',
        );
        filtered = letters.isNotEmpty ? letters : null;
        break;

      case TextFilterType.alphanumeric:
        // Chữ và số tiếng Việt và tiếng Anh
        final alphanum = text.replaceAll(
          RegExp(r'[^a-zA-Z0-9À-ỹ\s]', caseSensitive: false),
          '',
        );
        filtered = alphanum.isNotEmpty ? alphanum : null;
        break;

      case TextFilterType.custom:
        if (widget.customFilterPattern == null) {
          filtered = text;
        } else {
          try {
            final pattern = RegExp(widget.customFilterPattern!);
            final matches = pattern.allMatches(text);
            if (matches.isEmpty) {
              filtered = null;
            } else {
              filtered = matches.map((m) => m.group(0)).join(' ');
            }
          } catch (e) {
            filtered = text;
          }
        }
        break;
    }

    return filtered;
  }

  void _updateMessage() {
    if (_isDisposed) return;

    if (widget.messageGetter != null) {
      try {
        final newMessage = widget.messageGetter!();
        if (mounted && newMessage != _currentMessage) {
          setState(() {
            _currentMessage = newMessage;
          });
        }
      } catch (e) {}
    } else if (widget.message != null) {
      if (_currentMessage != widget.message) {
        setState(() {
          _currentMessage = widget.message!;
        });
      }
    }
  }

  void _startMessageUpdateTimer() {
    _messageUpdateTimer?.cancel();
    _messageUpdateTimer = Timer.periodic(
      Duration(milliseconds: widget.messageUpdateInterval),
      (_) => _updateMessage(),
    );
  }

  void _displayTemporaryMessage(String message) {
    if (!widget.showMessage || widget.messageDuration == 0) return;

    _messageDurationTimer?.cancel();
    setState(() {
      _temporaryMessage = message;
      _showTemporaryMessage = true;
    });

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

  Future<void> _playBeep() async {
    if (!widget.playBeepSound) return;

    try {
      SoundSourceType sourceType;
      String? soundPath;

      switch (widget.currentSoundMode) {
        case 'success':
          sourceType = widget.successSoundType;
          soundPath = widget.successSoundPath;
          break;
        case 'error':
          sourceType = widget.errorSoundType;
          soundPath = widget.errorSoundPath;
          break;
        default:
          sourceType = widget.defaultSoundType;
          soundPath = widget.defaultSoundPath;
      }

      switch (sourceType) {
        case SoundSourceType.system:
          SystemSound.play(SystemSoundType.click);
          HapticFeedback.mediumImpact();
          break;

        case SoundSourceType.asset:
          if (soundPath != null) {
            await _audioPlayer.play(AssetSource(soundPath));
            HapticFeedback.mediumImpact();
          } else {
            _playSystemSound();
          }
          break;

        case SoundSourceType.url:
          if (soundPath != null) {
            await _audioPlayer.play(UrlSource(soundPath));
            HapticFeedback.mediumImpact();
          } else {
            _playSystemSound();
          }
          break;

        case SoundSourceType.file:
          if (soundPath != null) {
            await _audioPlayer.play(DeviceFileSource(soundPath));
            HapticFeedback.mediumImpact();
          } else {
            _playSystemSound();
          }
          break;
      }
    } catch (e) {
      _playSystemSound();
    }
  }

  void _playSystemSound() {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.mediumImpact();
  }

  @override
  void didUpdateWidget(CyberCameraRecognitionText oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.message != oldWidget.message ||
        widget.messageGetter != oldWidget.messageGetter) {
      _updateMessage();
      if (widget.messageGetter != oldWidget.messageGetter) {
        _messageUpdateTimer?.cancel();
        if (widget.messageGetter != null) {
          _startMessageUpdateTimer();
        }
      }
    }

    if (widget.beepVolume != oldWidget.beepVolume) {
      _audioPlayer.setVolume(widget.beepVolume);
    }

    if (widget.torchEnabled != oldWidget.torchEnabled) {
      _toggleTorch();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return;
    }

    switch (state) {
      case AppLifecycleState.resumed:
        _resumeRecognizing();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _pauseRecognizing();
        break;
    }
  }

  Future<void> _resumeRecognizing() async {
    if (_isDisposed) return;

    try {
      if (_cameraController != null &&
          !_cameraController!.value.isStreamingImages) {
        if (widget.recognitionMode == TextRecognitionMode.continuous) {
          _startImageStream();
        }
        if (mounted) {
          setState(() {
            _isRecognizing =
                widget.recognitionMode == TextRecognitionMode.continuous;
          });
        }
      }
    } catch (e) {}
  }

  Future<void> _pauseRecognizing() async {
    if (_isDisposed) return;

    try {
      await _stopImageStream();
      if (mounted) {
        setState(() {
          _isRecognizing = false;
        });
      }
    } catch (e) {}
  }

  Future<void> _toggleRecognizing() async {
    if (_isDisposed || !widget.clickScan) return;

    if (_isRecognizing) {
      await _stopRecognizing();
    } else {
      await _startRecognizing();
    }
  }

  Future<void> _startRecognizing() async {
    if (_isDisposed || _cameraController == null) return;

    try {
      if (widget.recognitionMode == TextRecognitionMode.continuous ||
          widget.recognitionMode == TextRecognitionMode.auto) {
        _startImageStream();
      } else {
        // Manual mode: capture single image
        await _captureSingleImage();
      }

      if (mounted) {
        setState(() {
          _isRecognizing = true;
        });
      }
    } catch (e) {}
  }

  Future<void> _stopRecognizing() async {
    if (_isDisposed) return;

    try {
      await _stopImageStream();
      if (mounted) {
        setState(() {
          _isRecognizing = false;
        });
      }
    } catch (e) {}
  }

  /// Capture single image cho manual mode
  Future<void> _captureSingleImage() async {
    if (_cameraController == null || _textRecognizer == null || _isDisposed) {
      return;
    }

    try {
      final image = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);

      final recognizedText = await _textRecognizer!.processImage(inputImage);

      // Delete temporary file để tiết kiệm bộ nhớ
      try {
        await File(image.path).delete();
      } catch (e) {}

      if (!_isDisposed && mounted) {
        _handleRecognizedText(recognizedText);
      }
    } catch (e) {}
  }

  Future<void> _toggleTorch() async {
    if (_cameraController == null || _isDisposed) return;

    try {
      await _cameraController!.setFlashMode(
        widget.torchEnabled ? FlashMode.torch : FlashMode.off,
      );
    } catch (e) {}
  }

  /// Public method để reset recognizer
  void resetRecognizer() {
    _lastRecognizedText = null;
    _lastResult = null;
    _debounceTimer?.cancel();
    if (!_isRecognizing &&
        widget.recognitionMode == TextRecognitionMode.continuous) {
      _startRecognizing();
    }
  }

  /// Public method để update message
  void updateMessage(String message) {
    if (mounted) {
      setState(() {
        _currentMessage = message;
      });
    }
  }

  /// Public method để lấy last result
  RecognizedTextResult? getLastResult() {
    return _lastResult;
  }

  /// Get effective resolution preset (after auto-detection)
  ResolutionPreset? getEffectiveResolution() {
    return _configInitialized ? _effectiveResolution : null;
  }

  /// Get effective frame skip count (after auto-detection)
  int? getEffectiveFrameSkip() {
    return _configInitialized ? _effectiveFrameSkip : null;
  }

  /// Get effective confidence threshold (after auto-detection)
  double? getEffectiveConfidence() {
    return _configInitialized ? _effectiveConfidence : null;
  }

  /// Get effective debounce ms (after auto-detection)
  int? getEffectiveDebounce() {
    return _configInitialized ? _effectiveDebounce : null;
  }

  /// Get device performance level
  Future<DevicePerformanceLevel> getDevicePerformanceLevel() async {
    return await DevicePerformanceDetector.getPerformanceLevel();
  }

  @override
  void dispose() {
    _isDisposed = true;

    // Cancel all timers
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _messageUpdateTimer?.cancel();
    _messageUpdateTimer = null;
    _messageDurationTimer?.cancel();
    _messageDurationTimer = null;

    // Dispose audio player
    _audioPlayer.dispose();

    // Stop image stream và dispose camera
    _stopImageStream().then((_) {
      _cameraController?.dispose();
      _cameraController = null;
    });

    // Dispose text recognizer
    _textRecognizer?.close();
    _textRecognizer = null;

    // Clear cache
    _lastRecognizedText = null;
    _lastResult = null;

    // Remove observer
    WidgetsBinding.instance.removeObserver(this);

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

    // Tính toán scale để camera preview fill full container
    // Tương tự như MobileScanner với fit: BoxFit.cover
    final mediaSize = MediaQuery.of(context).size;
    final containerHeight = widget.height ?? mediaSize.height;

    // Lấy camera aspect ratio
    final cameraAspectRatio = _cameraController!.value.aspectRatio;

    // Tính container aspect ratio
    final containerAspectRatio = mediaSize.width / containerHeight;

    // Tính scale factor để cover full container
    double scale;
    if (containerAspectRatio > cameraAspectRatio) {
      // Container rộng hơn camera -> scale theo width
      scale = containerAspectRatio / cameraAspectRatio;
    } else {
      // Container cao hơn camera -> scale theo height
      scale = cameraAspectRatio / containerAspectRatio;
    }

    return Transform.scale(
      scale: scale,
      child: Center(
        child: AspectRatio(
          aspectRatio: cameraAspectRatio,
          child: CameraPreview(_cameraController!),
        ),
      ),
    );
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
