// ignore: file_names

import 'package:cyberframework/cyberframework.dart';
import 'package:intl/intl.dart';

/// CyberDataRow - đại diện cho một row dữ liệu với memory leak protection
class CyberDataRow extends ChangeNotifier {
  final Map<String, dynamic> _data = {};
  final Map<String, dynamic> _originalData = {};
  final Set<String> _changedFields = {};

  // ✅ NEW: Track listeners để có thể dispose
  final Set<VoidCallback> _trackedListeners = {};
  bool _isDisposed = false;

  CyberDataRow([Map<String, dynamic>? initialData]) {
    if (initialData != null) {
      _data.addAll(initialData);
      _originalData.addAll(initialData);
    }
  }

  // ============================================================================
  // ENHANCED LISTENER MANAGEMENT
  // ============================================================================

  @override
  void addListener(VoidCallback listener) {
    if (_isDisposed) {
      return;
    }

    super.addListener(listener);
    _trackedListeners.add(listener);
  }

  @override
  // ignore: unnecessary_overrides
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
  }

  /// ✅ NEW: Dispose all tracked listeners
  void disposeAllListeners() {
    if (_trackedListeners.isEmpty) return;
    // Create copy to avoid concurrent modification
    final listenersCopy = _trackedListeners.toList();

    for (var listener in listenersCopy) {
      try {
        super.removeListener(listener);
        // ignore: empty_catches
      } catch (e) {}
    }

    _trackedListeners.clear();
  }

  /// ✅ NEW: Check if row has listeners
  @override
  bool get hasListeners => _trackedListeners.isNotEmpty;

  /// ✅ NEW: Get listener count
  int get listenerCount => _trackedListeners.length;

  // ============================================================================
  // EXISTING METHODS (UNCHANGED)
  // ============================================================================

  // ignore: non_constant_identifier_names
  void V_Call(BuildContext context) {
    if (!hasField("PageName")) return;
    String pageName = this["PageName"];
    String title = !hasField("TitlePage") ? "" : this["TitlePage"].toString();
    String cpName = !hasField("cp_name") ? "" : this["cp_name"].toString();
    String typepage = !hasField("TypePageName")
        ? ""
        : this["TypePageName"].toString();
    String strParameter = !hasField("strParameter")
        ? ""
        : this["strParameter"].toString();

    V_callform(context, pageName, title, cpName, strParameter, typepage);
  }

  dynamic operator [](String fieldName) {
    return _data[fieldName.toLowerCase()];
  }

  void operator []=(String fieldName, dynamic value) {
    setValue(fieldName.toLowerCase(), value);
  }

  T? get<T>(String fieldName) {
    return _data[fieldName.toLowerCase()] as T?;
  }

  void setValue(String fieldName, dynamic value) {
    if (_isDisposed) {
      return;
    }

    fieldName = fieldName.toLowerCase();
    final oldValue = _data[fieldName];

    if (oldValue != value) {
      _data[fieldName] = value;

      // Track changed fields
      if (_originalData[fieldName] != value) {
        _changedFields.add(fieldName);
      } else {
        _changedFields.remove(fieldName);
      }

      notifyListeners();
    }
  }

  bool hasField(String fieldName) {
    return _data.containsKey(fieldName.toLowerCase());
  }

  List<String> get fieldNames => _data.keys.toList();

  bool get isDirty => _changedFields.isNotEmpty;

  Set<String> get changedFields => Set.unmodifiable(_changedFields);

  void acceptChanges() {
    _originalData.clear();
    _originalData.addAll(_data);
    _changedFields.clear();
    notifyListeners();
  }

  void rejectChanges() {
    _data.clear();
    _data.addAll(_originalData);
    _changedFields.clear();
    notifyListeners();
  }

  dynamic getOriginal(String fieldName) {
    return _originalData[fieldName.toLowerCase()];
  }

  CyberDataRow copy() {
    return CyberDataRow(Map<String, dynamic>.from(_data));
  }

  Map<String, dynamic> toMap() {
    return Map<String, dynamic>.from(_data);
  }

  Map<String, dynamic> getChangedValues() {
    final changed = <String, dynamic>{};
    for (var field in _changedFields) {
      changed[field.toLowerCase()] = _data[field.toLowerCase()];
    }
    return changed;
  }

  String toXml(
    String tableName, {
    List<String>? includeColumns,
    List<String>? excludeColumns,
  }) {
    final StringBuffer xml = StringBuffer();
    final tableTag = tableName.toUpperCase();

    // Lấy danh sách fields cần xử lý
    List<String> fieldsToProcess = _getFieldsToProcess(
      includeColumns,
      excludeColumns,
    );

    if (fieldsToProcess.isEmpty) {
      return '';
    }

    xml.write('<$tableTag>');

    for (var fieldName in fieldsToProcess) {
      final columnTag = fieldName.toUpperCase();
      final value = this[fieldName];

      xml.write('<$columnTag>');
      xml.write(_formatValue(value));
      xml.write('</$columnTag>');
    }

    xml.write('</$tableTag>');

    return xml.toString();
  }

  /// Lấy danh sách fields cần process
  List<String> _getFieldsToProcess(
    List<String>? includeColumns,
    List<String>? excludeColumns,
  ) {
    List<String> fields = fieldNames;

    if (includeColumns != null && includeColumns.isNotEmpty) {
      // Nếu có includeColumns, chỉ lấy những columns trong list
      final includeLower = includeColumns.map((e) => e.toLowerCase()).toSet();
      fields = fields
          .where((f) => includeLower.contains(f.toLowerCase()))
          .toList();
    } else if (excludeColumns != null && excludeColumns.isNotEmpty) {
      // Nếu có excludeColumns, loại bỏ những columns trong list
      final excludeLower = excludeColumns.map((e) => e.toLowerCase()).toSet();
      fields = fields
          .where((f) => !excludeLower.contains(f.toLowerCase()))
          .toList();
    }

    return fields;
  }

  /// Format giá trị theo type (tương tự C#)
  String _formatValue(dynamic value) {
    if (value == null) {
      return '';
    }

    // DateTime
    if (value is DateTime) {
      // Format: yyyyMMdd HH:mm:ss (giống V_CyberToStringDatetimeSQL)
      return DateFormat('yyyyMMdd HH:mm:ss').format(value);
    }

    // Int
    if (value is int) {
      return value.toString();
    }

    // Double, Float
    if (value is double) {
      return value.toStringAsFixed(4).replaceAll(',', '.');
    }

    // Bool
    if (value is bool) {
      return value ? '1' : '0';
    }

    // String và các type khác => CDATA
    String strValue = value.toString().replaceAll('#', '!~!\$!~!');
    return '<![CDATA[$strValue]]>';
  }
  // ============================================================================
  // ENHANCED DISPOSE
  // ============================================================================

  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }
    // ✅ Dispose all listeners first
    disposeAllListeners();

    // Clear data
    _data.clear();
    _originalData.clear();
    _changedFields.clear();

    _isDisposed = true;

    super.dispose();
  }

  /// ✅ NEW: Check if disposed
  bool get isDisposed => _isDisposed;
  @override
  String toString() {
    return 'CyberDataRow{fields: ${_data.keys.join(", ")}, isDirty: $isDirty, listeners: $listenerCount, disposed: $_isDisposed}';
  }
}

/// Extension để format string với placeholder {0}, {1}, {2}...
extension StringFormatExtension on String {
  String format(List<dynamic> args) {
    String result = this;
    for (int i = 0; i < args.length; i++) {
      result = result.replaceAll('{$i}', args[i]?.toString() ?? '');
    }
    return result;
  }
}

/// CyberBindingExpression - đại diện cho expression drEdit['name']
class CyberBindingExpression {
  final CyberDataRow row;
  final String fieldName;

  CyberBindingExpression(this.row, this.fieldName);

  dynamic get value => row[fieldName.toLowerCase()];

  set value(dynamic newValue) {
    row[fieldName.toLowerCase()] = newValue;
  }

  @override
  String toString() => value?.toString() ?? '';
}
