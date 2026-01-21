// lib/Module/file_handler.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_picker/file_picker.dart'; // ✅ ADDED

enum FileSourceType { base64, path, url }

/// ✅ NEW: Track temp files for cleanup
class _TempFileTracker {
  static final Set<String> _tempFiles = {};
  static Timer? _cleanupTimer;

  /// ✅ Register temp file for later cleanup
  static void register(String path) {
    _tempFiles.add(path);
    _startCleanupTimer();
  }

  /// ✅ Remove temp file immediately
  static Future<void> remove(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      _tempFiles.remove(path);
    } catch (e) {
      debugPrint('Error removing temp file: $e');
    }
  }

  /// ✅ Clean up old temp files (older than 1 hour)
  static Future<void> cleanupOldFiles() async {
    final now = DateTime.now();
    final filesToRemove = <String>[];

    for (var path in _tempFiles) {
      try {
        final file = File(path);
        if (!await file.exists()) {
          filesToRemove.add(path);
          continue;
        }

        final stat = await file.stat();
        final age = now.difference(stat.modified);

        // Remove files older than 1 hour
        if (age.inHours >= 1) {
          await file.delete();
          filesToRemove.add(path);
        }
      } catch (e) {
        debugPrint('Error cleaning temp file $path: $e');
        filesToRemove.add(path);
      }
    }

    _tempFiles.removeAll(filesToRemove);
  }

  /// ✅ Start periodic cleanup
  static void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 30),
      (_) => cleanupOldFiles(),
    );
  }

  /// ✅ Clean all temp files
  static Future<void> cleanAll() async {
    for (var path in _tempFiles.toList()) {
      await remove(path);
    }
    _cleanupTimer?.cancel();
  }
}

/// ✅ IMPROVED: FileData with cleanup capability
class FileData {
  final Uint8List bytes;
  final String path;
  final FileSourceType sourceType;
  final bool isTemp;

  FileData({
    required this.bytes,
    required this.path,
    required this.sourceType,
    this.isTemp = false,
  }) {
    // ✅ Register temp files for cleanup
    if (isTemp) {
      _TempFileTracker.register(path);
    }
  }

  /// ✅ Clean up temp file
  Future<void> cleanup() async {
    if (isTemp) {
      await _TempFileTracker.remove(path);
    }
  }
}

class FileHandler {
  /// Initialize file handler (call in main.dart)
  static void initialize() {
    // Start cleanup timer
    _TempFileTracker.cleanupOldFiles();
  }

  /// Cleanup on app dispose
  static Future<void> dispose() async {
    await _TempFileTracker.cleanAll();
  }

  /// Detect source type
  static FileSourceType detectSourceType(String input) {
    if (input.startsWith('http://') || input.startsWith('https://')) {
      return FileSourceType.url;
    } else if (input.startsWith('data:') || _isBase64(input)) {
      return FileSourceType.base64;
    } else {
      return FileSourceType.path;
    }
  }

  static bool _isBase64(String str) {
    try {
      if (str.isEmpty || str.length % 4 != 0) return false;
      base64Decode(str);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// ✅ IMPROVED: Load file with automatic cleanup
  static Future<FileData> loadFile(String source, String fileExtension) async {
    final sourceType = detectSourceType(source);

    switch (sourceType) {
      case FileSourceType.base64:
        return await _loadFromBase64(source, fileExtension);
      case FileSourceType.path:
        return await _loadFromPath(source);
      case FileSourceType.url:
        return await _loadFromUrl(source, fileExtension);
    }
  }

  /// ✅ FIXED: Mark temp files for cleanup
  static Future<FileData> _loadFromBase64(
    String base64String,
    String ext,
  ) async {
    if (base64String.contains(',')) {
      base64String = base64String.split(',')[1];
    }

    final bytes = base64Decode(base64String);

    final tempDir = await getTemporaryDirectory();
    final fileName = 'temp_${DateTime.now().millisecondsSinceEpoch}$ext';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);

    return FileData(
      bytes: bytes,
      path: file.path,
      sourceType: FileSourceType.base64,
      isTemp: true, // ✅ Mark as temp for cleanup
    );
  }

  static Future<FileData> _loadFromPath(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw Exception('File does not exist: $path');
    }

    final bytes = await file.readAsBytes();

    return FileData(
      bytes: bytes,
      path: path,
      sourceType: FileSourceType.path,
      isTemp: false, // ✅ Not temp - don't cleanup
    );
  }

  /// ✅ FIXED: Mark downloaded files for cleanup
  static Future<FileData> _loadFromUrl(String url, String ext) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: Failed to download file');
    }

    final bytes = response.bodyBytes;

    final tempDir = await getTemporaryDirectory();
    final fileName =
        'temp_download_${DateTime.now().millisecondsSinceEpoch}$ext';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);

    return FileData(
      bytes: bytes,
      path: file.path,
      sourceType: FileSourceType.url,
      isTemp: true, // ✅ Mark as temp for cleanup
    );
  }

  /// ✅ IMPROVED: Share file with cleanup
  static Future<void> shareFile({
    required String source,
    required String fileExtension,
    String? fileName,
    String? subject,
    BuildContext? context,
  }) async {
    FileData? fileData;
    try {
      fileData = await loadFile(source, fileExtension);

      final params = ShareParams(
        text: fileName ?? 'Shared file',
        files: [XFile(fileData.path)],
      );

      await SharePlus.instance.share(params);
    } catch (e) {
      if (context != null && context.mounted) {
        _showError(context, 'Share error: $e');
      }
      rethrow;
    } finally {
      // ✅ Cleanup temp file after sharing
      if (fileData != null) {
        await Future.delayed(const Duration(seconds: 5));
        await fileData.cleanup();
      }
    }
  }

  /// ✅ IMPROVED: Download file with iOS-style file picker
  static Future<String?> downloadFile({
    required String source,
    required String fileExtension,
    String? customFileName,
    BuildContext? context,
  }) async {
    FileData? fileData;
    try {
      // Load file data
      fileData = await loadFile(source, fileExtension);

      // Generate default file name
      final defaultFileName =
          customFileName ??
          'download_${DateTime.now().millisecondsSinceEpoch}$fileExtension';

      // ✅ Show native file picker to choose save location
      final savePath = await FilePicker.platform.saveFile(
        fileName: defaultFileName,
        bytes: fileData.bytes,
        type: _getFileTypeFromExtension(fileExtension),
        allowedExtensions: fileExtension.isNotEmpty
            ? [fileExtension.replaceAll('.', '')]
            : null,
      );

      // User cancelled
      if (savePath == null) {
        if (context != null && context.mounted) {
          _showInfo(context, 'Đã hủy lưu file');
        }
        return null;
      }

      // ✅ On some platforms, we need to manually write the file
      if (Platform.isAndroid || Platform.isIOS) {
        final file = File(savePath);
        await file.writeAsBytes(fileData.bytes);
      }

      if (context != null && context.mounted) {
        _showSuccess(context, 'Đã lưu: ${_getFileNameFromPath(savePath)}');
      }

      return savePath;
    } catch (e) {
      if (context != null && context.mounted) {
        _showError(context, 'Lỗi khi lưu: $e');
      }
      rethrow;
    } finally {
      // ✅ Cleanup temp file after download
      await fileData?.cleanup();
    }
  }

  /// ✅ Helper: Get file type from extension
  static FileType _getFileTypeFromExtension(String extension) {
    final ext = extension.toLowerCase().replaceAll('.', '');

    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        return FileType.image;

      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
        return FileType.video;

      case 'mp3':
      case 'wav':
      case 'aac':
      case 'm4a':
        return FileType.audio;

      default:
        return FileType.any;
    }
  }

  /// ✅ Helper: Extract file name from path
  static String _getFileNameFromPath(String path) {
    return path.split('/').last.split('\\').last;
  }

  static String _getFileExtension(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return '.pdf';
      case 'image':
      case 'img':
      case 'jpg':
      case 'jpeg':
        return '.jpg';
      case 'png':
        return '.png';
      case 'text':
      case 'txt':
        return '.txt';
      case 'excel':
      case 'xls':
      case 'xlsx':
        return '.xlsx';
      case 'word':
      case 'doc':
      case 'docx':
        return '.docx';
      default:
        return '';
    }
  }

  /// ✅ IMPROVED: Print file with cleanup
  static Future<void> printFile({
    required String source,
    required String fileType,
    String? documentName,
    BuildContext? context,
  }) async {
    FileData? fileData;
    try {
      final ext = _getFileExtension(fileType);
      fileData = await loadFile(source, ext);

      switch (fileType.toLowerCase()) {
        case 'pdf':
          await _printPdf(fileData.bytes, documentName);
          break;
        case 'image':
        case 'img':
        case 'jpg':
        case 'jpeg':
        case 'png':
          await _printImage(fileData.bytes, documentName);
          break;
        case 'text':
        case 'txt':
          await _printText(fileData.bytes, documentName);
          break;
        default:
          throw Exception('Unsupported file type: $fileType');
      }
    } catch (e) {
      if (context != null && context.mounted) {
        _showError(context, 'Print error: $e');
      }
      rethrow;
    } finally {
      // ✅ Cleanup temp file after printing
      await fileData?.cleanup();
    }
  }

  static Future<void> _printPdf(Uint8List pdfBytes, String? name) async {
    await Printing.layoutPdf(
      name: name ?? 'document.pdf',
      onLayout: (format) async => pdfBytes,
    );
  }

  static Future<void> _printImage(Uint8List imageBytes, String? name) async {
    final pdf = pw.Document();
    final image = pw.MemoryImage(imageBytes);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) =>
            pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
      ),
    );

    await Printing.layoutPdf(
      name: name ?? 'image.pdf',
      onLayout: (format) async => pdf.save(),
    );
  }

  static Future<void> _printText(Uint8List textBytes, String? name) async {
    final textContent = utf8.decode(textBytes);
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(textContent, style: const pw.TextStyle(fontSize: 12)),
        ],
      ),
    );

    await Printing.layoutPdf(
      name: name ?? 'text.pdf',
      onLayout: (format) async => pdf.save(),
    );
  }

  static void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  static void _showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// ✅ NEW: Manual cleanup trigger
  static Future<void> cleanupTempFiles() async {
    await _TempFileTracker.cleanupOldFiles();
  }
}
