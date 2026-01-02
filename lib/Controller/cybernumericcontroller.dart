import 'package:flutter/foundation.dart';

/// Controller cho CyberNumeric widget
///
/// Quản lý:
/// - Value (num?)
/// - Enabled state
/// - Min/Max validation
/// - Clear/Reset
class CyberNumericController extends ChangeNotifier {
  num? _value;
  bool _enabled = true;
  num? _min;
  num? _max;

  CyberNumericController({num? value, bool enabled = true, num? min, num? max})
    : _value = value,
      _enabled = enabled,
      _min = min,
      _max = max;

  /// Giá trị hiện tại
  num? get value => _value;

  /// Trạng thái enabled
  bool get enabled => _enabled;

  /// Giá trị min
  num? get min => _min;

  /// Giá trị max
  num? get max => _max;

  /// Set giá trị mới (có validation)
  void setValue(num? v) {
    if (v == _value) return;
    _value = _validateValue(v);
    notifyListeners();
  }

  /// Set enabled state
  void setEnabled(bool enabled) {
    if (_enabled == enabled) return;
    _enabled = enabled;
    notifyListeners();
  }

  /// Set min/max
  void setMinMax({num? min, num? max}) {
    bool changed = false;
    if (min != _min) {
      _min = min;
      changed = true;
    }
    if (max != _max) {
      _max = max;
      changed = true;
    }
    if (changed) {
      _value = _validateValue(_value);
      notifyListeners();
    }
  }

  /// Clear về null
  void clear() => setValue(null);

  /// Reset về giá trị ban đầu
  void reset(num? initialValue) => setValue(initialValue);

  /// Validate value theo min/max
  num? _validateValue(num? value) {
    if (value == null) return null;

    if (_min != null && value < _min!) {
      return _min;
    }
    if (_max != null && value > _max!) {
      return _max;
    }
    return value;
  }

}
