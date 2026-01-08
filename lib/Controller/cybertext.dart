import 'package:cyberframework/cyberframework.dart';

class CyberText extends StatefulWidget {
  // === BINDING / STATIC MODE ===
  /// Giá trị của field - có thể là:
  /// - `CyberBindingExpression` (từ `row.bind('field')`) → Binding mode
  /// - `String` → Static mode
  /// - `null` → Không có giá trị
  final dynamic text;

  /// Callback khi text thay đổi (chỉ dùng với static String mode)
  final ValueChanged<String>? onChanged;

  // === EXTERNAL CONTROLLER MODE ===
  /// Controller tự quản lý từ bên ngoài
  /// ⚠️ Nếu dùng mode này thì KHÔNG dùng text
  final CyberTextController? controller;

  // === VALIDATION & FORMAT ===
  /// Bắt buộc nhập (hiển thị dấu * đỏ)
  final bool isCheckEmpty;

  /// Format string với {0} là placeholder
  /// VD: "Mã KH: {0}" → hiển thị "Mã KH: ABC123"
  final String? format;

  /// Hiển thị format ngay trong field (true) hay dưới dạng helper text (false)
  final bool showFormatInField;

  // === UI PROPERTIES ===
  /// Label hiển thị phía trên (nếu isShowLabel = true)
  final String? label;

  /// Hint text bên trong field
  final String? hint;

  /// Icon code hiển thị bên trái (VD: "e853")
  /// Parse từ hex string sang IconData
  final String? prefixIcon;

  /// Kích thước border (đơn vị: pixel)
  final int? borderSize;

  /// Border radius (đơn vị: pixel)
  final int? borderRadius;

  /// Loại bàn phím
  final TextInputType? keyboardType;

  /// Input formatters
  final List<TextInputFormatter>? inputFormatters;

  /// Số dòng tối đa
  final int? maxLines;

  /// Độ dài tối đa
  final int? maxLength;

  /// Có cho phép nhập hay không
  final bool enabled;

  /// Có hiển thị widget hay không
  final bool isVisible;

  /// Text style
  final TextStyle? style;

  /// Custom decoration (nếu muốn override hoàn toàn)
  final InputDecoration? decoration;

  /// Có phải password field không
  final bool isPassword;

  /// Có hiển thị label phía trên không
  final bool isShowLabel;

  /// Có cho phép hint rỗng không
  /// - false: Nếu hint null/empty thì tự động dùng label làm hint
  /// - true: Giữ nguyên giá trị hint (có thể rỗng)
  final bool isHintEmpty;

  /// Màu nền của field
  final Color? backgroundColor;

  /// Màu border
  final Color? borderColor;

  /// Màu khi focus (chưa dùng)
  final Color? focusColor;

  /// Style của label
  final TextStyle? labelStyle;

  // === CALLBACKS ===
  /// Callback khi focus ra khỏi field
  final VoidCallback? onLeaver;

  const CyberText({
    super.key,
    // Binding / Static mode
    this.text,
    this.onChanged,
    // External controller mode
    this.controller,
    // Validation & Format
    this.isCheckEmpty = false,
    this.format,
    this.showFormatInField = false,
    // UI
    this.label,
    this.hint,
    this.prefixIcon,
    this.borderSize = 1,
    this.borderRadius,
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
    this.isHintEmpty = false,
    this.backgroundColor,
    this.borderColor = Colors.transparent,
    this.focusColor,
    this.labelStyle,
    this.onLeaver,
  }) : assert(
         // Không được dùng cả text và controller cùng lúc
         text == null || controller == null,
         'CyberText: Không được truyền cả text và controller cùng lúc.\n'
         'Chọn 1 trong 2:\n'
         '- text: row.bind("field") hoặc text: "value"\n'
         '- controller: myController',
       ),
       assert(
         // Nếu text là String thì mới được dùng onChanged
         text is! String || controller == null,
         'CyberText: onChanged chỉ dùng với text mode, không dùng với controller mode',
       );

  @override
  State<CyberText> createState() => _CyberTextState();
}

class _CyberTextState extends State<CyberText> {
  // === WIDGET SỞ HỮU ===
  late TextEditingController _textController;
  late FocusNode _focusNode;

  /// Internal controller - TỰ ĐỘNG tạo nếu không có external controller
  late CyberTextController _internalController;

  /// Controller thực sự đang dùng (internal hoặc external)
  CyberTextController get _activeController =>
      widget.controller ?? _internalController;

  /// Binding hiện tại (nếu đang dùng binding mode)
  CyberBindingExpression? _currentBinding;

  bool _obscure = true;

  // === FLAG CHỐNG LOOP ===
  bool _isInternalUpdate = false;

  @override
  void initState() {
    super.initState();

    // === TẠO INTERNAL CONTROLLER ===
    _internalController = _createInternalController();

    // === TẠO TEXT CONTROLLER ===
    final initialValue = _getInitialValue();
    _textController = TextEditingController(text: initialValue);

    // === TẠO FOCUS NODE ===
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChanged);

    // === LẮNG NGHE CONTROLLER ===
    _activeController.addListener(_onControllerChanged);

    // === LẮNG NGHE TEXT INPUT ===
    _textController.addListener(_onTextChanged);

    // === SETUP BINDING (nếu có) ===
    _setupBindingListener();
  }

  @override
  void didUpdateWidget(CyberText oldWidget) {
    super.didUpdateWidget(oldWidget);

    // === XỬ LÝ THAY ĐỔI CONTROLLER ===
    if (widget.controller != oldWidget.controller) {
      // Remove listener từ old controller
      if (oldWidget.controller != null) {
        oldWidget.controller!.removeListener(_onControllerChanged);
      } else {
        _internalController.removeListener(_onControllerChanged);
      }

      // Recreate internal controller nếu không còn external controller
      if (widget.controller == null && oldWidget.controller != null) {
        _internalController.dispose();
        _internalController = _createInternalController();
      }

      // Add listener cho new controller
      _activeController.addListener(_onControllerChanged);

      // Sync lại giá trị
      _syncFromController();
    }

    // === XỬ LÝ THAY ĐỔI TEXT/BINDING ===
    if (widget.text != oldWidget.text) {
      // Cleanup old binding listener
      _cleanupBindingListener();

      // Setup new binding listener
      _setupBindingListener();

      // Recreate internal controller với binding mới
      if (widget.controller == null) {
        _internalController.removeListener(_onControllerChanged);
        _internalController.dispose();
        _internalController = _createInternalController();
        _activeController.addListener(_onControllerChanged);
      }

      // Sync value
      final newValue = _getInitialValue();
      if (_textController.text != newValue) {
        _isInternalUpdate = true;
        _textController.text = newValue;
        _isInternalUpdate = false;
      }
    }

    // === XỬ LÝ THAY ĐỔI VALIDATION/FORMAT ===
    if (widget.controller == null) {
      if (widget.isCheckEmpty != oldWidget.isCheckEmpty) {
        _internalController.setCheckEmpty(widget.isCheckEmpty);
      }
      if (widget.format != oldWidget.format) {
        _internalController.setFormat(widget.format);
      }
      if (widget.showFormatInField != oldWidget.showFormatInField) {
        _internalController.setShowFormatInField(widget.showFormatInField);
      }
    }
  }

  @override
  void dispose() {
    _activeController.removeListener(_onControllerChanged);
    _textController.removeListener(_onTextChanged);
    _textController.dispose();

    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();

    // Cleanup binding listener
    _cleanupBindingListener();

    // Dispose internal controller nếu đang dùng
    if (widget.controller == null) {
      _internalController.dispose();
    }

    super.dispose();
  }

  // === HELPER METHODS ===

  /// Tạo internal controller dựa vào mode
  CyberTextController _createInternalController() {
    // BINDING EXPRESSION MODE
    if (_isBindingExpressionMode()) {
      final binding = widget.text as CyberBindingExpression;
      return CyberTextController.withBinding(
        dataRow: binding.row,
        fieldName: binding.fieldName,
        isCheckEmpty: widget.isCheckEmpty,
        format: widget.format,
        showFormatInField: widget.showFormatInField,
        enabled: widget.enabled,
      );
    }

    // STATIC MODE hoặc chưa có binding
    final initialValue = _isStaticTextMode() ? widget.text as String? : null;
    return CyberTextController(
      initialValue: initialValue,
      isCheckEmpty: widget.isCheckEmpty,
      format: widget.format,
      showFormatInField: widget.showFormatInField,
      enabled: widget.enabled,
    );
  }

  /// Setup listener cho binding (nếu có)
  void _setupBindingListener() {
    if (_isBindingExpressionMode()) {
      _currentBinding = widget.text as CyberBindingExpression;
      // Lắng nghe thay đổi từ DataRow
      _currentBinding!.row.addListener(_onBindingChanged);
    }
  }

  /// Cleanup binding listener
  void _cleanupBindingListener() {
    if (_currentBinding != null) {
      _currentBinding!.row.removeListener(_onBindingChanged);
      _currentBinding = null;
    }
  }

  /// Callback khi binding value thay đổi (từ code khác)
  void _onBindingChanged() {
    if (!mounted || _isInternalUpdate) return;

    // Sync từ binding → controller → text
    final newValue = _currentBinding!.value?.toString() ?? '';

    if (_activeController.value != newValue) {
      _isInternalUpdate = true;
      _activeController.setValue(newValue);
      _isInternalUpdate = false;
    }
  }

  /// Lấy giá trị ban đầu cho TextController
  String _getInitialValue() {
    if (widget.controller != null) {
      return widget.controller!.displayValue ?? '';
    }

    if (_isBindingExpressionMode()) {
      final binding = widget.text as CyberBindingExpression;
      return binding.value?.toString() ?? '';
    }

    if (_isStaticTextMode()) {
      return widget.text as String;
    }

    return '';
  }

  /// Check mode hiện tại
  bool _isBindingExpressionMode() => widget.text is CyberBindingExpression;
  bool _isStaticTextMode() => widget.text is String;

  /// Lấy hint text dựa vào logic isHintEmpty
  String? _getEffectiveHint() {
    // Nếu isHintEmpty = true → giữ nguyên giá trị hint (có thể null/empty)
    if (widget.isHintEmpty) {
      return widget.hint;
    }

    // Nếu isHintEmpty = false
    // - Nếu hint có giá trị → dùng hint
    // - Nếu hint null/empty → dùng label
    if (widget.hint != null && widget.hint!.isNotEmpty) {
      return widget.hint;
    }

    return widget.label;
  }

  /// Parse icon code từ hex string sang IconData
  // IconData? _parseIconCode(String? iconCode) {
  //   if (iconCode == null || iconCode.isEmpty) return null;

  //   try {
  //     // Parse hex string sang int (VD: "e853" -> 0xe853)
  //     final codePoint = int.parse(iconCode, radix: 16);
  //     return IconData(codePoint, fontFamily: 'MaterialIcons');
  //   } catch (e) {
  //     debugPrint('CyberText: Invalid icon code "$iconCode"');
  //     return null;
  //   }
  // }

  // === SYNC CONTROLLER ↔ TEXT CONTROLLER (ANTI-LOOP) ===

  /// Controller thay đổi → Cập nhật TextController
  /// ⚠️ CRITICAL: Check trước khi set để tránh loop và cursor jump
  void _onControllerChanged() {
    if (!mounted || _isInternalUpdate) return;
    _syncFromController();
  }

  void _syncFromController() {
    final newValue = _activeController.displayValue ?? '';

    // ✅ CRITICAL: Check trước khi set
    // Nếu không check → cursor nhảy vị trí, lag nhẹ
    if (_textController.text != newValue) {
      _isInternalUpdate = true;
      _textController.text = newValue;
      _isInternalUpdate = false;
    }

    setState(() {}); // Rebuild cho validation indicator
  }

  /// TextController thay đổi → Cập nhật Controller (và Binding nếu có)
  /// ⚠️ CRITICAL: Dùng flag để tránh loop
  void _onTextChanged() {
    // Nếu đang update từ controller → bỏ qua
    if (_isInternalUpdate) return;

    final text = _textController.text;

    if (!_isStaticTextMode() || widget.controller != null) {
      // Controller mode hoặc Binding mode
      final rawValue = _extractRawValue(text);

      // ✅ CRITICAL: Check trước khi set để tránh trigger lại
      if (_activeController.value != rawValue) {
        _isInternalUpdate = true;
        _activeController.setValue(rawValue);
        _isInternalUpdate = false;
      }

      // Nếu có binding, controller sẽ tự động update DataRow
      // DataRow sẽ notify và trigger _onBindingChanged
    } else {
      // Static String mode: callback
      widget.onChanged?.call(text);
    }
  }

  /// Trích xuất raw value từ display value (remove format)
  String _extractRawValue(String displayValue) {
    final controller = _activeController;
    if (!controller.showFormatInField || controller.format == null) {
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

    final effectiveEnabled = _activeController.enabled && widget.enabled;
    final isRequired = _activeController.isCheckEmpty;

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
    final helperText = _activeController.helperText;
    final iconData = widget.prefixIcon == null
        ? null
        : v_parseIcon(widget.prefixIcon!);
    final borderWidth = widget.borderSize?.toDouble() ?? 0.0;
    final radius = widget.borderRadius?.toDouble() ?? 4.0;
    final effectiveBorderColor = widget.borderColor ?? Colors.grey;
    final effectiveHint = _getEffectiveHint();

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
      hintText: effectiveHint,
      hintStyle: TextStyle(
        color: Colors.grey.shade500, // tương đương secondaryLabel
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      helperText: helperText,
      helperStyle: const TextStyle(
        color: Colors.blue,
        fontStyle: FontStyle.italic,
      ),
      prefixIcon: iconData != null ? Icon(iconData, size: 18) : null,
      prefixIconConstraints: iconData != null
          ? const BoxConstraints(minWidth: 36, minHeight: 36)
          : null,
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
      // Áp dụng border nếu có borderSize > 0
      border: borderStyle ?? InputBorder.none,
      enabledBorder: borderStyle ?? InputBorder.none,
      focusedBorder: borderStyle ?? InputBorder.none,
      errorBorder: borderStyle ?? InputBorder.none,
      disabledBorder: borderStyle ?? InputBorder.none,
      focusedErrorBorder: borderStyle ?? InputBorder.none,
      filled: true,
      fillColor: widget.enabled
          ? (widget.backgroundColor ?? const Color(0xFFF5F5F5))
          : const Color(0xFFE0E0E0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}
