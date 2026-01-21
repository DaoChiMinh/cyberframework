import 'dart:io';
import 'package:cyberframework/cyberframework.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

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
  ///
  /// Returns: CyberFilePickerResult chứa thông tin file đã chọn/upload
  Future<CyberFilePickerResult?> showFilePickerActionSheet({
    required List<String> actions,
    required List<FilePickerType> types,
    bool autoUpload = true,
    String? uploadFilePath,
    String? title,
    String? cancelLabel,
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

    // Tạo Completer để đợi kết quả
    final completer = Completer<CyberFilePickerResult?>();
    bool hasCompleted = false;

    // Tạo list CyberActionSheet
    List<CyberActionSheet> actionSheetItems = [];

    for (int i = 0; i < actions.length; i++) {
      final action = actions[i];
      final type = types[i];

      actionSheetItems.add(
        CyberActionSheet(
          label: action,
          icon: _getIconForType(type),
          onclick: () async {
            // Kiểm tra đã complete chưa
            if (hasCompleted) return;

            try {
              // Xử lý chọn file
              final result = await _handleFilePicker(
                this,
                type,
                autoUpload,
                uploadFilePath,
              );

              // Complete completer nếu chưa complete
              if (!hasCompleted && !completer.isCompleted) {
                hasCompleted = true;
                completer.complete(result);
              }
            } catch (e) {
              debugPrint('❌ Error in onclick: $e');
              if (!hasCompleted && !completer.isCompleted) {
                hasCompleted = true;
                completer.complete(null);
              }
            }
          },
        ),
      );
    }

    // Hiển thị ActionSheet
    showCyberCupertinoActionSheet(
      this,
      actionSheetItems,
      title: title ?? 'Chọn tệp tin',
      cancelLabel: cancelLabel ?? 'Hủy',
    );

    // Đợi kết quả từ completer
    return completer.future;
  }

  /// Xử lý chọn file theo loại
  Future<CyberFilePickerResult?> _handleFilePicker(
    BuildContext context,
    FilePickerType type,
    bool autoUpload,
    String? uploadFilePath,
  ) async {
    try {
      CyberFilePickerResult? result;

      switch (type) {
        case FilePickerType.pdf:
          result = await _pickPdfFile(context, autoUpload, uploadFilePath);
          break;

        case FilePickerType.image:
          result = await _pickImageFile(context, autoUpload, uploadFilePath);
          break;

        case FilePickerType.doc:
          result = await _pickDocFile(context, autoUpload, uploadFilePath);
          break;

        case FilePickerType.camera:
          result = await _pickFromCamera(context, autoUpload, uploadFilePath);
          break;

        case FilePickerType.file:
          result = await _pickAnyFile(context, autoUpload, uploadFilePath);
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
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null || result.files.isEmpty) return null;

      return await _processPickedFile(
        context,
        result.files.first,
        autoUpload,
        uploadFilePath,
      );
    } catch (e) {
      debugPrint('❌ Error picking PDF: $e');
      return null;
    }
  }

  /// Chọn file ảnh từ thư viện
  Future<CyberFilePickerResult?> _pickImageFile(
    BuildContext context,
    bool autoUpload,
    String? uploadFilePath,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);

      if (result == null || result.files.isEmpty) return null;

      return await _processPickedFile(
        context,
        result.files.first,
        autoUpload,
        uploadFilePath,
      );
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      return null;
    }
  }

  /// Chọn file DOC/DOCX
  Future<CyberFilePickerResult?> _pickDocFile(
    BuildContext context,
    bool autoUpload,
    String? uploadFilePath,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['doc', 'docx'],
      );

      if (result == null || result.files.isEmpty) return null;

      return await _processPickedFile(
        context,
        result.files.first,
        autoUpload,
        uploadFilePath,
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
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.any);

      if (result == null || result.files.isEmpty) return null;

      return await _processPickedFile(
        context,
        result.files.first,
        autoUpload,
        uploadFilePath,
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
  }) async {
    try {
      // Convert sang base64
      final strBase64 = base64Encode(fileBytes);

      // Nếu không auto upload, trả về thông tin file
      if (!autoUpload) {
        return CyberFilePickerResult(
          fileName: fileName,
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
            ? '$uploadFilePath$fileName'
            : '/$fileName';

        debugPrint('🚀 Starting upload: $finalUploadPath');

        // Upload sử dụng uploadSingleObjectAndCheck
        if (!context.mounted) {
          debugPrint('❌ Context not mounted, cannot upload');
          return CyberFilePickerResult(
            fileName: fileName,
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
            fileName: fileName,
            fileType: fileType,
            fileSize: fileSize,
            strBase64: strBase64,
            fileObject: fileObject,
          );
        }

        debugPrint('✅ Upload success: ${uploadedFile.url}');

        // Trả về kết quả với URL
        return CyberFilePickerResult(
          fileName: uploadedFile.name.isNotEmpty ? uploadedFile.name : fileName,
          fileType: uploadedFile.fileType.isNotEmpty
              ? uploadedFile.fileType
              : fileType,
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
          fileName: fileName,
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

  /// Lấy icon tương ứng với loại file
  IconData _getIconForType(FilePickerType type) {
    switch (type) {
      case FilePickerType.pdf:
        return Icons.picture_as_pdf;
      case FilePickerType.image:
        return Icons.image;
      case FilePickerType.doc:
        return Icons.description;
      case FilePickerType.camera:
        return Icons.camera_alt;
      case FilePickerType.file:
        return Icons.attach_file;
    }
  }
}
