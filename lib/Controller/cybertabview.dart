import 'package:cyberframework/cyberframework.dart';

// ============================================================================
// MODEL - CyberTab
// ============================================================================

/// Model cho mỗi tab trong CyberTabView
class CyberTab {
  final String label;
  final String? viewName; // ✅ Optional nếu có child
  final String cpName;
  final String strParameter;
  final dynamic objectData;
  final IconData? icon;
  final int? badgeCount; // ✅ Badge số lượng
  final Color? badgeColor; // ✅ Màu badge
  final Widget? child; // ✅ View/Screen widget (thay thế viewName)

  const CyberTab({
    required this.label,
    this.viewName, // ✅ Optional
    this.cpName = "",
    this.strParameter = "",
    this.objectData,
    this.icon,
    this.badgeCount,
    this.badgeColor,
    this.child, // ✅ NEW: Direct widget view
  }) : assert(
         viewName != null || child != null,
         'Either viewName or child must be provided',
       );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CyberTab &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          viewName == other.viewName &&
          cpName == other.cpName &&
          strParameter == other.strParameter;

  @override
  int get hashCode =>
      label.hashCode ^
      viewName.hashCode ^
      cpName.hashCode ^
      strParameter.hashCode;
}

// ============================================================================
// ✅ CACHED VIEW WRAPPER - Proper Disposal
// ============================================================================

/// Wrapper for cached views with disposal tracking
class _CachedView {
  final Widget widget;
  final DateTime cachedAt;
  bool isDisposed = false;

  _CachedView(this.widget) : cachedAt = DateTime.now();

  /// Dispose the view if it's a StatefulWidget with disposable resources
  void dispose() {
    if (isDisposed) return;
    isDisposed = true;

    try {
      if (widget is StatefulWidget) {
        // StatefulWidget disposal is handled by Flutter framework
      }
    } catch (e) {
      // Silent error - disposal is best-effort
    }
  }
}

// ============================================================================
// ✅ OPTIMIZED WIDGET - CyberTabView (Smooth Animation)
// ============================================================================

/// TabView với lazy loading, smooth animation, và giao diện đẹp
class CyberTabView extends StatefulWidget {
  final List<CyberTab> tabs;
  final int initialIndex;
  final Color? backColorTab;
  final Color? textColorTab;
  final Color? selectBackColorTab;
  final Color? selectTextColorTab;
  final double? tabBarHeight;
  final bool keepAlive;
  final Function(int index)? onTabChanged;

  // ✅ Styling options
  final BorderRadius? tabBorderRadius;
  final double? tabSpacing;
  final EdgeInsets? tabBarMargin; // ✅ NEW: Control tab bar margin
  final bool isScrollable; // ✅ Enable scroll cho nhiều tabs

  // ✅ Animation options
  final Duration? animationDuration;
  final Curve? animationCurve;

  const CyberTabView({
    super.key,
    required this.tabs,
    this.initialIndex = 0,
    this.backColorTab,
    this.textColorTab,
    this.selectBackColorTab,
    this.selectTextColorTab,
    this.tabBarHeight,
    this.keepAlive = false,
    this.onTabChanged,
    this.tabBorderRadius,
    this.tabSpacing,
    this.tabBarMargin, // ✅ NEW
    this.isScrollable = false, // ✅ Default false cho segmented style
    this.animationDuration,
    this.animationCurve,
  });

  @override
  State<CyberTabView> createState() => _CyberTabViewState();
}

class _CyberTabViewState extends State<CyberTabView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController =
      ScrollController(); // ✅ Add scroll controller
  final Map<int, _CachedView> _cachedViews = {};
  int _currentIndex = 0;

  // ✅ Pre-build all views to avoid rebuild jank
  final Map<int, Widget> _prebuiltViews = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _tabController = TabController(
      length: widget.tabs.length,
      vsync: this,
      initialIndex: widget.initialIndex,
      animationDuration:
          widget.animationDuration ?? const Duration(milliseconds: 300),
    );

    // ✅ Listen to both index changes and animation
    _tabController.addListener(_handleTabChange);
    _tabController.animation?.addListener(_handleAnimationChange);

    // ✅ Pre-build current view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preloadView(_currentIndex);
    });
  }

  /// ✅ Handle animation changes during swipe
  void _handleAnimationChange() {
    if (!mounted) return;

    // ✅ Update tab bar position during swipe
    final animationValue =
        _tabController.animation?.value ?? _currentIndex.toDouble();
    final newIndex = animationValue.round();

    if (newIndex != _currentIndex &&
        newIndex >= 0 &&
        newIndex < widget.tabs.length) {
      setState(() {
        _currentIndex = newIndex;
      });
      _preloadView(newIndex);

      // ✅ Auto scroll tab bar để hiện tab active
      if (widget.isScrollable) {
        _scrollToTab(newIndex);
      }
    }
  }

  /// ✅ Auto scroll tab bar to show active tab
  void _scrollToTab(int index) {
    if (!_scrollController.hasClients) return;

    // ✅ Estimated tab width (với segmented style, tabs thường ~80-120px)
    // Tính dựa trên label length và badge
    final tab = widget.tabs[index];
    final hasIcon = tab.icon != null;
    final hasBadge = tab.badgeCount != null && tab.badgeCount! > 0;

    // Base width: padding (32) + label (~60-80)
    double estimatedWidth = 32.0 + (tab.label.length * 8.0).clamp(60.0, 120.0);
    if (hasIcon) estimatedWidth += 24.0; // Icon + spacing
    if (hasBadge) estimatedWidth += 28.0; // Badge + spacing

    // Add spacing
    estimatedWidth += (widget.tabSpacing ?? 2) * 2;

    // ✅ Calculate target offset
    double targetOffset = 0;
    for (int i = 0; i < index; i++) {
      final prevTab = widget.tabs[i];
      double prevWidth = 32.0 + (prevTab.label.length * 8.0).clamp(60.0, 120.0);
      if (prevTab.icon != null) prevWidth += 24.0;
      if (prevTab.badgeCount != null && prevTab.badgeCount! > 0)
        prevWidth += 28.0;
      prevWidth += (widget.tabSpacing ?? 2) * 2;
      targetOffset += prevWidth;
    }

    // ✅ Get viewport width
    final viewportWidth = _scrollController.position.viewportDimension;
    final maxScroll = _scrollController.position.maxScrollExtent;

    // ✅ Center tab in viewport (nếu có thể)
    final centeredOffset =
        (targetOffset - viewportWidth / 2 + estimatedWidth / 2).clamp(
          0.0,
          maxScroll,
        );

    // ✅ Smooth scroll
    _scrollController.animateTo(
      centeredOffset,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  void didUpdateWidget(CyberTabView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.tabs != oldWidget.tabs) {
      _prebuiltViews.clear();

      if (!widget.keepAlive) {
        _disposeAllCachedViews();
      }

      if (widget.tabs.length != oldWidget.tabs.length) {
        // ✅ Cleanup old listeners
        _tabController.removeListener(_handleTabChange);
        _tabController.animation?.removeListener(_handleAnimationChange);
        _tabController.dispose();

        _currentIndex = widget.initialIndex.clamp(0, widget.tabs.length - 1);
        _tabController = TabController(
          length: widget.tabs.length,
          vsync: this,
          initialIndex: _currentIndex,
          animationDuration:
              widget.animationDuration ?? const Duration(milliseconds: 300),
        );

        // ✅ Add new listeners
        _tabController.addListener(_handleTabChange);
        _tabController.animation?.addListener(_handleAnimationChange);
      }
    }
  }

  void _handleTabChange() {
    if (!mounted) return;

    // ✅ Chỉ process khi animation hoàn tất (để call callback)
    if (_tabController.indexIsChanging) return;

    final newIndex = _tabController.index;
    if (newIndex != _currentIndex) {
      // ✅ Dispose old view if not keeping alive
      if (!widget.keepAlive && _cachedViews.containsKey(_currentIndex)) {
        _cachedViews[_currentIndex]?.dispose();
        _cachedViews.remove(_currentIndex);
      }

      // ✅ Notify callback chỉ khi animation hoàn tất
      widget.onTabChanged?.call(newIndex);
    }
  }

  /// ✅ Pre-load view to prevent jank
  void _preloadView(int index) {
    if (_prebuiltViews.containsKey(index)) return;

    final tab = widget.tabs[index];

    // ✅ Nếu có child widget, dùng child
    // ✅ Nếu không có, dùng V_getView với viewName
    final view =
        tab.child ??
        V_getView(
          tab.viewName!,
          cpName: tab.cpName,
          strParameter: tab.strParameter,
          objectData: tab.objectData,
        );

    if (view != null) {
      setState(() {
        _prebuiltViews[index] = view;
        if (widget.keepAlive) {
          _cachedViews[index] = _CachedView(view);
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.animation?.removeListener(_handleAnimationChange);
    _tabController.dispose();
    _scrollController.dispose(); // ✅ Dispose scroll controller
    _disposeAllCachedViews();
    _prebuiltViews.clear();
    super.dispose();
  }

  void _disposeAllCachedViews() {
    for (var cachedView in _cachedViews.values) {
      cachedView.dispose();
    }
    _cachedViews.clear();
  }

  /// ✅ Build tab content with proper caching
  Widget _buildTabContent(int index) {
    // Return pre-built view
    if (_prebuiltViews.containsKey(index)) {
      return _prebuiltViews[index]!;
    }

    // Return cached view if available
    if (_cachedViews.containsKey(index)) {
      final cached = _cachedViews[index]!;
      if (!cached.isDisposed) {
        return cached.widget;
      }
      _cachedViews.remove(index);
    }

    // ✅ FIX: Lazy load view - Check child first, then V_getView
    final tab = widget.tabs[index];

    // Nếu có child widget, dùng child
    // Nếu không có child, dùng V_getView với viewName
    final view =
        tab.child ??
        (tab.viewName != null
            ? V_getView(
                tab.viewName!,
                cpName: tab.cpName,
                strParameter: tab.strParameter,
                objectData: tab.objectData,
              )
            : null);

    if (view == null) {
      final errorWidget = _buildErrorWidget(tab);
      if (widget.keepAlive) {
        _cachedViews[index] = _CachedView(errorWidget);
      }
      return errorWidget;
    }

    // Cache view if keepAlive
    if (widget.keepAlive) {
      _cachedViews[index] = _CachedView(view);
    }

    _prebuiltViews[index] = view;
    return view;
  }

  Widget _buildErrorWidget(CyberTab tab) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'View "${tab.viewName}" không tìm thấy',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Tab: ${tab.label}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  /// ✅ Build segmented tab bar (pill style)
  Widget _buildTabBar() {
    final container = Container(
      margin:
          widget.tabBarMargin ?? const EdgeInsets.all(8), // ✅ Use tabBarMargin
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: widget.backColorTab ?? const Color(0xFFE8F5E9),
        borderRadius: widget.tabBorderRadius ?? BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: widget.isScrollable
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              controller: _scrollController, // ✅ Attach controller
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: _buildSegmentedTabs(),
              ),
            )
          : Row(children: _buildSegmentedTabs()),
    );

    return widget.tabBarHeight != null
        ? SizedBox(height: widget.tabBarHeight, child: container)
        : container;
  }

  /// ✅ Build segmented tabs
  List<Widget> _buildSegmentedTabs() {
    return List.generate(widget.tabs.length, (index) {
      final tab = widget.tabs[index];
      final isSelected = index == _currentIndex;

      final tabWidget = _AnimatedSegmentedTab(
        isSelected: isSelected,
        tab: tab,
        selectBackColorTab: widget.selectBackColorTab,
        selectTextColorTab: widget.selectTextColorTab,
        textColorTab: widget.textColorTab,
        tabSpacing: widget.tabSpacing,
        animationDuration:
            widget.animationDuration ?? const Duration(milliseconds: 250),
        animationCurve: widget.animationCurve ?? Curves.easeInOut,
        onTap: () => _tabController.animateTo(index),
      );

      // ✅ Scrollable: không wrap, để tự sizing
      if (widget.isScrollable) {
        return tabWidget;
      }

      // ✅ Fixed: wrap trong Expanded để chia đều
      return Expanded(child: tabWidget);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ✅ Segmented Tab Bar (pill style)
        _buildTabBar(),

        // ✅ Tab Content (smooth transition)
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const BouncingScrollPhysics(),
            children: List.generate(
              widget.tabs.length,
              (index) => _buildTabContent(index),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// ✅ ANIMATED SEGMENTED TAB - Pill style với nền chung
// ============================================================================

class _AnimatedSegmentedTab extends StatelessWidget {
  final bool isSelected;
  final CyberTab tab;
  final Color? selectBackColorTab;
  final Color? selectTextColorTab;
  final Color? textColorTab;
  final double? tabSpacing;
  final Duration animationDuration;
  final Curve animationCurve;
  final VoidCallback onTap;

  const _AnimatedSegmentedTab({
    required this.isSelected,
    required this.tab,
    this.selectBackColorTab,
    this.selectTextColorTab,
    this.textColorTab,
    this.tabSpacing,
    required this.animationDuration,
    required this.animationCurve,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Colors cho segmented style
    final selectedBg = selectBackColorTab ?? const Color(0xFF4CAF50);
    final selectedText = selectTextColorTab ?? Colors.white;
    final unselectedText = textColorTab ?? const Color(0xFF2E7D32);

    // ✅ Badge color từ tab hoặc default
    final badgeBgSelected =
        tab.badgeColor ?? Colors.white.withValues(alpha: 0.9);
    final badgeBgUnselected =
        tab.badgeColor ?? selectedBg.withValues(alpha: 0.2);
    final badgeTextSelected = tab.badgeColor != null
        ? _getContrastColor(tab.badgeColor!) // Contrast với custom color
        : selectedBg; // Default: primary color
    final badgeTextUnselected = tab.badgeColor != null
        ? _getContrastColor(tab.badgeColor!)
        : unselectedText;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: animationDuration,
        curve: animationCurve,
        margin: EdgeInsets.symmetric(horizontal: tabSpacing ?? 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: const BoxConstraints(minHeight: 40),
        decoration: BoxDecoration(
          // ✅ Tab active: màu nổi bật + shadow
          // ✅ Tab inactive: trong suốt
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon (if exists)
            if (tab.icon != null) ...[
              Icon(
                tab.icon,
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
                  tab.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            // Badge với badgeColor tùy chỉnh
            if (tab.badgeCount != null && tab.badgeCount! > 0) ...[
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
                    tab.badgeCount.toString(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? badgeTextSelected
                          : badgeTextUnselected,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// ✅ Get contrasting text color for badge
  Color _getContrastColor(Color backgroundColor) {
    // Calculate relative luminance
    final luminance = backgroundColor.computeLuminance();
    // Return black or white based on luminance
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

// ============================================================================
// ✅ BACKWARD COMPATIBILITY
// ============================================================================

@Deprecated('Use CyberTabView instead. All features are now in main widget.')
typedef CyberTabViewAdvanced = CyberTabView;
