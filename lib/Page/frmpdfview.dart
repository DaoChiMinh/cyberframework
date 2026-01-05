import 'package:cyberframework/cyberframework.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class FrmPdfView extends CyberForm {
  String pdfUrl = "";
  String pdfPath = ""; // For local file
  PdfViewerController? _pdfController;
  bool showToolbar = true;

  @override
  void onInit() {
    super.onInit();
    _pdfController = PdfViewerController();
  }

  @override
  Widget buildBody(BuildContext context) {
    return Column(
      children: [
        // Toolbar (optional)
        if (showToolbar) _buildToolbar(),

        // PDF Viewer
        Expanded(child: _buildPdfViewer()),
      ],
    );
  }

  Widget _buildPdfViewer() {
    // Nếu có URL thì load từ network
    if (pdfUrl.isNotEmpty) {
      return SfPdfViewer.network(
        pdfUrl,
        controller: _pdfController,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        enableDoubleTapZooming: true,
        enableTextSelection: true,
      );
    }

    // Nếu có path thì load từ file local
    if (pdfPath.isNotEmpty) {
      return SfPdfViewer.file(
        File(pdfPath),
        controller: _pdfController,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        enableDoubleTapZooming: true,
        enableTextSelection: true,
      );
    }

    // Nếu không có gì thì hiện lỗi
    return Center(
      child: Text(
        setText('Không có file PDF để hiển thị', 'No PDF file to display'),
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          // Zoom out
          IconButton(
            icon: const Icon(Icons.zoom_out),
            tooltip: setText('Thu nhỏ', 'Zoom out'),
            onPressed: () {
              _pdfController?.zoomLevel =
                  (_pdfController?.zoomLevel ?? 1.0) - 0.25;
            },
          ),

          // Zoom in
          IconButton(
            icon: const Icon(Icons.zoom_in),
            tooltip: setText('Phóng to', 'Zoom in'),
            onPressed: () {
              _pdfController?.zoomLevel =
                  (_pdfController?.zoomLevel ?? 1.0) + 0.25;
            },
          ),

          const VerticalDivider(),

          // First page
          IconButton(
            icon: const Icon(Icons.first_page),
            tooltip: setText('Trang đầu', 'First page'),
            onPressed: () {
              _pdfController?.jumpToPage(1);
            },
          ),

          // Previous page
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: setText('Trang trước', 'Previous page'),
            onPressed: () {
              _pdfController?.previousPage();
            },
          ),

          // Page info
          Expanded(
            child: Center(
              child: Text(
                '${setText("Trang", "Page")} ${_pdfController?.pageNumber ?? 1} / ${_pdfController?.pageCount ?? 1}',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),

          // Next page
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: setText('Trang sau', 'Next page'),
            onPressed: () {
              _pdfController?.nextPage();
            },
          ),

          // Last page
          IconButton(
            icon: const Icon(Icons.last_page),
            tooltip: setText('Trang cuối', 'Last page'),
            onPressed: () {
              _pdfController?.jumpToPage(_pdfController?.pageCount ?? 1);
            },
          ),
        ],
      ),
    );
  }

  @override
  void onDispose() {
    _pdfController?.dispose();
    super.onDispose();
  }
}
