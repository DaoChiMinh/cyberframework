import 'package:cyberframework/cyberframework.dart';

/// CyberDataTable - collection của CyberDataRow với proper disposal
class CyberDataTable extends ChangeNotifier {
  final String tableName;
  final List<CyberDataRow> _rows = [];
  final Map<String, Type> _columns = {};
  bool _isDisposed = false;

  // ✅ NEW: Batch mode flag
  bool _isBatchMode = false;

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

  // ✅ OPTIMIZED: Smart notification
  void addRow(CyberDataRow row) {
    if (_isDisposed) {
      return;
    }

    _rows.add(row);
    row.addListener(_onRowChanged);

    // ✅ Only notify if not in batch mode
    if (!_isBatchMode) {
      notifyListeners();
    }
  }

  /// ✅ NEW: Add multiple rows in batch (no notifications until done)
  void addRowsBatch(List<CyberDataRow> rows) {
    if (_isDisposed) return;
    if (rows.isEmpty) return;

    beginBatch();
    try {
      for (var row in rows) {
        _rows.add(row);
        row.addListener(_onRowChanged);
      }
    } finally {
      endBatch();
    }
  }

  /// ✅ NEW: Batch mode control
  void beginBatch() {
    _isBatchMode = true;
  }

  void endBatch() {
    _isBatchMode = false;
    notifyListeners();
  }

  /// ✅ NEW: Execute action in batch mode
  void batch(void Function() action) {
    beginBatch();
    try {
      action();
    } finally {
      endBatch();
    }
  }

  /// ✅ FIXED: Tạo row mới với các giá trị default theo type của column
  ///
  /// Trước đây hàm này truyền Map<String, Type> vào constructor CyberDataRow
  /// gây ra lỗi vì constructor nhận Map<String, dynamic>
  ///
  /// Bây giờ tạo đúng giá trị default theo type:
  /// - String -> ""
  /// - int -> 0
  /// - double -> 0.0
  /// - bool -> false
  /// - DateTime -> null
  /// - Other types -> null
  ///
  /// Usage:
  /// ```dart
  /// var newRow = table.newRow();
  /// newRow['name'] = 'John';
  /// newRow['age'] = 25;
  /// table.addRow(newRow);
  /// ```
  CyberDataRow newRow() {
    final initialData = <String, dynamic>{};

    // Tạo giá trị default cho mỗi column theo type
    for (var entry in _columns.entries) {
      final columnName = entry.key;
      final columnType = entry.value;

      // Assign default value based on type
      if (columnType == String) {
        initialData[columnName] = '';
      } else if (columnType == int) {
        initialData[columnName] = 0;
      } else if (columnType == double) {
        initialData[columnName] = 0.0;
      } else if (columnType == bool) {
        initialData[columnName] = false;
      } else if (columnType == DateTime) {
        initialData[columnName] = null; // DateTime thường nullable
      } else {
        initialData[columnName] = null; // Default cho các type khác
      }
    }

    return CyberDataRow(initialData);
  }

  void removeRow(CyberDataRow row) {
    row.removeListener(_onRowChanged);
    row.disposeAllListeners();
    row.dispose();
    _rows.remove(row);

    if (!_isBatchMode) {
      notifyListeners();
    }
  }

  void removeAt(int index) {
    if (index >= 0 && index < _rows.length) {
      final row = _rows[index];
      row.removeListener(_onRowChanged);
      row.disposeAllListeners();
      row.dispose();
      _rows.removeAt(index);

      if (!_isBatchMode) {
        notifyListeners();
      }
    }
  }

  /// ✅ OPTIMIZED: Clear with proper disposal
  void clear() {
    if (_rows.isEmpty) return;

    for (var row in _rows) {
      row.removeListener(_onRowChanged);
      row.disposeAllListeners();
      row.dispose();
    }
    _rows.clear();

    if (!_isBatchMode) {
      notifyListeners();
    }
  }

  /// ✅ OPTIMIZED: Batch mode for better performance
  void loadData(List<Map<String, dynamic>> data) {
    batch(() {
      // Clear existing data
      for (var row in _rows) {
        row.removeListener(_onRowChanged);
        row.disposeAllListeners();
        row.dispose();
      }
      _rows.clear();

      // Detect columns from first item
      if (data.isNotEmpty) {
        var firstItem = data.first;
        for (var entry in firstItem.entries) {
          var columnName = entry.key;
          var value = entry.value;
          Type columnType = value?.runtimeType ?? dynamic;
          _columns[columnName.toLowerCase()] = columnType;
        }
      }

      // Add all rows
      for (var item in data) {
        final row = CyberDataRow(item);
        _rows.add(row);
        row.addListener(_onRowChanged);
      }
    });
  }

  /// ✅ OPTIMIZED: Batch mode + zero-copy option
  void loadDataFromRows(List<CyberDataRow> rows, {bool copy = true}) {
    batch(() {
      // Clear existing data
      for (var row in _rows) {
        row.removeListener(_onRowChanged);
        row.disposeAllListeners();
        row.dispose();
      }
      _rows.clear();

      // Detect columns from first row
      if (rows.isNotEmpty) {
        _columns.clear();
        var firstRow = rows.first;
        for (var fieldName in firstRow.fieldNames) {
          var value = firstRow[fieldName];
          Type columnType = value?.runtimeType ?? dynamic;
          _columns[fieldName.toLowerCase()] = columnType;
        }
      }

      // Add rows (copy or transfer)
      for (var row in rows) {
        final targetRow = copy ? row.copy() : row;
        _rows.add(targetRow);
        targetRow.addListener(_onRowChanged);
      }
    });
  }

  /// ✅ OPTIMIZED: Batch mode + smart copying
  void loadDatafromTb(CyberDataTable data, {bool copy = true}) {
    batch(() {
      // Clear existing data
      for (var row in _rows) {
        row.removeListener(_onRowChanged);
        row.disposeAllListeners();
        row.dispose();
      }
      _rows.clear();

      // Add rows
      for (var row in data.rows) {
        final targetRow = copy ? row.copy() : row;
        _rows.add(targetRow);
        targetRow.addListener(_onRowChanged);
      }
    });
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
    if (!_isBatchMode) {
      notifyListeners();
    }
  }

  void rejectChanges() {
    for (var row in _rows) {
      row.rejectChanges();
    }
    if (!_isBatchMode) {
      notifyListeners();
    }
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

    newTable.batch(() {
      for (var row in _rows) {
        final newRow = row.copy();
        newTable._rows.add(newRow);
        newRow.addListener(newTable._onRowChanged);
      }
    });

    return newTable;
  }

  void _onRowChanged() {
    if (!_isDisposed && !_isBatchMode) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }

    for (var row in _rows) {
      row.removeListener(_onRowChanged);
      row.disposeAllListeners();
      row.dispose();
    }
    _rows.clear();

    _isDisposed = true;
    super.dispose();
  }

  bool get isDisposed => _isDisposed;

  @override
  String toString() {
    return 'CyberDataTable{name: $tableName, rows: $rowCount, hasChanges: $hasChanges, disposed: $_isDisposed}';
  }
}
