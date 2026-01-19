// lib/Controller/cyberradiogroup.dart

import 'package:cyberframework/cyberframework.dart';
import 'package:flutter/material.dart';

/// CyberRadioGroup - Radio group với multi-column hoặc single-column binding
///
/// **Multi-column mode (default):**
/// - Mỗi radio item bind vào 1 column riêng trong CyberDataRow
/// - Khi chọn item: column của item đó = selectedValue (default: 1)
/// - Các item khác: column = unselectedValue (default: 0)
/// - Tự động listen và update khi binding thay đổi
///
/// **Single-column mode:**
/// - Tất cả items bind vào cùng 1 column
/// - Mỗi item có value riêng
/// - Khi chọn item: column = value của item đó
///
/// **Mode Priority:**
/// - Group level `isSingleColumn` có priority cao nhất (override tất cả items)
/// - Nếu không set ở group level, dùng setting của từng item
/// - Default: Multi-column mode
///
/// Usage:
/// ```dart
/// // Multi-column mode (default)
/// CyberRadioGroup(
///   label: "Loại phương tiện",
///   items: [
///     CyberRadioItem(label: "Ô tô", binding: drEdit.bind("is_car")),
///     CyberRadioItem(label: "Xe máy", binding: drEdit.bind("is_motorcycle")),
///   ],
/// )
///
/// // Single-column mode - Set ở group level (RECOMMENDED)
/// CyberRadioGroup(
///   label: "Loại phương tiện",
///   isSingleColumn: true,  // ← Set 1 lần cho tất cả items
///   items: [
///     CyberRadioItem(
///       label: "Ô tô",
///       binding: drEdit.bind("vehicle_type"),
///       value: "car",
///     ),
///     CyberRadioItem(
///       label: "Xe máy",
///       binding: drEdit.bind("vehicle_type"),
///       value: "motorcycle",
///     ),
///   ],
/// )
///
/// // Single-column mode - Set ở item level (nếu cần control riêng lẻ)
/// CyberRadioGroup(
///   label: "Loại phương tiện",
///   items: [
///     CyberRadioItem(
///       label: "Ô tô",
///       binding: drEdit.bind("vehicle_type"),
///       value: "car",
///       isSingleColumn: true,  // ← Set cho từng item
///     ),
///     CyberRadioItem(
///       label: "Xe máy",
///       binding: drEdit.bind("vehicle_type"),
///       value: "motorcycle",
///       isSingleColumn: true,
///     ),
///   ],
/// )
/// ```
class CyberRadioGroup extends StatefulWidget {
  /// Danh sách radio items
  final List<CyberRadioItem> items;

  /// Label hiển thị phía trên
  final String? label;

  /// Hướng hiển thị (horizontal/vertical)
  final Axis direction;

  /// Spacing giữa các items
  final double spacing;

  /// Label style
  final TextStyle? labelStyle;

  /// Item text style
  final TextStyle? itemTextStyle;

  /// Selected item text style
  final TextStyle? selectedItemTextStyle;

  /// Radio button color
  final Color? activeColor;

  /// Callback khi selection thay đổi
  /// Trả về index của item được chọn
  final ValueChanged<int>? onChanged;

  /// Visible (có thể binding)
  final dynamic isVisible;

  /// Check empty
  final dynamic isCheckEmpty;

  /// Show label
  final bool isShowLabel;

  /// Enabled
  final bool enabled;

  /// Single-column mode cho tất cả items
  /// - true: Tất cả items sẽ bind vào cùng 1 column (mỗi item có value riêng)
  /// - false: Mỗi item bind vào column riêng (multi-column mode)
  /// - null: Dùng setting của từng item (default behavior)
  final bool? isSingleColumn;

  const CyberRadioGroup({
    super.key,
    required this.items,
    this.label,
    this.direction = Axis.horizontal,
    this.spacing = 12.0,
    this.labelStyle,
    this.itemTextStyle,
    this.selectedItemTextStyle,
    this.activeColor,
    this.onChanged,
    this.isVisible = true,
    this.isCheckEmpty = false,
    this.isShowLabel = true,
    this.enabled = true,
    this.isSingleColumn = true,
  });

  @override
  State<CyberRadioGroup> createState() => _CyberRadioGroupState();
}

class _CyberRadioGroupState extends State<CyberRadioGroup> {
  // ============================================================================
  // BINDING STATE
  // ============================================================================

  final List<CyberDataRow?> _boundRows = [];
  CyberDataRow? _visibilityBoundRow;
  String? _visibilityBoundField;
  bool _isUpdating = false;

  // ============================================================================
  // LIFECYCLE
  // ============================================================================

  @override
  void initState() {
    super.initState();
    _parseBindings();
    _parseVisibilityBinding();
    _registerListeners();
  }

  @override
  void didUpdateWidget(CyberRadioGroup oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if items changed
    if (widget.items != oldWidget.items) {
      _unregisterListeners();
      _parseBindings();
      _registerListeners();
    }

    // Check visibility binding
    if (widget.isVisible != oldWidget.isVisible) {
      _parseVisibilityBinding();
    }
  }

  @override
  void dispose() {
    _unregisterListeners();
    super.dispose();
  }

  // ============================================================================
  // BINDING MANAGEMENT
  // ============================================================================

  void _parseBindings() {
    _boundRows.clear();
    for (var item in widget.items) {
      final info = item.bindingInfo;
      _boundRows.add(info?.row);
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
    // Register listeners cho tất cả bound rows (unique)
    final uniqueRows = _boundRows.whereType<CyberDataRow>().toSet();
    for (var row in uniqueRows) {
      row.addListener(_onBindingChanged);
    }

    // Visibility binding
    if (_visibilityBoundRow != null &&
        !uniqueRows.contains(_visibilityBoundRow)) {
      _visibilityBoundRow!.addListener(_onVisibilityChanged);
    }
  }

  void _unregisterListeners() {
    final uniqueRows = _boundRows.whereType<CyberDataRow>().toSet();
    for (var row in uniqueRows) {
      row.removeListener(_onBindingChanged);
    }

    if (_visibilityBoundRow != null &&
        !uniqueRows.contains(_visibilityBoundRow)) {
      _visibilityBoundRow!.removeListener(_onVisibilityChanged);
    }
  }

  // ============================================================================
  // LISTENERS
  // ============================================================================

  void _onBindingChanged() {
    if (_isUpdating) return;
    setState(() {}); // Rebuild when any binding changes
  }

  void _onVisibilityChanged() {
    if (_isUpdating) return;
    setState(() {});
  }

  // ============================================================================
  // SELECTION LOGIC
  // ============================================================================

  /// Kiểm tra mode của item (group level override item level nếu có)
  bool _isItemSingleColumn(CyberRadioItem item) {
    // Group level có set? → Dùng group level
    if (widget.isSingleColumn != null) {
      return widget.isSingleColumn!;
    }
    // Không có group level → Dùng item level
    return item.isSingleColumn;
  }

  /// Kiểm tra item có được chọn không (với group mode override)
  bool _isItemSelected(CyberRadioItem item) {
    final info = item.bindingInfo;
    if (info == null) return false;

    try {
      final currentValue = info.row[info.fieldName];
      final isSingleColumn = _isItemSingleColumn(item);

      // Single-column mode: so sánh với value
      if (isSingleColumn && item.value != null) {
        return _compareValue(currentValue, item.value);
      }

      // Multi-column mode: so sánh với selectedValue
      return _compareValue(currentValue, item.selectedValue);
    } catch (e) {
      return false;
    }
  }

  /// Select một item (với group mode override)
  void _selectItemValue(CyberRadioItem item) {
    final info = item.bindingInfo;
    if (info == null || !item.enabled) return;

    try {
      final currentValue = info.row[info.fieldName];
      final isSingleColumn = _isItemSingleColumn(item);

      // Single-column mode: set = value của item
      if (isSingleColumn && item.value != null) {
        _setFieldValue(info, currentValue, item.value);
        return;
      }

      // Multi-column mode: set = selectedValue
      _setFieldValue(info, currentValue, item.selectedValue);
    } catch (e) {
      // Ignore
    }
  }

  /// Unselect một item (với group mode override)
  void _unselectItemValue(CyberRadioItem item) {
    final isSingleColumn = _isItemSingleColumn(item);

    // Single-column mode: không cần unselect
    if (isSingleColumn) return;

    // Multi-column mode: set = unselectedValue
    final info = item.bindingInfo;
    if (info == null) return;

    try {
      final currentValue = info.row[info.fieldName];
      _setFieldValue(info, currentValue, item.unselectedValue);
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
    if (a is num && b is num) return a == b;
    if (a is bool && b is bool) return a == b;
    return a.toString() == b.toString();
  }

  /// Lấy index của item đang được chọn
  int? _getSelectedIndex() {
    for (int i = 0; i < widget.items.length; i++) {
      if (_isItemSelected(widget.items[i])) {
        return i;
      }
    }
    return null;
  }

  /// Select một item và unselect tất cả các item khác
  void _selectItem(int index) {
    if (!widget.enabled) return;
    if (index < 0 || index >= widget.items.length) return;

    final selectedItem = widget.items[index];
    if (!selectedItem.enabled) return;

    _isUpdating = true;
    try {
      // Select item được chọn
      _selectItemValue(selectedItem);

      // Unselect tất cả các item khác
      for (int i = 0; i < widget.items.length; i++) {
        if (i != index) {
          _unselectItemValue(widget.items[i]);
        }
      }

      // Callback
      widget.onChanged?.call(index);

      setState(() {});
    } finally {
      _isUpdating = false;
    }
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

  bool _isCheckEmpty() {
    return _parseBool(widget.isCheckEmpty);
  }

  bool _isVisible() {
    if (_visibilityBoundRow != null && _visibilityBoundField != null) {
      return _parseBool(_visibilityBoundRow![_visibilityBoundField!]);
    }
    return _parseBool(widget.isVisible);
  }

  // ============================================================================
  // BUILD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    if (!_isVisible()) {
      return const SizedBox.shrink();
    }

    // Collect all unique rows to listen
    final uniqueRows = _boundRows.whereType<CyberDataRow>().toSet().toList();

    return ListenableBuilder(
      listenable: Listenable.merge([
        ...uniqueRows,
        if (_visibilityBoundRow != null &&
            !uniqueRows.contains(_visibilityBoundRow))
          _visibilityBoundRow!,
      ]),
      builder: (context, _) {
        final selectedIndex = _getSelectedIndex();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label
            if (widget.isShowLabel &&
                widget.label != null &&
                widget.label!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
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

            // Radio items
            widget.direction == Axis.horizontal
                ? _buildHorizontalLayout(selectedIndex)
                : _buildVerticalLayout(selectedIndex),
          ],
        );
      },
    );
  }

  Widget _buildHorizontalLayout(int? selectedIndex) {
    return Wrap(
      spacing: widget.spacing,
      runSpacing: 8.0,
      children: List.generate(
        widget.items.length,
        (index) => _buildRadioItem(index, selectedIndex == index),
      ),
    );
  }

  Widget _buildVerticalLayout(int? selectedIndex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        widget.items.length,
        (index) => Padding(
          padding: EdgeInsets.only(
            bottom: index < widget.items.length - 1 ? widget.spacing : 0,
          ),
          child: _buildRadioItem(index, selectedIndex == index),
        ),
      ),
    );
  }

  Widget _buildRadioItem(int index, bool isSelected) {
    final item = widget.items[index];
    final isItemEnabled = widget.enabled && item.enabled;

    return InkWell(
      onTap: isItemEnabled ? () => _selectItem(index) : null,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Radio button
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isItemEnabled
                      ? (isSelected
                            ? (widget.activeColor ??
                                  Theme.of(context).primaryColor)
                            : Colors.grey.shade400)
                      : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isItemEnabled
                              ? (widget.activeColor ??
                                    Theme.of(context).primaryColor)
                              : Colors.grey.shade300,
                        ),
                      ),
                    )
                  : null,
            ),

            const SizedBox(width: 8),

            // Icon (optional)
            if (item.icon != null) ...[
              Icon(
                v_parseIcon(item.icon!),
                size: 18,
                color: isItemEnabled
                    ? (isSelected
                          ? (widget.activeColor ??
                                Theme.of(context).primaryColor)
                          : Colors.grey.shade600)
                    : Colors.grey.shade400,
              ),
              const SizedBox(width: 6),
            ],

            // Label
            Text(
              item.label,
              style: isSelected
                  ? (widget.selectedItemTextStyle ??
                        TextStyle(
                          fontSize: 15,
                          color: isItemEnabled
                              ? Colors.black87
                              : Colors.grey.shade400,
                          fontWeight: FontWeight.w500,
                        ))
                  : (widget.itemTextStyle ??
                        TextStyle(
                          fontSize: 15,
                          color: isItemEnabled
                              ? Colors.black87
                              : Colors.grey.shade400,
                        )),
            ),
          ],
        ),
      ),
    );
  }
}
