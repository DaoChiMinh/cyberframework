import 'package:cyberframework/cyberframework.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class FrmExcelView extends BaseFileViewer {
  Excel? _excel;
  String _currentSheet = "";
  List<String> _sheetNames = [];
  int _currentSheetIndex = 0;

  FrmExcelView() {
    fileExtension = '.xlsx';
  }

  @override
  Future<void> onAfterLoad() async {
    super.onAfterLoad();

    if (fileBytes != null) {
      _excel = Excel.decodeBytes(fileBytes!);
      _sheetNames = _excel!.tables.keys.toList();

      if (_sheetNames.isNotEmpty) {
        _currentSheet = _sheetNames[0];
      }
    }
  }

  @override
  Widget buildViewer() {
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

        // Excel table
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: _buildTable(sheet),
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
          final isActive = index == _currentSheetIndex;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: ElevatedButton(
              onPressed: () {
                _currentSheetIndex = index;
                _currentSheet = sheetName;
                rebuild();
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

  Widget _buildTable(Sheet sheet) {
    return DataTable(
      border: TableBorder.all(color: Colors.grey[300]!),
      headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
      columns: _buildColumns(sheet),
      rows: _buildRows(sheet),
    );
  }

  List<DataColumn> _buildColumns(Sheet sheet) {
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

  List<DataRow> _buildRows(Sheet sheet) {
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

  @override
  List<Widget> buildAdditionalToolbarButtons() {
    return [Text('Sheet: $_currentSheet'), const SizedBox(width: 8)];
  }

  @override
  bool canPrint() => true;

  @override
  Future<void> onPrint() async {
    if (_excel == null) return;

    final pdf = pw.Document();
    final sheet = _excel!.tables[_currentSheet];

    if (sheet == null) return;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: sheet.rows.first.map((e) => _getCellValue(e)).toList(),
            data: sheet.rows
                .skip(1)
                .map((row) => row.map((e) => _getCellValue(e)).toList())
                .toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }
}
