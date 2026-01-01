import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Controller for CyberTime widget
/// Similar to TextEditingController but for TimeOfDay values
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
  /// Use this when loading data from backend to avoid triggering validation
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

  /// Set value to current time
  void setNow() {
    final now = TimeOfDay.now();
    value = now;
  }

  /// Set specific time
  void setTime(int hour, int minute) {
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      throw ArgumentError('Invalid time: $hour:$minute');
    }
    value = TimeOfDay(hour: hour, minute: minute);
  }

  /// Set to start of day (00:00)
  void setStartOfDay() {
    value = const TimeOfDay(hour: 0, minute: 0);
  }

  /// Set to end of day (23:59)
  void setEndOfDay() {
    value = const TimeOfDay(hour: 23, minute: 59);
  }

  /// Set to noon (12:00)
  void setNoon() {
    value = const TimeOfDay(hour: 12, minute: 0);
  }

  /// Set to midnight (00:00) - alias for setStartOfDay
  void setMidnight() {
    value = const TimeOfDay(hour: 0, minute: 0);
  }

  /// Add hours to current value
  void addHours(int hours) {
    if (_value != null) {
      final totalMinutes = _value!.hour * 60 + _value!.minute + (hours * 60);
      final normalizedMinutes = totalMinutes % (24 * 60);
      final newHour = normalizedMinutes ~/ 60;
      final newMinute = normalizedMinutes % 60;
      value = TimeOfDay(hour: newHour, minute: newMinute);
    }
  }

  /// Add minutes to current value
  void addMinutes(int minutes) {
    if (_value != null) {
      final totalMinutes = _value!.hour * 60 + _value!.minute + minutes;
      final normalizedMinutes = totalMinutes % (24 * 60);
      final newHour = normalizedMinutes ~/ 60;
      final newMinute = normalizedMinutes % 60;
      value = TimeOfDay(hour: newHour, minute: newMinute);
    }
  }

  /// Subtract hours from current value
  void subtractHours(int hours) {
    addHours(-hours);
  }

  /// Subtract minutes from current value
  void subtractMinutes(int minutes) {
    addMinutes(-minutes);
  }

  /// Check if value is null
  bool get isEmpty => _value == null;

  /// Check if value is not null
  bool get isNotEmpty => _value != null;

  /// Check if value is before another time
  bool isBefore(TimeOfDay other) {
    if (_value == null) return false;
    return _toMinutes(_value!) < _toMinutes(other);
  }

  /// Check if value is after another time
  bool isAfter(TimeOfDay other) {
    if (_value == null) return false;
    return _toMinutes(_value!) > _toMinutes(other);
  }

  /// Check if value is same time as another time
  bool isSameTime(TimeOfDay other) {
    return _sameTime(_value, other);
  }

  /// Convert TimeOfDay to minutes since midnight
  int _toMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  /// Get total minutes since midnight
  int? get totalMinutes {
    if (_value == null) return null;
    return _toMinutes(_value!);
  }

  /// Check if time is AM (before 12:00)
  bool get isAM {
    if (_value == null) return false;
    return _value!.hour < 12;
  }

  /// Check if time is PM (12:00 or after)
  bool get isPM {
    if (_value == null) return false;
    return _value!.hour >= 12;
  }

  /// Check if time is morning (00:00 - 11:59)
  bool get isMorning {
    if (_value == null) return false;
    return _value!.hour >= 0 && _value!.hour < 12;
  }

  /// Check if time is afternoon (12:00 - 17:59)
  bool get isAfternoon {
    if (_value == null) return false;
    return _value!.hour >= 12 && _value!.hour < 18;
  }

  /// Check if time is evening (18:00 - 23:59)
  bool get isEvening {
    if (_value == null) return false;
    return _value!.hour >= 18;
  }

  /// Check if time is business hours (08:00 - 17:00)
  bool get isBusinessHours {
    if (_value == null) return false;
    return _value!.hour >= 8 && _value!.hour < 17;
  }

  /// Get formatted string (HH:mm)
  String? get formatted {
    if (_value == null) return null;
    return '${_value!.hour.toString().padLeft(2, '0')}:${_value!.minute.toString().padLeft(2, '0')}';
  }

  /// Get formatted string (HH:mm:ss)
  String? get formattedWithSeconds {
    if (_value == null) return null;
    return '${_value!.hour.toString().padLeft(2, '0')}:${_value!.minute.toString().padLeft(2, '0')}:00';
  }

  /// Get 12-hour format string (h:mm AM/PM)
  String? get formatted12Hour {
    if (_value == null) return null;
    final hour12 = _value!.hourOfPeriod == 0 ? 12 : _value!.hourOfPeriod;
    final period = _value!.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour12:${_value!.minute.toString().padLeft(2, '0')} $period';
  }

  /// Parse time from string (HH:mm or HH:mm:ss)
  static TimeOfDay? parse(String timeString) {
    try {
      final parts = timeString.trim().split(':');
      if (parts.length >= 2) {
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);

        if (hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
          return TimeOfDay(hour: hour, minute: minute);
        }
      }
    } catch (e) {
      // Invalid format
    }
    return null;
  }

  /// Copy value from another controller
  void copyFrom(CyberTimeController other) {
    value = other.value;
  }

  /// Compare with another controller
  bool equals(CyberTimeController other) {
    return _sameTime(_value, other.value);
  }

  /// Create TimeOfDay from DateTime
  static TimeOfDay fromDateTime(DateTime dateTime) {
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }

  /// Convert to DateTime (using today's date)
  DateTime? toDateTime() {
    if (_value == null) return null;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, _value!.hour, _value!.minute);
  }

  /// Convert to DateTime with specific date
  DateTime? toDateTimeWithDate(DateTime date) {
    if (_value == null) return null;
    return DateTime(
      date.year,
      date.month,
      date.day,
      _value!.hour,
      _value!.minute,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  String toString() {
    return 'CyberTimeController(value: ${formatted ?? "null"})';
  }
}
