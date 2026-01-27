// lib/Module/file_handler.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cyberframework/cyberframework.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_picker/file_picker.dart';
import 'package:gal/gal.dart';

enum FileSourceType { base64, path, url }

enum MediaType { image, video, audio, document }

/// ✅ Track temp files for cleanup
class _TempFileTracker {
  static final Set<String> _tempFiles = {};
  static Timer? _cleanupTimer;

  /// Register temp file for later cleanup
  static void register(String path) {
    _tempFiles.add(path);
    _startCleanupTimer();
  }

  /// Remove temp file immediately
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

  /// Clean up old temp files (older than 1 hour)
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

  /// Start periodic cleanup
  static void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 30),
      (_) => cleanupOldFiles(),
    );
  }

  /// Clean all temp files
  static Future<void> cleanAll() async {
    for (var path in _tempFiles.toList()) {
      await remove(path);
    }
    _cleanupTimer?.cancel();
  }
}

/// FileData with cleanup capability
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
    if (isTemp) {
      _TempFileTracker.register(path);
    }
  }

  /// Clean up temp file
  Future<void> cleanup() async {
    if (isTemp) {
      await _TempFileTracker.remove(path);
    }
  }
}

class FileHandler {
  /// Initialize file handler (call in main.dart)
  static void initialize() {
    _TempFileTracker.cleanupOldFiles();
  }

  /// Cleanup on app dispose
  static Future<void> dispose() async {
    await _TempFileTracker.cleanAll();
  }

  /// Detect source type (url, base64, or file path)
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

  /// Detect media type from file extension
  static MediaType? detectMediaType(String extension) {
    final ext = extension.toLowerCase().replaceAll('.', '');

    // Image extensions
    if ([
      'jpg',
      'jpeg',
      'png',
      'gif',
      'bmp',
      'webp',
      'heic',
      'heif',
    ].contains(ext)) {
      return MediaType.image;
    }

    // Video extensions
    if ([
      'mp4',
      'mov',
      'avi',
      'mkv',
      'flv',
      'wmv',
      'm4v',
      '3gp',
    ].contains(ext)) {
      return MediaType.video;
    }

    // Audio extensions
    if (['mp3', 'wav', 'aac', 'm4a', 'flac', 'ogg', 'wma'].contains(ext)) {
      return MediaType.audio;
    }

    // Document (non-media)
    return MediaType.document;
  }

  /// Load file from source (base64, path, or url)
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

  /// Load from base64 string
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
      isTemp: true,
    );
  }

  /// Load from file path
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
      isTemp: false,
    );
  }

  /// Load from URL
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
      isTemp: true,
    );
  }

  /// Show file options bottom sheet (Share, Download, Print)
  static Future<void> showFileOptions({
    required BuildContext context,
    required String source,
    required String fileExtension,
    String? fileName,
    String? subject,
    Rect? sharePositionOrigin,
  }) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Chia sẻ'),
              onTap: () {
                Navigator.pop(context);
                shareFile(
                  source: source,
                  fileExtension: fileExtension,
                  fileName: fileName,
                  subject: subject,
                  context: context,
                  sharePositionOrigin: sharePositionOrigin,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Lưu vào thiết bị'),
              onTap: () {
                Navigator.pop(context);
                downloadFile(
                  source: source,
                  fileExtension: fileExtension,
                  customFileName: fileName,
                  context: context,
                );
              },
            ),
            if (fileExtension.toLowerCase() == '.pdf' ||
                _isImageExtension(fileExtension))
              ListTile(
                leading: const Icon(Icons.print),
                title: const Text('In'),
                onTap: () {
                  Navigator.pop(context);
                  printFile(
                    source: source,
                    fileType: _getFileTypeFromExtension(fileExtension),
                    documentName: fileName,
                    context: context,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  static bool _isImageExtension(String ext) {
    final imageExts = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];
    return imageExts.contains(ext.toLowerCase());
  }

  static String _getFileTypeFromExtension(String ext) {
    switch (ext.toLowerCase()) {
      case '.pdf':
        return 'pdf';
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.webp':
        return 'image';
      case '.txt':
        return 'text';
      default:
        return 'file';
    }
  }

  /// Share file using native share sheet
  static Future<ShareResult?> shareFile({
    required String source,
    required String fileExtension,
    String? fileName,
    String? subject,
    BuildContext? context,
    Rect? sharePositionOrigin,
  }) async {
    FileData? fileData;
    try {
      fileData = await loadFile(source, fileExtension);

      final name =
          fileName ??
          'file_${DateTime.now().millisecondsSinceEpoch}$fileExtension';

      final xFile = XFile(
        fileData.path,
        name: name,
        mimeType: _getMimeType(fileExtension),
      );

      final result = await Share.shareXFiles(
        [xFile],
        subject: subject,
        text: name,
        sharePositionOrigin: sharePositionOrigin,
      );

      if (context != null && context.mounted) {
        switch (result.status) {
          case ShareResultStatus.success:
            _showSuccessDialog('Đã chia sẻ thành công');
            break;
          case ShareResultStatus.dismissed:
            break;
          case ShareResultStatus.unavailable:
            _showErrorDialog(context, 'Không thể chia sẻ file này');
            break;
        }
      }

      return result;
    } catch (e) {
      if (context != null && context.mounted) {
        _showErrorDialog(context, 'Lỗi chia sẻ', detail: e.toString());
      }
      rethrow;
    } finally {
      if (fileData != null) {
        await Future.delayed(const Duration(seconds: 5));
        await fileData.cleanup();
      }
    }
  }

  /// Download file with smart handling based on file type and platform
  /// - Media files (image/video/audio): Save directly to gallery
  /// - Documents on iOS: Use Share Sheet (includes "Save to Files")
  /// - Documents on Android: Use File Picker
  /// Download file with smart handling based on file type and platform
  static Future<dynamic> downloadFile({
    required String source,
    required String fileExtension,
    String? customFileName,
    BuildContext? context,
  }) async {
    FileData? fileData;
    try {
      // Load file data
      fileData = await loadFile(source, fileExtension);

      // Detect media type
      final mediaType = detectMediaType(fileExtension);

      // Generate file name
      final fileName =
          customFileName ??
          'download_${DateTime.now().millisecondsSinceEpoch}$fileExtension';

      // ✅ Media files → Save directly to gallery/media folder
      if (mediaType != MediaType.document) {
        await _saveMediaFile(
          fileData: fileData,
          fileName: fileName,
          mediaType: mediaType!,
          context: context,
        );
        return; // ✅ Exit after saving
      }

      // ✅ Non-media files → Platform-specific handling
      if (Platform.isIOS) {
        // iOS: Use Share Sheet (includes "Save to Files" option)
        return await _saveNonMediaFileIOS(
          fileData: fileData,
          fileName: fileName,
          fileExtension: fileExtension,
          context: context,
        );
      } else {
        // Android: Use File Picker
        return await _saveNonMediaFileAndroid(
          fileData: fileData,
          fileName: fileName,
          context: context,
        );
      }
    } catch (e) {
      if (context != null && context.mounted) {
        _showErrorDialog(context, 'Lỗi khi tải xuống', detail: e.toString());
      }
      rethrow;
    } finally {
      await fileData?.cleanup();
    }
  }

  /// Save media file to gallery using Gal library
  static Future<void> _saveMediaFile({
    required FileData fileData,
    required String fileName,
    required MediaType mediaType,
    BuildContext? context,
  }) async {
    try {
      // Request permission first
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final granted = await Gal.requestAccess(toAlbum: true);
        if (!granted) {
          throw Exception('Không có quyền truy cập thư viện');
        }
      }

      // Save to gallery based on media type
      if (mediaType == MediaType.image) {
        await Gal.putImageBytes(fileData.bytes, name: fileName);
      } else if (mediaType == MediaType.video) {
        await Gal.putVideo(fileData.path, album: fileName);
      } else if (mediaType == MediaType.audio) {
        // Audio files go to Downloads folder
        final dir = await _getDownloadsDirectory();
        final savePath = '${dir.path}/$fileName';
        final file = File(savePath);
        await file.writeAsBytes(fileData.bytes);
      }

      _showSuccessDialog(
        'Đã tải xuống thành công!',
        detail: 'File đã được lưu vào thư viện',
      );
    } catch (e) {
      debugPrint('Error saving media: $e');
      if (context != null && context.mounted) {
        _showErrorDialog(context, 'Lỗi lưu media', detail: e.toString());
      }
      rethrow;
    }
  }

  /// Save non-media file on iOS (use Share Sheet)
  static Future<ShareResult> _saveNonMediaFileIOS({
    required FileData fileData,
    required String fileName,
    required String fileExtension,
    BuildContext? context,
  }) async {
    final xFile = XFile(
      fileData.path,
      name: fileName,
      mimeType: _getMimeType(fileExtension),
    );

    final result = await Share.shareXFiles([xFile], text: fileName);

    if (context != null && context.mounted) {
      switch (result.status) {
        case ShareResultStatus.success:
          // Success handled by caller
          break;
        case ShareResultStatus.dismissed:
          _showInfoDialog(context, 'Đã hủy');
          break;
        case ShareResultStatus.unavailable:
          _showErrorDialog(context, 'Không thể lưu file này');
          break;
      }
    }
    _showInfoDialog(
      context!,
      setText("Lưu file thành công", "Saved file successfully"),
    );
    return result;
  }

  /// Save non-media file on Android (use File Picker)
  static Future<String?> _saveNonMediaFileAndroid({
    required FileData fileData,
    required String fileName,
    BuildContext? context,
  }) async {
    final savePath = await FilePicker.saveFile(
      fileName: fileName,
      bytes: fileData.bytes,
    );

    if (savePath == null) {
      if (context != null && context.mounted) {
        _showInfoDialog(context, 'Đã hủy lưu file');
      }
      return null;
    }
    _showInfoDialog(
      context!,
      setText("Lưu file thành công", "Saved file successfully"),
    );
    return savePath;
  }

  /// Get downloads directory
  static Future<Directory> _getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      final dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    } else {
      return await getApplicationDocumentsDirectory();
    }
  }

  /// Print file (PDF, Image, or Text)
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
      String _fileType = fileType.replaceAll(".", "").toLowerCase();
      switch (_fileType.toLowerCase()) {
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
        _showErrorDialog(context, 'Lỗi in', detail: e.toString());
      }
      rethrow;
    } finally {
      await fileData?.cleanup();
    }
  }

  /// Get file extension from file type string
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

  /// Get MIME type from file extension
  static String _getMimeType(String extension) {
    final ext = extension.toLowerCase().replaceAll('.', '');

    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'txt':
        return 'text/plain';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'zip':
        return 'application/zip';
      case 'mp4':
        return 'video/mp4';
      case 'mp3':
        return 'audio/mpeg';
      default:
        return 'application/octet-stream';
    }
  }

  /// Print PDF file
  static Future<void> _printPdf(Uint8List pdfBytes, String? name) async {
    await Printing.layoutPdf(
      name: name ?? 'document.pdf',
      onLayout: (format) async => pdfBytes,
    );
  }

  /// Print image file (convert to PDF first)
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

  /// Print text file (convert to PDF first)
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

  /// Show success dialog
  static void _showSuccessDialog(String message, {String? detail}) {
    //message.showToast(type: CyberShowToast.center);
    message.showToast(
      type: CyberShowToast.center,
      toastType: CyberToastType.success,
    );
    // showDialog(
    //   context: AppNavigator.context!,
    //   builder: (context) => AlertDialog(
    //     icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
    //     title: Text(message),
    //     content: detail != null ? Text(detail) : null,
    //     actions: [
    //       TextButton(
    //         onPressed: () => Navigator.pop(context),
    //         child: const Text('OK'),
    //       ),
    //     ],
    //   ),
    // );
  }

  /// Show error dialog
  static void _showErrorDialog(
    BuildContext context,
    String message, {
    String? detail,
  }) {
    message.showToast(
      type: CyberShowToast.center,
      toastType: CyberToastType.error,
    );
    // showDialog(
    //   context: context,
    //   builder: (context) => AlertDialog(
    //     icon: const Icon(Icons.error, color: Colors.red, size: 48),
    //     title: Text(message),
    //     content: detail != null
    //         ? SingleChildScrollView(child: Text(detail))
    //         : null,
    //     actions: [
    //       TextButton(
    //         onPressed: () => Navigator.pop(context),
    //         child: const Text('Đóng'),
    //       ),
    //     ],
    //   ),
    // );
  }

  /// Show info dialog
  static void _showInfoDialog(BuildContext context, String message) {
    message.showToast(
      type: CyberShowToast.center,
      toastType: CyberToastType.info,
    );
  }

  /// Manual cleanup trigger
  static Future<void> cleanupTempFiles() async {
    await _TempFileTracker.cleanupOldFiles();
  }
}
