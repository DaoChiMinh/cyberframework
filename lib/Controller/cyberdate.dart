import 'dart:math';
import 'package:cyberframework/cyberframework.dart';
import 'package:intl/intl.dart';

// ============================================================================
// PICKER STYLE ENUM
// ============================================================================

/// Kiểu picker hiển thị khi người dùng chọn ngày
enum CyberDatePickerStyle {
  /// Picker kiểu iOS - cuộn con lăn ngày/tháng/năm (mặc định)
  scroll,

  /// Picker kiểu lịch tháng - có cả lịch âm và lịch dương
  calendar,
}

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
/// // Cách 2: Picker kiểu lịch tháng (có âm lịch)
/// CyberDate(
///   text: dr.bind("ngay_xuat_phat"),
///   label: "Ngày xuất phát",
///   pickerStyle: CyberDatePickerStyle.calendar,
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
///   nullValue: DateTime(1900, 1, 1),
///   showClearButton: true,
/// )
///
/// // Cách 5: Giữ nguyên giờ phút giây khi chọn ngày mới
/// CyberDate(
///   text: dr.bind("Ngay_BD"),
///   isResetTime: false,
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

  /// Hiển thị prefix icon hay không (mặc định: true)
  final bool showprefixIcon;

  /// Hiển thị suffix icon (dropdown) hay không (mặc định: true)
  final bool showSuffixIcon;

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

  /// Reset time về 00:00:00 khi chọn ngày mới (mặc định: true)
  /// Nếu false: giữ nguyên giờ:phút:giây từ giá trị cũ
  final bool isResetTime;

  /// Kiểu picker hiển thị khi người dùng nhấn vào field
  ///
  /// - [CyberDatePickerStyle.scroll]: Picker cuộn kiểu iOS (mặc định)
  /// - [CyberDatePickerStyle.calendar]: Picker kiểu lịch tháng có âm lịch
  ///
  /// ```dart
  /// CyberDate(
  ///   pickerStyle: CyberDatePickerStyle.calendar, // Hiển thị lịch tháng
  /// )
  /// ```
  final CyberDatePickerStyle pickerStyle;

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
    this.showprefixIcon = true,
    this.showSuffixIcon = true,
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
    this.showClearButton = false,
    this.isResetTime = true,
    this.pickerStyle = CyberDatePickerStyle.scroll,
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

    if (controllerChanged) {
      oldWidget.controller?.removeListener(_onControllerChanged);

      if (widget.controller == null) {
        _internalController ??= CyberDateController();
      } else {
        _internalController?.dispose();
        _internalController = null;
      }

      _effectiveController.addListener(_onControllerChanged);
      _updateTextController();
    }

    if (widget.text != oldWidget.text) {
      _unregisterBindingListeners();
      _parseBinding();
      bindingChanged = true;
    }

    if (widget.isVisible != oldWidget.isVisible) {
      if (!bindingChanged) {
        _unregisterBindingListeners();
      }
      _parseVisibilityBinding();
      visibilityBindingChanged = true;
    }

    if (bindingChanged || visibilityBindingChanged) {
      _registerBindingListeners();
      if (!controllerChanged) {
        _updateTextController();
      }
    }

    if (widget.format != oldWidget.format ||
        widget.formatter != oldWidget.formatter) {
      _setupDateFormat();
      _updateTextController();
    }

    if (widget.minDate != oldWidget.minDate ||
        widget.maxDate != oldWidget.maxDate) {
      _setupDateRange();
      _validate();
    }

    if (widget.validator != oldWidget.validator) {
      _validate();
    }

    if (widget.errorText != oldWidget.errorText) {
      setState(() {});
    }

    if (oldWidget.enabled != widget.enabled) {
      setState(() {});
    }

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

  void _registerBindingListeners() {
    if (_boundRow != null) {
      _boundRow!.addListener(_onBindingChanged);
    }
    if (_visibilityBoundRow != null && _visibilityBoundRow != _boundRow) {
      _visibilityBoundRow!.addListener(_onBindingChanged);
    }
  }

  void _unregisterBindingListeners() {
    if (_boundRow != null) {
      _boundRow!.removeListener(_onBindingChanged);
    }
    if (_visibilityBoundRow != null && _visibilityBoundRow != _boundRow) {
      _visibilityBoundRow!.removeListener(_onBindingChanged);
    }
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
    // ✅ Normalize về 00:00:00 để tránh lỗi so sánh khi minDate = DateTime.now()
    // Ví dụ: minDate = DateTime.now() lúc 09:28 → normalize → 2026-03-17 00:00:00
    // Ngày được chọn từ lịch = DateTime(2026,3,17) = 00:00:00 → không bị báo lỗi
    final minRaw = widget.minDate ?? DateTime(now.year - 100, 1, 1);
    final maxRaw = widget.maxDate ?? DateTime(now.year + 100, 12, 31);
    _minDate = DateTime(minRaw.year, minRaw.month, minRaw.day);
    _maxDate = DateTime(maxRaw.year, maxRaw.month, maxRaw.day);
  }

  // ============================================================================
  // VALUE MANAGEMENT
  // ============================================================================

  bool _isNullValue(DateTime? date) {
    if (date == null) return true;
    final nullVal = widget.nullValue ?? CyberDate.defaultNullValue;
    return date.year == nullVal.year &&
        date.month == nullVal.month &&
        date.day == nullVal.day;
  }

  DateTime? _getCurrentValue() {
    if (widget.controller != null) {
      final value = widget.controller!.value;
      return _isNullValue(value) ? null : value;
    }

    dynamic rawValue;
    if (_boundRow != null && _boundField != null) {
      rawValue = _boundRow![_boundField!];
    } else if (widget.text != null) {
      rawValue = widget.text;
    } else {
      return null;
    }

    final parsed = _parseDateTime(rawValue);
    return _isNullValue(parsed) ? null : parsed;
  }

  DateTime? _getRawBindingValue() {
    if (_boundRow != null && _boundField != null) {
      return _parseDateTime(_boundRow![_boundField!]);
    }
    if (widget.text != null && widget.text is! CyberBindingExpression) {
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

  String _formatDate(DateTime? date) {
    if (date == null || _isNullValue(date)) {
      return '';
    }
    return _dateFormat.format(date);
  }

  void _updateTextController() {
    final value = _getCurrentValue();
    final displayValue = _formatDate(value);
    _textController.text = displayValue;
    _validate();
  }

  void _onControllerChanged() {
    if (_isUpdating) return;

    _isUpdating = true;

    final value = _effectiveController.value;
    final displayValue = _formatDate(value);

    if (_textController.text != displayValue) {
      _textController.text = displayValue;
    }

    if (_boundRow != null && _boundField != null) {
      if (_boundRow![_boundField!] != value) {
        _boundRow![_boundField!] = value;
      }
    }

    _validate();

    _isUpdating = false;

    if (mounted) {
      setState(() {});
    }
  }

  void _onBindingChanged() {
    if (_isUpdating || _boundRow == null || _boundField == null) return;

    _isUpdating = true;

    final value = _getCurrentValue();
    final displayValue = _formatDate(value);

    if (_textController.text != displayValue) {
      _textController.text = displayValue;
    }

    if (widget.controller == null && _internalController!.value != value) {
      _internalController!.setSilently(value);
    }

    _validate();

    _isUpdating = false;

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================================
  // VALIDATION
  // ============================================================================

  void _validate() {
    final value = _getCurrentValue();

    if (widget.validator != null) {
      _validationError = widget.validator!(value);
      return;
    }

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

    if (_isCheckEmpty() && value == null) {
      _validationError = 'Vui lòng chọn ngày';
      return;
    }

    _validationError = null;
  }

  // ============================================================================
  // DATE PICKER
  // ============================================================================

  void _updateValue(DateTime newDate) {
    _isUpdating = true;

    DateTime finalDateTime;

    if (!widget.isResetTime) {
      final oldValue = _getRawBindingValue();
      if (oldValue != null) {
        finalDateTime = DateTime(
          newDate.year,
          newDate.month,
          newDate.day,
          oldValue.hour,
          oldValue.minute,
          oldValue.second,
        );
      } else {
        finalDateTime = newDate;
      }
    } else {
      finalDateTime = DateTime(newDate.year, newDate.month, newDate.day);
    }

    if (widget.controller == null) {
      _internalController!.value = finalDateTime;
    }

    if (_boundRow != null && _boundField != null) {
      final originalValue = _boundRow![_boundField!];

      if (originalValue is String) {
        _boundRow![_boundField!] = finalDateTime.toIso8601String();
      } else {
        _boundRow![_boundField!] = finalDateTime;
      }
    }

    _textController.text = _formatDate(finalDateTime);

    _validate();

    widget.onChanged?.call(finalDateTime);

    _isUpdating = false;

    if (mounted) {
      setState(() {});
    }
  }

  void _clearValue() {
    _isUpdating = true;

    final nullVal = widget.nullValue ?? CyberDate.defaultNullValue;

    if (widget.controller == null) {
      _internalController!.value = nullVal;
    }

    if (_boundRow != null && _boundField != null) {
      final originalValue = _boundRow![_boundField!];

      if (originalValue is String) {
        _boundRow![_boundField!] = nullVal.toIso8601String();
      } else {
        _boundRow![_boundField!] = nullVal;
      }
    }

    _textController.text = '';

    _validate();

    widget.onChanged?.call(null);

    _isUpdating = false;

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _showDatePicker() async {
    _focusNode.unfocus();

    final currentValue = _getCurrentValue() ?? DateTime.now();

    final result = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        // ✅ Chọn picker theo pickerStyle
        if (widget.pickerStyle == CyberDatePickerStyle.calendar) {
          return _CalendarDatePickerSheet(
            initialDate: currentValue,
            minDate: _minDate,
            maxDate: _maxDate,
          );
        }
        // Mặc định: iOS scroll picker
        return _IOSDatePickerSheet(
          initialDate: currentValue,
          minDate: _minDate,
          maxDate: _maxDate,
          dateFormat: _dateFormat,
        );
      },
    );

    if (result != null) {
      _updateValue(result);

      if (widget.onLeaver != null) {
        DateTime finalDateTime;
        if (!widget.isResetTime) {
          final oldValue = _getRawBindingValue();
          if (oldValue != null) {
            finalDateTime = DateTime(
              result.year,
              result.month,
              result.day,
              oldValue.hour,
              oldValue.minute,
              oldValue.second,
            );
          } else {
            finalDateTime = result;
          }
        } else {
          finalDateTime = DateTime(result.year, result.month, result.day);
        }
        widget.onLeaver!(finalDateTime);
      }
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

    Widget? suffixWidget;
    if (widget.enabled && widget.showSuffixIcon) {
      if (hasValue && widget.showClearButton) {
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
      prefixIcon: widget.showprefixIcon
          ? (iconData != null
                ? Icon(iconData, size: 18)
                : const Icon(Icons.calendar_today, size: 18))
          : null,
      suffixIcon: suffixWidget,
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
// LUNAR CALENDAR UTILITY (Thuật toán âm lịch Việt Nam - Ho Ngoc Duc)
// ============================================================================

/// Tiện ích chuyển đổi lịch dương sang lịch âm Việt Nam
/// Thuật toán: Ho Ngoc Duc (https://www.informatik.uni-leipzig.de/~duc/amlich/)
/// Múi giờ: UTC+7 (Việt Nam)
///
/// FIX quan trọng: JD (Julian Day) bắt đầu từ **trưa UTC**, trong khi ngày
/// dân dụng bắt đầu từ **nửa đêm**. Khi trăng mới xảy ra sau 12:00 UTC
/// (ví dụ 01:23 UTC ngày hôm sau = 08:23 giờ Hà Nội), thuật toán gốc
/// INT(newMoon) cho kết quả sai lệch 1 ngày. Fix: dùng [_newMoonDay] =
/// INT(newMoon + (12 + TZ) / 24) để quy về ngày dân dụng địa phương.
class _LunarUtils {
  static const int _TZ = 7;

  /// Hệ số chuyển JD (noon UTC) → ngày dân dụng Vietnam (UTC+7)
  /// = (12 + 7) / 24 = 19/24
  static const double _civilOffset = (12 + _TZ) / 24.0;

  /// Tương đương Math.floor() trong JS (đúng với cả số âm)
  static int _INT(double d) => d.floor();

  // ── Julian Day Number ─────────────────────────────────────────────────────

  static int _jdFromDate(int dd, int mm, int yy) {
    final int a = _INT((14 - mm) / 12);
    final int y = yy + 4800 - a;
    final int m = mm + 12 * a - 3;
    int jd =
        dd +
        _INT((153 * m + 2) / 5) +
        365 * y +
        _INT(y / 4) -
        _INT(y / 100) +
        _INT(y / 400) -
        32045;
    if (jd < 2299161) {
      jd = dd + _INT((153 * m + 2) / 5) + 365 * y + _INT(y / 4) - 32083;
    }
    return jd;
  }

  /// Public alias dùng cho tính hoàng đạo / hắc đạo
  static int jdFromDate(int dd, int mm, int yy) => _jdFromDate(dd, mm, yy);

  // ── Ngày Trăng Mới ────────────────────────────────────────────────────────

  /// Trả về JD thực (float) của trăng mới thứ k
  static double _newMoon(int k) {
    final double T = k / 1236.85;
    final double T2 = T * T;
    final double T3 = T2 * T;
    const double dr = pi / 180;

    double jd1 =
        2415020.75933 + 29.53058868 * k + 0.0001178 * T2 - 0.000000155 * T3;
    jd1 += 0.00033 * sin((166.56 + 132.87 * T - 0.009173 * T2) * dr);

    final double M =
        359.2242 + 29.10535608 * k - 0.0000333 * T2 - 0.00000347 * T3;
    final double Mpr =
        306.0253 + 385.81691806 * k + 0.0107306 * T2 + 0.00001236 * T3;
    final double F =
        21.2964 + 390.67050646 * k - 0.0016528 * T2 - 0.00000239 * T3;

    double c1 = (0.1734 - 0.000393 * T) * sin(M * dr);
    c1 += 0.0021 * sin(2 * dr * M);
    c1 -= 0.4068 * sin(Mpr * dr);
    c1 += 0.0161 * sin(2 * dr * Mpr);
    c1 -= 0.0004 * sin(3 * dr * Mpr);
    c1 += 0.0104 * sin(2 * dr * F);
    c1 -= 0.0051 * sin((M + Mpr) * dr);
    c1 -= 0.0074 * sin((M - Mpr) * dr);
    c1 += 0.0004 * sin((2 * F + M) * dr);
    c1 -= 0.0004 * sin((2 * F - M) * dr);
    c1 -= 0.0006 * sin((2 * F + Mpr) * dr);
    c1 += 0.0010 * sin((2 * F - Mpr) * dr);
    c1 += 0.0005 * sin((M + 2 * Mpr) * dr);

    // T*T2 = T³ (không phải T*T3 = T⁴)
    final double deltat = (T < -11)
        ? 0.001 +
              0.000839 * T +
              0.0002261 * T2 -
              0.00000845 * T3 -
              0.000000081 * T * T2
        : -0.000278 + 0.000265 * T + 0.000262 * T2;

    return jd1 + c1 - deltat;
  }

  /// ✅ Ngày dân dụng Vietnam (JD integer) của trăng mới thứ k.
  ///
  /// Khác với INT(_newMoon(k)): hệ số [_civilOffset] = 19/24 bù trừ việc
  /// JD bắt đầu từ trưa UTC, đảm bảo quy đúng sang ngày dân dụng UTC+7.
  ///
  /// Ví dụ: trăng mới ngày 19/03/2026 lúc 01:23 UTC (08:23 Hà Nội):
  ///   raw newMoon = 2461118.559
  ///   INT(raw)         = 2461118  → sai (18/03)
  ///   INT(raw + 19/24) = 2461119  → đúng (19/03) ✓
  static int _newMoonDay(int k) => _INT(_newMoon(k) + _civilOffset);

  // ── Kinh Độ Mặt Trời ──────────────────────────────────────────────────────

  static int _sunLongitude(double jdn) {
    final double T = (jdn - 2451545.0) / 36525;
    final double T2 = T * T;
    const double dr = pi / 180;

    final double M =
        357.5291 + 35999.0503 * T - 0.0001559 * T2 - 0.00000048 * T * T2;
    final double L0 = 280.46646 + 36000.76983 * T + 0.0003032 * T2;

    double DL = (1.9146 - 0.004817 * T - 0.000014 * T2) * sin(dr * M);
    DL += (0.019993 - 0.000101 * T) * sin(dr * 2 * M);
    DL += 0.00029 * sin(dr * 3 * M);

    double L = (L0 + DL) * dr;
    L -= 2 * pi * _INT(L / (2 * pi));
    return _INT(L / pi * 6);
  }

  // ── Tháng 11 Âm Lịch ──────────────────────────────────────────────────────

  /// Trả về ngày dân dụng Vietnam (JD integer) của đầu tháng 11 âm lịch năm [yy].
  static int _getLunarMonth11(int yy) {
    final double off = _jdFromDate(31, 12, yy) - 2415021.076998695;
    int k = _INT(off / 29.530588853);
    // sunLongitude check dùng INT(newMoon) gốc để đúng thiên văn
    final int nm0 = _INT(_newMoon(k));
    if (_sunLongitude(nm0 + 0.5 + _TZ / 24.0) >= 9) {
      k = k - 1;
    }
    // ✅ Trả về ngày dân dụng Vietnam
    return _newMoonDay(k);
  }

  // ── Tháng Nhuận ───────────────────────────────────────────────────────────

  static int _getLeapMonthOffset(int a11) {
    final int k = _INT((a11 - 2415021.076998695) / 29.530588853 + 0.5);
    int last = 0;
    int i = 1;
    int arc = _sunLongitude(_INT(_newMoon(k + i)) + 0.5 + _TZ / 24.0);
    do {
      last = arc;
      i++;
      arc = _sunLongitude(_INT(_newMoon(k + i)) + 0.5 + _TZ / 24.0);
    } while (arc != last && i < 14);
    return i - 1;
  }

  // ── API Công Khai ─────────────────────────────────────────────────────────

  /// Chuyển ngày dương lịch → âm lịch Việt Nam (UTC+7).
  ///
  /// Trả về `[lunarDay, lunarMonth, lunarYear, isLeap]`
  /// - `isLeap = 1` nếu là tháng nhuận, `0` nếu không
  ///
  /// ```dart
  /// _LunarUtils.toLunar(18, 3, 2026) // → [30, 1, 2026, 0] ✓
  /// ```
  static List<int> toLunar(int dd, int mm, int yy) {
    final int dayNumber = _jdFromDate(dd, mm, yy);
    final int k = _INT((dayNumber - 2415021.076998695) / 29.530588853);

    // ✅ Dùng _newMoonDay thay cho INT(_newMoon) — đúng múi giờ Vietnam
    int monthStart = _newMoonDay(k + 1);
    if (monthStart > dayNumber) {
      monthStart = _newMoonDay(k);
    }

    int a11 = _getLunarMonth11(yy);
    int b11 = a11;
    int lunarYear;
    if (a11 >= monthStart) {
      lunarYear = yy;
      a11 = _getLunarMonth11(yy - 1);
    } else {
      lunarYear = yy + 1;
      b11 = _getLunarMonth11(yy + 1);
    }

    final int lunarDay = dayNumber - monthStart + 1;
    final int diff = _INT((monthStart - a11) / 29);
    int lunarLeap = 0;
    int lunarMonth = diff + 11;

    if (b11 - a11 > 365) {
      final int leapMonthDiff = _getLeapMonthOffset(a11);
      if (diff >= leapMonthDiff) {
        lunarMonth = diff + 10;
        if (diff == leapMonthDiff) {
          lunarLeap = 1;
        }
      }
    }

    if (lunarMonth > 12) lunarMonth -= 12;
    if (lunarMonth >= 11 && diff < 4) lunarYear -= 1;

    return [lunarDay, lunarMonth, lunarYear, lunarLeap];
  }
}

// ============================================================================
// CALENDAR DATE PICKER SHEET (Lịch tháng có âm lịch)
// ============================================================================

class _CalendarDatePickerSheet extends StatefulWidget {
  final DateTime initialDate;
  final DateTime minDate;
  final DateTime maxDate;

  const _CalendarDatePickerSheet({
    required this.initialDate,
    required this.minDate,
    required this.maxDate,
  });

  @override
  State<_CalendarDatePickerSheet> createState() =>
      _CalendarDatePickerSheetState();
}

class _CalendarDatePickerSheetState extends State<_CalendarDatePickerSheet> {
  late DateTime _viewMonth;
  late DateTime _selectedDate;

  static const List<String> _dayHeaders = [
    'T2',
    'T3',
    'T4',
    'T5',
    'T6',
    'T7',
    'CN',
  ];
  static const Color _primaryGreen = Color(0xFF2DB54B);

  @override
  void initState() {
    super.initState();
    final init = widget.initialDate;
    _selectedDate = DateTime(init.year, init.month, init.day);
    _viewMonth = DateTime(init.year, init.month, 1);
  }

  // ============================================================================
  // NAVIGATION
  // ============================================================================

  void _prevMonth() {
    if (!_canGoPrev) return;
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    if (!_canGoNext) return;
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 1);
    });
  }

  void _goToToday() {
    if (!_isTodayInRange) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    Navigator.pop(context, today);
  }

  // ============================================================================
  // CALENDAR LOGIC
  // ============================================================================

  /// Xây dựng danh sách ngày trong lịch tháng (bao gồm ngày tháng trước/sau)
  /// Tuần bắt đầu từ Thứ 2 (chuẩn Việt Nam)
  List<DateTime> _buildCalendarDays() {
    final firstDay = _viewMonth;
    // weekday: 1=T2, 7=CN -> offset = weekday - 1
    final int startOffset = firstDay.weekday - 1;
    final int daysInMonth = DateTime(
      _viewMonth.year,
      _viewMonth.month + 1,
      0,
    ).day;

    final List<DateTime> days = [];

    // Ngày tháng trước
    for (int i = startOffset; i > 0; i--) {
      days.add(firstDay.subtract(Duration(days: i)));
    }

    // Ngày tháng hiện tại
    for (int d = 1; d <= daysInMonth; d++) {
      days.add(DateTime(_viewMonth.year, _viewMonth.month, d));
    }

    // Ngày tháng sau để đủ số hàng
    final int remaining = 7 - (days.length % 7);
    if (remaining < 7) {
      final lastDay = DateTime(_viewMonth.year, _viewMonth.month, daysInMonth);
      for (int i = 1; i <= remaining; i++) {
        days.add(lastDay.add(Duration(days: i)));
      }
    }

    return days;
  }

  bool _isCurrentMonth(DateTime date) =>
      date.month == _viewMonth.month && date.year == _viewMonth.year;

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isSelected(DateTime date) =>
      date.year == _selectedDate.year &&
      date.month == _selectedDate.month &&
      date.day == _selectedDate.day;

  bool _isSunday(DateTime date) => date.weekday == DateTime.sunday;

  /// Kiểm tra ngày có nằm ngoài khoảng [minDate, maxDate] không
  /// So sánh theo ngày (bỏ phần giờ:phút:giây)
  bool _isDisabled(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final min = DateTime(
      widget.minDate.year,
      widget.minDate.month,
      widget.minDate.day,
    );
    final max = DateTime(
      widget.maxDate.year,
      widget.maxDate.month,
      widget.maxDate.day,
    );
    return d.isBefore(min) || d.isAfter(max);
  }

  /// Tháng hiện tại có thể đi về tháng trước không
  bool get _canGoPrev {
    final prevMonthEnd = DateTime(
      _viewMonth.year,
      _viewMonth.month,
      0,
    ); // ngày cuối tháng trước
    final min = DateTime(
      widget.minDate.year,
      widget.minDate.month,
      widget.minDate.day,
    );
    return !prevMonthEnd.isBefore(min);
  }

  /// Tháng hiện tại có thể đi sang tháng sau không
  bool get _canGoNext {
    final nextMonthStart = DateTime(_viewMonth.year, _viewMonth.month + 1, 1);
    final max = DateTime(
      widget.maxDate.year,
      widget.maxDate.month,
      widget.maxDate.day,
    );
    return !nextMonthStart.isAfter(max);
  }

  bool get _isTodayInRange => !_isDisabled(DateTime.now());

  // ============================================================================
  // LUNAR & HOÀNG ĐẠO
  // ============================================================================

  /// Kết quả thông tin âm lịch + hoàng đạo cho 1 ngày
  ({String label, bool isFirstDay}) _getLunarInfo(DateTime date) {
    final lunar = _LunarUtils.toLunar(date.day, date.month, date.year);
    final int lunarDay = lunar[0];
    final int lunarMonth = lunar[1];
    final int isLeap = lunar[3];

    final String label = (lunarDay == 1)
        ? (isLeap == 1 ? '1/${lunarMonth}n' : '1/$lunarMonth')
        : '$lunarDay';

    return (label: label, isFirstDay: lunarDay == 1);
  }

  // ============================================================================
  // BUILD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    final days = _buildCalendarDays();
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle bar ──────────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Tiêu đề ─────────────────────────────────────────────────────────
          const Text(
            'Chọn ngày',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),

          // ── Điều hướng tháng ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NavButton(
                  icon: Icons.chevron_left,
                  onTap: _prevMonth,
                  disabled: !_canGoPrev,
                ),
                Text(
                  'Tháng ${_viewMonth.month}/${_viewMonth.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                _NavButton(
                  icon: Icons.chevron_right,
                  onTap: _nextMonth,
                  disabled: !_canGoNext,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // ── Header thứ trong tuần ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: _dayHeaders.map((d) {
                final isSun = d == 'CN';
                return Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSun ? Colors.red : Colors.black54,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),

          // ── Grid lịch ───────────────────────────────────────────────────────
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 0.82,
                ),
                itemCount: days.length,
                itemBuilder: (context, index) {
                  return _buildDayCell(days[index]);
                },
              ),
            ),
          ),

          const SizedBox(height: 6),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // ── Các nút bên dưới ─────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(8, 4, 8, bottomPad + 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _isTodayInRange ? _goToToday : null,
                  style: TextButton.styleFrom(
                    foregroundColor: _isTodayInRange
                        ? Colors.black87
                        : Colors.grey[400],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  child: const Text('Hôm nay', style: TextStyle(fontSize: 15)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  child: const Text('Hủy bỏ', style: TextStyle(fontSize: 15)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime date) {
    final isCurrentMonth = _isCurrentMonth(date);
    final isToday = _isToday(date);
    final isSelected = _isSelected(date);
    final isSun = _isSunday(date);
    final isDisabled = _isDisabled(date);

    // ── Thông tin âm lịch + hoàng/hắc đạo ───────────────────────────────────
    final info = _getLunarInfo(date);

    // ── Màu text dương lịch ─────────────────────────────────────────────────
    Color solarColor;
    if (isDisabled) {
      solarColor = Colors.grey[350]!;
    } else if (isSelected) {
      solarColor = Colors.white;
    } else if (!isCurrentMonth) {
      solarColor = Colors.grey[400]!;
    } else if (isToday) {
      solarColor = _primaryGreen;
    } else if (isSun) {
      solarColor = Colors.red;
    } else {
      solarColor = Colors.black87;
    }

    // ── Màu text âm lịch ────────────────────────────────────────────────────
    // Ngày 1 âm lịch → đỏ (trừ khi selected/disabled/tháng khác)
    Color lunarColor;
    if (isDisabled) {
      lunarColor = Colors.grey[350]!;
    } else if (isSelected) {
      lunarColor = Colors.white.withOpacity(0.9);
    } else if (!isCurrentMonth) {
      lunarColor = Colors.grey[400]!;
    } else if (info.isFirstDay) {
      // ✅ Ngày đầu tháng âm → màu đỏ nổi bật
      lunarColor = Colors.red;
    } else {
      lunarColor = Colors.grey[600]!;
    }

    return GestureDetector(
      onTap: isDisabled ? null : () => Navigator.pop(context, date),
      child: Container(
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: isSelected && !isDisabled ? _primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isToday && !isSelected && !isDisabled
              ? Border.all(color: _primaryGreen, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Số ngày dương lịch ─────────────────────────────────────────
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: (isToday || isSelected) && !isDisabled
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: solarColor,
              ),
            ),
            const SizedBox(height: 1),
            // ── Label âm lịch ──────────────────────────────────────────────
            Text(
              info.label,
              style: TextStyle(
                fontSize: 9,
                color: lunarColor,
                fontWeight: info.isFirstDay && !isDisabled && isCurrentMonth
                    ? FontWeight.w700
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nút điều hướng tháng trước/sau
class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool disabled;

  const _NavButton({
    required this.icon,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          icon,
          size: 24,
          color: disabled ? Colors.grey[350] : Colors.black87,
        ),
      ),
    );
  }
}

// ============================================================================
// iOS-STYLE DATE PICKER SHEET (Scroll wheel - giữ nguyên)
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
