import 'package:cyberframework/cyberframework.dart';
import 'package:flutter/cupertino.dart';

// ============================================================================
// ✅ INTERNAL CONTROLLER + BINDING PATTERN
// ============================================================================
// Triết lý ERP/CyberFramework:
// - Widget tự quản lý internal controller
// - Không cần khai báo controller bên ngoài
// - Binding qua thuộc tính text: dr.bind("field_name")
// - Controller là single source of truth bên trong
// ============================================================================

class CyberTime extends StatefulWidget {
  // ✅ BINDING SUPPORT: text có thể là:
  // - CyberBindingExpression: dr.bind("gio_bat_dau")
  // - TimeOfDay: giá trị trực tiếp
  // - String: "14:30" (sẽ parse)
  // - null: sử dụng initialValue
  final dynamic text;

  // ✅ Initial value (chỉ dùng khi text == null)
  final TimeOfDay? initialValue;

  // UI Configuration
  final String? label;
  final String? hint;
  final String format;

  /// Icon code hiển thị bên trái (VD: "e8b5")
  final String? prefixIcon;

  /// Kích thước border (đơn vị: pixel)
  final int? borderSize;

  /// Border radius (đơn vị: pixel)
  final int? borderRadius;

  final bool enabled;
  final TextStyle? style;
  final InputDecoration? decoration;
  final bool isShowLabel;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? focusColor;
  final TextStyle? labelStyle;
  final dynamic isVisible;
  final bool showSeconds;
  final dynamic isCheckEmpty;

  // Callbacks
  final ValueChanged<TimeOfDay>? onChanged;
  final Function(dynamic)? onLeaver;

  // Validation
  final String? Function(TimeOfDay?)? validator;
  final String? errorText;
  final TimeOfDay? minTime;
  final TimeOfDay? maxTime;

  const CyberTime({
    super.key,
    this.text,
    this.initialValue,
    this.label,
    this.hint,
    this.format = "HH:mm",
    this.prefixIcon,
    this.borderSize = 1,
    this.borderRadius,
    this.enabled = true,
    this.style,
    this.decoration,
    this.isShowLabel = true,
    this.backgroundColor,
    this.borderColor = Colors.transparent,
    this.focusColor,
    this.labelStyle,
    this.isVisible = true,
    this.showSeconds = false,
    this.isCheckEmpty = false,
    this.onChanged,
    this.onLeaver,
    this.validator,
    this.errorText,
    this.minTime,
    this.maxTime,
  });

  @override
  State<CyberTime> createState() => _CyberTimeState();
}

class _CyberTimeState extends State<CyberTime> {
  // ✅ INTERNAL CONTROLLER - Single Source of Truth
  late CyberTimeController _controller;

  late TextEditingController _textController;
  late FocusNode _focusNode;

  // Binding support
  CyberDataRow? _boundRow;
  String? _boundField;
  CyberDataRow? _visibilityBoundRow;
  String? _visibilityBoundField;

  bool _isUpdating = false;
  String? _validationError;

  @override
  void initState() {
    super.initState();

    // ✅ 1. Tạo internal controller
    _controller = CyberTimeController();

    // ✅ 2. Khởi tạo UI components
    _focusNode = FocusNode();
    _textController = TextEditingController();

    // ✅ 3. Parse binding
    _parseBinding();
    _parseVisibilityBinding();

    // ✅ 4. Load initial value vào controller
    _loadInitialValue();

    // ✅ 5. Attach listeners
    _controller.addListener(_onControllerChanged);
    _attachBinding(_boundRow);
    _attachBinding(_visibilityBoundRow);

    // ✅ 6. Update UI lần đầu
    _updateTextController();

    // ✅ 7. Focus listener
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && widget.enabled) {
        _showTimePicker();
      }
    });
  }

  @override
  void didUpdateWidget(CyberTime oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ✅ 1. Handle binding changes
    if (oldWidget.text != widget.text) {
      _detachBinding(_boundRow);
      _parseBinding();
      _attachBinding(_boundRow);

      // Reload value from new binding
      _loadValueFromBinding();
      _updateTextController();
    }

    // ✅ 2. Handle visibility binding changes
    if (oldWidget.isVisible != widget.isVisible) {
      _detachBinding(_visibilityBoundRow);
      _parseVisibilityBinding();
      _attachBinding(_visibilityBoundRow);
    }

    // ✅ 3. Handle validation changes
    if (oldWidget.minTime != widget.minTime ||
        oldWidget.maxTime != widget.maxTime ||
        oldWidget.validator != widget.validator) {
      _validate();
    }

    // ✅ 4. Handle initial value changes (khi không có binding)
    if (_boundRow == null && oldWidget.initialValue != widget.initialValue) {
      _controller.value = widget.initialValue;
      _updateTextController();
    }
  }

  @override
  void dispose() {
    // ✅ Clean up all listeners
    _controller.removeListener(_onControllerChanged);
    _detachBinding(_boundRow);
    _detachBinding(_visibilityBoundRow);

    // ✅ Dispose controllers
    _controller.dispose();
    _textController.dispose();
    _focusNode.dispose();

    super.dispose();
  }

  // =========================================================================
  // ✅ INITIALIZATION - Load initial value vào controller
  // =========================================================================

  void _loadInitialValue() {
    final initialValue = _getValueFromProps();
    _controller.setSilently(initialValue);
  }

  // =========================================================================
  // ✅ CONTROLLER LISTENER - Controller → UI
  // =========================================================================

  void _onControllerChanged() {
    if (_isUpdating) return;

    _isUpdating = true;

    // ✅ 1. Update text display
    _updateTextController();

    // ✅ 2. Sync controller → binding (one-way: controller is source)
    _syncControllerToBinding();

    // ✅ 3. Validate
    _validate();

    _isUpdating = false;

    if (mounted) {
      setState(() {});
    }
  }

  // =========================================================================
  // ✅ BINDING MANAGEMENT
  // =========================================================================

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

  void _attachBinding(CyberDataRow? row) {
    row?.addListener(_onBindingChanged);
  }

  void _detachBinding(CyberDataRow? row) {
    row?.removeListener(_onBindingChanged);
  }

  // ✅ BINDING LISTENER - Binding → Controller → UI
  void _onBindingChanged() {
    if (_isUpdating || _boundRow == null || _boundField == null) return;

    _isUpdating = true;

    // ✅ Load value từ binding vào controller
    _loadValueFromBinding();

    // ✅ Update UI (thông qua controller listener)
    _updateTextController();

    // ✅ Validate
    _validate();

    _isUpdating = false;

    if (mounted) {
      setState(() {});
    }
  }

  // =========================================================================
  // ✅ VALUE FLOW - Unidirectional Data Flow
  // =========================================================================

  /// ✅ Get value từ props (binding hoặc direct value)
  TimeOfDay? _getValueFromProps() {
    // Priority 1: Binding
    if (_boundRow != null && _boundField != null) {
      final rawValue = _boundRow![_boundField!];
      return _parseTimeOfDay(rawValue);
    }

    // Priority 2: Direct value
    if (widget.text != null && widget.text is! CyberBindingExpression) {
      return _parseTimeOfDay(widget.text);
    }

    // Priority 3: Initial value
    if (widget.initialValue != null) {
      return widget.initialValue;
    }

    return null;
  }

  /// ✅ Load value từ binding vào controller
  void _loadValueFromBinding() {
    final value = _getValueFromProps();
    if (!_sameTime(_controller.value, value)) {
      _controller.setSilently(value);
    }
  }

  /// ✅ Sync controller → binding (one-way)
  void _syncControllerToBinding() {
    if (_boundRow == null || _boundField == null) return;

    final controllerValue = _controller.value;
    final originalValue = _boundRow![_boundField!];

    // ✅ Nếu binding value là DateTime, preserve date part
    if (originalValue is DateTime && controllerValue != null) {
      final newDateTime = DateTime(
        originalValue.year,
        originalValue.month,
        originalValue.day,
        controllerValue.hour,
        controllerValue.minute,
        0,
      );

      if (originalValue != newDateTime) {
        _boundRow![_boundField!] = newDateTime;
      }
      return;
    }

    // ✅ Ngược lại, sync as string
    final timeString = controllerValue != null
        ? _formatTime(controllerValue)
        : '';
    final currentBindingValue = _boundRow![_boundField!];

    if (currentBindingValue != timeString) {
      _boundRow![_boundField!] = timeString;
    }
  }

  // =========================================================================
  // ✅ PARSING & FORMATTING
  // =========================================================================

  TimeOfDay? _parseTimeOfDay(dynamic value) {
    if (value == null) return null;
    if (value is TimeOfDay) return value;

    if (value is DateTime) {
      return TimeOfDay(hour: value.hour, minute: value.minute);
    }

    if (value is String) {
      try {
        final parts = value.trim().split(':');
        if (parts.length >= 2) {
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1]);

          if (hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
            return TimeOfDay(hour: hour, minute: minute);
          }
        }
      } catch (e) {
        // Invalid format
      }
    }

    return null;
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

  bool _sameTime(TimeOfDay? a, TimeOfDay? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.hour == b.hour && a.minute == b.minute;
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    if (widget.format.contains('ss') || widget.showSeconds) {
      return '$hour:$minute:00';
    }

    return '$hour:$minute';
  }

  bool _isVisible() {
    if (_visibilityBoundRow != null && _visibilityBoundField != null) {
      return _parseBool(_visibilityBoundRow![_visibilityBoundField!]);
    }
    return _parseBool(widget.isVisible);
  }

  bool _isCheckEmpty() {
    return _parseBool(widget.isCheckEmpty);
  }

  // =========================================================================
  // ✅ UI UPDATE
  // =========================================================================

  void _updateTextController() {
    final timeOfDay = _controller.value;
    final displayValue = timeOfDay != null ? _formatTime(timeOfDay) : '';

    if (_textController.text != displayValue) {
      _textController.text = displayValue;
    }
  }

  void _validate() {
    final value = _controller.value;

    // Custom validator
    if (widget.validator != null) {
      _validationError = widget.validator!(value);
      return;
    }

    // Built-in validation
    if (value != null) {
      if (widget.minTime != null) {
        final minMinutes = widget.minTime!.hour * 60 + widget.minTime!.minute;
        final valueMinutes = value.hour * 60 + value.minute;
        if (valueMinutes < minMinutes) {
          _validationError = 'Giờ phải sau ${_formatTime(widget.minTime!)}';
          return;
        }
      }

      if (widget.maxTime != null) {
        final maxMinutes = widget.maxTime!.hour * 60 + widget.maxTime!.minute;
        final valueMinutes = value.hour * 60 + value.minute;
        if (valueMinutes > maxMinutes) {
          _validationError = 'Giờ phải trước ${_formatTime(widget.maxTime!)}';
          return;
        }
      }
    }

    // Required validation
    if (_isCheckEmpty() && value == null) {
      _validationError = 'Vui lòng chọn giờ';
      return;
    }

    _validationError = null;
  }

  // =========================================================================
  // ✅ USER INTERACTION - UI → Controller → Binding
  // =========================================================================

  void _updateValue(TimeOfDay newTime) {
    _isUpdating = true;

    // ✅ Update controller (single source of truth)
    _controller.value = newTime;
    // Controller listener sẽ tự động:
    // - Update UI
    // - Sync to binding
    // - Validate

    // ✅ User callback
    widget.onChanged?.call(newTime);

    _isUpdating = false;
  }

  Future<void> _showTimePicker() async {
    _focusNode.unfocus();

    final currentValue = _controller.value ?? TimeOfDay.now();

    final result = await showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _IOSTimePickerSheet(
        initialTime: currentValue,
        showSeconds: widget.showSeconds,
      ),
    );

    if (result != null) {
      _updateValue(result);

      // ✅ onLeaver callback
      if (widget.onLeaver != null) {
        if (_boundRow != null && _boundField != null) {
          final originalValue = _boundRow![_boundField!];
          if (originalValue is DateTime) {
            final newDateTime = DateTime(
              originalValue.year,
              originalValue.month,
              originalValue.day,
              result.hour,
              result.minute,
              0,
            );
            widget.onLeaver!(newDateTime);
          } else {
            widget.onLeaver!(_formatTime(result));
          }
        } else {
          widget.onLeaver!(_formatTime(result));
        }
      }
    }
  }

  // =========================================================================
  // ✅ BUILD - Reactive UI
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    if (!_isVisible()) {
      return const SizedBox.shrink();
    }

    final currentError = widget.errorText ?? _validationError;

    Widget textField = TextField(
      controller: _textController,
      focusNode: _focusNode,
      readOnly: true,
      enabled: widget.enabled,
      style: widget.style,
      decoration: widget.decoration ?? _buildDecoration(currentError),
      onTap: widget.enabled ? _showTimePicker : null,
    );

    Widget finalWidget;
    if (widget.isShowLabel &&
        widget.label != null &&
        widget.decoration == null) {
      finalWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
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
                  const Text(
                    ' *',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          textField,
          if (currentError != null)
            Padding(
              padding: const EdgeInsets.only(left: 4.0, top: 4.0),
              child: Text(
                currentError,
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ),
        ],
      );
    } else {
      finalWidget = textField;
    }

    // ✅ Listen to controller for reactive updates
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        // ✅ Also listen to binding if exists
        if (_boundRow != null) {
          return ListenableBuilder(
            listenable: _boundRow!,
            builder: (context, child) => finalWidget,
          );
        }
        return finalWidget;
      },
    );
  }

  InputDecoration _buildDecoration(String? errorText) {
    final hasError = errorText != null;
    final iconData = widget.prefixIcon != null
        ? v_parseIcon(widget.prefixIcon!)
        : null;
    final borderWidth = widget.borderSize?.toDouble() ?? 0.0;
    final radius = widget.borderRadius?.toDouble() ?? 4.0;
    final effectiveBorderColor = hasError
        ? Colors.red
        : (widget.borderColor ?? Colors.grey);

    // Tạo border style dựa vào borderSize và error state
    final borderStyle = (borderWidth > 0 || hasError)
        ? OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide(
              color: effectiveBorderColor,
              width: hasError ? 1.0 : borderWidth,
            ),
          )
        : null;

    final focusedBorderStyle = hasError
        ? OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          )
        : (borderWidth > 0
              ? OutlineInputBorder(
                  borderRadius: BorderRadius.circular(radius),
                  borderSide: BorderSide(
                    color: effectiveBorderColor,
                    width: borderWidth,
                  ),
                )
              : null);

    return InputDecoration(
      hintText: widget.hint ?? 'Chọn giờ',
      hintStyle: TextStyle(
        color: Colors.grey.shade500,
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: iconData != null
          ? Icon(iconData, size: 18)
          : const Icon(Icons.access_time, size: 18),
      suffixIcon: widget.enabled
          ? IconButton(
              icon: const Icon(Icons.arrow_drop_down, size: 20),
              onPressed: _showTimePicker,
            )
          : null,

      // ✅ Border based on error state and borderSize
      border: borderStyle ?? InputBorder.none,
      enabledBorder: borderStyle ?? InputBorder.none,
      focusedBorder: focusedBorderStyle ?? InputBorder.none,
      errorBorder: borderStyle ?? InputBorder.none,
      disabledBorder: InputBorder.none,
      focusedErrorBorder: focusedBorderStyle ?? InputBorder.none,

      filled: true,
      fillColor: widget.enabled
          ? (widget.backgroundColor ?? const Color(0xFFF5F5F5))
          : const Color(0xFFE0E0E0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}

// ============================================================================
// ✅ IOS TIME PICKER SHEET
// ============================================================================

class _IOSTimePickerSheet extends StatefulWidget {
  final TimeOfDay initialTime;
  final bool showSeconds;

  const _IOSTimePickerSheet({
    required this.initialTime,
    this.showSeconds = false,
  });

  @override
  State<_IOSTimePickerSheet> createState() => _IOSTimePickerSheetState();
}

class _IOSTimePickerSheetState extends State<_IOSTimePickerSheet> {
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late FixedExtentScrollController _secondController;

  late int _selectedHour;
  late int _selectedMinute;
  late int _selectedSecond;

  final List<int> _hours = List.generate(24, (index) => index);
  final List<int> _minutes = List.generate(60, (index) => index);
  final List<int> _seconds = List.generate(60, (index) => index);

  @override
  void initState() {
    super.initState();

    _selectedHour = widget.initialTime.hour;
    _selectedMinute = widget.initialTime.minute;
    _selectedSecond = 0;

    _hourController = FixedExtentScrollController(initialItem: _selectedHour);
    _minuteController = FixedExtentScrollController(
      initialItem: _selectedMinute,
    );
    _secondController = FixedExtentScrollController(
      initialItem: _selectedSecond,
    );
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _secondController.dispose();
    super.dispose();
  }

  void _onHourChanged(int index) {
    setState(() {
      _selectedHour = _hours[index];
    });
  }

  void _onMinuteChanged(int index) {
    setState(() {
      _selectedMinute = _minutes[index];
    });
  }

  void _onSecondChanged(int index) {
    setState(() {
      _selectedSecond = _seconds[index];
    });
  }

  TimeOfDay _getSelectedTime() {
    return TimeOfDay(hour: _selectedHour, minute: _selectedMinute);
  }

  String _formatDisplay() {
    final hour = _selectedHour.toString().padLeft(2, '0');
    final minute = _selectedMinute.toString().padLeft(2, '0');

    if (widget.showSeconds) {
      final second = _selectedSecond.toString().padLeft(2, '0');
      return '$hour:$minute:$second';
    }

    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy', style: TextStyle(fontSize: 16)),
                ),
                Text(
                  _formatDisplay(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, _getSelectedTime()),
                  child: const Text(
                    'Xong',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 250,
            child: Row(
              children: [
                Expanded(
                  child: _buildPicker(
                    controller: _hourController,
                    items: _hours,
                    selectedValue: _selectedHour,
                    onSelectedItemChanged: _onHourChanged,
                    label: 'Giờ',
                  ),
                ),
                const Text(
                  ':',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: _buildPicker(
                    controller: _minuteController,
                    items: _minutes,
                    selectedValue: _selectedMinute,
                    onSelectedItemChanged: _onMinuteChanged,
                    label: 'Phút',
                  ),
                ),
                if (widget.showSeconds) ...[
                  const Text(
                    ':',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: _buildPicker(
                      controller: _secondController,
                      items: _seconds,
                      selectedValue: _selectedSecond,
                      onSelectedItemChanged: _onSecondChanged,
                      label: 'Giây',
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPicker({
    required FixedExtentScrollController controller,
    required List<int> items,
    required int selectedValue,
    required void Function(int) onSelectedItemChanged,
    required String label,
  }) {
    return StatefulBuilder(
      builder: (context, setPickerState) {
        return Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: CupertinoPicker(
                scrollController: controller,
                itemExtent: 50,
                onSelectedItemChanged: (index) {
                  onSelectedItemChanged(index);
                  setPickerState(() {});
                },
                children: items.map((value) {
                  final isSelected = value == selectedValue;
                  return Center(
                    child: Text(
                      value.toString().padLeft(2, '0'),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected ? Colors.black : Colors.grey[600],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}
