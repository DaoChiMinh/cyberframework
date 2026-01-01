import 'package:cyberframework/cyberframework.dart';
import 'package:intl/intl.dart';

class CyberDate extends StatefulWidget {
  final dynamic text;
  final String? label;
  final String? hint;
  final String format; // Date format: "dd/MM/yyyy", "yyyy-MM-dd", etc.
  final IconData? icon;
  final bool enabled;
  final TextStyle? style;
  final InputDecoration? decoration;
  final ValueChanged<DateTime>? onChanged;
  final Function(dynamic)? onLeaver;
  final DateTime? minDate;
  final DateTime? maxDate;
  final bool isShowLabel;
  final Color? backgroundColor;
  final Color? focusColor;
  final TextStyle? labelStyle;
  final dynamic isVisible;
  final dynamic isCheckEmpty;

  /// Controller for programmatic control of the date value
  final CyberDateController? controller;

  /// Initial value when no controller is provided
  final DateTime? initialValue;

  /// Date formatter (if null, use format string)
  final DateFormat? formatter;

  /// Validator function
  final String? Function(DateTime?)? validator;

  /// Error text to display
  final String? errorText;

  const CyberDate({
    super.key,
    this.text,
    this.label,
    this.hint,
    this.format = "dd/MM/yyyy",
    this.icon,
    this.enabled = true,
    this.style,
    this.decoration,
    this.onChanged,
    this.onLeaver,
    this.minDate,
    this.maxDate,
    this.isShowLabel = true,
    this.backgroundColor,
    this.focusColor,
    this.labelStyle,
    this.isVisible = true,
    this.isCheckEmpty = false,
    this.controller,
    this.initialValue,
    this.formatter,
    this.validator,
    this.errorText,
  });

  @override
  State<CyberDate> createState() => _CyberDateState();
}

class _CyberDateState extends State<CyberDate> {
  late TextEditingController _textController;
  late FocusNode _focusNode;
  late DateFormat _dateFormat;
  late DateTime _minDate;
  late DateTime _maxDate;

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
    _setupDateFormat();
    _setupDateRange();
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
        _showDatePicker();
      }
    });
  }

  @override
  void didUpdateWidget(CyberDate oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ✅ 1. Handle controller swap/changes
    if (oldWidget.controller != widget.controller) {
      // Remove listener from old controller
      oldWidget.controller?.removeListener(_onControllerChanged);

      // Add listener to new controller
      widget.controller?.addListener(_onControllerChanged);

      // Update display with new controller value
      _onControllerChanged();
    }

    // ✅ 2. Handle binding changes
    if (oldWidget.text != widget.text) {
      // Remove listener from old binding
      if (_boundRow != null) {
        _boundRow!.removeListener(_onBindingChanged);
      }

      // Parse new binding
      _parseBinding();

      // Add listener to new binding
      if (_boundRow != null) {
        _boundRow!.addListener(_onBindingChanged);
      }

      // Update display with new binding value
      _onBindingChanged();
    }

    // ✅ 3. Handle visibility binding changes
    if (oldWidget.isVisible != widget.isVisible) {
      // Remove listener from old visibility binding
      if (_visibilityBoundRow != null && _visibilityBoundRow != _boundRow) {
        _visibilityBoundRow!.removeListener(_onBindingChanged);
      }

      // Parse new visibility binding
      _parseVisibilityBinding();

      // Add listener to new visibility binding
      if (_visibilityBoundRow != null && _visibilityBoundRow != _boundRow) {
        _visibilityBoundRow!.addListener(_onBindingChanged);
      }
    }

    // ✅ 4. Handle date format changes
    if (oldWidget.format != widget.format ||
        oldWidget.formatter != widget.formatter) {
      _setupDateFormat();
      _updateTextController();
    }

    // ✅ 5. Handle date range changes
    if (oldWidget.minDate != widget.minDate ||
        oldWidget.maxDate != widget.maxDate) {
      _setupDateRange();
      _validate();
    }

    // ✅ 6. Handle validator changes
    if (oldWidget.validator != widget.validator) {
      _validate();
    }

    // ✅ 7. Handle error text changes
    if (oldWidget.errorText != widget.errorText) {
      setState(() {}); // Trigger rebuild to show new error
    }

    // ✅ 8. Handle enabled state changes
    if (oldWidget.enabled != widget.enabled) {
      setState(() {}); // Trigger rebuild
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

  void _setupDateFormat() {
    if (widget.formatter != null) {
      _dateFormat = widget.formatter!;
    } else {
      try {
        _dateFormat = DateFormat(widget.format);
      } catch (e) {
        // ✅ Fallback to global config if available
        // _dateFormat = CyberAppConfig.dateFormat ?? DateFormat('dd/MM/yyyy');
        _dateFormat = DateFormat('dd/MM/yyyy');
      }
    }
  }

  void _setupDateRange() {
    final now = DateTime.now();
    _minDate = widget.minDate ?? DateTime(now.year - 100, 1, 1);
    _maxDate = widget.maxDate ?? DateTime(now.year + 100, 12, 31);
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

  bool _isCheckEmpty() {
    return _parseBool(widget.isCheckEmpty);
  }

  bool _isVisible() {
    if (_visibilityBoundRow != null && _visibilityBoundField != null) {
      return _parseBool(_visibilityBoundRow![_visibilityBoundField!]);
    }
    return _parseBool(widget.isVisible);
  }

  void _updateTextController() {
    final value = _getCurrentValue();
    final displayValue = value != null ? _formatDate(value) : '';
    _textController = TextEditingController(text: displayValue);
  }

  /// ✅ Handle controller value changes
  void _onControllerChanged() {
    if (_isUpdating) return;

    _isUpdating = true;

    final value = _getCurrentValue();
    final displayValue = value != null ? _formatDate(value) : '';

    // Update text display
    if (_textController.text != displayValue) {
      _textController.text = displayValue;
    }

    // Sync controller value to binding
    if (_boundRow != null && _boundField != null) {
      if (_boundRow![_boundField!] != value) {
        _boundRow![_boundField!] = value;
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
    final displayValue = value != null ? _formatDate(value) : '';

    // Update text display
    if (_textController.text != displayValue) {
      _textController.text = displayValue;
    }

    // Sync binding to controller
    if (widget.controller != null && widget.controller!.value != value) {
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
  DateTime? _getCurrentValue() {
    // Priority: Controller > Binding > Initial value
    if (widget.controller != null) {
      return widget.controller!.value;
    } else if (_boundRow != null && _boundField != null) {
      final rawValue = _boundRow![_boundField!];
      return _parseDateTime(rawValue);
    } else if (widget.initialValue != null) {
      return widget.initialValue;
    } else if (widget.text != null && widget.text is! CyberBindingExpression) {
      return _parseDateTime(widget.text);
    }
    return null;
  }

  DateTime? _parseDateTime(dynamic rawValue) {
    if (rawValue is DateTime) return rawValue;
    if (rawValue is String) {
      try {
        return DateTime.parse(rawValue);
      } catch (e) {
        try {
          return _dateFormat.parse(rawValue);
        } catch (e) {
          return null;
        }
      }
    }
    return null;
  }

  String _formatDate(DateTime date) {
    return _dateFormat.format(date);
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
      if (value.isBefore(_minDate)) {
        _validationError = 'Ngày phải sau ${_formatDate(_minDate)}';
        return;
      }
      if (value.isAfter(_maxDate)) {
        _validationError = 'Ngày phải trước ${_formatDate(_maxDate)}';
        return;
      }
    }

    // Required validation
    if (_isCheckEmpty() && value == null) {
      _validationError = 'Vui lòng chọn ngày';
      return;
    }

    _validationError = null;
  }

  void _updateValue(DateTime newDate) {
    _isUpdating = true;

    // ✅ Update controller/binding
    if (widget.controller != null) {
      widget.controller!.value = newDate;
    } else if (_boundRow != null && _boundField != null) {
      _boundRow![_boundField!] = newDate;
    }

    // Update display
    _textController.text = _formatDate(newDate);

    // Validate
    _validate();

    // Callback
    widget.onChanged?.call(newDate);

    _isUpdating = false;

    // Trigger rebuild
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _showDatePicker() async {
    // Unfocus to avoid keyboard
    _focusNode.unfocus();

    final currentValue = _getCurrentValue() ?? DateTime.now();

    final result = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _IOSDatePickerSheet(
        initialDate: currentValue,
        minDate: _minDate,
        maxDate: _maxDate,
        dateFormat: _dateFormat,
      ),
    );

    if (result != null) {
      _updateValue(result);
      widget.onLeaver?.call(result);
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
      onTap: widget.enabled ? _showDatePicker : null,
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
      hintText: widget.hint ?? 'Chọn ngày',
      prefixIcon: widget.icon != null
          ? Icon(widget.icon, size: 20)
          : const Icon(Icons.calendar_today, size: 20),
      suffixIcon: widget.enabled
          ? IconButton(
              icon: const Icon(Icons.arrow_drop_down, size: 20),
              onPressed: _showDatePicker,
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

      // Background
      filled: true,
      fillColor: widget.enabled
          ? (widget.backgroundColor ?? const Color(0xFFF5F5F5))
          : const Color(0xFFE0E0E0),

      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}

// ✅ iOS Date Picker remains the same
class _IOSDatePickerSheet extends StatefulWidget {
  final DateTime initialDate;
  final DateTime minDate;
  final DateTime maxDate;
  final DateFormat dateFormat;

  const _IOSDatePickerSheet({
    required this.initialDate,
    required this.minDate,
    required this.maxDate,
    required this.dateFormat,
  });

  @override
  State<_IOSDatePickerSheet> createState() => _IOSDatePickerSheetState();
}

class _IOSDatePickerSheetState extends State<_IOSDatePickerSheet> {
  late FixedExtentScrollController _dayController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _yearController;

  late int _selectedDay;
  late int _selectedMonth;
  late int _selectedYear;

  late List<int> _days;
  late List<int> _months;
  late List<int> _years;

  @override
  void initState() {
    super.initState();

    _selectedDay = widget.initialDate.day;
    _selectedMonth = widget.initialDate.month;
    _selectedYear = widget.initialDate.year;

    _months = List.generate(12, (index) => index + 1);
    _years = List.generate(
      widget.maxDate.year - widget.minDate.year + 1,
      (index) => widget.minDate.year + index,
    );

    _updateDays();

    _dayController = FixedExtentScrollController(
      initialItem: _days.indexOf(_selectedDay),
    );
    _monthController = FixedExtentScrollController(
      initialItem: _months.indexOf(_selectedMonth),
    );
    _yearController = FixedExtentScrollController(
      initialItem: _years.indexOf(_selectedYear),
    );
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _updateDays() {
    final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    _days = List.generate(daysInMonth, (index) => index + 1);

    if (_selectedDay > daysInMonth) {
      _selectedDay = daysInMonth;
    }
  }

  void _onDayChanged(int index) {
    setState(() {
      _selectedDay = _days[index];
    });
  }

  void _onMonthChanged(int index) {
    setState(() {
      _selectedMonth = _months[index];
      _updateDays();

      if (_selectedDay > _days.length) {
        _selectedDay = _days.last;
        _dayController.jumpToItem(_days.length - 1);
      }
    });
  }

  void _onYearChanged(int index) {
    setState(() {
      _selectedYear = _years[index];
      _updateDays();

      if (_selectedDay > _days.length) {
        _selectedDay = _days.last;
        _dayController.jumpToItem(_days.length - 1);
      }
    });
  }

  DateTime _getSelectedDate() {
    return DateTime(_selectedYear, _selectedMonth, _selectedDay);
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
                  widget.dateFormat.format(_getSelectedDate()),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, _getSelectedDate()),
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
                    controller: _dayController,
                    itemCount: _days.length,
                    itemBuilder: (index) =>
                        _days[index].toString().padLeft(2, '0'),
                    onSelectedItemChanged: _onDayChanged,
                  ),
                ),
                Expanded(
                  child: _buildPicker(
                    controller: _monthController,
                    itemCount: _months.length,
                    itemBuilder: (index) => _getMonthName(_months[index]),
                    onSelectedItemChanged: _onMonthChanged,
                  ),
                ),
                Expanded(
                  child: _buildPicker(
                    controller: _yearController,
                    itemCount: _years.length,
                    itemBuilder: (index) => _years[index].toString(),
                    onSelectedItemChanged: _onYearChanged,
                  ),
                ),
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
    required int itemCount,
    required String Function(int) itemBuilder,
    required void Function(int) onSelectedItemChanged,
  }) {
    return StatefulBuilder(
      builder: (context, setPickerState) {
        return ListWheelScrollView.useDelegate(
          controller: controller,
          itemExtent: 50,
          perspective: 0.005,
          diameterRatio: 1.2,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: (index) {
            onSelectedItemChanged(index);
            setPickerState(() {});
          },
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: itemCount,
            builder: (context, index) {
              final isSelected =
                  controller.hasClients && controller.selectedItem == index;

              return Center(
                child: Text(
                  itemBuilder(index),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected ? Colors.black : Colors.grey[600],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _getMonthName(int month) {
    const monthNames = [
      'Tháng 1',
      'Tháng 2',
      'Tháng 3',
      'Tháng 4',
      'Tháng 5',
      'Tháng 6',
      'Tháng 7',
      'Tháng 8',
      'Tháng 9',
      'Tháng 10',
      'Tháng 11',
      'Tháng 12',
    ];
    return monthNames[month - 1];
  }
}
