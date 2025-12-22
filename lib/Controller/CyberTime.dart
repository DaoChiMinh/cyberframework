import 'package:cyberframework/cyberframework.dart';
import 'package:flutter/cupertino.dart';

class CyberTime extends StatefulWidget {
  final dynamic text;
  final String? label;
  final String? hint;
  final String format; // Time format: "HH:mm" or "HH:mm:ss"
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
  final bool showSeconds; // Hiển thị giây trong picker

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

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _parseBinding();
    _parseVisibilityBinding();
    _updateController();

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
  void dispose() {
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

  void _updateController() {
    final timeOfDay = _getCurrentValue();
    final displayValue = timeOfDay != null ? _formatTime(timeOfDay) : '';

    _textController = TextEditingController(text: displayValue);
  }

  void _onBindingChanged() {
    if (_isUpdating || _boundRow == null || _boundField == null) return;

    final timeOfDay = _getCurrentValue();
    final displayValue = timeOfDay != null ? _formatTime(timeOfDay) : '';

    if (_textController.text != displayValue) {
      _textController.text = displayValue;
    }
  }

  /// Get current value as TimeOfDay
  TimeOfDay? _getCurrentValue() {
    dynamic rawValue;

    if (_boundRow != null && _boundField != null) {
      rawValue = _boundRow![_boundField!];
    } else if (widget.text != null && widget.text is! CyberBindingExpression) {
      rawValue = widget.text;
    } else {
      return null;
    }

    return _parseTimeOfDay(rawValue);
  }

  /// Parse dynamic value to TimeOfDay
  TimeOfDay? _parseTimeOfDay(dynamic value) {
    if (value == null) return null;

    // ✅ DateTime → lấy phần time
    if (value is DateTime) {
      return TimeOfDay(hour: value.hour, minute: value.minute);
    }

    // ✅ String → parse theo format
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
        debugPrint('Error parsing time string: $e');
      }
    }

    return null;
  }

  /// Format TimeOfDay to string
  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    
    if (widget.format.contains('ss') || widget.showSeconds) {
      return '$hour:$minute:00';
    }
    
    return '$hour:$minute';
  }

  /// Update value with proper type preservation
  void _updateValue(TimeOfDay newTime) {
    _isUpdating = true;

    if (_boundRow != null && _boundField != null) {
      final originalValue = _boundRow![_boundField!];

      // ✅ Preserve original type
      if (originalValue is DateTime) {
        // Update DateTime with new time, keep same date
        final newDateTime = DateTime(
          originalValue.year,
          originalValue.month,
          originalValue.day,
          newTime.hour,
          newTime.minute,
          0, // seconds
        );
        _boundRow![_boundField!] = newDateTime;
        
        // Callback with DateTime
        widget.onChanged?.call(newDateTime);
      } else if (originalValue is String) {
        // Update as String with proper format
        final timeString = _formatTime(newTime);
        _boundRow![_boundField!] = timeString;
        
        // Callback with String
        widget.onChanged?.call(timeString);
      } else {
        // Default: save as String
        final timeString = _formatTime(newTime);
        _boundRow![_boundField!] = timeString;
        
        // Callback with String
        widget.onChanged?.call(timeString);
      }
    } else {
      // No binding, just callback
      final timeString = _formatTime(newTime);
      widget.onChanged?.call(timeString);
    }

    // Update display
    _textController.text = _formatTime(newTime);

    _isUpdating = false;
  }

  /// Show iOS-style time picker
  Future<void> _showTimePicker() async {
    // Unfocus để tránh keyboard hiện lên
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
      
      // ✅ Call onLeaver với đúng type
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

    Widget textField = TextField(
      controller: _textController,
      focusNode: _focusNode,
      readOnly: true, // ✅ Read-only, chỉ mở picker
      enabled: widget.enabled,
      style: widget.style,
      decoration: widget.decoration ?? _buildDecoration(),
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
          textField,
        ],
      );
    } else {
      finalWidget = textField;
    }

    if (_boundRow != null) {
      return ListenableBuilder(
        listenable: _boundRow!,
        builder: (context, child) => finalWidget,
      );
    }

    return finalWidget;
  }

  InputDecoration _buildDecoration() {
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

      // ✅ Bỏ border
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,

      // ✅ Background đồng bộ
      filled: true,
      fillColor: widget.enabled
          ? (widget.backgroundColor ?? const Color(0xFFF5F5F5))
          : const Color(0xFFE0E0E0),

      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}

/// iOS-style Time Picker Bottom Sheet
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

    _hourController = FixedExtentScrollController(
      initialItem: _selectedHour,
    );
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
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
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

          // Picker
          SizedBox(
            height: 250,
            child: Row(
              children: [
                // Hour picker
                Expanded(
                  child: _buildPicker(
                    controller: _hourController,
                    items: _hours,
                    selectedValue: _selectedHour,
                    onSelectedItemChanged: _onHourChanged,
                    label: 'Giờ',
                  ),
                ),

                // Separator
                const Text(
                  ':',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),

                // Minute picker
                Expanded(
                  child: _buildPicker(
                    controller: _minuteController,
                    items: _minutes,
                    selectedValue: _selectedMinute,
                    onSelectedItemChanged: _onMinuteChanged,
                    label: 'Phút',
                  ),
                ),

                // Second picker (if enabled)
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
                  setPickerState(() {}); // ✅ Trigger rebuild to update styles
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
