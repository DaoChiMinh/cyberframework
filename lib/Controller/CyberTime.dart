import 'package:cyberframework/cyberframework.dart';
import 'package:flutter/cupertino.dart';

class CyberTime extends StatefulWidget {
  // ✅ SIMPLE MODE: Direct value binding
  final dynamic text;

  // ✅ CONTROLLED MODE: Controller for external control
  final CyberTimeController? controller;

  // ✅ Initial value (only used when no controller and no binding)
  final TimeOfDay? initialValue;

  // UI Configuration
  final String? label;
  final String? hint;
  final String format;
  final IconData? icon;
  final bool enabled;
  final TextStyle? style;
  final InputDecoration? decoration;
  final bool isShowLabel;
  final Color? backgroundColor;
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
    this.controller,
    this.initialValue,
    this.label,
    this.hint,
    this.format = "HH:mm",
    this.icon,
    this.enabled = true,
    this.style,
    this.decoration,
    this.isShowLabel = true,
    this.backgroundColor,
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
  late TextEditingController _textController;
  late FocusNode _focusNode;

  // Binding support
  CyberDataRow? _boundRow;
  String? _boundField;
  CyberDataRow? _visibilityBoundRow;
  String? _visibilityBoundField;

  // ✅ SIMPLE MODE ONLY: Internal state
  // CRITICAL: This is ONLY used when controller == null
  TimeOfDay? _internalValue;

  bool _isUpdating = false;
  String? _validationError;

  // ✅ Determine if using controller mode
  bool get _isControlled => widget.controller != null;

  @override
  void initState() {
    super.initState();

    _focusNode = FocusNode();
    _parseBinding();
    _parseVisibilityBinding();

    // ✅ Initialize internal value ONLY for SIMPLE mode
    if (!_isControlled) {
      _internalValue = _getCurrentValueFromProps();
    }

    _updateTextController();

    // ✅ Attach controller if provided
    _attachController(widget.controller);

    // Attach binding listeners
    _attachBinding(_boundRow);
    _attachBinding(_visibilityBoundRow);

    _focusNode.addListener(() {
      if (_focusNode.hasFocus && widget.enabled) {
        _showTimePicker();
      }
    });
  }

  @override
  void didUpdateWidget(CyberTime oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ✅ 1. CRITICAL: Handle controller swap
    if (oldWidget.controller != widget.controller) {
      _detachController(oldWidget.controller);
      _attachController(widget.controller);

      // ✅ Reset internal state based on new mode
      if (_isControlled) {
        // Switched TO controlled mode - clear internal state
        _internalValue = null;
      } else {
        // Switched TO simple mode - initialize internal state
        _internalValue = _getCurrentValueFromProps();
      }

      _updateTextController();
    }

    // ✅ 2. Handle binding changes
    if (oldWidget.text != widget.text) {
      _detachBinding(_boundRow);
      _parseBinding();
      _attachBinding(_boundRow);

      // Update internal state if in simple mode
      if (!_isControlled) {
        _internalValue = _getCurrentValueFromProps();
      }

      _updateTextController();
    }

    // ✅ 3. Handle visibility binding changes
    if (oldWidget.isVisible != widget.isVisible) {
      _detachBinding(_visibilityBoundRow);
      _parseVisibilityBinding();
      _attachBinding(_visibilityBoundRow);
    }

    // ✅ 4. Handle time range changes
    if (oldWidget.minTime != widget.minTime ||
        oldWidget.maxTime != widget.maxTime) {
      _validate();
    }

    // ✅ 5. Handle validator changes
    if (oldWidget.validator != widget.validator) {
      _validate();
    }

    // ✅ 6. Handle initial value changes (SIMPLE mode only)
    if (!_isControlled && oldWidget.initialValue != widget.initialValue) {
      _internalValue = widget.initialValue;
      _updateTextController();
    }
  }

  @override
  void dispose() {
    // ✅ Clean up all listeners
    _detachController(widget.controller);
    _detachBinding(_boundRow);
    _detachBinding(_visibilityBoundRow);

    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // =========================================================================
  // LIFECYCLE MANAGEMENT - Controller
  // =========================================================================

  /// ✅ Attach controller listener
  void _attachController(CyberTimeController? controller) {
    controller?.addListener(_onControllerChanged);
  }

  /// ✅ Detach controller listener
  void _detachController(CyberTimeController? controller) {
    controller?.removeListener(_onControllerChanged);
  }

  /// ✅ Handle controller value changes
  void _onControllerChanged() {
    if (_isUpdating) return;

    _isUpdating = true;

    final value = _getCurrentValue();
    final displayValue = value != null ? _formatTime(value) : '';

    // Update text display
    if (_textController.text != displayValue) {
      _textController.text = displayValue;
    }

    // Sync controller value to binding (if exists)
    if (_boundRow != null && _boundField != null) {
      _syncToBinding(value);
    }

    // Validate
    _validate();

    _isUpdating = false;

    if (mounted) {
      setState(() {});
    }
  }

  // =========================================================================
  // LIFECYCLE MANAGEMENT - Binding
  // =========================================================================

  /// ✅ Attach binding listener
  void _attachBinding(CyberDataRow? row) {
    if (row != null && row != _boundRow) {
      row.addListener(_onBindingChanged);
    } else if (row == _boundRow) {
      row?.addListener(_onBindingChanged);
    }
  }

  /// ✅ Detach binding listener
  void _detachBinding(CyberDataRow? row) {
    row?.removeListener(_onBindingChanged);
  }

  /// ✅ Handle binding value changes
  void _onBindingChanged() {
    if (_isUpdating || _boundRow == null || _boundField == null) return;

    _isUpdating = true;

    final value = _getCurrentValueFromProps();
    final displayValue = value != null ? _formatTime(value) : '';

    // Update text display
    if (_textController.text != displayValue) {
      _textController.text = displayValue;
    }

    // ✅ Sync to controller OR internal state (NO DUPLICATION)
    if (_isControlled) {
      // CONTROLLED MODE: Sync to controller only
      if (!_sameTime(widget.controller!.value, value)) {
        widget.controller!.setSilently(value);
      }
    } else {
      // SIMPLE MODE: Sync to internal state only
      _internalValue = value;
    }

    // Validate
    _validate();

    _isUpdating = false;

    if (mounted) {
      setState(() {});
    }
  }

  // =========================================================================
  // VALUE MANAGEMENT - Single Source of Truth
  // =========================================================================

  /// ✅ Get current value from props (binding or direct value)
  TimeOfDay? _getCurrentValueFromProps() {
    if (_boundRow != null && _boundField != null) {
      final rawValue = _boundRow![_boundField!];
      return _parseTimeOfDay(rawValue);
    } else if (widget.text != null && widget.text is! CyberBindingExpression) {
      return _parseTimeOfDay(widget.text);
    } else if (widget.initialValue != null) {
      return widget.initialValue;
    }
    return null;
  }

  /// ✅ SINGLE SOURCE OF TRUTH
  /// CRITICAL: Widget is STATELESS about data when controlled
  TimeOfDay? _getCurrentValue() {
    if (_isControlled) {
      // ✅ CONTROLLED MODE: Controller is the ONLY source
      // Widget does NOT keep any internal state
      return widget.controller!.value;
    } else {
      // ✅ SIMPLE MODE: Internal state OR props
      return _internalValue ?? _getCurrentValueFromProps();
    }
  }

  // =========================================================================
  // PARSING & FORMATTING - UI Logic Only
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
  // UPDATE LOGIC
  // =========================================================================

  void _updateTextController() {
    final timeOfDay = _getCurrentValue();
    final displayValue = timeOfDay != null ? _formatTime(timeOfDay) : '';
    _textController = TextEditingController(text: displayValue);
  }

  void _validate() {
    final value = _getCurrentValue();

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

  void _syncToBinding(TimeOfDay? newTime) {
    if (_boundRow == null || _boundField == null) return;

    final originalValue = _boundRow![_boundField!];

    if (originalValue is DateTime && newTime != null) {
      final newDateTime = DateTime(
        originalValue.year,
        originalValue.month,
        originalValue.day,
        newTime.hour,
        newTime.minute,
        0,
      );
      if (_boundRow![_boundField!] != newDateTime) {
        _boundRow![_boundField!] = newDateTime;
      }
    } else {
      final timeString = newTime != null ? _formatTime(newTime) : '';
      if (_boundRow![_boundField!] != timeString) {
        _boundRow![_boundField!] = timeString;
      }
    }
  }

  void _updateValue(TimeOfDay newTime) {
    _isUpdating = true;

    // ✅ Update state based on mode - NO DUPLICATION
    if (_isControlled) {
      // CONTROLLED MODE: Update controller ONLY
      widget.controller!.value = newTime;
      // DO NOT touch _internalValue - it should remain null
    } else {
      // SIMPLE MODE: Update internal state ONLY
      _internalValue = newTime;
      // DO NOT touch controller - it doesn't exist
    }

    // Sync to binding
    _syncToBinding(newTime);

    // Update display
    _textController.text = _formatTime(newTime);

    // Validate
    _validate();

    // Callback
    widget.onChanged?.call(newTime);

    _isUpdating = false;

    if (mounted) {
      setState(() {});
    }
  }

  // =========================================================================
  // UI INTERACTION
  // =========================================================================

  Future<void> _showTimePicker() async {
    _focusNode.unfocus();

    final currentValue = _getCurrentValue() ?? TimeOfDay.now();

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

    // ✅ Listen to controller for reactive updates (CONTROLLED MODE only)
    if (_isControlled) {
      return ListenableBuilder(
        listenable: widget.controller!,
        builder: (context, child) => finalWidget,
      );
    }

    // ✅ Listen to binding (SIMPLE MODE)
    if (_boundRow != null) {
      return ListenableBuilder(
        listenable: _boundRow!,
        builder: (context, child) => finalWidget,
      );
    }

    return finalWidget;
  }

  InputDecoration _buildDecoration(String? errorText) {
    final hasError = errorText != null;

    return InputDecoration(
      hintText: widget.hint ?? 'Chọn giờ',
      prefixIcon: widget.icon != null
          ? Icon(widget.icon, size: 20)
          : const Icon(Icons.access_time, size: 20),
      suffixIcon: widget.enabled
          ? IconButton(
              icon: const Icon(Icons.arrow_drop_down, size: 20),
              onPressed: _showTimePicker,
            )
          : null,
      border: hasError
          ? OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.red),
              borderRadius: BorderRadius.circular(8),
            )
          : InputBorder.none,
      enabledBorder: hasError
          ? OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.red),
              borderRadius: BorderRadius.circular(8),
            )
          : InputBorder.none,
      focusedBorder: hasError
          ? OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.red, width: 2),
              borderRadius: BorderRadius.circular(8),
            )
          : InputBorder.none,
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red),
        borderRadius: BorderRadius.circular(8),
      ),
      disabledBorder: InputBorder.none,
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      filled: true,
      fillColor: widget.enabled
          ? (widget.backgroundColor ?? const Color(0xFFF5F5F5))
          : const Color(0xFFE0E0E0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}

// iOS Time Picker Sheet remains the same...
// iOS Time Picker giữ nguyên...
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
