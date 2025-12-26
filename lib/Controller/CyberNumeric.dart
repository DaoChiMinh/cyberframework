import 'package:cyberframework/cyberframework.dart';

class CyberNumeric extends StatefulWidget {
  final dynamic text;
  final String? label;
  final String? hint;
  final String?
  format; // Number format pattern: "###,###,##0.##" hoặc "#,##0.00"
  final IconData? icon;
  final bool enabled;
  final dynamic isVisible;
  final TextStyle? style;
  final InputDecoration? decoration;
  final ValueChanged<double>? onChanged;
  final Function(dynamic)? onLeaver;

  /// Giá trị min
  final double? min;

  /// Giá trị max
  final double? max;

  final bool isShowLabel;
  final Color? backgroundColor;
  final Color? focusColor;
  final TextStyle? labelStyle;
  final dynamic isCheckEmpty;
  const CyberNumeric({
    super.key,
    this.text,
    this.label,
    this.hint,
    this.format = "### ### ### ###.##",
    this.icon,
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
    this.focusColor,
    this.labelStyle,
    this.isCheckEmpty = false,
  });

  @override
  State<CyberNumeric> createState() => _CyberNumericState();
}

class _CyberNumericState extends State<CyberNumeric> {
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
    _updateController();
    _parseVisibilityBinding();
    if (_boundRow != null) {
      _boundRow!.addListener(_onBindingChanged);
    }
    if (_visibilityBoundRow != null && _visibilityBoundRow != _boundRow) {
      _visibilityBoundRow!.addListener(_onBindingChanged);
    }
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _validateAndFormat();
        widget.onLeaver?.call(_getCurrentValue());
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

  bool _isCheckEmpty() {
    return _parseBool(widget.isCheckEmpty);
  }

  bool _isVisible() {
    if (_visibilityBoundRow != null && _visibilityBoundField != null) {
      return _parseBool(_visibilityBoundRow![_visibilityBoundField!]);
    }
    return _parseBool(widget.isVisible);
  }

  void _updateController() {
    double value = _getCurrentValue();
    final displayValue = _formatValue(value);

    _textController = TextEditingController(text: displayValue);
  }

  void _onBindingChanged() {
    if (_isUpdating || _boundRow == null || _boundField == null) return;

    final value = _getCurrentValue();
    final displayValue = _formatValue(value);

    if (_textController.text != displayValue) {
      _textController.text = displayValue;
    }
  }

  double _getCurrentValue() {
    dynamic rawValue;

    if (_boundRow != null && _boundField != null) {
      rawValue = _boundRow![_boundField!];
    } else if (widget.text != null) {
      rawValue = widget.text;
    } else {
      return 0.0;
    }

    // ✅ Convert sang double
    if (rawValue is double) return rawValue;
    if (rawValue is int) return rawValue.toDouble();
    if (rawValue is String) {
      return double.tryParse(rawValue) ?? 0.0;
    }

    return 0.0;
  }

  String _formatValue(double value, {bool forceFormat = false}) {
    // Parse pattern to get decimal places
    int decimalPlaces = 0;
    if (widget.format!.contains('.')) {
      var parts = widget.format!.split('.');
      if (parts.length > 1) {
        decimalPlaces = parts[1].replaceAll('#', '').replaceAll('0', '').isEmpty
            ? parts[1].length
            : 2;
      }
    }

    // Format number with decimal places
    String numStr = value.toStringAsFixed(decimalPlaces);
    var parts = numStr.split('.');
    String intPart = parts[0];
    String decPart = parts.length > 1 ? parts[1] : '';

    // Add thousands separator
    String separator = widget.format!.contains(' ') ? ' ' : ',';
    String formatted = '';
    int count = 0;

    for (int i = intPart.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        formatted = separator + formatted;
      }
      formatted = intPart[i] + formatted;
      count++;
    }

    if (decPart.isNotEmpty) {
      formatted += '.$decPart';
    }

    return formatted;
  }

  double _parseInput(String input) {
    if (input.isEmpty) return 0.0;

    // ✅ Remove prefix/suffix
    String cleaned = input;
    String thousandsSep = ',';
    if (widget.format!.contains(RegExp(r'[\u00A0 ]'))) {
      thousandsSep = ' ';
    }

    // ✅ Remove thousands separator
    cleaned = cleaned.replaceAll(thousandsSep, '');

    // ✅ Remove whitespace
    cleaned = cleaned.trim();

    return double.tryParse(cleaned) ?? 0.0;
  }

  double _validateValue(double value) {
    if (widget.min != null && value < widget.min!) {
      return widget.min!;
    }
    if (widget.max != null && value > widget.max!) {
      return widget.max!;
    }
    return value;
  }

  void _validateAndFormat() {
    double value = _parseInput(_textController.text);
    value = _validateValue(value);

    // ✅ Update binding
    _isUpdating = true;
    if (_boundRow != null && _boundField != null) {
      _boundRow![_boundField!] = value;
    }
    _isUpdating = false;

    final displayValue = _formatValue(value, forceFormat: true);
    if (_textController.text != displayValue) {
      _textController.text = displayValue;
    }
  }

  void _onTextChanged(String value) {
    if (_isUpdating) return;
    value = value.replaceAll(',', '');
    _isUpdating = true;
    if (value.split(".").length > 2) {
      value = widget.text.toString();
      final dotIndex = value.indexOf('.');
      _textController.selection = TextSelection.collapsed(offset: dotIndex + 2);
    } else {
      var valueNew = _normalizeDecimalOverwrite(
        widget.text.toString(),
        value,
        widget.format ?? "### ### ### ###.##",
      );
      value = valueNew.$2;
      if (valueNew.$1) {
        final pos = _textController.selection.baseOffset;
        final len = _textController.text.length;

        if (pos < len - 1) {
          _textController.selection = TextSelection.collapsed(offset: pos + 1);
        }
      }
    }

    // ✅ Parse input
    double numericValue = _parseInput(value);

    // ✅ Update binding
    if (_boundRow != null && _boundField != null) {
      _boundRow![_boundField!] = numericValue;
    }

    // ✅ Callback
    widget.onChanged?.call(numericValue);

    // ✅ Real-time formatting while typing
    final currentCursorPosition = _textController.selection.baseOffset;
    final formattedValue = _formatValue(numericValue);

    if (_textController.text != formattedValue) {
      // Calculate new cursor position
      final oldLength = _textController.text.length;
      final newLength = formattedValue.length;
      final lengthDiff = newLength - oldLength;

      _textController.value = TextEditingValue(
        text: formattedValue,
        selection: TextSelection.collapsed(
          offset: (currentCursorPosition + lengthDiff).clamp(0, newLength),
        ),
      );
    }

    _isUpdating = false;
  }

  (bool, String) _normalizeDecimalOverwrite(
    String oldStr,
    String newStr,
    String strFormat,
  ) {
    // Không có decimal → bỏ qua
    if (!oldStr.contains('.') || !newStr.contains('.')) {
      return (false, newStr);
    }
    // Xác định số chữ số thập phân từ format
    int decimalCount = 0;
    if (strFormat.contains('.')) {
      decimalCount = strFormat.split('.').last.length;
    }

    int oldDot = oldStr.indexOf('.');
    int newDot = newStr.indexOf('.');

    // Khác phần nguyên → không xử lý
    if (oldDot != newDot) return (false, newStr);

    // Chuẩn hoá old decimal theo format
    String oldDec = oldStr.substring(oldDot + 1).padRight(decimalCount, '0');

    // Lấy decimal mới (có thể dài hơn format)
    String newDec = newStr.substring(newDot + 1);

    // Nếu new không dài hơn old → không cần overwrite
    if (newDec.length <= oldDec.length) {
      return (
        true,
        oldStr.substring(0, oldDot + 1) +
            newDec.padRight(decimalCount, '0').substring(0, decimalCount),
      );
    }

    List<String> resultDec = oldDec.split('');

    // Tìm vị trí overwrite đầu tiên
    for (int i = 0; i < decimalCount; i++) {
      if (i >= newDec.length) break;
      if (newDec[i] != oldDec[i]) {
        resultDec[i] = newDec[i];
        break;
      }
    }
    return (true, oldStr.substring(0, oldDot + 1) + resultDec.join());
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible()) {
      return const SizedBox.shrink();
    }
    Widget textField = TextField(
      controller: _textController,
      onChanged: _onTextChanged,
      focusNode: _focusNode,
      textAlign: TextAlign.end,
      keyboardType: TextInputType.numberWithOptions(
        decimal: true,
        signed: false,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9\.\,\-]')),
      ],
      enabled: widget.enabled,
      style: widget.style,
      decoration: widget.decoration ?? _buildDecoration(),
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
      hintText: widget.hint,
      prefixIcon: widget.icon != null ? Icon(widget.icon, size: 20) : null,

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
