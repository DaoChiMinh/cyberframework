// lib/Module/CallData/ReturnData.dart

import 'package:cyberframework/cyberframework.dart';

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

  /// ✅ Check if response is valid
  bool isValid() {
    if (status == false && message == null) return false;
    if (status == false) return false;
    return true;
  }

  /// ✅ Convert data to CyberDataset with lowercase keys
  CyberDataset? toCyberDataset() {
    if (data == null) return null;

    try {
      final dataset = CyberDataset();

      if (data is Map<String, dynamic>) {
        final normalizedMap = _normalizeMapKeys(data as Map<String, dynamic>);
        dataset.loadFromMap(normalizedMap);
      } else if (data is List) {
        final normalizedList = _normalizeListKeys(data as List);
        dataset.loadTable('table1', normalizedList);
      }
      if (noRow != null) {
        for (int i = 0; i < noRow!.length; i++) {
          if (dataset[noRow![i]] == null) continue;
          dataset[noRow![i]]!.clear();
        }
      }

      return dataset;
    } catch (e) {
      debugPrint('❌ Error converting to CyberDataset: $e');
      return null;
    }
  }

  /// Normalize Map keys to lowercase (recursive)
  Map<String, dynamic> _normalizeMapKeys(Map<String, dynamic> map) {
    final result = <String, dynamic>{};

    for (var entry in map.entries) {
      final key = entry.key.toLowerCase();
      final value = entry.value;

      if (value is Map<String, dynamic>) {
        result[key] = _normalizeMapKeys(value);
      } else if (value is List) {
        result[key] = _normalizeListKeys(value);
      } else {
        result[key] = value;
      }
    }

    return result;
  }

  /// Normalize List items keys to lowercase
  List<Map<String, dynamic>> _normalizeListKeys(List list) {
    return list.map((item) {
      if (item is Map<String, dynamic>) {
        return _normalizeMapKeys(item);
      }
      return item as Map<String, dynamic>;
    }).toList();
  }
}
