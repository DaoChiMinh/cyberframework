import 'dart:math';
import 'package:cyberframework/cyberframework.dart';

/// CyberNumeric - Widget nhập liệu số với binding hỗ trợ
///
/// Triết lý ERP/CyberFramework:
/// - Internal Controller tự động (không cần khai báo)
/// - Hỗ trợ binding: text: dr.bind("field_name")
/// - Two-way binding tự động
///
/// ✅ FIXED ISSUES:
/// - Cursor jump bug khi gõ số
/// - Double/triple listeners
/// - Nested ListenableBuilder
/// - Format optimization
///
/// Ví dụ sử dụng:
/// ```dart
/// // Cách 1: Binding với CyberDataRow
/// CyberNumeric(
///   text: dr.bind("so_luong"),
///   label: "Số lượng",
///   format: "#,##0.##",
/// )
///
/// // Cách 2: Giá trị tĩnh
/// CyberNumeric(
///   text: 12345.67,
///   label: "Giá trị",
/// )
///
/// // Cách 3: External controller (advanced)
/// final controller = CyberNumericController(value: 100);
/// CyberNumeric(
///   controller: controller,
///   label: "Điều khiển từ ngoài",
/// )
/// ```
class CyberNumeric extends StatefulWidget {
  /// ⚠️ KHÔNG dùng cả text VÀ controller cùng lúc
  ///
  /// text hỗ trợ:
  /// - Binding: dr.bind("field_name")
  /// - Giá trị tĩnh: 123.45
  /// - null: rỗng
  final dynamic text;

  /// Controller để quản lý state từ bên ngoài (Optional - không bắt buộc)
  /// Chỉ dùng khi cần điều khiển widget từ code
  final CyberNumericController? controller;

  final String? label;
  final String? hint;

  /// Number format pattern: "###,###,##0.##" hoặc "#,##0.00"
  final String? format;

  /// Icon code hiển thị bên trái (VD: "e853")
  final String? prefixIcon;

  /// Kích thước border (đơn vị: pixel)
  final int? borderSize;

  /// Border radius (đơn vị: pixel)
  final int? borderRadius;

  final bool enabled;
  final dynamic isVisible;
  final TextStyle? style;
  final InputDecoration? decoration;

  /// ✅ Callback trả num? (không phải String)
  final ValueChanged<num?>? onChanged;
  final Function(num?)? onLeaver;

  /// Giá trị min
  final num? min;

  /// Giá trị max
  final num? max;

  final bool isShowLabel;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? focusColor;
  final TextStyle? labelStyle;
  final dynamic isCheckEmpty;

  const CyberNumeric({
    super.key,
    this.text,
    this.controller,
    this.label,
    this.hint,
    this.format = "### ### ### ###.##",
    this.prefixIcon,
    this.borderSize = 1,
    this.borderRadius,
    this.enabled = true,
    this.isVisible = true,
    this.style,
    this.decoration,
    this.onChanged,
    this.onLeaver,
    this.min,
    this.max,
    this.isShowLabel = true,
    this.backgroundColor,
    this.borderColor = Colors.transparent,
    this.focusColor,
    this.labelStyle,
    this.isCheckEmpty = false,
  }) : assert(
         controller == null || text == null,
         'CyberNumeric: không được dùng cả text và controller cùng lúc',
       );

  @override
  State<CyberNumeric> createState() => _CyberNumericState();
}

class _CyberNumericState extends State<CyberNumeric> {
  late TextEditingController _textController;
  late FocusNode _focusNode;

  // Binding state
  CyberDataRow? _boundRow;
  String? _boundField;
  CyberDataRow? _visibilityBoundRow;
  String? _visibilityBoundField;
  bool _isUpdating = false;

  /// ✅ Internal controller (tạo tự động nếu không có external controller)
  CyberNumericController? _internalController;

  /// ✅ Effective controller - ưu tiên external, fallback internal
  CyberNumericController get _effectiveController =>
      widget.controller ?? _internalController!;

  // ✅ Cache format configuration để tối ưu performance
  late String _thousandsSeparator;
  late int _decimalPlaces;

  @override
  void initState() {
    super.initState();

    // ✅ Parse format config
    _parseFormatConfig();

    // ✅ Tạo internal controller nếu không có external controller
    if (widget.controller == null) {
      _internalController = CyberNumericController(
        value: null,
        enabled: widget.enabled,
        min: widget.min,
        max: widget.max,
      );
    }

    // Khởi tạo text controller và focus node
    _textController = TextEditingController();
    _focusNode = FocusNode();

    // Parse binding và update giá trị ban đầu
    _parseBinding();
    _parseVisibilityBinding();
    _updateControllerValue();

    // ✅ CHỈ listen controller - KHÔNG listen binding trực tiếp
    // Controller sẽ sync với binding thông qua _onTextChanged
    _effectiveController.addListener(_onControllerChanged);

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _validateAndFormat();
        widget.onLeaver?.call(_getCurrentValue());
      }
    });
  }

  @override
  void didUpdateWidget(CyberNumeric oldWidget) {
    super.didUpdateWidget(oldWidget);

    bool controllerChanged = widget.controller != oldWidget.controller;

    // ✅ Update format config nếu format thay đổi
    if (widget.format != oldWidget.format) {
      _parseFormatConfig();
    }

    // ✅ Xử lý controller thay đổi
    if (controllerChanged) {
      oldWidget.controller?.removeListener(_onControllerChanged);

      if (widget.controller == null) {
        // Chuyển sang internal controller
        _internalController ??= CyberNumericController(
          value: null,
          enabled: widget.enabled,
          min: widget.min,
          max: widget.max,
        );
      } else {
        // Chuyển sang external controller - dispose internal
        _internalController?.dispose();
        _internalController = null;
      }

      _effectiveController.addListener(_onControllerChanged);
      _updateControllerValue();
    }

    // ✅ Kiểm tra binding đã thay đổi
    if (widget.text != oldWidget.text) {
      _parseBinding();
      if (!controllerChanged) {
        _updateControllerValue();
      }
    }

    // ✅ Kiểm tra visibility binding đã thay đổi
    if (widget.isVisible != oldWidget.isVisible) {
      _parseVisibilityBinding();
    }

    // ✅ Cập nhật giá trị nếu format thay đổi
    if (widget.format != oldWidget.format && !controllerChanged) {
      _updateControllerValue();
    }

    // ✅ Update min/max trong internal controller
    if (widget.min != oldWidget.min || widget.max != oldWidget.max) {
      if (widget.controller == null) {
        _internalController?.setMinMax(min: widget.min, max: widget.max);
      }
    }
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_onControllerChanged);
    _internalController?.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ============================================================================
  // FORMAT CONFIG
  // ============================================================================

  /// ✅ Parse và cache format configuration
  void _parseFormatConfig() {
    _thousandsSeparator = widget.format!.contains(' ') ? ' ' : ',';

    _decimalPlaces = 0;
    if (widget.format!.contains('.')) {
      var parts = widget.format!.split('.');
      if (parts.length > 1) {
        _decimalPlaces = parts[1].length;
      }
    }
  }

  // ============================================================================
  // BINDING MANAGEMENT
  // ============================================================================

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

    // Nếu không phải binding, clear binding state
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
  // VALUE MANAGEMENT
  // ============================================================================

  /// ✅ Source of truth: num? (không phải String)
  /// Priority: controller > binding > text
  num? _getCurrentValue() {
    // Priority 1: External controller
    if (widget.controller != null) {
      return widget.controller!.value;
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

    // ✅ Convert sang num?
    return _parseNum(rawValue);
  }

  /// ✅ Parse về num? (hỗ trợ int, double, String)
  num? _parseNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) {
      return num.tryParse(value);
    }
    return null;
  }

  /// ✅ Update controller value từ binding/text
  void _updateControllerValue() {
    num? value = _getCurrentValue();
    final displayValue = _formatValue(value);

    // ✅ Update text controller
    _textController.text = displayValue;
  }

  /// ✅ Callback khi controller changed
  void _onControllerChanged() {
    if (_isUpdating) return;

    final value = _effectiveController.value;
    final displayValue = _formatValue(value);

    if (_textController.text != displayValue) {
      // ✅ Preserve cursor position
      final oldSelection = _textController.selection;
      _textController.text = displayValue;

      // Restore cursor hoặc đặt ở cuối nếu selection không hợp lệ
      if (oldSelection.isValid &&
          oldSelection.baseOffset <= displayValue.length) {
        _textController.selection = oldSelection;
      } else {
        _textController.selection = TextSelection.collapsed(
          offset: displayValue.length,
        );
      }
    }
  }

  // ============================================================================
  // FORMATTING & VALIDATION
  // ============================================================================

  /// ✅ Format num? về String để hiển thị (FULL format - dùng khi blur)
  String _formatValue(num? value) {
    if (value == null) return '';

    // ✅ Dùng cached config
    double doubleValue = value.toDouble();

    // Format number with decimal places
    String numStr = doubleValue.toStringAsFixed(_decimalPlaces);
    var parts = numStr.split('.');
    String intPart = parts[0];
    String decPart = parts.length > 1 ? parts[1] : '';

    // Add thousands separator
    String formatted = _formatIntegerPart(intPart);

    if (decPart.isNotEmpty) {
      formatted += '.$decPart';
    }

    return formatted;
  }

  /// ✅ FIX CURSOR JUMP: Format PARTIAL - chỉ format thousands, giữ nguyên decimal input
  /// Dùng trong khi typing để tránh cursor jump
  String _formatValuePartial(String cleanValue) {
    if (cleanValue.isEmpty) return '';

    // Split integer và decimal parts
    final parts = cleanValue.split('.');
    String intPart = parts[0];
    String decPart = parts.length > 1 ? parts[1] : '';

    // Format chỉ phần integer với thousands separator
    String formatted = _formatIntegerPart(intPart);

    // ✅ GIỮ NGUYÊN decimal part từ user input
    // KHÔNG tự động thêm .00
    if (decPart.isNotEmpty) {
      formatted += '.$decPart';
    } else if (cleanValue.endsWith('.')) {
      // User vừa gõ dấu chấm → giữ lại
      formatted += '.';
    }

    return formatted;
  }

  /// ✅ Format phần integer với thousands separator (optimized với StringBuffer)
  String _formatIntegerPart(String intPart) {
    if (intPart.isEmpty) return '';
    if (intPart.length <= 3) return intPart;

    final buffer = StringBuffer();
    int count = 0;

    for (int i = intPart.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        buffer.write(_thousandsSeparator);
      }
      buffer.write(intPart[i]);
      count++;
    }

    // Reverse string
    return buffer.toString().split('').reversed.join('');
  }

  /// ✅ Parse input String về num?
  num? _parseInput(String input) {
    if (input.isEmpty) return null;

    // Remove thousands separator
    String cleaned = input.replaceAll(_thousandsSeparator, '');

    // Remove whitespace
    cleaned = cleaned.trim();

    return num.tryParse(cleaned);
  }

  /// ✅ Validate value theo min/max
  num? _validateValue(num? value) {
    if (value == null) return null;

    final min = widget.min ?? _effectiveController.min;
    final max = widget.max ?? _effectiveController.max;

    if (min != null && value < min) {
      return min;
    }
    if (max != null && value > max) {
      return max;
    }
    return value;
  }

  /// ✅ Validate và format khi mất focus
  void _validateAndFormat() {
    num? value = _parseInput(_textController.text);
    value = _validateValue(value);

    // ✅ Update binding và internal controller
    _isUpdating = true;

    if (widget.controller == null) {
      _internalController?.setValue(value);
    }

    if (_boundRow != null && _boundField != null) {
      _boundRow![_boundField!] = value;
    }

    _isUpdating = false;

    final displayValue = _formatValue(value);
    if (_textController.text != displayValue) {
      _textController.text = displayValue;
    }
  }

  // ============================================================================
  // TEXT INPUT HANDLING
  // ============================================================================

  /// ✅ FIX CURSOR JUMP: Callback khi text changed (real-time formatting)
  void _onTextChanged(String value) {
    if (_isUpdating) return;

    // ✅ Preserve cursor position TRƯỚC khi format
    final oldSelection = _textController.selection;
    final oldText = _textController.text;

    // Remove thousands separator để parse
    String cleanValue = value.replaceAll(_thousandsSeparator, '');

    // ✅ Ngăn chặn nhiều dấu chấm
    if (cleanValue.split(".").length > 2) {
      // Có nhiều hơn 1 dấu chấm → bỏ qua thay đổi
      return;
    }

    _isUpdating = true;

    // ✅ Parse input về num?
    num? numericValue = _parseInput(cleanValue);

    // ✅ Update internal controller
    if (widget.controller == null) {
      _internalController?.setValue(numericValue);
    }

    // ✅ Update binding
    if (_boundRow != null && _boundField != null) {
      _boundRow![_boundField!] = numericValue;
    }

    // ✅ Callback
    widget.onChanged?.call(numericValue);

    // ✅ FIX CURSOR JUMP: Dùng partial format trong khi typing
    // CHỈ format thousands, KHÔNG thêm decimal tự động
    final formattedValue = _formatValuePartial(cleanValue);

    if (_textController.text != formattedValue) {
      // ✅ Calculate cursor position based on separator changes
      final newCursorPos = _calculateCursorPosition(
        oldText,
        formattedValue,
        oldSelection.baseOffset,
      );

      _textController.value = TextEditingValue(
        text: formattedValue,
        selection: TextSelection.collapsed(offset: newCursorPos),
      );
    }

    _isUpdating = false;
  }

  /// ✅ Calculate cursor position sau khi format (handle separator changes)
  int _calculateCursorPosition(String oldText, String newText, int oldPos) {
    // Count số separator trước cursor position
    int oldSepCountBefore = 0;
    int newSepCountBefore = 0;

    // Count separators in old text before cursor
    for (int i = 0; i < min(oldPos, oldText.length); i++) {
      if (oldText[i] == _thousandsSeparator) {
        oldSepCountBefore++;
      }
    }

    // Count separators in new text before equivalent position
    final rawOldPos = oldPos - oldSepCountBefore;
    int rawNewPos = 0;
    for (int i = 0; i < newText.length; i++) {
      if (newText[i] != _thousandsSeparator) {
        if (rawNewPos >= rawOldPos) {
          return i;
        }
        rawNewPos++;
      }
    }

    return newText.length;
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

    // ✅ FIX DOUBLE REBUILD: Dùng Listenable.merge thay vì nested ListenableBuilder
    final listenable = _boundRow != null
        ? Listenable.merge([_effectiveController, _boundRow!])
        : _effectiveController;

    return ListenableBuilder(
      listenable: listenable,
      builder: (context, _) {
        final isEnabled = widget.enabled && _effectiveController.enabled;

        Widget textField = TextField(
          controller: _textController,
          onChanged: _onTextChanged,
          focusNode: _focusNode,
          textAlign: TextAlign.end,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: false,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9\.\,\-\s]')),
          ],
          enabled: isEnabled,
          style: widget.style,
          decoration: widget.decoration ?? _buildDecoration(isEnabled),
        );

        if (widget.isShowLabel &&
            widget.label != null &&
            widget.decoration == null) {
          return Column(
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
            ],
          );
        }

        return textField;
      },
    );
  }

  InputDecoration _buildDecoration(bool isEnabled) {
    final iconData = widget.prefixIcon == null
        ? null
        : v_parseIcon(widget.prefixIcon!);
    final borderWidth = widget.borderSize?.toDouble() ?? 0.0;
    final radius = widget.borderRadius?.toDouble() ?? 4.0;
    final effectiveBorderColor = widget.borderColor ?? Colors.grey;

    // Tạo border style dựa vào borderSize
    final borderStyle = borderWidth > 0
        ? OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide(
              color: effectiveBorderColor,
              width: borderWidth,
            ),
          )
        : null;

    return InputDecoration(
      hintText: widget.hint,
      hintStyle: TextStyle(
        color: Colors.grey.shade500,
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: iconData != null ? Icon(iconData, size: 18) : null,

      // Áp dụng border nếu có borderSize > 0
      border: borderStyle ?? InputBorder.none,
      enabledBorder: borderStyle ?? InputBorder.none,
      focusedBorder: borderStyle ?? InputBorder.none,
      errorBorder: borderStyle ?? InputBorder.none,
      disabledBorder: borderStyle ?? InputBorder.none,
      focusedErrorBorder: borderStyle ?? InputBorder.none,

      // ✅ Background đồng bộ
      filled: true,
      fillColor: isEnabled
          ? (widget.backgroundColor ?? const Color(0xFFF5F5F5))
          : const Color(0xFFE0E0E0),

      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}
