import 'package:flutter/foundation.dart';

/// Controller for CyberDate widget
/// Similar to TextEditingController but for DateTime values
class CyberDateController extends ChangeNotifier {
  DateTime? _value;

  /// Current date value
  DateTime? get value => _value;

  /// Set new date value and notify listeners
  set value(DateTime? v) {
    if (!_isSame(_value, v)) {
      _value = v;
      notifyListeners();
    }
  }

  /// Set value silently without notifying listeners
  /// Use this when loading data from backend to avoid triggering validation
  void setSilently(DateTime? v) {
    _value = v;
  }

  /// Compare two DateTime values by date only (ignore time)
  bool _isSame(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Clear the current value
  void clear() {
    value = null;
  }

  /// Set value to today
  void setToday() {
    final now = DateTime.now();
    value = DateTime(now.year, now.month, now.day);
  }

  /// Set value to start of current month
  void setStartOfMonth() {
    final now = DateTime.now();
    value = DateTime(now.year, now.month, 1);
  }

  /// Set value to end of current month
  void setEndOfMonth() {
    final now = DateTime.now();
    value = DateTime(now.year, now.month + 1, 0);
  }

  /// Set value to start of current year
  void setStartOfYear() {
    final now = DateTime.now();
    value = DateTime(now.year, 1, 1);
  }

  /// Set value to end of current year
  void setEndOfYear() {
    final now = DateTime.now();
    value = DateTime(now.year, 12, 31);
  }

  /// Set specific date (time will be set to 00:00:00)
  void setDate(int year, int month, int day) {
    value = DateTime(year, month, day);
  }

  /// Add days to current value
  void addDays(int days) {
    if (_value != null) {
      value = _value!.add(Duration(days: days));
    }
  }

  /// Subtract days from current value
  void subtractDays(int days) {
    if (_value != null) {
      value = _value!.subtract(Duration(days: days));
    }
  }

  /// Add months to current value
  void addMonths(int months) {
    if (_value != null) {
      final newMonth = _value!.month + months;
      final newYear = _value!.year + (newMonth - 1) ~/ 12;
      final finalMonth = ((newMonth - 1) % 12) + 1;
      value = DateTime(newYear, finalMonth, _value!.day);
    }
  }

  /// Add years to current value
  void addYears(int years) {
    if (_value != null) {
      value = DateTime(_value!.year + years, _value!.month, _value!.day);
    }
  }

  /// Check if value is null
  bool get isEmpty => _value == null;

  /// Check if value is not null
  bool get isNotEmpty => _value != null;

  /// Check if value is before another date
  bool isBefore(DateTime other) {
    if (_value == null) return false;
    return _value!.isBefore(other);
  }

  /// Check if value is after another date
  bool isAfter(DateTime other) {
    if (_value == null) return false;
    return _value!.isAfter(other);
  }

  /// Get normalized date (without time component)
  DateTime? get normalizedDate {
    if (_value == null) return null;
    return DateTime(_value!.year, _value!.month, _value!.day);
  }

}
