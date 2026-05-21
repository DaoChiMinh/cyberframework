import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:convert';

/// ============================================================================
/// CONTROLLER - Source of truth
/// ============================================================================
class CyberFilePickerController extends ChangeNotifier {
  PlatformFile? _file;
  bool _enabled = true;

  PlatformFile? get file => _file;
  bool get enabled => _enabled;
  bool get hasFile => _file != null;

  void setFile(PlatformFile? file) {
    if (_file == file) return;
    _file = file;
    notifyListeners();
  }

  void clear() {
    if (_file == null) return;
    _file = null;
    notifyListeners();
  }

  void setEnabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _file = null;
    super.dispose();
  }
}

/// ============================================================================
/// DATA MODELS
/// ============================================================================
enum CyberFileType { image, file }

class CyberFileResult {
  final File file;
  final String fileName;
  final String extension;
  final int fileSize;
  final CyberFileType fileType;
  final bool isCompressed;

  CyberFileResult({
    required this.file,
    required this.fileName,
    required this.extension,
    required this.fileSize,
    required this.fileType,
    this.isCompressed = false,
  });

  /// Convert to PlatformFile
  PlatformFile toPlatformFile() {
    return PlatformFile(
      name: fileName,
      size: fileSize,
      path: file.path,
      bytes: null,
    );
  }

  Future<List<int>> getBytes() async {
    return await file.readAsBytes();
  }

  Future<String> getBase64() async {
    final bytes = await getBytes();
    return base64Encode(bytes);
  }
}

/// ============================================================================
/// CALLBACKS
/// ============================================================================
typedef OnFileSelected = void Function(CyberFileResult result);
typedef OnFileError = void Function(String error);

/// ============================================================================
/// MAIN WIDGET - CyberFilePicker
/// ============================================================================
class CyberFilePicker extends StatefulWidget {
  final String label;
  final IconData? icon;

  /// ⚠️ Controller - REQUIRED cho framework consistency
  final CyberFilePickerController? controller;

  /// ⚠️ Callback - optional, chỉ dùng khi KHÔNG có controller
  final OnFileSelected? onFileSelected;
  final OnFileError? onError;

  final Color? backgroundColor;
  final Color? textColor;
  final double borderRadius;
  final EdgeInsets? padding;

  /// ⚠️ enabled - deprecated, dùng controller.setEnabled()
  @Deprecated('Use controller.setEnabled() instead')
  final bool? enabled;

  // Compression settings
  final bool enableCompression;
  final int compressionQuality;
  final int? maxWidth;
  final int? maxHeight;

  // File picker settings
  final List<String>? allowedExtensions;
  final bool allowMultiple;
  final ButtonStyle? buttonStyle;

  const CyberFilePicker({
    super.key,
    this.label = "Chọn file",
    this.icon,
    this.controller,
    this.onFileSelected,
    this.onError,
    this.backgroundColor,
    this.textColor,
    this.borderRadius = 8.0,
    this.padding,
    this.enabled,
    this.enableCompression = true,
    this.compressionQuality = 85,
    this.maxWidth = 1920,
    this.maxHeight = 1920,
    this.allowedExtensions,
    this.allowMultiple = false,
    this.buttonStyle,
  }) : assert(
         controller != null || onFileSelected != null,
         'CyberFilePicker: phải có controller HOẶC onFileSelected',
       );

  @override
  State<CyberFilePicker> createState() => _CyberFilePickerState();
}

class _CyberFilePickerState extends State<CyberFilePicker> {
  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(CyberFilePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerChanged);
      widget.controller?.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
  }

  bool get _isEnabled {
    // Priority: controller.enabled > widget.enabled > true
    if (widget.controller != null) {
      return widget.controller!.enabled;
    }
    return widget.enabled ?? true;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.icon != null) {
      return ElevatedButton.icon(
        onPressed: _isEnabled ? () => _showOptions(context) : null,
        icon: Icon(widget.icon, size: 20),
        label: Text(widget.label),
        style: widget.buttonStyle ?? _buildButtonStyle(),
      );
    }

    return ElevatedButton(
      onPressed: _isEnabled ? () => _showOptions(context) : null,
      style: widget.buttonStyle ?? _buildButtonStyle(),
      child: Text(widget.label),
    );
  }

  ButtonStyle _buildButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: widget.backgroundColor ?? const Color(0xFF00D287),
      foregroundColor: widget.textColor ?? Colors.white,
      padding:
          widget.padding ??
          const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
    );
  }

  Future<void> _showOptions(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilePickerBottomSheet(
        onCameraTap: () => _handleCamera(context),
        onGalleryTap: () => _handleGallery(context),
        onFileTap: () => _handleFilePicker(context),
      ),
    );
  }

  Future<void> _handleCamera(BuildContext context) async {
    Navigator.pop(context);

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: widget.enableCompression
            ? widget.compressionQuality
            : 100,
        maxWidth: widget.enableCompression ? widget.maxWidth?.toDouble() : null,
        maxHeight: widget.enableCompression
            ? widget.maxHeight?.toDouble()
            : null,
      );

      if (image == null) return;
      await _processImage(image);
    } catch (e) {
      _handleError('Lỗi khi chụp ảnh: $e');
    }
  }

  Future<void> _handleGallery(BuildContext context) async {
    Navigator.pop(context);

    try {
      final ImagePicker picker = ImagePicker();

      if (widget.allowMultiple) {
        final List<XFile> images = await picker.pickMultipleMedia(
          imageQuality: widget.enableCompression
              ? widget.compressionQuality
              : 100,
          maxWidth: widget.enableCompression
              ? widget.maxWidth?.toDouble()
              : null,
          maxHeight: widget.enableCompression
              ? widget.maxHeight?.toDouble()
              : null,
        );

        if (images.isEmpty) return;
        await _processImage(images.first);
      } else {
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: widget.enableCompression
              ? widget.compressionQuality
              : 100,
          maxWidth: widget.enableCompression
              ? widget.maxWidth?.toDouble()
              : null,
          maxHeight: widget.enableCompression
              ? widget.maxHeight?.toDouble()
              : null,
        );

        if (image == null) return;
        await _processImage(image);
      }
    } catch (e) {
      _handleError('Lỗi khi chọn ảnh: $e');
    }
  }

  Future<void> _handleFilePicker(BuildContext context) async {
    Navigator.pop(context);

    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: widget.allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: widget.allowedExtensions,
        allowMultiple: widget.allowMultiple,
      );

      if (result == null || result.files.isEmpty) return;

      final PlatformFile platformFile = result.files.first;

      if (platformFile.path == null) {
        _handleError('Không thể đọc file');
        return;
      }

      final File file = File(platformFile.path!);
      final fileSize = await file.length();

      final fileResult = CyberFileResult(
        file: file,
        fileName: platformFile.name,
        extension: platformFile.extension ?? '',
        fileSize: fileSize,
        fileType: CyberFileType.file,
        isCompressed: false,
      );

      // ✅ Update controller FIRST
      widget.controller?.setFile(fileResult.toPlatformFile());

      // ✅ Then callback
      widget.onFileSelected?.call(fileResult);
    } catch (e) {
      _handleError('Lỗi khi chọn file: $e');
    }
  }

  Future<void> _processImage(XFile xFile) async {
    try {
      File imageFile = File(xFile.path);

      // ✅ Compress nếu cần
      if (widget.enableCompression) {
        final compressedFile = await _compressImage(imageFile);
        if (compressedFile != null) {
          imageFile = compressedFile;
        }
      }

      final fileSize = await imageFile.length();
      final fileName = path.basename(imageFile.path);
      final extension = path.extension(fileName).replaceAll('.', '');

      final result = CyberFileResult(
        file: imageFile,
        fileName: fileName,
        extension: extension,
        fileSize: fileSize,
        fileType: CyberFileType.image,
        isCompressed: widget.enableCompression,
      );

      // ✅ Update controller FIRST
      widget.controller?.setFile(result.toPlatformFile());

      // ✅ Then callback
      widget.onFileSelected?.call(result);
    } catch (e) {
      _handleError('Lỗi khi xử lý ảnh: $e');
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
      return null;
    }
  }

  void _handleError(String error) {
    widget.onError?.call(error);
  }
}

/// ============================================================================
/// FIELD WIDGET - With Preview
/// ============================================================================
class CyberFilePickerField extends StatefulWidget {
  final String label;
  final String? hint;

  /// ⚠️ Controller - REQUIRED
  final CyberFilePickerController? controller;

  final OnFileSelected? onFileSelected;
  final OnFileError? onError;
  final bool enableCompression;
  final int compressionQuality;
  final int? maxWidth;
  final int? maxHeight;
  final List<String>? allowedExtensions;
  final bool isShowLabel;
  final Color? backgroundColor;

  const CyberFilePickerField({
    super.key,
    this.label = "Chọn file",
    this.hint,
    this.controller,
    this.onFileSelected,
    this.onError,
    this.enableCompression = true,
    this.compressionQuality = 85,
    this.maxWidth = 1920,
    this.maxHeight = 1920,
    this.allowedExtensions,
    this.isShowLabel = true,
    this.backgroundColor,
  });

  @override
  State<CyberFilePickerField> createState() => _CyberFilePickerFieldState();
}

class _CyberFilePickerFieldState extends State<CyberFilePickerField> {
  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(CyberFilePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerChanged);
      widget.controller?.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    setState(() {});
  }

  bool get _isEnabled => widget.controller?.enabled ?? true;
  PlatformFile? get _selectedFile => widget.controller?.file;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.isShowLabel)
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
            child: Text(
              widget.label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF555555),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _selectedFile == null
              ? _buildEmptyState()
              : _buildFilePreview(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return InkWell(
      onTap: _isEnabled ? _showFilePicker : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 48,
              color: _isEnabled ? Colors.grey[400] : Colors.grey[300],
            ),
            const SizedBox(height: 8),
            Text(
              widget.hint ?? 'Nhấn để chọn file',
              style: TextStyle(
                fontSize: 14,
                color: _isEnabled ? Colors.grey[600] : Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePreview() {
    final file = _selectedFile!;
    final isImage = _isImageFile(file.extension ?? '');

    return Row(
      children: [
        // Preview
        if (isImage && file.path != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(file.path!),
              width: 60,
              height: 60,
              fit: BoxFit.cover,
            ),
          )
        else
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.insert_drive_file,
              size: 32,
              color: Colors.blue[700],
            ),
          ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                file.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _formatFileSize(file.size),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),

        // Remove button
        if (_isEnabled)
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () {
              widget.controller?.clear();
            },
          ),
      ],
    );
  }

  bool _isImageFile(String ext) {
    final imageExts = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    return imageExts.contains(ext.toLowerCase());
  }

  void _showFilePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilePickerBottomSheet(
        onCameraTap: () => _handleCamera(context),
        onGalleryTap: () => _handleGallery(context),
        onFileTap: () => _handleFilePicker(context),
      ),
    );
  }

  Future<void> _handleCamera(BuildContext context) async {
    Navigator.pop(context);

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: widget.enableCompression
            ? widget.compressionQuality
            : 100,
        maxWidth: widget.enableCompression ? widget.maxWidth?.toDouble() : null,
        maxHeight: widget.enableCompression
            ? widget.maxHeight?.toDouble()
            : null,
      );

      if (image == null) return;
      await _processImage(image);
    } catch (e) {
      widget.onError?.call('Lỗi khi chụp ảnh: $e');
    }
  }

  Future<void> _handleGallery(BuildContext context) async {
    Navigator.pop(context);

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: widget.enableCompression
            ? widget.compressionQuality
            : 100,
        maxWidth: widget.enableCompression ? widget.maxWidth?.toDouble() : null,
        maxHeight: widget.enableCompression
            ? widget.maxHeight?.toDouble()
            : null,
      );

      if (image == null) return;
      await _processImage(image);
    } catch (e) {
      widget.onError?.call('Lỗi khi chọn ảnh: $e');
    }
  }

  Future<void> _handleFilePicker(BuildContext context) async {
    Navigator.pop(context);

    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: widget.allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: widget.allowedExtensions,
      );

      if (result == null || result.files.isEmpty) return;

      final PlatformFile platformFile = result.files.first;

      if (platformFile.path == null) {
        widget.onError?.call('Không thể đọc file');
        return;
      }

      // ✅ Update controller
      widget.controller?.setFile(platformFile);

      // ✅ Callback
      if (widget.onFileSelected != null) {
        final File file = File(platformFile.path!);
        final fileSize = await file.length();

        final fileResult = CyberFileResult(
          file: file,
          fileName: platformFile.name,
          extension: platformFile.extension ?? '',
          fileSize: fileSize,
          fileType: CyberFileType.file,
          isCompressed: false,
        );

        widget.onFileSelected!(fileResult);
      }
    } catch (e) {
      widget.onError?.call('Lỗi khi chọn file: $e');
    }
  }

  Future<void> _processImage(XFile xFile) async {
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
      final extension = path.extension(fileName).replaceAll('.', '');

      // ✅ Update controller
      widget.controller?.setFile(
        PlatformFile(name: fileName, size: fileSize, path: imageFile.path),
      );

      // ✅ Callback
      if (widget.onFileSelected != null) {
        final result = CyberFileResult(
          file: imageFile,
          fileName: fileName,
          extension: extension,
          fileSize: fileSize,
          fileType: CyberFileType.image,
          isCompressed: widget.enableCompression,
        );

        widget.onFileSelected!(result);
      }
    } catch (e) {
      widget.onError?.call('Lỗi khi xử lý ảnh: $e');
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
      return null;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// ============================================================================
/// BOTTOM SHEET
/// ============================================================================
class _FilePickerBottomSheet extends StatelessWidget {
  final VoidCallback onCameraTap;
  final VoidCallback onGalleryTap;
  final VoidCallback onFileTap;

  const _FilePickerBottomSheet({
    required this.onCameraTap,
    required this.onGalleryTap,
    required this.onFileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    'Chọn nguồn',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            _buildOption(
              icon: Icons.camera_alt,
              iconColor: Colors.blue,
              label: 'Chụp ảnh',
              subtitle: 'Sử dụng camera',
              onTap: onCameraTap,
            ),

            _buildOption(
              icon: Icons.photo_library,
              iconColor: Colors.green,
              label: 'Chọn ảnh',
              subtitle: 'Từ thư viện ảnh',
              onTap: onGalleryTap,
            ),

            _buildOption(
              icon: Icons.folder_open,
              iconColor: Colors.orange,
              label: 'Chọn tệp tin',
              subtitle: 'Từ bộ nhớ thiết bị',
              onTap: onFileTap,
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
