import 'package:cyberframework/cyberframework.dart';

/// Controller cho CyberComboBox widget
///
/// Quản lý:
/// - Selected value (text value)
/// - Display value (display text)
/// - DataSource
/// - DisplayMember/ValueMember
/// - Enabled state
/// - Clear/Reset
///
/// NOTE: Binding logic được xử lý ở widget level, không cần ở controller
class CyberComboBoxController extends ChangeNotifier {
  dynamic _value;
  String _displayValue = '';
  bool _enabled = true;
  CyberDataTable? _dataSource;
  String? _displayMember;
  String? _valueMember;

  CyberComboBoxController({
    dynamic value,
    String? displayValue,
    bool enabled = true,
    CyberDataTable? dataSource,
    String? displayMember,
    String? valueMember,
  }) : _value = value,
       _displayValue = displayValue ?? '',
       _enabled = enabled,
       _dataSource = dataSource,
       _displayMember = displayMember,
       _valueMember = valueMember {
    // Listen to dataSource changes
    _dataSource?.addListener(_onDataSourceChanged);
  }

  // ============================================================================
  // GETTERS
  // ============================================================================

  /// Giá trị được chọn hiện tại (value)
  dynamic get value => _value;

  /// Display value (text hiển thị)
  String get displayValue => _displayValue;

  /// Trạng thái enabled
  bool get enabled => _enabled;

  /// DataSource
  CyberDataTable? get dataSource => _dataSource;

  /// DisplayMember field name
  String? get displayMember => _displayMember;

  /// ValueMember field name
  String? get valueMember => _valueMember;

  /// Check if has value
  bool get hasValue => _displayValue.isNotEmpty;

  /// Check if dataSource is valid and has data
  bool get hasDataSource =>
      _dataSource != null && (_dataSource?.rowCount ?? 0) > 0;

  // ============================================================================
  // SETTERS
  // ============================================================================

  /// Set giá trị được chọn (value)
  void setValue(dynamic v) {
    if (_value == v) return;
    _value = v;
    notifyListeners();
  }

  /// Set display value
  void setDisplayValue(String displayText) {
    if (_displayValue == displayText) return;
    _displayValue = displayText;
    notifyListeners();
  }

  /// Set cả value và display value cùng lúc
  void setValues({required dynamic value, required String displayValue}) {
    if (_value == value && _displayValue == displayValue) return;
    _value = value;
    _displayValue = displayValue;
    notifyListeners();
  }

  /// Set enabled state
  void setEnabled(bool enabled) {
    if (_enabled == enabled) return;
    _enabled = enabled;
    notifyListeners();
  }

  /// Set DataSource
  void setDataSource(CyberDataTable? ds) {
    if (_dataSource == ds) return;

    // Unregister old listener
    _dataSource?.removeListener(_onDataSourceChanged);

    _dataSource = ds;

    // Register new listener
    _dataSource?.addListener(_onDataSourceChanged);

    notifyListeners();
  }

  /// Set DisplayMember
  void setDisplayMember(String? member) {
    if (_displayMember == member) return;
    _displayMember = member;
    notifyListeners();
  }

  /// Set ValueMember
  void setValueMember(String? member) {
    if (_valueMember == member) return;
    _valueMember = member;
    notifyListeners();
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Clear về null
  void clear() {
    _value = null;
    _displayValue = '';
    notifyListeners();
  }

  /// Reset về giá trị ban đầu
  void reset({dynamic initialValue, String? initialDisplayValue}) {
    _value = initialValue;
    _displayValue = initialDisplayValue ?? '';
    notifyListeners();
  }

  /// Get display text cho value hiện tại từ dataSource
  /// (Tự động tìm trong dataSource nếu có)
  String? getDisplayText() {
    // Kiểm tra điều kiện cơ bản
    if (_value == null) return null;
    if (_dataSource == null) return null;
    if (_displayMember == null || _valueMember == null) return null;

    try {
      final length = _dataSource!.rowCount;

      // Kiểm tra dataSource có data không
      if (length == 0) return null;

      for (int i = 0; i < length; i++) {
        final row = _dataSource![i];

        // Kiểm tra field tồn tại trong row
        if (!row.hasField(_valueMember!)) continue;

        final rowValue = row[_valueMember!];
        if (rowValue?.toString() == _value?.toString()) {
          // Kiểm tra displayMember tồn tại
          if (!row.hasField(_displayMember!)) return null;
          return row[_displayMember!]?.toString();
        }
      }
    } catch (e) {
      // Log error nếu cần
      return null;
    }

    return null;
  }

  /// Check if value exists in dataSource
  bool isValidValue() {
    // Nếu value null thì không valid
    if (_value == null) return false;

    // Nếu không có dataSource hoặc không có data thì không valid
    if (_dataSource == null) return false;
    if (_valueMember == null) return false;

    try {
      final length = _dataSource!.rowCount;

      // Nếu dataSource rỗng thì không valid
      if (length == 0) return false;

      for (int i = 0; i < length; i++) {
        final row = _dataSource![i];

        // Kiểm tra field tồn tại trong row
        if (!row.hasField(_valueMember!)) continue;

        final rowValue = row[_valueMember!];
        if (rowValue?.toString() == _value?.toString()) {
          return true;
        }
      }
    } catch (e) {
      return false;
    }

    return false;
  }

  /// Get selected row from dataSource
  CyberDataRow? getSelectedRow() {
    if (_value == null) return null;
    if (_dataSource == null) return null;
    if (_valueMember == null) return null;

    try {
      final length = _dataSource!.rowCount;

      // Kiểm tra dataSource có data không
      if (length == 0) return null;

      for (int i = 0; i < length; i++) {
        final row = _dataSource![i];

        // Kiểm tra field tồn tại trong row
        if (!row.hasField(_valueMember!)) continue;

        final rowValue = row[_valueMember!];
        if (rowValue?.toString() == _value?.toString()) {
          return row;
        }
      }
    } catch (e) {
      return null;
    }

    return null;
  }

  /// Sync display value từ dataSource
  /// Tự động tìm display text tương ứng với value hiện tại
  void syncDisplayValueFromDataSource() {
    final displayText = getDisplayText();
    if (displayText != null && displayText != _displayValue) {
      _displayValue = displayText;
      notifyListeners();
    }
  }

  /// Validate trước khi submit/confirm
  /// Trả về error message nếu có lỗi, null nếu OK
  String? validate() {
    // Nếu không có dataSource
    if (_dataSource == null) {
      return 'DataSource chưa được thiết lập';
    }

    // Nếu dataSource rỗng
    if (_dataSource!.rowCount == 0) {
      return 'DataSource không có dữ liệu';
    }

    // Nếu thiếu displayMember hoặc valueMember
    if (_displayMember == null || _valueMember == null) {
      return 'DisplayMember hoặc ValueMember chưa được thiết lập';
    }

    // Nếu có value nhưng không hợp lệ
    if (_value != null && !isValidValue()) {
      return 'Giá trị được chọn không tồn tại trong DataSource';
    }

    return null;
  }

  /// Check if can submit (no validation errors)
  bool canSubmit() {
    return validate() == null;
  }

  // ============================================================================
  // PRIVATE METHODS
  // ============================================================================

  void _onDataSourceChanged() {
    notifyListeners();
  }

  // ============================================================================
  // DISPOSE
  // ============================================================================

  @override
  void dispose() {
    _dataSource?.removeListener(_onDataSourceChanged);
    super.dispose();
  }

  @override
  String toString() {
    return 'CyberComboBoxController('
        'value: $_value, '
        'displayValue: $_displayValue, '
        'enabled: $_enabled, '
        'displayMember: $_displayMember, '
        'valueMember: $_valueMember, '
        'dataSource: ${_dataSource?.rowCount ?? 0} rows'
        ')';
  }
}
