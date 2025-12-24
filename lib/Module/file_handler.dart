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

enum FileSourceType { base64, path, url }

class FileHandler {
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
      if (str.length % 4 != 0) return false;
      base64Decode(str);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Load file from any source and return bytes + local path
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

  static Future<FileData> _loadFromBase64(
    String base64String,
    String ext,
  ) async {
    // Remove data URI prefix if exists
    if (base64String.contains(',')) {
      base64String = base64String.split(',')[1];
    }

    final bytes = base64Decode(base64String);

    // Save to temp file
    final tempDir = await getTemporaryDirectory();
    final fileName = 'temp_${DateTime.now().millisecondsSinceEpoch}$ext';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);

    return FileData(
      bytes: bytes,
      path: file.path,
      sourceType: FileSourceType.base64,
    );
  }

  static Future<FileData> _loadFromPath(String path) async {
    final file = File(path);
    if (!await file.exists()) {
      throw Exception('File does not exist: $path');
    }

    final bytes = await file.readAsBytes();

    return FileData(bytes: bytes, path: path, sourceType: FileSourceType.path);
  }

  static Future<FileData> _loadFromUrl(String url, String ext) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}: Failed to download file');
    }

    final bytes = response.bodyBytes;

    // Save to temp file
    final tempDir = await getTemporaryDirectory();
    final fileName =
        'temp_download_${DateTime.now().millisecondsSinceEpoch}$ext';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);

    return FileData(
      bytes: bytes,
      path: file.path,
      sourceType: FileSourceType.url,
    );
  }

  /// Share file
  static Future<void> shareFile({
    required String source,
    required String fileExtension,
    String? fileName,
    String? subject,
    BuildContext? context,
  }) async {
    try {
      final fileData = await loadFile(source, fileExtension);
      final params = ShareParams(
        text: 'Great picture',
        files: [XFile(fileData.path)],
      );

      await SharePlus.instance.share(params);
      // await Share.shareXFiles(
      //   [XFile(fileData.path)],
      //   subject: subject,
      //   text: fileName,
      // );
    } catch (e) {
      if (context != null && context.mounted) {
        _showError(context, 'Share error: $e');
      }
      rethrow;
    }
  }

  /// Download file to Downloads folder
  static Future<String> downloadFile({
    required String source,
    required String fileExtension,
    String? customFileName,
    BuildContext? context,
  }) async {
    try {
      final fileData = await loadFile(source, fileExtension);

      // Get Downloads directory
      final downloadsDir = await _getDownloadsDirectory();

      // Generate file name
      final fileName =
          customFileName ??
          'download_${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      final savePath = '${downloadsDir.path}/$fileName';

      // Save file
      final file = File(savePath);
      await file.writeAsBytes(fileData.bytes);

      if (context != null && context.mounted) {
        _showSuccess(context, 'Saved: $savePath');
      }

      return savePath;
    } catch (e) {
      if (context != null && context.mounted) {
        _showError(context, 'Download error: $e');
      }
      rethrow;
    }
  }

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

  /// Print file (PDF, Image, Text)
  static Future<void> printFile({
    required String source,
    required String fileType, // 'pdf', 'image', 'text'
    String? documentName,
    BuildContext? context,
  }) async {
    try {
      final ext = _getFileExtension(fileType);
      final fileData = await loadFile(source, ext);

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
          throw Exception('Unsupported file type for printing: $fileType');
      }
    } catch (e) {
      if (context != null && context.mounted) {
        _showError(context, 'Print error: $e');
      }
      rethrow;
    }
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
}

/// Data class to hold file information
class FileData {
  final Uint8List bytes;
  final String path;
  final FileSourceType sourceType;

  FileData({required this.bytes, required this.path, required this.sourceType});
}
