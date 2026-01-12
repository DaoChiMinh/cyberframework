import 'dart:math';
import 'package:cyberframework/cyberframework.dart';

/// CyberNumeric - VERSION CỰC KỲ ĐƠN GIẢN
/// CHỈ FIX 3 REQUIREMENTS CƠ BẢN:
/// 1. Format số nguyên → không cho phép dấu chấm
/// 2. Dấu trừ → luôn ở đầu
/// 3. Gõ dấu chấm → cursor nhảy sau dấu chấm
///
/// KHÔNG CÓ INSERT MODE - dùng behavior mặc định của TextField
class CyberNumeric extends StatefulWidget {
  final dynamic text;
  final CyberNumericController? controller;
  final String? label;
  final String? hint;
  final String? format;
  final String? prefixIcon;
  final int? borderSize;
  final int? borderRadius;
  final bool enabled;
  final dynamic isVisible;
  final TextStyle? style;
  final InputDecoration? decoration;
  final ValueChanged<num?>? onChanged;
  final Function(num?)? onLeaver;
  final num? min;
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
  });

  @override
  State<CyberNumeric> createState() => _CyberNumericState();
}

class _CyberNumericState extends State<CyberNumeric> {
  late TextEditingController _textController;
  late FocusNode _focusNode;

  CyberDataRow? _boundRow;
  String? _boundField;
  bool _isUpdating = false;

  CyberNumericController? _internalController;
  CyberNumericController get _effectiveController =>
      widget.controller ?? _internalController!;

  String _thousandsSeparator = ' ';
  int _decimalPlaces = 0;
  bool _hasDecimal = false;

  // Lưu text trước đó để restore khi gõ dấu chấm thừa
  String _previousText = '';

  @override
  void initState() {
    super.initState();
    _parseFormat();

    if (widget.controller == null) {
      _internalController = CyberNumericController(
        value: null,
        enabled: widget.enabled,
        min: widget.min,
        max: widget.max,
      );
    }

    _textController = TextEditingController();
    _focusNode = FocusNode();

    _parseBinding();
    _syncFromSource();

    _effectiveController.addListener(_onControllerChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(CyberNumeric oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.format != oldWidget.format) {
      _parseFormat();
    }

    if (widget.controller != oldWidget.controller) {
      _effectiveController.removeListener(_onControllerChanged);

      if (widget.controller == null) {
        _internalController ??= CyberNumericController(
          value: null,
          enabled: widget.enabled,
          min: widget.min,
          max: widget.max,
        );
      } else {
        _internalController?.dispose();
        _internalController = null;
      }

      _effectiveController.addListener(_onControllerChanged);
    }

    if (widget.text != oldWidget.text) {
      _parseBinding();
      _syncFromSource();
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

  void _parseFormat() {
    _thousandsSeparator = widget.format!.contains(' ') ? ' ' : ',';
    _hasDecimal = widget.format!.contains('.');
    _decimalPlaces = 0;

    if (_hasDecimal) {
      final parts = widget.format!.split('.');
      if (parts.length > 1) {
        _decimalPlaces = parts[1].replaceAll(RegExp(r'[^#0]'), '').length;
      }
    }
  }

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

  num? _getSourceValue() {
    if (widget.controller != null) return widget.controller!.value;
    if (_boundRow != null && _boundField != null) {
      final val = _boundRow![_boundField!];
      if (val is num) return val;
      if (val is String) return num.tryParse(val);
    }
    return null;
  }

  void _syncFromSource() {
    if (_isUpdating) return;
    final value = _getSourceValue();
    _textController.text = _format(value);
    _previousText = _textController.text; // Lưu lại text sau khi sync
  }

  void _onControllerChanged() {
    _syncFromSource();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      // Blur: validate và format đầy đủ
      final text = _textController.text.replaceAll(_thousandsSeparator, '');
      num? value = num.tryParse(text);
      if (value == null) {
        value = 0;
      }
      // Validate min/max
      if (value != null) {
        if (widget.min != null && value < widget.min!) value = widget.min;
        if (widget.max != null && value! > widget.max!) value = widget.max;
      }

      _isUpdating = true;
      if (widget.controller == null) {
        _internalController?.setValue(value);
      }
      if (_boundRow != null && _boundField != null) {
        _boundRow![_boundField!] = value;
      }
      _isUpdating = false;

      widget.onLeaver?.call(value);
      _textController.text = _format(value);
      _previousText = _textController.text; // Lưu lại text sau khi blur
    }
  }

  String _format(num? value) {
    if (value == null) return '';

    final str = value.toStringAsFixed(_decimalPlaces);
    final parts = str.split('.');

    // Format integer part with thousands separator
    String intPart = parts[0];
    bool isNegative = intPart.startsWith('-');
    if (isNegative) intPart = intPart.substring(1);

    if (intPart.length > 3) {
      final buffer = StringBuffer();
      int count = 0;
      for (int i = intPart.length - 1; i >= 0; i--) {
        if (count > 0 && count % 3 == 0) buffer.write(_thousandsSeparator);
        buffer.write(intPart[i]);
        count++;
      }
      intPart = buffer.toString().split('').reversed.join('');
    }

    if (isNegative) intPart = '-$intPart';

    // Add decimal part
    if (_hasDecimal && parts.length > 1) {
      return '$intPart.${parts[1]}';
    }
    return intPart;
  }

  void _onTextChanged(String value) {
    if (_isUpdating) return;

    // Lấy vị trí con trỏ hiện tại
    final cursorPos = _textController.selection.baseOffset;

    String clean = value
        .replaceAll(_thousandsSeparator, '')
        .replaceAll(' ', '');

    // ✅ DETECT: User vừa xóa ký tự (backspace/delete)
    final isDeleting = value.length < _previousText.length;

    // ✅ DETECT: User vừa gõ dấu chấm khi đã có dấu chấm
    bool shouldRestoreAndMoveCursor = false;
    if (_hasDecimal && clean.contains('.')) {
      final dotCount = clean.split('.').length - 1;
      if (dotCount > 1) {
        shouldRestoreAndMoveCursor = true;
      }
    }

    // Nếu phát hiện nhiều dấu chấm → Restore text cũ và di chuyển cursor
    if (shouldRestoreAndMoveCursor) {
      final dotIndex = _previousText.indexOf('.');
      final newCursorPos = dotIndex >= 0 ? dotIndex + 1 : _previousText.length;

      _isUpdating = true;
      _textController.value = TextEditingValue(
        text: _previousText,
        selection: TextSelection.collapsed(offset: newCursorPos),
      );
      _isUpdating = false;
      return;
    }

    // ✅ DETECT: User vừa nhập dấu trừ khi đã có dấu trừ
    final previousClean = _previousText
        .replaceAll(_thousandsSeparator, '')
        .replaceAll(' ', '');
    final hadMinus = previousClean.contains('-');
    final hasMinus = clean.contains('-');
    final minusCount = clean.split('-').length - 1;

    if (hadMinus && hasMinus && minusCount > 1) {
      // Đã có dấu trừ rồi, user lại nhập thêm → Restore và giữ nguyên vị trí
      _isUpdating = true;
      _textController.value = TextEditingValue(
        text: _previousText,
        selection: TextSelection.collapsed(offset: cursorPos - 1),
      );
      _isUpdating = false;
      return;
    }

    // ✅ DETECT: User vừa nhập dấu trừ
    // final isTypingMinus =
    //     clean.replaceAll('-', '').length >=
    //     previousClean.replaceAll('-', '').length;

    // ✅ INSERT MODE cho số thập phân (BỎ QUA nếu đang nhập dấu trừ hoặc đang xóa)
    if (_hasDecimal && clean.contains('.')) {
      final dotIndex = clean.indexOf('.');
      final decimalPart = clean.substring(dotIndex + 1);

      // Tính vị trí con trỏ trong clean text (không có thousands separator)
      int cleanCursorPos = 0;
      for (int i = 0; i < min(cursorPos, value.length); i++) {
        if (value[i] != _thousandsSeparator && value[i] != ' ') {
          cleanCursorPos++;
        }
      }

      // Kiểm tra nếu con trỏ đang ở sau dấu chấm
      if (cleanCursorPos > dotIndex &&
          decimalPart.length > _decimalPlaces &&
          minusCount > 1) {
        // Xóa ký tự ngay đằng sau vị trí con trỏ
        final beforeCursor = clean.substring(0, cleanCursorPos);
        final afterCursor = clean.substring(cleanCursorPos + 1);
        clean = beforeCursor + afterCursor;
      }
    }

    // ✅ Rule 1: Dấu trừ phải ở đầu
    if (clean.contains('-')) {
      final parts = clean.split('-');
      if (parts.length > 2) {
        clean = '-${parts.where((p) => p.isNotEmpty).join('')}';
      } else if (!clean.startsWith('-')) {
        clean = '-${clean.replaceAll('-', '')}';
      }
    }

    // ✅ Rule 2: Nếu format KHÔNG có decimal → loại bỏ dấu chấm
    if (!_hasDecimal && clean.contains('.')) {
      clean = clean.replaceAll('.', '');
    }

    // ✅ Rule 3: Giới hạn decimal places
    if (_hasDecimal && clean.contains('.')) {
      final parts = clean.split('.');
      if (parts.length == 2 && parts[1].length > _decimalPlaces) {
        clean = '${parts[0]}.${parts[1].substring(0, _decimalPlaces)}';
      }
    }

    // Parse value
    num? numValue = num.tryParse(clean);

    // Update sources
    _isUpdating = true;
    if (widget.controller == null) {
      _internalController?.setValue(numValue);
    }
    if (_boundRow != null && _boundField != null) {
      _boundRow![_boundField!] = numValue;
    }
    widget.onChanged?.call(numValue);
    _isUpdating = false;

    // Format with thousands separator
    String formatted = _formatPartial(clean);

    // Update TextField
    if (_textController.text != formatted) {
      int newCursorPos = _calculateCursorPosition(
        _textController.text,
        formatted,
        cursorPos,
      );

      // ✅ Nếu con trỏ ở cuối cùng → di chuyển về trước số cuối (CHỈ KHI KHÔNG XÓA)
      if (_hasDecimal && formatted.contains('.') && !isDeleting) {
        final dotIndex = formatted.indexOf('.');
        if (newCursorPos == formatted.length &&
            formatted.length > dotIndex + 1) {
          newCursorPos = formatted.length - 1;
        }
      }

      _isUpdating = true;
      _textController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: newCursorPos),
      );
      _isUpdating = false;
    }

    // Lưu lại text hiện tại để dùng cho lần sau
    _previousText = _textController.text;
  }

  String _formatPartial(String clean) {
    if (clean.isEmpty) return '';

    bool isNegative = clean.startsWith('-');
    if (isNegative) clean = clean.substring(1);

    final parts = clean.split('.');
    String intPart = parts[0];

    // Add thousands separator
    if (intPart.length > 3) {
      final buffer = StringBuffer();
      int count = 0;
      for (int i = intPart.length - 1; i >= 0; i--) {
        if (count > 0 && count % 3 == 0) buffer.write(_thousandsSeparator);
        buffer.write(intPart[i]);
        count++;
      }
      intPart = buffer.toString().split('').reversed.join('');
    }

    if (isNegative) intPart = '-$intPart';

    // Add decimal part
    if (parts.length > 1) {
      return '$intPart.${parts[1]}';
    } else if (clean.endsWith('.')) {
      return '$intPart.';
    }
    return intPart;
  }

  int _calculateCursorPosition(String oldText, String newText, int oldPos) {
    // Count non-separator characters before cursor in old text
    int charsBeforeCursor = 0;
    for (int i = 0; i < min(oldPos, oldText.length); i++) {
      if (oldText[i] != _thousandsSeparator && oldText[i] != ' ') {
        charsBeforeCursor++;
      }
    }

    // Find same position in new text
    int charCount = 0;
    for (int i = 0; i < newText.length; i++) {
      if (newText[i] != _thousandsSeparator && newText[i] != ' ') {
        if (charCount >= charsBeforeCursor) return i;
        charCount++;
      }
    }

    return newText.length;
  }

  bool _parseBool(dynamic value) {
    if (value == null) return true;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase().trim();
      return lower == "1" || lower == "true";
    }
    return true;
  }

  bool _isVisible() {
    return _parseBool(widget.isVisible);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible()) return const SizedBox.shrink();

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
          keyboardType: TextInputType.numberWithOptions(
            decimal: _hasDecimal,
            signed: true,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9\.\-]')),
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
                    if (_parseBool(widget.isCheckEmpty))
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
      border: borderStyle ?? InputBorder.none,
      enabledBorder: borderStyle ?? InputBorder.none,
      focusedBorder: borderStyle ?? InputBorder.none,
      errorBorder: borderStyle ?? InputBorder.none,
      disabledBorder: borderStyle ?? InputBorder.none,
      focusedErrorBorder: borderStyle ?? InputBorder.none,
      filled: true,
      fillColor: isEnabled
          ? (widget.backgroundColor ?? const Color(0xFFF5F5F5))
          : const Color(0xFFE0E0E0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}
