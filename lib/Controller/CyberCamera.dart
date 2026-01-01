// ============================================================================
// VIEW - CyberCameraView (Full screen camera)
// ============================================================================

import 'package:camera/camera.dart';
import 'package:cyberframework/cyberframework.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;

/// CyberCameraView - Màn hình camera full screen với controller
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

  /// Show camera screen và trả về result
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

/// Camera Screen Widget
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
          icon: Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_isInitialized && _cameras != null && _cameras!.length > 1)
            IconButton(
              icon: Icon(Icons.flip_camera_ios),
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
                Center(
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
                    color: Colors.white.withValues(alpha: 0.5),
                    child: Center(
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
                    padding: EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SizedBox(width: 60),

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
                              margin: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(width: 60),
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
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
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
