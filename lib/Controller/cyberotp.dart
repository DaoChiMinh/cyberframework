import 'package:cyberframework/cyberframework.dart';

class CyberOTP extends StatefulWidget {
  // === BINDING / STATIC MODE ===
  /// Giá trị của OTP - có thể là:
  /// - `CyberBindingExpression` (từ `row.bind('field')`) → Binding mode
  /// - `String` → Static mode (VD: "123456")
  /// - `null` → Không có giá trị
  final dynamic text;

  /// Callback khi OTP thay đổi (chỉ dùng với static String mode)
  final ValueChanged<String>? onChanged;

  /// Callback khi OTP đã nhập đầy đủ
  final ValueChanged<String>? onCompleted;

  // === EXTERNAL CONTROLLER MODE ===
  /// Controller tự quản lý từ bên ngoài
  /// ⚠️ Nếu dùng mode này thì KHÔNG dùng text
  final CyberOTPController? controller;

  // === OTP PROPERTIES ===
  /// Số lượng ô OTP (mặc định: 6)
  final int length;

  /// Có phải ô password (ẩn giá trị) không
  final bool isPassword;

  // === VALIDATION ===
  /// Bắt buộc nhập (hiển thị dấu * đỏ)
  final bool isCheckEmpty;

  // === UI PROPERTIES ===
  /// Label hiển thị phía trên
  final String? label;

  /// Hint text cho mỗi ô (thường là số thứ tự hoặc để trống)
  final String? hint;

  /// Khoảng cách giữa các ô
  final double spacing;

  /// Kích thước mỗi ô
  final double boxSize;

  /// Border radius của mỗi ô
  final double borderRadius;

  /// Độ dày border
  final double borderWidth;

  /// Màu nền của ô
  final Color? backgroundColor;

  /// Màu border khi không focus
  final Color? borderColor;

  /// Màu border khi focus
  final Color? focusedBorderColor;

  /// Màu text
  final Color? textColor;

  /// Font size của text
  final double? fontSize;

  /// Có cho phép nhập hay không
  final bool enabled;

  /// Có hiển thị widget hay không
  final bool isVisible;

  /// Có hiển thị label phía trên không
  final bool isShowLabel;

  /// Style của label
  final TextStyle? labelStyle;

  // === CALLBACKS ===
  /// Callback khi focus ra khỏi tất cả các ô
  final VoidCallback? onLeaver;

  const CyberOTP({
    super.key,
    // Binding / Static mode
    this.text,
    this.onChanged,
    this.onCompleted,
    // External controller mode
    this.controller,
    // OTP properties
    this.length = 6,
    this.isPassword = false,
    // Validation
    this.isCheckEmpty = false,
    // UI
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
         'CyberOTP: Không được truyền cả text và controller cùng lúc.\n'
         'Chọn 1 trong 2:\n'
         '- text: row.bind("field") hoặc text: "value"\n'
         '- controller: myController',
       ),
       assert(
         text is! String || controller == null,
         'CyberOTP: onChanged chỉ dùng với text mode, không dùng với controller mode',
       );

  @override
  State<CyberOTP> createState() => _CyberOTPState();
}

class _CyberOTPState extends State<CyberOTP> {
  // === WIDGET SỞ HỮU ===
  late List<TextEditingController> _textControllers;
  late List<FocusNode> _focusNodes;

  /// Internal controller - TỰ ĐỘNG tạo nếu không có external controller
  late CyberOTPController _internalController;

  /// Controller thực sự đang dùng (internal hoặc external)
  CyberOTPController get _activeController =>
      widget.controller ?? _internalController;

  /// Binding hiện tại (nếu đang dùng binding mode)
  CyberBindingExpression? _currentBinding;

  // === FLAG CHỐNG LOOP ===
  bool _isInternalUpdate = false;

  @override
  void initState() {
    super.initState();

    // === TẠO INTERNAL CONTROLLER ===
    _internalController = _createInternalController();

    // === TẠO TEXT CONTROLLERS & FOCUS NODES ===
    _textControllers = List.generate(
      widget.length,
      (index) => TextEditingController(),
    );

    _focusNodes = List.generate(widget.length, (index) => FocusNode());

    // === SETUP INITIAL VALUE ===
    _syncFromController();

    // === LẮNG NGHE CONTROLLER ===
    _activeController.addListener(_onControllerChanged);

    // === LẮNG NGHE TEXT INPUT ===
    for (int i = 0; i < widget.length; i++) {
      _textControllers[i].addListener(() => _onTextChanged(i));
      _focusNodes[i].addListener(() => _onFocusChanged(i));
    }

    // === SETUP BINDING (nếu có) ===
    _setupBindingListener();
  }

  @override
  void didUpdateWidget(CyberOTP oldWidget) {
    super.didUpdateWidget(oldWidget);

    // === XỬ LÝ THAY ĐỔI LENGTH ===
    if (widget.length != oldWidget.length) {
      _recreateControllers();
    }

    // === XỬ LÝ THAY ĐỔI CONTROLLER ===
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
      _syncFromController();
    }

    // === XỬ LÝ THAY ĐỔI TEXT/BINDING ===
    if (widget.text != oldWidget.text) {
      _cleanupBindingListener();
      _setupBindingListener();

      if (widget.controller == null) {
        _internalController.removeListener(_onControllerChanged);
        _internalController.dispose();
        _internalController = _createInternalController();
        _activeController.addListener(_onControllerChanged);
      }

      _syncFromController();
    }

    // === XỬ LÝ THAY ĐỔI VALIDATION ===
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

  // === HELPER METHODS ===

  void _recreateControllers() {
    // Dispose old controllers
    for (var controller in _textControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }

    // Create new controllers
    _textControllers = List.generate(
      widget.length,
      (index) => TextEditingController(),
    );

    _focusNodes = List.generate(widget.length, (index) => FocusNode());

    // Setup listeners
    for (int i = 0; i < widget.length; i++) {
      _textControllers[i].addListener(() => _onTextChanged(i));
      _focusNodes[i].addListener(() => _onFocusChanged(i));
    }

    _syncFromController();
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

  // === SYNC CONTROLLER ↔ TEXT CONTROLLERS ===

  void _onControllerChanged() {
    if (!mounted || _isInternalUpdate) return;
    _syncFromController();
  }

  void _syncFromController() {
    final value = _activeController.value ?? '';
    final digits = _activeController.digits;

    _isInternalUpdate = true;

    for (int i = 0; i < widget.length; i++) {
      final digit = i < digits.length ? digits[i] : '';
      if (_textControllers[i].text != digit) {
        _textControllers[i].text = digit;
      }
    }

    _isInternalUpdate = false;
    setState(() {});
  }

  void _onTextChanged(int index) {
    if (_isInternalUpdate) return;

    final text = _textControllers[index].text;

    // Chỉ cho phép 1 ký tự số
    if (text.length > 1) {
      final lastChar = text[text.length - 1];
      _textControllers[index].text = lastChar;
      _textControllers[index].selection = TextSelection.fromPosition(
        TextPosition(offset: 1),
      );
      return;
    }

    // Nếu không phải số, xóa
    if (text.isNotEmpty && !RegExp(r'^\d$').hasMatch(text)) {
      _textControllers[index].text = '';
      return;
    }

    // Update controller
    _updateControllerFromFields();

    // Auto focus next field khi nhập xong
    if (text.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    // Trigger onCompleted nếu đã nhập đủ
    if (_activeController.isComplete) {
      widget.onCompleted?.call(_activeController.value!);
    }
  }

  void _updateControllerFromFields() {
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

  void _onFocusChanged(int index) {
    // Check nếu tất cả ô đều không focus → trigger onLeaver
    if (!_focusNodes[index].hasFocus) {
      final anyFocused = _focusNodes.any((node) => node.hasFocus);
      if (!anyFocused) {
        widget.onLeaver?.call();
      }
    }
  }

  // === HANDLE BACKSPACE ===
  bool _handleKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      // Nếu ô hiện tại rỗng và không phải ô đầu tiên → nhảy về ô trước
      if (_textControllers[index].text.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
        // Xóa ô trước
        _textControllers[index - 1].clear();
        _updateControllerFromFields();
        return true;
      }
    }
    return false;
  }

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
        if (_handleKeyEvent(index, event)) {
          // Event đã được xử lý
        }
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
            counterText: '', // Ẩn counter text
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
