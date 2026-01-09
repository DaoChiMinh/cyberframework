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

  Future<bool> checkEmpty(
    BuildContext contex,
    String fieldName,
    String MsgBoxVN,
    String MsgBoxEN,
  ) async {
    if (this[fieldName] == "") {
      if (MsgBoxEN == "") MsgBoxEN = MsgBoxVN;
      await setText(
        MsgBoxVN,
        MsgBoxEN,
      ).V_MsgBox(contex, type: CyberMsgBoxType.error);

      return false;
    }

    return true;
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

  String getString(String fieldName, [String defaultValue = '']) {
    final value = this[fieldName];
    if (value == null) return defaultValue;
    return value.toString();
  }

  /// Lấy giá trị int với default value
  int getInt(String fieldName, [int defaultValue = 0]) {
    final value = this[fieldName];
    if (value == null) return defaultValue;

    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      if (value.isEmpty) return defaultValue;
      return int.tryParse(value) ?? defaultValue;
    }

    return defaultValue;
  }

  /// Lấy giá trị double/decimal với default value
  double getDouble(String fieldName, [double defaultValue = 0.0]) {
    final value = this[fieldName];
    if (value == null) return defaultValue;

    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      if (value.isEmpty) return defaultValue;
      return double.tryParse(value) ?? defaultValue;
    }

    return defaultValue;
  }

  /// Alias cho getDouble (tương tự decimal trong C#)
  double getDecimal(String fieldName, [double defaultValue = 0.0]) {
    return getDouble(fieldName, defaultValue);
  }

  /// Lấy giá trị DateTime với default value
  DateTime getDateTime(String fieldName, [DateTime? defaultValue]) {
    defaultValue ??= DateTime.now();
    final value = this[fieldName];

    if (value == null) return defaultValue;
    if (value is DateTime) return value;

    if (value is String) {
      if (value.isEmpty) return defaultValue;
      try {
        return DateTime.parse(value);
      } catch (e) {
        return defaultValue;
      }
    }

    return defaultValue;
  }

  /// Lấy giá trị bool với default value
  bool getBool(String fieldName, [bool defaultValue = false]) {
    final value = this[fieldName];

    if (value == null) return defaultValue;
    if (value is bool) return value;

    if (value is int) return value == 1;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == '1' || lower == 'true' || lower == 'yes';
    }

    return defaultValue;
  }

  /// SET methods với auto conversion

  /// Set string value
  void setString(String fieldName, String value) {
    setValue(fieldName, value);
  }

  /// Set int value
  void setInt(String fieldName, int value) {
    setValue(fieldName, value);
  }

  /// Set double/decimal value
  void setDouble(String fieldName, double value) {
    setValue(fieldName, value);
  }

  /// Set DateTime value
  void setDateTime(String fieldName, DateTime value) {
    setValue(fieldName, value);
  }

  /// Set bool value (convert to 1/0 hoặc true/false tùy config)
  void setBool(String fieldName, bool value, {bool useNumeric = false}) {
    setValue(fieldName, useNumeric ? (value ? 1 : 0) : value);
  }

  // ============================================================================
  // GENERIC GET/SET WITH TYPE INFERENCE
  // ============================================================================

  /// Generic getter với type inference
  /// Sử dụng: row.getTyped<int>('age')
  T getTyped<T>(String fieldName, [T? defaultValue]) {
    if (T == String) {
      return (getString(fieldName, defaultValue as String? ?? '') as T);
    } else if (T == int) {
      return (getInt(fieldName, defaultValue as int? ?? 0) as T);
    } else if (T == double) {
      return (getDouble(fieldName, defaultValue as double? ?? 0.0) as T);
    } else if (T == DateTime) {
      return (getDateTime(fieldName, defaultValue as DateTime?) as T);
    } else if (T == bool) {
      return (getBool(fieldName, defaultValue as bool? ?? false) as T);
    }

    // Fallback to direct access
    return (this[fieldName] ?? defaultValue) as T;
  }

  /// Generic setter với type inference
  void setTyped<T>(String fieldName, T value) {
    setValue(fieldName, value);
  }

  // ============================================================================
  // ✅ FORMAT METHODS - toString2 (giống C#)
  // ============================================================================

  /// Format giá trị của field với pattern giống C#
  ///
  /// Auto-detect kiểu dữ liệu và apply format phù hợp:
  /// - `num` (int, double) → format như số
  /// - `DateTime` → format như date
  /// - `String` → return as-is hoặc thử parse
  /// - `null` → return empty string
  ///
  /// Examples:
  /// ```dart
  /// row.toString2("Amount", "N2")      // 12,345.67
  /// row.toString2("CreatedDate", "dd/MM/yyyy")  // 09/01/2026
  /// row.toString2("Percent", "P")      // 12.34%
  /// row.toString2("so_luong", "### ### ### ##0")  // 12 345 678
  /// ```
  String toString2(String fieldName, String format) {
    try {
      final value = this[fieldName];

      // Null → empty string
      if (value == null) return '';

      // DateTime → format date
      if (value is DateTime) {
        return _formatDateTime(value, format);
      }

      // num (int, double) → format number
      if (value is num) {
        return _formatNumber(value, format);
      }

      // String → return as-is nếu không có format, hoặc thử parse
      if (value is String) {
        if (format.isEmpty) return value;

        // Thử parse thành số
        final numValue = num.tryParse(value);
        if (numValue != null) {
          return _formatNumber(numValue, format);
        }

        // Thử parse thành DateTime
        final dateValue = DateTime.tryParse(value);
        if (dateValue != null) {
          return _formatDateTime(dateValue, format);
        }

        // Không parse được → return original
        return value;
      }

      // Các kiểu khác → toString()
      return value.toString();
    } catch (e) {
      debugPrint('❌ toString2 error: $e');
      return this[fieldName]?.toString() ?? '';
    }
  }

  /// Format số theo pattern
  String _formatNumber(num value, String format) {
    try {
      if (format.isEmpty) return value.toString();

      // Extract format type và precision
      final formatUpper = format.toUpperCase();
      final formatType = formatUpper[0];
      final precision = format.length > 1
          ? int.tryParse(format.substring(1))
          : null;

      switch (formatType) {
        case 'N': // Number: 12,345.67
          return _formatNumberWithSeparator(value, precision ?? 2, ',', '.');

        case 'C': // Currency: ₫12,345.67
          final formatted = _formatNumberWithSeparator(
            value,
            precision ?? 0,
            ',',
            '.',
          );
          return '₫$formatted';

        case 'P': // Percent: 12.34%
          final percentValue = value * 100;
          final formatted = _formatNumberWithSeparator(
            percentValue,
            precision ?? 2,
            ',',
            '.',
            grouping: false,
          );
          return '$formatted%';

        case 'F': // Fixed-point: 12345.67
          return value.toStringAsFixed(precision ?? 2);

        case 'D': // Decimal with padding: 012345
          if (value is! int) return value.toString();
          final width = precision ?? 0;
          return value.toString().padLeft(width, '0');

        case 'E': // Scientific: 1.23E+04
          return value.toStringAsExponential(precision ?? 6).toUpperCase();

        case 'X': // Hexadecimal: FF
          if (value is! int) return value.toString();
          final hex = value.toRadixString(16).toUpperCase();
          final width = precision ?? 0;
          return hex.padLeft(width, '0');

        case '#': // Custom pattern: #,##0.00 hoặc ### ### ##0
          return _formatCustomPattern(value, format);

        default:
          return value.toString();
      }
    } catch (e) {
      debugPrint('❌ Format number error: $e');
      return value.toString();
    }
  }

  /// Format DateTime theo pattern
  String _formatDateTime(DateTime date, String format) {
    try {
      if (format.isEmpty) return date.toString();

      // Standard shortcuts
      switch (format) {
        case 'd':
          return _formatDatePattern(date, 'dd/MM/yyyy');
        case 't':
          return _formatDatePattern(date, 'HH:mm');
        case 'T':
          return _formatDatePattern(date, 'HH:mm:ss');
        case 'g':
          return _formatDatePattern(date, 'dd/MM/yyyy HH:mm');
        case 'G':
          return _formatDatePattern(date, 'dd/MM/yyyy HH:mm:ss');
        case 's':
          return _formatDatePattern(date, "yyyy-MM-dd'T'HH:mm:ss");
        case 'u':
          return _formatDatePattern(date.toUtc(), "yyyy-MM-dd HH:mm:ss'Z'");
        default:
          return _formatDatePattern(date, format);
      }
    } catch (e) {
      debugPrint('❌ Format DateTime error: $e');
      return date.toString();
    }
  }

  /// Helper: Format number với separator
  String _formatNumberWithSeparator(
    num value,
    int decimals,
    String groupSeparator,
    String decimalSeparator, {
    bool grouping = true,
  }) {
    final fixed = value.toStringAsFixed(decimals);
    final parts = fixed.split('.');

    if (grouping && parts[0].length > 3) {
      final intPart = parts[0];
      final buffer = StringBuffer();
      final length = intPart.length;

      for (int i = 0; i < length; i++) {
        if (i > 0 && (length - i) % 3 == 0) {
          buffer.write(groupSeparator);
        }
        buffer.write(intPart[i]);
      }

      parts[0] = buffer.toString();
    }

    return parts.join(decimalSeparator);
  }

  /// Helper: Format theo custom pattern
  String _formatCustomPattern(num value, String pattern) {
    try {
      // Detect separator type (comma, space, etc.)
      String groupSeparator = ',';
      if (pattern.contains(' ')) {
        groupSeparator = ' ';
      } else if (pattern.contains(',')) {
        groupSeparator = ',';
      }

      // Parse pattern để lấy decimal part
      final parts = pattern.split('.');
      final intPattern = parts[0];
      final decPattern = parts.length > 1 ? parts[1] : '';

      // Determine decimal places
      int decimals = 0;
      if (decPattern.isNotEmpty) {
        decimals = decPattern.replaceAll(RegExp(r'[^0#]'), '').length;
      }

      // Check if pattern has grouping
      final hasGrouping = intPattern.contains(groupSeparator);

      // Format number
      final fixed = value.toStringAsFixed(decimals);
      final numParts = fixed.split('.');

      if (hasGrouping && numParts[0].isNotEmpty) {
        final intPart = numParts[0];
        final buffer = StringBuffer();
        final length = intPart.length;

        for (int i = 0; i < length; i++) {
          if (i > 0 && (length - i) % 3 == 0) {
            buffer.write(groupSeparator);
          }
          buffer.write(intPart[i]);
        }

        numParts[0] = buffer.toString();
      }

      return numParts.join('.');
    } catch (e) {
      debugPrint('❌ Custom pattern error: $e');
      return value.toString();
    }
  }

  /// Helper: Format date pattern
  String _formatDatePattern(DateTime date, String pattern) {
    String result = pattern;

    // Year
    result = result.replaceAll('yyyy', date.year.toString());
    result = result.replaceAll(
      'yy',
      (date.year % 100).toString().padLeft(2, '0'),
    );

    // Month
    result = result.replaceAll('MM', date.month.toString().padLeft(2, '0'));
    result = result.replaceAll('M', date.month.toString());

    // Day
    result = result.replaceAll('dd', date.day.toString().padLeft(2, '0'));
    result = result.replaceAll('d', date.day.toString());

    // Hour (24h)
    result = result.replaceAll('HH', date.hour.toString().padLeft(2, '0'));
    result = result.replaceAll('H', date.hour.toString());

    // Hour (12h)
    final hour12 = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    result = result.replaceAll('hh', hour12.toString().padLeft(2, '0'));
    result = result.replaceAll('h', hour12.toString());

    // Minute
    result = result.replaceAll('mm', date.minute.toString().padLeft(2, '0'));
    result = result.replaceAll('m', date.minute.toString());

    // Second
    result = result.replaceAll('ss', date.second.toString().padLeft(2, '0'));
    result = result.replaceAll('s', date.second.toString());

    // Millisecond
    result = result.replaceAll(
      'fff',
      date.millisecond.toString().padLeft(3, '0'),
    );
    result = result.replaceAll(
      'ff',
      (date.millisecond ~/ 10).toString().padLeft(2, '0'),
    );
    result = result.replaceAll('f', (date.millisecond ~/ 100).toString());

    // AM/PM
    result = result.replaceAll('tt', date.hour >= 12 ? 'PM' : 'AM');
    result = result.replaceAll('t', date.hour >= 12 ? 'P' : 'A');

    // Remove literal quotes
    result = result.replaceAll("'", '');

    return result;
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
