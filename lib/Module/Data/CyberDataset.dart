import 'package:cyberframework/cyberframework.dart';

/// CyberDataset - collection của CyberDataTable với proper disposal
class CyberDataset extends ChangeNotifier {
  final Map<String, CyberDataTable> _tables = {};
  bool _isDisposed = false;

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

  bool checkStatus(BuildContext contex, {bool isShowMsg = true}) {
    if (_isDisposed) {
      return false;
    }

    // Quét tất cả các tables
    for (var table in _tables.values) {
      // Kiểm tra table có dòng dữ liệu
      if (table.rows.isEmpty) {
        continue;
      }

      // Kiểm tra có cột Status không
      if (!table.containerColumn('status')) {
        continue;
      }
      // Lấy dòng đầu tiên
      var firstRow = table.rows.first;

      // Lấy giá trị Status
      String? statusValue = firstRow['status']?.toString().trim().toUpperCase();
      String? msgValue = table.containerColumn('msg')
          ? firstRow['Msg']?.toString()
          : null;

      // Lấy nội dung message để hiển thị
      String message = firstRow['note'].toString();

      // ✅ Kiểm tra Status = "N"
      if (statusValue == 'N') {
        // Hiển thị message nếu isShowMsg = true
        if (isShowMsg) {
          // Tránh hiển thị 2 lần
          message.V_MsgBox(contex, type: CyberMsgBoxType.error);
        }
        return false; // ❌ Return false ngay khi tìm thấy Status = "N"
      }
      // ✅ Nếu có Msg = "Y" và isShowMsg = true => luôn hiển thị message
      if (msgValue == 'Y' && isShowMsg) {
        message.V_MsgBox(contex, type: CyberMsgBoxType.warning);
      }
    }

    // ✅ Tất cả Status hợp lệ (khác "N")
    return true;
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

  // String toXml({
  //   Map<String, List<String>>? tableIncludeColumns,
  //   Map<String, List<String>>? tableExcludeColumns,
  // }) {
  //   final StringBuffer xml = StringBuffer();

  //   for (var entry in tables.entries) {
  //     final tableName = entry.key;
  //     final table = entry.value;

  //     // Lấy include/exclude columns cho table này
  //     List<String>? includeColumns = tableIncludeColumns?[tableName];
  //     List<String>? excludeColumns = tableExcludeColumns?[tableName];

  //     xml.write(
  //       table.toXml(
  //         includeColumns: includeColumns,
  //         excludeColumns: excludeColumns,
  //       ),
  //     );
  //   }

  //   return xml.toString();
  // }

  String toXml({
    List<String>? tableNames,
    Map<String, List<String>>? tableIncludeColumns,
    Map<String, List<String>>? tableExcludeColumns,
  }) {
    final StringBuffer xml = StringBuffer();

    // Nếu có danh sách tableNames, duyệt theo thứ tự đó
    if (tableNames != null && tableNames.isNotEmpty) {
      for (var tableName in tableNames) {
        final table = this[tableName];

        // Bỏ qua nếu table không tồn tại
        if (table == null) {
          debugPrint('⚠️ WARNING: Table "$tableName" not found in dataset');
          continue;
        }

        // Lấy include/exclude columns cho table này
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
      // Nếu không có tableNames, duyệt tất cả tables
      for (var entry in tables.entries) {
        final tableName = entry.key;
        final table = entry.value;

        // Lấy include/exclude columns cho table này
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
