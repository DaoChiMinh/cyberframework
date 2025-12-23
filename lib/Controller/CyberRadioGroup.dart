import 'package:cyberframework/cyberframework.dart';

/// CyberRadioGroup - Radio button group đơn giản với values và displays
///
/// Usage:
/// ```dart
/// CyberRadioGroup(
///   text: row.bind("gender"),
///   values: "0;1",
///   displays: "Nam;Nữ",
///   label: "Giới tính",
///   group: "gender_group",
/// )
/// ```
class CyberRadioGroup extends StatefulWidget {
  /// Binding đến field chứa giá trị được chọn (data binding)
  final dynamic text;

  /// Danh sách giá trị, phân cách bởi ";" - Có thể binding
  /// VD: "0;1;2" hoặc "male;female;other"
  final dynamic values;

  /// Danh sách label hiển thị, phân cách bởi ";" - Có thể binding
  /// VD: "Nam;Nữ;Khác"
  final dynamic displays;

  /// Label cho toàn bộ group
  final String? label;

  /// Tên group (unique identifier)
  final String group;

  /// Hướng hiển thị: vertical hoặc horizontal
  final Axis direction;

  /// Khoảng cách giữa các radio
  final double spacing;

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

  /// Style cho label group
  final TextStyle? labelStyle;

  /// Style cho label từng item
  final TextStyle? itemLabelStyle;

  /// Có hiển thị label group không
  final bool isShowLabel;

  /// Visibility binding
  final dynamic isVisible;

  const CyberRadioGroup({
    super.key,
    required this.text,
    required this.values,
    required this.displays,
    this.label,
    required this.group,
    this.direction = Axis.vertical,
    this.spacing = 8,
    this.enabled = true,
    this.onChanged,
    this.onLeaver,
    this.activeColor,
    this.fillColor,
    this.size,
    this.labelStyle,
    this.itemLabelStyle,
    this.isShowLabel = true,
    this.isVisible = true,
  });

  @override
  State<CyberRadioGroup> createState() => _CyberRadioGroupState();
}

class _CyberRadioGroupState extends State<CyberRadioGroup> {
  CyberDataRow? _boundTextRow;
  String? _boundTextField;
  CyberDataRow? _boundValuesRow;
  String? _boundValuesField;
  CyberDataRow? _boundDisplaysRow;
  String? _boundDisplaysField;
  CyberDataRow? _visibilityBoundRow;
  String? _visibilityBoundField;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _parseBindings();
    _parseVisibilityBinding();

    // Listen to all bound rows
    if (_boundTextRow != null) {
      _boundTextRow!.addListener(_onBindingChanged);
    }
    if (_boundValuesRow != null && _boundValuesRow != _boundTextRow) {
      _boundValuesRow!.addListener(_onBindingChanged);
    }
    if (_boundDisplaysRow != null &&
        _boundDisplaysRow != _boundTextRow &&
        _boundDisplaysRow != _boundValuesRow) {
      _boundDisplaysRow!.addListener(_onBindingChanged);
    }
    if (_visibilityBoundRow != null &&
        _visibilityBoundRow != _boundTextRow &&
        _visibilityBoundRow != _boundValuesRow &&
        _visibilityBoundRow != _boundDisplaysRow) {
      _visibilityBoundRow!.addListener(_onBindingChanged);
    }
  }

  @override
  void dispose() {
    if (_boundTextRow != null) {
      _boundTextRow!.removeListener(_onBindingChanged);
    }
    if (_boundValuesRow != null && _boundValuesRow != _boundTextRow) {
      _boundValuesRow!.removeListener(_onBindingChanged);
    }
    if (_boundDisplaysRow != null &&
        _boundDisplaysRow != _boundTextRow &&
        _boundDisplaysRow != _boundValuesRow) {
      _boundDisplaysRow!.removeListener(_onBindingChanged);
    }
    if (_visibilityBoundRow != null &&
        _visibilityBoundRow != _boundTextRow &&
        _visibilityBoundRow != _boundValuesRow &&
        _visibilityBoundRow != _boundDisplaysRow) {
      _visibilityBoundRow!.removeListener(_onBindingChanged);
    }
    super.dispose();
  }

  void _parseBindings() {
    // Parse text binding
    if (widget.text is CyberBindingExpression) {
      final expr = widget.text as CyberBindingExpression;
      _boundTextRow = expr.row;
      _boundTextField = expr.fieldName;
    }

    // Parse values binding
    if (widget.values is CyberBindingExpression) {
      final expr = widget.values as CyberBindingExpression;
      _boundValuesRow = expr.row;
      _boundValuesField = expr.fieldName;
    }

    // Parse displays binding
    if (widget.displays is CyberBindingExpression) {
      final expr = widget.displays as CyberBindingExpression;
      _boundDisplaysRow = expr.row;
      _boundDisplaysField = expr.fieldName;
    }
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
    if (_isUpdating) return;
    setState(() {});
  }

  /// Get current selected value
  dynamic _getCurrentValue() {
    // Parse binding if needed
    if (widget.text is CyberBindingExpression) {
      final expr = widget.text as CyberBindingExpression;
      if (_boundTextRow != expr.row || _boundTextField != expr.fieldName) {
        _boundTextRow = expr.row;
        _boundTextField = expr.fieldName;
      }
    }

    dynamic rawValue;

    if (_boundTextRow != null && _boundTextField != null) {
      try {
        rawValue = _boundTextRow![_boundTextField!];
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

  /// Get values list
  List<String> _getValues() {
    String valuesStr;

    if (_boundValuesRow != null && _boundValuesField != null) {
      try {
        valuesStr = _boundValuesRow![_boundValuesField!]?.toString() ?? '';
      } catch (e) {
        return [];
      }
    } else if (widget.values != null &&
        widget.values is! CyberBindingExpression) {
      valuesStr = widget.values.toString();
    } else {
      return [];
    }

    if (valuesStr.isEmpty) return [];

    return valuesStr
        .split(';')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Get displays list
  List<String> _getDisplays() {
    String displaysStr;

    if (_boundDisplaysRow != null && _boundDisplaysField != null) {
      try {
        displaysStr =
            _boundDisplaysRow![_boundDisplaysField!]?.toString() ?? '';
      } catch (e) {
        return [];
      }
    } else if (widget.displays != null &&
        widget.displays is! CyberBindingExpression) {
      displaysStr = widget.displays.toString();
    } else {
      return [];
    }

    if (displaysStr.isEmpty) return [];

    return displaysStr
        .split(';')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Update selected value
  void _updateValue(dynamic newValue) {
    if (!widget.enabled) return;

    _isUpdating = true;

    // Update binding
    if (_boundTextRow != null && _boundTextField != null) {
      final originalValue = _boundTextRow![_boundTextField!];

      // Preserve original type
      if (originalValue is String && newValue != null) {
        _boundTextRow![_boundTextField!] = newValue.toString();
      } else if (originalValue is int && newValue is String) {
        _boundTextRow![_boundTextField!] = int.tryParse(newValue) ?? 0;
      } else if (originalValue is double && newValue is String) {
        _boundTextRow![_boundTextField!] = double.tryParse(newValue) ?? 0.0;
      } else {
        _boundTextRow![_boundTextField!] = newValue;
      }
    }

    // Callbacks
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

    Widget buildRadioGroup() {
      final values = _getValues();
      final displays = _getDisplays();
      final currentValue = _getCurrentValue();

      if (values.isEmpty) {
        return const SizedBox.shrink();
      }

      // Đảm bảo displays có cùng số lượng với values
      final displaysList = List<String>.generate(
        values.length,
        (index) => index < displays.length ? displays[index] : values[index],
      );

      List<Widget> radioWidgets = [];

      for (int i = 0; i < values.length; i++) {
        final value = values[i];
        final display = displaysList[i];
        final isSelected = currentValue?.toString() == value;

        radioWidgets.add(
          _buildRadioItem(
            value: value,
            display: display,
            isSelected: isSelected,
          ),
        );
      }

      Widget radioGroup;

      if (widget.direction == Axis.horizontal) {
        radioGroup = Wrap(
          spacing: widget.spacing,
          runSpacing: widget.spacing,
          children: radioWidgets,
        );
      } else {
        radioGroup = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: radioWidgets
              .map(
                (radio) => Padding(
                  padding: EdgeInsets.only(bottom: widget.spacing),
                  child: radio,
                ),
              )
              .toList(),
        );
      }

      // Add label if needed
      if (widget.isShowLabel &&
          widget.label != null &&
          widget.label!.isNotEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
              child: Text(
                widget.label!,
                style:
                    widget.labelStyle ??
                    const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF555555),
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            radioGroup,
          ],
        );
      }

      return radioGroup;
    }

    // Wrap with ListenableBuilder if has any binding
    final listeners = <Listenable>[];
    if (_boundTextRow != null) listeners.add(_boundTextRow!);
    if (_boundValuesRow != null && _boundValuesRow != _boundTextRow) {
      listeners.add(_boundValuesRow!);
    }
    if (_boundDisplaysRow != null &&
        _boundDisplaysRow != _boundTextRow &&
        _boundDisplaysRow != _boundValuesRow) {
      listeners.add(_boundDisplaysRow!);
    }

    if (listeners.isNotEmpty) {
      return ListenableBuilder(
        listenable: Listenable.merge(listeners),
        builder: (context, child) => buildRadioGroup(),
      );
    }

    return buildRadioGroup();
  }

  Widget _buildRadioItem({
    required String value,
    required String display,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: widget.enabled ? () => _updateValue(value) : null,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _IOSRadioButton(
              selected: isSelected,
              enabled: widget.enabled,
              activeColor: widget.activeColor ?? const Color(0xFF007AFF),
              fillColor: widget.fillColor ?? Colors.white,
              size: widget.size ?? 24,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                display,
                style:
                    widget.itemLabelStyle ??
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
}

/// iOS-style Radio Button Widget
class _IOSRadioButton extends StatelessWidget {
  final bool selected;
  final bool enabled;
  final Color activeColor;
  final Color fillColor;
  final double size;

  const _IOSRadioButton({
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
