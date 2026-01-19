// lib/Controller/cyberradiobox.dart

import 'package:cyberframework/cyberframework.dart';
import 'package:flutter/material.dart';

/// CyberRadioBox - Single radio button widget (Traditional Pattern)
///
/// Triết lý:
/// - Một binding cho cả group (text)
/// - Mỗi radio có value riêng
/// - Khi chọn: text = value của radio được chọn
///
/// Usage:
/// ```dart
/// // Sử dụng riêng lẻ
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
/// ```
class CyberRadioBox extends StatefulWidget {
  /// Binding đến field chứa giá trị được chọn (data binding)
  final dynamic text;

  /// Tên nhóm để group các radio buttons với nhau (có thể binding)
  final dynamic group;

  /// Giá trị của radio này (khi được chọn, text sẽ = value) (có thể binding)
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

  const CyberRadioBox({
    super.key,
    required this.text,
    required this.group,
    required this.value,
    this.label,
    this.labelStyle,
    this.enabled = true,
    this.isVisible = true,
    this.onChanged,
    this.onLeaver,
    this.activeColor,
    this.fillColor,
    this.size,
  });

  @override
  State<CyberRadioBox> createState() => _CyberRadioBoxState();
}

class _CyberRadioBoxState extends State<CyberRadioBox> {
  CyberDataRow? _boundRow;
  String? _boundField;
  CyberDataRow? _visibilityBoundRow;
  String? _visibilityBoundField;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _parseBinding();
    _parseVisibilityBinding();
    _registerListeners();
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
  }

  @override
  void dispose() {
    _unregisterListeners();
    super.dispose();
  }

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

  dynamic _getCurrentGroupValue() {
    if (widget.text is CyberBindingExpression) {
      final expr = widget.text as CyberBindingExpression;
      if (_boundRow != expr.row || _boundField != expr.fieldName) {
        _boundRow = expr.row;
        _boundField = expr.fieldName;
      }
    }

    dynamic rawValue;

    if (_boundRow != null && _boundField != null) {
      try {
        rawValue = _boundRow![_boundField!];
      } catch (e) {
        return null;
      }
    } else if (widget.text != null && widget.text is! CyberBindingExpression) {
      rawValue = widget.text;
    } else {
      return null;
    }

    return rawValue;
  }

  /// Get current value (support binding)
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
    final groupValue = _getCurrentGroupValue();
    final myValue = _getValue();

    // So sánh theo string để tránh lỗi type mismatch
    return groupValue?.toString() == myValue?.toString();
  }

  void _updateValue() {
    if (!widget.enabled) return;

    final newValue = _getValue();

    _isUpdating = true;

    try {
      // Update binding
      if (_boundRow != null && _boundField != null) {
        final originalValue = _boundRow![_boundField!];

        // Preserve original type
        if (originalValue is String && newValue != null) {
          _boundRow![_boundField!] = newValue.toString();
        } else if (originalValue is int && newValue is int) {
          _boundRow![_boundField!] = newValue;
        } else if (originalValue is double && newValue is num) {
          _boundRow![_boundField!] = newValue.toDouble();
        } else {
          _boundRow![_boundField!] = newValue;
        }
      }

      // Callbacks
      widget.onChanged?.call(newValue);
      widget.onLeaver?.call(newValue);

      setState(() {});
    } finally {
      _isUpdating = false;
    }
  }

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
