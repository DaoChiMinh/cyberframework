import 'package:flutter/material.dart';
import 'dart:convert';
import 'CyberDataTable.dart';

/// CyberDataset - collection của CyberDataTable (giống ADO.NET Dataset)
class CyberDataset extends ChangeNotifier {
  final Map<String, CyberDataTable> _tables = {};

  /// Get tables
  Map<String, CyberDataTable> get tables => Map.unmodifiable(_tables);

  /// Get table count
  int get tableCount => _tables.length;

  /// Indexer để get table theo name
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

  /// Add table
  void addTable(CyberDataTable table) {
    _tables[table.tableName] = table;
    table.addListener(_onTableChanged);
    notifyListeners();
  }

  /// Create và add table
  CyberDataTable createTable(String tableName) {
    final table = CyberDataTable(tableName: tableName);
    addTable(table);
    return table;
  }

  /// Remove table
  void removeTable(String tableName) {
    final table = _tables[tableName];
    if (table != null) {
      table.removeListener(_onTableChanged);
      _tables.remove(tableName);
      notifyListeners();
    }
  }

  /// Clear all tables
  void clear() {
    for (var table in _tables.values) {
      table.removeListener(_onTableChanged);
      table.dispose();
    }
    _tables.clear();
    notifyListeners();
  }

  /// Load từ JSON (từ API)
  /// JSON format: { "tableName": [ {...}, {...} ], "tableName2": [...] }
  void loadFromJson(String jsonString) {
    final data = json.decode(jsonString) as Map<String, dynamic>;
    loadFromMap(data);
  }

  /// Load từ Map
  void loadFromMap(Map<String, dynamic> data) {
    clear();

    for (var entry in data.entries) {
      final tableName = entry.key;
      final tableData = entry.value;

      if (tableData is List) {
        // Array of objects → DataTable
        final table = createTable(tableName);
        final rows = tableData
            .map((item) => item as Map<String, dynamic>)
            .toList();
        table.loadData(rows);
      } else if (tableData is Map) {
        // Single object → DataTable với 1 row
        final table = createTable(tableName);
        table.loadData([tableData as Map<String, dynamic>]);
      }
    }
  }

  /// Load single table từ List
  void loadTable(String tableName, List<Map<String, dynamic>> data) {
    var table = _tables[tableName];
    table ??= createTable(tableName);
    table.loadData(data);
  }

  /// Accept all changes
  void acceptChanges() {
    for (var table in _tables.values) {
      table.acceptChanges();
    }
    notifyListeners();
  }

  /// Reject all changes
  void rejectChanges() {
    for (var table in _tables.values) {
      table.rejectChanges();
    }
    notifyListeners();
  }

  /// Check có thay đổi không
  bool get hasChanges => _tables.values.any((table) => table.hasChanges);

  /// Get changed tables
  List<CyberDataTable> getChangedTables() {
    return _tables.values.where((table) => table.hasChanges).toList();
  }

  /// Export to Map
  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};
    for (var entry in _tables.entries) {
      result[entry.key] = entry.value.toList();
    }
    return result;
  }

  /// Export to JSON string
  String toJson() {
    return json.encode(toMap());
  }

  /// Copy dataset
  CyberDataset copy() {
    final newDataset = CyberDataset();
    for (var table in _tables.values) {
      newDataset.addTable(table.copy());
    }
    return newDataset;
  }

  void _onTableChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    for (var table in _tables.values) {
      table.removeListener(_onTableChanged);
      table.dispose();
    }
    _tables.clear();
    super.dispose();
  }

  @override
  String toString() {
    return 'CyberDataset{tables: ${_tables.keys.join(", ")}, hasChanges: $hasChanges}';
  }
}

/// Helper để tạo dataset từ JSON response đơn giản
class CyberDatasetHelper {
  /// Load từ flat JSON (single table)
  /// Example: [{"id": 1, "name": "John"}, {"id": 2, "name": "Jane"}]
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

  /// Load từ nested JSON (multiple tables)
  /// Example: {"users": [...], "orders": [...]}
  static CyberDataset fromNestedJson(String jsonString) {
    final dataset = CyberDataset();
    dataset.loadFromJson(jsonString);
    return dataset;
  }
}
