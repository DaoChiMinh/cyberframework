import 'package:flutter/material.dart';

/// Controller for CyberTime widget
/// Follows Flutter's TextEditingController pattern
/// ONLY manages state - NO UI logic
class CyberTimeController extends ChangeNotifier {
  TimeOfDay? _value;

  /// Current time value
  TimeOfDay? get value => _value;

  /// Set new time value and notify listeners
  set value(TimeOfDay? v) {
    if (!_sameTime(_value, v)) {
      _value = v;
      notifyListeners();
    }
  }

  /// Set value silently without notifying listeners
  void setSilently(TimeOfDay? v) {
    _value = v;
  }

  /// ✅ Compare two TimeOfDay values (hour and minute only)
  bool _sameTime(TimeOfDay? a, TimeOfDay? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.hour == b.hour && a.minute == b.minute;
  }

  /// Clear the current value
  void clear() {
    value = null;
  }

  /// Check if value is null
  bool get isEmpty => _value == null;

  /// Check if value is not null
  bool get isNotEmpty => _value != null;

  @override
  String toString() {
    if (_value == null) return 'CyberTimeController(value: null)';
    return 'CyberTimeController(value: ${_value!.hour}:${_value!.minute})';
  }
}
