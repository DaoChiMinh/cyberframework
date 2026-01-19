import 'package:cyberframework/cyberframework.dart';

/// ============================================================================
/// CyberSignature - Internal Controller + Binding Pattern
/// ============================================================================
///
/// TRIẾT LÝ:
/// 1. Thuộc tính `text` là PRIMARY SOURCE - có thể binding trực tiếp
/// 2. Controller (nếu có) chỉ để điều khiển programmatically
/// 3. Nếu không truyền controller → tự tạo internal controller
/// 4. Sync 2 chiều: text binding <-> controller <-> UI
///
/// CÁCH DÙNG:
///
/// // Cách 1: Chỉ binding (không cần controller)
/// CyberSignature(
///   text: drEdit.bind("signature"),
///   label: "Chữ ký",
///   isSign: true,
///   isClear: true,
/// )
///
/// // Cách 2: Có controller để điều khiển
/// final signCtrl = CyberSignatureController();
/// CyberSignature(
///   controller: signCtrl,
///   text: drEdit.bind("signature"),
///   label: "Chữ ký",
///   onSigned: (base64) => print('Đã ký: $base64'),
/// )
/// signCtrl.triggerSign(); // Trigger action
///
/// ============================================================================

class CyberSignature extends StatefulWidget {
  final CyberSignatureController? controller;

  /// Thuộc tính text - có thể binding với CyberDataRow
  /// Hỗ trợ: String (base64), CyberBindingExpression, null
  final dynamic text;

  final String? label;
  final dynamic isSign; // Hiển thị nút ký
  final dynamic isView; // Hiển thị nút xem
  final dynamic isClear; // Hiển thị nút xóa
  final double? width;
  final double? height;
  final double borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final TextStyle? labelStyle;
  final bool isShowLabel;

  /// Callbacks
  final ValueChanged<String>? onChanged;
  final Function(dynamic)? onLeaver;
  final ValueChanged<String>? onSigned; // Callback sau khi ký xong
  final VoidCallback? onSignRequested; // Callback khi bắt đầu ký
  final VoidCallback? onViewRequested; // Callback khi xem
  final VoidCallback? onClearRequested; // Callback khi xóa

  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final bool enabled;
  final dynamic isVisible;

  // Signature pad settings
  final Color penColor;
  final double penStrokeWidth;
  final Color signaturePadBackgroundColor;

  // Icons
  final IconData? signIcon;
  final IconData? viewIcon;
  final IconData? clearIcon;

  const CyberSignature({
    super.key,
    this.controller,
    this.text,
    this.label,
    this.isSign = true,
    this.isView = true,
    this.isClear = true,
    this.width,
    this.height = 200,
    this.borderRadius = 12.0,
    this.placeholder,
    this.errorWidget,
    this.labelStyle,
    this.isShowLabel = true,
    this.onChanged,
    this.onLeaver,
    this.onSigned,
    this.onSignRequested,
    this.onViewRequested,
    this.onClearRequested,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 2.0,
    this.enabled = true,
    this.isVisible = true,
    this.penColor = Colors.black,
    this.penStrokeWidth = 3.0,
    this.signaturePadBackgroundColor = Colors.white,
    this.signIcon,
    this.viewIcon,
    this.clearIcon,
  });

  @override
  State<CyberSignature> createState() => _CyberSignatureState();
}

class _CyberSignatureState extends State<CyberSignature> {
  /// Internal controller (tự tạo nếu không có từ bên ngoài)
  CyberSignatureController? _internalController;

  /// Binding references
  CyberDataRow? _boundRow;
  String? _boundField;

  /// Visibility binding
  CyberDataRow? _visibilityBoundRow;
  String? _visibilityBoundField;

  /// State flags
  bool _isSyncing = false;

  /// Cache
  bool? _cachedVisibility;

  /// Effective controller - luôn có giá trị
  CyberSignatureController get _effectiveController =>
      widget.controller ?? _internalController!;

  @override
  void initState() {
    super.initState();
    _initializeController();
    _initializeBindings();
  }

  void _initializeController() {
    // Tạo internal controller nếu chưa có
    if (widget.controller == null) {
      _internalController = CyberSignatureController();
    }

    // Sync initial value từ binding vào controller
    final initialValue = _getValueFromBinding();
    _effectiveController.syncFromBinding(initialValue);

    // Listen controller changes
    _effectiveController.addListener(_onControllerChanged);
  }

  void _initializeBindings() {
    _parseTextBinding();
    _parseVisibilityBinding();
    _addAllListeners();
  }

  /// ============================================================================
  /// BINDING PARSING
  /// ============================================================================

  void _parseTextBinding() {
    if (widget.text is CyberBindingExpression) {
      final expr = widget.text as CyberBindingExpression;
      _boundRow = expr.row;
      _boundField = expr.fieldName;
    } else {
      _boundRow = null;
      _boundField = null;
    }
  }

  void _parseVisibilityBinding() {
    if (widget.isVisible is CyberBindingExpression) {
      final expr = widget.isVisible as CyberBindingExpression;
      _visibilityBoundRow = expr.row;
      _visibilityBoundField = expr.fieldName;
    } else {
      _visibilityBoundRow = null;
      _visibilityBoundField = null;
    }
  }

  /// ============================================================================
  /// LISTENER MANAGEMENT
  /// ============================================================================

  void _addAllListeners() {
    if (_boundRow != null) {
      _boundRow!.addListener(_onBindingChanged);
    }
    if (_visibilityBoundRow != null && _visibilityBoundRow != _boundRow) {
      _visibilityBoundRow!.addListener(_onVisibilityBindingChanged);
    }
  }

  void _removeAllListeners() {
    if (_boundRow != null) {
      _boundRow!.removeListener(_onBindingChanged);
    }
    if (_visibilityBoundRow != null && _visibilityBoundRow != _boundRow) {
      _visibilityBoundRow!.removeListener(_onVisibilityBindingChanged);
    }
  }

  /// ============================================================================
  /// SYNC LOGIC: BINDING <-> CONTROLLER <-> UI
  /// ============================================================================

  /// Khi binding thay đổi → sync vào controller
  void _onBindingChanged() {
    if (_isSyncing || !mounted) return;

    final newValue = _getValueFromBinding();
    if (newValue != _effectiveController.signatureData) {
      _isSyncing = true;
      _effectiveController.syncFromBinding(newValue);
      _isSyncing = false;

      if (mounted) {
        setState(() {});
      }
    }
  }

  /// Khi visibility binding thay đổi
  void _onVisibilityBindingChanged() {
    if (!mounted) return;
    _cachedVisibility = null;
    setState(() {});
  }

  /// Khi controller thay đổi → sync ra binding và UI
  void _onControllerChanged() {
    if (_isSyncing || !mounted) return;

    // Handle pending actions
    final action = _effectiveController.pendingAction;
    if (action != CyberSignatureAction.none) {
      _handlePendingAction(action);
      return;
    }

    // Handle signature data change
    final controllerData = _effectiveController.signatureData;
    final bindingData = _getValueFromBinding();

    if (controllerData != bindingData) {
      _isSyncing = true;

      // Sync controller → binding
      if (_boundRow != null && _boundField != null) {
        _boundRow![_boundField!] = controllerData ?? '';
      }

      _isSyncing = false;
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _handlePendingAction(CyberSignatureAction action) {
    if (!mounted) return;

    final signatureData = _getCurrentValue();
    final hasSignature = signatureData != null && signatureData.isNotEmpty;

    switch (action) {
      case CyberSignatureAction.sign:
        _showOptionsBottomSheet(hasSignature, true, false, false);
        break;
      case CyberSignatureAction.view:
        if (hasSignature) {
          _viewSignature(signatureData);
        }
        break;
      case CyberSignatureAction.clear:
        _clearSignature();
        break;
      case CyberSignatureAction.none:
        break;
    }
  }

  /// ============================================================================
  /// VALUE GETTERS
  /// ============================================================================

  /// Lấy value từ binding (nếu có)
  String? _getValueFromBinding() {
    if (_boundRow != null && _boundField != null) {
      try {
        final value = _boundRow![_boundField!];
        return value?.toString();
      } catch (e) {
        return null;
      }
    } else if (widget.text != null && widget.text is! CyberBindingExpression) {
      // Static value
      return widget.text.toString();
    }
    return null;
  }

  /// Lấy current value (ưu tiên controller)
  String? _getCurrentValue() {
    // Priority 1: Controller value
    final controllerValue = _effectiveController.signatureData;
    if (controllerValue != null && controllerValue.isNotEmpty) {
      return controllerValue;
    }

    // Priority 2: Binding value
    return _getValueFromBinding();
  }

  /// ============================================================================
  /// UPDATE VALUE
  /// ============================================================================

  void _updateValue(String? newValue) {
    if (!_effectiveController.enabled || !widget.enabled || _isSyncing) return;

    _isSyncing = true;

    // Update controller
    _effectiveController.loadSignature(newValue);

    // Update binding
    if (_boundRow != null && _boundField != null) {
      _boundRow![_boundField!] = newValue ?? '';
    }

    // Callbacks
    widget.onChanged?.call(newValue ?? '');
    widget.onLeaver?.call(newValue);

    // onSigned callback nếu có giá trị
    if (newValue != null && newValue.isNotEmpty) {
      widget.onSigned?.call(newValue);
    }

    _isSyncing = false;

    if (mounted) {
      setState(() {});
    }
  }

  /// ============================================================================
  /// VISIBILITY
  /// ============================================================================

  bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final lower = value.toLowerCase().trim();
      if (lower == "1" || lower == "true") return true;
      if (lower == "0" || lower == "false") return false;
      return false;
    }
    return false;
  }

  bool _isVisible() {
    if (_cachedVisibility != null) return _cachedVisibility!;

    if (_visibilityBoundRow != null && _visibilityBoundField != null) {
      _cachedVisibility = _parseBool(
        _visibilityBoundRow![_visibilityBoundField!],
      );
    } else {
      _cachedVisibility = _parseBool(widget.isVisible);
    }

    return _cachedVisibility!;
  }

  bool _canSign() {
    if (widget.isSign is CyberBindingExpression) {
      final expr = widget.isSign as CyberBindingExpression;
      try {
        return _parseBool(expr.row[expr.fieldName]);
      } catch (e) {
        return true;
      }
    }
    return _parseBool(widget.isSign);
  }

  bool _canView() {
    if (widget.isView is CyberBindingExpression) {
      final expr = widget.isView as CyberBindingExpression;
      try {
        return _parseBool(expr.row[expr.fieldName]);
      } catch (e) {
        return true;
      }
    }
    return _parseBool(widget.isView);
  }

  bool _canClear() {
    if (widget.isClear is CyberBindingExpression) {
      final expr = widget.isClear as CyberBindingExpression;
      try {
        return _parseBool(expr.row[expr.fieldName]);
      } catch (e) {
        return true;
      }
    }
    return _parseBool(widget.isClear);
  }

  /// ============================================================================
  /// SIGNATURE ACTIONS
  /// ============================================================================

  Future<void> _handleSignatureTap() async {
    if (!_effectiveController.enabled || !widget.enabled) return;

    final signatureData = _getCurrentValue();
    final hasSignature = signatureData != null && signatureData.isNotEmpty;

    final canSign = _canSign();
    final canView = _canView();
    final canClear = _canClear();

    if (!canSign && !canView && !canClear) return;

    // Simple case: chỉ view
    if (canView && hasSignature && !canSign && !canClear) {
      widget.onViewRequested?.call();
      await _viewSignature(signatureData);
      return;
    }

    if (!mounted) return;
    await _showOptionsBottomSheet(hasSignature, canSign, canView, canClear);
  }

  Future<void> _showOptionsBottomSheet(
    bool hasSignature,
    bool canSign,
    bool canView,
    bool canClear,
  ) async {
    if (!mounted) return;

    try {
      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => _SignatureOptionsSheet(
          hasSignature: hasSignature,
          canSign: canSign,
          canView: canView,
          canClear: canClear,
          signIcon: widget.signIcon,
          viewIcon: widget.viewIcon,
          clearIcon: widget.clearIcon,
          onSign: () async {
            Navigator.pop(context);
            await _openSignaturePad();
          },
          onView: () async {
            Navigator.pop(context);
            final signatureData = _getCurrentValue();
            if (signatureData != null && signatureData.isNotEmpty) {
              widget.onViewRequested?.call();
              await _viewSignature(signatureData);
            }
          },
          onClear: () async {
            Navigator.pop(context);
            widget.onClearRequested?.call();
            await _clearSignature();
          },
        ),
      );
    } catch (e) {
      debugPrint('Error showing bottom sheet: $e');
    }
  }

  Future<void> _openSignaturePad() async {
    widget.onSignRequested?.call();

    try {
      final currentSignature = _getCurrentValue();

      final result = await showDialog<String>(
        context: context,
        builder: (context) => CyberSignaturePad(
          initialSignature: currentSignature,
          penColor: widget.penColor,
          penStrokeWidth: widget.penStrokeWidth,
          backgroundColor: widget.signaturePadBackgroundColor,
        ),
      );

      if (result != null && result.isNotEmpty) {
        _updateValue(result);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi ký: $e')));
      }
    }
  }

  Future<void> _viewSignature(String signatureData) async {
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            CyberFullscreenSignatureViewer(signatureValue: signatureData),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _clearSignature() async {
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa chữ ký này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _updateValue(null);
    }
  }

  /// ============================================================================
  /// WIDGET LIFECYCLE
  /// ============================================================================

  @override
  void didUpdateWidget(CyberSignature oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Controller changed
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerChanged);

      if (widget.controller == null && _internalController == null) {
        _internalController = CyberSignatureController();
      }

      final currentValue = _getValueFromBinding();
      _effectiveController.syncFromBinding(currentValue);
      _effectiveController.addListener(_onControllerChanged);
    }

    // Bindings changed
    bool bindingsChanged = false;

    if (oldWidget.text != widget.text) {
      bindingsChanged = true;
    }
    if (oldWidget.isVisible != widget.isVisible) {
      bindingsChanged = true;
      _cachedVisibility = null;
    }

    if (bindingsChanged) {
      _removeAllListeners();
      _initializeBindings();

      // Sync new binding value to controller
      final newValue = _getValueFromBinding();
      _effectiveController.syncFromBinding(newValue);
    }
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_onControllerChanged);
    _removeAllListeners();
    _cachedVisibility = null;
    _internalController?.dispose();
    super.dispose();
  }

  /// ============================================================================
  /// BUILD UI
  /// ============================================================================

  @override
  Widget build(BuildContext context) {
    if (!_isVisible()) {
      return const SizedBox.shrink();
    }

    final listeners = <Listenable>[];
    if (_boundRow != null) listeners.add(_boundRow!);
    if (_visibilityBoundRow != null && _visibilityBoundRow != _boundRow) {
      listeners.add(_visibilityBoundRow!);
    }

    Widget buildSignature() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isShowLabel &&
              widget.label != null &&
              widget.label!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
              child: Text(
                widget.label!,
                style:
                    widget.labelStyle ??
                    const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF555555),
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          _buildSignatureContainer(),
        ],
      );
    }

    if (listeners.isNotEmpty) {
      return ListenableBuilder(
        listenable: Listenable.merge(listeners),
        builder: (context, child) => buildSignature(),
      );
    }

    return buildSignature();
  }

  Widget _buildSignatureContainer() {
    final signatureData = _getCurrentValue();
    final hasSignature = signatureData != null && signatureData.isNotEmpty;
    final isEnabled = _effectiveController.enabled && widget.enabled;

    Widget signatureWidget;

    if (hasSignature) {
      signatureWidget = _buildSignatureWidget(signatureData);
    } else {
      signatureWidget = _buildPlaceholder();
    }

    return GestureDetector(
      onTap: isEnabled ? _handleSignatureTap : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? Colors.grey[100],
            border: widget.borderColor != null
                ? Border.all(
                    color: widget.borderColor!,
                    width: widget.borderWidth,
                  )
                : null,
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: signatureWidget,
          ),
        ),
      ),
    );
  }

  Uint8List? _decodeBase64(String base64String) {
    try {
      String base64Data = base64String;
      if (base64String.contains(',')) {
        base64Data = base64String.split(',').last;
      }
      return base64Decode(base64Data);
    } catch (e) {
      debugPrint('Error decoding base64: $e');
      return null;
    }
  }

  Widget _buildSignatureWidget(String signatureData) {
    try {
      final bytes = _decodeBase64(signatureData);
      if (bytes == null) {
        return widget.errorWidget ?? _buildErrorWidget();
      }

      return Container(
        color: Colors.white,
        padding: const EdgeInsets.all(8),
        child: Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return widget.errorWidget ?? _buildErrorWidget();
          },
        ),
      );
    } catch (e) {
      return widget.errorWidget ?? _buildErrorWidget();
    }
  }

  Widget _buildPlaceholder() {
    if (widget.placeholder != null) return widget.placeholder!;

    final height = widget.height ?? 200;
    final isSmall = height < 120;

    return Center(
      child: isSmall
          ? Icon(
              Icons.draw_outlined,
              size: height * 0.4,
              color: Colors.grey[400],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.draw_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  _canSign() ? 'Nhấn để ký' : 'Chưa có chữ ký',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
    );
  }

  Widget _buildErrorWidget() {
    final height = widget.height ?? 200;
    final isSmall = height < 120;

    return Center(
      child: isSmall
          ? Icon(
              Icons.broken_image,
              size: height * 0.4,
              color: Colors.grey[400],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'Lỗi hiển thị chữ ký',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
    );
  }
}

/// ============================================================================
/// Signature Options Bottom Sheet
/// ============================================================================

class _SignatureOptionsSheet extends StatelessWidget {
  final bool hasSignature;
  final bool canSign;
  final bool canView;
  final bool canClear;
  final IconData? signIcon;
  final IconData? viewIcon;
  final IconData? clearIcon;
  final VoidCallback onSign;
  final VoidCallback onView;
  final VoidCallback onClear;

  const _SignatureOptionsSheet({
    required this.hasSignature,
    required this.canSign,
    required this.canView,
    required this.canClear,
    this.signIcon,
    this.viewIcon,
    this.clearIcon,
    required this.onSign,
    required this.onView,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
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
                children: [
                  const Text(
                    'Chọn hành động',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (canSign)
              _buildOption(
                icon: signIcon ?? Icons.edit,
                iconColor: Colors.blue,
                label: hasSignature ? 'Ký lại' : 'Ký tên',
                subtitle: hasSignature
                    ? 'Thay đổi chữ ký hiện tại'
                    : 'Tạo chữ ký mới',
                onTap: onSign,
              ),
            if (canView && hasSignature)
              _buildOption(
                icon: viewIcon ?? Icons.visibility,
                iconColor: Colors.purple,
                label: 'Xem chữ ký',
                subtitle: 'Xem toàn màn hình',
                onTap: onView,
              ),
            if (canClear && hasSignature)
              _buildOption(
                icon: clearIcon ?? Icons.delete,
                iconColor: Colors.red,
                label: 'Xóa chữ ký',
                subtitle: 'Xóa chữ ký hiện tại',
                onTap: onClear,
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
