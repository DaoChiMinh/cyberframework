import 'package:cyberframework/Module/Data/CyberDataset.dart';

class ReturnData {
  bool? status;
  String? message;
  dynamic data;
  List<int>? noRow;
  bool? isConnect;
  dynamic cyberObject;

  ReturnData({
    this.status,
    this.message,
    this.data,
    this.noRow,
    this.isConnect,
    this.cyberObject,
  });

  factory ReturnData.fromJson(Map<String, dynamic> json) {
    return ReturnData(
      status: json['status'] as bool?,
      message: json['message'] as String?,
      data: json['data'],
      noRow: (json['noRow'] as List?)?.cast<int>(),
      isConnect: json['isConnect'] as bool?,
      cyberObject: json['CyberObject'],
    );
  }

  bool isValid() {
    if (status == false && message == null) return false;
    if (status == false) return false;
    return true;
  }

  // ============================================================================
  // ⭐ CONVERT TO CYBERDATASET - LOWERCASE KEYS
  // ============================================================================

  /// Convert data sang CyberDataset với keys normalized thành lowercase
  /// Usage:
  /// ```dart
  /// final response = await context.callApi(...);
  /// final dataset = response.toCyberDataset();
  /// final table = dataset['TableName']; // case-insensitive
  /// ```
  CyberDataset? toCyberDataset() {
    if (data == null) return null;

    try {
      final dataset = CyberDataset();

      if (data is Map<String, dynamic>) {
        // ✅ Normalize Map keys thành lowercase
        final normalizedMap = _normalizeMapKeys(data as Map<String, dynamic>);
        dataset.loadFromMap(normalizedMap);
      } else if (data is List) {
        // ✅ Normalize List items keys thành lowercase
        final normalizedList = _normalizeListKeys(data as List);
        dataset.loadTable('table1', normalizedList);
      }

      return dataset;
    } catch (e) {
      return null;
    }
  }

  /// Normalize Map keys thành lowercase (cho nested Map cũng áp dụng)
  Map<String, dynamic> _normalizeMapKeys(Map<String, dynamic> map) {
    final result = <String, dynamic>{};

    for (var entry in map.entries) {
      final key = entry.key.toLowerCase();
      final value = entry.value;

      if (value is Map<String, dynamic>) {
        // ✅ Recursive normalize nested Map
        result[key] = _normalizeMapKeys(value);
      } else if (value is List) {
        // ✅ Normalize List items
        result[key] = _normalizeListKeys(value);
      } else {
        result[key] = value;
      }
    }

    return result;
  }

  /// Normalize List items keys thành lowercase
  List<Map<String, dynamic>> _normalizeListKeys(List list) {
    return list.map((item) {
      if (item is Map<String, dynamic>) {
        return _normalizeMapKeys(item);
      }
      return item as Map<String, dynamic>;
    }).toList();
  }
}

// // ============================================================================
// // EXTENSIONS
// // ============================================================================

// extension ReturnDataExtension on ReturnData {
//   CyberDataset? get dataset => toCyberDataset();
//   CyberDataTable? get firstTable => getFirstTable();
//   CyberDataTable? operator [](dynamic key) {
//     if (key is String) {
//       return getTable(key);
//     } else if (key is int) {
//       return toCyberDataset()?[key];
//     }
//     return null;
//   }
// }

// // ============================================================================
// // HELPER FUNCTIONS
// // ============================================================================

// CyberDataset getDatasetOrThrow(ReturnData response) {
//   if (!response.isValid()) {
//     throw Exception(response.message ?? 'API call failed');
//   }

//   final dataset = response.toCyberDataset();
//   if (dataset == null) {
//     throw Exception('Cannot parse data to CyberDataset');
//   }

//   return dataset;
// }

// CyberDataTable getTableOrThrow(ReturnData response, String tableName) {
//   final dataset = getDatasetOrThrow(response);
//   final table = dataset[tableName];

//   if (table == null) {
//     throw Exception('Table "$tableName" not found');
//   }

//   return table;
// }
