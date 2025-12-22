import 'package:cyberframework/Module/callobject.dart';
import 'package:flutter/material.dart';

/// CyberDataRow - đại diện cho một row dữ liệu (giống ADO.NET DataRow)
class CyberDataRow extends ChangeNotifier {
  final Map<String, dynamic> _data = {};
  final Map<String, dynamic> _originalData = {};
  final Set<String> _changedFields = {};

  /// Constructor
  CyberDataRow([Map<String, dynamic>? initialData]) {
    if (initialData != null) {
      _data.addAll(initialData);
      _originalData.addAll(initialData);
    }
  }
  void V_Call(BuildContext context) {
    if (!hasField("PageName")) return;
    String pageName = this["PageName"];
    String title = !hasField("PageName") ? "" : this["TitlePage"].toString();
    String cpName = !hasField("cp_name") ? "" : this["cp_name"].toString();
    String typepage = !hasField("TypePageName")
        ? ""
        : this["TypePageName"].toString();
    String strParameter = !hasField("strParameter")
        ? ""
        : this["strParameter"].toString();

    V_callform(context, pageName, title, cpName, strParameter, typepage);
  }

  /// Indexer để get value - trả về raw value
  /// Dùng cho binding: drEdit['name']
  dynamic operator [](String fieldName) {
    return _data[fieldName.toLowerCase()];
  }

  /// Indexer để set value
  void operator []=(String fieldName, dynamic value) {
    setValue(fieldName.toLowerCase(), value);
  }

  /// Get value với type safe
  T? get<T>(String fieldName) {
    return _data[fieldName.toLowerCase()] as T?;
  }

  /// Set value
  void setValue(String fieldName, dynamic value) {
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

  /// Check field có tồn tại không
  bool hasField(String fieldName) {
    return _data.containsKey(fieldName.toLowerCase());
  }

  /// Get tất cả field names
  List<String> get fieldNames => _data.keys.toList();

  /// Check row có thay đổi không
  bool get isDirty => _changedFields.isNotEmpty;

  /// Get các field đã thay đổi
  Set<String> get changedFields => Set.unmodifiable(_changedFields);

  /// Accept changes (commit)
  void acceptChanges() {
    _originalData.clear();
    _originalData.addAll(_data);
    _changedFields.clear();
    notifyListeners();
  }

  /// Reject changes (revert)
  void rejectChanges() {
    _data.clear();
    _data.addAll(_originalData);
    _changedFields.clear();
    notifyListeners();
  }

  /// Get original value
  dynamic getOriginal(String fieldName) {
    return _originalData[fieldName.toLowerCase()];
  }

  /// Copy row
  CyberDataRow copy() {
    return CyberDataRow(Map<String, dynamic>.from(_data));
  }

  /// To Map
  Map<String, dynamic> toMap() {
    return Map<String, dynamic>.from(_data);
  }

  /// Get changed values only
  Map<String, dynamic> getChangedValues() {
    final changed = <String, dynamic>{};
    for (var field in _changedFields) {
      changed[field.toLowerCase()] = _data[field.toLowerCase()];
    }
    return changed;
  }

  @override
  String toString() {
    return 'CyberDataRow{fields: ${_data.keys.join(", ")}, isDirty: $isDirty}';
  }
}

/// Extension để format string với placeholder {0}, {1}, {2}...
extension StringFormatExtension on String {
  /// Format string với các placeholder {0}, {1}, {2}...
  /// Example: "Hello {0}, you are {1} years old".format(["John", 25])
  String format(List<dynamic> args) {
    String result = this;
    for (int i = 0; i < args.length; i++) {
      result = result.replaceAll('{$i}', args[i]?.toString() ?? '');
    }
    return result;
  }
}

/// CyberBindingExpression - đại diện cho expression drEdit['name']
/// Đây là wrapper để biết rằng value này đến từ binding
class CyberBindingExpression {
  final CyberDataRow row;
  final String fieldName;

  CyberBindingExpression(this.row, this.fieldName);

  /// Get value
  dynamic get value => row[fieldName.toLowerCase()];

  /// Set value
  set value(dynamic newValue) {
    row[fieldName.toLowerCase()] = newValue;
  }

  @override
  String toString() => value?.toString() ?? '';
}
