// lib/Controller/cybercombobox.dart

import 'package:cyberframework/cyberframework.dart';
import 'package:flutter/cupertino.dart';

class CyberComboBox extends StatefulWidget {
  final dynamic text;
  final dynamic display;
  final CyberComboBoxController? controller;
  final dynamic displayMember;
  final dynamic valueMember;
  final CyberDataTable? dataSource;
  final dynamic strFilter;
  final String? label;
  final String? hint;
  final TextStyle? labelStyle;
  final TextStyle? textStyle;
  final String? prefixIcon;
  final int? borderSize;
  final int? borderRadius;
  final bool enabled;
  final ValueChanged<dynamic>? onChanged;
  final Function(dynamic)? onLeaver;
  final Color? iconColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool isShowLabel;
  final dynamic isVisible;
  final dynamic isCheckEmpty;

  const CyberComboBox({
    super.key,
    this.text,
    this.display,
    this.controller,
    this.displayMember,
    this.valueMember,
    this.dataSource,
    this.strFilter,
    this.label,
    this.hint,
    this.labelStyle,
    this.textStyle,
    this.prefixIcon,
    this.borderSize = 1,
    this.borderRadius,
    this.enabled = true,
    this.onChanged,
    this.onLeaver,
    this.iconColor,
    this.backgroundColor,
    this.borderColor = Colors.transparent,
    this.isShowLabel = true,
    this.isVisible = true,
    this.isCheckEmpty = false,
  });

  @override
  State<CyberComboBox> createState() => _CyberComboBoxState();
}

class _CyberComboBoxState extends State<CyberComboBox> {
  // ============================================================================
  // BINDING STATE
  // ============================================================================

  CyberDataRow? _boundRow;
  String? _boundField;
  CyberDataRow? _displayBoundRow;
  String? _displayBoundField;
  CyberDataRow? _visibilityBoundRow;
  String? _visibilityBoundField;
  CyberDataRow? _filterBoundRow;
  String? _filterBoundField;
  bool _isUpdating = false;

  // ============================================================================
  // CONTROLLER STATE
  // ============================================================================

  late final CyberComboBoxController _internalController;

  CyberComboBoxController get _controller =>
      widget.controller ?? _internalController;

  // ============================================================================
  // MULTI-SELECT STATE
  // ============================================================================

  /// Tự động phát hiện multi-select khi dataSource có cột "ischon"
  bool get _isMultiSelect {
    final ds = widget.dataSource ?? _controller.dataSource;
    if (ds == null) return false;
    return ds.containerColumn("ischon");
  }

  // ============================================================================
  // LIFECYCLE
  // ============================================================================

  @override
  void initState() {
    super.initState();

    _internalController = CyberComboBoxController(
      value: _getInitialValue(),
      displayValue: _getInitialDisplayValue(),
      enabled: widget.enabled,
      dataSource: widget.dataSource,
      displayMember: _getDisplayMember(),
      valueMember: _getValueMember(),
      strFilter: _getFilterString(),
    );

    _parseBinding();
    _parseDisplayBinding();
    _parseVisibilityBinding();
    _parseFilterBinding();
    _registerListeners();
  }

  @override
  void didUpdateWidget(CyberComboBox oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.text != oldWidget.text) {
      _unregisterListeners();
      _parseBinding();
      _registerListeners();
      if (!_isUpdating) _syncFromBinding();
    }

    if (widget.display != oldWidget.display) {
      _unregisterDisplayListeners();
      _parseDisplayBinding();
      _registerDisplayListeners();
      if (!_isUpdating) _syncFromDisplayBinding();
    }

    if (widget.isVisible != oldWidget.isVisible) {
      _parseVisibilityBinding();
    }

    if (widget.strFilter != oldWidget.strFilter) {
      _unregisterFilterListeners();
      _parseFilterBinding();
      _registerFilterListeners();
      if (!_isUpdating && widget.controller == null) {
        _internalController.setFilter(_getFilterString());
      }
    }

    if (widget.controller == null) {
      if (widget.dataSource != oldWidget.dataSource) {
        _internalController.setDataSource(widget.dataSource);
      }
      if (widget.displayMember != oldWidget.displayMember) {
        _internalController.setDisplayMember(_getDisplayMember());
      }
      if (widget.valueMember != oldWidget.valueMember) {
        _internalController.setValueMember(_getValueMember());
      }
      if (widget.enabled != oldWidget.enabled) {
        _internalController.setEnabled(widget.enabled);
      }
      if (widget.strFilter != oldWidget.strFilter) {
        _internalController.setFilter(_getFilterString());
      }
    }
  }

  @override
  void dispose() {
    _unregisterListeners();
    _unregisterDisplayListeners();
    _unregisterFilterListeners();
    _internalController.dispose();
    super.dispose();
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

  void _parseDisplayBinding() {
    if (widget.display is CyberBindingExpression) {
      final expr = widget.display as CyberBindingExpression;
      _displayBoundRow = expr.row;
      _displayBoundField = expr.fieldName;
    } else {
      _displayBoundRow = null;
      _displayBoundField = null;
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

  void _parseFilterBinding() {
    if (widget.strFilter is CyberBindingExpression) {
      final expr = widget.strFilter as CyberBindingExpression;
      _filterBoundRow = expr.row;
      _filterBoundField = expr.fieldName;
    } else {
      _filterBoundRow = null;
      _filterBoundField = null;
    }
  }

  void _registerListeners() {
    _boundRow?.addListener(_onBindingChanged);
    if (_visibilityBoundRow != null && _visibilityBoundRow != _boundRow) {
      _visibilityBoundRow!.addListener(_onVisibilityChanged);
    }
    _controller.addListener(_onControllerChanged);
  }

  void _registerDisplayListeners() {
    if (_displayBoundRow != null && _displayBoundRow != _boundRow) {
      _displayBoundRow!.addListener(_onDisplayBindingChanged);
    }
  }

  void _registerFilterListeners() {
    if (_filterBoundRow != null &&
        _filterBoundRow != _boundRow &&
        _filterBoundRow != _displayBoundRow &&
        _filterBoundRow != _visibilityBoundRow) {
      _filterBoundRow!.addListener(_onFilterBindingChanged);
    }
  }

  void _unregisterListeners() {
    _boundRow?.removeListener(_onBindingChanged);
    if (_visibilityBoundRow != null && _visibilityBoundRow != _boundRow) {
      _visibilityBoundRow!.removeListener(_onVisibilityChanged);
    }
    _controller.removeListener(_onControllerChanged);
  }

  void _unregisterDisplayListeners() {
    if (_displayBoundRow != null && _displayBoundRow != _boundRow) {
      _displayBoundRow!.removeListener(_onDisplayBindingChanged);
    }
  }

  void _unregisterFilterListeners() {
    if (_filterBoundRow != null &&
        _filterBoundRow != _boundRow &&
        _filterBoundRow != _displayBoundRow &&
        _filterBoundRow != _visibilityBoundRow) {
      _filterBoundRow!.removeListener(_onFilterBindingChanged);
    }
  }

  // ============================================================================
  // LISTENERS
  // ============================================================================

  void _onBindingChanged() {
    if (_isUpdating) return;
    _syncFromBinding();
  }

  void _onDisplayBindingChanged() {
    if (_isUpdating) return;
    _syncFromDisplayBinding();
  }

  void _onVisibilityChanged() {
    if (_isUpdating) return;
    setState(() {});
  }

  void _onFilterBindingChanged() {
    if (_isUpdating) return;
    _syncFromFilterBinding();
  }

  void _onControllerChanged() {
    if (_isUpdating) return;
    _syncToBinding();
  }

  // ============================================================================
  // SYNC LOGIC
  // ============================================================================

  void _syncFromBinding() {
    if (_boundRow == null || _boundField == null) return;
    _isUpdating = true;
    try {
      final bindingValue = _boundRow![_boundField!];
      if (_controller.value != bindingValue) {
        if (widget.controller == null) {
          _internalController.setValue(bindingValue);
        }
        setState(() {});
      }
    } finally {
      _isUpdating = false;
    }
  }

  void _syncFromDisplayBinding() {
    if (_displayBoundRow == null || _displayBoundField == null) return;
    _isUpdating = true;
    try {
      final bindingValue =
          _displayBoundRow![_displayBoundField!]?.toString() ?? '';
      if (_controller.displayValue != bindingValue) {
        if (widget.controller == null) {
          _internalController.setDisplayValue(bindingValue);
        }
        setState(() {});
      }
    } finally {
      _isUpdating = false;
    }
  }

  void _syncFromFilterBinding() {
    if (_filterBoundRow == null || _filterBoundField == null) return;
    _isUpdating = true;
    try {
      final bindingValue = _filterBoundRow![_filterBoundField!]?.toString();
      if (_controller.strFilter != bindingValue) {
        if (widget.controller == null) {
          _internalController.setFilter(bindingValue);
        }
        setState(() {});
      }
    } finally {
      _isUpdating = false;
    }
  }

  void _syncToBinding() {
    _isUpdating = true;
    try {
      final controllerValue = _controller.value;
      final controllerDisplayValue = _controller.displayValue;

      if (_boundRow != null && _boundField != null) {
        final bindingValue = _boundRow![_boundField!];
        if (bindingValue != controllerValue) {
          if (bindingValue is String && controllerValue != null) {
            _boundRow![_boundField!] = controllerValue.toString();
          } else if (bindingValue is int && controllerValue is int) {
            _boundRow![_boundField!] = controllerValue;
          } else if (bindingValue is double && controllerValue is num) {
            _boundRow![_boundField!] = controllerValue.toDouble();
          } else {
            _boundRow![_boundField!] = controllerValue;
          }
        }
      }

      if (_displayBoundRow != null && _displayBoundField != null) {
        final displayBindingValue = _displayBoundRow![_displayBoundField!];
        if (displayBindingValue?.toString() != controllerDisplayValue) {
          if (displayBindingValue is String) {
            _displayBoundRow![_displayBoundField!] = controllerDisplayValue;
          } else {
            _displayBoundRow![_displayBoundField!] = controllerDisplayValue;
          }
        }
      }

      setState(() {});
    } finally {
      _isUpdating = false;
    }
  }

  // ============================================================================
  // VALUE GETTERS
  // ============================================================================

  dynamic _getInitialValue() {
    if (widget.text is CyberBindingExpression) {
      final expr = widget.text as CyberBindingExpression;
      try {
        return expr.row[expr.fieldName];
      } catch (e) {
        return null;
      }
    }
    if (widget.text != null && widget.text is! CyberBindingExpression) {
      return widget.text;
    }
    return null;
  }

  String _getInitialDisplayValue() {
    if (widget.display is CyberBindingExpression) {
      final expr = widget.display as CyberBindingExpression;
      try {
        return expr.row[expr.fieldName]?.toString() ?? '';
      } catch (e) {
        return '';
      }
    }
    if (widget.display != null && widget.display is! CyberBindingExpression) {
      return widget.display.toString();
    }
    return '';
  }

  dynamic _getCurrentValue() {
    if (_boundRow != null && _boundField != null) {
      try {
        return _boundRow![_boundField!];
      } catch (e) {
        return null;
      }
    }
    return _controller.value;
  }

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

  String? _getFilterString() {
    if (widget.strFilter is CyberBindingExpression) {
      final expr = widget.strFilter as CyberBindingExpression;
      try {
        return expr.row[expr.fieldName]?.toString();
      } catch (e) {
        return null;
      }
    }
    if (widget.strFilter != null &&
        widget.strFilter is! CyberBindingExpression) {
      return widget.strFilter.toString();
    }
    return null;
  }

  /// Get display text - hỗ trợ cả single và multi (join ';')
  String _getDisplayText() {
    final currentValue = _getCurrentValue();
    final dataSource = widget.dataSource ?? _controller.dataSource;

    if (currentValue == null || dataSource == null) {
      return widget.hint ?? '';
    }

    final valueMember = _getValueMember();
    final displayMember = _getDisplayMember();
    if (valueMember.isEmpty || displayMember.isEmpty) return widget.hint ?? '';

    try {
      final filteredRows = _controller.getFilteredRows();

      // Multi-select: value là chuỗi join bằng ';'
      if (_isMultiSelect) {
        final selectedValues = currentValue
            .toString()
            .split(';')
            .map((e) => e.trim())
            .toSet();
        final displayParts = <String>[];

        for (var row in filteredRows) {
          final rowValue = row[valueMember]?.toString() ?? '';
          if (selectedValues.contains(rowValue)) {
            final displayVal = row[displayMember]?.toString() ?? '';
            if (displayVal.isNotEmpty) displayParts.add(displayVal);
          }
        }
        return displayParts.isNotEmpty
            ? displayParts.join('; ')
            : (widget.hint ?? '');
      }

      // Single-select
      for (var row in filteredRows) {
        final rowValue = row[valueMember];
        if (rowValue?.toString() == currentValue?.toString()) {
          return row[displayMember]?.toString() ?? '';
        }
      }
    } catch (e) {
      debugPrint('❌ Get display text error: $e');
    }

    return widget.hint ?? '';
  }

  // ============================================================================
  // VISIBILITY
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

  bool _isCheckEmpty() => _parseBool(widget.isCheckEmpty);

  bool _isVisible() {
    if (_visibilityBoundRow != null && _visibilityBoundField != null) {
      return _parseBool(_visibilityBoundRow![_visibilityBoundField!]);
    }
    return _parseBool(widget.isVisible);
  }

  // ============================================================================
  // UPDATE VALUE
  // ============================================================================

  /// Single select: update 1 value
  void _updateValue(dynamic newValue) {
    final isEnabled = widget.enabled && _controller.enabled;
    if (!isEnabled) return;

    _isUpdating = true;
    try {
      final dataSource = widget.dataSource ?? _controller.dataSource;
      final valueMember = _getValueMember();
      final displayMember = _getDisplayMember();

      String newDisplayText = '';
      if (newValue != null &&
          dataSource != null &&
          valueMember.isNotEmpty &&
          displayMember.isNotEmpty) {
        try {
          final filteredRows = _controller.getFilteredRows();
          for (var row in filteredRows) {
            final rowValue = row[valueMember];
            if (rowValue?.toString() == newValue?.toString()) {
              newDisplayText = row[displayMember]?.toString() ?? '';
              break;
            }
          }
        } catch (e) {
          debugPrint('❌ Find display text error: $e');
        }
      }

      _applyValue(newValue, newDisplayText);
    } finally {
      _isUpdating = false;
    }
  }

  /// Multi select: update danh sách values (join ';')
  void _updateMultiValues(Set<dynamic> selectedValues) {
    final isEnabled = widget.enabled && _controller.enabled;
    if (!isEnabled) return;

    _isUpdating = true;
    try {
      final valueMember = _getValueMember();
      final displayMember = _getDisplayMember();
      final filteredRows = _controller.getFilteredRows();

      final displayParts = <String>[];
      final valueParts = <String>[];

      for (var row in filteredRows) {
        final rowValue = row[valueMember]?.toString() ?? '';
        if (selectedValues.map((e) => e.toString()).contains(rowValue)) {
          final displayVal = row[displayMember]?.toString() ?? '';
          if (displayVal.isNotEmpty) displayParts.add(displayVal);
          if (rowValue.isNotEmpty) valueParts.add(rowValue);
        }
      }

      final joinedValue = valueParts.join(';');
      final joinedDisplay = displayParts.join('; ');

      _applyValue(joinedValue, joinedDisplay);
    } finally {
      _isUpdating = false;
    }
  }

  /// Áp dụng value + display vào controller và bindings
  void _applyValue(dynamic newValue, String newDisplayText) {
    if (widget.controller == null) {
      _internalController.setValue(newValue);
      _internalController.setDisplayValue(newDisplayText);
    } else {
      widget.controller!.setValue(newValue);
      widget.controller!.setDisplayValue(newDisplayText);
    }

    // Update text binding
    if (_boundRow != null && _boundField != null) {
      final originalValue = _boundRow![_boundField!];
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

    // Update display binding
    if (_displayBoundRow != null && _displayBoundField != null) {
      _displayBoundRow![_displayBoundField!] = newDisplayText;
    }

    widget.onChanged?.call(newValue);
    widget.onLeaver?.call(newValue);

    setState(() {});
  }

  // ============================================================================
  // SHOW PICKER
  // ============================================================================

  Future<void> _showPicker() async {
    final isEnabled = widget.enabled && _controller.enabled;
    final dataSource = widget.dataSource ?? _controller.dataSource;

    if (!isEnabled || dataSource == null) return;

    final valueMember = _getValueMember();
    final displayMember = _getDisplayMember();
    if (valueMember.isEmpty || displayMember.isEmpty) return;

    final filteredRows = _controller.getFilteredRows();

    if (filteredRows.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không có dữ liệu phù hợp với điều kiện lọc'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    final currentValue = _getCurrentValue();

    if (_isMultiSelect) {
      // === MULTI-SELECT: bottom sheet với checkbox ===
      final currentSelected = currentValue != null
          ? currentValue
                .toString()
                .split(';')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toSet()
          : <String>{};

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _MultiSelectSheet(
          filteredRows: filteredRows,
          valueMember: valueMember,
          displayMember: displayMember,
          initialSelected: currentSelected,
          onConfirm: (selectedValues) {
            _updateMultiValues(selectedValues);
          },
        ),
      );
    } else {
      // === SINGLE-SELECT: iOS Cupertino Picker với search ===
      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        // isScrollControlled để sheet mở rộng khi keyboard xuất hiện
        isScrollControlled: true,
        builder: (context) => _IOSPickerSheet(
          filteredRows: filteredRows,
          valueMember: valueMember,
          displayMember: displayMember,
          currentValue: currentValue,
          onSelected: (value) {
            _updateValue(value);
          },
        ),
      );
    }
  }

  // ============================================================================
  // BUILD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    if (!_isVisible()) return const SizedBox.shrink();

    final dataSource = widget.dataSource ?? _controller.dataSource;

    return ListenableBuilder(
      listenable: Listenable.merge([
        _controller,
        ?dataSource,
        ?_boundRow,
        if (_displayBoundRow != null && _displayBoundRow != _boundRow)
          _displayBoundRow!,
        if (_visibilityBoundRow != null &&
            _visibilityBoundRow != _boundRow &&
            _visibilityBoundRow != _displayBoundRow)
          _visibilityBoundRow!,
        if (_filterBoundRow != null &&
            _filterBoundRow != _boundRow &&
            _filterBoundRow != _displayBoundRow &&
            _filterBoundRow != _visibilityBoundRow)
          _filterBoundRow!,
      ]),
      builder: (context, _) {
        final displayText = _getDisplayText();
        final hasValue = displayText.isNotEmpty && displayText != widget.hint;
        final isEnabled = widget.enabled && _controller.enabled;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isShowLabel &&
                widget.label != null &&
                widget.label!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
                child: Row(
                  children: [
                    Text(
                      widget.label!,
                      style:
                          widget.labelStyle ??
                          const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF555555),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    if (_isCheckEmpty())
                      Text(
                        ' *',
                        style: TextStyle(
                          fontSize: 14,
                          color: Appinfo.textColorOrangeDefault,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            InkWell(
              onTap: isEnabled ? _showPicker : null,
              borderRadius: BorderRadius.circular(
                widget.borderRadius?.toDouble() ?? 4.0,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: _buildDecoration(isEnabled),
                child: Row(
                  children: [
                    if (widget.prefixIcon != null) ...[
                      Icon(
                        v_parseIcon(widget.prefixIcon!),
                        color: isEnabled
                            ? (widget.iconColor ?? Colors.grey[600])
                            : Colors.grey[400],
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        displayText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            widget.textStyle ??
                            TextStyle(
                              fontSize: 15,
                              color: hasValue
                                  ? (isEnabled ? Colors.black87 : Colors.grey)
                                  : Colors.grey.shade500,
                              fontWeight: hasValue ? null : FontWeight.w400,
                            ),
                      ),
                    ),
                    Icon(
                      _isMultiSelect
                          ? Icons.checklist_rounded
                          : Icons.keyboard_arrow_down,
                      color: isEnabled ? Colors.grey[600] : Colors.grey[400],
                      size: 24,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  BoxDecoration _buildDecoration(bool isEnabled) {
    final borderWidth = widget.borderSize?.toDouble() ?? 0.0;
    final radius = widget.borderRadius?.toDouble() ?? 4.0;
    final effectiveBorderColor = widget.borderColor ?? Colors.grey;

    return BoxDecoration(
      color: isEnabled
          ? (widget.backgroundColor ?? const Color(0xFFF5F5F5))
          : const Color(0xFFE0E0E0),
      borderRadius: BorderRadius.circular(radius),
      border: borderWidth > 0
          ? Border.all(color: effectiveBorderColor, width: borderWidth)
          : null,
    );
  }
}

// ============================================================================
// MULTI SELECT SHEET - Tương tự CyberLookup
// ============================================================================

class _MultiSelectSheet extends StatefulWidget {
  final List<CyberDataRow> filteredRows;
  final String valueMember;
  final String displayMember;
  final Set<String> initialSelected;
  final ValueChanged<Set<dynamic>> onConfirm;

  const _MultiSelectSheet({
    required this.filteredRows,
    required this.valueMember,
    required this.displayMember,
    required this.initialSelected,
    required this.onConfirm,
  });

  @override
  State<_MultiSelectSheet> createState() => _MultiSelectSheetState();
}

class _MultiSelectSheetState extends State<_MultiSelectSheet> {
  late Set<String> _selectedValues;
  final TextEditingController _searchController = TextEditingController();
  List<CyberDataRow> _filteredRows = [];

  @override
  void initState() {
    super.initState();
    _selectedValues = Set.from(widget.initialSelected);
    _filteredRows = List.from(widget.filteredRows);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredRows = List.from(widget.filteredRows);
      } else {
        final lower = query.toLowerCase();
        _filteredRows = widget.filteredRows.where((row) {
          final display =
              row[widget.displayMember]?.toString().toLowerCase() ?? '';
          final value = row[widget.valueMember]?.toString().toLowerCase() ?? '';
          return display.contains(lower) || value.contains(lower);
        }).toList();
      }
    });
  }

  void _toggleItem(String value) {
    setState(() {
      if (_selectedValues.contains(value)) {
        _selectedValues.remove(value);
      } else {
        _selectedValues.add(value);
      }
    });
  }

  void _confirm() {
    if (_selectedValues.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 mục')),
      );
      return;
    }
    widget.onConfirm(_selectedValues);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Chọn nhiều mục',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_selectedValues.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      'Đã chọn: ${_selectedValues.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm trong danh sách...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onChanged: _onSearch,
            ),
          ),

          const SizedBox(height: 8),

          // List
          Expanded(
            child: _filteredRows.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inbox, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          _searchController.text.isNotEmpty
                              ? 'Không tìm thấy kết quả'
                              : 'Không có dữ liệu',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: _filteredRows.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey[200],
                    ),
                    itemBuilder: (context, index) {
                      final row = _filteredRows[index];
                      final value = row[widget.valueMember]?.toString() ?? '';
                      final display =
                          row[widget.displayMember]?.toString() ?? '';
                      final isSelected = _selectedValues.contains(value);

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (_) => _toggleItem(value),
                        title: Text(
                          display,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          value,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        selected: isSelected,
                        selectedTileColor: Colors.blue[50],
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: Colors.blue,
                      );
                    },
                  ),
          ),

          // Confirm button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Xác nhận (${_selectedValues.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// IOS PICKER SHEET - Single select với search (hiện khi > 10 bản ghi)
// ============================================================================

class _IOSPickerSheet extends StatefulWidget {
  final List<CyberDataRow> filteredRows;
  final String valueMember;
  final String displayMember;
  final dynamic currentValue;
  final ValueChanged<dynamic> onSelected;

  const _IOSPickerSheet({
    required this.filteredRows,
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
  final TextEditingController _searchController = TextEditingController();
  int _selectedIndex = 0;

  /// Danh sách rows sau khi filter search
  late List<CyberDataRow> _displayRows;

  /// Số bản ghi tối thiểu để hiển thị ô tìm kiếm
  static const int _searchThreshold = 10;

  bool get _showSearch => widget.filteredRows.length > _searchThreshold;

  @override
  void initState() {
    super.initState();
    _displayRows = List.from(widget.filteredRows);
    _initSelectedIndex();
    _scrollController = FixedExtentScrollController(
      initialItem: _selectedIndex,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Tìm index của giá trị hiện tại trong _displayRows
  void _initSelectedIndex() {
    _selectedIndex = 0;
    for (int i = 0; i < _displayRows.length; i++) {
      final rowValue = _displayRows[i][widget.valueMember];
      if (rowValue?.toString() == widget.currentValue?.toString()) {
        _selectedIndex = i;
        break;
      }
    }
  }

  /// Row đang được focus trong picker
  CyberDataRow? get _selectedRow {
    if (_displayRows.isEmpty) return null;
    final safeIndex = _selectedIndex.clamp(0, _displayRows.length - 1);
    return _displayRows[safeIndex];
  }

  /// Xử lý tìm kiếm theo displayMember
  void _onSearch(String query) {
    final filtered = query.trim().isEmpty
        ? List<CyberDataRow>.from(widget.filteredRows)
        : widget.filteredRows.where((row) {
            final display =
                row[widget.displayMember]?.toString().toLowerCase() ?? '';
            return display.contains(query.trim().toLowerCase());
          }).toList();

    setState(() {
      _displayRows = filtered;
      _selectedIndex = 0;

      // Nếu có giá trị đang chọn, cố giữ vị trí
      if (widget.currentValue != null) {
        for (int i = 0; i < _displayRows.length; i++) {
          final rowValue = _displayRows[i][widget.valueMember];
          if (rowValue?.toString() == widget.currentValue?.toString()) {
            _selectedIndex = i;
            break;
          }
        }
      }
    });

    // Scroll đến vị trí mới sau khi rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _displayRows.isNotEmpty) {
        final safeIndex = _selectedIndex.clamp(0, _displayRows.length - 1);
        _scrollController.jumpToItem(safeIndex);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Padding bottom để tránh keyboard che mất picker
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Toolbar: Hủy / Search (hoặc preview) / Xong ─────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  // Nút Hủy
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy'),
                  ),

                  // Giữa: search box (> 10 bản ghi) hoặc tên item đang chọn
                  Expanded(
                    child: _showSearch
                        ? TextField(
                            controller: _searchController,
                            autofocus: false,
                            decoration: InputDecoration(
                              hintText: 'Tìm kiếm...',
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 16),
                                      onPressed: () {
                                        _searchController.clear();
                                        _onSearch('');
                                      },
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                            ),
                            onChanged: (value) {
                              setState(() {});
                              _onSearch(value);
                            },
                          )
                        : Text(
                            _selectedRow?[widget.displayMember]?.toString() ??
                                '',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                  ),

                  // Nút Xong
                  TextButton(
                    onPressed: () {
                      if (_selectedRow != null) {
                        widget.onSelected(_selectedRow![widget.valueMember]);
                      }
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

            // ── Picker ────────────────────────────────────────────────────
            _displayRows.isEmpty
                ? SizedBox(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.search_off, size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'Không tìm thấy kết quả',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                : SizedBox(
                    height: 220,
                    child: CupertinoPicker(
                      scrollController: _scrollController,
                      itemExtent: 44,
                      onSelectedItemChanged: (index) {
                        setState(() => _selectedIndex = index);
                      },
                      children: _displayRows.map((row) {
                        final displayText =
                            row[widget.displayMember]?.toString() ?? '';
                        final rowValue = row[widget.valueMember];
                        final isCurrentValue =
                            rowValue?.toString() ==
                            widget.currentValue?.toString();

                        return Center(
                          child: Text(
                            displayText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: isCurrentValue
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isCurrentValue
                                  ? Colors.blue
                                  : Colors.black87,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
