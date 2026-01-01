import 'package:flutter/foundation.dart';

class CyberCheckboxController extends ChangeNotifier {
  bool _value = false;
  bool _enabled = true;

  bool get value => _value;
  bool get enabled => _enabled;

  void setValue(bool newValue) {
    if (_value == newValue) return; // Guard
    _value = newValue;
    notifyListeners();
  }

  void toggle() {
    setValue(!_value);
  }

  void setEnabled(bool newEnabled) {
    if (_enabled == newEnabled) return; // Guard
    _enabled = newEnabled;
    notifyListeners();
  }

  // Internal: set value without notify (dùng khi update từ binding)
  void setValueInternal(bool newValue) {
    _value = newValue;
  }
}
