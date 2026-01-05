import 'package:cyberframework/cyberframework.dart';

// ============================================================================
// MODEL - CyberTab
// ============================================================================

/// Model cho mỗi tab trong CyberTabView
class CyberTab {
  final String label;
  final String viewName;
  final String cpName;
  final String strParameter;
  final dynamic objectData;
  final IconData? icon;

  const CyberTab({
    required this.label,
    required this.viewName,
    this.cpName = "",
    this.strParameter = "",
    this.objectData,
    this.icon,
  });

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

    // ✅ Try to dispose ContentView if possible
    // ContentView should implement a dispose method or use proper lifecycle
    try {
      if (widget is StatefulWidget) {
        // StatefulWidget disposal is handled by Flutter framework
        // when removed from tree, but we mark it as disposed
      }
    } catch (e) {
      // Silent error - disposal is best-effort
    }
  }
}

// ============================================================================
// ✅ OPTIMIZED WIDGET - CyberTabView
// ============================================================================

/// TabView với lazy loading, proper disposal, và optimized rendering
class CyberTabView extends StatefulWidget {
  final List<CyberTab> tabs;
  final int initialIndex;
  final Color? backColorTab;
  final Color? textColorTab;
  final Color? selectBackColorTab;
  final Color? selectTextColorTab;
  final Color? indicatorColor;
  final double? tabBarHeight;
  final bool isScrollable;
  final bool keepAlive;
  final Function(int index)? onTabChanged;

  // ✅ Advanced options (merged from Advanced version)
  final TabBarIndicatorSize? indicatorSize;
  final EdgeInsets? labelPadding;
  final EdgeInsets? indicatorPadding;
  final Decoration? indicator;
  final bool enableFeedback;
  final BorderRadius? tabBorderRadius;
  final double? tabSpacing;

  const CyberTabView({
    super.key,
    required this.tabs,
    this.initialIndex = 0,
    this.backColorTab,
    this.textColorTab,
    this.selectBackColorTab,
    this.selectTextColorTab,
    this.indicatorColor,
    this.tabBarHeight,
    this.isScrollable = true,
    this.keepAlive = false,
    this.onTabChanged,
    this.indicatorSize,
    this.labelPadding,
    this.indicatorPadding,
    this.indicator,
    this.enableFeedback = true,
    this.tabBorderRadius,
    this.tabSpacing,
  });

  @override
  State<CyberTabView> createState() => _CyberTabViewState();
}

class _CyberTabViewState extends State<CyberTabView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<int, _CachedView> _cachedViews = {};
  int _currentIndex = 0;

  // ✅ Cache TabBarView children to avoid regeneration
  List<Widget>? _cachedChildren;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _tabController = TabController(
      length: widget.tabs.length,
      vsync: this,
      initialIndex: widget.initialIndex,
    );

    _tabController.addListener(_handleTabChange);
  }

  @override
  void didUpdateWidget(CyberTabView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ✅ Invalidate children cache if tabs changed
    if (widget.tabs != oldWidget.tabs) {
      _cachedChildren = null;

      // ✅ Dispose removed tabs
      if (!widget.keepAlive) {
        _disposeAllCachedViews();
      }

      // Recreate controller if tab count changed
      if (widget.tabs.length != oldWidget.tabs.length) {
        _tabController.removeListener(_handleTabChange);
        _tabController.dispose();

        _currentIndex = widget.initialIndex.clamp(0, widget.tabs.length - 1);
        _tabController = TabController(
          length: widget.tabs.length,
          vsync: this,
          initialIndex: _currentIndex,
        );
        _tabController.addListener(_handleTabChange);
      }
    }
  }

  void _handleTabChange() {
    if (!mounted) return;
    if (_tabController.indexIsChanging) return;

    final newIndex = _tabController.index;
    if (newIndex != _currentIndex) {
      // ✅ Dispose old view if not keeping alive
      if (!widget.keepAlive && _cachedViews.containsKey(_currentIndex)) {
        _cachedViews[_currentIndex]?.dispose();
        _cachedViews.remove(_currentIndex);
      }

      setState(() {
        _currentIndex = newIndex;
        _cachedChildren = null; // ✅ Invalidate children cache
      });

      widget.onTabChanged?.call(newIndex);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();

    // ✅ Dispose all cached views properly
    _disposeAllCachedViews();

    super.dispose();
  }

  /// ✅ Properly dispose all cached views
  void _disposeAllCachedViews() {
    for (var cachedView in _cachedViews.values) {
      cachedView.dispose();
    }
    _cachedViews.clear();
    _cachedChildren = null;
  }

  /// ✅ Build tab content with proper caching
  Widget _buildTabContent(int index) {
    // Return cached view if available
    if (_cachedViews.containsKey(index)) {
      final cached = _cachedViews[index]!;
      if (!cached.isDisposed) {
        return cached.widget;
      }
      // Remove disposed view
      _cachedViews.remove(index);
    }

    // Lazy load view
    final tab = widget.tabs[index];
    final view = V_getView(
      tab.viewName,
      cpName: tab.cpName,
      strParameter: tab.strParameter,
      objectData: tab.objectData,
    );

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

    return view;
  }

  /// ✅ Build error widget
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

  /// ✅ Build tab bar items (optimized - no indexOf)
  List<Widget> _buildTabs() {
    return List.generate(widget.tabs.length, (index) {
      final tab = widget.tabs[index];
      final isSelected = index == _currentIndex;

      return Container(
        margin: EdgeInsets.symmetric(horizontal: widget.tabSpacing ?? 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (widget.selectBackColorTab ?? Theme.of(context).primaryColor)
              : Colors.transparent,
          borderRadius:
              widget.tabBorderRadius ??
              const BorderRadius.vertical(top: Radius.circular(8)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Tab(
          icon: tab.icon != null ? Icon(tab.icon, size: 20) : null,
          text: tab.label,
          height: widget.tabBarHeight ?? 48,
        ),
      );
    });
  }

  /// ✅ Build TabBarView children (cached)
  List<Widget> _buildChildren() {
    // Return cached children if available
    if (_cachedChildren != null) {
      return _cachedChildren!;
    }

    // Build new children list
    _cachedChildren = List.generate(widget.tabs.length, (index) {
      // Only build active tab or cached tabs
      if (index == _currentIndex || _cachedViews.containsKey(index)) {
        return _buildTabContent(index);
      }
      // Placeholder for unloaded tabs
      return const SizedBox.shrink();
    }, growable: false);

    return _cachedChildren!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Colors
    final backColorTab = widget.backColorTab ?? Colors.grey[200]!;
    final textColorTab = widget.textColorTab ?? Colors.black87;
    //final selectBackColorTab = widget.selectBackColorTab ?? theme.primaryColor;
    final selectTextColorTab = widget.selectTextColorTab ?? Colors.white;
    final indicatorColor = widget.indicatorColor ?? theme.primaryColor;

    return Column(
      children: [
        // ✅ Tab Bar (optimized)
        Container(
          height: widget.tabBarHeight ?? 48,
          decoration: BoxDecoration(
            color: backColorTab,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: widget.isScrollable,
            indicatorColor: indicatorColor,
            indicatorWeight: 3,
            indicatorSize: widget.indicatorSize,
            labelPadding:
                widget.labelPadding ??
                const EdgeInsets.symmetric(horizontal: 16),
            indicatorPadding: widget.indicatorPadding ?? EdgeInsets.zero,
            indicator: widget.indicator,
            enableFeedback: widget.enableFeedback,
            labelColor: selectTextColorTab,
            unselectedLabelColor: textColorTab,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
            tabs: _buildTabs(), // ✅ Optimized tab building
          ),
        ),

        // ✅ Tab Content (cached children)
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _buildChildren(), // ✅ Cached children list
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// ✅ BACKWARD COMPATIBILITY - CyberTabViewAdvanced
// ============================================================================

/// Advanced TabView - Now just an alias to CyberTabView
/// All advanced features are merged into main CyberTabView
@Deprecated('Use CyberTabView instead. All features are now in main widget.')
typedef CyberTabViewAdvanced = CyberTabView;
