import 'package:cyberframework/cyberframework.dart';

/// CyberDataset - collection của CyberDataTable với proper disposal
class CyberDataset extends ChangeNotifier {
  final Map<String, CyberDataTable> _tables = {};
  bool _isDisposed = false;

  // ✅ NEW: Batch mode flag
  bool _isBatchMode = false;

  Map<String, CyberDataTable> get tables => Map.unmodifiable(_tables);
  int get tableCount => _tables.length;

  CyberDataTable? operator [](dynamic tableName) {
    return Table(tableName);
  }

  // ignore: non_constant_identifier_names
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

  /// ✅ NEW: Batch mode control
  void beginBatch() {
    _isBatchMode = true;
  }

  void endBatch() {
    _isBatchMode = false;
    notifyListeners();
  }

  void batch(void Function() action) {
    beginBatch();
    try {
      action();
    } finally {
      endBatch();
    }
  }

  void addTable(CyberDataTable table) {
    if (_isDisposed) {
      return;
    }

    _tables[table.tableName] = table;
    table.addListener(_onTableChanged);

    if (!_isBatchMode) {
      notifyListeners();
    }
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
      table.dispose();
      _tables.remove(tableName);

      if (!_isBatchMode) {
        notifyListeners();
      }
    }
  }

  Future<bool> checkStatus(BuildContext contex, {bool isShowMsg = true}) async {
    if (_isDisposed) {
      return false;
    }

    for (var table in _tables.values) {
      if (table.rows.isEmpty) {
        continue;
      }

      if (!table.containerColumn('status')) {
        continue;
      }

      var firstRow = table.rows.first;
      String? statusValue = firstRow['status']?.toString().trim().toUpperCase();
      String? msgValue = table.containerColumn('msg')
          ? firstRow['Msg']?.toString()
          : null;
      String message = firstRow['note'].toString();

      if (statusValue == 'N') {
        if (isShowMsg) {
          await message.V_MsgBox(contex, type: CyberMsgBoxType.error);
        }
        return false;
      }

      if (msgValue == 'Y' && isShowMsg) {
        await message.V_MsgBox(contex, type: CyberMsgBoxType.warning);
      }
    }

    return true;
  }

  void clear() {
    if (_tables.isEmpty) return;

    for (var table in _tables.values) {
      table.removeListener(_onTableChanged);
      table.dispose();
    }
    _tables.clear();

    if (!_isBatchMode) {
      notifyListeners();
    }
  }

  /// ✅ OPTIMIZED: Batch mode for loading
  void loadFromJson(String jsonString) {
    final data = json.decode(jsonString) as Map<String, dynamic>;
    loadFromMap(data);
  }

  void loadFromMap(Map<String, dynamic> data) {
    batch(() {
      // Clear existing tables
      for (var table in _tables.values) {
        table.removeListener(_onTableChanged);
        table.dispose();
      }
      _tables.clear();

      // Load new tables
      for (var entry in data.entries) {
        final tableName = entry.key;
        final tableData = entry.value;

        if (tableData is List) {
          final table = CyberDataTable(tableName: tableName);
          _tables[tableName] = table;
          table.addListener(_onTableChanged);

          final rows = tableData
              .map((item) => item as Map<String, dynamic>)
              .toList();
          table.loadData(rows);
        } else if (tableData is Map) {
          final table = CyberDataTable(tableName: tableName);
          _tables[tableName] = table;
          table.addListener(_onTableChanged);
          table.loadData([tableData as Map<String, dynamic>]);
        }
      }
    });
  }

  void loadTable(String tableName, List<Map<String, dynamic>> data) {
    var table = _tables[tableName];

    table ??= createTable(tableName);

    table.loadData(data);
  }

  String toXml({
    List<String>? tableNames,
    Map<String, List<String>>? tableIncludeColumns,
    Map<String, List<String>>? tableExcludeColumns,
  }) {
    final StringBuffer xml = StringBuffer();

    if (tableNames != null && tableNames.isNotEmpty) {
      for (var tableName in tableNames) {
        final table = this[tableName];
        if (table == null) continue;

        List<String>? includeColumns = tableIncludeColumns?[tableName];
        List<String>? excludeColumns = tableExcludeColumns?[tableName];

        xml.write(
          table.toXml(
            includeColumns: includeColumns,
            excludeColumns: excludeColumns,
          ),
        );
      }
    } else {
      for (var entry in tables.entries) {
        final tableName = entry.key;
        final table = entry.value;

        List<String>? includeColumns = tableIncludeColumns?[tableName];
        List<String>? excludeColumns = tableExcludeColumns?[tableName];

        xml.write(
          table.toXml(
            includeColumns: includeColumns,
            excludeColumns: excludeColumns,
          ),
        );
      }
    }

    return xml.toString();
  }

  void acceptChanges() {
    for (var table in _tables.values) {
      table.acceptChanges();
    }
    if (!_isBatchMode) {
      notifyListeners();
    }
  }

  void rejectChanges() {
    for (var table in _tables.values) {
      table.rejectChanges();
    }
    if (!_isBatchMode) {
      notifyListeners();
    }
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

    newDataset.batch(() {
      for (var table in _tables.values) {
        final newTable = table.copy();
        newDataset._tables[newTable.tableName] = newTable;
        newTable.addListener(newDataset._onTableChanged);
      }
    });

    return newDataset;
  }

  void _onTableChanged() {
    if (!_isDisposed && !_isBatchMode) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }

    for (var table in _tables.values) {
      table.removeListener(_onTableChanged);
      table.dispose();
    }
    _tables.clear();

    _isDisposed = true;
    super.dispose();
  }

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
