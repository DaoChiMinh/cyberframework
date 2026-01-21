import 'package:cyberframework/cyberframework.dart';

extension CyberApiExtension on BuildContext {
  Future<ReturnData> callApi({
    required String functionName,
    String? parameter,
    bool showLoading = true,
    bool showError = true,
  }) {
    final dataPost = CyberDataPost(
      functionName: functionName,
      strParameter: parameter,
    );

    return CyberApiService().callApi(
      context: this,
      dataPost: dataPost,
      showLoading: showLoading,
      showError: showError,
    );
  }

  Future<(CyberDataset? ms, bool status)> callApiAndCheck({
    required String functionName,
    String? parameter,
    bool showLoading = true,
    bool showError = true,
    bool isCheckNullData = true,
  }) async {
    final dataPost = CyberDataPost(
      functionName: functionName,
      strParameter: parameter,
    );

    ReturnData returnData = await CyberApiService().callApi(
      context: this,
      dataPost: dataPost,
      showLoading: showLoading,
      showError: showError,
    );

    if (!returnData.isValid()) {
      if (returnData.message != null) {
        await returnData.message!.V_MsgBox(this, type: CyberMsgBoxType.error);
      }
      return (null, false);
    }
    CyberDataset? ds = returnData.toCyberDataset();
    if (ds == null && isCheckNullData) return (null, false);
    if (ds != null) {
      if (!await ds.checkStatus(this)) return (null, false);
    }
    return (ds, true);
  }

  Future<ReturnData> v_dns({
    String dns = '',
    bool showLoading = true,
    bool showError = true,
  }) {
    return CyberApiService().v_dns(
      context: this,
      dns: dns,
      showLoading: showLoading,
      showError: showError,
    );
  }
}

extension CyberApiUploadExtension on BuildContext {
  /// Upload nhiều files với list base64 và list file paths
  ///
  /// File path format: /SubFolder/FileName.FileType
  /// - Có subfolder: "/images/photo.jpg" => SubFolder: "images"
  /// - Không có subfolder: "photo.jpg" => SubFolder tự động sinh theo GUID
  ///
  /// Ví dụ:
  /// ```dart
  /// final result = await context.uploadFiles(
  ///   base64List: [base64Image1, base64Image2],
  ///   filePathList: ['/images/photo1.jpg', 'document.pdf'],
  /// );
  /// ```
  Future<ReturnData> uploadFiles({
    required List<String> base64List,
    required List<String> filePathList,
    bool showLoading = true,
    bool showError = true,
  }) {
    return CyberApiService().uploadFiles(
      context: this,
      base64List: base64List,
      filePathList: filePathList,
      showLoading: showLoading,
      showError: showError,
    );
  }

  /// Upload 1 file với base64 và file path
  ///
  /// Ví dụ:
  /// ```dart
  /// final result = await context.uploadSingleFile(
  ///   base64Data: base64Image,
  ///   filePath: '/images/photo.jpg',
  /// );
  /// ```
  Future<ReturnData> uploadSingleFile({
    required String base64Data,
    required String filePath,
    bool showLoading = true,
    bool showError = true,
  }) {
    return CyberApiService().uploadSingleFile(
      context: this,
      base64Data: base64Data,
      filePath: filePath,
      showLoading: showLoading,
      showError: showError,
    );
  }

  /// Upload file với CyberApiFilePost object (advanced)
  Future<ReturnData> uploadFile({
    required CyberApiFilePost filePost,
    bool showLoading = true,
    bool showError = true,
  }) {
    return CyberApiService().uploadFile(
      context: this,
      filePost: filePost,
      showLoading: showLoading,
      showError: showError,
    );
  }

  /// Upload files và kiểm tra kết quả
  ///
  /// Ví dụ:
  /// ```dart
  /// final (files, status) = await context.uploadFilesAndCheck(
  ///   base64List: [base64Image1, base64Image2],
  ///   filePathList: ['/images/photo1.jpg', '/docs/file.pdf'],
  /// );
  ///
  /// if (status && files != null) {
  ///   for (var file in files) {
  ///     print('Uploaded: ${file.url}');
  ///   }
  /// }
  /// ```
  Future<(List<CyberAPIFileReturn>? files, bool status)> uploadFilesAndCheck({
    required List<String> base64List,
    required List<String> filePathList,
    bool showLoading = true,
    bool showError = true,
  }) async {
    ReturnData returnData = await uploadFiles(
      base64List: base64List,
      filePathList: filePathList,
      showLoading: showLoading,
      showError: showError,
    );

    if (!returnData.isValid()) {
      if (returnData.message != null) {
        await returnData.message!.V_MsgBox(this, type: CyberMsgBoxType.error);
      }
      return (null, false);
    }

    // Parse data to list of CyberAPIFileReturn
    List<CyberAPIFileReturn>? uploadedFiles = _parseUploadedFiles(
      returnData.data,
    );

    return (uploadedFiles, true);
  }

  /// Upload 1 file và kiểm tra kết quả
  Future<(CyberAPIFileReturn? file, bool status)> uploadSingleFileAndCheck({
    required String base64Data,
    required String filePath,
    bool showLoading = true,
    bool showError = true,
  }) async {
    final (files, status) = await uploadFilesAndCheck(
      base64List: [base64Data],
      filePathList: [filePath],
      showLoading: showLoading,
      showError: showError,
    );

    if (status && files != null && files.isNotEmpty) {
      return (files.first, true);
    }

    return (null, false);
  }

  /// Parse uploaded files from return data
  List<CyberAPIFileReturn>? _parseUploadedFiles(dynamic data) {
    if (data == null) return null;

    try {
      if (data is List) {
        return data.map((item) {
          if (item is Map<String, dynamic>) {
            return CyberAPIFileReturn.fromJson(item);
          }
          return CyberAPIFileReturn();
        }).toList();
      } else if (data is Map<String, dynamic>) {
        // Single file return
        return [CyberAPIFileReturn.fromJson(data)];
      }
    } catch (e) {
      debugPrint('❌ Error parsing uploaded files: $e');
    }

    return null;
  }
}

extension CyberApiUploadObjectExtension on BuildContext {
  /// Upload nhiều objects với auto-detection
  ///
  /// Objects có thể là mix của:
  /// - File paths (String)
  /// - URLs (String)
  /// - Base64 strings (String)
  /// - File objects
  /// - Bytes arrays (Uint8List / List<&gt;int&gt;>)
  /// - XFiles (từ image_picker)
  ///
  /// Ví dụ:
  /// ```dart
  /// final result = await context.uploadObjects(
  ///   objects: [
  ///     '/storage/photo.jpg',              // File path
  ///     'https://example.com/img.jpg',     // URL
  ///     base64String,                      // Base64
  ///     File('/path/file.pdf'),            // File
  ///     uint8List,                         // Bytes
  ///     xfile,                             // XFile
  ///   ],
  /// );
  /// ```
  Future<ReturnData> uploadObjects({
    required List<dynamic> objects,
    List<String?>? filePaths,
    bool showLoading = true,
    bool showError = true,
  }) {
    return CyberApiService().uploadObjects(
      context: this,
      objects: objects,
      filePaths: filePaths,
      showLoading: showLoading,
      showError: showError,
    );
  }

  /// Upload 1 object với auto-detection
  ///
  /// Object có thể là:
  /// - File path (String): "/storage/photo.jpg"
  /// - URL (String): "https://example.com/image.jpg"
  /// - Base64 (String): "iVBORw0KGgoAAAANSUhEUgAA..."
  /// - File object: File('/path/to/file.jpg')
  /// - Bytes: Uint8List hoặc List<&gt;int>
  /// - XFile: từ image_picker
  ///
  /// Ví dụ:
  /// ```dart
  /// // Auto detect từ file path
  /// await context.uploadSingleObject(
  ///   object: '/storage/photo.jpg',
  ///   filePath: '/photos/vacation.jpg',
  /// );
  ///
  /// // Auto detect từ URL
  /// await context.uploadSingleObject(
  ///   object: 'https://example.com/image.jpg',
  /// );
  ///
  /// // Auto detect từ File
  /// await context.uploadSingleObject(
  ///   object: File('/path/to/document.pdf'),
  /// );
  /// ```
  Future<ReturnData> uploadSingleObject({
    required dynamic object,
    String? filePath,
    bool showLoading = true,
    bool showError = true,
  }) {
    return CyberApiService().uploadSingleObject(
      context: this,
      object: object,
      filePath: filePath,
      showLoading: showLoading,
      showError: showError,
    );
  }

  /// Upload nhiều objects và parse kết quả
  ///
  /// Ví dụ:
  /// ```dart
  /// final (files, status) = await context.uploadObjectsAndCheck(
  ///   objects: [
  ///     '/storage/photo1.jpg',
  ///     'https://example.com/photo2.jpg',
  ///     base64String,
  ///   ],
  /// );
  ///
  /// if (status && files != null) {
  ///   for (var file in files) {
  ///     print('Uploaded: ${file.url}');
  ///   }
  /// }
  /// ```
  Future<(List<CyberAPIFileReturn>? files, bool status)> uploadObjectsAndCheck({
    required List<dynamic> objects,
    List<String?>? filePaths,
    bool showLoading = true,
    bool showError = true,
  }) async {
    ReturnData returnData = await uploadObjects(
      objects: objects,
      filePaths: filePaths,
      showLoading: showLoading,
      showError: showError,
    );

    if (!returnData.isValid()) {
      if (returnData.message != null) {
        await returnData.message!.V_MsgBox(this, type: CyberMsgBoxType.error);
      }
      return (null, false);
    }

    // Parse data to list of CyberAPIFileReturn
    List<CyberAPIFileReturn>? uploadedFiles = _parseUploadedFiles(
      returnData.cyberObject,
    );

    return (uploadedFiles, true);
  }

  /// Upload 1 object và parse kết quả
  ///
  /// Ví dụ:
  /// ```dart
  /// final (file, status) = await context.uploadSingleObjectAndCheck(
  ///   object: '/storage/photo.jpg',
  ///   filePath: '/photos/vacation.jpg',
  /// );
  ///
  /// if (status && file != null) {
  ///   print('URL: ${file.url}');
  ///   print('ID: ${file.id}');
  /// }
  /// ```
  Future<(CyberAPIFileReturn? file, bool status)> uploadSingleObjectAndCheck({
    required dynamic object,
    String? filePath,
    bool showLoading = true,
    bool showError = true,
  }) async {
    final (files, status) = await uploadObjectsAndCheck(
      objects: [object],
      filePaths: filePath != null ? [filePath] : null,
      showLoading: showLoading,
      showError: showError,
    );

    if (status && files != null && files.isNotEmpty) {
      return (files.first, true);
    }

    return (null, false);
  }

  /// Parse uploaded files from return data
  List<CyberAPIFileReturn>? _parseUploadedFiles(dynamic data) {
    if (data == null) return null;

    try {
      if (data is List) {
        return data.map((item) {
          if (item is Map<String, dynamic>) {
            return CyberAPIFileReturn.fromJson(item);
          }
          return CyberAPIFileReturn();
        }).toList();
      } else if (data is Map<String, dynamic>) {
        // Single file return
        return [CyberAPIFileReturn.fromJson(data)];
      }
    } catch (e) {
      debugPrint('❌ Error parsing uploaded files: $e');
    }

    return null;
  }
}
