// lib/Controller/cybercamera.dart

import 'package:cyberframework/cyberframework.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;

// ============================================================================
// WIDGET - CyberCamera (Single StatefulWidget, inline camera preview)
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

  /// Custom placeholder khi chưa có ảnh
  final Widget? placeholder;

  /// Error callback
  final OnCameraError? onError;

  /// Hiện/ẩn status bar (đang chụp / đã chụp)
  final bool showStatus;
  final Color statusTextColor;
  final Color statusBackgroundColor;

  /// Cho phép click vào preview để chụp
  final bool clickCapture;

  /// Hiện/ẩn nút flip camera
  final bool showFlipButton;

  /// Hint text phía trên preview
  final String? hintText;
  final bool showHint;

  /// ── Auto Upload ──────────────────────────────────────────────────────────
  /// Tự động upload ảnh lên server sau khi chụp.
  /// - true : upload → binding nhận URL, [afterUpload] trả về (result, url)
  /// - false: binding nhận local path, [afterUpload] trả về (result, '')
  final bool autoUpload;

  /// Folder lưu file trên server, ví dụ: '/chamcong/photos/'
  final String? uploadFilePath;

  /// Callback sau khi chụp (và upload nếu autoUpload=true).
  /// Parameters:
  ///   - result   : CyberCameraResult (file local, fileName, fileSize…)
  ///   - uploadedUrl: URL server nếu upload thành công, '' nếu không upload
  final void Function(CyberCameraResult result, String uploadedUrl)?
  afterUpload;

  /// Callback khi upload thành công, trả về URL
  final ValueChanged<String>? onUploadSuccess;

  /// Callback khi upload thất bại, trả về thông báo lỗi
  final ValueChanged<String>? onUploadError;

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
    this.placeholder,
    this.onError,
    this.showStatus = true,
    this.statusTextColor = Colors.white,
    this.statusBackgroundColor = Colors.black54,
    this.clickCapture = true,
    this.showFlipButton = true,
    this.hintText,
    this.showHint = true,
    this.autoUpload = false,
    this.uploadFilePath,
    this.afterUpload,
    this.onUploadSuccess,
    this.onUploadError,
  });

  @override
  State<CyberCamera> createState() => _CyberCameraState();
}

class _CyberCameraState extends State<CyberCamera> with WidgetsBindingObserver {
  // ─── Camera ──────────────────────────────────────────────────────────────
  List<CameraDescription>? _cameras;
  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isCapturing = false;
  int _currentCameraIndex = 0;
  bool _isDisposed = false;

  // ─── Binding ─────────────────────────────────────────────────────────────
  CyberBindingExpression? _binding;
  String? _currentImagePath;
  bool _isBinding = false;

  // ─── Upload state ─────────────────────────────────────────────────────────
  bool _isUploading = false;

  // ─── Preview mode ─────────────────────────────────────────────────────────
  /// true = đang hiện camera live, false = hiện ảnh đã chụp / placeholder
  bool _showCamera = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initBinding();
    // Nếu chưa có ảnh, tự động mở camera
    if (_currentImagePath == null || _currentImagePath!.isEmpty) {
      _showCamera = true;
      _initializeCamera();
    }
  }

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void didUpdateWidget(CyberCamera oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.enabled != oldWidget.enabled) {
      // nothing extra needed – AbsorbPointer handles UI
    }

    if (widget.imagePath != oldWidget.imagePath) {
      _cleanupBinding();
      _initBinding();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed || _cameraController == null) return;
    switch (state) {
      case AppLifecycleState.resumed:
        if (_showCamera) _initController(_cameras![_currentCameraIndex]);
        break;
      case AppLifecycleState.inactive:
        _cameraController?.dispose();
        _cameraController = null;
        if (mounted) setState(() => _isInitialized = false);
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cleanupBinding();
    _cameraController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ─── Binding helpers ──────────────────────────────────────────────────────

  void _initBinding() {
    if (widget.imagePath == null) {
      _isBinding = false;
      _currentImagePath = null;
      return;
    }

    if (widget.imagePath is CyberBindingExpression) {
      _binding = widget.imagePath as CyberBindingExpression;
      _isBinding = true;
      _currentImagePath = _binding!.value?.toString();
      _binding!.row.addListener(_onBindingChanged);
    } else {
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
        _showCamera = newValue == null || newValue.isEmpty;
        if (_showCamera && !_isInitialized) _initializeCamera();
      });
    }
  }

  // ─── Camera helpers ───────────────────────────────────────────────────────

  Future<void> _initializeCamera() async {
    if (_isDisposed) return;
    try {
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        _handleError('Không tìm thấy camera');
        return;
      }

      _currentCameraIndex = _cameras!.indexWhere(
        (c) => c.lensDirection == widget.defaultCamera,
      );
      if (_currentCameraIndex == -1) _currentCameraIndex = 0;

      await _initController(_cameras![_currentCameraIndex]);
    } catch (e) {
      _handleError('Lỗi khởi tạo camera: $e');
    }
  }

  Future<void> _initController(CameraDescription camera) async {
    if (_isDisposed) return;
    await _cameraController?.dispose();
    _cameraController = null;

    if (mounted) setState(() => _isInitialized = false);

    _cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      _handleError('Lỗi khởi tạo controller: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    if (!widget.enabled) return;

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
        !widget.enabled) {
      return;
    }

    setState(() => _isCapturing = true);

    try {
      final XFile xFile = await _cameraController!.takePicture();
      final result = await _processImage(xFile);

      if (result != null) {
        _handleCaptureResult(result);
      }
    } catch (e) {
      _handleError('Lỗi khi chụp ảnh: $e');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<CyberCameraResult?> _processImage(XFile xFile) async {
    try {
      File imageFile = File(xFile.path);

      if (widget.enableCompression) {
        final compressed = await _compressImage(imageFile);
        if (compressed != null) imageFile = compressed;
      }

      return CyberCameraResult(
        file: imageFile,
        fileName: path.basename(imageFile.path),
        fileSize: await imageFile.length(),
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

      return result == null ? null : File(result.path);
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return null;
    }
  }

  void _handleCaptureResult(CyberCameraResult result) {
    // Fire onCaptured ngay sau khi chụp (trước khi upload)
    widget.onCaptured?.call(result);

    if (widget.autoUpload) {
      _uploadImage(result);
    } else {
      // Không upload: lưu local path vào binding
      if (_isBinding && _binding != null) {
        _binding!.value = result.file.path;
      }
      widget.afterUpload?.call(result, '');
    }

    // Quay lại camera ngay, không chờ upload
    if (mounted) setState(() {}); // _showCamera vẫn = true
  }

  // ─── Auto Upload ──────────────────────────────────────────────────────────

  Future<void> _uploadImage(CyberCameraResult result) async {
    if (!mounted) return;

    setState(() => _isUploading = true);

    try {
      final bytes = await result.file.readAsBytes();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = path.extension(result.fileName).isNotEmpty
          ? path.extension(result.fileName)
          : '.jpg';
      final fileName = 'photo_$timestamp$ext';
      final uploadPath = widget.uploadFilePath != null
          ? '${widget.uploadFilePath}$fileName'
          : '/$fileName';

      debugPrint('📷 CyberCamera upload: $uploadPath');

      final (uploadedFile, status) = await context.uploadSingleObjectAndCheck(
        object: bytes,
        filePath: uploadPath,
        showLoading: false,
        showError: false,
      );

      if (!status || uploadedFile == null) {
        debugPrint('❌ CyberCamera upload failed');

        if (mounted) {
          await 'Upload ảnh thất bại. Đã lưu ảnh tạm thời.'.V_MsgBox(
            context,
            type: CyberMsgBoxType.warning,
          );

          // Fallback: lưu local path
          if (_isBinding && _binding != null) {
            _binding!.value = result.file.path;
          }
          widget.afterUpload?.call(result, '');
          widget.onUploadError?.call('Upload failed');
        }
        return;
      }

      debugPrint('✅ CyberCamera upload success: ${uploadedFile.url}');

      // Lưu URL vào binding
      if (_isBinding && _binding != null) {
        _binding!.value = uploadedFile.url;
      }

      widget.afterUpload?.call(result, uploadedFile.url);
      widget.onUploadSuccess?.call(uploadedFile.url);

      if (mounted) {
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(
        //     content: Text('Upload ảnh thành công!'),
        //     backgroundColor: Colors.green,
        //     duration: Duration(seconds: 2),
        //   ),
        // );
      }
    } catch (e) {
      debugPrint('❌ CyberCamera upload error: $e');

      if (mounted) {
        await 'Lỗi upload ảnh: $e'.V_MsgBox(
          context,
          type: CyberMsgBoxType.error,
        );

        // Fallback: lưu local path
        if (_isBinding && _binding != null) {
          _binding!.value = result.file.path;
        }
        widget.afterUpload?.call(result, '');
        widget.onUploadError?.call(e.toString());
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // void _clearImage() {
  //   if (!widget.enabled) return;

  //   if (_isBinding && _binding != null) {
  //     _binding!.value = null;
  //   } else {
  //     setState(() {
  //       _currentImagePath = null;
  //       _showCamera = true;
  //     });
  //   }
  //   _initializeCamera();
  // }

  // void _openCameraMode() {
  //   if (!widget.enabled) return;
  //   setState(() => _showCamera = true);
  //   _initializeCamera();
  // }

  void _handleError(String error) {
    debugPrint('CyberCamera Error: $error');
    widget.onError?.call(error);
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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

        // Main container
        AbsorbPointer(
          absorbing: !widget.enabled,
          child: Opacity(
            opacity: widget.enabled ? 1.0 : 0.5,
            child: Container(
              width: widget.width ?? double.infinity,
              height: widget.height ?? 280,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  // ── Camera live preview ──────────────────────────────────
                  if (_showCamera) ...[
                    if (_isInitialized && _cameraController != null)
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: widget.clickCapture ? _captureImage : null,
                          child: CameraPreview(_cameraController!),
                        ),
                      )
                    else
                      const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Colors.white),
                            SizedBox(height: 12),
                            Text(
                              'Đang khởi tạo camera...',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                  ],

                  // ── Flash overlay khi đang chụp ──────────────────────────
                  if (_isCapturing)
                    Positioned.fill(
                      child: Container(
                        color: Colors.white.withOpacity(0.6),
                        child: const Center(
                          child: Icon(
                            Icons.camera_alt,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                  // ── Upload loading overlay ───────────────────────────────
                  if (_isUploading)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.55),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(color: Colors.white),
                              SizedBox(height: 12),
                              Text(
                                'Đang upload ảnh...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // ── Status bar (trên cùng) ───────────────────────────────
                  if (widget.showStatus && _showCamera && _isInitialized)
                    Positioned(
                      top: 12,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: widget.statusBackgroundColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                color: widget.statusTextColor,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Sẵn sàng chụp',
                                style: TextStyle(
                                  color: widget.statusTextColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // ── Hint text ────────────────────────────────────────────
                  if (widget.showHint &&
                      _showCamera &&
                      _isInitialized &&
                      widget.clickCapture)
                    Positioned(
                      bottom: 80,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.hintText ?? 'Nhấn vào màn hình để chụp',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // ── Bottom controls ──────────────────────────────────────
                  if (_showCamera && _isInitialized)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.65),
                            ],
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Flip camera
                            if (widget.showFlipButton &&
                                _cameras != null &&
                                _cameras!.length > 1)
                              _buildCircleButton(
                                icon: Icons.flip_camera_ios,
                                onTap: _switchCamera,
                              )
                            else
                              const SizedBox(width: 48),

                            // Capture button
                            GestureDetector(
                              onTap: _captureImage,
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
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

                            const SizedBox(width: 48),
                          ],
                        ),
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

  // Widget _buildPlaceholder(ThemeData theme) {
  //   return widget.placeholder ??
  //       Center(
  //         child: Column(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             Icon(
  //               Icons.add_a_photo,
  //               size: 48,
  //               color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
  //             ),
  //             const SizedBox(height: 8),
  //             Text(
  //               'Chụp ảnh',
  //               style: theme.textTheme.bodyMedium?.copyWith(
  //                 color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
  //               ),
  //             ),
  //           ],
  //         ),
  //       );
  // }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? background,
  }) {
    return Material(
      color: background ?? Colors.black.withOpacity(0.55),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
