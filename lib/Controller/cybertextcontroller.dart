import 'package:cyberframework/cyberframework.dart';

/// Controller quản lý STATE và BUSINESS LOGIC
/// KHÔNG biết gì về UI, TextEditingController, FocusNode
class CyberTextController extends ChangeNotifier {
  // === PRIVATE STATE (encapsulated) ===
  String? _value;
  bool _enabled = true;
  bool _isValid = true;

  // === BINDING ===
  CyberDataRow? _boundRow;
  String? _boundField;
  bool _isUpdating = false;

  // === VALIDATION & FORMAT (private với getters) ===
  bool _isCheckEmpty;
  String? _format;
  bool _showFormatInField;

  // === PUBLIC GETTERS ONLY ===
  String? get value => _value;
  bool get enabled => _enabled;
  bool get isValid => _isValid;
  bool get isCheckEmpty => _isCheckEmpty;
  String? get format => _format;
  bool get showFormatInField => _showFormatInField;

  String? get displayValue => _getDisplayValue();
  String? get helperText => _getHelperText();

  CyberTextController({
    String? initialValue,
    bool isCheckEmpty = false,
    String? format,
    bool showFormatInField = false,
    bool enabled = true,
  }) : _value = initialValue,
       _enabled = enabled,
       _isCheckEmpty = isCheckEmpty,
       _format = format,
       _showFormatInField = showFormatInField {
    _validate();
  }

  // === PUBLIC SETTERS (controlled mutation) ===

  /// Set giá trị (raw value, không có format)
  void setValue(String? value) {
    if (_value == value) return;

    _isUpdating = true;
    _value = value;

    // Update binding nếu có
    if (_boundRow != null && _boundField != null) {
      _boundRow![_boundField!] = value;
    }

    _validate();
    _isUpdating = false;
    notifyListeners();
  }

  /// Enable/disable field
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

  /// Set format string
  void setFormat(String? format) {
    if (_format == format) return;
    _format = format;
    notifyListeners();
  }

  /// Set show format in field
  void setShowFormatInField(bool show) {
    if (_showFormatInField == show) return;
    _showFormatInField = show;
    notifyListeners();
  }

  /// Clear value
  void clear() => setValue(null);

  /// Validate giá trị hiện tại
  bool validate() {
    _validate();
    notifyListeners();
    return _isValid;
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
    final newValue = _boundRow![_boundField!]?.toString();

    if (_value != newValue) {
      _value = newValue;
      _validate();
      notifyListeners();
    }

    _isUpdating = false;
  }

  void _onBindingChanged() {
    _updateFromBinding();
  }

  void _validate() {
    if (!_isCheckEmpty) {
      _isValid = true;
      return;
    }

    _isValid = _value?.trim().isNotEmpty ?? false;
  }

  String? _getDisplayValue() {
    if (_value == null || _value!.isEmpty) return _value;

    if (_showFormatInField && _format != null) {
      return _format!.format([_value]);
    }

    return _value;
  }

  String? _getHelperText() {
    if (_showFormatInField || _format == null) return null;
    if (_value == null || _value!.isEmpty) return null;

    return _format!.format([_value]);
  }

  @override
  void dispose() {
    unbind();
    super.dispose();
  }
}
