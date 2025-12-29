import 'package:cyberframework/cyberframework.dart';
import 'package:photo_view/photo_view.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class FrmImageView extends BaseFileViewer {
  PhotoViewController? _photoController;
  double _currentScale = 1.0;

  FrmImageView() {
    fileExtension = '.jpg';
  }

  @override
  void onInit() {
    super.onInit();
    _photoController = PhotoViewController();
  }

  @override
  Widget buildViewer() {
    if (fileBytes == null) {
      return Center(child: Text(setText('Không có dữ liệu', 'No data')));
    }

    return PhotoView(
      imageProvider: MemoryImage(fileBytes!),
      controller: _photoController,
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 4,
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      onScaleEnd: (context, details, controllerValue) {
        _currentScale = controllerValue.scale ?? 1.0;
      },
    );
  }

  @override
  List<Widget> buildAdditionalToolbarButtons() {
    return [
      // Zoom out
      IconButton(
        icon: const Icon(Icons.zoom_out),
        tooltip: setText('Thu nhỏ', 'Zoom out'),
        onPressed: () {
          _photoController?.scale = (_currentScale - 0.5).clamp(0.5, 4.0);
        },
      ),

      // Zoom in
      IconButton(
        icon: const Icon(Icons.zoom_in),
        tooltip: setText('Phóng to', 'Zoom in'),
        onPressed: () {
          _photoController?.scale = (_currentScale + 0.5).clamp(0.5, 4.0);
        },
      ),

      // Reset zoom
      IconButton(
        icon: const Icon(Icons.fit_screen),
        tooltip: setText('Vừa màn hình', 'Fit screen'),
        onPressed: () {
          _photoController?.scale = 1.0;
        },
      ),

      // Rotate
      IconButton(
        icon: const Icon(Icons.rotate_right),
        tooltip: setText('Xoay', 'Rotate'),
        onPressed: () {
          final currentRotation = _photoController?.rotation ?? 0;
          _photoController?.rotation = currentRotation + 90;
        },
      ),
    ];
  }

  @override
  bool canPrint() => true;

  @override
  Future<void> onPrint() async {
    if (fileBytes == null) return;

    final pdf = pw.Document();
    final image = pw.MemoryImage(fileBytes!);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Center(child: pw.Image(image)),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  @override
  void onDispose() {
    _photoController?.dispose();
    super.onDispose();
  }
}
