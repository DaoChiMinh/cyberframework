import 'package:cyberframework/cyberframework.dart';
import 'package:flutter/material.dart';

/// Enum định nghĩa kiểu hiển thị của menu
enum CyberActionType {
  /// Menu luôn hiển thị
  alwaysShow,

  /// Menu tự động ẩn/hiện khi hover hoặc click
  autoShow,
}

/// Enum định nghĩa hướng mở rộng của menu
enum CyberActionDirection {
  /// Mở rộng theo chiều dọc (top to bottom)
  vertical,

  /// Mở rộng theo chiều ngang (left to right)
  horizontal,
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

  /// Màu nền của button
  final Color? backgroundColor;

  /// Màu icon (override styleIcon.color)
  final Color? iconColor;

  /// Size của icon
  final double? iconSize;

  /// Có hiển thị button này không (mặc định true)
  final bool visible;

  const CyberButtonAction({
    required this.label,
    required this.icon,
    this.onclick,
    this.styleLabel,
    this.styleIcon,
    this.backgroundColor,
    this.iconColor,
    this.iconSize,
    this.visible = true,
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

  const CyberAction({
    super.key,
    required this.children,
    this.type = CyberActionType.autoShow,
    this.top,
    this.left,
    this.bottom,
    this.right,
    this.direction = CyberActionDirection.vertical,
    this.spacing = 6,
    this.mainButtonColor,
    this.mainButtonIcon,
    this.mainButtonSize = 56.0,
    this.mainIconColor,
    this.animationDuration = 300,
    this.showBackdrop = false,
    this.backdropColor,
  });

  @override
  State<CyberAction> createState() => _CyberActionState();
}

class _CyberActionState extends State<CyberAction>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isExpanded = false;
  bool _isHovering = false;
  bool _isPinned = false; // Track xem menu có đang được pin (click) hay không
  int? _hoveredItemIndex; // Track item nào đang được hover

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

    // Nếu là AlwaysShow thì mở luôn
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
      _isPinned = !_isPinned; // Toggle pin state
      _isExpanded = _isPinned;

      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
        _hoveredItemIndex = null; // Reset hover state khi đóng menu
      }
    });
  }

  void _handleHoverEnter() {
    // Chỉ mở khi hover nếu chưa được pinned
    if (widget.type == CyberActionType.autoShow && !_isPinned && !_isExpanded) {
      setState(() {
        _isHovering = true;
        _isExpanded = true;
        _animationController.forward();
      });
    }
  }

  void _handleHoverExit() {
    // Chỉ đóng khi hover out nếu chưa được pinned
    if (widget.type == CyberActionType.autoShow && _isHovering && !_isPinned) {
      setState(() {
        _isHovering = false;
        _isExpanded = false;
        _animationController.reverse();
        _hoveredItemIndex = null; // Reset hover state
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

    return Stack(
      children: [
        // Backdrop nếu cần
        if (_isExpanded && widget.showBackdrop)
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                // Click backdrop để đóng menu
                if (_isPinned) {
                  _toggleMenu();
                }
              },
              child: Container(
                color:
                    widget.backdropColor ?? Colors.black.withValues(alpha: 0.3),
              ),
            ),
          ),

        // Main menu
        Positioned(
          top: widget.top,
          left: widget.left,
          bottom: widget.bottom,
          right: widget.right,
          child: MouseRegion(
            onEnter: (_) => _handleHoverEnter(),
            onExit: (_) => _handleHoverExit(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  widget.direction == CyberActionDirection.vertical
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                // Menu items
                if (widget.direction == CyberActionDirection.vertical)
                  ..._buildVerticalItems(visibleChildren)
                else
                  _buildHorizontalItems(visibleChildren),

                // Spacing giữa items và main button
                if (_isExpanded && visibleChildren.isNotEmpty)
                  SizedBox(height: widget.spacing),

                // Main FAB button
                _buildMainButton(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build các items theo chiều dọc
  List<Widget> _buildVerticalItems(List<CyberButtonAction> items) {
    return items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;

      return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final slideOffset =
              _animation.value * (items.length - index) * (widget.spacing + 48);

          return Transform.translate(
            offset: Offset(0, -slideOffset),
            child: Opacity(opacity: _animation.value, child: child),
          );
        },
        child: Padding(
          padding: EdgeInsets.only(bottom: widget.spacing),
          child: _buildMenuItem(item, index),
        ),
      );
    }).toList();
  }

  /// Build các items theo chiều ngang
  Widget _buildHorizontalItems(List<CyberButtonAction> items) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Padding(
                padding: EdgeInsets.only(right: widget.spacing),
                child: _buildMenuItem(item, index),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  /// Build một menu item với label hiển thị khi hover
  Widget _buildMenuItem(CyberButtonAction item, int index) {
    final iconSize = item.iconSize ?? 24.0;
    final buttonSize = iconSize + 24.0; // padding around icon
    final isHovered = _hoveredItemIndex == index;

    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _hoveredItemIndex = index;
        });
      },
      onExit: (_) {
        setState(() {
          if (_hoveredItemIndex == index) {
            _hoveredItemIndex = null;
          }
        });
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Label text (hiển thị bên trái icon khi hover)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: isHovered ? null : 0,
            padding: isHovered
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
                : EdgeInsets.zero,
            decoration: BoxDecoration(
              color: isHovered
                  ? Colors.white.withValues(alpha: 0.95)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              boxShadow: isHovered
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: isHovered ? 1.0 : 0.0,
              child: Text(
                item.label,
                style:
                    item.styleLabel ??
                    const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                overflow: TextOverflow.visible,
                softWrap: false,
              ),
            ),
          ),
          if (isHovered) const SizedBox(width: 8),
          // Icon button
          Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(buttonSize / 2),
            color: (item.backgroundColor ?? Theme.of(context).primaryColor)
                .withValues(alpha: 0.95), // Thêm opacity
            child: InkWell(
              onTap: () {
                item.onclick?.call();
                // Luôn đóng menu sau khi click item (cho cả pinned và unpinned)
                if (widget.type == CyberActionType.autoShow) {
                  if (_isPinned) {
                    _toggleMenu();
                  } else {
                    // Nếu menu đang mở bởi hover, đóng luôn
                    setState(() {
                      _isExpanded = false;
                      _animationController.reverse();
                      _hoveredItemIndex = null;
                    });
                  }
                }
              },
              borderRadius: BorderRadius.circular(buttonSize / 2),
              child: Container(
                width: buttonSize,
                height: buttonSize,
                alignment: Alignment.center,
                child: CyberLabel(
                  text: item.icon,
                  isIcon: true,
                  iconSize: iconSize,
                  textcolor:
                      item.iconColor ?? item.styleIcon?.color ?? Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build main FAB button
  Widget _buildMainButton() {
    final size = widget.mainButtonSize ?? 56.0;
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
            turns: _isExpanded ? 0.125 : 0, // Rotate 45 degrees khi mở
            duration: Duration(milliseconds: widget.animationDuration),
            child: CyberLabel(
              text: widget.mainButtonIcon ?? "e145", // default add icon
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

/// Extension để tạo CyberAction từ List<CyberButtonAction>
extension CyberActionExtension on List<CyberButtonAction> {
  /// Tạo CyberAction với các tham số tùy chỉnh
  Widget toCyberAction({
    CyberActionType type = CyberActionType.autoShow,
    double? top,
    double? left,
    double? bottom,
    double? right,
    CyberActionDirection direction = CyberActionDirection.vertical,
    double spacing = 12.0,
    Color? mainButtonColor,
    String? mainButtonIcon,
    double? mainButtonSize,
    Color? mainIconColor,
    int animationDuration = 300,
    bool showBackdrop = false,
    Color? backdropColor,
  }) {
    return CyberAction(
      children: this,
      type: type,
      top: top,
      left: left,
      bottom: bottom,
      right: right,
      direction: direction,
      spacing: spacing,
      mainButtonColor: mainButtonColor,
      mainButtonIcon: mainButtonIcon,
      mainButtonSize: mainButtonSize,
      mainIconColor: mainIconColor,
      animationDuration: animationDuration,
      showBackdrop: showBackdrop,
      backdropColor: backdropColor,
    );
  }
}
