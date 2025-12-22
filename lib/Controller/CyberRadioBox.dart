import 'package:cyberframework/cyberframework.dart';

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

  void _onBindingChanged() {
    if (_isUpdating || _boundRow == null || _boundField == null) return;
    setState(() {}); // Trigger rebuild
  }

  dynamic _getCurrentGroupValue() {
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
        final val = expr.row[expr.fieldName];

        return val;
      } catch (e) {
        return null;
      }
    }
    return widget.value;
  }

  bool _isSelected() {
    final groupValue = _getCurrentGroupValue();
    final myValue = _getValue();

    // ✅ So sánh theo string để tránh lỗi type mismatch
    final isSelected = groupValue?.toString() == myValue?.toString();

    return isSelected;
  }

  void _updateValue() {
    if (!widget.enabled) {
      return;
    }

    final newValue = _getValue();

    _isUpdating = true;

    // ✅ Update binding
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
    Widget buildRadioBox() {
      final isSelected = _isSelected();

      // ✅ iOS Radio widget (không có gesture)
      Widget radioDisplay = _IOSRadioBox(
        selected: isSelected,
        enabled: widget.enabled,
        activeColor: widget.activeColor ?? const Color(0xFF007AFF),
        fillColor: widget.fillColor ?? Colors.white,
        size: widget.size ?? 24,
      );

      // ✅ Nếu có label, wrap với InkWell + Row
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

      // ✅ Không có label, wrap radio với GestureDetector
      return GestureDetector(
        onTap: widget.enabled ? _updateValue : null,
        child: radioDisplay,
      );
    }

    // ✅ Wrap toàn bộ với ListenableBuilder nếu có binding
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

/// Helper để tạo RadioBox group dễ dàng hơn
class CyberRadioGroup extends StatelessWidget {
  /// Binding đến field chứa giá trị được chọn
  final dynamic text;

  /// Tên nhóm
  final String group;

  /// Danh sách các radio items
  final List<CyberRadioItem> items;

  /// Callback khi thay đổi
  final ValueChanged<dynamic>? onChanged;

  /// Hướng hiển thị
  final Axis direction;

  /// Khoảng cách
  final double spacing;

  /// Enable/disable
  final bool enabled;

  const CyberRadioGroup({
    super.key,
    required this.text,
    required this.group,
    required this.items,
    this.onChanged,
    this.direction = Axis.vertical,
    this.spacing = 8,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final radios = items.map((item) {
      return CyberRadioBox(
        text: text,
        group: group,
        value: item.value,
        label: item.label,
        enabled: enabled && item.enabled,
        onChanged: onChanged,
        activeColor: item.activeColor,
        size: item.size,
      );
    }).toList();

    if (direction == Axis.horizontal) {
      return Wrap(spacing: spacing, children: radios);
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: radios
            .map(
              (radio) => Padding(
                padding: EdgeInsets.only(bottom: spacing),
                child: radio,
              ),
            )
            .toList(),
      );
    }
  }
}

/// Data class cho mỗi radio item
class CyberRadioItem {
  final dynamic value;
  final String label;
  final bool enabled;
  final Color? activeColor;
  final double? size;

  const CyberRadioItem({
    required this.value,
    required this.label,
    this.enabled = true,
    this.activeColor,
    this.size,
  });
}
