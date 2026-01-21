import 'package:cyberframework/cyberframework.dart';
import 'package:http/http.dart' as http;

/// Enum định nghĩa loại nguồn file
enum UploadSourceType {
  filePath, // Đường dẫn file: "/storage/photo.jpg"
  url, // URL: "https://example.com/image.jpg"
  base64, // String base64
  fileObject, // File object
  bytes, // Uint8List / List<int>
  xfile, // XFile (từ image_picker)
  unknown,
}

/// Class đại diện cho một object cần upload
///
/// Hỗ trợ nhiều loại input:
/// - File path: String đường dẫn file
/// - URL: String URL để download
/// - Base64: String base64 đã encode
/// - File: File object
/// - Bytes: Uint8List hoặc List<int>
/// - XFile: XFile từ image_picker
///
/// Ví dụ:
/// ```dart
/// // Từ file path
/// UploadObject.fromPath('/storage/photo.jpg', filePath: '/images/photo.jpg')
///
/// // Từ URL
/// UploadObject.fromUrl('https://example.com/image.jpg', filePath: '/downloads/image.jpg')
///
/// // Từ base64
/// UploadObject.fromBase64(base64String, filePath: '/encoded/file.jpg')
///
/// // Từ File object
/// UploadObject.fromFile(fileObject, filePath: '/files/document.pdf')
///
/// // Từ bytes
/// UploadObject.fromBytes(uint8List, filePath: '/bytes/data.bin')
///
/// // Auto detect
/// UploadObject.auto(anyObject, filePath: '/auto/file.jpg')
/// ```
class UploadObject {
  /// Nguồn data gốc
  final dynamic source;

  /// Loại nguồn
  final UploadSourceType sourceType;

  /// File path đích (optional, nếu null sẽ tự động sinh)
  final String? filePath;

  /// Base64 data (cached sau khi convert)
  String? _cachedBase64;

  /// File path đã được xử lý (cached)
  String? _cachedFilePath;

  UploadObject._({
    required this.source,
    required this.sourceType,
    this.filePath,
  });

  // ============================================================================
  // FACTORY CONSTRUCTORS
  // ============================================================================

  /// Tạo từ file path
  factory UploadObject.fromPath(String path, {String? filePath}) {
    return UploadObject._(
      source: path,
      sourceType: UploadSourceType.filePath,
      filePath: filePath,
    );
  }

  /// Tạo từ URL
  factory UploadObject.fromUrl(String url, {String? filePath}) {
    return UploadObject._(
      source: url,
      sourceType: UploadSourceType.url,
      filePath: filePath,
    );
  }

  /// Tạo từ base64 string
  factory UploadObject.fromBase64(String base64, {String? filePath}) {
    return UploadObject._(
      source: base64,
      sourceType: UploadSourceType.base64,
      filePath: filePath,
    );
  }

  /// Tạo từ File object
  factory UploadObject.fromFile(File file, {String? filePath}) {
    return UploadObject._(
      source: file,
      sourceType: UploadSourceType.fileObject,
      filePath: filePath,
    );
  }

  /// Tạo từ bytes
  factory UploadObject.fromBytes(dynamic bytes, {String? filePath}) {
    return UploadObject._(
      source: bytes,
      sourceType: UploadSourceType.bytes,
      filePath: filePath,
    );
  }

  /// Tạo từ XFile (image_picker)
  factory UploadObject.fromXFile(dynamic xfile, {String? filePath}) {
    return UploadObject._(
      source: xfile,
      sourceType: UploadSourceType.xfile,
      filePath: filePath,
    );
  }

  /// Tự động detect loại và tạo UploadObject
  ///
  /// Ví dụ:
  /// ```dart
  /// UploadObject.auto('/storage/photo.jpg')
  /// UploadObject.auto('https://example.com/image.jpg')
  /// UploadObject.auto(base64String)
  /// UploadObject.auto(fileObject)
  /// UploadObject.auto(uint8List)
  /// ```
  factory UploadObject.auto(dynamic source, {String? filePath}) {
    final sourceType = _detectSourceType(source);
    return UploadObject._(
      source: source,
      sourceType: sourceType,
      filePath: filePath,
    );
  }

  // ============================================================================
  // AUTO DETECTION
  // ============================================================================

  /// Tự động detect loại nguồn
  static UploadSourceType _detectSourceType(dynamic source) {
    if (source == null) return UploadSourceType.unknown;

    // Check XFile first (has path property)
    if (source.runtimeType.toString().contains('XFile')) {
      return UploadSourceType.xfile;
    }

    // Check File object
    if (source is File) {
      return UploadSourceType.fileObject;
    }

    // Check bytes
    if (source is List<int> ||
        source.runtimeType.toString().contains('Uint8List')) {
      return UploadSourceType.bytes;
    }

    // Check String
    if (source is String) {
      final str = source.trim();

      // Check URL (http/https)
      if (str.startsWith('http://') || str.startsWith('https://')) {
        return UploadSourceType.url;
      }

      // Check base64 (long string without path separators)
      // Base64 strings are typically long and don't contain / or \
      if (str.length > 100 && !str.contains('/') && !str.contains('\\')) {
        // Try to decode to verify it's base64
        try {
          base64.decode(str);
          return UploadSourceType.base64;
        } catch (e) {
          // Not base64
        }
      }

      // Check file path (contains / or \ or looks like a path)
      if (str.contains('/') || str.contains('\\') || str.contains('.')) {
        return UploadSourceType.filePath;
      }

      // Default to base64 for other strings
      return UploadSourceType.base64;
    }

    return UploadSourceType.unknown;
  }

  // ============================================================================
  // CONVERSION TO BASE64
  // ============================================================================

  /// Convert source sang base64
  Future<String> toBase64() async {
    // Return cached nếu đã convert
    if (_cachedBase64 != null) return _cachedBase64!;

    String base64Data;

    switch (sourceType) {
      case UploadSourceType.base64:
        // Đã là base64
        base64Data = source as String;
        break;

      case UploadSourceType.filePath:
        // Đọc file từ path
        final file = File(source as String);
        if (!await file.exists()) {
          throw Exception('File không tồn tại: ${source}');
        }
        final bytes = await file.readAsBytes();
        base64Data = base64Encode(bytes);
        break;

      case UploadSourceType.url:
        // Download từ URL
        base64Data = await _downloadAndEncode(source as String);
        break;

      case UploadSourceType.fileObject:
        // Đọc từ File object
        final file = source as File;
        if (!await file.exists()) {
          throw Exception('File không tồn tại: ${file.path}');
        }
        final bytes = await file.readAsBytes();
        base64Data = base64Encode(bytes);
        break;

      case UploadSourceType.bytes:
        // Convert bytes sang base64
        final bytes = source is List<int>
            ? Uint8List.fromList(source as List<int>)
            : source as Uint8List;
        base64Data = base64Encode(bytes);
        break;

      case UploadSourceType.xfile:
        // Đọc từ XFile
        try {
          // XFile has readAsBytes method
          final bytes = await (source as dynamic).readAsBytes();
          base64Data = base64Encode(bytes as List<int>);
        } catch (e) {
          throw Exception('Không thể đọc XFile: $e');
        }
        break;

      case UploadSourceType.unknown:
      default:
        throw Exception('Không thể xác định loại nguồn: ${source.runtimeType}');
    }

    // Cache kết quả
    _cachedBase64 = base64Data;
    return base64Data;
  }

  /// Download file từ URL và encode sang base64
  Future<String> _downloadAndEncode(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception(
          'Không thể download file từ URL: ${response.statusCode}',
        );
      }

      return base64Encode(response.bodyBytes);
    } catch (e) {
      throw Exception('Lỗi khi download từ URL: $e');
    }
  }

  // ============================================================================
  // FILE PATH GENERATION
  // ============================================================================

  /// Lấy hoặc tạo file path
  Future<String> getFilePath() async {
    // Return cached nếu đã xử lý
    if (_cachedFilePath != null) return _cachedFilePath!;

    String resultPath;

    // Nếu đã có filePath được chỉ định
    if (filePath != null && filePath!.isNotEmpty) {
      resultPath = filePath!;
    } else {
      // Tự động tạo file path
      resultPath = await _generateFilePath();
    }

    // Cache kết quả
    _cachedFilePath = resultPath;
    return resultPath;
  }

  /// Tự động tạo file path dựa trên source
  Future<String> _generateFilePath() async {
    String fileName;
    String? extension;

    switch (sourceType) {
      case UploadSourceType.filePath:
        // Lấy tên file từ path
        final file = File(source as String);
        fileName = file.path.split('/').last.split('\\').last;
        break;

      case UploadSourceType.url:
        // Lấy tên file từ URL
        final uri = Uri.parse(source as String);
        fileName = uri.pathSegments.isNotEmpty
            ? uri.pathSegments.last
            : 'download_${DateTime.now().millisecondsSinceEpoch}';
        break;

      case UploadSourceType.fileObject:
        // Lấy tên file từ File object
        final file = source as File;
        fileName = file.path.split('/').last.split('\\').last;
        break;

      case UploadSourceType.xfile:
        // Lấy tên file từ XFile
        try {
          fileName = (source as dynamic).name as String;
        } catch (e) {
          fileName = 'xfile_${DateTime.now().millisecondsSinceEpoch}';
        }
        break;

      case UploadSourceType.base64:
      case UploadSourceType.bytes:
      default:
        // Tạo tên file mới với timestamp
        fileName = 'file_${DateTime.now().millisecondsSinceEpoch}';

        // Try to detect extension from base64/bytes if possible
        if (sourceType == UploadSourceType.base64) {
          extension = _detectExtensionFromBase64(source as String);
        }

        if (extension != null) {
          fileName = '$fileName.$extension';
        }
        break;
    }

    // Nếu fileName không có extension, thêm .bin
    if (!fileName.contains('.')) {
      fileName = '$fileName.bin';
    }

    // Return file path (không có subfolder, sẽ auto generate GUID)
    return fileName;
  }

  /// Detect file extension từ base64 header
  String? _detectExtensionFromBase64(String base64String) {
    try {
      // Decode first few bytes to check magic numbers
      final bytes = base64.decode(
        base64String.substring(0, min(100, base64String.length)),
      );

      // Check magic numbers
      if (bytes.length >= 2) {
        // JPEG
        if (bytes[0] == 0xFF && bytes[1] == 0xD8) return 'jpg';

        // PNG
        if (bytes[0] == 0x89 && bytes[1] == 0x50) return 'png';

        // GIF
        if (bytes[0] == 0x47 && bytes[1] == 0x49) return 'gif';

        // PDF
        if (bytes[0] == 0x25 && bytes[1] == 0x50) return 'pdf';

        // ZIP
        if (bytes[0] == 0x50 && bytes[1] == 0x4B) return 'zip';
      }
    } catch (e) {
      // Ignore decode errors
    }

    return null;
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  /// Get source type name
  String get sourceTypeName {
    switch (sourceType) {
      case UploadSourceType.filePath:
        return 'File Path';
      case UploadSourceType.url:
        return 'URL';
      case UploadSourceType.base64:
        return 'Base64';
      case UploadSourceType.fileObject:
        return 'File Object';
      case UploadSourceType.bytes:
        return 'Bytes';
      case UploadSourceType.xfile:
        return 'XFile';
      case UploadSourceType.unknown:
        return 'Unknown';
    }
  }

  @override
  String toString() {
    return 'UploadObject(type: $sourceTypeName, filePath: ${filePath ?? "auto"})';
  }
}

/// Helper function - min
int min(int a, int b) => a < b ? a : b;
