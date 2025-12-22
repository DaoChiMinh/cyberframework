import 'package:cyberframework/cyberframework.dart';

class CyberCheckbox extends StatefulWidget {
  final dynamic text;
  final String? label;
  final bool enabled;
  final TextStyle? labelStyle;
  final ValueChanged<bool>? onChanged;
  final Function(dynamic)? onLeaver;
  final Color? activeColor;
  final Color? checkColor;
  final double? size;
  final dynamic isVisible;
  const CyberCheckbox({
    super.key,
    this.text,
    this.label,
    this.enabled = true,
    this.labelStyle,
    this.onChanged,
    this.onLeaver,
    this.activeColor,
    this.checkColor,
    this.size,
    this.isVisible = true,
  });

  @override
  State<CyberCheckbox> createState() => _CyberCheckboxState();
}

class _CyberCheckboxState extends State<CyberCheckbox> {
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
    if (_boundRow != null) {
      _boundRow!.addListener(_onBindingChanged);
    }
    if (_visibilityBoundRow != null && _visibilityBoundRow != _boundRow) {
      _visibilityBoundRow!.addListener(_onBindingChanged);
    }
  }

  @override
  void dispose() {
    if (_boundRow != null) {
      _boundRow!.removeListener(_onBindingChanged);
    }
    if (_visibilityBoundRow != null && _visibilityBoundRow != _boundRow) {
      _visibilityBoundRow!.removeListener(_onBindingChanged);
    }
    super.dispose();
  }

  void _parseBinding() {
    if (widget.text == null) {
      _boundRow = null;
      _boundField = null;
      return;
    }

    if (widget.text is CyberBindingExpression) {
      final expr = widget.text as CyberBindingExpression;
      _boundRow = expr.row;
      _boundField = expr.fieldName;

      return;
    }

    _boundRow = null;
    _boundField = null;
  }

  void _parseVisibilityBinding() {
    if (widget.isVisible == null) {
      _visibilityBoundRow = null;
      _visibilityBoundField = null;
      return;
    }

    if (widget.isVisible is CyberBindingExpression) {
      final expr = widget.isVisible as CyberBindingExpression;
      _visibilityBoundRow = expr.row;
      _visibilityBoundField = expr.fieldName;
      return;
    }

    _visibilityBoundRow = null;
    _visibilityBoundField = null;
  }

  // bool _parseBool(dynamic value) {
  //   if (value == null) return true;
  //   if (value is bool) return value;
  //   if (value is int) return value != 0;
  //   if (value is String) {
  //     final lower = value.toLowerCase().trim();
  //     if (lower == "1" || lower == "true") return true;
  //     if (lower == "0" || lower == "false") return false;
  //     return true;
  //   }
  //   return true;
  // }

  bool _isVisible() {
    if (_visibilityBoundRow != null && _visibilityBoundField != null) {
      return _parseBool(_visibilityBoundRow![_visibilityBoundField!]);
    }
    return _parseBool(widget.isVisible);
  }

  void _onBindingChanged() {
    if (_isUpdating || _boundRow == null || _boundField == null) return;
    setState(() {}); // Trigger rebuild
  }

  bool _getCurrentValue() {
    // ✅ Parse binding nếu chưa parse hoặc widget.text thay đổi
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
        return false;
      }
    } else if (widget.text != null && widget.text is! CyberBindingExpression) {
      rawValue = widget.text;
    } else {
      return false;
    }

    // ✅ Convert sang bool
    final result = _parseBool(rawValue);

    return result;
  }

  /// Parse dynamic value to bool
  /// Ưu tiên: string "1" = true, "0" = false
  bool _parseBool(dynamic value) {
    if (value == null) return false;

    // Bool trực tiếp
    if (value is bool) return value;

    // Int: 1 = true, 0 = false
    if (value is int) return value == 1;

    // String: "1" = true, "0" = false
    if (value is String) {
      final trimmed = value.trim().toLowerCase();
      if (trimmed == "1" || trimmed == "true") return true;
      if (trimmed == "0" || trimmed == "false") return false;
      return false;
    }

    return false;
  }

  void _updateValue(bool newValue) {
    if (!widget.enabled) return;

    _isUpdating = true;

    // ✅ Update binding
    if (_boundRow != null && _boundField != null) {
      final originalValue = _boundRow![_boundField!];

      // Preserve original type
      if (originalValue is String) {
        _boundRow![_boundField!] = newValue ? "1" : "0";
      } else if (originalValue is int) {
        _boundRow![_boundField!] = newValue ? 1 : 0;
      } else {
        _boundRow![_boundField!] = newValue;
      }
    }

    // ✅ Callback
    widget.onChanged?.call(newValue);
    widget.onLeaver?.call(newValue);

    setState(() {
      _isUpdating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible()) {
      return const SizedBox.shrink();
    }
    Widget buildCheckbox() {
      final isChecked = _getCurrentValue();

      // ✅ iOS Checkbox widget (không có gesture)
      Widget checkboxDisplay = _IOSCheckbox(
        value: isChecked,
        enabled: widget.enabled,
        activeColor: widget.activeColor ?? const Color(0xFF00D287),
        checkColor: widget.checkColor ?? Colors.white,
        size: widget.size ?? 24,
      );

      // ✅ Nếu có label, wrap với InkWell + Row
      if (widget.label != null && widget.label!.isNotEmpty) {
        return InkWell(
          onTap: widget.enabled ? () => _updateValue(!isChecked) : null,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                checkboxDisplay,
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

      // ✅ Không có label, wrap checkbox với GestureDetector
      return GestureDetector(
        onTap: widget.enabled ? () => _updateValue(!isChecked) : null,
        child: checkboxDisplay,
      );
    }

    // ✅ Wrap toàn bộ với ListenableBuilder nếu có binding
    if (_boundRow != null) {
      return ListenableBuilder(
        listenable: _boundRow!,
        builder: (context, child) => buildCheckbox(),
      );
    }

    return buildCheckbox();
  }
}

/// iOS-style Checkbox Widget
class _IOSCheckbox extends StatelessWidget {
  final bool value;
  final bool enabled;
  final Color activeColor;
  final Color checkColor;
  final double size;

  const _IOSCheckbox({
    required this.value,
    required this.enabled,
    required this.activeColor,
    required this.checkColor,
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
          color: value ? activeColor : Colors.transparent,
          border: Border.all(
            color: value ? activeColor : Colors.grey[400]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(size * 0.25), // 25% border radius
        ),
        child: value
            ? Icon(Icons.check, color: checkColor, size: size * 0.7)
            : null,
      ),
    );
  }
}

/// Extension để tạo clickable checkbox từ String (optional)
extension CyberCheckboxExtension on String {
  Widget toCheckbox(
    BuildContext context, {
    dynamic value,
    bool enabled = true,
    ValueChanged<bool>? onChanged,
  }) {
    return CyberCheckbox(
      text: value,
      label: this,
      enabled: enabled,
      onChanged: onChanged,
    );
  }
}
