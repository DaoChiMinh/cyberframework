import 'package:cyberframework/cyberframework.dart';

import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:docx_to_text/docx_to_text.dart';

class FrmDocView extends BaseFileViewer {
  String? _extractedText;
  PdfViewerController? _pdfController;
  int _currentPage = 1;
  int _totalPages = 1;

  FrmDocView() {
    fileExtension = '.docx';
  }

  @override
  void onInit() {
    super.onInit();
    _pdfController = PdfViewerController();
  }

  @override
  Future<void> onAfterLoad() async {
    super.onAfterLoad();

    // Extract text from DOCX for search/copy
    if (fileBytes != null) {
      try {
        _extractedText = docxToText(fileBytes!);
      } catch (e) {
        //debugPrint('Error extracting text: $e');
      }
    }
  }

  @override
  Widget buildViewer() {
    if (localFilePath == null) {
      return Center(child: Text(setText('Không có dữ liệu', 'No data')));
    }

    // Using Syncfusion to render DOCX
    // Note: This requires converting DOCX to PDF first for viewing
    // Or use a webview with Google Docs Viewer

    return FutureBuilder<String>(
      future: _convertDocxToPdf(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(setText('Lỗi hiển thị file', 'Display error')),
                const SizedBox(height: 8),
                Text(snapshot.error.toString(), textAlign: TextAlign.center),
              ],
            ),
          );
        }

        // Show PDF viewer
        return SfPdfViewer.file(
          File(snapshot.data!),
          controller: _pdfController,
          onPageChanged: (details) {
            _currentPage = details.newPageNumber;
            _totalPages = _pdfController?.pageCount ?? 1;
            rebuild();
          },
        );
      },
    );
  }

  Future<String> _convertDocxToPdf() async {
    // Using Syncfusion to convert DOCX to PDF
    if (fileBytes == null) throw Exception('No file data');

    final PdfDocument document = PdfDocument();

    // Add extracted text to PDF (simple conversion)
    final PdfPage page = document.pages.add();
    page.graphics.drawString(
      _extractedText ??
          setText('Không thể trích xuất nội dung', 'Cannot extract content'),
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

    // Save to temp file
    final tempDir = await getTemporaryDirectory();
    final pdfPath =
        '${tempDir.path}/converted_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final pdfFile = File(pdfPath);
    await pdfFile.writeAsBytes(bytes);

    return pdfPath;
  }

  @override
  List<Widget> buildAdditionalToolbarButtons() {
    return [
      // Page info
      Text('$_currentPage / $_totalPages'),
      const SizedBox(width: 8),

      // Previous page
      IconButton(
        icon: const Icon(Icons.chevron_left),
        onPressed: _currentPage > 1
            ? () => _pdfController?.previousPage()
            : null,
      ),

      // Next page
      IconButton(
        icon: const Icon(Icons.chevron_right),
        onPressed: _currentPage < _totalPages
            ? () => _pdfController?.nextPage()
            : null,
      ),
    ];
  }

  @override
  bool canPrint() => true;

  @override
  Future<void> onPrint() async {
    final pdfPath = await _convertDocxToPdf();
    final pdfBytes = await File(pdfPath).readAsBytes();

    await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
  }

  @override
  void onDispose() {
    _pdfController?.dispose();
    super.onDispose();
  }
}
