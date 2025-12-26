import 'package:cyberframework/cyberframework.dart';

class CyberText extends StatefulWidget {
  final dynamic text;
  final String? label;
  final String? hint;
  final String? format; // Format string với {0}, VD: "Minhdc: {0}"
  final IconData? icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final TextStyle? style;
  final InputDecoration? decoration;
  final ValueChanged<String>? onChanged;
  final Function(dynamic)? onLeaver;
  final bool showFormatInField;
  final bool isPassword;
  final bool isShowLabel;
  final Color? backgroundColor;
  final Color? focusColor;
  final TextStyle? labelStyle;
  final dynamic isVisible;
  final dynamic isCheckEmpty;
  
  const CyberText({
    super.key,
    this.text,
    this.label,
    this.hint,
    this.format,
    this.icon,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.isVisible = true,
    this.style,
    this.decoration,
    this.onChanged,
    this.onLeaver,
    this.showFormatInField = false,
    this.isPassword = false,
    this.isShowLabel = true,
    this.backgroundColor,
    this.focusColor,
    this.labelStyle,
    this.isCheckEmpty = false,
  });

  @override
  State<CyberText> createState() => _CyberTextState();
}

class _CyberTextState extends State<CyberText> {
  late TextEditingController _textController;
  CyberDataRow? _boundRow;
  String? _boundField;
  bool _isUpdating = false;
  CyberDataRow? _visibilityBoundRow;
  String? _visibilityBoundField;
  late FocusNode _focusNode;

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
      if (!_focusNode.hasFocus) {
        widget.onLeaver?.call(_textController.text);
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
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase().trim();
      if (lower == "1" || lower == "true") return true;
      if (lower == "0" || lower == "false") return false;
      return false;
    }
    return false;
  }

  bool _isVisible() {
    if (_visibilityBoundRow != null && _visibilityBoundField != null) {
      return _parseBool(_visibilityBoundRow![_visibilityBoundField!]);
    }
    return widget.isVisible == null ? true : _parseBool(widget.isVisible);
  }

  bool _isCheckEmpty() {
    return _parseBool(widget.isCheckEmpty);
  }

  /// Kiểm tra giá trị có hợp lệ không (nếu isCheckEmpty = true thì không được rỗng)
  bool isValid() {
    if (!_isCheckEmpty()) return true;
    
    final value = _getCurrentValue();
    return value.trim().isNotEmpty;
  }

  /// Lấy giá trị hiện tại dưới dạng string
  String _getCurrentValue() {
    if (_boundRow != null && _boundField != null) {
      return _boundRow![_boundField!]?.toString() ?? '';
    } else if (widget.text != null && widget.text is! CyberBindingExpression) {
      return widget.text.toString();
    }
    return '';
  }

  void _updateController() {
    String value = _getCurrentValue();

    final displayValue =
        widget.showFormatInField && widget.format != null && value.isNotEmpty
        ? widget.format!.format([value])
        : value;

    _textController = TextEditingController(text: displayValue);
  }

  void _onBindingChanged() {
    if (_isUpdating || _boundRow == null || _boundField == null) return;

    final value = _boundRow![_boundField!]?.toString() ?? '';
    final displayValue =
        widget.showFormatInField && widget.format != null && value.isNotEmpty
        ? widget.format!.format([value])
        : value;

    if (_textController.text != displayValue) {
      _textController.text = displayValue;
    }
  }

  void _onTextChanged(String value) {
    _isUpdating = true;

    if (_boundRow != null && _boundField != null) {
      String rawValue = value;
      if (widget.showFormatInField && widget.format != null) {
        final parts = widget.format!.split('{0}');
        if (parts.length == 2) {
          rawValue = value;
          if (parts[0].isNotEmpty) {
            rawValue = rawValue.replaceFirst(parts[0], '');
          }
          if (parts[1].isNotEmpty) {
            rawValue = rawValue.replaceFirst(parts[1], '');
          }
          rawValue = rawValue.trim();
        }
      }

      _boundRow![_boundField!] = rawValue;
    }

    widget.onChanged?.call(value);

    _isUpdating = false;
  }

  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    if (!_isVisible()) {
      return const SizedBox.shrink();
    }
    
    Widget textField = TextField(
      controller: _textController,
      onChanged: _onTextChanged,
      focusNode: _focusNode,
      obscureText: widget.isPassword ? _obscure : false,
      keyboardType: widget.isPassword
          ? TextInputType.visiblePassword
          : widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
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
              mainAxisSize: MainAxisSize.min,
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
    String? helperText;
    if (!widget.showFormatInField && widget.format != null) {
      String? value;
      if (_boundRow != null && _boundField != null) {
        value = _boundRow![_boundField!]?.toString();
      } else if (widget.text != null) {
        value = widget.text.toString();
      }

      if (value != null && value.isNotEmpty) {
        helperText = widget.format!.format([value]);
      }
    }

    return InputDecoration(
      hintText: widget.hint,
      helperText: helperText,
      helperStyle: const TextStyle(
        color: Colors.blue,
        fontStyle: FontStyle.italic,
      ),
      prefixIcon: widget.icon != null ? Icon(widget.icon, size: 20) : null,
      suffixIcon: !widget.isPassword
          ? null
          : IconButton(
              icon: Icon(
                _obscure ? Icons.visibility_off : Icons.visibility,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _obscure = !_obscure;
                });
              },
            ),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      filled: true,
      fillColor: widget.enabled
          ? (widget.backgroundColor ?? const Color(0xFFF5F5F5))
          : const Color(0xFFE0E0E0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}
