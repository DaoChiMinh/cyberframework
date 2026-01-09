import 'package:cyberframework/cyberframework.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui';

/// Enum định nghĩa kiểu hiển thị của menu
enum CyberActionType {
  /// Menu có main button, tự động ẩn/hiện khi hover hoặc click
  autoShow,

  /// Menu không có main button, items luôn hiển thị
  alwaysShow,
}

/// Enum định nghĩa hướng mở rộng của menu
enum CyberActionDirection {
  /// Mở rộng theo chiều dọc (top to bottom)
  vertical,

  /// Mở rộng theo chiều ngang (left to right)
  horizontal,
}

/// Enum định nghĩa vị trí label
enum LabelPosition {
  /// Label ở bên phải icon (mặc định)
  right,

  /// Label ở bên trái icon
  left,

  /// Label ở bên dưới icon
  bottom,
}

/// Class định nghĩa một button action trong menu
class CyberButtonAction {
  /// Label hiển thị khi hover
  final String label;

  /// Icon code (sử dụng CyberLabel để parse)
  final String icon;

  /// Callback khi click
  final VoidCallback? onclick;

  /// Style cho label tooltip
  final TextStyle? styleLabel;

  /// Style cho icon
  final TextStyle? styleIcon;

  /// Màu nền của button (default: Color.fromARGB(255, 247, 247, 247))
  final Color? backgroundColor;

  /// Opacity của background button (0.0 - 1.0)
  final double? backgroundOpacity;

  /// Màu icon (override styleIcon.color)
  final Color? iconColor;

  /// Size của icon
  final double? iconSize;

  /// Có hiển thị button này không (mặc định true)
  final bool visible;

  /// Hiển thị label (desktop: ignore hover, mobile: hiển thị luôn)
  final bool showLabel;

  /// Vị trí của label (right, left, bottom)
  final LabelPosition labelPosition;

  const CyberButtonAction({
    required this.label,
    required this.icon,
    this.onclick,
    this.styleLabel,
    this.styleIcon,
    this.backgroundColor,
    this.backgroundOpacity,
    this.iconColor,
    this.iconSize,
    this.visible = true,
    this.showLabel = false,
    this.labelPosition = LabelPosition.right,
  });
}

/// Floating Action Button Menu với auto show/hide
class CyberAction extends StatefulWidget {
  /// Danh sách các button actions
  final List<CyberButtonAction> children;

  /// Kiểu hiển thị menu
  final CyberActionType type;

  /// Vị trí top (null = không set)
  final double? top;

  /// Vị trí left (null = không set)
  final double? left;

  /// Vị trí bottom (null = không set)
  final double? bottom;

  /// Vị trí right (null = không set)
  final double? right;

  /// Căn giữa theo chiều dọc (bỏ qua top/bottom)
  final bool isCenterVer;

  /// Căn giữa theo chiều ngang (bỏ qua left/right)
  final bool isCenterHor;

  /// Hướng mở rộng menu
  final CyberActionDirection direction;

  /// Khoảng cách giữa các items
  final double spacing;

  /// Màu nền của main FAB
  final Color? mainButtonColor;

  /// Icon của main FAB
  final String? mainButtonIcon;

  /// Size của main FAB
  final double? mainButtonSize;

  /// Màu icon của main FAB
  final Color? mainIconColor;

  /// Animation duration (milliseconds)
  final int animationDuration;

  /// Có hiển thị backdrop khi menu mở không
  final bool showBackdrop;

  /// Màu của backdrop
  final Color? backdropColor;

  /// Có hiển thị background của container không
  final bool isShowBackgroundColor;

  /// Màu nền của container chứa items (mặc định frosted glass)
  final Color? backgroundColor;

  /// Opacity của background container (0.0 - 1.0) (mặc định 0.85)
  final double backgroundOpacity;

  /// Border radius của container (mặc định 12)
  final double borderRadius;

  /// Border width của container
  final double? containerBorderWidth;

  /// Border color của container
  final Color? containerBorderColor;

  /// Padding của container (mặc định 8)
  final EdgeInsets containerPadding;

  const CyberAction({
    super.key,
    required this.children,
    this.type = CyberActionType.autoShow,
    this.top,
    this.left,
    this.bottom,
    this.right,
    this.isCenterVer = false,
    this.isCenterHor = false,
    this.direction = CyberActionDirection.vertical,
    this.spacing = 6.0,
    this.mainButtonColor,
    this.mainButtonIcon,
    this.mainButtonSize = 56.0,
    this.mainIconColor,
    this.animationDuration = 300,
    this.showBackdrop = false,
    this.backdropColor,
    this.isShowBackgroundColor = true,
    this.backgroundColor,
    this.backgroundOpacity = 0.85,
    this.borderRadius = 12.0,
    this.containerBorderWidth,
    this.containerBorderColor,
    this.containerPadding = const EdgeInsets.all(8),
  });

  @override
  State<CyberAction> createState() => _CyberActionState();
}

class _CyberActionState extends State<CyberAction>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isExpanded = false;
  bool _isPinned = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.animationDuration),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Nếu là AlwaysShow thì mở menu luôn
    if (widget.type == CyberActionType.alwaysShow) {
      _isExpanded = true;
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (widget.type == CyberActionType.alwaysShow) return;

    setState(() {
      _isPinned = !_isPinned;
      _isExpanded = _isPinned;

      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _handleHoverEnter() {
    if (widget.type == CyberActionType.autoShow && !_isPinned) {
      setState(() {
        _isExpanded = true;
        _animationController.forward();
      });
    }
  }

  void _handleHoverExit() {
    if (widget.type == CyberActionType.autoShow && !_isPinned) {
      setState(() {
        _isExpanded = false;
        _animationController.reverse();
      });
    }
  }

  void _closeMenu() {
    if (widget.type == CyberActionType.autoShow) {
      setState(() {
        _isPinned = false;
        _isExpanded = false;
        _animationController.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lọc ra các items visible
    final visibleChildren = widget.children
        .where((item) => item.visible)
        .toList();

    if (visibleChildren.isEmpty) {
      return const SizedBox.shrink();
    }

    final isVertical = widget.direction == CyberActionDirection.vertical;
    final showMainButton = widget.type == CyberActionType.autoShow;

    // Tính toán alignment dựa trên isCenterVer và isCenterHor
    Alignment alignment = Alignment.center;
    double? finalTop = widget.top;
    double? finalLeft = widget.left;
    double? finalBottom = widget.bottom;
    double? finalRight = widget.right;

    if (widget.isCenterVer) {
      // Căn giữa theo chiều dọc
      finalTop = null;
      finalBottom = null;
      if (widget.isCenterHor) {
        // Cả 2 chiều đều center
        alignment = Alignment.center;
        finalLeft = null;
        finalRight = null;
      } else if (widget.left != null) {
        alignment = Alignment.centerLeft;
      } else if (widget.right != null) {
        alignment = Alignment.centerRight;
      } else {
        alignment = Alignment.center;
      }
    } else if (widget.isCenterHor) {
      // Chỉ căn giữa theo chiều ngang
      finalLeft = null;
      finalRight = null;
      if (widget.top != null) {
        alignment = Alignment.topCenter;
      } else if (widget.bottom != null) {
        alignment = Alignment.bottomCenter;
      } else {
        alignment = Alignment.center;
      }
    }

    return Stack(
      children: [
        // Backdrop nếu cần
        if (_isExpanded && widget.showBackdrop)
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeMenu,
              child: Container(
                color:
                    widget.backdropColor ?? Colors.black.withValues(alpha: 0.3),
              ),
            ),
          ),

        // Main menu - Use Align if centered, otherwise Positioned
        if (widget.isCenterVer || widget.isCenterHor)
          Align(
            alignment: alignment,
            child: Padding(
              padding: EdgeInsets.only(
                top: finalTop ?? 0,
                left: finalLeft ?? 0,
                bottom: finalBottom ?? 0,
                right: finalRight ?? 0,
              ),
              child: _buildMenuContent(
                isVertical,
                showMainButton,
                visibleChildren,
              ),
            ),
          )
        else
          Positioned(
            top: finalTop,
            left: finalLeft,
            bottom: finalBottom,
            right: finalRight,
            child: _buildMenuContent(
              isVertical,
              showMainButton,
              visibleChildren,
            ),
          ),
      ],
    );
  }

  /// Build menu content (extracted for reuse)
  Widget _buildMenuContent(
    bool isVertical,
    bool showMainButton,
    List<CyberButtonAction> visibleChildren,
  ) {
    return MouseRegion(
      onEnter: (_) => _handleHoverEnter(),
      onExit: (_) => _handleHoverExit(),
      child: isVertical
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Menu items vertical wrapped in container
                _buildItemsContainer(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (int i = 0; i < visibleChildren.length; i++)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: i < visibleChildren.length - 1
                                ? widget.spacing
                                : 0,
                          ),
                          child: _ActionMenuItem(
                            item: visibleChildren[i],
                            onTap: () {
                              visibleChildren[i].onclick?.call();
                              _closeMenu();
                            },
                          ),
                        ),
                    ],
                  ),
                ),

                // Spacing giữa items và main button
                if (_isExpanded && visibleChildren.isNotEmpty && showMainButton)
                  SizedBox(height: widget.spacing),

                // Main FAB button (chỉ hiện khi AutoShow)
                if (showMainButton) _buildMainButton(),
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Menu items horizontal wrapped in container
                _buildItemsContainer(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < visibleChildren.length; i++)
                        Padding(
                          padding: EdgeInsets.only(
                            right: i < visibleChildren.length - 1
                                ? widget.spacing
                                : 0,
                          ),
                          child: _ActionMenuItem(
                            item: visibleChildren[i],
                            onTap: () {
                              visibleChildren[i].onclick?.call();
                              _closeMenu();
                            },
                          ),
                        ),
                    ],
                  ),
                ),

                // Spacing giữa items và main button
                if (_isExpanded && visibleChildren.isNotEmpty && showMainButton)
                  SizedBox(width: widget.spacing),

                // Main FAB button (chỉ hiện khi AutoShow)
                if (showMainButton) _buildMainButton(),
              ],
            ),
    );
  }

  /// Wrap items trong container với background và border (frosted glass effect)
  Widget _buildItemsContainer({required Widget child}) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Transform.scale(
          scale: _animation.value,
          alignment: widget.direction == CyberActionDirection.vertical
              ? Alignment.bottomRight
              : Alignment.centerRight,
          child: Opacity(
            opacity: _animation.value,
            child: widget.isShowBackgroundColor
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: widget.containerPadding,
                        decoration: BoxDecoration(
                          color:
                              (widget.backgroundColor ??
                                      Colors.white.withValues(alpha: 0.1))
                                  .withValues(alpha: widget.backgroundOpacity),
                          borderRadius: BorderRadius.circular(
                            widget.borderRadius,
                          ),
                          border:
                              widget.containerBorderWidth != null &&
                                  widget.containerBorderWidth! > 0
                              ? Border.all(
                                  color:
                                      widget.containerBorderColor ??
                                      Colors.white.withValues(alpha: 0.3),
                                  width: widget.containerBorderWidth!,
                                )
                              : null,
                        ),
                        child: _buildScrollableChild(child),
                      ),
                    ),
                  )
                : _buildScrollableChild(child),
          ),
        );
      },
    );
  }

  /// Wrap child trong SingleChildScrollView với constraints
  Widget _buildScrollableChild(Widget child) {
    // Get screen size
    final screenSize = MediaQuery.of(context).size;

    // Calculate max size (70% of screen)
    final maxHeight = screenSize.height * 0.7;
    final maxWidth = screenSize.width * 0.7;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: widget.direction == CyberActionDirection.vertical
            ? maxHeight
            : double.infinity,
        maxWidth: widget.direction == CyberActionDirection.horizontal
            ? maxWidth
            : double.infinity,
      ),
      child: SingleChildScrollView(
        scrollDirection: widget.direction == CyberActionDirection.vertical
            ? Axis.vertical
            : Axis.horizontal,
        child: child,
      ),
    );
  }

  /// Build main FAB button
  Widget _buildMainButton() {
    final size = widget.mainButtonSize ?? 52.0;
    final iconSize = size * 0.5;

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(size / 2),
      color: widget.mainButtonColor ?? Theme.of(context).primaryColor,
      child: InkWell(
        onTap: widget.type == CyberActionType.autoShow ? _toggleMenu : null,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          child: AnimatedRotation(
            turns: _isExpanded ? 0.125 : 0,
            duration: Duration(milliseconds: widget.animationDuration),
            child: CyberLabel(
              text: widget.mainButtonIcon ?? "e5d4",
              isIcon: true,
              iconSize: iconSize,
              textcolor: widget.mainIconColor ?? Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget riêng cho mỗi action menu item
class _ActionMenuItem extends StatefulWidget {
  final CyberButtonAction item;
  final VoidCallback onTap;

  const _ActionMenuItem({required this.item, required this.onTap});

  @override
  State<_ActionMenuItem> createState() => _ActionMenuItemState();
}

class _ActionMenuItemState extends State<_ActionMenuItem> {
  bool _isHovered = false;

  // Check if running on mobile (not web)
  bool get _isMobile => !kIsWeb;

  @override
  Widget build(BuildContext context) {
    final iconSize = widget.item.iconSize ?? 20.0;
    final buttonSize = iconSize + 24.0;

    // Default background: Color.fromARGB(255, 247, 247, 247)
    final bgColor =
        widget.item.backgroundColor ?? const Color.fromARGB(255, 247, 247, 247);
    final bgOpacity = widget.item.backgroundOpacity ?? 0.95;

    // Trên mobile: dùng Tooltip thay vì MouseRegion
    if (_isMobile) {
      return _buildMobileVersion(buttonSize, iconSize, bgColor, bgOpacity);
    }

    // Trên desktop: dùng MouseRegion như cũ
    return _buildDesktopVersion(buttonSize, iconSize, bgColor, bgOpacity);
  }

  /// Build version cho mobile (với Tooltip)
  Widget _buildMobileVersion(
    double buttonSize,
    double iconSize,
    Color bgColor,
    double bgOpacity,
  ) {
    final iconButton = _buildIconButton(
      buttonSize,
      iconSize,
      bgColor,
      bgOpacity,
    );

    // Nếu showLabel = true: hiển thị label luôn theo position
    if (widget.item.showLabel) {
      return _buildWithLabel(iconButton);
    }

    // Nếu không: dùng Tooltip (long press để xem)
    return Tooltip(
      message: widget.item.label,
      waitDuration: const Duration(milliseconds: 500),
      child: iconButton,
    );
  }

  /// Build version cho desktop (với MouseRegion hover)
  Widget _buildDesktopVersion(
    double buttonSize,
    double iconSize,
    Color bgColor,
    double bgOpacity,
  ) {
    final iconButton = _buildIconButton(
      buttonSize,
      iconSize,
      bgColor,
      bgOpacity,
    );

    // Nếu showLabel = true: hiển thị label luôn (không cần hover)
    if (widget.item.showLabel) {
      return _buildWithLabel(iconButton);
    }

    // Nếu không: chỉ hiển thị khi hover
    return MouseRegion(
      onEnter: (event) {
        setState(() {
          _isHovered = true;
        });
      },
      onExit: (event) {
        setState(() {
          _isHovered = false;
        });
      },
      cursor: SystemMouseCursors.click,
      child: _isHovered ? _buildWithLabel(iconButton) : iconButton,
    );
  }

  /// Build icon + label theo position
  Widget _buildWithLabel(Widget iconButton) {
    final label = _buildLabel();

    switch (widget.item.labelPosition) {
      case LabelPosition.right:
        // Label bên PHẢI icon: icon → label
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [iconButton, label],
        );

      case LabelPosition.left:
        // Label bên TRÁI icon: label → icon
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [label, iconButton],
        );

      case LabelPosition.bottom:
        // Label bên DƯỚI icon
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [iconButton, const SizedBox(height: 4), label],
        );
    }
  }

  /// Build label widget
  Widget _buildLabel() {
    EdgeInsets margin;

    // Adjust margin based on position
    switch (widget.item.labelPosition) {
      case LabelPosition.right:
        // Label ở bên phải icon → margin left
        margin = const EdgeInsets.only(left: 3);
        break;
      case LabelPosition.left:
        // Label ở bên trái icon → margin right
        margin = const EdgeInsets.only(right: 3);
        break;
      case LabelPosition.bottom:
        // Label ở dưới icon → no horizontal margin
        margin = EdgeInsets.zero;
        break;
    }

    return Container(
      margin: margin,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      // decoration: BoxDecoration(
      //   color: Colors.white.withValues(alpha: 0.95),
      //   borderRadius: BorderRadius.circular(4),
      //   boxShadow: [
      //     BoxShadow(
      //       color: Colors.black.withValues(alpha: 0.1),
      //       blurRadius: 4,
      //       offset: const Offset(0, 2),
      //     ),
      //   ],
      // ),
      child: Text(
        widget.item.label,
        style:
            widget.item.styleLabel ??
            const TextStyle(
              color: Colors.grey,
              // fontSize: 14,
              // fontWeight: FontWeight.w500,
            ),
        overflow: TextOverflow.visible,
        softWrap: false,
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Build icon button
  Widget _buildIconButton(
    double buttonSize,
    double iconSize,
    Color bgColor,
    double bgOpacity,
  ) {
    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: bgOpacity),
        borderRadius: BorderRadius.circular(buttonSize / 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(buttonSize / 2),
          child: Center(
            child: CyberLabel(
              text: widget.item.icon,
              isIcon: true,
              iconSize: iconSize,
              textcolor:
                  widget.item.iconColor ??
                  widget.item.styleIcon?.color ??
                  Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

/// Extension để tạo CyberAction từ List<CyberButtonAction>
extension CyberActionExtension on List<CyberButtonAction> {
  /// Tạo CyberAction với các tham số tùy chỉnh
  Widget toCyberAction({
    CyberActionType type = CyberActionType.autoShow,
    double? top,
    double? left,
    double? bottom,
    double? right,
    bool isCenterVer = false,
    bool isCenterHor = false,
    CyberActionDirection direction = CyberActionDirection.vertical,
    double spacing = 6.0,
    Color? mainButtonColor,
    String? mainButtonIcon,
    double? mainButtonSize,
    Color? mainIconColor,
    int animationDuration = 300,
    bool showBackdrop = false,
    Color? backdropColor,
    bool isShowBackgroundColor = true,
    Color? backgroundColor,
    double backgroundOpacity = 0.85,
    double borderRadius = 12.0,
    double? containerBorderWidth,
    Color? containerBorderColor,
    EdgeInsets containerPadding = const EdgeInsets.all(8),
  }) {
    return CyberAction(
      children: this,
      type: type,
      top: top,
      left: left,
      bottom: bottom,
      right: right,
      isCenterVer: isCenterVer,
      isCenterHor: isCenterHor,
      direction: direction,
      spacing: spacing,
      mainButtonColor: mainButtonColor,
      mainButtonIcon: mainButtonIcon,
      mainButtonSize: mainButtonSize,
      mainIconColor: mainIconColor,
      animationDuration: animationDuration,
      showBackdrop: showBackdrop,
      backdropColor: backdropColor,
      isShowBackgroundColor: isShowBackgroundColor,
      backgroundColor: backgroundColor,
      backgroundOpacity: backgroundOpacity,
      borderRadius: borderRadius,
      containerBorderWidth: containerBorderWidth,
      containerBorderColor: containerBorderColor,
      containerPadding: containerPadding,
    );
  }
}
