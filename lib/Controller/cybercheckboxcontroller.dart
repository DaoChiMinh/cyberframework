import 'package:cyberframework/cyberframework.dart';

/// CyberCheckboxController - OPTIONAL controller cho advanced use cases
/// 
/// NOTE: Trong hầu hết trường hợp, KHÔNG CẦN dùng controller này.
/// CyberCheckbox đã có internal controller và hỗ trợ binding trực tiếp.
/// 
/// Chỉ dùng controller này khi:
/// - Cần programmatic control phức tạp
/// - Cần validation logic đặc biệt
/// - Cần share state giữa nhiều widgets
/// 
/// Example with binding (RECOMMENDED - không cần controller):
/// ```dart
/// CyberCheckbox(
///   text: drEdit.bind('is_active'),
///   label: 'Kích hoạt',
/// )
/// ```
/// 
/// Example with controller (ADVANCED):
/// ```dart
/// final controller = CyberCheckboxController(initialValue: true);
/// 
/// // Programmatic control
/// controller.setValue(false);
/// controller.toggle();
/// 
/// // Bind to CyberDataRow
/// controller.bind(drEdit, 'is_active');
/// ```
class CyberCheckboxController extends ChangeNotifier {
  // === PRIVATE STATE ===
  bool _value = false;
  bool _enabled = true;

  // === BINDING ===
  CyberDataRow? _boundRow;
  String? _boundField;
  bool _isUpdating = false;

  // === PUBLIC GETTERS ===
  bool get value => _value;
  bool get enabled => _enabled;

  CyberCheckboxController({
    bool initialValue = false,
    bool enabled = true,
  }) : _value = initialValue,
       _enabled = enabled;

  // === PUBLIC SETTERS ===

  /// Set value
  void setValue(bool newValue) {
    if (_value == newValue) return;

    _isUpdating = true;
    _value = newValue;

    // Update binding nếu có
    if (_boundRow != null && _boundField != null) {
      _updateBindingValue(newValue);
    }

    _isUpdating = false;
    notifyListeners();
  }

  /// Toggle value
  void toggle() {
    setValue(!_value);
  }

  /// Set enabled state
  void setEnabled(bool newEnabled) {
    if (_enabled == newEnabled) return;
    _enabled = newEnabled;
    notifyListeners();
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

  /// Unbind
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
    final newValue = _parseBool(_boundRow![_boundField!]);

    if (_value != newValue) {
      _value = newValue;
      notifyListeners();
    }

    _isUpdating = false;
  }

  void _updateBindingValue(bool newValue) {
    if (_boundRow == null || _boundField == null) return;

    final originalValue = _boundRow![_boundField!];

    // Preserve original type
    if (originalValue is String) {
      _boundRow![_boundField!] = newValue ? "1" : "0";
    } else if (originalValue is int) {
      _boundRow![_boundField!] = newValue ? 1 : 0;
    } else {
      _boundRow![_boundField!] = newValue;
    }
  }

  void _onBindingChanged() {
    _updateFromBinding();
  }

  bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final trimmed = value.trim().toLowerCase();
      if (trimmed == "1" || trimmed == "true") return true;
      if (trimmed == "0" || trimmed == "false") return false;
      return false;
    }
    return false;
  }

  // === INTERNAL METHOD (used by widget when no controller) ===
  
  /// Internal: set value without notify (dùng khi update từ binding)
  void setValueInternal(bool newValue) {
    _value = newValue;
  }

  @override
  void dispose() {
    unbind();
    super.dispose();
  }
}