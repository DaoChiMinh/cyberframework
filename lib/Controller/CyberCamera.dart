// lib/Controller/CyberCamera.dart

import 'package:camera/camera.dart';
import 'package:cyberframework/cyberframework.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;

// ============================================================================
// WIDGET - CyberCamera (Main Widget with Internal Controller + Binding)
// ============================================================================

class CyberCamera extends StatefulWidget {
  /// Binding hoặc static string cho đường dẫn ảnh
  final dynamic imagePath; // String hoặc CyberBindingExpression

  /// Label hiển thị
  final String? label;

  /// Callback khi chụp ảnh thành công
  final OnCaptureImage? onCaptured;

  /// Enable/disable
  final bool enabled;

  /// Image display settings
  final double? width;
  final double? height;
  final BoxFit fit;

  /// Camera settings
  final bool enableCompression;
  final int compressionQuality;
  final int? maxWidth;
  final int? maxHeight;
  final CameraLensDirection defaultCamera;

  /// Title cho camera screen
  final String? cameraTitle;

  /// Custom placeholder khi chưa có ảnh
  final Widget? placeholder;

  /// Error callback
  final OnCameraError? onError;

  const CyberCamera({
    super.key,
    this.imagePath,
    this.label,
    this.onCaptured,
    this.enabled = true,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.enableCompression = true,
    this.compressionQuality = 85,
    this.maxWidth = 1920,
    this.maxHeight = 1920,
    this.defaultCamera = CameraLensDirection.back,
    this.cameraTitle,
    this.placeholder,
    this.onError,
  });

  @override
  State<CyberCamera> createState() => _CyberCameraState();
}

class _CyberCameraState extends State<CyberCamera> {
  // ============================================================================
  // INTERNAL CONTROLLER - User không cần khai báo
  // ============================================================================
  late final CyberCameraController _controller;

  CyberBindingExpression? _binding;
  String? _currentImagePath;
  bool _isBinding = false;

  @override
  void initState() {
    super.initState();
    _controller = CyberCameraController();
    _controller.setEnabled(widget.enabled);
    _initBinding();
  }

  @override
  void didUpdateWidget(CyberCamera oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update enabled state
    if (widget.enabled != oldWidget.enabled) {
      _controller.setEnabled(widget.enabled);
    }

    // Re-init binding nếu imagePath thay đổi
    if (widget.imagePath != oldWidget.imagePath) {
      _cleanupBinding();
      _initBinding();
    }
  }

  void _initBinding() {
    if (widget.imagePath == null) {
      _isBinding = false;
      _currentImagePath = null;
      return;
    }

    if (widget.imagePath is CyberBindingExpression) {
      // Binding mode
      _binding = widget.imagePath as CyberBindingExpression;
      _isBinding = true;
      _currentImagePath = _binding!.value?.toString();

      // Listen to binding changes
      _binding!.row.addListener(_onBindingChanged);
    } else {
      // Static string mode
      _isBinding = false;
      _currentImagePath = widget.imagePath.toString();
    }
  }

  void _cleanupBinding() {
    if (_binding != null) {
      _binding!.row.removeListener(_onBindingChanged);
      _binding = null;
    }
  }

  void _onBindingChanged() {
    if (!mounted) return;

    final newValue = _binding?.value?.toString();
    if (newValue != _currentImagePath) {
      setState(() {
        _currentImagePath = newValue;
      });
    }
  }

  Future<void> _openCamera() async {
    if (!widget.enabled) return;

    final view = CyberCameraView(
      context: context,
      controller: _controller,
      enableCompression: widget.enableCompression,
      compressionQuality: widget.compressionQuality,
      maxWidth: widget.maxWidth,
      maxHeight: widget.maxHeight,
      title: widget.cameraTitle ?? 'Chụp ảnh',
      defaultCamera: widget.defaultCamera,
      onError: widget.onError,
    );

    final result = await view.show();

    if (result != null) {
      _handleCaptureResult(result);
    }
  }

  void _handleCaptureResult(CyberCameraResult result) {
    final imagePath = result.file.path;

    // Update binding hoặc local state
    if (_isBinding && _binding != null) {
      _binding!.value = imagePath;
    } else {
      setState(() {
        _currentImagePath = imagePath;
      });
    }

    // Trigger callback
    widget.onCaptured?.call(result);
  }

  void _clearImage() {
    if (!widget.enabled) return;

    if (_isBinding && _binding != null) {
      _binding!.value = null;
    } else {
      setState(() {
        _currentImagePath = null;
      });
    }
  }

  @override
  void dispose() {
    _cleanupBinding();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = _currentImagePath != null && _currentImagePath!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Image Display & Controls
        AbsorbPointer(
          absorbing: !widget.enabled,
          child: Opacity(
            opacity: widget.enabled ? 1.0 : 0.5,
            child: Container(
              width: widget.width ?? double.infinity,
              height: widget.height ?? 200,
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(8),
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              child: Stack(
                children: [
                  // Image or Placeholder
                  if (hasImage)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(_currentImagePath!),
                        width: double.infinity,
                        height: double.infinity,
                        fit: widget.fit,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholder(theme);
                        },
                      ),
                    )
                  else
                    _buildPlaceholder(theme),

                  // Control buttons
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Row(
                      children: [
                        // Clear button (chỉ hiện khi có ảnh)
                        if (hasImage) ...[
                          Material(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              onTap: _clearImage,
                              borderRadius: BorderRadius.circular(20),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  Icons.delete_outline,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],

                        // Camera button
                        Material(
                          color: theme.colorScheme.primary.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            onTap: _openCamera,
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return widget.placeholder ??
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_a_photo,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'Chụp ảnh',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
            ],
          ),
        );
  }
}

// ============================================================================
// VIEW - CyberCameraView (Full screen camera)
// ============================================================================

class CyberCameraView {
  final BuildContext context;
  final CyberCameraController? controller;
  final bool enableCompression;
  final int compressionQuality;
  final int? maxWidth;
  final int? maxHeight;
  final String? title;
  final CameraLensDirection defaultCamera;
  final OnCameraError? onError;

  CyberCameraView({
    required this.context,
    this.controller,
    this.enableCompression = true,
    this.compressionQuality = 85,
    this.maxWidth = 1920,
    this.maxHeight = 1920,
    this.title,
    this.defaultCamera = CameraLensDirection.back,
    this.onError,
  });

  Future<CyberCameraResult?> show() async {
    final result = await Navigator.of(context).push<CyberCameraResult>(
      MaterialPageRoute(
        builder: (context) => _CyberCameraScreen(
          controller: controller,
          enableCompression: enableCompression,
          compressionQuality: compressionQuality,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          title: title,
          defaultCamera: defaultCamera,
          onError: onError,
        ),
        fullscreenDialog: true,
      ),
    );

    return result;
  }
}

// ============================================================================
// SCREEN - _CyberCameraScreen (Internal camera screen)
// ============================================================================

class _CyberCameraScreen extends StatefulWidget {
  final CyberCameraController? controller;
  final bool enableCompression;
  final int compressionQuality;
  final int? maxWidth;
  final int? maxHeight;
  final String? title;
  final CameraLensDirection defaultCamera;
  final OnCameraError? onError;

  const _CyberCameraScreen({
    this.controller,
    required this.enableCompression,
    required this.compressionQuality,
    this.maxWidth,
    this.maxHeight,
    this.title,
    required this.defaultCamera,
    this.onError,
  });

  @override
  State<_CyberCameraScreen> createState() => _CyberCameraScreenState();
}

class _CyberCameraScreenState extends State<_CyberCameraScreen> {
  CyberCameraController? _internalController;
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;
  int _currentCameraIndex = 0;

  CyberCameraController get _effectiveController =>
      widget.controller ?? _internalController!;

  @override
  void initState() {
    super.initState();

    if (widget.controller == null) {
      _internalController = CyberCameraController();
    }

    _initializeCamera();
    _effectiveController.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (!mounted) return;

    final action = _effectiveController.pendingAction;
    if (action != CyberCameraAction.none) {
      _handlePendingAction(action);
      return;
    }

    setState(() {});
  }

  void _handlePendingAction(CyberCameraAction action) {
    switch (action) {
      case CyberCameraAction.capture:
        _captureImage();
        break;
      case CyberCameraAction.switchCamera:
        _switchCamera();
        break;
      case CyberCameraAction.none:
        break;
    }
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_onControllerChanged);
    _cameraController?.dispose();
    _internalController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        _handleError('Không tìm thấy camera');
        return;
      }

      _currentCameraIndex = _cameras!.indexWhere(
        (camera) => camera.lensDirection == widget.defaultCamera,
      );

      if (_currentCameraIndex == -1) {
        _currentCameraIndex = 0;
      }

      await _initController(_cameras![_currentCameraIndex]);
    } catch (e) {
      _handleError('Lỗi khởi tạo camera: $e');
    }
  }

  Future<void> _initController(CameraDescription camera) async {
    _cameraController?.dispose();

    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      _handleError('Lỗi khởi tạo controller: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    if (!_effectiveController.enabled) return;

    setState(() {
      _isInitialized = false;
      _currentCameraIndex = (_currentCameraIndex + 1) % _cameras!.length;
    });

    await _initController(_cameras![_currentCameraIndex]);
  }

  Future<void> _captureImage() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isCapturing ||
        !_effectiveController.enabled) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile image = await _cameraController!.takePicture();
      final result = await _processImage(image);

      if (result != null && mounted) {
        Navigator.of(context).pop(result);
      }
    } catch (e) {
      _handleError('Lỗi khi chụp ảnh: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  Future<CyberCameraResult?> _processImage(XFile xFile) async {
    try {
      File imageFile = File(xFile.path);

      if (widget.enableCompression) {
        final compressedFile = await _compressImage(imageFile);
        if (compressedFile != null) {
          imageFile = compressedFile;
        }
      }

      final fileSize = await imageFile.length();
      final fileName = path.basename(imageFile.path);

      return CyberCameraResult(
        file: imageFile,
        fileName: fileName,
        fileSize: fileSize,
        isCompressed: widget.enableCompression,
        quality: widget.enableCompression ? widget.compressionQuality : null,
      );
    } catch (e) {
      _handleError('Lỗi xử lý ảnh: $e');
      return null;
    }
  }

  Future<File?> _compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(
        dir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: widget.compressionQuality,
        minWidth: widget.maxWidth ?? 1920,
        minHeight: widget.maxHeight ?? 1920,
      );

      if (result == null) return null;

      return File(result.path);
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return null;
    }
  }

  void _handleError(String error) {
    debugPrint('CyberCameraView Error: $error');
    widget.onError?.call(error);
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = _effectiveController.enabled;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.title ?? 'Chụp ảnh'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isInitialized && _cameras != null && _cameras!.length > 1)
            IconButton(
              icon: const Icon(Icons.flip_camera_ios),
              onPressed: _switchCamera,
            ),
        ],
      ),
      body: AbsorbPointer(
        absorbing: !isEnabled,
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.5,
          child: Stack(
            children: [
              // Camera Preview
              if (_isInitialized && _cameraController != null)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _captureImage,
                    child: CameraPreview(_cameraController!),
                  ),
                )
              else
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 16),
                      Text(
                        'Đang khởi tạo camera...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),

              // Capture overlay effect
              if (_isCapturing)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withOpacity(0.5),
                    child: const Center(
                      child: Icon(
                        Icons.camera_alt,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              // Bottom controls
              if (_isInitialized)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const SizedBox(width: 60),

                        // Capture button
                        GestureDetector(
                          onTap: _captureImage,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 60),
                      ],
                    ),
                  ),
                ),

              // Hint text
              if (_isInitialized)
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Nhấn vào màn hình để chụp',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}