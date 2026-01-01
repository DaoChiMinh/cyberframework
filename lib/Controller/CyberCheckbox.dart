import 'package:cyberframework/cyberframework.dart';

class CyberCheckbox extends StatefulWidget {
  final CyberCheckboxController? controller;
  final dynamic text;
  final String? label;
  final bool enabled;
  final TextStyle? labelStyle;
  final ValueChanged<bool>? onChanged;
  final Function(dynamic)? onLeaver;
  final Color? activeColor;
  final Color? checkColor;
  final double? size;
  final dynamic isVisible;

  const CyberCheckbox({
    super.key,
    this.controller,
    this.text,
    this.label,
    this.enabled = true,
    this.labelStyle,
    this.onChanged,
    this.onLeaver,
    this.activeColor,
    this.checkColor,
    this.size,
    this.isVisible = true,
  }) : assert(
         controller == null || text == null,
         'CyberCheckbox: không được dùng controller cùng với text/binding trực tiếp',
       );

  @override
  State<CyberCheckbox> createState() => _CyberCheckboxState();
}

class _CyberCheckboxState extends State<CyberCheckbox> {
  // Internal controller nếu không có từ bên ngoài
  CyberCheckboxController? _internalController;

  // Binding references (giữ cho backward compatible)
  CyberDataRow? _boundRow;
  String? _boundField;
  CyberDataRow? _visibilityBoundRow;
  String? _visibilityBoundField;

  // State flags
  bool _isUpdating = false;

  // Cache
  bool? _cachedVisibility;

  // Track để tránh rebuild
  bool? _lastValue;

  CyberCheckboxController get _effectiveController =>
      widget.controller ?? _internalController!;

  @override
  void initState() {
    super.initState();

    // Tạo internal controller nếu cần
    if (widget.controller == null) {
      _internalController = CyberCheckboxController();

      // Set initial value từ binding hoặc text
      final initialValue = _getInitialValue();
      _internalController!.setValueInternal(initialValue);
      _lastValue = initialValue;
    }

    _parseBinding();
    _parseVisibilityBinding();
    _addAllListeners();
    _effectiveController.addListener(_onControllerChanged);
  }

  bool _getInitialValue() {
    if (widget.text is CyberBindingExpression) {
      final expr = widget.text as CyberBindingExpression;
      try {
        final value = expr.row[expr.fieldName];
        return _parseBool(value);
      } catch (e) {
        return false;
      }
    } else if (widget.text != null && widget.text is! CyberBindingExpression) {
      return _parseBool(widget.text);
    }
    return false;
  }

  void _onControllerChanged() {
    if (!mounted || _isUpdating) return;

    // Handle value change
    final newValue = _effectiveController.value;
    if (_lastValue != newValue) {
      _lastValue = newValue;

      // Sync to binding if exists
      if (_boundRow != null && _boundField != null && !_isUpdating) {
        _isUpdating = true;
        _updateBindingValue(newValue);
        _isUpdating = false;
      }

      if (mounted) {
        setState(() {});
      }
    }

    // Handle enabled state change
    if (mounted) {
      setState(() {});
    }
  }

  void _updateBindingValue(bool newValue) {
    if (_boundRow == null || _boundField == null) return;

    final originalValue = _boundRow![_boundField!];

    // Preserve original type
    if (originalValue is String) {
      _boundRow![_boundField!] = newValue ? "1" : "0";
    } else if (originalValue is int) {
      _boundRow![_boundField!] = newValue ? 1 : 0;
    } else {
      _boundRow![_boundField!] = newValue;
    }
  }

  @override
  void didUpdateWidget(CyberCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Controller changed
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerChanged);

      if (widget.controller == null && _internalController == null) {
        _internalController = CyberCheckboxController();
        final initialValue = _getInitialValue();
        _internalController!.setValueInternal(initialValue);
        _lastValue = initialValue;
      }

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
      _parseBinding();
      _parseVisibilityBinding();
      _addAllListeners();

      // Update internal controller from new binding
      if (widget.controller == null) {
        final newValue = _getInitialValue();
        if (newValue != _internalController!.value) {
          _internalController!.setValueInternal(newValue);
          _lastValue = newValue;
        }
      }
    }
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_onControllerChanged);
    _removeAllListeners();
    _internalController?.dispose();
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

  void _addAllListeners() {
    if (_boundRow != null) {
      _boundRow!.addListener(_onBindingChanged);
    }
    if (_visibilityBoundRow != null && _visibilityBoundRow != _boundRow) {
      _visibilityBoundRow!.addListener(_onBindingChanged);
    }
  }

  void _removeAllListeners() {
    if (_boundRow != null) {
      _boundRow!.removeListener(_onBindingChanged);
    }
    if (_visibilityBoundRow != null && _visibilityBoundRow != _boundRow) {
      _visibilityBoundRow!.removeListener(_onBindingChanged);
    }
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

  void _onBindingChanged() {
    if (_isUpdating) return;

    // Sync binding value to controller
    final currentBindingValue = _getCurrentValueFromBinding();
    if (currentBindingValue != _effectiveController.value) {
      _isUpdating = true;
      _effectiveController.setValueInternal(currentBindingValue);
      _lastValue = currentBindingValue;
      _isUpdating = false;
    }

    _cachedVisibility = null;

    if (mounted) {
      setState(() {});
    }
  }

  bool _getCurrentValueFromBinding() {
    if (_boundRow != null && _boundField != null) {
      try {
        final value = _boundRow![_boundField!];
        return _parseBool(value);
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  bool _getCurrentValue() {
    // Ưu tiên controller
    return _effectiveController.value;
  }

  /// Parse dynamic value to bool
  /// Ưu tiên: string "1" = true, "0" = false
  bool _parseBool(dynamic value) {
    if (value == null) return false;

    // Bool trực tiếp
    if (value is bool) return value;

    // Int: 1 = true, 0 = false
    if (value is int) return value == 1;

    // String: "1" = true, "0" = false
    if (value is String) {
      final trimmed = value.trim().toLowerCase();
      if (trimmed == "1" || trimmed == "true") return true;
      if (trimmed == "0" || trimmed == "false") return false;
      return false;
    }

    return false;
  }

  void _updateValue(bool newValue) {
    if (!_effectiveController.enabled || !widget.enabled) return;

    _isUpdating = true;

    // Update controller
    _effectiveController.setValueInternal(newValue);

    // Update binding
    if (_boundRow != null && _boundField != null) {
      _updateBindingValue(newValue);
    }

    _lastValue = newValue;

    // Callback
    widget.onChanged?.call(newValue);
    widget.onLeaver?.call(newValue);

    setState(() {
      _isUpdating = false;
    });
  }

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

    Widget buildCheckbox() {
      final isChecked = _getCurrentValue();
      final isEnabled = _effectiveController.enabled && widget.enabled;

      // iOS Checkbox widget (không có gesture)
      Widget checkboxDisplay = _IOSCheckbox(
        value: isChecked,
        enabled: isEnabled,
        activeColor: widget.activeColor ?? const Color(0xFF00D287),
        checkColor: widget.checkColor ?? Colors.white,
        size: widget.size ?? 24,
      );

      // Nếu có label, wrap với InkWell + Row
      if (widget.label != null && widget.label!.isNotEmpty) {
        return InkWell(
          onTap: isEnabled ? () => _updateValue(!isChecked) : null,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                checkboxDisplay,
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.label!,
                    style:
                        widget.labelStyle ??
                        TextStyle(
                          fontSize: 16,
                          color: isEnabled ? Colors.black87 : Colors.grey,
                        ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // Không có label, wrap checkbox với GestureDetector
      return GestureDetector(
        onTap: isEnabled ? () => _updateValue(!isChecked) : null,
        child: checkboxDisplay,
      );
    }

    if (listeners.isNotEmpty) {
      return ListenableBuilder(
        listenable: Listenable.merge(listeners),
        builder: (context, child) => buildCheckbox(),
      );
    }

    return buildCheckbox();
  }
}

/// iOS-style Checkbox Widget
class _IOSCheckbox extends StatelessWidget {
  final bool value;
  final bool enabled;
  final Color activeColor;
  final Color checkColor;
  final double size;

  const _IOSCheckbox({
    required this.value,
    required this.enabled,
    required this.activeColor,
    required this.checkColor,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final opacity = enabled ? 1.0 : 0.5;

    return Opacity(
      opacity: opacity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: value ? activeColor : Colors.transparent,
          border: Border.all(
            color: value ? activeColor : Colors.grey[400]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(size * 0.25),
        ),
        child: value
            ? Icon(Icons.check, color: checkColor, size: size * 0.7)
            : null,
      ),
    );
  }
}

/// Extension để tạo clickable checkbox từ String (optional)
extension CyberCheckboxExtension on String {
  Widget toCheckbox(
    BuildContext context, {
    dynamic value,
    bool enabled = true,
    ValueChanged<bool>? onChanged,
  }) {
    return CyberCheckbox(
      text: value,
      label: this,
      enabled: enabled,
      onChanged: onChanged,
    );
  }
}
