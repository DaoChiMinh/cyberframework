import 'package:cyberframework/cyberframework.dart';
import 'package:flutter/cupertino.dart';

/// CyberComboBox - ComboBox widget với data binding và internal controller
///
/// Triết lý:
/// - Internal Controller: Widget tự quản lý state, không cần khai báo controller bên ngoài
/// - Binding Support: Hỗ trợ binding trực tiếp qua thuộc tính `text` và `display`
/// - External Controller: Optional, khi cần control từ code
///
/// Usage:
/// ```dart
/// // 1. Simple usage (không binding)
/// CyberComboBox(
///   text: "001",
///   dataSource: dtKhachHang,
///   valueMember: "ma_kh",
///   displayMember: "ten_kh",
/// )
///
/// // 2. Binding usage (ERP style) - UPDATE CẢ VALUE VÀ DISPLAY
/// CyberComboBox(
///   text: drEdit.bind("ma_kh"),           // Binding value field
///   display: drEdit.bind("ten_kh"),       // Binding display field
///   dataSource: dtKhachHang,
///   valueMember: "ma_kh",
///   displayMember: "ten_kh",
/// )
///
/// // 3. With external controller (advanced)
/// final controller = CyberComboBoxController();
/// CyberComboBox(
///   controller: controller,
///   dataSource: dtKhachHang,
///   valueMember: "ma_kh",
///   displayMember: "ten_kh",
/// )
/// ```
class CyberComboBox extends StatefulWidget {
  /// Binding đến field chứa giá trị được chọn (value binding)
  /// Có thể là: null, value trực tiếp, hoặc CyberBindingExpression
  final dynamic text;

  /// Binding đến field chứa display value (display text binding)
  /// Có thể là: null, value trực tiếp, hoặc CyberBindingExpression
  /// VD: drEdit.bind("ten_kh") để lưu tên khách hàng
  final dynamic display;

  /// Controller để quản lý state từ bên ngoài (optional)
  /// Nếu không cung cấp, widget tự tạo internal controller
  final CyberComboBoxController? controller;

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

  /// Icon code hiển thị bên trái (VD: "e853")
  final String? prefixIcon;

  /// Kích thước border (đơn vị: pixel)
  final int? borderSize;

  /// Border radius (đơn vị: pixel)
  final int? borderRadius;

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
  final dynamic isCheckEmpty;

  const CyberComboBox({
    super.key,
    this.text,
    this.display,
    this.controller,
    this.displayMember,
    this.valueMember,
    this.dataSource,
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
  bool _isUpdating = false;

  // ============================================================================
  // CONTROLLER STATE
  // ============================================================================

  /// Internal controller - luôn tồn tại
  late final CyberComboBoxController _internalController;

  /// Effective controller - ưu tiên external > internal
  CyberComboBoxController get _controller =>
      widget.controller ?? _internalController;

  // ============================================================================
  // LIFECYCLE
  // ============================================================================

  @override
  void initState() {
    super.initState();

    // ✅ Luôn tạo internal controller
    _internalController = CyberComboBoxController(
      value: _getInitialValue(),
      displayValue: _getInitialDisplayValue(),
      enabled: widget.enabled,
      dataSource: widget.dataSource,
      displayMember: _getDisplayMember(),
      valueMember: _getValueMember(),
    );

    // Parse binding
    _parseBinding();
    _parseDisplayBinding();
    _parseVisibilityBinding();

    // Đăng ký listeners
    _registerListeners();
  }

  @override
  void didUpdateWidget(CyberComboBox oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ✅ Kiểm tra text binding changes
    if (widget.text != oldWidget.text) {
      _unregisterListeners();
      _parseBinding();
      _registerListeners();

      // Sync initial value từ binding mới
      if (!_isUpdating) {
        _syncFromBinding();
      }
    }

    // ✅ Kiểm tra display binding changes
    if (widget.display != oldWidget.display) {
      _unregisterDisplayListeners();
      _parseDisplayBinding();
      _registerDisplayListeners();

      // Sync initial display value từ binding mới
      if (!_isUpdating) {
        _syncFromDisplayBinding();
      }
    }

    // ✅ Kiểm tra visibility binding changes
    if (widget.isVisible != oldWidget.isVisible) {
      _parseVisibilityBinding();
    }

    // ✅ Sync widget properties vào internal controller
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
    }
  }

  @override
  void dispose() {
    _unregisterListeners();
    _unregisterDisplayListeners();
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

  void _registerListeners() {
    // Text binding listener
    _boundRow?.addListener(_onBindingChanged);

    // Visibility binding listener
    if (_visibilityBoundRow != null && _visibilityBoundRow != _boundRow) {
      _visibilityBoundRow!.addListener(_onVisibilityChanged);
    }

    // Controller listener
    _controller.addListener(_onControllerChanged);
  }

  void _registerDisplayListeners() {
    // Display binding listener (chỉ register nếu khác text binding)
    if (_displayBoundRow != null && _displayBoundRow != _boundRow) {
      _displayBoundRow!.addListener(_onDisplayBindingChanged);
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
    setState(() {}); // Rebuild for visibility change
  }

  void _onControllerChanged() {
    if (_isUpdating) return;
    _syncToBinding();
  }

  // ============================================================================
  // SYNC LOGIC
  // ============================================================================

  /// Sync giá trị từ text binding vào controller
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

  /// Sync giá trị từ display binding vào controller
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

  /// Sync giá trị từ controller vào bindings
  void _syncToBinding() {
    _isUpdating = true;
    try {
      final controllerValue = _controller.value;
      final controllerDisplayValue = _controller.displayValue;

      // Sync text binding
      if (_boundRow != null && _boundField != null) {
        final bindingValue = _boundRow![_boundField!];

        if (bindingValue != controllerValue) {
          // Preserve original type
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

      // Sync display binding
      if (_displayBoundRow != null && _displayBoundField != null) {
        final displayBindingValue = _displayBoundRow![_displayBoundField!];

        if (displayBindingValue?.toString() != controllerDisplayValue) {
          // Preserve original type
          if (displayBindingValue is String) {
            _displayBoundRow![_displayBoundField!] = controllerDisplayValue;
          } else if (displayBindingValue is int &&
              controllerDisplayValue.isNotEmpty) {
            _displayBoundRow![_displayBoundField!] = int.tryParse(
              controllerDisplayValue,
            );
          } else if (displayBindingValue is double &&
              controllerDisplayValue.isNotEmpty) {
            _displayBoundRow![_displayBoundField!] = double.tryParse(
              controllerDisplayValue,
            );
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

  /// Get giá trị khởi tạo ban đầu cho text value
  dynamic _getInitialValue() {
    // Priority 1: Binding
    if (widget.text is CyberBindingExpression) {
      final expr = widget.text as CyberBindingExpression;
      try {
        return expr.row[expr.fieldName];
      } catch (e) {
        return null;
      }
    }

    // Priority 2: Direct value
    if (widget.text != null && widget.text is! CyberBindingExpression) {
      return widget.text;
    }

    return null;
  }

  /// Get giá trị khởi tạo ban đầu cho display value
  String _getInitialDisplayValue() {
    // Priority 1: Binding
    if (widget.display is CyberBindingExpression) {
      final expr = widget.display as CyberBindingExpression;
      try {
        return expr.row[expr.fieldName]?.toString() ?? '';
      } catch (e) {
        return '';
      }
    }

    // Priority 2: Direct value
    if (widget.display != null && widget.display is! CyberBindingExpression) {
      return widget.display.toString();
    }

    return '';
  }

  /// Get current value (ưu tiên binding > controller)
  dynamic _getCurrentValue() {
    // Priority 1: Binding (source of truth khi có binding)
    if (_boundRow != null && _boundField != null) {
      try {
        return _boundRow![_boundField!];
      } catch (e) {
        return null;
      }
    }

    // Priority 2: Controller
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

  /// Get display text cho value hiện tại
  String _getDisplayText() {
    final currentValue = _getCurrentValue();
    final dataSource = widget.dataSource ?? _controller.dataSource;

    if (currentValue == null || dataSource == null) {
      return widget.hint ?? '';
    }

    final valueMember = _getValueMember();
    final displayMember = _getDisplayMember();

    if (valueMember.isEmpty || displayMember.isEmpty) {
      return widget.hint ?? '';
    }

    try {
      final length = dataSource.rowCount;
      for (int i = 0; i < length; i++) {
        final row = dataSource[i];
        final rowValue = row[valueMember];
        if (rowValue?.toString() == currentValue?.toString()) {
          return row[displayMember]?.toString() ?? '';
        }
      }
    } catch (e) {
      // Ignore errors
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
  // UPDATE VALUE
  // ============================================================================

  /// Cập nhật giá trị mới (update cả value và display)
  void _updateValue(dynamic newValue) {
    final isEnabled = widget.enabled && _controller.enabled;
    if (!isEnabled) return;

    _isUpdating = true;
    try {
      final dataSource = widget.dataSource ?? _controller.dataSource;
      final valueMember = _getValueMember();
      final displayMember = _getDisplayMember();

      // Tìm display text tương ứng với value
      String newDisplayText = '';
      if (newValue != null &&
          dataSource != null &&
          valueMember.isNotEmpty &&
          displayMember.isNotEmpty) {
        try {
          final length = dataSource.rowCount;
          for (int i = 0; i < length; i++) {
            final row = dataSource[i];
            final rowValue = row[valueMember];
            if (rowValue?.toString() == newValue?.toString()) {
              newDisplayText = row[displayMember]?.toString() ?? '';
              break;
            }
          }
        } catch (e) {
          // Ignore errors
        }
      }

      // ✅ Update controller
      if (widget.controller == null) {
        _internalController.setValue(newValue);
        _internalController.setDisplayValue(newDisplayText);
      } else {
        widget.controller!.setValue(newValue);
        widget.controller!.setDisplayValue(newDisplayText);
      }

      // ✅ Update text binding
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

      // ✅ Update display binding
      if (_displayBoundRow != null && _displayBoundField != null) {
        final originalDisplayValue = _displayBoundRow![_displayBoundField!];

        // Preserve original type
        if (originalDisplayValue is String) {
          _displayBoundRow![_displayBoundField!] = newDisplayText;
        } else if (originalDisplayValue is int && newDisplayText.isNotEmpty) {
          _displayBoundRow![_displayBoundField!] = int.tryParse(newDisplayText);
        } else if (originalDisplayValue is double &&
            newDisplayText.isNotEmpty) {
          _displayBoundRow![_displayBoundField!] = double.tryParse(
            newDisplayText,
          );
        } else {
          _displayBoundRow![_displayBoundField!] = newDisplayText;
        }
      }

      // ✅ Callbacks
      widget.onChanged?.call(newValue);
      widget.onLeaver?.call(newValue);

      setState(() {});
    } finally {
      _isUpdating = false;
    }
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

    if (valueMember.isEmpty || displayMember.isEmpty) {
      return;
    }

    final currentValue = _getCurrentValue();

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _IOSPickerSheet(
        dataSource: dataSource,
        valueMember: valueMember,
        displayMember: displayMember,
        currentValue: currentValue,
        onSelected: (value) {
          _updateValue(value);
        },
      ),
    );
  }

  // ============================================================================
  // BUILD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    if (!_isVisible()) {
      return const SizedBox.shrink();
    }

    final dataSource = widget.dataSource ?? _controller.dataSource;

    // ✅ Lắng nghe tất cả thay đổi
    return ListenableBuilder(
      listenable: Listenable.merge([
        _controller,
        if (dataSource != null) dataSource,
        if (_boundRow != null) _boundRow!,
        if (_displayBoundRow != null && _displayBoundRow != _boundRow)
          _displayBoundRow!,
        if (_visibilityBoundRow != null &&
            _visibilityBoundRow != _boundRow &&
            _visibilityBoundRow != _displayBoundRow)
          _visibilityBoundRow!,
      ]),
      builder: (context, _) {
        final displayText = _getDisplayText();
        final hasValue = displayText.isNotEmpty && displayText != widget.hint;
        final isEnabled = widget.enabled && _controller.enabled;

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

            // ComboBox
            InkWell(
              onTap: isEnabled ? _showPicker : null,
              borderRadius: BorderRadius.circular(
                widget.borderRadius?.toDouble() ?? 4.0,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: _buildDecoration(isEnabled),
                child: Row(
                  children: [
                    // Icon (optional)
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

                    // Display text
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

                    // Dropdown arrow
                    Icon(
                      Icons.keyboard_arrow_down,
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
// IOS PICKER SHEET
// ============================================================================

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
                    if (widget.dataSource.rowCount > 0) {
                      final selectedRow = widget.dataSource[_selectedIndex];
                      final selectedValue = selectedRow[widget.valueMember];
                      widget.onSelected(selectedValue);
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
