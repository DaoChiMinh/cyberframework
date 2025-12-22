import 'package:cyberframework/cyberframework.dart';
import 'package:flutter/cupertino.dart';

class CyberComboBox extends StatefulWidget {
  /// Binding đến field chứa giá trị được chọn (value binding)
  final dynamic text;

  /// Field name để hiển thị (có thể binding)
  final dynamic displayMember;

  /// Field name cho giá trị (có thể binding)
  final dynamic valueMember;

  /// DataSource là CyberDataTable
  final CyberDataTable? dataSource;

  /// Label hiển thị phía trên
  final String? label;

  /// Hint text khi chưa chọn
  final String? hint;

  /// Style cho label
  final TextStyle? labelStyle;

  /// Style cho text được chọn
  final TextStyle? textStyle;

  /// Icon
  final IconData? icon;

  /// Có enable hay không
  final bool enabled;

  /// Callback khi value thay đổi
  final ValueChanged<dynamic>? onChanged;

  /// Callback khi rời khỏi control
  final Function(dynamic)? onLeaver;

  /// Màu icon
  final Color? iconColor;

  /// Background color
  final Color? backgroundColor;

  /// Border color
  final Color? borderColor;

  /// Show label hay không
  final bool isShowLabel;
  final dynamic isVisible;
  const CyberComboBox({
    super.key,
    this.text,
    this.displayMember,
    this.valueMember,
    this.dataSource,
    this.label,
    this.hint,
    this.labelStyle,
    this.textStyle,
    this.icon,
    this.enabled = true,
    this.onChanged,
    this.onLeaver,
    this.iconColor,
    this.backgroundColor,
    this.borderColor,
    this.isShowLabel = true,
    this.isVisible = true,
  });

  @override
  State<CyberComboBox> createState() => _CyberComboBoxState();
}

class _CyberComboBoxState extends State<CyberComboBox> {
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
    // Listen to DataSource changes
    if (widget.dataSource != null) {
      widget.dataSource!.addListener(_onDataSourceChanged);
    }
  }

  @override
  void dispose() {
    if (_boundRow != null) {
      _boundRow!.removeListener(_onBindingChanged);
    }
    if (widget.dataSource != null) {
      widget.dataSource!.removeListener(_onDataSourceChanged);
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

  void _onDataSourceChanged() {
    if (_isUpdating) return;
    setState(() {}); // Trigger rebuild when datasource changes
  }

  /// Get current selected value
  dynamic _getCurrentValue() {
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

  /// Get display member field name
  String _getDisplayMember() {
    if (widget.displayMember is CyberBindingExpression) {
      final expr = widget.displayMember as CyberBindingExpression;
      try {
        return expr.row[expr.fieldName]?.toString() ?? '';
      } catch (e) {
        return '';
      }
    }
    return widget.displayMember?.toString() ?? '';
  }

  /// Get value member field name
  String _getValueMember() {
    if (widget.valueMember is CyberBindingExpression) {
      final expr = widget.valueMember as CyberBindingExpression;
      try {
        return expr.row[expr.fieldName]?.toString() ?? '';
      } catch (e) {
        return '';
      }
    }
    return widget.valueMember?.toString() ?? '';
  }

  /// Get display text for current value
  String _getDisplayText() {
    final currentValue = _getCurrentValue();
    if (currentValue == null || widget.dataSource == null) {
      return widget.hint ?? '';
    }

    final valueMember = _getValueMember();
    final displayMember = _getDisplayMember();

    if (valueMember.isEmpty || displayMember.isEmpty) {
      return widget.hint ?? '';
    }

    try {
      // Find row with matching value
      final length = widget.dataSource!.rowCount;
      for (int i = 0; i < length; i++) {
        final row = widget.dataSource![i];
        final rowValue = row[valueMember];
        if (rowValue?.toString() == currentValue?.toString()) {
          final displayText = row[displayMember]?.toString() ?? '';

          return displayText;
        }
      }
      // ignore: empty_catches
    } catch (e) {}

    return widget.hint ?? '';
  }

  /// Update selected value
  void _updateValue(dynamic newValue) {
    if (!widget.enabled) {
      return;
    }

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

  /// Show picker bottom sheet
  Future<void> _showPicker() async {
    if (!widget.enabled || widget.dataSource == null) return;

    final valueMember = _getValueMember();
    final displayMember = _getDisplayMember();

    if (valueMember.isEmpty || displayMember.isEmpty) {
      return;
    }

    final currentValue = _getCurrentValue();

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _IOSPickerSheet(
        dataSource: widget.dataSource!,
        valueMember: valueMember,
        displayMember: displayMember,
        currentValue: currentValue,
        onSelected: (value) {
          _updateValue(value);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible()) {
      return const SizedBox.shrink();
    }
    Widget buildComboBox() {
      final displayText = _getDisplayText();
      final hasValue = displayText.isNotEmpty && displayText != widget.hint;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label
          if (widget.isShowLabel &&
              widget.label != null &&
              widget.label!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
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

          // ComboBox
          InkWell(
            onTap: widget.enabled ? _showPicker : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                // ✅ Background đồng bộ, bỏ border
                color: widget.enabled
                    ? (widget.backgroundColor ?? const Color(0xFFF5F5F5))
                    : const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  // Icon (optional)
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      color: widget.enabled
                          ? (widget.iconColor ?? Colors.grey[600])
                          : Colors.grey[400],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                  ],

                  // Display text
                  Expanded(
                    child: Text(
                      displayText,
                      style:
                          widget.textStyle ??
                          TextStyle(
                            fontSize: 16,
                            color: hasValue
                                ? (widget.enabled
                                      ? Colors.black87
                                      : Colors.grey)
                                : Colors.grey[500],
                          ),
                    ),
                  ),

                  // Dropdown arrow
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: widget.enabled ? Colors.grey[600] : Colors.grey[400],
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // ✅ Wrap với ListenableBuilder nếu có binding
    if (_boundRow != null) {
      return ListenableBuilder(
        listenable: _boundRow!,
        builder: (context, child) => buildComboBox(),
      );
    }

    return buildComboBox();
  }
}

/// iOS-style Picker Bottom Sheet
class _IOSPickerSheet extends StatefulWidget {
  final CyberDataTable dataSource;
  final String valueMember;
  final String displayMember;
  final dynamic currentValue;
  final ValueChanged<dynamic> onSelected;

  const _IOSPickerSheet({
    required this.dataSource,
    required this.valueMember,
    required this.displayMember,
    required this.currentValue,
    required this.onSelected,
  });

  @override
  State<_IOSPickerSheet> createState() => _IOSPickerSheetState();
}

class _IOSPickerSheetState extends State<_IOSPickerSheet> {
  late FixedExtentScrollController _scrollController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    // Find current value index
    _selectedIndex = 0;
    for (int i = 0; i < widget.dataSource.rowCount; i++) {
      final row = widget.dataSource[i];
      final rowValue = row[widget.valueMember];
      if (rowValue?.toString() == widget.currentValue?.toString()) {
        _selectedIndex = i;
        break;
      }
    }

    _scrollController = FixedExtentScrollController(
      initialItem: _selectedIndex,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<Widget> _buildPickerItems() {
    List<Widget> items = [];

    final length = widget.dataSource.rowCount;
    for (int i = 0; i < length; i++) {
      final row = widget.dataSource[i];
      final displayText = row[widget.displayMember]?.toString() ?? '';
      final rowValue = row[widget.valueMember];
      final isSelected =
          rowValue?.toString() == widget.currentValue?.toString();

      items.add(
        Center(
          child: Text(
            displayText,
            style: TextStyle(
              fontSize: 18,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.blue : Colors.black87,
            ),
          ),
        ),
      );
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                TextButton(
                  onPressed: () {
                    final selectedRow = widget.dataSource[_selectedIndex];
                    final selectedValue = selectedRow[widget.valueMember];
                    widget.onSelected(selectedValue);
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Xong',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Picker
          SizedBox(
            height: 250,
            child: CupertinoPicker(
              scrollController: _scrollController,
              itemExtent: 44,
              onSelectedItemChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              children: _buildPickerItems(),
            ),
          ),

          // Bottom padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
