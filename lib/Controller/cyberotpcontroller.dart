import 'package:cyberframework/cyberframework.dart';

/// Controller quản lý STATE và BUSINESS LOGIC cho OTP
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

  // ✅ CALLBACK: onCompleted từ Controller
  ValueChanged<String>? _onCompleted;

  // === PUBLIC GETTERS ===
  String? get value => _value;
  bool get enabled => _enabled;
  bool get isValid => _isValid;
  bool get isCheckEmpty => _isCheckEmpty;
  int get length => _length;

  List<String> get digits {
    if (_value == null || _value!.isEmpty) {
      return List.filled(_length, '');
    }

    final chars = _value!.split('');
    if (chars.length >= _length) {
      return chars.sublist(0, _length);
    }

    return [...chars, ...List.filled(_length - chars.length, '')];
  }

  bool get isComplete => _value != null && _value!.length == _length;

  CyberOTPController({
    String? initialValue,
    int length = 6,
    bool isCheckEmpty = false,
    bool enabled = true,
    ValueChanged<String>? onCompleted,
  }) : _value = initialValue,
       _length = length,
       _enabled = enabled,
       _isCheckEmpty = isCheckEmpty,
       _onCompleted = onCompleted {
    _validate();
  }

  factory CyberOTPController.withBinding({
    required CyberDataRow dataRow,
    required String fieldName,
    int length = 6,
    bool isCheckEmpty = false,
    bool enabled = true,
    ValueChanged<String>? onCompleted,
  }) {
    final controller = CyberOTPController(
      length: length,
      isCheckEmpty: isCheckEmpty,
      enabled: enabled,
      onCompleted: onCompleted,
    );

    controller.bind(dataRow, fieldName);
    return controller;
  }

  // === PUBLIC SETTERS ===

  /// Set giá trị OTP
  void setValue(String? value) {
    if (value != null &&
        value.isNotEmpty &&
        !RegExp(r'^\d+$').hasMatch(value)) {
      return;
    }

    if (value != null && value.length > _length) {
      value = value.substring(0, _length);
    }

    if (_value == value) return;

    _isUpdating = true;
    _value = value;

    if (_boundRow != null && _boundField != null) {
      _boundRow![_boundField!] = value;
    }

    _validate();

    // ✅ TRIGGER onCompleted từ Controller (không phải Widget)
    if (isComplete && _onCompleted != null) {
      _onCompleted!(_value!);
    }

    _isUpdating = false;
    notifyListeners();
  }

  /// ✅ Set onCompleted callback
  void setOnCompleted(ValueChanged<String>? onCompleted) {
    _onCompleted = onCompleted;
  }

  void setEnabled(bool enabled) {
    if (_enabled == enabled) return;
    _enabled = enabled;
    notifyListeners();
  }

  void setCheckEmpty(bool checkEmpty) {
    if (_isCheckEmpty == checkEmpty) return;
    _isCheckEmpty = checkEmpty;
    _validate();
    notifyListeners();
  }

  void setLength(int length) {
    if (_length == length) return;
    _length = length;

    if (_value != null && _value!.length > _length) {
      _value = _value!.substring(0, _length);
      _validate();
    }

    notifyListeners();
  }

  void clear() => setValue(null);

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

    _isValid = _value != null && _value!.length == _length;
  }

  @override
  void dispose() {
    unbind();
    super.dispose();
  }
}
