import 'package:cyberframework/cyberframework.dart';

/// CyberCheckbox - Checkbox control với Internal Controller + Binding
///
/// Hỗ trợ binding 2 chiều:
/// ```dart
/// CyberCheckbox(
///   text: drEdit.bind('is_active'),    // Binding boolean field
///   label: 'Kích hoạt',
/// )
/// ```
class CyberCheckbox extends StatefulWidget {
  // === DATA BINDING ===
  /// Value - có thể binding: dr.bind('is_active')
  /// Hỗ trợ: bool, int (0/1), String ("0"/"1", "true"/"false")
  final dynamic text;

  /// Callback khi giá trị thay đổi
  final ValueChanged<bool>? onChanged;

  /// Callback khi rời khỏi (blur)
  final Function(dynamic)? onLeaver;

  // === UI PROPERTIES ===
  final String? label;
  final TextStyle? labelStyle;
  final bool enabled;
  final Color? activeColor;
  final Color? checkColor;
  final double? size;
  final dynamic isVisible;

  const CyberCheckbox({
    super.key,
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
  });

  @override
  State<CyberCheckbox> createState() => _CyberCheckboxState();
}

// ============================================================================
// INTERNAL STATE - QUẢN LÝ CONTROLLER VÀ BINDING
// ============================================================================

class _CyberCheckboxState extends State<CyberCheckbox> {
  // === INTERNAL CONTROLLER ===
  late final _InternalCheckboxController _controller;

  // === BINDING CONTEXT ===
  CyberDataRow? _boundRow;
  String? _boundField;

  // === VISIBILITY BINDING ===
  CyberDataRow? _visibilityBoundRow;
  String? _visibilityBoundField;

  // === FLAGS ===
  bool _isInternalUpdate = false;

  @override
  void initState() {
    super.initState();

    // Khởi tạo internal controller
    _controller = _InternalCheckboxController();

    // Parse bindings
    _parseBinding();
    _parseVisibilityBinding();

    // Sync initial value
    _syncFromWidget();

    // Listen to controller changes
    _controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(CyberCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Re-parse bindings nếu properties thay đổi
    if (widget.text != oldWidget.text) {
      _parseBinding();
    }
    if (widget.isVisible != oldWidget.isVisible) {
      _parseVisibilityBinding();
    }

    // Sync values
    _syncFromWidget();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();

    // Cleanup bindings
    _boundRow?.removeListener(_onBindingChanged);

    super.dispose();
  }

  // ============================================================================
  // BINDING PARSERS
  // ============================================================================

  void _parseBinding() {
    // Cleanup old binding
    if (_boundRow != null) {
      _boundRow!.removeListener(_onBindingChanged);
      _boundRow = null;
      _boundField = null;
    }

    // Parse new binding
    if (widget.text is CyberBindingExpression) {
      final expr = widget.text as CyberBindingExpression;
      _boundRow = expr.row;
      _boundField = expr.fieldName;
      _boundRow!.addListener(_onBindingChanged);
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

  // ============================================================================
  // SYNC LOGIC
  // ============================================================================

  /// Sync từ widget properties vào controller
  void _syncFromWidget() {
    if (_isInternalUpdate) return;

    _isInternalUpdate = true;

    final value = _extractValue(widget.text);
    if (_controller.value != value) {
      _controller._value = value;
    }

    _isInternalUpdate = false;
  }

  /// Sync từ binding vào controller
  void _onBindingChanged() {
    if (_isInternalUpdate || !mounted) return;
    if (_boundRow == null || _boundField == null) return;

    _isInternalUpdate = true;

    final newValue = _parseBool(_boundRow![_boundField!]);
    if (_controller.value != newValue) {
      _controller._value = newValue;
      _controller.notifyListeners();
    }

    _isInternalUpdate = false;
  }

  /// Sync từ controller vào binding (khi user click checkbox)
  void _syncToBinding(bool newValue) {
    if (_isInternalUpdate) return;

    _isInternalUpdate = true;

    // Update controller
    _controller._value = newValue;

    // Update binding - preserve original type
    if (_boundRow != null && _boundField != null) {
      final originalValue = _boundRow![_boundField!];

      // Preserve type: String → "0"/"1", int → 0/1, bool → bool
      if (originalValue is String) {
        _boundRow![_boundField!] = newValue ? "1" : "0";
      } else if (originalValue is int) {
        _boundRow![_boundField!] = newValue ? 1 : 0;
      } else if (originalValue is double) {
        _boundRow![_boundField!] = newValue ? 1.0 : 0.0;
      } else {
        _boundRow![_boundField!] = newValue;
      }
    }

    // Callbacks
    widget.onChanged?.call(newValue);
    widget.onLeaver?.call(newValue);

    _isInternalUpdate = false;
    _controller.notifyListeners();
  }

  /// Listen to controller changes
  void _onControllerChanged() {
    if (!mounted || _isInternalUpdate) return;
    setState(() {}); // Rebuild UI
  }

  // ============================================================================
  // VALUE EXTRACTORS
  // ============================================================================

  bool _extractValue(dynamic value) {
    if (value is CyberBindingExpression) {
      try {
        return _parseBool(value.row[value.fieldName]);
      } catch (e) {
        return false;
      }
    }
    return _parseBool(value);
  }

  /// Parse dynamic value to bool
  /// Supports: bool, int (0/1), String ("0"/"1", "true"/"false")
  bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is double) return value.toInt() == 1;
    if (value is String) {
      final trimmed = value.trim().toLowerCase();
      if (trimmed == "1" || trimmed == "true") return true;
      if (trimmed == "0" || trimmed == "false") return false;
      return false;
    }
    return false;
  }

  // ============================================================================
  // VISIBILITY HELPERS
  // ============================================================================

  bool _isVisible() {
    if (_visibilityBoundRow != null && _visibilityBoundField != null) {
      return _parseBool(_visibilityBoundRow![_visibilityBoundField!]);
    }
    return _parseBool(widget.isVisible);
  }

  // ============================================================================
  // ACTIONS
  // ============================================================================

  void _toggleValue() {
    if (!widget.enabled) return;

    final newValue = !_controller.value;
    _syncToBinding(newValue);
  }

  // ============================================================================
  // BUILD UI
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    Widget buildCheckboxWidget() {
      if (!_isVisible()) {
        return const SizedBox.shrink();
      }

      final isChecked = _controller.value;
      final isEnabled = widget.enabled;

      // iOS-style checkbox display
      Widget checkboxDisplay = _IOSCheckbox(
        value: isChecked,
        enabled: isEnabled,
        activeColor: widget.activeColor ?? const Color(0xFF00D287),
        checkColor: widget.checkColor ?? Colors.white,
        size: widget.size ?? 24,
      );

      // With label: InkWell + Row
      if (widget.label != null && widget.label!.isNotEmpty) {
        return InkWell(
          onTap: isEnabled ? _toggleValue : null,
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

      // Without label: GestureDetector
      return GestureDetector(
        onTap: isEnabled ? _toggleValue : null,
        child: checkboxDisplay,
      );
    }

    // Use ListenableBuilder if there are bindings
    final listeners = <Listenable>[];
    if (_boundRow != null) listeners.add(_boundRow!);
    if (_visibilityBoundRow != null && _visibilityBoundRow != _boundRow) {
      listeners.add(_visibilityBoundRow!);
    }

    if (listeners.isNotEmpty) {
      return ListenableBuilder(
        listenable: Listenable.merge(listeners),
        builder: (context, child) => buildCheckboxWidget(),
      );
    }

    return buildCheckboxWidget();
  }
}

// ============================================================================
// INTERNAL CONTROLLER
// ============================================================================

class _InternalCheckboxController extends ChangeNotifier {
  bool _value = false;

  bool get value => _value;
}

// ============================================================================
// iOS-STYLE CHECKBOX WIDGET
// ============================================================================

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

// ============================================================================
// EXTENSION HELPERS
// ============================================================================

/// Extension để tạo checkbox từ String label
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
