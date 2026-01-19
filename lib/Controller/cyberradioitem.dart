// lib/Controller/cyberradioitem.dart

import 'package:cyberframework/cyberframework.dart';

/// Model cho một radio button item với multi-column hoặc single-column binding
///
/// **Multi-column mode (default):**
/// - Mỗi item bind vào 1 cột riêng trong CyberDataRow
/// - Khi chọn item: cột của item đó = selectedValue (default: 1)
/// - Các item khác: cột = unselectedValue (default: 0)
///
/// **Single-column mode:**
/// - Tất cả items bind vào cùng 1 cột
/// - Mỗi item có value riêng
/// - Khi chọn item: cột = value của item đó
///
/// Usage:
/// ```dart
/// // Multi-column mode (default)
/// CyberRadioItem(
///   label: "Ô tô",
///   binding: drEdit.bind("is_car"),
/// )
///
/// // Single-column mode
/// CyberRadioItem(
///   label: "Ô tô",
///   binding: drEdit.bind("vehicle_type"),
///   value: "car",
///   isSingleColumn: true,
/// )
/// ```
class CyberRadioItem {
  /// Label hiển thị
  final String label;

  /// Binding expression tới column trong CyberDataRow
  final dynamic binding;

  /// Icon code (optional)
  final String? icon;

  /// Enabled
  final bool enabled;

  /// Value của item này (cho single-column mode)
  /// Khi isSingleColumn = true và item được chọn, binding sẽ = value này
  final dynamic value;

  /// Chế độ single-column (tất cả items bind vào 1 cột)
  /// - true: Single-column mode (giống CyberRadioBox)
  /// - false: Multi-column mode (mỗi item 1 cột riêng)
  final bool isSingleColumn;

  /// Value khi được chọn (chỉ dùng cho multi-column mode, default: 1)
  final dynamic selectedValue;

  /// Value khi không được chọn (chỉ dùng cho multi-column mode, default: 0)
  final dynamic unselectedValue;

  const CyberRadioItem({
    required this.label,
    required this.binding,
    this.icon,
    this.enabled = true,
    this.value,
    this.isSingleColumn = false,
    this.selectedValue = 1,
    this.unselectedValue = 0,
  });

  /// Parse binding để lấy row và field
  CyberBindingInfo? get bindingInfo {
    if (binding is CyberBindingExpression) {
      final expr = binding as CyberBindingExpression;
      return CyberBindingInfo(row: expr.row, fieldName: expr.fieldName);
    }
    return null;
  }

  /// Kiểm tra item này có được chọn không
  bool isSelected() {
    final info = bindingInfo;
    if (info == null) return false;

    try {
      final currentValue = info.row[info.fieldName];

      // Single-column mode: so sánh với value
      if (isSingleColumn && value != null) {
        return _compareValue(currentValue, value);
      }

      // Multi-column mode: so sánh với selectedValue
      return _compareValue(currentValue, selectedValue);
    } catch (e) {
      return false;
    }
  }

  /// Set item này là selected
  void select() {
    final info = bindingInfo;
    if (info == null || !enabled) return;

    try {
      final currentValue = info.row[info.fieldName];

      // Single-column mode: set = value của item này
      if (isSingleColumn && value != null) {
        _setFieldValue(info, currentValue, value);
        return;
      }

      // Multi-column mode: set = selectedValue
      _setFieldValue(info, currentValue, selectedValue);
    } catch (e) {
      // Ignore
    }
  }

  /// Set item này là unselected
  void unselect() {
    // Single-column mode: không cần unselect
    // (vì khi chọn item khác, nó sẽ set = value của item khác)
    if (isSingleColumn) return;

    // Multi-column mode: set = unselectedValue
    final info = bindingInfo;
    if (info == null) return;

    try {
      final currentValue = info.row[info.fieldName];
      _setFieldValue(info, currentValue, unselectedValue);
    } catch (e) {
      // Ignore
    }
  }

  /// Helper: Set field value với type preservation
  void _setFieldValue(
    CyberBindingInfo info,
    dynamic currentValue,
    dynamic newValue,
  ) {
    if (currentValue is String && newValue != null) {
      info.row[info.fieldName] = newValue.toString();
    } else if (currentValue is int && newValue is num) {
      info.row[info.fieldName] = newValue.toInt();
    } else if (currentValue is double && newValue is num) {
      info.row[info.fieldName] = newValue.toDouble();
    } else if (currentValue is bool && newValue is bool) {
      info.row[info.fieldName] = newValue;
    } else {
      info.row[info.fieldName] = newValue;
    }
  }

  /// So sánh 2 giá trị
  bool _compareValue(dynamic a, dynamic b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;

    // Number comparison
    if (a is num && b is num) {
      return a == b;
    }

    // Boolean comparison
    if (a is bool && b is bool) {
      return a == b;
    }

    // String comparison
    return a.toString() == b.toString();
  }
}

/// Helper class để parse binding info
class CyberBindingInfo {
  final CyberDataRow row;
  final String fieldName;

  CyberBindingInfo({required this.row, required this.fieldName});
}
