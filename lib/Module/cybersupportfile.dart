import 'package:cyberframework/cyberframework.dart';
import 'package:file_picker/file_picker.dart';

/// Enum định nghĩa các loại file có thể chọn
enum FilePickerType { pdf, image, doc, camera, file }

/// Model cho thông tin file đã chọn
class CyberFilePickerResult {
  String fileName;
  String fileType;
  int fileSize;
  String? strBase64;
  String? urlFile;
  File? fileObject;

  CyberFilePickerResult({
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    this.strBase64,
    this.urlFile,
    this.fileObject,
  });

  /// Convert sang CyberDataRow
  CyberDataRow toCyberDataRow() {
    return CyberDataRow()
      ..setValue('file_name', fileName)
      ..setValue('file_type', fileType)
      ..setValue('file_size', fileSize)
      ..setValue('strbase64', strBase64 ?? '')
      ..setValue('url', urlFile ?? '');
  }

  /// Convert sang Map
  Map<String, dynamic> toMap() {
    return {
      'file_name': fileName,
      'file_type': fileType,
      'file_size': fileSize,
      'strbase64': strBase64 ?? '',
      'url': urlFile ?? '',
    };
  }
}

/// Extension để show file picker với ActionSheet
extension CyberFilePickerExtension on BuildContext {
  /// Hiển thị ActionSheet để chọn file và tự động upload
  ///
  /// [actions]: Danh sách các chức năng hiển thị
  /// [types]: Danh sách loại file tương ứng với actions
  /// [autoUpload]: true = tự động upload và trả về URL, false = chỉ trả về thông tin file
  /// [uploadFilePath]: Đường dẫn lưu file trên server (optional)
  /// [title]: Tiêu đề của ActionSheet
  /// [cancelLabel]: Text của nút Cancel
  /// [isChangeName]: true = hiển thị dialog đổi tên trước khi upload
  ///
  /// Returns: CyberFilePickerResult chứa thông tin file đã chọn/upload
  Future<CyberFilePickerResult?> showFilePickerActionSheet({
    required List<String> actions,
    required List<FilePickerType> types,
    bool autoUpload = true,
    String? uploadFilePath,
    String? title,
    String? cancelLabel,
    bool isChangeName = false,
  }) async {
    // Validate input
    if (actions.isEmpty || types.isEmpty) {
      throw ArgumentError('actions và types không được rỗng');
    }

    if (actions.length != types.length) {
      throw ArgumentError(
        'actions và types phải có cùng số lượng phần tử. '
        'Got ${actions.length} actions và ${types.length} types.',
      );
    }

    // Hiển thị Bottom Sheet và lấy index được chọn
    final selectedIndex = await showModalBottomSheet<int>(
      context: this,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _FilePickerOptionsSheet(
        title: title ?? 'Chọn tệp tin',
        actions: actions,
        types: types,
        onOptionSelected: (index) {
          // Trả về index và đóng bottom sheet
          Navigator.pop(context, index);
        },
        onClose: () {
          Navigator.pop(context, null);
        },
      ),
    );

    // Nếu user không chọn gì (đóng bottom sheet)
    if (selectedIndex == null) {
      return null;
    }

    // Xử lý chọn file SAU KHI bottom sheet đã đóng
    try {
      final result = await _handleFilePicker(
        this,
        types[selectedIndex],
        autoUpload,
        uploadFilePath,
        isChangeName,
      );
      return result;
    } catch (e) {
      debugPrint('❌ Error in showFilePickerActionSheet: $e');
      return null;
    }
  }

  /// Xử lý chọn file theo loại
  Future<CyberFilePickerResult?> _handleFilePicker(
    BuildContext context,
    FilePickerType type,
    bool autoUpload,
    String? uploadFilePath,
    bool isChangeName,
  ) async {
    try {
      CyberFilePickerResult? result;

      switch (type) {
        case FilePickerType.pdf:
          result = await _pickPdfFile(
            context,
            autoUpload,
            uploadFilePath,
            isChangeName,
          );
          break;

        case FilePickerType.image:
          result = await _pickImageFile(
            context,
            autoUpload,
            uploadFilePath,
            isChangeName,
          );
          break;

        case FilePickerType.doc:
          result = await _pickDocFile(
            context,
            autoUpload,
            uploadFilePath,
            isChangeName,
          );
          break;

        case FilePickerType.camera:
          result = await _pickFromCamera(
            context,
            autoUpload,
            uploadFilePath,
            isChangeName,
          );
          break;

        case FilePickerType.file:
          result = await _pickAnyFile(
            context,
            autoUpload,
            uploadFilePath,
            isChangeName,
          );
          break;
      }

      return result;
    } catch (e) {
      debugPrint('❌ Error picking file: $e');

      // Kiểm tra xem có phải lỗi quyền không
      if (e.toString().contains('background') ||
          e.toString().contains('permission')) {
        if (context.mounted) {
          await _showPermissionError(context);
        }
      } else {
        // Hiển thị lỗi cho user
        if (context.mounted) {
          await 'Không thể chọn file. Vui lòng thử lại.'.V_MsgBox(
            context,
            type: CyberMsgBoxType.error,
          );
        }
      }

      return null;
    }
  }

  /// Hiển thị lỗi quyền
  Future<void> _showPermissionError(BuildContext context) async {
    await 'Ứng dụng cần quyền truy cập camera/thư viện ảnh. Vui lòng cấp quyền trong Cài đặt.'
        .V_MsgBox(context, type: CyberMsgBoxType.error);
  }

  /// Chọn file PDF
  Future<CyberFilePickerResult?> _pickPdfFile(
    BuildContext context,
    bool autoUpload,
    String? uploadFilePath,
    bool isChangeName,
  ) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null || result.files.isEmpty) return null;

      return await _processPickedFile(
        context,
        result.files.first,
        autoUpload,
        uploadFilePath,
        isChangeName,
      );
    } catch (e) {
      debugPrint('❌ Error picking PDF: $e');
      return null;
    }
  }

  /// Chọn file ảnh từ thư viện - Dùng ImagePicker giống CyberImage
  Future<CyberFilePickerResult?> _pickImageFile(
    BuildContext context,
    bool autoUpload,
    String? uploadFilePath,
    bool isChangeName,
  ) async {
    try {
      final ImagePicker picker = ImagePicker();

      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return null;

      // Convert XFile sang File
      final file = File(image.path);

      // Kiểm tra file có tồn tại không
      if (!await file.exists()) {
        throw Exception('File không tồn tại sau khi chọn ảnh');
      }

      final bytes = await file.readAsBytes();
      final fileSize = bytes.length;
      final fileName = image.name.isNotEmpty
          ? image.name
          : 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final fileType = fileName.split('.').last.toLowerCase();

      // Tạo CyberFilePickerResult
      return await _processFileData(
        context,
        fileName: fileName,
        fileType: fileType,
        fileSize: fileSize,
        fileBytes: bytes,
        fileObject: file,
        autoUpload: autoUpload,
        uploadFilePath: uploadFilePath,
        isChangeName: isChangeName,
      );
    } catch (e) {
      debugPrint('❌ Error picking image: $e');

      if (context.mounted) {
        if (e.toString().contains('background') ||
            e.toString().contains('permission')) {
          await _showPermissionError(context);
        } else {
          await 'Không thể chọn ảnh. Vui lòng thử lại.'.V_MsgBox(
            context,
            type: CyberMsgBoxType.error,
          );
        }
      }

      return null;
    }
  }

  /// Chọn file DOC/DOCX
  Future<CyberFilePickerResult?> _pickDocFile(
    BuildContext context,
    bool autoUpload,
    String? uploadFilePath,
    bool isChangeName,
  ) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['doc', 'docx'],
      );

      if (result == null || result.files.isEmpty) return null;

      return await _processPickedFile(
        context,
        result.files.first,
        autoUpload,
        uploadFilePath,
        isChangeName,
      );
    } catch (e) {
      debugPrint('❌ Error picking doc: $e');
      return null;
    }
  }

  /// Chụp ảnh từ camera
  Future<CyberFilePickerResult?> _pickFromCamera(
    BuildContext context,
    bool autoUpload,
    String? uploadFilePath,
    bool isChangeName,
  ) async {
    try {
      final ImagePicker picker = ImagePicker();

      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo == null) return null;

      // Convert XFile sang File
      final file = File(photo.path);

      // Kiểm tra file có tồn tại không
      if (!await file.exists()) {
        throw Exception('File không tồn tại sau khi chụp ảnh');
      }

      final bytes = await file.readAsBytes();
      final fileSize = bytes.length;
      final fileName = photo.name.isNotEmpty
          ? photo.name
          : 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final fileType = fileName.split('.').last.toLowerCase();

      // Tạo CyberFilePickerResult
      return await _processFileData(
        context,
        fileName: fileName,
        fileType: fileType,
        fileSize: fileSize,
        fileBytes: bytes,
        fileObject: file,
        autoUpload: autoUpload,
        uploadFilePath: uploadFilePath,
        isChangeName: isChangeName,
      );
    } on Exception catch (e) {
      debugPrint('❌ Camera error: $e');

      // Kiểm tra lỗi cụ thể
      if (context.mounted) {
        if (e.toString().contains('background')) {
          await _showPermissionError(context);
        } else {
          await 'Không thể mở camera. Vui lòng thử lại.'.V_MsgBox(
            context,
            type: CyberMsgBoxType.error,
          );
        }
      }

      return null;
    }
  }

  /// Chọn bất kỳ loại file nào
  Future<CyberFilePickerResult?> _pickAnyFile(
    BuildContext context,
    bool autoUpload,
    String? uploadFilePath,
    bool isChangeName,
  ) async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.any);

      if (result == null || result.files.isEmpty) return null;

      return await _processPickedFile(
        context,
        result.files.first,
        autoUpload,
        uploadFilePath,
        isChangeName,
      );
    } catch (e) {
      debugPrint('❌ Error picking file: $e');
      return null;
    }
  }

  /// Xử lý file đã chọn từ FilePicker
  Future<CyberFilePickerResult?> _processPickedFile(
    BuildContext context,
    PlatformFile platformFile,
    bool autoUpload,
    String? uploadFilePath,
    bool isChangeName,
  ) async {
    try {
      final fileName = platformFile.name;
      final fileType = platformFile.extension ?? '';
      final fileSize = platformFile.size;

      // Lấy bytes
      Uint8List? fileBytes;
      File? fileObject;

      if (platformFile.path != null) {
        fileObject = File(platformFile.path!);
        fileBytes = await fileObject.readAsBytes();
      } else if (platformFile.bytes != null) {
        fileBytes = platformFile.bytes!;
      } else {
        throw Exception('Không thể đọc file');
      }

      return await _processFileData(
        context,
        fileName: fileName,
        fileType: fileType,
        fileSize: fileSize,
        fileBytes: fileBytes,
        fileObject: fileObject,
        autoUpload: autoUpload,
        uploadFilePath: uploadFilePath,
        isChangeName: isChangeName,
      );
    } catch (e) {
      debugPrint('❌ Error processing file: $e');
      return null;
    }
  }

  /// Xử lý dữ liệu file và upload (nếu cần)
  Future<CyberFilePickerResult?> _processFileData(
    BuildContext context, {
    required String fileName,
    required String fileType,
    required int fileSize,
    required Uint8List fileBytes,
    File? fileObject,
    required bool autoUpload,
    String? uploadFilePath,
    bool isChangeName = false,
  }) async {
    try {
      // Convert sang base64
      final strBase64 = base64Encode(fileBytes);

      // Lấy tên file (không có extension)
      String fileNameWithoutExt = fileName;
      String extension = fileType;

      if (fileName.contains('.')) {
        final lastDotIndex = fileName.lastIndexOf('.');
        fileNameWithoutExt = fileName.substring(0, lastDotIndex);
        extension = fileName.substring(lastDotIndex + 1);
      }

      // Nếu isChangeName = true, hiển thị dialog đổi tên
      String finalFileName = fileName;
      if (isChangeName && context.mounted) {
        final newName = await _showChangeNameDialog(
          context,
          fileNameWithoutExt,
          extension,
        );

        // Nếu user cancel dialog
        if (newName == null) {
          return null;
        }

        finalFileName = newName;
        // Cập nhật fileType nếu extension thay đổi
        if (finalFileName.contains('.')) {
          fileType = finalFileName.split('.').last.toLowerCase();
        }
      }

      // Nếu không auto upload, trả về thông tin file
      if (!autoUpload) {
        return CyberFilePickerResult(
          fileName: finalFileName,
          fileType: fileType,
          fileSize: fileSize,
          strBase64: strBase64,
          fileObject: fileObject,
        );
      }

      // Tự động upload file
      try {
        // Tạo upload path
        final finalUploadPath = uploadFilePath != null
            ? '$uploadFilePath$finalFileName'
            : '/$finalFileName';

        debugPrint('🚀 Starting upload: $finalUploadPath');

        // Upload sử dụng uploadSingleObjectAndCheck
        if (!context.mounted) {
          debugPrint('❌ Context not mounted, cannot upload');
          return CyberFilePickerResult(
            fileName: finalFileName,
            fileType: fileType,
            fileSize: fileSize,
            strBase64: strBase64,
            fileObject: fileObject,
          );
        }

        final (uploadedFile, status) = await context.uploadSingleObjectAndCheck(
          object: fileBytes,
          filePath: finalUploadPath,
          showLoading: true,
          showError: false, // Tắt auto show error để xử lý thủ công
        );

        if (!status || uploadedFile == null) {
          debugPrint('❌ Upload failed: status=$status, file=$uploadedFile');

          // Hiển thị lỗi nếu context còn mounted
          if (context.mounted) {
            await 'Upload file thất bại. Vui lòng thử lại.'.V_MsgBox(
              context,
              type: CyberMsgBoxType.error,
            );
          }

          // Trả về kết quả không có URL
          return CyberFilePickerResult(
            fileName: finalFileName,
            fileType: fileType,
            fileSize: fileSize,
            strBase64: strBase64,
            fileObject: fileObject,
          );
        }

        debugPrint('✅ Upload success: ${uploadedFile.url}');

        // Trả về kết quả với URL
        // Luôn dùng finalFileName (tên mới nếu isChangeName = true)
        return CyberFilePickerResult(
          fileName: finalFileName,
          fileType: fileType,
          fileSize: fileSize,
          strBase64: strBase64,
          urlFile: uploadedFile.url,
          fileObject: fileObject,
        );
      } catch (uploadError) {
        debugPrint('❌ Upload exception: $uploadError');

        // Hiển thị lỗi nếu context còn mounted
        if (context.mounted) {
          await 'Upload file thất bại. Vui lòng thử lại.'.V_MsgBox(
            context,
            type: CyberMsgBoxType.error,
          );
        }

        // Trả về kết quả không có URL
        return CyberFilePickerResult(
          fileName: finalFileName,
          fileType: fileType,
          fileSize: fileSize,
          strBase64: strBase64,
          fileObject: fileObject,
        );
      }
    } catch (e) {
      debugPrint('❌ Process file data error: $e');
      return null;
    }
  }

  /// Hiển thị dialog đổi tên file
  Future<String?> _showChangeNameDialog(
    BuildContext context,
    String currentName,
    String extension,
  ) async {
    return await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ChangeFileNameSheet(
        currentName: currentName,
        extension: extension,
        onConfirm: (newName) {
          Navigator.pop(context, newName);
        },
        onCancel: () {
          Navigator.pop(context, null);
        },
      ),
    );
  }
}

/// ============================================================================
/// File Picker Options Bottom Sheet - Giao diện giống CyberImage
/// ============================================================================

class _FilePickerOptionsSheet extends StatelessWidget {
  final String title;
  final List<String> actions;
  final List<FilePickerType> types;
  final void Function(int index) onOptionSelected;
  final VoidCallback onClose;

  const _FilePickerOptionsSheet({
    required this.title,
    required this.actions,
    required this.types,
    required this.onOptionSelected,
    required this.onClose,
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
            // Thanh kéo
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header với title và nút close
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: onClose),
                ],
              ),
            ),
            const Divider(height: 1),
            // Danh sách options
            ...List.generate(actions.length, (index) {
              final type = types[index];
              final action = actions[index];

              return _buildOption(
                icon: _getIconForType(type),
                iconColor: _getColorForType(type),
                label: action,
                subtitle: _getSubtitleForType(type),
                onTap: () => onOptionSelected(index),
              );
            }),
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

  /// Lấy icon tương ứng với loại file
  IconData _getIconForType(FilePickerType type) {
    switch (type) {
      case FilePickerType.pdf:
        return Icons.picture_as_pdf;
      case FilePickerType.image:
        return Icons.photo_library;
      case FilePickerType.doc:
        return Icons.description;
      case FilePickerType.camera:
        return Icons.camera_alt;
      case FilePickerType.file:
        return Icons.attach_file;
    }
  }

  /// Lấy màu tương ứng với loại file
  Color _getColorForType(FilePickerType type) {
    switch (type) {
      case FilePickerType.pdf:
        return Colors.red;
      case FilePickerType.image:
        return Colors.green;
      case FilePickerType.doc:
        return Colors.blue;
      case FilePickerType.camera:
        return Colors.blue;
      case FilePickerType.file:
        return Colors.orange;
    }
  }

  /// Lấy subtitle tương ứng với loại file
  String _getSubtitleForType(FilePickerType type) {
    switch (type) {
      case FilePickerType.pdf:
        return 'Chọn file PDF';
      case FilePickerType.image:
        return 'Từ thư viện ảnh';
      case FilePickerType.doc:
        return 'Chọn file Word';
      case FilePickerType.camera:
        return 'Sử dụng camera';
      case FilePickerType.file:
        return 'Chọn bất kỳ file nào';
    }
  }
}

/// ============================================================================
/// Change File Name Bottom Sheet - Dialog đổi tên file
/// ============================================================================

class _ChangeFileNameSheet extends StatefulWidget {
  final String currentName;
  final String extension;
  final void Function(String newName) onConfirm;
  final VoidCallback onCancel;

  const _ChangeFileNameSheet({
    required this.currentName,
    required this.extension,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<_ChangeFileNameSheet> createState() => _ChangeFileNameSheetState();
}

class _ChangeFileNameSheetState extends State<_ChangeFileNameSheet> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
    _focusNode = FocusNode();

    // Auto focus và select all text
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _validateAndConfirm() {
    final newName = _controller.text.trim();

    if (newName.isEmpty) {
      setState(() {
        _errorText = 'Tên file không được để trống';
      });
      return;
    }

    // Kiểm tra ký tự không hợp lệ
    final invalidChars = RegExp(r'[<>:"/\\|?*]');
    if (invalidChars.hasMatch(newName)) {
      setState(() {
        _errorText = 'Tên file chứa ký tự không hợp lệ';
      });
      return;
    }

    // Thêm extension nếu có
    final finalName = widget.extension.isNotEmpty
        ? '$newName.${widget.extension}'
        : newName;

    widget.onConfirm(finalName);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Thêm padding khi keyboard hiện lên
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Thanh kéo
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Text(
                      setText('Đổi tên file', "Rename files"),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: widget.onCancel,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon và thông tin file
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.edit_document,
                            color: Colors.blue,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                setText(
                                  'Nhập tên file mới',
                                  "Enter a new file name",
                                ),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.extension.isNotEmpty
                                    ? 'Extension: .${widget.extension}'
                                    : 'Không có extension',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Text field
                    TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      decoration: InputDecoration(
                        labelText: setText('Tên file', 'File name'),
                        hintText: setText('Nhập tên file', "Enter file name"),
                        errorText: _errorText,
                        suffixText: widget.extension.isNotEmpty
                            ? '.${widget.extension}'
                            : null,
                        suffixStyle: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.blue,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.red,
                            width: 1,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onChanged: (_) {
                        if (_errorText != null) {
                          setState(() => _errorText = null);
                        }
                      },
                      onSubmitted: (_) => _validateAndConfirm(),
                    ),
                    const SizedBox(height: 20),
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.onCancel,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: Colors.grey[400]!),
                            ),
                            child: Text(
                              setText('Hủy', 'Cancel'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _validateAndConfirm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              setText('Xác nhận', 'Confirm'),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
