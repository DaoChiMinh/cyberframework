import 'package:cyberframework/cyberframework.dart';

/// CyberDataTable - collection của CyberDataRow với proper disposal
class CyberDataTable extends ChangeNotifier {
  final String tableName;
  final List<CyberDataRow> _rows = [];
  final Map<String, Type> _columns = {};
  bool _isDisposed = false;

  CyberDataTable({required this.tableName});

  List<CyberDataRow> get rows => List.unmodifiable(_rows);
  int get rowCount => _rows.length;
  Map<String, Type> get columns => Map.unmodifiable(_columns);

  CyberDataRow operator [](int index) {
    return _rows[index];
  }

  bool containerColumn(String columnName) {
    return _columns.containsKey(columnName.toLowerCase());
  }

  void addColumn(String columnName, Type type) {
    _columns[columnName] = type;
  }

  void addRow(CyberDataRow row) {
    if (_isDisposed) {
      debugPrint('⚠️ WARNING: Trying to add row to disposed table!');
      return;
    }

    _rows.add(row);
    row.addListener(_onRowChanged);
    notifyListeners();
  }

  CyberDataRow newRow() {
    return CyberDataRow(columns);
  }

  void removeRow(CyberDataRow row) {
    row.removeListener(_onRowChanged);
    // ✅ Dispose row when removing
    row.disposeAllListeners();
    row.dispose();
    _rows.remove(row);
    notifyListeners();
  }

  void removeAt(int index) {
    if (index >= 0 && index < _rows.length) {
      final row = _rows[index];
      row.removeListener(_onRowChanged);
      // ✅ Dispose row when removing
      row.disposeAllListeners();
      row.dispose();
      _rows.removeAt(index);
      notifyListeners();
    }
  }

  /// ✅ FIXED: Clear with proper disposal
  void clear() {
    for (var row in _rows) {
      row.removeListener(_onRowChanged);
      // ✅ Dispose all widget listeners first
      row.disposeAllListeners();
      // ✅ Then dispose the row itself
      row.dispose();
    }
    _rows.clear();
    notifyListeners();
  }

  void loadData(List<Map<String, dynamic>> data) {
    clear();

    if (data.isNotEmpty) {
      var firstItem = data.first;
      for (var entry in firstItem.entries) {
        var columnName = entry.key;
        var value = entry.value;

        // Detect type từ giá trị (lowercase key để match với containsColumn)
        Type columnType = value?.runtimeType ?? dynamic;
        _columns[columnName.toLowerCase()] = columnType;
      }
    }

    for (var item in data) {
      final row = CyberDataRow(item);
      addRow(row);
    }
  }

  void loadDataFromRows(List<CyberDataRow> rows) {
    clear();

    if (rows.isNotEmpty) {
      _columns.clear();
      // Lấy field names và detect type từ row đầu tiên
      var firstRow = rows.first;
      for (var fieldName in firstRow.fieldNames) {
        var value = firstRow[fieldName];
        Type columnType = value?.runtimeType ?? dynamic;
        _columns[fieldName.toLowerCase()] = columnType;
      }
    }

    // Copy và add từng row
    for (var row in rows) {
      addRow(row.copy());
    }
  }

  void loadDatafromTb(CyberDataTable data) {
    clear();
    for (var row in data.rows) {
      addRow(row.copy());
    }
  }

  String toXml({
    String? tableNameOverride,
    List<String>? includeColumns,
    List<String>? excludeColumns,
  }) {
    final StringBuffer xml = StringBuffer();
    final String tableTag = tableNameOverride ?? tableName;

    for (var row in rows) {
      xml.write(
        row.toXml(
          tableTag,
          includeColumns: includeColumns,
          excludeColumns: excludeColumns,
        ),
      );
    }

    return xml.toString();
  }

  void acceptChanges() {
    for (var row in _rows) {
      row.acceptChanges();
    }
    notifyListeners();
  }

  void rejectChanges() {
    for (var row in _rows) {
      row.rejectChanges();
    }
    notifyListeners();
  }

  List<CyberDataRow> getChangedRows() {
    return _rows.where((row) => row.isDirty).toList();
  }

  bool get hasChanges => _rows.any((row) => row.isDirty);

  List<CyberDataRow> findRows(bool Function(CyberDataRow) predicate) {
    return _rows.where(predicate).toList();
  }

  CyberDataRow? findRow(bool Function(CyberDataRow) predicate) {
    try {
      return _rows.firstWhere(predicate);
    } catch (e) {
      return null;
    }
  }

  List<Map<String, dynamic>> toList() {
    return _rows.map((row) => row.toMap()).toList();
  }

  CyberDataTable copy() {
    final newTable = CyberDataTable(tableName: tableName);
    newTable._columns.addAll(_columns);

    for (var row in _rows) {
      newTable.addRow(row.copy());
    }

    return newTable;
  }

  void _onRowChanged() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  /// ✅ ENHANCED: Dispose with proper cleanup
  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }

    // ✅ Proper cleanup
    for (var row in _rows) {
      row.removeListener(_onRowChanged);
      row.disposeAllListeners();
      row.dispose();
    }
    _rows.clear();

    _isDisposed = true;
    super.dispose();
  }

  /// ✅ NEW: Check if disposed
  bool get isDisposed => _isDisposed;

  @override
  String toString() {
    return 'CyberDataTable{name: $tableName, rows: $rowCount, hasChanges: $hasChanges, disposed: $_isDisposed}';
  }
}
