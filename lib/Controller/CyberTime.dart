import 'package:cyberframework/cyberframework.dart';
import 'package:flutter/cupertino.dart';

class CyberTime extends StatefulWidget {
  final dynamic text;
  final String? label;
  final String? hint;
  final String format;
  final IconData? icon;
  final bool enabled;
  final TextStyle? style;
  final InputDecoration? decoration;
  final ValueChanged<dynamic>? onChanged;
  final Function(dynamic)? onLeaver;
  final bool isShowLabel;
  final Color? backgroundColor;
  final Color? focusColor;
  final TextStyle? labelStyle;
  final dynamic isVisible;
  final bool showSeconds;
  final dynamic isCheckEmpty;

  /// Controller for programmatic control of the time value
  final CyberTimeController? controller;

  /// Initial value when no controller is provided
  final TimeOfDay? initialValue;

  /// Validator function
  final String? Function(TimeOfDay?)? validator;

  /// Error text to display
  final String? errorText;

  /// Minimum allowed time
  final TimeOfDay? minTime;

  /// Maximum allowed time
  final TimeOfDay? maxTime;

  const CyberTime({
    super.key,
    this.text,
    this.label,
    this.hint,
    this.format = "HH:mm",
    this.icon,
    this.enabled = true,
    this.style,
    this.decoration,
    this.onChanged,
    this.onLeaver,
    this.isShowLabel = true,
    this.backgroundColor,
    this.focusColor,
    this.labelStyle,
    this.isVisible = true,
    this.showSeconds = false,
    this.isCheckEmpty = false,
    this.controller,
    this.initialValue,
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

  CyberDataRow? _boundRow;
  String? _boundField;
  CyberDataRow? _visibilityBoundRow;
  String? _visibilityBoundField;
  bool _isUpdating = false;

  String? _validationError;

  @override
  void initState() {
    super.initState();

    _focusNode = FocusNode();
    _parseBinding();
    _parseVisibilityBinding();
    _updateTextController();

    // Listen to controller if provided
    widget.controller?.addListener(_onControllerChanged);

    if (_boundRow != null) {
      _boundRow!.addListener(_onBindingChanged);
    }
    if (_visibilityBoundRow != null && _visibilityBoundRow != _boundRow) {
      _visibilityBoundRow!.addListener(_onBindingChanged);
    }

    _focusNode.addListener(() {
      if (_focusNode.hasFocus && widget.enabled) {
        _showTimePicker();
      }
    });
  }

  @override
  void didUpdateWidget(CyberTime oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ✅ 1. Handle controller swap/changes
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerChanged);
      widget.controller?.addListener(_onControllerChanged);
      _onControllerChanged();
    }

    // ✅ 2. Handle binding changes
    if (oldWidget.text != widget.text) {
      if (_boundRow != null) {
        _boundRow!.removeListener(_onBindingChanged);
      }
      _parseBinding();
      if (_boundRow != null) {
        _boundRow!.addListener(_onBindingChanged);
      }
      _onBindingChanged();
    }

    // ✅ 3. Handle visibility binding changes
    if (oldWidget.isVisible != widget.isVisible) {
      if (_visibilityBoundRow != null && _visibilityBoundRow != _boundRow) {
        _visibilityBoundRow!.removeListener(_onBindingChanged);
      }
      _parseVisibilityBinding();
      if (_visibilityBoundRow != null && _visibilityBoundRow != _boundRow) {
        _visibilityBoundRow!.addListener(_onBindingChanged);
      }
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

    // ✅ 6. Handle error text changes
    if (oldWidget.errorText != widget.errorText) {
      setState(() {});
    }

    // ✅ 7. Handle enabled state changes
    if (oldWidget.enabled != widget.enabled) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    // ✅ Remove all listeners
    widget.controller?.removeListener(_onControllerChanged);

    if (_boundRow != null) {
      _boundRow!.removeListener(_onBindingChanged);
    }
    if (_visibilityBoundRow != null && _visibilityBoundRow != _boundRow) {
      _visibilityBoundRow!.removeListener(_onBindingChanged);
    }

    _textController.dispose();
    _focusNode.dispose();
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

  bool _isCheckEmpty() {
    return _parseBool(widget.isCheckEmpty);
  }

  void _updateTextController() {
    final timeOfDay = _getCurrentValue();
    final displayValue = timeOfDay != null ? _formatTime(timeOfDay) : '';
    _textController = TextEditingController(text: displayValue);
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

    // Sync controller value to binding
    if (_boundRow != null && _boundField != null) {
      final originalValue = _boundRow![_boundField!];
      if (originalValue is DateTime && value != null) {
        final newDateTime = DateTime(
          originalValue.year,
          originalValue.month,
          originalValue.day,
          value.hour,
          value.minute,
          0,
        );
        if (_boundRow![_boundField!] != newDateTime) {
          _boundRow![_boundField!] = newDateTime;
        }
      } else {
        final timeString = value != null ? _formatTime(value) : '';
        if (_boundRow![_boundField!] != timeString) {
          _boundRow![_boundField!] = timeString;
        }
      }
    }

    // Validate
    _validate();

    _isUpdating = false;

    // Trigger rebuild
    if (mounted) {
      setState(() {});
    }
  }

  /// Handle binding value changes
  void _onBindingChanged() {
    if (_isUpdating || _boundRow == null || _boundField == null) return;

    _isUpdating = true;

    final value = _getCurrentValue();
    final displayValue = value != null ? _formatTime(value) : '';

    // Update text display
    if (_textController.text != displayValue) {
      _textController.text = displayValue;
    }

    // Sync binding to controller
    if (widget.controller != null &&
        !_sameTime(widget.controller!.value, value)) {
      widget.controller!.setSilently(value);
    }

    // Validate
    _validate();

    _isUpdating = false;

    // Trigger rebuild
    if (mounted) {
      setState(() {});
    }
  }

  /// ✅ Single source of truth for current value
  TimeOfDay? _getCurrentValue() {
    // Priority: Controller > Binding > Initial value
    if (widget.controller != null) {
      return widget.controller!.value;
    } else if (_boundRow != null && _boundField != null) {
      final rawValue = _boundRow![_boundField!];
      return _parseTimeOfDay(rawValue);
    } else if (widget.initialValue != null) {
      return widget.initialValue;
    } else if (widget.text != null && widget.text is! CyberBindingExpression) {
      return _parseTimeOfDay(widget.text);
    }
    return null;
  }

  TimeOfDay? _parseTimeOfDay(dynamic value) {
    if (value == null) return null;

    if (value is TimeOfDay) return value;

    if (value is DateTime) {
      return TimeOfDay(hour: value.hour, minute: value.minute);
    }

    if (value is String) {
      return CyberTimeController.parse(value);
    }

    return null;
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

  /// ✅ Validation logic
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

  void _updateValue(TimeOfDay newTime) {
    _isUpdating = true;

    // ✅ Update controller/binding
    if (widget.controller != null) {
      widget.controller!.value = newTime;
    } else if (_boundRow != null && _boundField != null) {
      final originalValue = _boundRow![_boundField!];

      if (originalValue is DateTime) {
        final newDateTime = DateTime(
          originalValue.year,
          originalValue.month,
          originalValue.day,
          newTime.hour,
          newTime.minute,
          0,
        );
        _boundRow![_boundField!] = newDateTime;
        widget.onChanged?.call(newDateTime);
      } else {
        final timeString = _formatTime(newTime);
        _boundRow![_boundField!] = timeString;
        widget.onChanged?.call(timeString);
      }
    } else {
      final timeString = _formatTime(newTime);
      widget.onChanged?.call(timeString);
    }

    // Update display
    _textController.text = _formatTime(newTime);

    // Validate
    _validate();

    // Callback (if not using controller)
    if (widget.controller == null) {
      widget.onChanged?.call(newTime);
    }

    _isUpdating = false;

    // Trigger rebuild
    if (mounted) {
      setState(() {});
    }
  }

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
          // ✅ Error text display
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
    if (widget.controller != null) {
      return ListenableBuilder(
        listenable: widget.controller!,
        builder: (context, child) => finalWidget,
      );
    }

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

      // ✅ Border for error state
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

/// iOS-style Time Picker Bottom Sheet (giữ nguyên như cũ)
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
