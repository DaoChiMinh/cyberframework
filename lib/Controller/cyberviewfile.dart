import 'package:cyberframework/cyberframework.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;
import 'package:photo_view/photo_view.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:docx_to_text/docx_to_text.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:gal/gal.dart';
import 'package:mime/mime.dart';

// ============================================================================
// ENUMS
// ============================================================================

/// Loại nguồn dữ liệu
enum CyberFileSourceType { base64, bytes, url, path, unknown }

/// Loại file để hiển thị
enum CyberFileViewType {
  text,
  html,
  web,
  image,
  pdf,
  doc,
  excel,
  powerpoint,
  video,
  audio,
  unknown,
}

/// Vị trí toolbar
enum CyberViewFileToolbarPosition { top, bottom, none }

// ============================================================================
// FILE INFO MODEL
// ============================================================================

class CyberFileInfo {
  final Uint8List bytes;
  final String localPath;
  final CyberFileSourceType sourceType;
  final CyberFileViewType viewType;
  final String fileName;
  final String extension;
  final String mimeType;
  final int fileSize;
  final bool isTemp;

  CyberFileInfo({
    required this.bytes,
    required this.localPath,
    required this.sourceType,
    required this.viewType,
    required this.fileName,
    required this.extension,
    required this.mimeType,
    required this.fileSize,
    this.isTemp = false,
  });

  /// Cleanup temp file
  Future<void> cleanup() async {
    if (isTemp) {
      try {
        final file = File(localPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('CyberViewFile: Error cleaning temp file: $e');
      }
    }
  }
}

// ============================================================================
// CYBER VIEW FILE WIDGET
// ============================================================================

class CyberViewFile extends StatefulWidget {
  /// Dữ liệu file: có thể là String (base64, url, path) hoặc Uint8List
  final dynamic text;

  /// Ép buộc loại file (nếu không set sẽ tự detect)
  final CyberFileViewType? forceViewType;

  /// Extension hint (giúp detect chính xác hơn)
  final String? extensionHint;

  /// File name hint
  final String? fileNameHint;

  /// Hiển thị nút download
  final bool showDownload;

  /// Hiển thị nút share
  final bool showShare;

  /// Hiển thị nút print
  final bool showPrint;

  /// Hiển thị toolbar
  final bool showToolbar;

  /// Vị trí toolbar
  final CyberViewFileToolbarPosition toolbarPosition;

  /// Custom toolbar actions
  final List<Widget>? customToolbarActions;

  /// Callback khi load xong
  final VoidCallback? onLoaded;

  /// Callback khi có lỗi
  final void Function(String error)? onError;

  /// Callback khi download xong
  final void Function(String path)? onDownloaded;

  /// Callback khi share xong
  final void Function(bool success)? onShared;

  /// Background color
  final Color? backgroundColor;

  /// Loading widget
  final Widget? loadingWidget;

  /// Error widget builder
  final Widget Function(String error, VoidCallback retry)? errorWidgetBuilder;

  /// Cho phép zoom (image, pdf)
  final bool enableZoom;

  /// Cho phép text selection (pdf, text)
  final bool enableTextSelection;

  /// Font size cho text viewer
  final double textFontSize;

  /// Auto play cho video/audio
  final bool autoPlay;

  const CyberViewFile({
    super.key,
    required this.text,
    this.forceViewType,
    this.extensionHint,
    this.fileNameHint,
    this.showDownload = true,
    this.showShare = true,
    this.showPrint = true,
    this.showToolbar = true,
    this.toolbarPosition = CyberViewFileToolbarPosition.top,
    this.customToolbarActions,
    this.onLoaded,
    this.onError,
    this.onDownloaded,
    this.onShared,
    this.backgroundColor,
    this.loadingWidget,
    this.errorWidgetBuilder,
    this.enableZoom = true,
    this.enableTextSelection = true,
    this.textFontSize = 14,
    this.autoPlay = false,
  });

  @override
  State<CyberViewFile> createState() => CyberViewFileState();
}

class CyberViewFileState extends State<CyberViewFile> {
  CyberFileInfo? _fileInfo;
  bool _isLoading = true;
  String? _errorMessage;

  // Controllers
  PdfViewerController? _pdfController;
  PhotoViewController? _photoController;
  TextEditingController? _textController;
  WebViewController? _webViewController;
  ScrollController? _scrollController;

  // State variables
  int _currentPage = 1;
  int _totalPages = 1;
  double _currentZoom = 1.0;
  double _currentFontSize = 14;
  String _currentSheet = "";
  List<String> _sheetNames = [];
  Excel? _excel;
  String? _extractedText;

  @override
  void initState() {
    super.initState();
    _currentFontSize = widget.textFontSize;
    _loadFile();
  }

  @override
  void didUpdateWidget(CyberViewFile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.forceViewType != widget.forceViewType) {
      _loadFile();
    }
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  void _cleanup() {
    _pdfController?.dispose();
    _photoController?.dispose();
    _textController?.dispose();
    _scrollController?.dispose();
    _fileInfo?.cleanup();
  }

  // ============================================================================
  // FILE LOADING
  // ============================================================================

  Future<void> _loadFile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Cleanup previous
      _cleanup();

      // Detect source and load
      _fileInfo = await _detectAndLoadFile();

      // Initialize controllers based on view type
      _initializeControllers();

      // Process specific file types
      await _processFileType();

      setState(() => _isLoading = false);
      widget.onLoaded?.call();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
      widget.onError?.call(e.toString());
    }
  }

  Future<CyberFileInfo> _detectAndLoadFile() async {
    final text = widget.text;

    // Detect source type
    CyberFileSourceType sourceType;
    Uint8List bytes;
    String localPath;
    bool isTemp = false;

    if (text is Uint8List) {
      // Byte array
      sourceType = CyberFileSourceType.bytes;
      bytes = text;
      localPath = await _saveTempFile(bytes);
      isTemp = true;
    } else if (text is String) {
      if (text.startsWith('http://') || text.startsWith('https://')) {
        // URL
        sourceType = CyberFileSourceType.url;
        bytes = await _downloadFromUrl(text);
        localPath = await _saveTempFile(bytes);
        isTemp = true;
      } else if (_isBase64(text)) {
        // Base64
        sourceType = CyberFileSourceType.base64;
        bytes = _decodeBase64(text);
        localPath = await _saveTempFile(bytes);
        isTemp = true;
      } else if (await File(text).exists()) {
        // File path
        sourceType = CyberFileSourceType.path;
        final file = File(text);
        bytes = await file.readAsBytes();
        localPath = text;
        isTemp = false;
      } else {
        // Assume it's text content
        sourceType = CyberFileSourceType.base64;
        bytes = utf8.encode(text);
        localPath = await _saveTempFile(bytes, extension: '.txt');
        isTemp = true;
      }
    } else {
      throw Exception(
        setText('Định dạng dữ liệu không hợp lệ', 'Invalid data format'),
      );
    }

    // Detect file type
    final extension = _detectExtension(localPath, bytes);
    final viewType = widget.forceViewType ?? _detectViewType(extension, bytes);
    final mimeType = _getMimeType(extension);
    final fileName =
        widget.fileNameHint ??
        'file_${DateTime.now().millisecondsSinceEpoch}$extension';

    return CyberFileInfo(
      bytes: bytes,
      localPath: localPath,
      sourceType: sourceType,
      viewType: viewType,
      fileName: fileName,
      extension: extension,
      mimeType: mimeType,
      fileSize: bytes.length,
      isTemp: isTemp,
    );
  }

  bool _isBase64(String str) {
    try {
      if (str.isEmpty) return false;

      // Remove data URI prefix
      String base64Str = str;
      if (str.contains(',')) {
        base64Str = str.split(',')[1];
      }

      // Check valid base64
      if (base64Str.length % 4 != 0) return false;
      if (!RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(base64Str)) return false;

      base64Decode(base64Str);
      return true;
    } catch (e) {
      return false;
    }
  }

  Uint8List _decodeBase64(String str) {
    String base64Str = str;
    if (str.contains(',')) {
      base64Str = str.split(',')[1];
    }
    return base64Decode(base64Str);
  }

  Future<Uint8List> _downloadFromUrl(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception(
        'HTTP ${response.statusCode}: ${setText("Không thể tải file", "Failed to download")}',
      );
    }
    return response.bodyBytes;
  }

  Future<String> _saveTempFile(Uint8List bytes, {String? extension}) async {
    final tempDir = await getTemporaryDirectory();
    final ext = extension ?? _detectExtension('', bytes);
    final fileName = 'cyber_view_${DateTime.now().millisecondsSinceEpoch}$ext';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  String _detectExtension(String path, Uint8List bytes) {
    // 1. Use hint if provided
    if (widget.extensionHint != null && widget.extensionHint!.isNotEmpty) {
      return widget.extensionHint!.startsWith('.')
          ? widget.extensionHint!
          : '.${widget.extensionHint}';
    }

    // 2. Extract from path
    if (path.isNotEmpty) {
      final pathExt = path.split('.').last.toLowerCase();
      if (_isValidExtension(pathExt)) {
        return '.$pathExt';
      }
    }

    // 3. Detect from magic bytes
    return _detectExtensionFromBytes(bytes);
  }

  bool _isValidExtension(String ext) {
    const validExts = [
      'txt',
      'html',
      'htm',
      'css',
      'js',
      'json',
      'xml',
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'bmp',
      'svg',
      'pdf',
      'doc',
      'docx',
      'xls',
      'xlsx',
      'ppt',
      'pptx',
      'mp4',
      'mov',
      'avi',
      'mkv',
      'mp3',
      'wav',
      'aac',
      'm4a',
    ];
    return validExts.contains(ext.toLowerCase());
  }

  String _detectExtensionFromBytes(Uint8List bytes) {
    if (bytes.length < 8) return '.bin';

    // PDF: %PDF
    if (bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46) {
      return '.pdf';
    }

    // PNG: 89 50 4E 47
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return '.png';
    }

    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return '.jpg';
    }

    // GIF: GIF8
    if (bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return '.gif';
    }

    // WEBP: RIFF....WEBP
    if (bytes.length > 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return '.webp';
    }

    // ZIP (DOCX, XLSX, PPTX): PK
    if (bytes[0] == 0x50 && bytes[1] == 0x4B) {
      // Check for Office formats
      final str = String.fromCharCodes(bytes.take(2000));
      if (str.contains('word/')) return '.docx';
      if (str.contains('xl/')) return '.xlsx';
      if (str.contains('ppt/')) return '.pptx';
      return '.zip';
    }

    // DOC: D0 CF 11 E0
    if (bytes[0] == 0xD0 &&
        bytes[1] == 0xCF &&
        bytes[2] == 0x11 &&
        bytes[3] == 0xE0) {
      return '.doc';
    }

    // Check if text
    try {
      final text = utf8.decode(bytes.take(1000).toList());
      if (text.contains('<!DOCTYPE html') || text.contains('<html')) {
        return '.html';
      }
      if (text.contains('<?xml')) {
        return '.xml';
      }
      // Likely plain text
      return '.txt';
    } catch (e) {
      // Not text
    }

    return '.bin';
  }

  CyberFileViewType _detectViewType(String extension, Uint8List bytes) {
    final ext = extension.toLowerCase().replaceAll('.', '');

    // Text
    if ([
      'txt',
      'log',
      'md',
      'json',
      'xml',
      'css',
      'js',
      'dart',
      'py',
      'java',
      'c',
      'cpp',
      'h',
    ].contains(ext)) {
      return CyberFileViewType.text;
    }

    // HTML
    if (['html', 'htm'].contains(ext)) {
      return CyberFileViewType.html;
    }

    // Image
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg'].contains(ext)) {
      return CyberFileViewType.image;
    }

    // PDF
    if (ext == 'pdf') {
      return CyberFileViewType.pdf;
    }

    // Doc
    if (['doc', 'docx'].contains(ext)) {
      return CyberFileViewType.doc;
    }

    // Excel
    if (['xls', 'xlsx', 'csv'].contains(ext)) {
      return CyberFileViewType.excel;
    }

    // PowerPoint
    if (['ppt', 'pptx'].contains(ext)) {
      return CyberFileViewType.powerpoint;
    }

    // Video
    if (['mp4', 'mov', 'avi', 'mkv', 'flv', 'wmv', '3gp'].contains(ext)) {
      return CyberFileViewType.video;
    }

    // Audio
    if (['mp3', 'wav', 'aac', 'm4a', 'flac', 'ogg'].contains(ext)) {
      return CyberFileViewType.audio;
    }

    return CyberFileViewType.unknown;
  }

  String _getMimeType(String extension) {
    final ext = extension.toLowerCase().replaceAll('.', '');
    return lookupMimeType('file.$ext') ?? 'application/octet-stream';
  }

  void _initializeControllers() {
    if (_fileInfo == null) return;

    switch (_fileInfo!.viewType) {
      case CyberFileViewType.pdf:
        _pdfController = PdfViewerController();
        break;
      case CyberFileViewType.image:
        _photoController = PhotoViewController();
        break;
      case CyberFileViewType.text:
        _textController = TextEditingController();
        _scrollController = ScrollController();
        break;
      case CyberFileViewType.html:
      case CyberFileViewType.web:
        _webViewController = WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted);
        break;
      default:
        break;
    }
  }

  Future<void> _processFileType() async {
    if (_fileInfo == null) return;

    switch (_fileInfo!.viewType) {
      case CyberFileViewType.text:
        final text = utf8.decode(_fileInfo!.bytes, allowMalformed: true);
        _textController?.text = text;
        break;

      case CyberFileViewType.html:
        final htmlContent = utf8.decode(_fileInfo!.bytes, allowMalformed: true);
        await _webViewController?.loadHtmlString(htmlContent);
        break;

      case CyberFileViewType.web:
        await _webViewController?.loadFile(_fileInfo!.localPath);
        break;

      case CyberFileViewType.doc:
        try {
          _extractedText = docxToText(_fileInfo!.bytes);
        } catch (e) {
          _extractedText = setText(
            'Không thể đọc nội dung',
            'Cannot read content',
          );
        }
        break;

      case CyberFileViewType.excel:
        _excel = Excel.decodeBytes(_fileInfo!.bytes);
        _sheetNames = _excel!.tables.keys.toList();
        if (_sheetNames.isNotEmpty) {
          _currentSheet = _sheetNames[0];
        }
        break;

      default:
        break;
    }
  }

  // ============================================================================
  // BUILD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor ?? Colors.white,
      child: Column(
        children: [
          // Top toolbar
          if (widget.showToolbar &&
              widget.toolbarPosition == CyberViewFileToolbarPosition.top)
            _buildToolbar(),

          // Content
          Expanded(child: _buildContent()),

          // Bottom toolbar
          if (widget.showToolbar &&
              widget.toolbarPosition == CyberViewFileToolbarPosition.bottom)
            _buildToolbar(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return widget.loadingWidget ?? _buildDefaultLoading();
    }

    if (_errorMessage != null) {
      if (widget.errorWidgetBuilder != null) {
        return widget.errorWidgetBuilder!(_errorMessage!, _loadFile);
      }
      return _buildDefaultError();
    }

    if (_fileInfo == null) {
      return Center(child: Text(setText('Không có dữ liệu', 'No data')));
    }

    return _buildViewer();
  }

  Widget _buildDefaultLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(setText('Đang tải...', 'Loading...')),
        ],
      ),
    );
  }

  Widget _buildDefaultError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadFile,
            icon: const Icon(Icons.refresh),
            label: Text(setText('Thử lại', 'Retry')),
          ),
        ],
      ),
    );
  }

  Widget _buildViewer() {
    switch (_fileInfo!.viewType) {
      case CyberFileViewType.text:
        return _buildTextViewer();
      case CyberFileViewType.html:
      case CyberFileViewType.web:
        return _buildWebViewer();
      case CyberFileViewType.image:
        return _buildImageViewer();
      case CyberFileViewType.pdf:
        return _buildPdfViewer();
      case CyberFileViewType.doc:
        return _buildDocViewer();
      case CyberFileViewType.excel:
        return _buildExcelViewer();
      case CyberFileViewType.powerpoint:
        return _buildPowerpointViewer();
      case CyberFileViewType.video:
        return _buildVideoViewer();
      case CyberFileViewType.audio:
        return _buildAudioViewer();
      case CyberFileViewType.unknown:
      default:
        return _buildUnknownViewer();
    }
  }

  // ============================================================================
  // VIEWERS
  // ============================================================================

  Widget _buildTextViewer() {
    return Container(
      color: Colors.white,
      child: Scrollbar(
        controller: _scrollController,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          child: SelectableText(
            _textController?.text ?? '',
            style: TextStyle(
              fontSize: _currentFontSize,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebViewer() {
    if (_webViewController == null) {
      return Center(
        child: Text(setText('Không thể hiển thị', 'Cannot display')),
      );
    }
    return WebViewWidget(controller: _webViewController!);
  }

  Widget _buildImageViewer() {
    if (!widget.enableZoom) {
      return Center(child: Image.memory(_fileInfo!.bytes, fit: BoxFit.contain));
    }

    return PhotoView(
      imageProvider: MemoryImage(_fileInfo!.bytes),
      controller: _photoController,
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 4,
      backgroundDecoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.black,
      ),
      onScaleEnd: (context, details, controllerValue) {
        _currentZoom = controllerValue.scale ?? 1.0;
      },
    );
  }

  Widget _buildPdfViewer() {
    return SfPdfViewer.file(
      File(_fileInfo!.localPath),
      controller: _pdfController,
      canShowScrollHead: true,
      canShowScrollStatus: true,
      enableDoubleTapZooming: widget.enableZoom,
      enableTextSelection: widget.enableTextSelection,
      onPageChanged: (details) {
        setState(() {
          _currentPage = details.newPageNumber;
          _totalPages = _pdfController?.pageCount ?? 1;
        });
      },
      onDocumentLoaded: (details) {
        setState(() {
          _totalPages = details.document.pages.count;
        });
      },
    );
  }

  Widget _buildDocViewer() {
    // Convert DOCX to PDF for viewing
    return FutureBuilder<String>(
      future: _convertDocxToPdf(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildDefaultLoading();
        }

        if (snapshot.hasError || snapshot.data == null) {
          // Fallback to text view
          return Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: SelectableText(
                _extractedText ??
                    setText('Không thể hiển thị', 'Cannot display'),
                style: TextStyle(fontSize: _currentFontSize),
              ),
            ),
          );
        }

        return SfPdfViewer.file(
          File(snapshot.data!),
          controller: _pdfController,
          enableDoubleTapZooming: widget.enableZoom,
          enableTextSelection: widget.enableTextSelection,
          onPageChanged: (details) {
            setState(() {
              _currentPage = details.newPageNumber;
              _totalPages = _pdfController?.pageCount ?? 1;
            });
          },
        );
      },
    );
  }

  Future<String> _convertDocxToPdf() async {
    final PdfDocument document = PdfDocument();
    final PdfPage page = document.pages.add();

    page.graphics.drawString(
      _extractedText ?? '',
      PdfStandardFont(PdfFontFamily.helvetica, 12),
      bounds: Rect.fromLTWH(
        0,
        0,
        page.getClientSize().width,
        page.getClientSize().height,
      ),
    );

    final bytes = await document.save();
    document.dispose();

    final tempDir = await getTemporaryDirectory();
    final pdfPath =
        '${tempDir.path}/converted_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final pdfFile = File(pdfPath);
    await pdfFile.writeAsBytes(bytes);

    return pdfPath;
  }

  Widget _buildExcelViewer() {
    if (_excel == null || _currentSheet.isEmpty) {
      return Center(child: Text(setText('Không có dữ liệu', 'No data')));
    }

    final sheet = _excel!.tables[_currentSheet];
    if (sheet == null) {
      return Center(
        child: Text(setText('Sheet không tồn tại', 'Sheet not found')),
      );
    }

    return Column(
      children: [
        // Sheet selector
        if (_sheetNames.length > 1) _buildSheetSelector(),

        // Table
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: _buildExcelTable(sheet),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSheetSelector() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _sheetNames.length,
        itemBuilder: (context, index) {
          final sheetName = _sheetNames[index];
          final isActive = sheetName == _currentSheet;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: ElevatedButton(
              onPressed: () {
                setState(() => _currentSheet = sheetName);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive ? Colors.blue : Colors.white,
                foregroundColor: isActive ? Colors.white : Colors.black,
              ),
              child: Text(sheetName),
            ),
          );
        },
      ),
    );
  }

  Widget _buildExcelTable(Sheet sheet) {
    if (sheet.rows.isEmpty) {
      return Center(child: Text(setText('Sheet trống', 'Empty sheet')));
    }

    return DataTable(
      border: TableBorder.all(color: Colors.grey[300]!),
      headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
      columns: _buildExcelColumns(sheet),
      rows: _buildExcelRows(sheet),
    );
  }

  List<DataColumn> _buildExcelColumns(Sheet sheet) {
    if (sheet.rows.isEmpty) return [];

    final firstRow = sheet.rows[0];
    return List.generate(
      firstRow.length,
      (index) => DataColumn(
        label: Text(
          _getCellValue(firstRow[index]),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  List<DataRow> _buildExcelRows(Sheet sheet) {
    if (sheet.rows.length <= 1) return [];

    return sheet.rows.skip(1).map((row) {
      return DataRow(
        cells: row.map((cell) {
          return DataCell(Text(_getCellValue(cell)));
        }).toList(),
      );
    }).toList();
  }

  String _getCellValue(Data? cell) {
    if (cell == null || cell.value == null) return '';
    return cell.value.toString();
  }

  Widget _buildPowerpointViewer() {
    // PowerPoint không hỗ trợ trực tiếp, hiển thị thông báo
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.slideshow, size: 64, color: Colors.orange),
          const SizedBox(height: 16),
          Text(
            setText(
              'Không hỗ trợ xem PowerPoint trực tiếp',
              'PowerPoint preview not supported',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.showDownload)
                ElevatedButton.icon(
                  onPressed: _handleDownload,
                  icon: const Icon(Icons.download),
                  label: Text(setText('Tải xuống', 'Download')),
                ),
              const SizedBox(width: 8),
              if (widget.showShare)
                ElevatedButton.icon(
                  onPressed: _handleShare,
                  icon: const Icon(Icons.share),
                  label: Text(setText('Chia sẻ', 'Share')),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVideoViewer() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.video_library, size: 64, color: Colors.blue),
          const SizedBox(height: 16),
          Text(setText('Video Viewer', 'Video Viewer')),
          const SizedBox(height: 8),
          Text(_fileInfo?.fileName ?? ''),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.showDownload)
                ElevatedButton.icon(
                  onPressed: _handleDownload,
                  icon: const Icon(Icons.download),
                  label: Text(setText('Tải xuống', 'Download')),
                ),
              const SizedBox(width: 8),
              if (widget.showShare)
                ElevatedButton.icon(
                  onPressed: _handleShare,
                  icon: const Icon(Icons.share),
                  label: Text(setText('Chia sẻ', 'Share')),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAudioViewer() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.audiotrack, size: 64, color: Colors.purple),
          const SizedBox(height: 16),
          Text(setText('Audio Player', 'Audio Player')),
          const SizedBox(height: 8),
          Text(_fileInfo?.fileName ?? ''),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.showDownload)
                ElevatedButton.icon(
                  onPressed: _handleDownload,
                  icon: const Icon(Icons.download),
                  label: Text(setText('Tải xuống', 'Download')),
                ),
              const SizedBox(width: 8),
              if (widget.showShare)
                ElevatedButton.icon(
                  onPressed: _handleShare,
                  icon: const Icon(Icons.share),
                  label: Text(setText('Chia sẻ', 'Share')),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnknownViewer() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.insert_drive_file, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            setText('Không thể xem file này', 'Cannot preview this file'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${_fileInfo?.fileName ?? ""}\n${formatBytes(_fileInfo?.fileSize ?? 0)}',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.showDownload)
                ElevatedButton.icon(
                  onPressed: _handleDownload,
                  icon: const Icon(Icons.download),
                  label: Text(setText('Tải xuống', 'Download')),
                ),
              const SizedBox(width: 8),
              if (widget.showShare)
                ElevatedButton.icon(
                  onPressed: _handleShare,
                  icon: const Icon(Icons.share),
                  label: Text(setText('Chia sẻ', 'Share')),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TOOLBAR
  // ============================================================================

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border(
          bottom: widget.toolbarPosition == CyberViewFileToolbarPosition.top
              ? BorderSide(color: Colors.grey[300]!)
              : BorderSide.none,
          top: widget.toolbarPosition == CyberViewFileToolbarPosition.bottom
              ? BorderSide(color: Colors.grey[300]!)
              : BorderSide.none,
        ),
      ),
      child: Row(
        children: [
          // File type icon
          _buildFileTypeIcon(),
          const SizedBox(width: 8),

          // Type specific controls
          ..._buildTypeSpecificControls(),

          const Spacer(),

          // Custom actions
          if (widget.customToolbarActions != null)
            ...widget.customToolbarActions!,

          // Print
          if (widget.showPrint && _canPrint())
            IconButton(
              icon: const Icon(Icons.print),
              tooltip: setText('In', 'Print'),
              onPressed: _handlePrint,
            ),

          // Download
          if (widget.showDownload)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: setText('Tải xuống', 'Download'),
              onPressed: _handleDownload,
            ),

          // Share
          if (widget.showShare)
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: setText('Chia sẻ', 'Share'),
              onPressed: _handleShare,
            ),
        ],
      ),
    );
  }

  Widget _buildFileTypeIcon() {
    IconData icon;
    Color color;

    switch (_fileInfo?.viewType) {
      case CyberFileViewType.text:
        icon = Icons.description;
        color = Colors.grey;
        break;
      case CyberFileViewType.html:
      case CyberFileViewType.web:
        icon = Icons.language;
        color = Colors.orange;
        break;
      case CyberFileViewType.image:
        icon = Icons.image;
        color = Colors.green;
        break;
      case CyberFileViewType.pdf:
        icon = Icons.picture_as_pdf;
        color = Colors.red;
        break;
      case CyberFileViewType.doc:
        icon = Icons.article;
        color = Colors.blue;
        break;
      case CyberFileViewType.excel:
        icon = Icons.table_chart;
        color = Colors.green;
        break;
      case CyberFileViewType.powerpoint:
        icon = Icons.slideshow;
        color = Colors.orange;
        break;
      case CyberFileViewType.video:
        icon = Icons.video_library;
        color = Colors.purple;
        break;
      case CyberFileViewType.audio:
        icon = Icons.audiotrack;
        color = Colors.pink;
        break;
      default:
        icon = Icons.insert_drive_file;
        color = Colors.grey;
    }

    return Icon(icon, color: color, size: 20);
  }

  List<Widget> _buildTypeSpecificControls() {
    switch (_fileInfo?.viewType) {
      case CyberFileViewType.text:
        return _buildTextControls();
      case CyberFileViewType.image:
        return _buildImageControls();
      case CyberFileViewType.pdf:
      case CyberFileViewType.doc:
        return _buildPdfControls();
      case CyberFileViewType.excel:
        return _buildExcelControls();
      default:
        return [];
    }
  }

  List<Widget> _buildTextControls() {
    return [
      IconButton(
        icon: const Icon(Icons.text_decrease, size: 20),
        tooltip: setText('Giảm cỡ chữ', 'Decrease font'),
        onPressed: () {
          setState(() {
            _currentFontSize = (_currentFontSize - 2).clamp(8, 32);
          });
        },
      ),
      Text('${_currentFontSize.toInt()}'),
      IconButton(
        icon: const Icon(Icons.text_increase, size: 20),
        tooltip: setText('Tăng cỡ chữ', 'Increase font'),
        onPressed: () {
          setState(() {
            _currentFontSize = (_currentFontSize + 2).clamp(8, 32);
          });
        },
      ),
    ];
  }

  List<Widget> _buildImageControls() {
    return [
      IconButton(
        icon: const Icon(Icons.zoom_out, size: 20),
        tooltip: setText('Thu nhỏ', 'Zoom out'),
        onPressed: () {
          _photoController?.scale = (_currentZoom - 0.5).clamp(0.5, 4.0);
        },
      ),
      IconButton(
        icon: const Icon(Icons.zoom_in, size: 20),
        tooltip: setText('Phóng to', 'Zoom in'),
        onPressed: () {
          _photoController?.scale = (_currentZoom + 0.5).clamp(0.5, 4.0);
        },
      ),
      IconButton(
        icon: const Icon(Icons.fit_screen, size: 20),
        tooltip: setText('Vừa màn hình', 'Fit screen'),
        onPressed: () {
          _photoController?.scale = 1.0;
        },
      ),
      IconButton(
        icon: const Icon(Icons.rotate_right, size: 20),
        tooltip: setText('Xoay', 'Rotate'),
        onPressed: () {
          final currentRotation = _photoController?.rotation ?? 0;
          _photoController?.rotation = currentRotation + 90;
        },
      ),
    ];
  }

  List<Widget> _buildPdfControls() {
    return [
      IconButton(
        icon: const Icon(Icons.first_page, size: 20),
        tooltip: setText('Trang đầu', 'First page'),
        onPressed: () => _pdfController?.jumpToPage(1),
      ),
      IconButton(
        icon: const Icon(Icons.chevron_left, size: 20),
        tooltip: setText('Trang trước', 'Previous'),
        onPressed: _currentPage > 1
            ? () => _pdfController?.previousPage()
            : null,
      ),
      Text('$_currentPage / $_totalPages'),
      IconButton(
        icon: const Icon(Icons.chevron_right, size: 20),
        tooltip: setText('Trang sau', 'Next'),
        onPressed: _currentPage < _totalPages
            ? () => _pdfController?.nextPage()
            : null,
      ),
      IconButton(
        icon: const Icon(Icons.last_page, size: 20),
        tooltip: setText('Trang cuối', 'Last page'),
        onPressed: () => _pdfController?.jumpToPage(_totalPages),
      ),
    ];
  }

  List<Widget> _buildExcelControls() {
    return [Text('Sheet: $_currentSheet')];
  }

  // ============================================================================
  // ACTIONS
  // ============================================================================

  bool _canPrint() {
    final printableTypes = [
      CyberFileViewType.text,
      CyberFileViewType.image,
      CyberFileViewType.pdf,
      CyberFileViewType.doc,
      CyberFileViewType.excel,
    ];
    return printableTypes.contains(_fileInfo?.viewType);
  }

  Future<void> _handlePrint() async {
    if (_fileInfo == null) return;

    try {
      switch (_fileInfo!.viewType) {
        case CyberFileViewType.pdf:
          await Printing.layoutPdf(
            name: _fileInfo!.fileName,
            onLayout: (format) async => _fileInfo!.bytes,
          );
          break;

        case CyberFileViewType.image:
          final pdf = pw.Document();
          final image = pw.MemoryImage(_fileInfo!.bytes);
          pdf.addPage(
            pw.Page(
              //pageFormat: PdfPageFormat(width, height),
              build: (context) =>
                  pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
            ),
          );
          await Printing.layoutPdf(
            name: _fileInfo!.fileName,
            onLayout: (format) => pdf.save(),
          );
          break;

        case CyberFileViewType.text:
          final pdf = pw.Document();
          pdf.addPage(
            pw.MultiPage(
              //pageFormat: PdfPageFormat.a4,
              build: (context) => [
                pw.Text(
                  _textController?.text ?? '',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
          await Printing.layoutPdf(
            name: _fileInfo!.fileName,
            onLayout: (format) => pdf.save(),
          );
          break;

        case CyberFileViewType.doc:
          final pdfPath = await _convertDocxToPdf();
          final pdfBytes = await File(pdfPath).readAsBytes();
          await Printing.layoutPdf(
            name: _fileInfo!.fileName,
            onLayout: (format) async => pdfBytes,
          );
          break;

        case CyberFileViewType.excel:
          if (_excel == null) return;
          final sheet = _excel!.tables[_currentSheet];
          if (sheet == null) return;

          final pdf = pw.Document();
          pdf.addPage(
            pw.MultiPage(
              //pageFormat: PdfPageFormat.a4.landscape,
              build: (context) => [
                pw.TableHelper.fromTextArray(
                  headers: sheet.rows.first
                      .map((e) => _getCellValue(e))
                      .toList(),
                  data: sheet.rows
                      .skip(1)
                      .map((row) => row.map((e) => _getCellValue(e)).toList())
                      .toList(),
                ),
              ],
            ),
          );
          await Printing.layoutPdf(
            name: _fileInfo!.fileName,
            onLayout: (format) => pdf.save(),
          );
          break;

        default:
          _showToast(
            setText(
              'Không hỗ trợ in loại file này',
              'Print not supported for this file type',
            ),
          );
      }
    } catch (e) {
      _showToast(setText('Lỗi in: $e', 'Print error: $e'), isError: true);
    }
  }

  Future<void> _handleDownload() async {
    if (_fileInfo == null) return;

    try {
      // Check if media file
      final isMedia = [
        CyberFileViewType.image,
        CyberFileViewType.video,
        CyberFileViewType.audio,
      ].contains(_fileInfo!.viewType);

      if (isMedia && _fileInfo!.viewType == CyberFileViewType.image) {
        // Save to gallery
        final hasAccess = await Gal.hasAccess(toAlbum: true);
        if (!hasAccess) {
          final granted = await Gal.requestAccess(toAlbum: true);
          if (!granted) {
            _showToast(
              setText('Không có quyền truy cập thư viện', 'No gallery access'),
              isError: true,
            );
            return;
          }
        }
        await Gal.putImageBytes(_fileInfo!.bytes, name: _fileInfo!.fileName);
        _showToast(setText('Đã lưu vào thư viện', 'Saved to gallery'));
        widget.onDownloaded?.call(_fileInfo!.localPath);
        return;
      }

      // Non-media: platform specific
      if (Platform.isIOS) {
        // iOS: Use share sheet
        final xFile = XFile(
          _fileInfo!.localPath,
          name: _fileInfo!.fileName,
          mimeType: _fileInfo!.mimeType,
        );
        await Share.shareXFiles([xFile], text: _fileInfo!.fileName);
      } else {
        // Android: Use file picker
        final savePath = await FilePicker.saveFile(
          fileName: _fileInfo!.fileName,
          bytes: _fileInfo!.bytes,
        );
        if (savePath != null) {
          _showToast(setText('Đã lưu file', 'File saved'));
          widget.onDownloaded?.call(savePath);
        }
      }
    } catch (e) {
      _showToast(
        setText('Lỗi tải xuống: $e', 'Download error: $e'),
        isError: true,
      );
    }
  }

  Future<void> _handleShare() async {
    if (_fileInfo == null) return;

    try {
      final xFile = XFile(
        _fileInfo!.localPath,
        name: _fileInfo!.fileName,
        mimeType: _fileInfo!.mimeType,
      );

      final result = await Share.shareXFiles([
        xFile,
      ], text: _fileInfo!.fileName);

      widget.onShared?.call(result.status == ShareResultStatus.success);
    } catch (e) {
      _showToast(setText('Lỗi chia sẻ: $e', 'Share error: $e'), isError: true);
      widget.onShared?.call(false);
    }
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  void _showToast(String message, {bool isError = false}) {
    message.showToast(
      toastType: isError ? CyberToastType.error : CyberToastType.success,
    );
  }

  // ============================================================================
  // PUBLIC METHODS
  // ============================================================================

  /// Reload file
  Future<void> reload() async {
    await _loadFile();
  }

  /// Get current file info
  CyberFileInfo? get fileInfo => _fileInfo;

  /// Get current view type
  CyberFileViewType? get viewType => _fileInfo?.viewType;

  /// Download file programmatically
  Future<void> download() async {
    await _handleDownload();
  }

  /// Share file programmatically
  Future<void> share() async {
    await _handleShare();
  }

  /// Print file programmatically
  Future<void> print() async {
    await _handlePrint();
  }
}
