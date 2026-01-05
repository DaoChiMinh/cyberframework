import 'package:cyberframework/cyberframework.dart';

class CyberOTP extends StatefulWidget {
  // === BINDING / STATIC MODE ===
  final dynamic text;
  final ValueChanged<String>? onChanged;

  // === EXTERNAL CONTROLLER MODE ===
  final CyberOTPController? controller;

  // === OTP PROPERTIES ===
  final int length;
  final bool isPassword;

  // === VALIDATION ===
  final bool isCheckEmpty;

  // === UI PROPERTIES ===
  final String? label;
  final String? hint;
  final double spacing;
  final double boxSize;
  final double borderRadius;
  final double borderWidth;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? textColor;
  final double? fontSize;
  final bool enabled;
  final bool isVisible;
  final bool isShowLabel;
  final TextStyle? labelStyle;

  // === CALLBACKS ===
  final VoidCallback? onLeaver;

  const CyberOTP({
    super.key,
    this.text,
    this.onChanged,
    this.controller,
    this.length = 6,
    this.isPassword = false,
    this.isCheckEmpty = false,
    this.label,
    this.hint,
    this.spacing = 8.0,
    this.boxSize = 50.0,
    this.borderRadius = 8.0,
    this.borderWidth = 1.5,
    this.backgroundColor,
    this.borderColor,
    this.focusedBorderColor,
    this.textColor,
    this.fontSize = 24.0,
    this.enabled = true,
    this.isVisible = true,
    this.isShowLabel = true,
    this.labelStyle,
    this.onLeaver,
  }) : assert(length > 0 && length <= 10, 'CyberOTP: length phải từ 1 đến 10'),
       assert(
         text == null || controller == null,
         'CyberOTP: Không được truyền cả text và controller cùng lúc',
       );

  @override
  State<CyberOTP> createState() => _CyberOTPState();
}

class _CyberOTPState extends State<CyberOTP> {
  // === WIDGET SỞ HỮU ===
  late List<TextEditingController> _textControllers;
  late List<FocusNode> _focusNodes;

  late CyberOTPController _internalController;

  CyberOTPController get _activeController =>
      widget.controller ?? _internalController;

  CyberBindingExpression? _currentBinding;

  // === FLAG CHỐNG LOOP ===
  bool _isInternalUpdate = false;

  @override
  void initState() {
    super.initState();

    _internalController = _createInternalController();

    _textControllers = List.generate(
      widget.length,
      (index) => TextEditingController(),
    );

    _focusNodes = List.generate(widget.length, (index) => FocusNode());

    // ✅ SYNC CONTROLLER → UI
    _syncControllerToUI();

    // === LẮNG NGHE CONTROLLER ===
    _activeController.addListener(_onControllerChanged);

    // === LẮNG NGHE TEXT INPUT ===
    for (int i = 0; i < widget.length; i++) {
      _textControllers[i].addListener(() => _onTextChanged(i));
      _focusNodes[i].addListener(() => _onFocusChanged(i));
    }

    _setupBindingListener();
  }

  @override
  void didUpdateWidget(CyberOTP oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.length != oldWidget.length) {
      _recreateControllers();
    }

    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller != null) {
        oldWidget.controller!.removeListener(_onControllerChanged);
      } else {
        _internalController.removeListener(_onControllerChanged);
      }

      if (widget.controller == null && oldWidget.controller != null) {
        _internalController.dispose();
        _internalController = _createInternalController();
      }

      _activeController.addListener(_onControllerChanged);
      _syncControllerToUI();
    }

    if (widget.text != oldWidget.text) {
      _cleanupBindingListener();
      _setupBindingListener();

      if (widget.controller == null) {
        _internalController.removeListener(_onControllerChanged);
        _internalController.dispose();
        _internalController = _createInternalController();
        _activeController.addListener(_onControllerChanged);
      }

      _syncControllerToUI();
    }

    if (widget.controller == null) {
      if (widget.isCheckEmpty != oldWidget.isCheckEmpty) {
        _internalController.setCheckEmpty(widget.isCheckEmpty);
      }
    }
  }

  @override
  void dispose() {
    _activeController.removeListener(_onControllerChanged);

    for (var controller in _textControllers) {
      controller.dispose();
    }

    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }

    _cleanupBindingListener();

    if (widget.controller == null) {
      _internalController.dispose();
    }

    super.dispose();
  }

  // ========================================
  // ✅ TẬP TRUNG MAPPING: CONTROLLER ↔ UI
  // ========================================

  /// ✅ SYNC: Controller → UI (TextControllers)
  /// Gọi khi: Controller thay đổi, init, rebuild
  void _syncControllerToUI() {
    final digits = _activeController.digits;

    _isInternalUpdate = true;

    for (int i = 0; i < widget.length; i++) {
      final digit = i < digits.length ? digits[i] : '';
      if (_textControllers[i].text != digit) {
        _textControllers[i].text = digit;
      }
    }

    _isInternalUpdate = false;

    if (mounted) {
      setState(() {});
    }
  }

  /// ✅ SYNC: UI (TextControllers) → Controller
  /// Gọi khi: User nhập, paste, autofill
  void _syncUIToController() {
    final digits = _textControllers.map((c) => c.text).toList();
    final value = digits.join();

    if (_activeController.value != value) {
      _isInternalUpdate = true;
      _activeController.setValue(value);
      _isInternalUpdate = false;

      // Static mode callback
      if (_isStaticTextMode() && widget.controller == null) {
        widget.onChanged?.call(value);
      }
    }
  }

  // ========================================
  // ✅ XỬ LÝ PASTE OTP (QUAN TRỌNG)
  // ========================================

  /// ✅ Xử lý paste OTP: "123456" → tách ra 6 ô
  void _handlePaste(int startIndex, String pastedText) {
    // Chỉ giữ lại các số
    final digits = pastedText.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) return;

    _isInternalUpdate = true;

    // Tách từng số vào các ô
    for (
      int i = 0;
      i < digits.length && (startIndex + i) < widget.length;
      i++
    ) {
      _textControllers[startIndex + i].text = digits[i];
    }

    _isInternalUpdate = false;

    // Sync về controller
    _syncUIToController();

    // Focus vào ô cuối cùng đã paste (hoặc ô cuối nếu paste đủ)
    final lastIndex = (startIndex + digits.length - 1).clamp(
      0,
      widget.length - 1,
    );
    if (lastIndex < widget.length) {
      _focusNodes[lastIndex].requestFocus();
    }
  }

  // ========================================
  // HELPER METHODS
  // ========================================

  void _recreateControllers() {
    for (var controller in _textControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }

    _textControllers = List.generate(
      widget.length,
      (index) => TextEditingController(),
    );

    _focusNodes = List.generate(widget.length, (index) => FocusNode());

    for (int i = 0; i < widget.length; i++) {
      _textControllers[i].addListener(() => _onTextChanged(i));
      _focusNodes[i].addListener(() => _onFocusChanged(i));
    }

    _syncControllerToUI();
  }

  CyberOTPController _createInternalController() {
    if (_isBindingExpressionMode()) {
      final binding = widget.text as CyberBindingExpression;
      return CyberOTPController.withBinding(
        dataRow: binding.row,
        fieldName: binding.fieldName,
        length: widget.length,
        isCheckEmpty: widget.isCheckEmpty,
        enabled: widget.enabled,
      );
    }

    final initialValue = _isStaticTextMode() ? widget.text as String? : null;
    return CyberOTPController(
      initialValue: initialValue,
      length: widget.length,
      isCheckEmpty: widget.isCheckEmpty,
      enabled: widget.enabled,
    );
  }

  void _setupBindingListener() {
    if (_isBindingExpressionMode()) {
      _currentBinding = widget.text as CyberBindingExpression;
      _currentBinding!.row.addListener(_onBindingChanged);
    }
  }

  void _cleanupBindingListener() {
    if (_currentBinding != null) {
      _currentBinding!.row.removeListener(_onBindingChanged);
      _currentBinding = null;
    }
  }

  void _onBindingChanged() {
    if (!mounted || _isInternalUpdate) return;

    final newValue = _currentBinding!.value?.toString() ?? '';

    if (_activeController.value != newValue) {
      _isInternalUpdate = true;
      _activeController.setValue(newValue);
      _isInternalUpdate = false;
    }
  }

  bool _isBindingExpressionMode() => widget.text is CyberBindingExpression;
  bool _isStaticTextMode() => widget.text is String;

  // ========================================
  // EVENT HANDLERS
  // ========================================

  void _onControllerChanged() {
    if (!mounted || _isInternalUpdate) return;
    _syncControllerToUI();
  }

  void _onTextChanged(int index) {
    if (_isInternalUpdate) return;

    final text = _textControllers[index].text;

    // ✅ PASTE: Nếu paste nhiều ký tự → xử lý paste
    if (text.length > 1) {
      _handlePaste(index, text);
      return;
    }

    // Chỉ cho phép 1 ký tự số
    if (text.isNotEmpty && !RegExp(r'^\d$').hasMatch(text)) {
      _textControllers[index].text = '';
      return;
    }

    // ✅ Sync về controller
    _syncUIToController();

    // Auto focus next field khi nhập xong
    if (text.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
  }

  void _onFocusChanged(int index) {
    if (!_focusNodes[index].hasFocus) {
      final anyFocused = _focusNodes.any((node) => node.hasFocus);
      if (!anyFocused) {
        widget.onLeaver?.call();
      }
    }
  }

  bool _handleKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_textControllers[index].text.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
        _textControllers[index - 1].clear();
        _syncUIToController();
        return true;
      }
    }
    return false;
  }

  // ========================================
  // BUILD UI
  // ========================================

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    final effectiveEnabled = _activeController.enabled && widget.enabled;
    final isRequired = _activeController.isCheckEmpty;

    Widget otpFields = Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(widget.length, (index) {
        return Padding(
          padding: EdgeInsets.only(
            right: index < widget.length - 1 ? widget.spacing : 0,
          ),
          child: _buildOTPBox(index, effectiveEnabled),
        );
      }),
    );

    if (widget.isShowLabel && widget.label != null) {
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
          otpFields,
        ],
      );
    }

    return otpFields;
  }

  Widget _buildOTPBox(int index, bool enabled) {
    final effectiveBorderColor = widget.borderColor ?? Colors.grey.shade300;
    final effectiveFocusedBorderColor =
        widget.focusedBorderColor ?? const Color(0xFF007AFF);
    final effectiveBackgroundColor =
        widget.backgroundColor ?? const Color(0xFFF5F5F5);
    final effectiveTextColor = widget.textColor ?? Colors.black;

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        _handleKeyEvent(index, event);
      },
      child: SizedBox(
        width: widget.boxSize,
        height: widget.boxSize,
        child: TextField(
          controller: _textControllers[index],
          focusNode: _focusNodes[index],
          enabled: enabled,
          obscureText: widget.isPassword,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          style: TextStyle(
            fontSize: widget.fontSize,
            fontWeight: FontWeight.w600,
            color: effectiveTextColor,
          ),
          decoration: InputDecoration(
            counterText: '',
            hintText: widget.hint,
            filled: true,
            fillColor: enabled
                ? effectiveBackgroundColor
                : Colors.grey.shade200,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: BorderSide(
                color: effectiveBorderColor,
                width: widget.borderWidth,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: BorderSide(
                color: effectiveFocusedBorderColor,
                width: widget.borderWidth * 1.5,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: BorderSide(
                color: Colors.grey.shade300,
                width: widget.borderWidth,
              ),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }
}
