import 'package:flutter/material.dart';

// ============================================================================
// MODEL - CyberSwitchOption
// ============================================================================

/// Model cho mỗi option trong CyberSwitchButton
class CyberSwitchOption {
  final String label;
  final dynamic value; // ✅ Giá trị khi được chọn
  final IconData? icon;
  final int? badgeCount;
  final Color? badgeColor;
  final bool enabled;

  const CyberSwitchOption({
    required this.label,
    this.value,
    this.icon,
    this.badgeCount,
    this.badgeColor,
    this.enabled = true,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CyberSwitchOption &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          value == other.value;

  @override
  int get hashCode => label.hashCode ^ value.hashCode;
}

// ============================================================================
// WIDGET - CyberSwitchButton
// ============================================================================

/// Segmented switch button control với smooth animation và event handling
/// Không có child widgets - chỉ có event callback
class CyberSwitchButton extends StatefulWidget {
  /// Danh sách options
  final List<CyberSwitchOption> options;

  /// Index được chọn ban đầu
  final int initialIndex;

  /// Callback khi option được chọn
  /// Trả về: index, value, và option được chọn
  final Function(int index, dynamic value, CyberSwitchOption option)? onChanged;

  // ✅ Styling options
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? textColor;
  final Color? selectedTextColor;
  final BorderRadius? borderRadius;
  final double? spacing;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? height;

  // ✅ Layout options
  final bool isScrollable;
  final bool isExpanded; // ✅ Các option chiếm đều không gian (fixed width)

  // ✅ Animation options
  final Duration? animationDuration;
  final Curve? animationCurve;

  // ✅ Shadow options
  final bool showShadow;
  final double? shadowBlurRadius;
  final Offset? shadowOffset;

  const CyberSwitchButton({
    super.key,
    required this.options,
    this.initialIndex = 0,
    this.onChanged,
    this.backgroundColor,
    this.selectedColor,
    this.textColor,
    this.selectedTextColor,
    this.borderRadius,
    this.spacing = 2.0,
    this.padding,
    this.margin,
    this.height,
    this.isScrollable = false,
    this.isExpanded = true,
    this.animationDuration,
    this.animationCurve = Curves.easeInOut,
    this.showShadow = true,
    this.shadowBlurRadius,
    this.shadowOffset,
  }) : assert(options.length > 0, 'Options cannot be empty');

  @override
  State<CyberSwitchButton> createState() => _CyberSwitchButtonState();
}

class _CyberSwitchButtonState extends State<CyberSwitchButton> {
  late int _selectedIndex;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, widget.options.length - 1);
    _scrollController = ScrollController();

    // ✅ Auto scroll to selected option if scrollable
    if (widget.isScrollable) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToOption(_selectedIndex);
      });
    }
  }

  @override
  void didUpdateWidget(CyberSwitchButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ✅ Update selected index if options changed
    if (widget.options != oldWidget.options) {
      _selectedIndex = _selectedIndex.clamp(0, widget.options.length - 1);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// ✅ Auto scroll to show selected option
  void _scrollToOption(int index) {
    if (!_scrollController.hasClients || !widget.isScrollable) return;

    // ✅ Estimate option width
    final estimatedWidth = _estimateOptionWidth(widget.options[index]);

    // ✅ Calculate target offset
    double targetOffset = 0;
    for (int i = 0; i < index; i++) {
      targetOffset += _estimateOptionWidth(widget.options[i]);
    }

    final viewportWidth = _scrollController.position.viewportDimension;
    final maxScroll = _scrollController.position.maxScrollExtent;

    // ✅ Center option in viewport
    final centeredOffset =
        (targetOffset - viewportWidth / 2 + estimatedWidth / 2).clamp(
          0.0,
          maxScroll,
        );

    _scrollController.animateTo(
      centeredOffset,
      duration: widget.animationDuration ?? const Duration(milliseconds: 250),
      curve: widget.animationCurve ?? Curves.easeOut,
    );
  }

  /// ✅ Estimate option width
  double _estimateOptionWidth(CyberSwitchOption option) {
    double width = 32.0 + (option.label.length * 8.0).clamp(60.0, 120.0);
    if (option.icon != null) width += 24.0;
    if (option.badgeCount != null && option.badgeCount! > 0) width += 28.0;
    width += (widget.spacing ?? 2) * 2;
    return width;
  }

  /// ✅ Handle option selection
  void _handleOptionTap(int index) {
    final option = widget.options[index];

    // ✅ Ignore if disabled
    if (!option.enabled) return;

    // ✅ Ignore if already selected
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    // ✅ Auto scroll if scrollable
    if (widget.isScrollable) {
      _scrollToOption(index);
    }

    // ✅ Notify callback
    widget.onChanged?.call(index, option.value ?? index, option);
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Default colors
    final bgColor = widget.backgroundColor ?? const Color(0xFFE8F5E9);
    final selectedBg =
        widget.selectedColor ?? const Color.fromARGB(255, 224, 224, 224);

    final container = Container(
      height: widget.height,
      margin:
          widget.margin ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: widget.padding ?? const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: widget.borderRadius ?? BorderRadius.circular(18),
        boxShadow: widget.showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: widget.shadowBlurRadius ?? 8,
                  offset: widget.shadowOffset ?? const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: widget.isScrollable
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              controller: _scrollController,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: _buildOptions(),
              ),
            )
          : Row(
              mainAxisSize: widget.isExpanded
                  ? MainAxisSize.max
                  : MainAxisSize.min,
              children: _buildOptions(),
            ),
    );

    return container;
  }

  /// ✅ Build option widgets
  List<Widget> _buildOptions() {
    return List.generate(widget.options.length, (index) {
      final option = widget.options[index];
      final isSelected = index == _selectedIndex;

      final optionWidget = _AnimatedSwitchOption(
        key: ValueKey('option_$index'),
        isSelected: isSelected,
        option: option,
        selectedColor: widget.selectedColor,
        selectedTextColor: widget.selectedTextColor,
        textColor: widget.textColor,
        spacing: widget.spacing,
        animationDuration:
            widget.animationDuration ?? const Duration(milliseconds: 250),
        animationCurve: widget.animationCurve ?? Curves.easeInOut,
        onTap: () => _handleOptionTap(index),
      );

      // ✅ Scrollable: không wrap
      if (widget.isScrollable || !widget.isExpanded) {
        return optionWidget;
      }

      // ✅ Fixed & Expanded: wrap trong Expanded
      return Expanded(child: optionWidget);
    });
  }
}

// ============================================================================
// ANIMATED SWITCH OPTION
// ============================================================================

class _AnimatedSwitchOption extends StatelessWidget {
  final bool isSelected;
  final CyberSwitchOption option;
  final Color? selectedColor;
  final Color? selectedTextColor;
  final Color? textColor;
  final double? spacing;
  final Duration animationDuration;
  final Curve animationCurve;
  final VoidCallback onTap;

  const _AnimatedSwitchOption({
    super.key,
    required this.isSelected,
    required this.option,
    this.selectedColor,
    this.selectedTextColor,
    this.textColor,
    this.spacing,
    required this.animationDuration,
    required this.animationCurve,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Extract colors once
    final selectedBg =
        selectedColor ?? const Color.fromARGB(255, 224, 224, 224);
    final selectedText = selectedTextColor ?? Colors.white;
    final unselectedText = textColor ?? const Color(0xFF2E7D32);

    // ✅ Disabled state
    final isDisabled = !option.enabled;
    final opacity = isDisabled ? 0.4 : 1.0;

    // ✅ Badge colors
    final badgeBgSelected =
        option.badgeColor ?? Colors.white.withValues(alpha: 0.9);
    final badgeBgUnselected =
        option.badgeColor ?? selectedBg.withValues(alpha: 0.2);
    final badgeTextSelected = option.badgeColor != null
        ? _getContrastColor(option.badgeColor!)
        : selectedBg;
    final badgeTextUnselected = option.badgeColor != null
        ? _getContrastColor(option.badgeColor!)
        : unselectedText;

    return Opacity(
      opacity: opacity,
      child: GestureDetector(
        onTap: isDisabled ? null : onTap,
        child: AnimatedContainer(
          duration: animationDuration,
          curve: animationCurve,
          margin: EdgeInsets.symmetric(horizontal: spacing ?? 2),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          constraints: const BoxConstraints(minHeight: 40),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: selectedBg.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: _buildOptionContent(
            isSelected,
            selectedText,
            unselectedText,
            badgeBgSelected,
            badgeBgUnselected,
            badgeTextSelected,
            badgeTextUnselected,
          ),
        ),
      ),
    );
  }

  /// ✅ Build option content
  Widget _buildOptionContent(
    bool isSelected,
    Color selectedText,
    Color unselectedText,
    Color badgeBgSelected,
    Color badgeBgUnselected,
    Color badgeTextSelected,
    Color badgeTextUnselected,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Icon
        if (option.icon != null) ...[
          Icon(
            option.icon,
            size: 18,
            color: isSelected ? selectedText : unselectedText,
          ),
          const SizedBox(width: 6),
        ],

        // Label
        Flexible(
          child: AnimatedDefaultTextStyle(
            duration: animationDuration,
            curve: animationCurve,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? selectedText : unselectedText,
            ),
            child: Text(
              option.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),

        // Badge
        if (option.badgeCount != null && option.badgeCount! > 0) ...[
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: animationDuration,
            curve: animationCurve,
            constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isSelected ? badgeBgSelected : badgeBgUnselected,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                option.badgeCount.toString(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? badgeTextSelected : badgeTextUnselected,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// ✅ Get contrasting text color for badge
  Color _getContrastColor(Color backgroundColor) {
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
