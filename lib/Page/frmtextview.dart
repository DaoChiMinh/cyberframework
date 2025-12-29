import 'package:cyberframework/cyberframework.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class FrmTextView extends BaseFileViewer {
  String _textContent = "";
  final TextEditingController _textController = TextEditingController();
  double _fontSize = 14;

  FrmTextView() {
    fileExtension = '.txt';
  }

  @override
  Future<void> onAfterLoad() async {
    super.onAfterLoad();
    if (fileBytes != null) {
      _textContent = utf8.decode(fileBytes!);
      _textController.text = _textContent;
    }
  }

  @override
  Widget buildViewer() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _textController,
        maxLines: null,
        readOnly: true,
        style: TextStyle(fontSize: _fontSize, fontFamily: 'monospace'),
        decoration: const InputDecoration(border: InputBorder.none),
      ),
    );
  }

  @override
  List<Widget> buildAdditionalToolbarButtons() {
    return [
      // Decrease font size
      IconButton(
        icon: const Icon(Icons.text_decrease),
        tooltip: setText('Giảm cỡ chữ', 'Decrease font'),
        onPressed: () {
          _fontSize = (_fontSize - 2).clamp(8, 32);
          rebuild();
        },
      ),

      // Increase font size
      IconButton(
        icon: const Icon(Icons.text_increase),
        tooltip: setText('Tăng cỡ chữ', 'Increase font'),
        onPressed: () {
          _fontSize = (_fontSize + 2).clamp(8, 32);
          rebuild();
        },
      ),

      // Word wrap toggle
      const SizedBox(width: 8),
      Text('${_fontSize.toInt()}px'),
      const SizedBox(width: 8),
    ];
  }

  @override
  bool canPrint() => true;

  @override
  Future<void> onPrint() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [pw.Text(_textContent)],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }

  @override
  void onDispose() {
    _textController.dispose();
    super.onDispose();
  }
}
