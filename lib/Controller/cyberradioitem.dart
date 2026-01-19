// lib/Controller/cyberradioitem.dart

import 'package:cyberframework/cyberframework.dart';

/// Model cho một radio button item với multi-column binding
///
/// Mỗi item bind vào 1 cột riêng trong CyberDataRow
/// Khi chọn item: cột của item đó = selectedValue
/// Các item khác: cột = unselectedValue
class CyberRadioItem {
  /// Label hiển thị
  final String label;

  /// Binding expression tới column trong CyberDataRow
  /// Khi item này được chọn: column = selectedValue (default: 1)
  /// Khi item khác được chọn: column = unselectedValue (default: 0)
  final dynamic binding;

  /// Icon code (optional)
  final String? icon;

  /// Enabled
  final bool enabled;

  /// Value khi được chọn (default: 1)
  final dynamic selectedValue;

  /// Value khi không được chọn (default: 0)
  final dynamic unselectedValue;

  const CyberRadioItem({
    required this.label,
    required this.binding,
    this.icon,
    this.enabled = true,
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
      final value = info.row[info.fieldName];
      return _compareValue(value, selectedValue);
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

      // Preserve type
      if (currentValue is String && selectedValue != null) {
        info.row[info.fieldName] = selectedValue.toString();
      } else if (currentValue is int && selectedValue is num) {
        info.row[info.fieldName] = selectedValue.toInt();
      } else if (currentValue is double && selectedValue is num) {
        info.row[info.fieldName] = selectedValue.toDouble();
      } else if (currentValue is bool && selectedValue is bool) {
        info.row[info.fieldName] = selectedValue;
      } else {
        info.row[info.fieldName] = selectedValue;
      }
    } catch (e) {
      // Ignore
    }
  }

  /// Set item này là unselected
  void unselect() {
    final info = bindingInfo;
    if (info == null) return;

    try {
      final currentValue = info.row[info.fieldName];

      // Preserve type
      if (currentValue is String && unselectedValue != null) {
        info.row[info.fieldName] = unselectedValue.toString();
      } else if (currentValue is int && unselectedValue is num) {
        info.row[info.fieldName] = unselectedValue.toInt();
      } else if (currentValue is double && unselectedValue is num) {
        info.row[info.fieldName] = unselectedValue.toDouble();
      } else if (currentValue is bool && unselectedValue is bool) {
        info.row[info.fieldName] = unselectedValue;
      } else {
        info.row[info.fieldName] = unselectedValue;
      }
    } catch (e) {
      // Ignore
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
