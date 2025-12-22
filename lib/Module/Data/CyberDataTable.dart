import 'package:flutter/material.dart';
import 'CyberDataRow.dart';

/// CyberDataTable - collection của CyberDataRow (giống ADO.NET DataTable)
class CyberDataTable extends ChangeNotifier {
  final String tableName;
  final List<CyberDataRow> _rows = [];
  final Map<String, Type> _columns = {};

  CyberDataTable({required this.tableName});

  /// Get rows
  List<CyberDataRow> get rows => List.unmodifiable(_rows);

  /// Get row count
  int get rowCount => _rows.length;

  /// Get columns
  Map<String, Type> get columns => Map.unmodifiable(_columns);

  /// Indexer để get row theo index
  CyberDataRow operator [](int index) {
    return _rows[index];
  }

  /// Define column
  bool containerColumn(String columnName) {
    return _columns.containsKey(columnName.toLowerCase());
  }

  /// Define column
  void addColumn(String columnName, Type type) {
    _columns[columnName] = type;
  }

  /// Add row
  void addRow(CyberDataRow row) {
    _rows.add(row);
    row.addListener(_onRowChanged);
    notifyListeners();
  }

  /// Create new row
  CyberDataRow newRow() {
    return CyberDataRow(columns);
  }

  /// Remove row
  void removeRow(CyberDataRow row) {
    row.removeListener(_onRowChanged);
    _rows.remove(row);
    notifyListeners();
  }

  /// Remove row at index
  void removeAt(int index) {
    if (index >= 0 && index < _rows.length) {
      final row = _rows[index];
      row.removeListener(_onRowChanged);
      _rows.removeAt(index);
      notifyListeners();
    }
  }

  /// Clear all rows
  void clear() {
    for (var row in _rows) {
      row.removeListener(_onRowChanged);
    }
    _rows.clear();
    notifyListeners();
  }

  /// Load từ List<Map>
  void loadData(List<Map<String, dynamic>> data) {
    clear();
    for (var item in data) {
      final row = CyberDataRow(item);
      addRow(row);
    }
  }

  void loadDatafromTb(CyberDataTable data) {
    clear();
    for (var row in data.rows) {
      addRow(row.copy());
    }
  }

  /// Accept all changes
  void acceptChanges() {
    for (var row in _rows) {
      row.acceptChanges();
    }
    notifyListeners();
  }

  /// Reject all changes
  void rejectChanges() {
    for (var row in _rows) {
      row.rejectChanges();
    }
    notifyListeners();
  }

  /// Get changed rows
  List<CyberDataRow> getChangedRows() {
    return _rows.where((row) => row.isDirty).toList();
  }

  /// Check có thay đổi không
  bool get hasChanges => _rows.any((row) => row.isDirty);

  /// Find rows by condition
  List<CyberDataRow> findRows(bool Function(CyberDataRow) predicate) {
    return _rows.where(predicate).toList();
  }

  /// Find first row by condition
  CyberDataRow? findRow(bool Function(CyberDataRow) predicate) {
    try {
      return _rows.firstWhere(predicate);
    } catch (e) {
      return null;
    }
  }

  /// Export to List<Map>
  List<Map<String, dynamic>> toList() {
    return _rows.map((row) => row.toMap()).toList();
  }

  /// Copy table
  CyberDataTable copy() {
    final newTable = CyberDataTable(tableName: tableName);
    newTable._columns.addAll(_columns);

    for (var row in _rows) {
      newTable.addRow(row.copy());
    }

    return newTable;
  }

  void _onRowChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    for (var row in _rows) {
      row.removeListener(_onRowChanged);
      row.dispose();
    }
    _rows.clear();
    super.dispose();
  }

  @override
  String toString() {
    return 'CyberDataTable{name: $tableName, rows: $rowCount, hasChanges: $hasChanges}';
  }
}
