import 'package:cyberframework/cyberframework.dart';

/// Widget RENDER UI và ĐIỀU KHIỂN INPUT
/// Sở hữu TextEditingController và FocusNode
class CyberText extends StatefulWidget {
  // === CONTROLLER (nếu có thì KHÔNG có text) ===
  final CyberTextController? controller;

  // === SIMPLE MODE (chỉ khi KHÔNG có controller) ===
  final String? text;
  final ValueChanged<String>? onChanged;

  // === UI PROPERTIES ===
  final String? label;
  final String? hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final bool isVisible;
  final TextStyle? style;
  final InputDecoration? decoration;
  final bool isPassword;
  final bool isShowLabel;
  final Color? backgroundColor;
  final Color? focusColor;
  final TextStyle? labelStyle;

  // === CALLBACKS ===
  final VoidCallback? onLeaver;

  const CyberText({
    super.key,
    this.controller,
    this.text,
    this.onChanged,
    this.label,
    this.hint,
    this.icon,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.isVisible = true,
    this.style,
    this.decoration,
    this.isPassword = false,
    this.isShowLabel = true,
    this.backgroundColor,
    this.focusColor,
    this.labelStyle,
    this.onLeaver,
  }) : assert(
         controller == null || text == null,
         'CyberText: KHÔNG được truyền đồng thời text và controller. '
         'Nếu dùng controller thì bỏ text property.',
       );

  @override
  State<CyberText> createState() => _CyberTextState();
}

class _CyberTextState extends State<CyberText> {
  // === WIDGET SỞ HỮU ===
  late TextEditingController _textController;
  late FocusNode _focusNode;

  bool _obscure = true;

  // === FLAG CHỐNG LOOP ===
  bool _isInternalUpdate = false;

  @override
  void initState() {
    super.initState();

    // Tạo TextEditingController từ controller hoặc text
    final initialValue = widget.controller?.displayValue ?? widget.text ?? '';
    _textController = TextEditingController(text: initialValue);

    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChanged);

    // Lắng nghe controller nếu có
    widget.controller?.addListener(_onControllerChanged);

    // Lắng nghe text input
    _textController.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(CyberText oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Nếu controller thay đổi
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_onControllerChanged);
      widget.controller?.addListener(_onControllerChanged);

      // Sync lại giá trị
      _syncFromController();
    }

    // Nếu text thay đổi (simple mode)
    if (widget.text != oldWidget.text && widget.controller == null) {
      final newText = widget.text ?? '';
      if (_textController.text != newText) {
        _isInternalUpdate = true;
        _textController.text = newText;
        _isInternalUpdate = false;
      }
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onControllerChanged);
    _textController.removeListener(_onTextChanged);
    _textController.dispose();

    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();

    super.dispose();
  }

  // === SYNC CONTROLLER ↔ TEXT CONTROLLER (ANTI-LOOP) ===

  /// Controller thay đổi → Cập nhật TextController
  /// ⚠️ CRITICAL: Check trước khi set để tránh loop và cursor jump
  void _onControllerChanged() {
    if (!mounted || _isInternalUpdate) return;
    _syncFromController();
  }

  void _syncFromController() {
    final newValue = widget.controller?.displayValue ?? '';

    // ✅ CRITICAL: Check trước khi set
    // Nếu không check → cursor nhảy vị trí, lag nhẹ
    if (_textController.text != newValue) {
      _isInternalUpdate = true;
      _textController.text = newValue;
      _isInternalUpdate = false;
    }

    setState(() {}); // Rebuild cho validation indicator
  }

  /// TextController thay đổi → Cập nhật Controller
  /// ⚠️ CRITICAL: Dùng flag để tránh loop
  void _onTextChanged() {
    // Nếu đang update từ controller → bỏ qua
    if (_isInternalUpdate) return;

    final text = _textController.text;

    if (widget.controller != null) {
      // Controller mode: extract raw value và set vào controller
      final rawValue = _extractRawValue(text);

      // ✅ CRITICAL: Check trước khi set để tránh trigger lại
      if (widget.controller!.value != rawValue) {
        _isInternalUpdate = true;
        widget.controller!.setValue(rawValue);
        _isInternalUpdate = false;
      }
    } else {
      // Simple mode: callback
      widget.onChanged?.call(text);
    }
  }

  /// Trích xuất raw value từ display value (remove format)
  String _extractRawValue(String displayValue) {
    final controller = widget.controller;
    if (controller == null ||
        !controller.showFormatInField ||
        controller.format == null) {
      return displayValue;
    }

    final parts = controller.format!.split('{0}');
    if (parts.length == 2) {
      String rawValue = displayValue;
      if (parts[0].isNotEmpty) {
        rawValue = rawValue.replaceFirst(parts[0], '');
      }
      if (parts[1].isNotEmpty) {
        rawValue = rawValue.replaceFirst(parts[1], '');
      }
      return rawValue.trim();
    }

    return displayValue;
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      widget.onLeaver?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    final effectiveEnabled = widget.controller?.enabled ?? widget.enabled;
    final isRequired = widget.controller?.isCheckEmpty ?? false;

    Widget textField = TextField(
      controller: _textController,
      focusNode: _focusNode,
      obscureText: widget.isPassword ? _obscure : false,
      keyboardType: widget.isPassword
          ? TextInputType.visiblePassword
          : widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      enabled: effectiveEnabled,
      style: widget.style,
      decoration: widget.decoration ?? _buildDecoration(),
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
                if (isRequired)
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
  }

  InputDecoration _buildDecoration() {
    final helperText = widget.controller?.helperText;
    final effectiveEnabled = widget.controller?.enabled ?? widget.enabled;

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
      fillColor: effectiveEnabled
          ? (widget.backgroundColor ?? const Color(0xFFF5F5F5))
          : const Color(0xFFE0E0E0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}
