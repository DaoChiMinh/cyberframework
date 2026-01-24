// lib/Controller/cyberradiobox.dart

import 'package:cyberframework/cyberframework.dart';
import 'package:flutter/material.dart';

/// CyberRadioBox - Single radio button widget với multi-column hoặc single-column binding
///
/// **Single-column mode (default - Traditional Pattern):**
/// - Một binding cho cả group (text)
/// - Mỗi radio có value riêng
/// - Khi chọn: text = value của radio được chọn
///
/// **Multi-column mode:**
/// - Mỗi radio bind vào 1 column riêng trong CyberDataRow
/// - Khi chọn: column = selectedValue (default: 1)
/// - Khi không chọn: column = unselectedValue (default: 0)
/// - Các radio cùng group sẽ tự động exclusive với nhau
///
/// Usage:
/// ```dart
/// // Single-column mode (default) - Traditional Pattern
/// CyberRadioBox(
///   text: drEdit.bind("gender"),
///   group: "gender_group",
///   value: "male",
///   label: "Nam",
/// )
///
/// CyberRadioBox(
///   text: drEdit.bind("gender"),
///   group: "gender_group",
///   value: "female",
///   label: "Nữ",
/// )
///
/// // Multi-column mode - Mỗi radio bind column riêng
/// // QUAN TRỌNG: Phải có cùng group để exclusive với nhau
/// CyberRadioBox(
///   text: drEdit.bind("is_car"),
///   group: "vehicle_type",  // ← Cùng group
///   isSingleColumn: false,
///   label: "Ô tô",
/// )
///
/// CyberRadioBox(
///   text: drEdit.bind("is_motorcycle"),
///   group: "vehicle_type",  // ← Cùng group
///   isSingleColumn: false,
///   label: "Xe máy",
/// )
/// ```
class CyberRadioBox extends StatefulWidget {
  /// Binding đến field chứa giá trị được chọn (data binding)
  final dynamic text;

  /// Tên nhóm để group các radio buttons với nhau
  /// QUAN TRỌNG: Trong multi-column mode, các radio cùng group sẽ exclusive với nhau
  final dynamic group;

  /// Giá trị của radio này (khi được chọn, text sẽ = value)
  /// Chỉ dùng cho single-column mode (có thể binding)
  final dynamic value;

  /// Label hiển thị bên cạnh radio
  final String? label;

  /// Style cho label
  final TextStyle? labelStyle;

  /// Có enable hay không
  final bool enabled;

  /// Callback khi value thay đổi
  final ValueChanged<dynamic>? onChanged;

  /// Callback khi rời khỏi control
  final Function(dynamic)? onLeaver;

  /// Màu khi được chọn
  final Color? activeColor;

  /// Màu của dot bên trong
  final Color? fillColor;

  /// Size của radio button
  final double? size;

  /// Visible binding
  final dynamic isVisible;

  /// Chế độ single-column (tất cả radios bind vào 1 cột)
  /// - true (default): Single-column mode - giống traditional radio pattern
  /// - false: Multi-column mode - mỗi radio bind column riêng
  final bool isSingleColumn;

  /// Value khi được chọn (chỉ dùng cho multi-column mode, default: 1)
  final dynamic selectedValue;

  /// Value khi không được chọn (chỉ dùng cho multi-column mode, default: 0)
  final dynamic unselectedValue;

  /// Cho phép toggle (click lần nữa sẽ unselect)
  /// Chỉ có tác dụng với multi-column mode khi không có group
  final bool allowToggle;

  const CyberRadioBox({
    super.key,
    required this.text,
    this.group,
    this.value,
    this.label,
    this.labelStyle,
    this.enabled = true,
    this.isVisible = true,
    this.onChanged,
    this.onLeaver,
    this.activeColor,
    this.fillColor,
    this.size,
    this.isSingleColumn = true,
    this.selectedValue = 1,
    this.unselectedValue = 0,
    this.allowToggle = false,
  });

  @override
  State<CyberRadioBox> createState() => _CyberRadioBoxState();
}

class _CyberRadioBoxState extends State<CyberRadioBox> {
  // ============================================================================
  // STATIC GROUP REGISTRY
  // Để các radio trong cùng group biết về nhau (cho multi-column mode)
  // ============================================================================
  static final Map<String, Set<_CyberRadioBoxState>> _groupRegistry = {};

  CyberDataRow? _boundRow;
  String? _boundField;
  CyberDataRow? _visibilityBoundRow;
  String? _visibilityBoundField;
  bool _isUpdating = false;
  String? _currentGroupKey;

  @override
  void initState() {
    super.initState();
    _parseBinding();
    _parseVisibilityBinding();
    _registerListeners();
    _registerToGroup();
  }

  @override
  void didUpdateWidget(CyberRadioBox oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.text != oldWidget.text) {
      _unregisterListeners();
      _parseBinding();
      _registerListeners();
    }

    if (widget.isVisible != oldWidget.isVisible) {
      _parseVisibilityBinding();
    }

    // Re-register nếu group thay đổi
    if (_getGroupKey() != _currentGroupKey) {
      _unregisterFromGroup();
      _registerToGroup();
    }
  }

  @override
  void dispose() {
    _unregisterListeners();
    _unregisterFromGroup();
    super.dispose();
  }

  // ============================================================================
  // GROUP REGISTRY MANAGEMENT
  // ============================================================================

  String? _getGroupKey() {
    if (widget.group == null) return null;

    // Support binding cho group
    if (widget.group is CyberBindingExpression) {
      final expr = widget.group as CyberBindingExpression;
      try {
        return expr.row[expr.fieldName]?.toString();
      } catch (e) {
        return null;
      }
    }
    return widget.group.toString();
  }

  void _registerToGroup() {
    _currentGroupKey = _getGroupKey();
    if (_currentGroupKey == null) return;

    _groupRegistry.putIfAbsent(_currentGroupKey!, () => {});
    _groupRegistry[_currentGroupKey!]!.add(this);
  }

  void _unregisterFromGroup() {
    if (_currentGroupKey == null) return;

    _groupRegistry[_currentGroupKey!]?.remove(this);
    if (_groupRegistry[_currentGroupKey!]?.isEmpty ?? false) {
      _groupRegistry.remove(_currentGroupKey!);
    }
    _currentGroupKey = null;
  }

  /// Unselect tất cả các radio khác trong cùng group (multi-column mode)
  void _unselectOthersInGroup() {
    final groupKey = _getGroupKey();
    if (groupKey == null) return;

    final siblings = _groupRegistry[groupKey];
    if (siblings == null) return;

    for (final sibling in siblings) {
      if (sibling != this && sibling.mounted) {
        sibling._unselectSelf();
      }
    }
  }

  /// Unselect bản thân (được gọi bởi radio khác trong group)
  void _unselectSelf() {
    if (_isUpdating) return;
    if (_boundRow == null || _boundField == null) return;

    _isUpdating = true;
    try {
      final currentValue = _boundRow![_boundField!];
      _setFieldValue(currentValue, widget.unselectedValue);
      setState(() {});
    } finally {
      _isUpdating = false;
    }
  }

  // ============================================================================
  // BINDING MANAGEMENT
  // ============================================================================

  void _parseBinding() {
    if (widget.text is CyberBindingExpression) {
      final expr = widget.text as CyberBindingExpression;
      _boundRow = expr.row;
      _boundField = expr.fieldName;
    } else {
      _boundRow = null;
      _boundField = null;
    }
  }

  void _parseVisibilityBinding() {
    if (widget.isVisible is CyberBindingExpression) {
      final expr = widget.isVisible as CyberBindingExpression;
      _visibilityBoundRow = expr.row;
      _visibilityBoundField = expr.fieldName;
    } else {
      _visibilityBoundRow = null;
      _visibilityBoundField = null;
    }
  }

  void _registerListeners() {
    if (_boundRow != null) {
      _boundRow!.addListener(_onBindingChanged);
    }
    if (_visibilityBoundRow != null && _visibilityBoundRow != _boundRow) {
      _visibilityBoundRow!.addListener(_onBindingChanged);
    }
  }

  void _unregisterListeners() {
    if (_boundRow != null) {
      _boundRow!.removeListener(_onBindingChanged);
    }
    if (_visibilityBoundRow != null && _visibilityBoundRow != _boundRow) {
      _visibilityBoundRow!.removeListener(_onBindingChanged);
    }
  }

  void _onBindingChanged() {
    if (_isUpdating) return;
    setState(() {});
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  bool _parseBool(dynamic value) {
    if (value == null) return true;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase().trim();
      if (lower == "1" || lower == "true") return true;
      if (lower == "0" || lower == "false") return false;
      return true;
    }
    return true;
  }

  bool _isVisible() {
    if (_visibilityBoundRow != null && _visibilityBoundField != null) {
      return _parseBool(_visibilityBoundRow![_visibilityBoundField!]);
    }
    return _parseBool(widget.isVisible);
  }

  /// So sánh 2 giá trị
  bool _compareValue(dynamic a, dynamic b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a is num && b is num) return a == b;
    if (a is bool && b is bool) return a == b;
    return a.toString() == b.toString();
  }

  /// Get current value from binding
  dynamic _getCurrentBindingValue() {
    if (widget.text is CyberBindingExpression) {
      final expr = widget.text as CyberBindingExpression;
      if (_boundRow != expr.row || _boundField != expr.fieldName) {
        _boundRow = expr.row;
        _boundField = expr.fieldName;
      }
    }

    if (_boundRow != null && _boundField != null) {
      try {
        return _boundRow![_boundField!];
      } catch (e) {
        return null;
      }
    } else if (widget.text != null && widget.text is! CyberBindingExpression) {
      return widget.text;
    }
    return null;
  }

  /// Get current value (support binding) - for single-column mode
  dynamic _getValue() {
    if (widget.value is CyberBindingExpression) {
      final expr = widget.value as CyberBindingExpression;
      try {
        return expr.row[expr.fieldName];
      } catch (e) {
        return null;
      }
    }
    return widget.value;
  }

  bool _isSelected() {
    final currentValue = _getCurrentBindingValue();

    if (widget.isSingleColumn) {
      // Single-column mode: so sánh với value
      final myValue = _getValue();
      return _compareValue(currentValue, myValue);
    } else {
      // Multi-column mode: so sánh với selectedValue
      return _compareValue(currentValue, widget.selectedValue);
    }
  }

  /// Helper: Set field value với type preservation
  void _setFieldValue(dynamic currentValue, dynamic newValue) {
    if (_boundRow == null || _boundField == null) return;

    if (currentValue is String && newValue != null) {
      _boundRow![_boundField!] = newValue.toString();
    } else if (currentValue is int && newValue is num) {
      _boundRow![_boundField!] = newValue.toInt();
    } else if (currentValue is double && newValue is num) {
      _boundRow![_boundField!] = newValue.toDouble();
    } else if (currentValue is bool && newValue is bool) {
      _boundRow![_boundField!] = newValue;
    } else {
      _boundRow![_boundField!] = newValue;
    }
  }

  void _updateValue() {
    if (!widget.enabled) return;

    _isUpdating = true;

    try {
      final currentValue = _getCurrentBindingValue();
      final isCurrentlySelected = _isSelected();
      dynamic newValue;

      if (widget.isSingleColumn) {
        // Single-column mode: set = value của radio này
        newValue = _getValue();
        _setFieldValue(currentValue, newValue);
      } else {
        // Multi-column mode
        final hasGroup = _getGroupKey() != null;

        if (isCurrentlySelected && widget.allowToggle && !hasGroup) {
          // Toggle off nếu đang selected, cho phép toggle, và không có group
          newValue = widget.unselectedValue;
        } else if (isCurrentlySelected && hasGroup) {
          // Đã selected và có group → không làm gì (radio behavior)
          return;
        } else {
          // Select
          newValue = widget.selectedValue;

          // Unselect các radio khác trong cùng group
          if (hasGroup) {
            _unselectOthersInGroup();
          }
        }
        _setFieldValue(currentValue, newValue);
      }

      // Callbacks
      widget.onChanged?.call(newValue);
      widget.onLeaver?.call(newValue);

      setState(() {});
    } finally {
      _isUpdating = false;
    }
  }

  // ============================================================================
  // BUILD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    if (!_isVisible()) {
      return const SizedBox.shrink();
    }

    Widget buildRadioBox() {
      final isSelected = _isSelected();

      // iOS Radio widget
      Widget radioDisplay = _IOSRadioBox(
        selected: isSelected,
        enabled: widget.enabled,
        activeColor: widget.activeColor ?? const Color(0xFF007AFF),
        fillColor: widget.fillColor ?? Colors.white,
        size: widget.size ?? 24,
      );

      // Nếu có label, wrap với InkWell + Row
      if (widget.label != null && widget.label!.isNotEmpty) {
        return InkWell(
          onTap: widget.enabled ? _updateValue : null,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                radioDisplay,
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.label!,
                    style:
                        widget.labelStyle ??
                        TextStyle(
                          fontSize: 16,
                          color: widget.enabled ? Colors.black87 : Colors.grey,
                        ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // Không có label, wrap radio với GestureDetector
      return GestureDetector(
        onTap: widget.enabled ? _updateValue : null,
        child: radioDisplay,
      );
    }

    // Wrap với ListenableBuilder nếu có binding
    if (_boundRow != null) {
      return ListenableBuilder(
        listenable: _boundRow!,
        builder: (context, child) => buildRadioBox(),
      );
    }

    return buildRadioBox();
  }
}

/// iOS-style Radio Button Widget
class _IOSRadioBox extends StatelessWidget {
  final bool selected;
  final bool enabled;
  final Color activeColor;
  final Color fillColor;
  final double size;

  const _IOSRadioBox({
    required this.selected,
    required this.enabled,
    required this.activeColor,
    required this.fillColor,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = enabled ? 1.0 : 0.5;

    return Opacity(
      opacity: opacity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(
            color: selected ? activeColor : Colors.grey[400]!,
            width: 2,
          ),
          shape: BoxShape.circle,
        ),
        child: selected
            ? Center(
                child: Container(
                  width: size * 0.5,
                  height: size * 0.5,
                  decoration: BoxDecoration(
                    color: activeColor,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
