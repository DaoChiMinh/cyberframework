import 'package:cyberframework/Module/callobject.dart';
import 'package:flutter/material.dart';

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
      } catch (e) {}
    }

    _trackedListeners.clear();
  }

  /// ✅ NEW: Check if row has listeners
  bool get hasListeners => _trackedListeners.isNotEmpty;

  /// ✅ NEW: Get listener count
  int get listenerCount => _trackedListeners.length;

  // ============================================================================
  // EXISTING METHODS (UNCHANGED)
  // ============================================================================

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
