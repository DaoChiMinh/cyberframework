import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:convert';

/// Result data sau khi chụp ảnh
class CyberCameraResult {
  final File file;
  final String fileName;
  final int fileSize;
  final bool isCompressed;
  final int? quality;

  CyberCameraResult({
    required this.file,
    required this.fileName,
    required this.fileSize,
    this.isCompressed = false,
    this.quality,
  });

  /// Get file as bytes
  Future<List<int>> getBytes() async {
    return await file.readAsBytes();
  }

  /// Get base64 string
  Future<String> getBase64() async {
    final bytes = await getBytes();
    return base64Encode(bytes);
  }
}

/// Callback khi chụp ảnh thành công
typedef OnCaptureImage = void Function(CyberCameraResult result);

/// Callback khi có lỗi
typedef OnCameraError = void Function(String error);

// ============================================================================
// CONTROL - CyberCamera (Inline camera control)
// ============================================================================

/// CyberCamera - Camera control có thể add vào màn hình
/// Tap vào preview để chụp ảnh
class CyberCamera extends StatefulWidget {
  /// Callback khi chụp ảnh thành công
  final OnCaptureImage onCapture;

  /// Callback khi có lỗi
  final OnCameraError? onError;

  /// Chiều cao của camera view
  final double? height;

  /// Border radius
  final double borderRadius;

  /// Có nén ảnh hay không
  final bool enableCompression;

  /// Chất lượng nén (0-100)
  final int compressionQuality;

  /// Kích thước max sau khi nén (width)
  final int? maxWidth;

  /// Kích thước max sau khi nén (height)
  final int? maxHeight;

  /// Hiển thị overlay khi tap
  final bool showTapOverlay;

  /// Text hướng dẫn
  final String? hintText;

  /// Camera mặc định (back/front)
  final CameraLensDirection defaultCamera;

  const CyberCamera({
    super.key,
    required this.onCapture,
    this.onError,
    this.height = 300,
    this.borderRadius = 12.0,
    this.enableCompression = true,
    this.compressionQuality = 85,
    this.maxWidth = 1920,
    this.maxHeight = 1920,
    this.showTapOverlay = true,
    this.hintText,
    this.defaultCamera = CameraLensDirection.back,
  });

  @override
  State<CyberCamera> createState() => _CyberCameraState();
}

class _CyberCameraState extends State<CyberCamera> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;
  int _currentCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        _handleError('Không tìm thấy camera');
        return;
      }

      // Find default camera
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
    _controller?.dispose();

    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
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

    setState(() {
      _isInitialized = false;
      _currentCameraIndex = (_currentCameraIndex + 1) % _cameras!.length;
    });

    await _initController(_cameras![_currentCameraIndex]);
  }

  Future<void> _captureImage() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile image = await _controller!.takePicture();
      await _processImage(image);
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

  Future<void> _processImage(XFile xFile) async {
    try {
      File imageFile = File(xFile.path);

      // Nén ảnh nếu enable
      if (widget.enableCompression) {
        final compressedFile = await _compressImage(imageFile);
        if (compressedFile != null) {
          imageFile = compressedFile;
        }
      }

      final fileSize = await imageFile.length();
      final fileName = path.basename(imageFile.path);

      final result = CyberCameraResult(
        file: imageFile,
        fileName: fileName,
        fileSize: fileSize,
        isCompressed: widget.enableCompression,
        quality: widget.enableCompression ? widget.compressionQuality : null,
      );

      widget.onCapture(result);
    } catch (e) {
      _handleError('Lỗi xử lý ảnh: $e');
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
      //debugPrint('Error compressing image: $e');
      return null;
    }
  }

  void _handleError(String error) {
    //debugPrint('CyberCamera Error: $error');
    widget.onError?.call(error);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Stack(
          children: [
            // Camera Preview
            if (_isInitialized && _controller != null)
              Positioned.fill(
                child: GestureDetector(
                  onTap: widget.showTapOverlay ? _captureImage : null,
                  child: CameraPreview(_controller!),
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

            // Tap overlay
            if (widget.showTapOverlay && _isInitialized)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _captureImage,
                  child: Container(
                    color: Colors.transparent,
                    child: Center(
                      child: widget.hintText != null
                          ? Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.hintText!,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
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

            // Control buttons
            if (_isInitialized)
              Positioned(top: 8, right: 8, child: _buildControlButtons()),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Column(
      children: [
        // Switch camera button
        if (_cameras != null && _cameras!.length > 1)
          Container(
            margin: EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.flip_camera_ios, color: Colors.white),
              onPressed: _switchCamera,
            ),
          ),

        // Manual capture button
        if (!widget.showTapOverlay)
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.camera_alt, color: Colors.white, size: 28),
              onPressed: _captureImage,
            ),
          ),
      ],
    );
  }
}

// ============================================================================
// VIEW - CyberCameraView (Full screen camera)
// ============================================================================

/// CyberCameraView - Màn hình camera full screen
/// Show như popup, chụp xong tự động đóng và trả về data
class CyberCameraView {
  final BuildContext context;
  final bool enableCompression;
  final int compressionQuality;
  final int? maxWidth;
  final int? maxHeight;
  final String? title;
  final CameraLensDirection defaultCamera;
  final OnCameraError? onError;

  CyberCameraView({
    required this.context,
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
  final bool enableCompression;
  final int compressionQuality;
  final int? maxWidth;
  final int? maxHeight;
  final String? title;
  final CameraLensDirection defaultCamera;
  final OnCameraError? onError;

  const _CyberCameraScreen({
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
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;
  int _currentCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
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
    _controller?.dispose();

    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
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

    setState(() {
      _isInitialized = false;
      _currentCameraIndex = (_currentCameraIndex + 1) % _cameras!.length;
    });

    await _initController(_cameras![_currentCameraIndex]);
  }

  Future<void> _captureImage() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isCapturing) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final XFile image = await _controller!.takePicture();
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
      //debugPrint('Error compressing image: $e');
      return null;
    }
  }

  void _handleError(String error) {
    //debugPrint('CyberCameraView Error: $error');
    widget.onError?.call(error);
  }

  @override
  Widget build(BuildContext context) {
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
      body: Stack(
        children: [
          // Camera Preview
          if (_isInitialized && _controller != null)
            Positioned.fill(
              child: GestureDetector(
                onTap: _captureImage,
                child: CameraPreview(_controller!),
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
                  child: Icon(Icons.camera_alt, size: 64, color: Colors.white),
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
                    // Gallery button (optional)
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

                    // Settings button (optional)
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
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    );
  }
}

/// Extension for base64 encoding

extension Base64Extension on List<int> {
  String base64Encode() => base64.encode(this);
}
