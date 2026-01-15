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
        initialData[columnName] = null;
      } else {
        initialData[columnName] = null;
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

  /// 🎯 NEW: Bulk remove range - O(n) performance
  /// Remove items from [start] to [end] (exclusive)
  ///
  /// Example:
  /// ```dart
  /// table.removeRange(0, 100); // Remove first 100 items
  /// ```
  void removeRange(int start, int end) {
    if (_isDisposed) return;

    if (start < 0 || end > _rows.length || start >= end) {
      throw RangeError(
        'Invalid range: start=$start, end=$end, length=${_rows.length}',
      );
    }

    // Dispose rows in range
    for (int i = start; i < end; i++) {
      final row = _rows[i];
      row.removeListener(_onRowChanged);
      row.disposeAllListeners();
      row.dispose();
    }

    // Bulk remove - O(n) instead of O(n²)
    _rows.removeRange(start, end);

    if (!_isBatchMode) {
      notifyListeners();
    }
  }

  /// 🎯 NEW: Remove first N items - O(n) performance
  ///
  /// Example:
  /// ```dart
  /// table.removeFirstN(100); // Remove first 100 items
  /// ```
  void removeFirstN(int count) {
    if (_isDisposed) return;

    if (count <= 0) return;

    if (count > _rows.length) {
      throw RangeError('count ($count) > length (${_rows.length})');
    }

    removeRange(0, count);
  }

  /// 🎯 NEW: Remove last N items - O(1) to O(n) depending on implementation
  ///
  /// Example:
  /// ```dart
  /// table.removeLastN(50); // Remove last 50 items
  /// ```
  void removeLastN(int count) {
    if (_isDisposed) return;

    if (count <= 0) return;

    if (count > _rows.length) {
      throw RangeError('count ($count) > length (${_rows.length})');
    }

    final newLength = _rows.length - count;
    removeRange(newLength, _rows.length);
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

  // Thêm vào class CyberDataTable

  /// Select rows based on filter expression (like DataTable.Select in C#)
  ///
  /// Supported operators:
  /// - Equality: Ma_kh = 'ABC'
  /// - Comparison: Tuoi > 25, Tuoi >= 18, Tuoi < 60, Tuoi <= 50
  /// - Not Equal: Ma_kh != 'ABC' or Ma_kh <> 'ABC'
  /// - LIKE: Ten LIKE '%Nguyen%'
  /// - IN: Ma_kh IN ('ABC', 'DEF', 'GHI')
  /// - AND: Ma_kh = 'ABC' AND Tuoi > 25
  /// - OR: Ma_kh = 'ABC' OR Ma_kh = 'DEF'
  ///
  /// [copy] - If true, returns copied rows (changes won't affect original table)
  ///          If false, returns reference (changes will affect original table)
  ///
  /// Example:
  /// ```dart
  /// // Reference - changes affect original table
  /// var result = table.select("Ma_kh = 'ABC'");
  ///
  /// // Copy - changes don't affect original table
  /// var result2 = table.select("Ma_kh = 'ABC'", copy: true);
  /// ```
  List<CyberDataRow> select(String filter, {bool copy = false}) {
    if (filter.isEmpty) {
      return copy ? _rows.map((row) => row.copy()).toList() : List.from(_rows);
    }

    // Handle AND operator
    if (filter.toUpperCase().contains(' AND ')) {
      return _selectAnd(filter, copy: copy);
    }

    // Handle OR operator
    if (filter.toUpperCase().contains(' OR ')) {
      return _selectOr(filter, copy: copy);
    }

    // Single condition
    return _selectSingle(filter, copy: copy);
  }

  /// Select and return copied rows (changes won't affect original table)
  ///
  /// This is a convenience method equivalent to: select(filter, copy: true)
  ///
  /// Example:
  /// ```dart
  /// var result = table.selectCopy("Ma_kh = 'ABC'");
  /// result[0]['ten'] = 'MODIFIED'; // Original table unchanged
  /// ```
  List<CyberDataRow> selectCopy(String filter) {
    return select(filter, copy: true);
  }

  List<CyberDataRow> _selectSingle(String filter, {bool copy = false}) {
    List<CyberDataRow> result;

    if (filter.contains('>=')) {
      result = _filterGreaterOrEqual(filter);
    } else if (filter.contains('<=')) {
      result = _filterLessOrEqual(filter);
    } else if (filter.contains('!=') || filter.contains('<>')) {
      result = _filterNotEqual(filter);
    } else if (filter.contains('=')) {
      result = _filterEqual(filter);
    } else if (filter.contains('>')) {
      result = _filterGreater(filter);
    } else if (filter.contains('<')) {
      result = _filterLess(filter);
    } else if (filter.toUpperCase().contains(' LIKE ')) {
      result = _filterLike(filter);
    } else if (filter.toUpperCase().contains(' IN ')) {
      result = _filterIn(filter);
    } else {
      result = List.from(_rows);
    }

    return copy ? result.map((row) => row.copy()).toList() : result;
  }

  List<CyberDataRow> _selectAnd(String filter, {bool copy = false}) {
    final conditions = _splitByOperator(filter, ' AND ');
    var result = List<CyberDataRow>.from(_rows);

    for (var condition in conditions) {
      result = _filterList(result, condition.trim());
    }

    return copy ? result.map((row) => row.copy()).toList() : result;
  }

  List<CyberDataRow> _selectOr(String filter, {bool copy = false}) {
    final conditions = _splitByOperator(filter, ' OR ');
    final resultSet = <CyberDataRow>{};

    for (var condition in conditions) {
      resultSet.addAll(_selectSingle(condition.trim(), copy: false));
    }

    var result = resultSet.toList();
    return copy ? result.map((row) => row.copy()).toList() : result;
  }

  List<String> _splitByOperator(String filter, String operator) {
    final upperFilter = filter.toUpperCase();
    final upperOp = operator.toUpperCase();
    final parts = <String>[];
    var start = 0;
    var inQuote = false;

    for (var i = 0; i < filter.length; i++) {
      if (filter[i] == "'" || filter[i] == '"') {
        inQuote = !inQuote;
      }

      if (!inQuote && i <= filter.length - operator.length) {
        if (upperFilter.substring(i, i + operator.length) == upperOp) {
          parts.add(filter.substring(start, i));
          start = i + operator.length;
          i += operator.length - 1;
        }
      }
    }

    parts.add(filter.substring(start));
    return parts;
  }

  List<CyberDataRow> _filterList(List<CyberDataRow> rows, String filter) {
    if (filter.contains('>=')) {
      return _filterGreaterOrEqualFromList(rows, filter);
    } else if (filter.contains('<=')) {
      return _filterLessOrEqualFromList(rows, filter);
    } else if (filter.contains('!=') || filter.contains('<>')) {
      return _filterNotEqualFromList(rows, filter);
    } else if (filter.contains('=')) {
      return _filterEqualFromList(rows, filter);
    } else if (filter.contains('>')) {
      return _filterGreaterFromList(rows, filter);
    } else if (filter.contains('<')) {
      return _filterLessFromList(rows, filter);
    } else if (filter.toUpperCase().contains(' LIKE ')) {
      return _filterLikeFromList(rows, filter);
    } else if (filter.toUpperCase().contains(' IN ')) {
      return _filterInFromList(rows, filter);
    }

    return rows;
  }

  List<CyberDataRow> _filterEqual(String filter) {
    return _filterEqualFromList(_rows, filter);
  }

  List<CyberDataRow> _filterEqualFromList(
    List<CyberDataRow> rows,
    String filter,
  ) {
    final parts = filter.split('=');
    if (parts.length != 2) return rows;

    final property = parts[0].trim().toLowerCase();
    final value = _cleanValue(parts[1].trim());

    return rows.where((row) {
      if (!row.hasField(property)) return false;
      final rowValue = row[property];
      return rowValue?.toString() == value;
    }).toList();
  }

  List<CyberDataRow> _filterNotEqual(String filter) {
    return _filterNotEqualFromList(_rows, filter);
  }

  List<CyberDataRow> _filterNotEqualFromList(
    List<CyberDataRow> rows,
    String filter,
  ) {
    final operator = filter.contains('!=') ? '!=' : '<>';
    final parts = filter.split(operator);
    if (parts.length != 2) return rows;

    final property = parts[0].trim().toLowerCase();
    final value = _cleanValue(parts[1].trim());

    return rows.where((row) {
      if (!row.hasField(property)) return false;
      final rowValue = row[property];
      return rowValue?.toString() != value;
    }).toList();
  }

  List<CyberDataRow> _filterGreater(String filter) {
    return _filterGreaterFromList(_rows, filter);
  }

  List<CyberDataRow> _filterGreaterFromList(
    List<CyberDataRow> rows,
    String filter,
  ) {
    final parts = filter.split('>');
    if (parts.length != 2) return rows;

    final property = parts[0].trim().toLowerCase();
    final value = num.tryParse(parts[1].trim());
    if (value == null) return rows;

    return rows.where((row) {
      if (!row.hasField(property)) return false;
      final rowValue = num.tryParse(row[property]?.toString() ?? '');
      if (rowValue == null) return false;
      return rowValue > value;
    }).toList();
  }

  List<CyberDataRow> _filterGreaterOrEqual(String filter) {
    return _filterGreaterOrEqualFromList(_rows, filter);
  }

  List<CyberDataRow> _filterGreaterOrEqualFromList(
    List<CyberDataRow> rows,
    String filter,
  ) {
    final parts = filter.split('>=');
    if (parts.length != 2) return rows;

    final property = parts[0].trim().toLowerCase();
    final value = num.tryParse(parts[1].trim());
    if (value == null) return rows;

    return rows.where((row) {
      if (!row.hasField(property)) return false;
      final rowValue = num.tryParse(row[property]?.toString() ?? '');
      if (rowValue == null) return false;
      return rowValue >= value;
    }).toList();
  }

  List<CyberDataRow> _filterLess(String filter) {
    return _filterLessFromList(_rows, filter);
  }

  List<CyberDataRow> _filterLessFromList(
    List<CyberDataRow> rows,
    String filter,
  ) {
    final parts = filter.split('<');
    if (parts.length != 2) return rows;

    final property = parts[0].trim().toLowerCase();
    final value = num.tryParse(parts[1].trim());
    if (value == null) return rows;

    return rows.where((row) {
      if (!row.hasField(property)) return false;
      final rowValue = num.tryParse(row[property]?.toString() ?? '');
      if (rowValue == null) return false;
      return rowValue < value;
    }).toList();
  }

  List<CyberDataRow> _filterLessOrEqual(String filter) {
    return _filterLessOrEqualFromList(_rows, filter);
  }

  List<CyberDataRow> _filterLessOrEqualFromList(
    List<CyberDataRow> rows,
    String filter,
  ) {
    final parts = filter.split('<=');
    if (parts.length != 2) return rows;

    final property = parts[0].trim().toLowerCase();
    final value = num.tryParse(parts[1].trim());
    if (value == null) return rows;

    return rows.where((row) {
      if (!row.hasField(property)) return false;
      final rowValue = num.tryParse(row[property]?.toString() ?? '');
      if (rowValue == null) return false;
      return rowValue <= value;
    }).toList();
  }

  List<CyberDataRow> _filterLike(String filter) {
    return _filterLikeFromList(_rows, filter);
  }

  List<CyberDataRow> _filterLikeFromList(
    List<CyberDataRow> rows,
    String filter,
  ) {
    final parts = _splitByOperator(filter, ' LIKE ');
    if (parts.length != 2) return rows;

    final property = parts[0].trim().toLowerCase();
    final pattern = _cleanValue(
      parts[1].trim(),
    ).replaceAll('%', '.*').replaceAll('_', '.');

    final regex = RegExp(pattern, caseSensitive: false);

    return rows.where((row) {
      if (!row.hasField(property)) return false;
      final rowValue = row[property]?.toString() ?? '';
      return regex.hasMatch(rowValue);
    }).toList();
  }

  List<CyberDataRow> _filterIn(String filter) {
    return _filterInFromList(_rows, filter);
  }

  List<CyberDataRow> _filterInFromList(List<CyberDataRow> rows, String filter) {
    final parts = _splitByOperator(filter, ' IN ');
    if (parts.length != 2) return rows;

    final property = parts[0].trim().toLowerCase();
    final valuesStr = parts[1].trim().replaceAll('(', '').replaceAll(')', '');

    final values = valuesStr
        .split(',')
        .map((e) => _cleanValue(e.trim()))
        .toList();

    return rows.where((row) {
      if (!row.hasField(property)) return false;
      final rowValue = row[property]?.toString();
      return values.contains(rowValue);
    }).toList();
  }

  String _cleanValue(String value) {
    return value.replaceAll("'", "").replaceAll('"', '').trim();
  }

  @override
  String toString() {
    return 'CyberDataTable{name: $tableName, rows: $rowCount, hasChanges: $hasChanges, disposed: $_isDisposed}';
  }
}
