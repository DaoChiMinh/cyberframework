import 'package:cyberframework/cyberframework.dart';

/// Controller cho CyberComboBox widget
///
/// Quản lý:
/// - Selected value
/// - DataSource
/// - DisplayMember/ValueMember
/// - Enabled state
/// - Clear/Reset
/// - Binding to CyberDataRow
class CyberComboBoxController extends ChangeNotifier {
  dynamic _value;
  bool _enabled = true;
  CyberDataTable? _dataSource;
  String? _displayMember;
  String? _valueMember;

  // === BINDING ===
  CyberDataRow? _boundRow;
  String? _boundField;
  bool _isUpdating = false;

  CyberComboBoxController({
    dynamic value,
    bool enabled = true,
    CyberDataTable? dataSource,
    String? displayMember,
    String? valueMember,
  }) : _value = value,
       _enabled = enabled,
       _dataSource = dataSource,
       _displayMember = displayMember,
       _valueMember = valueMember {
    // Listen to dataSource changes
    _dataSource?.addListener(_onDataSourceChanged);
  }

  /// Giá trị được chọn hiện tại
  dynamic get value => _value;

  /// Trạng thái enabled
  bool get enabled => _enabled;

  /// DataSource
  CyberDataTable? get dataSource => _dataSource;

  /// DisplayMember field name
  String? get displayMember => _displayMember;

  /// ValueMember field name
  String? get valueMember => _valueMember;

  /// Set giá trị được chọn
  void setValue(dynamic v) {
    if (_value == v) return;

    _isUpdating = true;
    _value = v;

    // Update binding nếu có
    if (_boundRow != null && _boundField != null) {
      _boundRow![_boundField!] = v;
    }

    _isUpdating = false;
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

  /// Clear về null
  void clear() => setValue(null);

  /// Reset về giá trị ban đầu
  void reset(dynamic initialValue) => setValue(initialValue);

  /// Get display text cho value hiện tại
  String? getDisplayText() {
    if (_value == null || _dataSource == null) return null;
    if (_displayMember == null || _valueMember == null) return null;

    try {
      final length = _dataSource!.rowCount;
      for (int i = 0; i < length; i++) {
        final row = _dataSource![i];
        final rowValue = row[_valueMember!];
        if (rowValue?.toString() == _value?.toString()) {
          return row[_displayMember!]?.toString();
        }
      }
    } catch (e) {
      return null;
    }

    return null;
  }

  /// Check if value exists in dataSource
  bool isValidValue() {
    if (_value == null || _dataSource == null) return false;
    if (_valueMember == null) return false;

    try {
      final length = _dataSource!.rowCount;
      for (int i = 0; i < length; i++) {
        final row = _dataSource![i];
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

  // === BINDING ===

  /// Bind to CyberDataRow field
  void bind(CyberDataRow row, String fieldName) {
    unbind();

    _boundRow = row;
    _boundField = fieldName;

    // Đọc giá trị ban đầu
    _updateFromBinding();

    // Lắng nghe thay đổi
    _boundRow!.addListener(_onBindingChanged);
  }

  /// Unbind khỏi CyberDataRow
  void unbind() {
    if (_boundRow != null) {
      _boundRow!.removeListener(_onBindingChanged);
      _boundRow = null;
      _boundField = null;
    }
  }

  // === PRIVATE METHODS ===

  void _updateFromBinding() {
    if (_isUpdating || _boundRow == null || _boundField == null) return;

    _isUpdating = true;
    final newValue = _boundRow![_boundField!];

    if (_value != newValue) {
      _value = newValue;
      notifyListeners();
    }

    _isUpdating = false;
  }

  void _onBindingChanged() {
    _updateFromBinding();
  }

  void _onDataSourceChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _dataSource?.removeListener(_onDataSourceChanged);
    unbind();
    super.dispose();
  }
}