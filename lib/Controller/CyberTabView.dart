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
}

// ============================================================================
// WIDGET - CyberTabView
// ============================================================================

/// TabView với lazy loading và auto dispose ContentViews
///
/// Usage:
/// ```dart
/// CyberTabView(
///   tabs: [
///     CyberTab(label: "Tab 1", viewName: "view1"),
///     CyberTab(label: "Tab 2", viewName: "view2"),
///     CyberTab(label: "Tab 3", viewName: "view3"),
///   ],
///   initialIndex: 0,
///   backColorTab: Colors.grey[200],
///   textColorTab: Colors.black,
///   selectBackColorTab: Colors.blue,
///   selectTextColorTab: Colors.white,
/// )
/// ```
class CyberTabView extends StatefulWidget {
  /// Danh sách các tabs
  final List<CyberTab> tabs;

  /// Tab được chọn ban đầu (index)
  final int initialIndex;

  /// Màu nền tab thường
  final Color? backColorTab;

  /// Màu chữ tab thường
  final Color? textColorTab;

  /// Màu nền tab được chọn
  final Color? selectBackColorTab;

  /// Màu chữ tab được chọn
  final Color? selectTextColorTab;

  /// Màu indicator dưới tab
  final Color? indicatorColor;

  /// Chiều cao của tab bar
  final double? tabBarHeight;

  /// Enable scroll cho tab bar
  final bool isScrollable;

  /// Keep alive các tab đã load (không dispose khi switch)
  final bool keepAlive;

  /// Callback khi đổi tab
  final Function(int index)? onTabChanged;

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
  });

  @override
  State<CyberTabView> createState() => _CyberTabViewState();
}

class _CyberTabViewState extends State<CyberTabView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<int, Widget> _cachedViews = {};
  int _currentIndex = 0;

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

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;

    final newIndex = _tabController.index;
    if (newIndex != _currentIndex) {
      setState(() {
        // Dispose old view nếu không keepAlive
        if (!widget.keepAlive && _cachedViews.containsKey(_currentIndex)) {
          _cachedViews.remove(_currentIndex);
        }
        _currentIndex = newIndex;
      });

      widget.onTabChanged?.call(newIndex);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _cachedViews.clear();
    super.dispose();
  }

  Widget _buildTabContent(int index) {
    // Return cached view nếu có
    if (_cachedViews.containsKey(index)) {
      return _cachedViews[index]!;
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
      final errorWidget = Center(
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

      if (widget.keepAlive) {
        _cachedViews[index] = errorWidget;
      }
      return errorWidget;
    }

    // Cache view nếu keepAlive
    if (widget.keepAlive) {
      _cachedViews[index] = view;
    }

    return view;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Colors
    final backColorTab = widget.backColorTab ?? Colors.grey[200]!;
    final textColorTab = widget.textColorTab ?? Colors.black87;
    final selectBackColorTab = widget.selectBackColorTab ?? theme.primaryColor;
    final selectTextColorTab = widget.selectTextColorTab ?? Colors.white;
    final indicatorColor = widget.indicatorColor ?? theme.primaryColor;

    return Column(
      children: [
        // Tab Bar
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
            tabs: widget.tabs.map((tab) {
              final index = widget.tabs.indexOf(tab);
              final isSelected = index == _currentIndex;

              return Container(
                decoration: BoxDecoration(
                  color: isSelected ? selectBackColorTab : Colors.transparent,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Tab(
                  icon: tab.icon != null ? Icon(tab.icon, size: 20) : null,
                  text: tab.label,
                  height: widget.tabBarHeight ?? 48,
                ),
              );
            }).toList(),
          ),
        ),

        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: List.generate(widget.tabs.length, (index) {
              // Chỉ build view của tab đang active hoặc đã cache
              if (index == _currentIndex || _cachedViews.containsKey(index)) {
                return _buildTabContent(index);
              }
              // Placeholder cho các tab chưa load
              return const SizedBox.shrink();
            }),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// ADVANCED VERSION - CyberTabViewAdvanced
// ============================================================================

/// Advanced TabView với nhiều tùy chọn hơn
class CyberTabViewAdvanced extends StatefulWidget {
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

  // Advanced options
  final TabBarIndicatorSize? indicatorSize;
  final EdgeInsets? labelPadding;
  final EdgeInsets? indicatorPadding;
  final Decoration? indicator;
  final bool enableFeedback;
  final BorderRadius? tabBorderRadius;
  final double? tabSpacing;

  const CyberTabViewAdvanced({
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
  State<CyberTabViewAdvanced> createState() => _CyberTabViewAdvancedState();
}

class _CyberTabViewAdvancedState extends State<CyberTabViewAdvanced>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<int, Widget> _cachedViews = {};
  int _currentIndex = 0;

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

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;

    final newIndex = _tabController.index;
    if (newIndex != _currentIndex) {
      setState(() {
        if (!widget.keepAlive && _cachedViews.containsKey(_currentIndex)) {
          _cachedViews.remove(_currentIndex);
        }
        _currentIndex = newIndex;
      });

      widget.onTabChanged?.call(newIndex);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _cachedViews.clear();
    super.dispose();
  }

  Widget _buildTabContent(int index) {
    if (_cachedViews.containsKey(index)) {
      return _cachedViews[index]!;
    }

    final tab = widget.tabs[index];
    final view = V_getView(
      tab.viewName,
      cpName: tab.cpName,
      strParameter: tab.strParameter,
      objectData: tab.objectData,
    );

    if (view == null) {
      final errorWidget = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'View "${tab.viewName}" không tìm thấy',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      );

      if (widget.keepAlive) {
        _cachedViews[index] = errorWidget;
      }
      return errorWidget;
    }

    if (widget.keepAlive) {
      _cachedViews[index] = view;
    }

    return view;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final backColorTab = widget.backColorTab ?? Colors.grey[200]!;
    final textColorTab = widget.textColorTab ?? Colors.black87;
    final selectBackColorTab = widget.selectBackColorTab ?? theme.primaryColor;
    final selectTextColorTab = widget.selectTextColorTab ?? Colors.white;
    final indicatorColor = widget.indicatorColor ?? theme.primaryColor;

    return Column(
      children: [
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
            tabs: widget.tabs.map((tab) {
              final index = widget.tabs.indexOf(tab);
              final isSelected = index == _currentIndex;

              return Container(
                margin: EdgeInsets.symmetric(
                  horizontal: widget.tabSpacing ?? 4,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? selectBackColorTab : Colors.transparent,
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
            }).toList(),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: List.generate(widget.tabs.length, (index) {
              if (index == _currentIndex || _cachedViews.containsKey(index)) {
                return _buildTabContent(index);
              }
              return const SizedBox.shrink();
            }),
          ),
        ),
      ],
    );
  }
}
