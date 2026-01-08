import 'package:cyberframework/cyberframework.dart';
import 'package:intl/intl.dart';

/// CyberDate - Widget chọn ngày với binding hỗ trợ
///
/// Triết lý ERP/CyberFramework:
/// - Internal Controller tự động (không cần khai báo)
/// - Hỗ trợ binding: text: dr.bind("ngay_sinh")
/// - Two-way binding tự động
///
/// Ví dụ sử dụng:
/// ```dart
/// // Cách 1: Binding với CyberDataRow
/// CyberDate(
///   text: dr.bind("ngay_sinh"),
///   label: "Ngày sinh",
///   format: "dd/MM/yyyy",
/// )
///
/// // Cách 2: Giá trị tĩnh
/// CyberDate(
///   text: DateTime.now(),
///   label: "Ngày hiện tại",
/// )
///
/// // Cách 3: External controller (advanced)
/// final controller = CyberDateController();
/// CyberDate(
///   controller: controller,
///   label: "Điều khiển từ ngoài",
/// )
///
/// // Cách 4: Với nullValue
/// CyberDate(
///   text: dr.bind("ngay_het_han"),
///   label: "Ngày hết hạn",
///   nullValue: DateTime(1900, 1, 1), // Mặc định, có thể không cần khai báo
///   showClearButton: true, // Hiển thị nút Clear
/// )
/// ```
class CyberDate extends StatefulWidget {
  /// ⚠️ KHÔNG dùng cả text VÀ controller cùng lúc
  ///
  /// text hỗ trợ:
  /// - Binding: dr.bind("ngay_sinh")
  /// - Giá trị tĩnh: DateTime.now()
  /// - null: rỗng
  final dynamic text;

  /// Controller để quản lý state từ bên ngoài (Optional - không bắt buộc)
  /// Chỉ dùng khi cần điều khiển widget từ code
  final CyberDateController? controller;

  final String? label;
  final String? hint;

  /// Date format: "dd/MM/yyyy", "yyyy-MM-dd", etc.
  final String format;

  /// Icon code hiển thị bên trái (VD: "e935")
  final String? prefixIcon;

  /// Kích thước border (đơn vị: pixel)
  final int? borderSize;

  /// Border radius (đơn vị: pixel)
  final int? borderRadius;

  final bool enabled;
  final TextStyle? style;
  final InputDecoration? decoration;

  /// Callback khi giá trị thay đổi
  final ValueChanged<DateTime?>? onChanged;
  final Function(dynamic)? onLeaver;

  /// Giới hạn ngày
  final DateTime? minDate;
  final DateTime? maxDate;

  final bool isShowLabel;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? focusColor;
  final TextStyle? labelStyle;
  final dynamic isVisible;
  final dynamic isCheckEmpty;

  /// Date formatter (nếu null, dùng format string)
  final DateFormat? formatter;

  /// Validator function
  final String? Function(DateTime?)? validator;

  /// Error text to display
  final String? errorText;

  /// Giá trị null - nếu date bằng giá trị này thì hiển thị hint text
  /// Mặc định: 01/01/1900
  final DateTime? nullValue;

  /// Hiển thị nút Clear để xóa giá trị (set về nullValue)
  final bool showClearButton;

  /// Default null value: 01/01/1900
  static final DateTime defaultNullValue = DateTime(1900, 1, 1);

  const CyberDate({
    super.key,
    this.text,
    this.controller,
    this.label,
    this.hint,
    this.format = "dd/MM/yyyy",
    this.prefixIcon,
    this.borderSize = 1,
    this.borderRadius,
    this.enabled = true,
    this.style,
    this.decoration,
    this.onChanged,
    this.onLeaver,
    this.minDate,
    this.maxDate,
    this.isShowLabel = true,
    this.backgroundColor,
    this.borderColor = Colors.transparent,
    this.focusColor,
    this.labelStyle,
    this.isVisible = true,
    this.isCheckEmpty = false,
    this.formatter,
    this.validator,
    this.errorText,
    this.nullValue,
    this.showClearButton = true,
  }) : assert(
         controller == null || text == null,
         'CyberDate: không được dùng cả text và controller cùng lúc',
       );

  @override
  State<CyberDate> createState() => _CyberDateState();
}

class _CyberDateState extends State<CyberDate> {
  late TextEditingController _textController;
  late FocusNode _focusNode;
  late DateFormat _dateFormat;
  late DateTime _minDate;
  late DateTime _maxDate;

  // Binding state
  CyberDataRow? _boundRow;
  String? _boundField;
  CyberDataRow? _visibilityBoundRow;
  String? _visibilityBoundField;
  bool _isUpdating = false;

  String? _validationError;

  /// ✅ Internal controller (tạo tự động nếu không có external controller)
  CyberDateController? _internalController;

  /// ✅ Effective controller - ưu tiên external, fallback internal
  CyberDateController get _effectiveController =>
      widget.controller ?? _internalController!;

  @override
  void initState() {
    super.initState();

    // ✅ Tạo internal controller nếu không có external controller
    if (widget.controller == null) {
      _internalController = CyberDateController();
    }

    _textController = TextEditingController();
    _focusNode = FocusNode();

    _setupDateFormat();
    _setupDateRange();
    _parseBinding();
    _parseVisibilityBinding();
    _updateTextController();

    // Đăng ký listeners
    _registerBindingListeners();
    _effectiveController.addListener(_onControllerChanged);

    _focusNode.addListener(() {
      if (_focusNode.hasFocus && widget.enabled) {
        _showDatePicker();
      }
    });
  }

  @override
  void didUpdateWidget(CyberDate oldWidget) {
    super.didUpdateWidget(oldWidget);

    bool bindingChanged = false;
    bool visibilityBindingChanged = false;
    bool controllerChanged = widget.controller != oldWidget.controller;

    // ✅ Xử lý controller thay đổi
    if (controllerChanged) {
      oldWidget.controller?.removeListener(_onControllerChanged);

      if (widget.controller == null) {
        // Chuyển sang internal controller
        _internalController ??= CyberDateController();
      } else {
        // Chuyển sang external controller - dispose internal
        _internalController?.dispose();
        _internalController = null;
      }

      _effectiveController.addListener(_onControllerChanged);
      _updateTextController();
    }

    // ✅ Kiểm tra text binding đã thay đổi
    if (widget.text != oldWidget.text) {
      _unregisterBindingListeners();
      _parseBinding();
      bindingChanged = true;
    }

    // ✅ Kiểm tra visibility binding đã thay đổi
    if (widget.isVisible != oldWidget.isVisible) {
      if (!bindingChanged) {
        _unregisterBindingListeners();
      }
      _parseVisibilityBinding();
      visibilityBindingChanged = true;
    }

    // ✅ Đăng ký lại listeners nếu có thay đổi
    if (bindingChanged || visibilityBindingChanged) {
      _registerBindingListeners();
      if (!controllerChanged) {
        _updateTextController();
      }
    }

    // ✅ Xử lý format changes
    if (widget.format != oldWidget.format ||
        widget.formatter != oldWidget.formatter) {
      _setupDateFormat();
      _updateTextController();
    }

    // ✅ Xử lý date range changes
    if (widget.minDate != oldWidget.minDate ||
        widget.maxDate != oldWidget.maxDate) {
      _setupDateRange();
      _validate();
    }

    // ✅ Xử lý validator changes
    if (widget.validator != oldWidget.validator) {
      _validate();
    }

    // ✅ Xử lý error text changes
    if (widget.errorText != oldWidget.errorText) {
      setState(() {});
    }

    // ✅ Xử lý enabled state changes
    if (oldWidget.enabled != widget.enabled) {
      setState(() {});
    }

    // ✅ Xử lý nullValue changes
    if (widget.nullValue != oldWidget.nullValue) {
      _updateTextController();
    }
  }

  @override
  void dispose() {
    _unregisterBindingListeners();
    _effectiveController.removeListener(_onControllerChanged);
    _internalController?.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ============================================================================
  // BINDING MANAGEMENT
  // ============================================================================

  /// ✅ Đăng ký listeners cho binding
  void _registerBindingListeners() {
    if (_boundRow != null) {
      _boundRow!.addListener(_onBindingChanged);
    }
    if (_visibilityBoundRow != null && _visibilityBoundRow != _boundRow) {
      _visibilityBoundRow!.addListener(_onBindingChanged);
    }
  }

  /// ✅ Hủy đăng ký listeners
  void _unregisterBindingListeners() {
    if (_boundRow != null) {
      _boundRow!.removeListener(_onBindingChanged);
    }
    if (_visibilityBoundRow != null && _visibilityBoundRow != _boundRow) {
      _visibilityBoundRow!.removeListener(_onBindingChanged);
    }
  }

  /// ✅ Parse text binding
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

  /// ✅ Parse visibility binding
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

  // ============================================================================
  // DATE SETUP
  // ============================================================================

  void _setupDateFormat() {
    if (widget.formatter != null) {
      _dateFormat = widget.formatter!;
    } else {
      try {
        _dateFormat = DateFormat(widget.format);
      } catch (e) {
        _dateFormat = DateFormat('dd/MM/yyyy');
      }
    }
  }

  void _setupDateRange() {
    final now = DateTime.now();
    _minDate = widget.minDate ?? DateTime(now.year - 100, 1, 1);
    _maxDate = widget.maxDate ?? DateTime(now.year + 100, 12, 31);
  }

  // ============================================================================
  // VALUE MANAGEMENT
  // ============================================================================

  /// ✅ Kiểm tra xem date có phải là nullValue không
  bool _isNullValue(DateTime? date) {
    if (date == null) return true;
    final nullVal = widget.nullValue ?? CyberDate.defaultNullValue;
    return date.year == nullVal.year &&
        date.month == nullVal.month &&
        date.day == nullVal.day;
  }

  /// ✅ Single source of truth for current value
  /// Priority: controller > binding > text
  DateTime? _getCurrentValue() {
    // Priority 1: External controller
    if (widget.controller != null) {
      final value = widget.controller!.value;
      return _isNullValue(value) ? null : value;
    }

    // Priority 2: Binding
    dynamic rawValue;
    if (_boundRow != null && _boundField != null) {
      rawValue = _boundRow![_boundField!];
    }
    // Priority 3: Static text value
    else if (widget.text != null) {
      rawValue = widget.text;
    } else {
      return null;
    }

    // ✅ Convert sang DateTime?
    final parsed = _parseDateTime(rawValue);
    return _isNullValue(parsed) ? null : parsed;
  }

  /// ✅ Parse dynamic value sang DateTime?
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

  /// ✅ Format DateTime sang String để hiển thị
  /// Nếu là nullValue thì trả về empty string để hiển thị hint
  String _formatDate(DateTime? date) {
    if (date == null || _isNullValue(date)) {
      return '';
    }
    return _dateFormat.format(date);
  }

  /// ✅ Update text controller từ binding/controller
  void _updateTextController() {
    final value = _getCurrentValue();
    final displayValue = _formatDate(value);
    _textController.text = displayValue;
    _validate();
  }

  /// ✅ Callback khi controller changed
  void _onControllerChanged() {
    if (_isUpdating) return;

    _isUpdating = true;

    final value = _effectiveController.value;
    final displayValue = _formatDate(value);

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

  /// ✅ Callback khi binding changed
  void _onBindingChanged() {
    if (_isUpdating || _boundRow == null || _boundField == null) return;

    _isUpdating = true;

    final value = _getCurrentValue();
    final displayValue = _formatDate(value);

    // Update text display
    if (_textController.text != displayValue) {
      _textController.text = displayValue;
    }

    // Sync binding to internal controller
    if (widget.controller == null && _internalController!.value != value) {
      _internalController!.setSilently(value);
    }

    // Validate
    _validate();

    _isUpdating = false;

    // Trigger rebuild
    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================================
  // VALIDATION
  // ============================================================================

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

  // ============================================================================
  // DATE PICKER
  // ============================================================================

  /// ✅ Update value từ date picker
  void _updateValue(DateTime newDate) {
    _isUpdating = true;

    // ✅ Update controller/binding
    if (widget.controller == null) {
      _internalController!.value = newDate;
    }

    if (_boundRow != null && _boundField != null) {
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

  /// ✅ Clear value (set về nullValue)
  void _clearValue() {
    _isUpdating = true;

    final nullVal = widget.nullValue ?? CyberDate.defaultNullValue;

    // ✅ Update controller/binding
    if (widget.controller == null) {
      _internalController!.value = nullVal;
    }

    if (_boundRow != null && _boundField != null) {
      _boundRow![_boundField!] = nullVal;
    }

    // Update display - sẽ hiển thị hint text vì là nullValue
    _textController.text = '';

    // Validate
    _validate();

    // Callback với null
    widget.onChanged?.call(null);

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

  // ============================================================================
  // VISIBILITY & VALIDATION HELPERS
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
  // BUILD UI
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    if (!_isVisible()) {
      return const SizedBox.shrink();
    }

    // ✅ Lắng nghe controller changes
    return ListenableBuilder(
      listenable: _effectiveController,
      builder: (context, _) {
        final currentError = widget.errorText ?? _validationError;
        final hasValue = _textController.text.isNotEmpty;

        Widget textField = TextField(
          controller: _textController,
          focusNode: _focusNode,
          readOnly: true,
          enabled: widget.enabled,
          style: widget.style,
          decoration:
              widget.decoration ?? _buildDecoration(currentError, hasValue),
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

        // ✅ Wrap với binding listener nếu có
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

  InputDecoration _buildDecoration(String? errorText, bool hasValue) {
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

    // ✅ Suffix icon: Hiển thị Clear hoặc Dropdown
    Widget? suffixWidget;
    if (widget.enabled) {
      if (hasValue && widget.showClearButton) {
        // Hiển thị nút Clear khi có giá trị
        suffixWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.clear, size: 18),
              onPressed: _clearValue,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.arrow_drop_down, size: 20),
              onPressed: _showDatePicker,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        );
      } else {
        // Chỉ hiển thị dropdown khi không có giá trị
        suffixWidget = IconButton(
          icon: const Icon(Icons.arrow_drop_down, size: 20),
          onPressed: _showDatePicker,
        );
      }
    }

    return InputDecoration(
      hintText: widget.hint ?? 'Chọn ngày',
      hintStyle: TextStyle(
        color: Colors.grey.shade500,
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: iconData != null
          ? Icon(iconData, size: 18)
          : const Icon(Icons.calendar_today, size: 18),
      suffixIcon: suffixWidget,

      // ✅ Border based on error state and borderSize
      border: borderStyle ?? InputBorder.none,
      enabledBorder: borderStyle ?? InputBorder.none,
      focusedBorder: focusedBorderStyle ?? InputBorder.none,
      errorBorder: borderStyle ?? InputBorder.none,
      disabledBorder: InputBorder.none,
      focusedErrorBorder: focusedBorderStyle ?? InputBorder.none,

      // Background
      filled: true,
      fillColor: widget.enabled
          ? (widget.backgroundColor ?? const Color(0xFFF5F5F5))
          : const Color(0xFFE0E0E0),

      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}

// ============================================================================
// iOS-STYLE DATE PICKER SHEET
// ============================================================================

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
