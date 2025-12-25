import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:convert';

/// Loại file được chọn
enum CyberFileType {
  image, // Ảnh từ camera hoặc gallery
  file, // File bất kỳ
}

/// Result data sau khi chọn file
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

/// Callback khi chọn file thành công
typedef OnFileSelected = void Function(CyberFileResult result);

/// Callback khi có lỗi
typedef OnFileError = void Function(String error);

/// CyberFilePicker - Button để chọn ảnh/file với compression
class CyberFilePicker extends StatelessWidget {
  /// Label hiển thị trên button
  final String label;

  /// Icon button
  final IconData? icon;

  /// Callback khi chọn file thành công
  final OnFileSelected onFileSelected;

  /// Callback khi có lỗi
  final OnFileError? onError;

  /// Màu nền button
  final Color? backgroundColor;

  /// Màu text
  final Color? textColor;

  /// Border radius
  final double borderRadius;

  /// Padding
  final EdgeInsets? padding;

  /// Có enable hay không
  final bool enabled;

  /// Có nén ảnh hay không
  final bool enableCompression;

  /// Chất lượng nén (0-100)
  final int compressionQuality;

  /// Kích thước max sau khi nén (width)
  final int? maxWidth;

  /// Kích thước max sau khi nén (height)
  final int? maxHeight;

  /// Allowed file extensions cho file picker
  final List<String>? allowedExtensions;

  /// Cho phép chọn nhiều file
  final bool allowMultiple;

  /// Style cho button
  final ButtonStyle? buttonStyle;

  const CyberFilePicker({
    super.key,
    this.label = "Chọn file",
    this.icon,
    required this.onFileSelected,
    this.onError,
    this.backgroundColor,
    this.textColor,
    this.borderRadius = 8.0,
    this.padding,
    this.enabled = true,
    this.enableCompression = true,
    this.compressionQuality = 85,
    this.maxWidth = 1920,
    this.maxHeight = 1920,
    this.allowedExtensions,
    this.allowMultiple = false,
    this.buttonStyle,
  });

  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return ElevatedButton.icon(
        onPressed: enabled ? () => _showOptions(context) : null,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: buttonStyle ?? _buildButtonStyle(),
      );
    }

    return ElevatedButton(
      onPressed: enabled ? () => _showOptions(context) : null,
      style: buttonStyle ?? _buildButtonStyle(),
      child: Text(label),
    );
  }

  ButtonStyle _buildButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: backgroundColor ?? const Color(0xFF00D287),
      foregroundColor: textColor ?? Colors.white,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  /// Show bottom sheet với 3 options
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

  /// Handle chụp ảnh từ camera
  Future<void> _handleCamera(BuildContext context) async {
    Navigator.pop(context); // Close bottom sheet

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: enableCompression ? compressionQuality : 100,
        maxWidth: enableCompression ? maxWidth?.toDouble() : null,
        maxHeight: enableCompression ? maxHeight?.toDouble() : null,
      );

      if (image == null) return;

      await _processImage(image, isCompressed: enableCompression);
    } catch (e) {
      _handleError('Lỗi khi chụp ảnh: $e');
    }
  }

  /// Handle chọn ảnh từ gallery
  Future<void> _handleGallery(BuildContext context) async {
    Navigator.pop(context); // Close bottom sheet

    try {
      final ImagePicker picker = ImagePicker();

      if (allowMultiple) {
        final List<XFile> images = await picker.pickMultipleMedia(
          imageQuality: enableCompression ? compressionQuality : 100,
          maxWidth: enableCompression ? maxWidth?.toDouble() : null,
          maxHeight: enableCompression ? maxHeight?.toDouble() : null,
        );

        if (images.isEmpty) return;

        // Process first image only (hoặc có thể mở rộng để handle multiple)
        await _processImage(images.first, isCompressed: enableCompression);
      } else {
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: enableCompression ? compressionQuality : 100,
          maxWidth: enableCompression ? maxWidth?.toDouble() : null,
          maxHeight: enableCompression ? maxHeight?.toDouble() : null,
        );

        if (image == null) return;

        await _processImage(image, isCompressed: enableCompression);
      }
    } catch (e) {
      _handleError('Lỗi khi chọn ảnh: $e');
    }
  }

  /// Handle chọn file
  Future<void> _handleFilePicker(BuildContext context) async {
    Navigator.pop(context); // Close bottom sheet

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: allowedExtensions,
        allowMultiple: allowMultiple,
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

      onFileSelected(fileResult);
    } catch (e) {
      _handleError('Lỗi khi chọn file: $e');
    }
  }

  /// Process image (compress if needed)
  Future<void> _processImage(XFile xFile, {bool isCompressed = false}) async {
    try {
      File imageFile = File(xFile.path);

      // ✅ Nén ảnh nếu enable compression
      if (enableCompression && isCompressed) {
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
        isCompressed: enableCompression,
      );

      onFileSelected(result);
    } catch (e) {
      _handleError('Lỗi khi xử lý ảnh: $e');
    }
  }

  /// Compress image using flutter_image_compress
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
        quality: compressionQuality,
        minWidth: maxWidth ?? 1920,
        minHeight: maxHeight ?? 1920,
      );

      if (result == null) return null;

      return File(result.path);
    } catch (e) {
      //debugPrint('Error compressing image: $e');
      return null;
    }
  }

  /// Handle error
  void _handleError(String error) {
    //debugPrint('CyberFilePicker Error: $error');
    onError?.call(error);
  }
}

/// Bottom sheet với 3 options
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
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
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

            // Options
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

/// Extension for base64 encoding

extension Base64Extension on List<int> {
  String base64Encode() => base64.encode(this);
}

/// Helper widget - CyberFilePickerField
/// Hiển thị file đã chọn với preview và button remove
class CyberFilePickerField extends StatefulWidget {
  final String label;
  final String? hint;
  final OnFileSelected onFileSelected;
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
    required this.onFileSelected,
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
  CyberFileResult? _selectedFile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
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

        // Content
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
      onTap: _showFilePicker,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              widget.hint ?? 'Nhấn để chọn file',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePreview() {
    final file = _selectedFile!;
    final isImage = file.fileType == CyberFileType.image;

    return Row(
      children: [
        // Preview
        if (isImage)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              file.file,
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

        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                file.fileName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${_formatFileSize(file.fileSize)}${file.isCompressed ? ' • Đã nén' : ''}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),

        // Remove button
        IconButton(
          icon: const Icon(Icons.close, size: 20),
          onPressed: () {
            setState(() {
              _selectedFile = null;
            });
          },
        ),
      ],
    );
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

      await _processImage(image, isCompressed: widget.enableCompression);
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

      await _processImage(image, isCompressed: widget.enableCompression);
    } catch (e) {
      widget.onError?.call('Lỗi khi chọn ảnh: $e');
    }
  }

  Future<void> _handleFilePicker(BuildContext context) async {
    Navigator.pop(context);

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: widget.allowedExtensions != null ? FileType.custom : FileType.any,
        allowedExtensions: widget.allowedExtensions,
      );

      if (result == null || result.files.isEmpty) return;

      final PlatformFile platformFile = result.files.first;

      if (platformFile.path == null) {
        widget.onError?.call('Không thể đọc file');
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

      setState(() {
        _selectedFile = fileResult;
      });

      widget.onFileSelected(fileResult);
    } catch (e) {
      widget.onError?.call('Lỗi khi chọn file: $e');
    }
  }

  Future<void> _processImage(XFile xFile, {bool isCompressed = false}) async {
    try {
      File imageFile = File(xFile.path);

      if (widget.enableCompression && isCompressed) {
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

      setState(() {
        _selectedFile = result;
      });

      widget.onFileSelected(result);
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
      //debugPrint('Error compressing image: $e');
      return null;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
