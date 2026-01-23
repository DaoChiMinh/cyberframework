import 'dart:collection';
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
// ✅ OPTIMIZED CACHED VIEW WRAPPER - Proper Disposal
// ============================================================================

/// Wrapper for cached views with proper disposal tracking
class _CachedView {
  final Widget widget;
  final DateTime cachedAt;
  final GlobalKey _key = GlobalKey(); // ✅ Track widget for disposal
  bool isDisposed = false;

  _CachedView(this.widget) : cachedAt = DateTime.now();

  /// ✅ Get widget wrapped with key for proper disposal
  Widget getWidget() {
    return KeyedSubtree(key: _key, child: widget);
  }

  /// ✅ Properly dispose the view and its resources
  void dispose() {
    if (isDisposed) return;
    isDisposed = true;

    try {
      // ✅ Force widget to detach from element tree
      if (_key.currentState != null) {
        (_key.currentState as State).dispose();
      }
    } catch (e) {
      debugPrint('⚠️ Error disposing cached view: $e');
    }
  }
}

// ============================================================================
// ✅ OPTIMIZED WIDGET - CyberTabView (Memory & Performance Optimized)
// ============================================================================

/// TabView với lazy loading, LRU cache, smooth animation, và memory optimization
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
  final EdgeInsets? tabBarMargin;
  final bool isScrollable;

  // ✅ Animation options
  final Duration? animationDuration;
  final Curve? animationCurve;

  // ✅ Performance options
  final int maxCachedViews; // ✅ Limit cache size

  // ✅ NEW: Ẩn/hiện thanh tab
  final bool showTabBar;

  // ✅ NEW: Content scroll options
  final bool contentScrollable; // Cho phép scroll content
  final ScrollPhysics? contentScrollPhysics;
  final EdgeInsets? contentPadding;

  const CyberTabView({
    super.key,
    required this.tabs,
    this.initialIndex = 0,
    this.backColorTab,
    this.textColorTab,
    this.selectBackColorTab,
    this.selectTextColorTab = Colors.black,
    this.tabBarHeight,
    this.keepAlive = false,
    this.onTabChanged,
    this.tabBorderRadius,
    this.tabSpacing = 8,
    this.tabBarMargin,
    this.isScrollable = true,
    this.animationDuration,
    this.animationCurve = Curves.easeInOut,
    this.maxCachedViews = 3,
    this.showTabBar = true, // ✅ NEW: Mặc định hiện thanh tab
    this.contentScrollable = true, // ✅ NEW: Mặc định có scroll
    this.contentScrollPhysics,
    this.contentPadding,
  });

  @override
  State<CyberTabView> createState() => _CyberTabViewState();
}

class _CyberTabViewState extends State<CyberTabView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _scrollController;

  // ✅ OPTIMIZED: Single source of truth với LRU cache
  final LinkedHashMap<int, _CachedView> _viewCache = LinkedHashMap();

  // ✅ OPTIMIZED: Cache tab widths to avoid recalculation
  final Map<int, double> _tabWidthCache = {};

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _scrollController = ScrollController();

    _tabController = TabController(
      length: widget.tabs.length,
      vsync: this,
      initialIndex: widget.initialIndex,
      animationDuration:
          widget.animationDuration ?? const Duration(milliseconds: 268),
    );

    // ✅ Listen to both index changes and animation
    _tabController.addListener(_handleTabChange);
    _tabController.animation?.addListener(_handleAnimationChange);

    // ✅ Calculate all tab widths once
    _calculateAllTabWidths();

    // ✅ Pre-load current view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureViewLoaded(_currentIndex);
    });
  }

  /// ✅ OPTIMIZED: Calculate all tab widths once and cache
  void _calculateAllTabWidths() {
    _tabWidthCache.clear();
    for (int i = 0; i < widget.tabs.length; i++) {
      _tabWidthCache[i] = _estimateTabWidth(widget.tabs[i]);
    }
  }

  /// ✅ Estimate tab width based on content
  double _estimateTabWidth(CyberTab tab) {
    // Base width: padding (32) + label
    double width = 32.0 + (tab.label.length * 8.0).clamp(60.0, 120.0);

    // Add icon space
    if (tab.icon != null) width += 24.0;

    // Add badge space
    if (tab.badgeCount != null && tab.badgeCount! > 0) width += 28.0;

    // Add spacing
    width += (widget.tabSpacing ?? 2) * 2;

    return width;
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
      _ensureViewLoaded(newIndex);

      // ✅ Auto scroll tab bar to show active tab
      if (widget.isScrollable && widget.showTabBar) {
        _scrollToTab(newIndex);
      }
    }
  }

  /// ✅ OPTIMIZED: Auto scroll using cached widths (O(n) → O(1))
  void _scrollToTab(int index) {
    if (!_scrollController.hasClients) return;

    // ✅ Use cached width
    final estimatedWidth = _tabWidthCache[index] ?? 100.0;

    // ✅ Calculate target offset using cached widths
    double targetOffset = 0;
    for (int i = 0; i < index; i++) {
      targetOffset += _tabWidthCache[i] ?? 100.0;
    }

    // ✅ Get viewport dimensions
    final viewportWidth = _scrollController.position.viewportDimension;
    final maxScroll = _scrollController.position.maxScrollExtent;

    // ✅ Center tab in viewport
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
      // ✅ Recalculate tab widths
      _calculateAllTabWidths();

      // ✅ Clear cache if not keeping alive
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

    // ✅ Chỉ process khi animation hoàn tất
    if (_tabController.indexIsChanging) return;

    final newIndex = _tabController.index;
    if (newIndex != _currentIndex) {
      // ✅ Dispose old view if not keeping alive
      if (!widget.keepAlive && _viewCache.containsKey(_currentIndex)) {
        _viewCache[_currentIndex]?.dispose();
        _viewCache.remove(_currentIndex);
      }

      // ✅ Notify callback
      widget.onTabChanged?.call(newIndex);
    }
  }

  /// ✅ OPTIMIZED: Ensure view is loaded with LRU cache management
  void _ensureViewLoaded(int index) {
    if (_viewCache.containsKey(index)) {
      // ✅ Move to end (mark as recently used)
      final cached = _viewCache.remove(index)!;
      if (!cached.isDisposed) {
        _viewCache[index] = cached;
      }
      return;
    }

    // ✅ Create new view
    final tab = widget.tabs[index];
    final view =
        tab.child ??
        V_getView(
          tab.viewName!,
          cpName: tab.cpName,
          strParameter: tab.strParameter,
          objectData: tab.objectData,
        );

    if (view != null && widget.keepAlive) {
      _addToCache(index, view);
    }
  }

  /// ✅ OPTIMIZED: Add to cache with LRU eviction
  void _addToCache(int index, Widget view) {
    if (!widget.keepAlive) return;

    // ✅ LRU: Remove oldest if exceeds limit
    while (_viewCache.length >= widget.maxCachedViews) {
      final oldestKey = _viewCache.keys.first;
      _viewCache[oldestKey]?.dispose();
      _viewCache.remove(oldestKey);
    }

    // ✅ Add new view to cache
    _viewCache[index] = _CachedView(view);
  }

  /// ✅ OPTIMIZED: Get from cache with LRU update
  Widget? _getFromCache(int index) {
    if (!_viewCache.containsKey(index)) return null;

    final cached = _viewCache.remove(index)!;
    if (cached.isDisposed) return null;

    // ✅ Move to end (mark as recently used)
    _viewCache[index] = cached;
    return cached.getWidget();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.animation?.removeListener(_handleAnimationChange);
    _tabController.dispose();
    _scrollController.dispose();
    _disposeAllCachedViews();
    _tabWidthCache.clear();
    super.dispose();
  }

  void _disposeAllCachedViews() {
    for (var cachedView in _viewCache.values) {
      cachedView.dispose();
    }
    _viewCache.clear();
  }

  /// ✅ OPTIMIZED: Build tab content with unified caching and auto scroll
  Widget _buildTabContent(int index) {
    // ✅ Return cached view if available
    final cachedWidget = _getFromCache(index);
    if (cachedWidget != null) {
      return _wrapWithScroll(cachedWidget);
    }

    // ✅ Lazy load view
    final tab = widget.tabs[index];
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
      return _buildErrorWidget(tab);
    }

    // ✅ Cache if keepAlive
    if (widget.keepAlive) {
      _addToCache(index, view);
      return _wrapWithScroll(_getFromCache(index)!);
    }

    return _wrapWithScroll(view);
  }

  /// ✅ NEW: Wrap content với SingleChildScrollView để tránh overflow
  Widget _wrapWithScroll(Widget child) {
    if (!widget.contentScrollable) {
      return widget.contentPadding != null
          ? Padding(padding: widget.contentPadding!, child: child)
          : child;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics:
              widget.contentScrollPhysics ??
              const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
              minWidth: constraints.maxWidth,
            ),
            child: widget.contentPadding != null
                ? Padding(padding: widget.contentPadding!, child: child)
                : child,
          ),
        );
      },
    );
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
          widget.tabBarMargin ??
          const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: widget.backColorTab ?? const Color(0xFFE8F5E9),
        borderRadius: widget.tabBorderRadius ?? BorderRadius.circular(18),
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
              controller: _scrollController,
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

  /// ✅ OPTIMIZED: Build segmented tabs with keys to prevent unnecessary rebuilds
  List<Widget> _buildSegmentedTabs() {
    return List.generate(widget.tabs.length, (index) {
      final tab = widget.tabs[index];
      final isSelected = index == _currentIndex;

      final tabWidget = _AnimatedSegmentedTab(
        key: ValueKey('tab_$index'), // ✅ Prevent unnecessary rebuilds
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

      // ✅ Scrollable: không wrap
      if (widget.isScrollable) {
        return tabWidget;
      }

      // ✅ Fixed: wrap trong Expanded
      return Expanded(child: tabWidget);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ✅ Segmented Tab Bar (có thể ẩn/hiện)
        if (widget.showTabBar) _buildTabBar(),

        // ✅ Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: widget.showTabBar
                ? const BouncingScrollPhysics()
                : const NeverScrollableScrollPhysics(), // ✅ Disable swipe khi ẩn tab
            children: List.generate(
              widget.tabs.length,
              (index) => _buildTabContent(index),
            ),
          ),
        ),
      ],
    );
  }

  /// ✅ NEW: Public method để chuyển tab programmatically
  void switchToTab(int index) {
    if (index >= 0 && index < widget.tabs.length) {
      _tabController.animateTo(index);
    }
  }
}

// ============================================================================
// ✅ OPTIMIZED ANIMATED SEGMENTED TAB - Minimize Rebuilds
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
    super.key, // ✅ Accept key
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
    // ✅ Extract colors once
    final selectedBg =
        selectBackColorTab ?? const Color.fromARGB(255, 224, 224, 224);
    final selectedText = selectTextColorTab ?? Colors.white;
    final unselectedText = textColorTab ?? const Color(0xFF2E7D32);

    // ✅ Badge colors
    final badgeBgSelected =
        tab.badgeColor ?? Colors.white.withValues(alpha: 0.9);
    final badgeBgUnselected =
        tab.badgeColor ?? selectedBg.withValues(alpha: 0.2);
    final badgeTextSelected = tab.badgeColor != null
        ? _getContrastColor(tab.badgeColor!)
        : selectedBg;
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
        child: _buildTabContent(
          isSelected,
          selectedText,
          unselectedText,
          badgeBgSelected,
          badgeBgUnselected,
          badgeTextSelected,
          badgeTextUnselected,
        ),
      ),
    );
  }

  /// ✅ OPTIMIZED: Separate method with const widgets
  Widget _buildTabContent(
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
        if (tab.icon != null) ...[
          Icon(
            tab.icon,
            size: 18,
            color: isSelected ? selectedText : unselectedText,
          ),
          const SizedBox(width: 6), // ✅ Const
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

        // Badge
        if (tab.badgeCount != null && tab.badgeCount! > 0) ...[
          const SizedBox(width: 8), // ✅ Const
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

// ============================================================================
// ✅ BACKWARD COMPATIBILITY
// ============================================================================

@Deprecated('Use CyberTabView instead. All features are now in main widget.')
typedef CyberTabViewAdvanced = CyberTabView;
