import 'package:flutter/material.dart';
import 'dart:convert';
import 'CyberDataTable.dart';

/// CyberDataset - collection của CyberDataTable với proper disposal
class CyberDataset extends ChangeNotifier {
  final Map<String, CyberDataTable> _tables = {};
  bool _isDisposed = false;

  Map<String, CyberDataTable> get tables => Map.unmodifiable(_tables);
  int get tableCount => _tables.length;

  CyberDataTable? operator [](dynamic tableName) {
    return Table(tableName);
  }

  CyberDataTable? Table(dynamic TableNameOrindex) {
    if (TableNameOrindex is String) {
      return _tables[TableNameOrindex];
    } else if (TableNameOrindex is int) {
      if (TableNameOrindex < 0 || TableNameOrindex >= _tables.length) {
        return null;
      }
      String tableName = _tables.keys.elementAt(TableNameOrindex);
      return _tables[tableName];
    }
    return null;
  }

  void addTable(CyberDataTable table) {
    if (_isDisposed) {
      return;
    }

    _tables[table.tableName] = table;
    table.addListener(_onTableChanged);
    notifyListeners();
  }

  CyberDataTable createTable(String tableName) {
    final table = CyberDataTable(tableName: tableName);
    addTable(table);
    return table;
  }

  void removeTable(String tableName) {
    final table = _tables[tableName];
    if (table != null) {
      table.removeListener(_onTableChanged);
      // ✅ Dispose table when removing
      table.dispose();
      _tables.remove(tableName);
      notifyListeners();
    }
  }

  /// ✅ FIXED: Clear with proper disposal
  void clear() {
    for (var table in _tables.values) {
      table.removeListener(_onTableChanged);
      // ✅ Dispose table (which will dispose all rows)
      table.dispose();
    }
    _tables.clear();
    notifyListeners();
  }

  void loadFromJson(String jsonString) {
    final data = json.decode(jsonString) as Map<String, dynamic>;
    loadFromMap(data);
  }

  void loadFromMap(Map<String, dynamic> data) {
    clear();

    for (var entry in data.entries) {
      final tableName = entry.key;
      final tableData = entry.value;

      if (tableData is List) {
        final table = createTable(tableName);
        final rows = tableData
            .map((item) => item as Map<String, dynamic>)
            .toList();
        table.loadData(rows);
      } else if (tableData is Map) {
        final table = createTable(tableName);
        table.loadData([tableData as Map<String, dynamic>]);
      }
    }
  }

  void loadTable(String tableName, List<Map<String, dynamic>> data) {
    var table = _tables[tableName];
    table ??= createTable(tableName);
    table.loadData(data);
  }

  void acceptChanges() {
    for (var table in _tables.values) {
      table.acceptChanges();
    }
    notifyListeners();
  }

  void rejectChanges() {
    for (var table in _tables.values) {
      table.rejectChanges();
    }
    notifyListeners();
  }

  bool get hasChanges => _tables.values.any((table) => table.hasChanges);

  List<CyberDataTable> getChangedTables() {
    return _tables.values.where((table) => table.hasChanges).toList();
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};
    for (var entry in _tables.entries) {
      result[entry.key] = entry.value.toList();
    }
    return result;
  }

  String toJson() {
    return json.encode(toMap());
  }

  CyberDataset copy() {
    final newDataset = CyberDataset();
    for (var table in _tables.values) {
      newDataset.addTable(table.copy());
    }
    return newDataset;
  }

  void _onTableChanged() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  /// ✅ ENHANCED: Dispose with proper cleanup
  @override
  void dispose() {
    if (_isDisposed) {
      debugPrint('⚠️ WARNING: Double dispose detected on dataset!');
      return;
    }

    debugPrint('🗑️ Disposing CyberDataset with ${_tables.length} tables');

    for (var table in _tables.values) {
      table.removeListener(_onTableChanged);
      table.dispose();
    }
    _tables.clear();

    _isDisposed = true;
    super.dispose();
  }

  /// ✅ NEW: Check if disposed
  bool get isDisposed => _isDisposed;

  @override
  String toString() {
    return 'CyberDataset{tables: ${_tables.keys.join(", ")}, hasChanges: $hasChanges, disposed: $_isDisposed}';
  }
}

/// Helper để tạo dataset từ JSON response đơn giản
class CyberDatasetHelper {
  static CyberDataset fromFlatJson(
    String jsonString, {
    String tableName = "Table1",
  }) {
    final dataset = CyberDataset();
    final data = json.decode(jsonString);

    if (data is List) {
      final rows = data.map((item) => item as Map<String, dynamic>).toList();
      dataset.loadTable(tableName, rows);
    } else if (data is Map) {
      dataset.loadTable(tableName, [data as Map<String, dynamic>]);
    }

    return dataset;
  }

  static CyberDataset fromNestedJson(String jsonString) {
    final dataset = CyberDataset();
    dataset.loadFromJson(jsonString);
    return dataset;
  }
}
