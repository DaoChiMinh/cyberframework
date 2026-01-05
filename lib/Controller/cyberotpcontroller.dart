import 'package:cyberframework/cyberframework.dart';

/// Controller quản lý STATE và BUSINESS LOGIC cho OTP
/// KHÔNG biết gì về UI, TextEditingController, FocusNode
///
/// **SỬ DỤNG:**
/// ```dart
/// // Tạo thông thường
/// final controller = CyberOTPController(length: 6);
///
/// // Tạo với binding sẵn
/// final controller = CyberOTPController.withBinding(
///   dataRow: myRow,
///   fieldName: 'otpCode',
///   length: 6,
///   isCheckEmpty: true,
/// );
/// ```
class CyberOTPController extends ChangeNotifier {
  // === PRIVATE STATE ===
  String? _value;
  bool _enabled = true;
  bool _isValid = true;
  int _length;

  // === BINDING ===
  CyberDataRow? _boundRow;
  String? _boundField;
  bool _isUpdating = false;

  // === VALIDATION ===
  bool _isCheckEmpty;

  // === PUBLIC GETTERS ===
  String? get value => _value;
  bool get enabled => _enabled;
  bool get isValid => _isValid;
  bool get isCheckEmpty => _isCheckEmpty;
  int get length => _length;

  /// Danh sách các chữ số (mỗi phần tử là 1 ký tự)
  List<String> get digits {
    if (_value == null || _value!.isEmpty) {
      return List.filled(_length, '');
    }

    final chars = _value!.split('');
    if (chars.length >= _length) {
      return chars.sublist(0, _length);
    }

    // Pad với empty string nếu chưa đủ
    return [...chars, ...List.filled(_length - chars.length, '')];
  }

  /// Check xem đã nhập đủ chưa
  bool get isComplete => _value != null && _value!.length == _length;

  CyberOTPController({
    String? initialValue,
    int length = 6,
    bool isCheckEmpty = false,
    bool enabled = true,
  }) : _value = initialValue,
       _length = length,
       _enabled = enabled,
       _isCheckEmpty = isCheckEmpty {
    _validate();
  }

  /// Factory constructor để tạo controller với binding ngay từ đầu
  factory CyberOTPController.withBinding({
    required CyberDataRow dataRow,
    required String fieldName,
    int length = 6,
    bool isCheckEmpty = false,
    bool enabled = true,
  }) {
    final controller = CyberOTPController(
      length: length,
      isCheckEmpty: isCheckEmpty,
      enabled: enabled,
    );

    controller.bind(dataRow, fieldName);
    return controller;
  }

  // === PUBLIC SETTERS ===

  /// Set giá trị OTP
  void setValue(String? value) {
    // Chỉ cho phép số
    if (value != null &&
        value.isNotEmpty &&
        !RegExp(r'^\d+$').hasMatch(value)) {
      return;
    }

    // Giới hạn độ dài
    if (value != null && value.length > _length) {
      value = value.substring(0, _length);
    }

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

  /// Set length (thay đổi số lượng ô)
  void setLength(int length) {
    if (_length == length) return;
    _length = length;

    // Trim value nếu vượt quá length mới
    if (_value != null && _value!.length > _length) {
      _value = _value!.substring(0, _length);
      _validate();
    }

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

  void bind(CyberDataRow row, String fieldName) {
    unbind();

    _boundRow = row;
    _boundField = fieldName;

    _updateFromBinding();
    _boundRow!.addListener(_onBindingChanged);
  }

  void unbind() {
    if (_boundRow != null) {
      _boundRow!.removeListener(_onBindingChanged);
      _boundRow = null;
      _boundField = null;
    }
  }

  bool get isBound => _boundRow != null && _boundField != null;

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

    // Valid nếu đã nhập đủ length
    _isValid = _value != null && _value!.length == _length;
  }

  @override
  void dispose() {
    unbind();
    super.dispose();
  }
}
