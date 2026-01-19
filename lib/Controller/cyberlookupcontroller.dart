import 'package:cyberframework/cyberframework.dart';

/// CyberLookupController - OPTIONAL controller cho advanced use cases
///
/// NOTE: Trong hầu hết trường hợp, KHÔNG CẦN dùng controller này.
/// CyberLookup đã có internal controller và hỗ trợ binding trực tiếp.
///
/// Chỉ dùng controller này khi:
/// - Cần programmatic control phức tạp
/// - Cần validation logic phức tạp
/// - Cần share state giữa nhiều widgets
///
/// Example with binding (RECOMMENDED - không cần controller):
/// ```dart
/// CyberLookup(
///   text: drEdit.bind('ma_kh'),
///   display: drEdit.bind('ten_kh'),
///   tbName: 'dmkh',
///   displayField: 'ten_kh',
///   displayValue: 'ma_kh',
/// )
/// ```
///
/// Example with custom data source:
/// ```dart
/// CyberLookup(
///   text: drEdit.bind('ma_sp'),
///   display: drEdit.bind('ten_sp'),
///   cp_nameCus: 'GET_SanPham',
///   parameterCus: 'param1#param2',
///   displayField: 'ten_sp',
///   displayValue: 'ma_sp',
/// )
/// ```
///
/// Example with controller (ADVANCED):
/// ```dart
/// final controller = CyberLookupController(
///   initialTextValue: 'KH001',
///   initialDisplayValue: 'Khách hàng A',
/// );
///
/// // Programmatic control
/// controller.setValues(textValue: 'KH002', displayValue: 'Khách hàng B');
/// controller.clear();
///
/// // Bind to CyberDataRow
/// controller.bindText(drEdit, 'ma_kh');
/// controller.bindDisplay(drEdit, 'ten_kh');
/// ```
class CyberLookupController extends ChangeNotifier {
  // === PRIVATE STATE ===
  dynamic _textValue;
  String _displayValue = '';
  bool _enabled = true;
  bool _isValid = true;

  // === BINDING ===
  CyberDataRow? _boundTextRow;
  String? _boundTextField;
  CyberDataRow? _boundDisplayRow;
  String? _boundDisplayField;
  bool _isUpdating = false;

  // === VALIDATION ===
  bool _isCheckEmpty;

  // === LOOKUP PARAMETERS ===
  String? _tbName;
  String? _strFilter;
  String? _displayFieldName;
  String? _valueFieldName;
  int _lookupPageSize;

  // === CUSTOM DATA SOURCE ===
  String? _cp_nameCus;
  String? _parameterCus;

  // === PUBLIC GETTERS ===
  dynamic get textValue => _textValue;
  String get displayValue => _displayValue;
  bool get enabled => _enabled;
  bool get isValid => _isValid;
  bool get isCheckEmpty => _isCheckEmpty;
  bool get hasValue => _displayValue.isNotEmpty;

  // Lookup parameters getters
  String? get tbName => _tbName;
  String? get strFilter => _strFilter;
  String? get displayFieldName => _displayFieldName;
  String? get valueFieldName => _valueFieldName;
  int get lookupPageSize => _lookupPageSize;

  // Custom data source getters
  String? get cp_nameCus => _cp_nameCus;
  String? get parameterCus => _parameterCus;

  CyberLookupController({
    dynamic initialTextValue,
    String? initialDisplayValue,
    bool isCheckEmpty = false,
    bool enabled = true,
    String? tbName,
    String? strFilter,
    String? displayFieldName,
    String? valueFieldName,
    int lookupPageSize = 50,
    String? cp_nameCus,
    String? parameterCus,
  }) : _textValue = initialTextValue,
       _displayValue = initialDisplayValue ?? '',
       _enabled = enabled,
       _isCheckEmpty = isCheckEmpty,
       _tbName = tbName,
       _strFilter = strFilter,
       _displayFieldName = displayFieldName,
       _valueFieldName = valueFieldName,
       _lookupPageSize = lookupPageSize,
       _cp_nameCus = cp_nameCus,
       _parameterCus = parameterCus {
    _validate();
  }

  // === PUBLIC SETTERS ===

  /// Set cả text value và display value
  void setValues({required dynamic textValue, required String displayValue}) {
    if (_textValue == textValue && _displayValue == displayValue) return;

    _isUpdating = true;
    _textValue = textValue;
    _displayValue = displayValue;

    // Update bindings nếu có
    if (_boundTextRow != null && _boundTextField != null) {
      _boundTextRow![_boundTextField!] = textValue;
    }
    if (_boundDisplayRow != null && _boundDisplayField != null) {
      _boundDisplayRow![_boundDisplayField!] = displayValue;
    }

    _validate();
    _isUpdating = false;
    notifyListeners();
  }

  /// Clear values
  void clear() {
    setValues(textValue: null, displayValue: '');
  }

  /// Enable/disable
  void setEnabled(bool enabled) {
    if (_enabled == enabled) return;
    _enabled = enabled;
    notifyListeners();
  }

  /// Set validation rule
  void setCheckEmpty(bool checkEmpty) {
    if (_isCheckEmpty == checkEmpty) return;
    _isCheckEmpty = checkEmpty;
    _validate();
    notifyListeners();
  }

  /// Set lookup parameters
  void setLookupParams({
    String? tbName,
    String? strFilter,
    String? displayFieldName,
    String? valueFieldName,
    int? lookupPageSize,
    String? cp_nameCus,
    String? parameterCus,
  }) {
    bool changed = false;

    if (tbName != null && _tbName != tbName) {
      _tbName = tbName;
      changed = true;
    }
    if (strFilter != null && _strFilter != strFilter) {
      _strFilter = strFilter;
      changed = true;
    }
    if (displayFieldName != null && _displayFieldName != displayFieldName) {
      _displayFieldName = displayFieldName;
      changed = true;
    }
    if (valueFieldName != null && _valueFieldName != valueFieldName) {
      _valueFieldName = valueFieldName;
      changed = true;
    }
    if (lookupPageSize != null && _lookupPageSize != lookupPageSize) {
      _lookupPageSize = lookupPageSize;
      changed = true;
    }
    if (cp_nameCus != null && _cp_nameCus != cp_nameCus) {
      _cp_nameCus = cp_nameCus;
      changed = true;
    }
    if (parameterCus != null && _parameterCus != parameterCus) {
      _parameterCus = parameterCus;
      changed = true;
    }

    if (changed) {
      notifyListeners();
    }
  }

  /// Validate giá trị hiện tại
  bool validate() {
    _validate();
    notifyListeners();
    return _isValid;
  }

  // === BINDING ===

  /// Bind text value to CyberDataRow field
  void bindText(CyberDataRow row, String fieldName) {
    unbindText();

    _boundTextRow = row;
    _boundTextField = fieldName;

    // Đọc giá trị ban đầu
    _updateFromTextBinding();

    // Lắng nghe thay đổi
    _boundTextRow!.addListener(_onTextBindingChanged);
  }

  /// Bind display value to CyberDataRow field
  void bindDisplay(CyberDataRow row, String fieldName) {
    unbindDisplay();

    _boundDisplayRow = row;
    _boundDisplayField = fieldName;

    // Đọc giá trị ban đầu
    _updateFromDisplayBinding();

    // Lắng nghe thay đổi
    _boundDisplayRow!.addListener(_onDisplayBindingChanged);
  }

  /// Unbind text value
  void unbindText() {
    if (_boundTextRow != null) {
      _boundTextRow!.removeListener(_onTextBindingChanged);
      _boundTextRow = null;
      _boundTextField = null;
    }
  }

  /// Unbind display value
  void unbindDisplay() {
    if (_boundDisplayRow != null) {
      _boundDisplayRow!.removeListener(_onDisplayBindingChanged);
      _boundDisplayRow = null;
      _boundDisplayField = null;
    }
  }

  // === PRIVATE METHODS ===

  void _updateFromTextBinding() {
    if (_isUpdating || _boundTextRow == null || _boundTextField == null) return;

    _isUpdating = true;
    final newValue = _boundTextRow![_boundTextField!];

    if (_textValue != newValue) {
      _textValue = newValue;
      _validate();
      notifyListeners();
    }

    _isUpdating = false;
  }

  void _updateFromDisplayBinding() {
    if (_isUpdating || _boundDisplayRow == null || _boundDisplayField == null) {
      return;
    }

    _isUpdating = true;
    final newValue = _boundDisplayRow![_boundDisplayField!]?.toString() ?? '';

    if (_displayValue != newValue) {
      _displayValue = newValue;
      _validate();
      notifyListeners();
    }

    _isUpdating = false;
  }

  void _onTextBindingChanged() {
    _updateFromTextBinding();
  }

  void _onDisplayBindingChanged() {
    _updateFromDisplayBinding();
  }

  void _validate() {
    if (!_isCheckEmpty) {
      _isValid = true;
      return;
    }

    _isValid = _displayValue.trim().isNotEmpty;
  }

  @override
  void dispose() {
    unbindText();
    unbindDisplay();
    super.dispose();
  }
}
