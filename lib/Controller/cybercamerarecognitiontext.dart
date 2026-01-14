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

class CyberCameraRecognitionText extends StatefulWidget {
  /// Callback khi nhận diện được text
  final Function(RecognizedTextResult)? onTextRecognized;

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

  const CyberCameraRecognitionText({
    super.key,
    this.onTextRecognized,
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
  void _initializeTextRecognizer() {
    if (_isDisposed) return;

    try {
      // Sử dụng script detection để tối ưu performance
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

    // Apply text filter
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
    if (_templateParser != null &&
        widget.onTextRecognizedWithTemplate != null) {
      // Parse với template
      final parsedData = _templateParser!.parse(result.fullText);

      // Validate nếu autoValidate enabled
      if (widget.autoValidateTemplate) {
        if (_templateParser!.validate(parsedData)) {
          widget.onTextRecognizedWithTemplate!.call(result, parsedData);
        } else {
          widget.onTextRecognizedWithTemplate!.call(result, null);
        }
      } else {
        // Không validate, trả về data luôn
        widget.onTextRecognizedWithTemplate!.call(result, parsedData);
      }
    } else {
      // Normal callback (không có template)
      widget.onTextRecognized?.call(result);
    }

    // Debounce timer
    _debounceTimer = Timer(Duration(milliseconds: _effectiveDebounce), () {
      if (widget.recognitionMode == TextRecognitionMode.continuous) {
        _lastRecognizedText = null;
      }
    });

    // Stop nếu là manual mode
    if (widget.recognitionMode == TextRecognitionMode.manual) {
      _stopRecognizing();
    }
  }

  /// Apply text filter
  String? _applyTextFilter(String text) {
    switch (widget.filterType) {
      case TextFilterType.all:
        return text;

      case TextFilterType.numeric:
        final numbers = text.replaceAll(RegExp(r'[^0-9]'), '');
        return numbers.isNotEmpty ? numbers : null;

      case TextFilterType.alphabetic:
        final letters = text.replaceAll(RegExp(r'[^a-zA-ZÀ-ỹ\s]'), '');
        return letters.isNotEmpty ? letters : null;

      case TextFilterType.alphanumeric:
        final alphanum = text.replaceAll(RegExp(r'[^a-zA-Z0-9À-ỹ\s]'), '');
        return alphanum.isNotEmpty ? alphanum : null;

      case TextFilterType.custom:
        if (widget.customFilterPattern == null) return text;
        try {
          final pattern = RegExp(widget.customFilterPattern!);
          final matches = pattern.allMatches(text);
          if (matches.isEmpty) return null;
          return matches.map((m) => m.group(0)).join(' ');
        } catch (e) {
          return text;
        }
    }
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
          //Center(child: CameraPreview(_cameraController!)),
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
