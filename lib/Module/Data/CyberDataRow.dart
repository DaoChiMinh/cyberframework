// ignore: file_names

import 'package:cyberframework/cyberframework.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

/// CyberDataRow - đại diện cho một row dữ liệu với memory leak protection
class CyberDataRow extends ChangeNotifier implements ICyberIdentifiable {
  final Map<String, dynamic> _data = {};
  final Map<String, dynamic> _originalData = {};
  final Set<String> _changedFields = {};

  // Field name caching
  final Map<String, String> _fieldNameCache = {};

  // Track listeners
  final Set<VoidCallback> _trackedListeners = {};
  bool _isDisposed = false;

  // Batch mode
  bool _isBatchMode = false;

  // ============================================================================
  // ✅ UUID-BASED IDENTITY WITH LOCK PROTECTION
  // ============================================================================

  /// Shared UUID generator instance (singleton pattern)
  static final _uuid = Uuid();

  /// Internal unique identity - UUID v4
  /// Format: "550e8400-e29b-41d4-a716-446655440000"
  /// - 128-bit random UUID
  /// - RFC 4122 compliant
  /// - Collision probability: ~1 in 10^38
  late final String _internalId = _uuid.v4();

  /// Optional: User-defined identity key (overrides internal)
  Object? _customIdentityKey;

  /// ✅ IMPROVED: Identity lock flag
  /// Locks identity ONLY when used in critical operations (e.g., widget keys)
  /// Does NOT lock on simple reads/debugging
  bool _identityLocked = false;

  CyberDataRow([Map<String, dynamic>? initialData]) {
    if (initialData != null) {
      _data.addAll(initialData);
      _originalData.addAll(initialData);
    }
  }

  // ============================================================================
  // ✅ IDENTITY CONTRACT IMPLEMENTATION
  // ============================================================================

  /// Get the identity key for this row
  /// Returns stable, unique UUID suitable for widget keys, caching, comparison
  ///
  /// NOTE: This getter does NOT lock identity. Use lockIdentity() explicitly
  /// when binding to UI to prevent accidental identity changes.
  @override
  Object get identityKey {
    return _customIdentityKey ?? _internalId;
  }

  /// ✅ NEW: Explicitly lock identity
  /// Call this before binding row to UI (e.g., in ListView itemBuilder)
  /// After locking, setIdentityKey() will throw error
  void lockIdentity() {
    _identityLocked = true;
  }

  /// ✅ Check if identity is locked
  bool get isIdentityLocked => _identityLocked;

  /// Set custom identity key (advanced usage)
  /// Use when you want to override internal UUID with data-based key
  ///
  /// Example: row.setIdentityKey('CUSTOMER_${row["id"]}')
  ///
  /// Throws StateError if identity is already locked (used in UI)
  void setIdentityKey(Object key) {
    if (_identityLocked) {
      throw StateError(
        'Cannot change identity key: Already locked (used in UI). '
        'Identity must be set before lockIdentity() or UI binding.',
      );
    }
    _customIdentityKey = key;
  }

  /// Clear custom identity (revert to internal UUID)
  /// Throws StateError if identity is locked
  void clearCustomIdentity() {
    if (_identityLocked) {
      throw StateError(
        'Cannot clear identity key: Already locked (used in UI).',
      );
    }
    _customIdentityKey = null;
  }

  /// Check if using custom identity
  bool get hasCustomIdentity => _customIdentityKey != null;

  /// Get internal UUID (even if custom identity is set)
  String get internalId => _internalId;

  // ============================================================================
  // OPTIMIZED: Field Name Caching
  // ============================================================================

  String _getCachedFieldName(String fieldName) {
    var cached = _fieldNameCache[fieldName];
    if (cached != null) return cached;

    final lowerKey = fieldName.toLowerCase();

    _fieldNameCache[fieldName] = lowerKey;
    if (fieldName != lowerKey) {
      _fieldNameCache[lowerKey] = lowerKey;
    }

    return lowerKey;
  }

  /// Batch mode operations
  void beginBatch() {
    _isBatchMode = true;
  }

  void endBatch() {
    _isBatchMode = false;
    if (hasListeners) {
      notifyListeners();
    }
  }

  void batch(void Function() action) {
    beginBatch();
    try {
      action();
    } finally {
      endBatch();
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
    _trackedListeners.remove(listener);
  }

  void disposeAllListeners() {
    if (_trackedListeners.isEmpty) return;

    final listenersCopy = _trackedListeners.toList();

    for (var listener in listenersCopy) {
      try {
        super.removeListener(listener);
      } catch (e) {
        // Ignore errors during cleanup
      }
    }

    _trackedListeners.clear();
  }

  @override
  bool get hasListeners => _trackedListeners.isNotEmpty;

  int get listenerCount => _trackedListeners.length;

  // ============================================================================
  // OPTIMIZED: Data Access Methods
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
    return _data[_getCachedFieldName(fieldName)];
  }

  void operator []=(String fieldName, dynamic value) {
    setValue(_getCachedFieldName(fieldName), value);
  }

  T? get<T>(String fieldName) {
    return _data[_getCachedFieldName(fieldName)] as T?;
  }

  void setValue(String fieldName, dynamic value) {
    if (_isDisposed) {
      return;
    }

    fieldName = _getCachedFieldName(fieldName);
    final oldValue = _data[fieldName];

    if (oldValue != value) {
      _data[fieldName] = value;

      // Track changed fields
      if (_originalData[fieldName] != value) {
        _changedFields.add(fieldName);
      } else {
        _changedFields.remove(fieldName);
      }

      // Smart notification
      if (!_isBatchMode && hasListeners) {
        notifyListeners();
      }
    }
  }

  bool hasField(String fieldName) {
    return _data.containsKey(_getCachedFieldName(fieldName));
  }

  List<String> get fieldNames => _data.keys.toList();

  bool get isDirty => _changedFields.isNotEmpty;

  Set<String> get changedFields => Set.unmodifiable(_changedFields);

  void acceptChanges() {
    _originalData.clear();
    _originalData.addAll(_data);
    _changedFields.clear();

    if (hasListeners) {
      notifyListeners();
    }
  }

  void rejectChanges() {
    _data.clear();
    _data.addAll(_originalData);
    _changedFields.clear();

    if (hasListeners) {
      notifyListeners();
    }
  }

  dynamic getOriginal(String fieldName) {
    return _originalData[_getCachedFieldName(fieldName)];
  }

  /// Copy creates new entity with new UUID
  CyberDataRow copy() {
    final newRow = CyberDataRow(Map<String, dynamic>.from(_data));
    // ✅ NEW ROW gets NEW UUID (different entity)
    return newRow;
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

  List<String> _getFieldsToProcess(
    List<String>? includeColumns,
    List<String>? excludeColumns,
  ) {
    List<String> fields = fieldNames;

    if (includeColumns != null && includeColumns.isNotEmpty) {
      final includeLower = includeColumns.map((e) => e.toLowerCase()).toSet();
      fields = fields
          .where((f) => includeLower.contains(f.toLowerCase()))
          .toList();
    } else if (excludeColumns != null && excludeColumns.isNotEmpty) {
      final excludeLower = excludeColumns.map((e) => e.toLowerCase()).toSet();
      fields = fields
          .where((f) => !excludeLower.contains(f.toLowerCase()))
          .toList();
    }

    return fields;
  }

  String _formatValue(dynamic value) {
    if (value == null) {
      return '';
    }

    if (value is DateTime) {
      return DateFormat('yyyyMMdd HH:mm:ss').format(value);
    }

    if (value is int) {
      return value.toString();
    }

    if (value is double) {
      return value.toStringAsFixed(4).replaceAll(',', '.');
    }

    if (value is bool) {
      return value ? '1' : '0';
    }

    String strValue = value.toString().replaceAll('#', '!~!\$!~!');
    return '<![CDATA[$strValue]]>';
  }

  // ============================================================================
  // ENHANCED: Equality based on identity
  // ============================================================================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CyberDataRow) return false;
    return identityKey == other.identityKey;
  }

  @override
  int get hashCode => identityKey.hashCode;

  // ============================================================================
  // ENHANCED DISPOSE
  // ============================================================================

  @override
  void dispose() {
    if (_isDisposed) {
      return;
    }

    disposeAllListeners();

    _data.clear();
    _originalData.clear();
    _changedFields.clear();
    _fieldNameCache.clear();
    _customIdentityKey = null;

    _isDisposed = true;

    super.dispose();
  }

  bool get isDisposed => _isDisposed;

  @override
  String toString() {
    return 'CyberDataRow{id: $identityKey, fields: ${_data.keys.join(", ")}, isDirty: $isDirty, listeners: $listenerCount, locked: $_identityLocked, disposed: $_isDisposed}';
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

abstract class ICyberIdentifiable {
  /// Returns a stable, unique identity key for this object
  /// - MUST be stable (same value across object's lifetime)
  /// - MUST be unique (different objects have different keys)
  /// - SHOULD be efficient to compute
  Object get identityKey;
}
