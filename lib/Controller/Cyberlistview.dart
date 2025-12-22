import 'package:cyberframework/cyberframework.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

typedef FutureDataCallback =
    Future<CyberDataTable> Function(
      int pageIndex,
      int pageSize,
      String strSearch,
    );

/// Callback khi tap item
typedef ItemTapCallback = void Function(CyberDataRow row, int index);

/// Callback khi long press item
typedef ItemLongPressCallback = void Function(CyberDataRow row, int index);

/// Builder để build UI cho mỗi item
typedef ItemBuilder =
    Widget Function(BuildContext context, CyberDataRow row, int index);

/// Callback khi tap swipe action
typedef SwipeActionCallback =
    void Function(CyberDataRow swipeRow, CyberDataRow sourceRow, int index);

/// Callback khi tap menu item
typedef MenuItemTapCallback =
    void Function(CyberDataRow menuRow, CyberDataRow sourceRow, int index);

/// Callback khi tap toolbar action
typedef ToolbarActionCallback = void Function(CyberDataRow actionRow);

class CyberListView extends StatefulWidget {
  final CyberDataTable? dataSource;

  /// Hàm load dữ liệu - Dùng cho load đầu, load more, refresh, search
  final FutureDataCallback? onLoadData;

  /// Builder để tùy chỉnh giao diện row
  final ItemBuilder itemBuilder;

  /// Tự động navigate đến màn hình khi click vào item
  final bool isClickToScreen;

  /// Callback khi tap vào item
  final ItemTapCallback? onItemTap;

  /// Callback khi long press item
  final ItemLongPressCallback? onItemLongPress;

  /// Menu data (CyberDataTable) - Hiển thị khi long press
  final CyberDataTable? menuDataTable;

  /// Tự động navigate đến màn hình khi tap menu item
  final bool isMenuClickToScreen;

  /// Callback khi tap vào menu item
  final MenuItemTapCallback? onMenuItemTap;

  /// Swipe actions data (CyberDataTable)
  final CyberDataTable? dtSwipeActions;

  /// Tự động navigate đến màn hình khi tap swipe action
  final bool isSwipeActionClickToScreen;

  /// Callback khi tap vào swipe action
  final SwipeActionCallback? onSwipeActionTap;

  /// Toolbar actions data (CyberDataTable) - Hiển thị bên cạnh search box
  final CyberDataTable? dtToolbarActions;

  /// Tự động navigate đến màn hình khi tap toolbar action
  final bool isToolbarActionClickToScreen;

  /// Callback khi tap vào toolbar action
  final ToolbarActionCallback? onToolbarActionTap;

  /// Page size cho load more
  final int pageSize;

  /// Có hiển thị search box không
  final bool showSearchBox;

  /// Placeholder khi không có dữ liệu
  final Widget? emptyWidget;

  /// Loading indicator
  final Widget? loadingWidget;

  /// Separator giữa các item
  final Widget? separator;

  /// Padding cho ListView
  final EdgeInsets? padding;

  /// ScrollController tùy chỉnh
  final ScrollController? scrollController;

  /// Debounce time cho search (milliseconds)
  final int searchDebounceTime;

  const CyberListView({
    super.key,
    this.dataSource, // ✅ NEW: External datasource
    this.onLoadData, // ✅ Optional khi có dataSource
    required this.itemBuilder,
    this.isClickToScreen = false,
    this.onItemTap,
    this.onItemLongPress,
    this.menuDataTable,
    this.isMenuClickToScreen = false,
    this.onMenuItemTap,
    this.dtSwipeActions,
    this.isSwipeActionClickToScreen = false,
    this.onSwipeActionTap,
    this.dtToolbarActions,
    this.isToolbarActionClickToScreen = false,
    this.onToolbarActionTap,
    this.pageSize = 20,
    this.showSearchBox = false,
    this.emptyWidget,
    this.loadingWidget,
    this.separator,
    this.padding,
    this.scrollController,
    this.searchDebounceTime = 500,
  });

  @override
  State<CyberListView> createState() => _CyberListViewState();
}

class _CyberListViewState extends State<CyberListView> {
  late ScrollController _scrollController;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 0;
  String _currentSearchText = '';

  /// ✅ Working DataTable - Luôn point đến external dataSource nếu có
  CyberDataTable get _dataTable {
    return widget.dataSource ?? CyberDataTable(tableName: 'Empty');
  }

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);

    // ✅ Load initial data nếu có onLoadData
    if (widget.onLoadData != null && widget.dataSource == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadInitialData();
      });
    }
  }

  @override
  void didUpdateWidget(CyberListView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ✅ Rebuild khi dataSource thay đổi reference
    if (widget.dataSource != oldWidget.dataSource) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    _searchController.dispose();
    super.dispose();
  }

  /// Load dữ liệu ban đầu - Reset về page 0
  Future<void> _loadInitialData() async {
    if (widget.onLoadData == null) return;

    setState(() {
      _isLoading = true;
      _currentPage = 0;
      _hasMoreData = true;
    });

    try {
      final newDataTable = await widget.onLoadData!(
        _currentPage,
        widget.pageSize,
        _currentSearchText,
      );

      // ✅ Sync vào external dataSource
      if (widget.dataSource != null) {
        widget.dataSource!.clear();
        widget.dataSource!.loadDatafromTb(newDataTable);
      }

      setState(() {
        _hasMoreData = newDataTable.rowCount >= widget.pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Lỗi khi load dữ liệu: $e');
    }
  }

  /// Load more data - Tự động tăng pageIndex
  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMoreData || widget.onLoadData == null) return;

    setState(() => _isLoadingMore = true);

    try {
      _currentPage++;

      final moreDataTable = await widget.onLoadData!(
        _currentPage,
        widget.pageSize,
        _currentSearchText,
      );

      // ✅ Append vào external dataSource
      if (widget.dataSource != null) {
        for (var row in moreDataTable.rows) {
          widget.dataSource!.addRow(row.copy());
        }
      }

      setState(() {
        _hasMoreData = moreDataTable.rowCount >= widget.pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
        _currentPage--;
      });
      _showError('Lỗi khi load thêm dữ liệu: $e');
    }
  }

  /// Refresh - Reset về page 0
  Future<void> _refresh() async {
    if (_currentSearchText.isNotEmpty) {
      _searchController.clear();
      _currentSearchText = '';
    }

    await _loadInitialData();
  }

  /// Search - Reset về page 0, gọi lại onLoadData với strSearch mới
  void _onSearchChanged(String searchText) {
    _currentSearchText = searchText;
    _loadInitialData();
  }

  /// Scroll listener - Trigger load more
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      _loadMore();
    }
  }

  /// Show error
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  /// ✅ PUBLIC METHOD: Refresh từ bên ngoài
  Future<void> refresh() async {
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.showSearchBox) _buildSearchBar(),
        Expanded(
          child: _isLoading
              ? _buildLoading()
              : _dataTable.rowCount == 0
              ? _buildEmpty()
              : _buildList(),
        ),
      ],
    );
  }

  /// Build search bar với toolbar actions
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          // Search TextField
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                Future.delayed(
                  Duration(milliseconds: widget.searchDebounceTime),
                  () {
                    if (_searchController.text == value) {
                      _onSearchChanged(value);
                    }
                  },
                );
              },
            ),
          ),

          // Toolbar Actions
          if (widget.dtToolbarActions != null &&
              widget.dtToolbarActions!.rowCount > 0)
            ..._buildToolbarActions(),
        ],
      ),
    );
  }

  /// Build toolbar action buttons
  List<Widget> _buildToolbarActions() {
    if (widget.dtToolbarActions == null ||
        widget.dtToolbarActions!.rowCount == 0) {
      return [];
    }

    return widget.dtToolbarActions!.rows.map((actionRow) {
      final label = actionRow['bar'] as String? ?? '';
      final iconName = actionRow['icon'] as String? ?? '';
      final backColorHex = actionRow['backcolor'] as String? ?? '';
      final textColorHex = actionRow['textcolor'] as String? ?? '';
      final showLabel = actionRow['showlabel'] as bool? ?? false;

      final backgroundColor = _parseColor(backColorHex, Colors.blue);
      final foregroundColor = _parseColor(textColorHex, Colors.white);
      final icon = v_parseIcon(iconName);

      return Padding(
        padding: const EdgeInsets.only(left: 8),
        child: showLabel
            ? ElevatedButton.icon(
                onPressed: () => _handleToolbarActionTap(actionRow),
                icon: icon != null ? Icon(icon, size: 20) : const SizedBox(),
                label: Text(label),
                style: ElevatedButton.styleFrom(
                  backgroundColor: backgroundColor,
                  foregroundColor: foregroundColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              )
            : IconButton(
                onPressed: () => _handleToolbarActionTap(actionRow),
                icon: icon != null ? Icon(icon) : const Icon(Icons.more_horiz),
                tooltip: label,
                style: IconButton.styleFrom(
                  backgroundColor: backgroundColor,
                  foregroundColor: foregroundColor,
                ),
              ),
      );
    }).toList();
  }

  /// Handle toolbar action tap với auto navigation
  void _handleToolbarActionTap(CyberDataRow actionRow) {
    // Auto navigation nếu enabled
    if (widget.isToolbarActionClickToScreen) {
      actionRow.V_Call(context);
    }

    // Callback
    widget.onToolbarActionTap?.call(actionRow);
  }

  Widget _buildLoading() {
    return widget.loadingWidget ??
        const Center(child: CircularProgressIndicator());
  }

  Widget _buildEmpty() {
    return widget.emptyWidget ??
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.inbox, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _currentSearchText.isNotEmpty
                    ? 'Không tìm thấy kết quả cho "$_currentSearchText"'
                    : 'Không có dữ liệu',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: AnimatedBuilder(
        // ✅ Listen to external dataSource changes
        animation: _dataTable,
        builder: (context, child) {
          final rows = _dataTable.rows;

          return ListView.separated(
            controller: _scrollController,
            padding: widget.padding ?? const EdgeInsets.all(8),
            itemCount: rows.length + (_isLoadingMore ? 1 : 0),
            separatorBuilder: (context, index) =>
                Divider(height: 1, thickness: 1, color: Colors.grey[200]),
            itemBuilder: (context, index) {
              if (index >= rows.length) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final row = rows[index];

              if (widget.dtSwipeActions != null &&
                  widget.dtSwipeActions!.rowCount > 0) {
                return _buildSlidableItem(row, index);
              }

              return _buildItem(row, index);
            },
          );
        },
      ),
    );
  }

  Widget _buildItem(CyberDataRow row, int index) {
    return InkWell(
      onTap: widget.onItemTap != null ? () => _handleItemTap(row, index) : null,
      onLongPress: () => _handleItemLongPress(row, index),
      child: widget.itemBuilder(context, row, index),
    );
  }

  void _handleItemTap(CyberDataRow row, int index) {
    widget.onItemTap?.call(row, index);

    if (widget.isClickToScreen) {
      row.V_Call(context);
    }
  }

  Future<void> _handleItemLongPress(CyberDataRow row, int index) async {
    if (widget.menuDataTable != null && widget.menuDataTable!.rowCount > 0) {
      await _showBottomMenu(row, index);
      return;
    }

    widget.onItemLongPress?.call(row, index);
  }

  Future<void> _showBottomMenu(CyberDataRow row, int index) async {
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _MenuBottomSheet(
        menuTable: widget.menuDataTable!,
        sourceRow: row,
        sourceIndex: index,
        isMenuClickToScreen: widget.isMenuClickToScreen,
        onMenuItemTap: widget.onMenuItemTap,
      ),
    );
  }

  Widget _buildSlidableItem(CyberDataRow row, int index) {
    return Slidable(
      key: Key('item_${row.hashCode}_$index'),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio:
            (widget.dtSwipeActions!.rowCount * 80) /
            MediaQuery.of(context).size.width,
        children: _buildSwipeActions(row, index),
      ),
      child: InkWell(
        onTap: widget.onItemTap != null
            ? () => _handleItemTap(row, index)
            : null,
        onLongPress: () => _handleItemLongPress(row, index),
        child: widget.itemBuilder(context, row, index),
      ),
    );
  }

  List<Widget> _buildSwipeActions(CyberDataRow sourceRow, int sourceIndex) {
    if (widget.dtSwipeActions == null || widget.dtSwipeActions!.rowCount == 0) {
      return [];
    }

    return widget.dtSwipeActions!.rows.map((swipeRow) {
      final label = swipeRow['bar'] as String? ?? '';
      final iconName = swipeRow['icon'] as String? ?? '';
      final backColorHex = swipeRow['backcolor'] as String? ?? '';
      final textColorHex = swipeRow['textcolor'] as String? ?? '';

      final backgroundColor = _parseColor(backColorHex, Colors.blue);
      final foregroundColor = _parseColor(textColorHex, Colors.white);
      final icon = v_parseIcon(iconName);

      return CustomSlidableAction(
        onPressed: (context) {
          _handleSwipeActionTap(swipeRow, sourceRow, sourceIndex);
        },
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) Icon(icon, size: 24),
            if (icon != null) const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }).toList();
  }

  /// Handle swipe action tap với auto navigation
  void _handleSwipeActionTap(
    CyberDataRow swipeRow,
    CyberDataRow sourceRow,
    int sourceIndex,
  ) {
    // Auto navigation nếu enabled
    if (widget.isSwipeActionClickToScreen) {
      swipeRow.V_Call(context);
    }

    // Callback
    widget.onSwipeActionTap?.call(swipeRow, sourceRow, sourceIndex);
  }

  Color _parseColor(String hexString, Color defaultColor) {
    if (hexString.isEmpty) return defaultColor;

    try {
      String hex = hexString.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return defaultColor;
    }
  }

  // IconData? _parseIcon(String codePointStr) {
  //   try {
  //     codePointStr = codePointStr.trim();

  //     int codePoint;

  //     // Format: 0xe047 hoặc 0xE047
  //     if (codePointStr.toLowerCase().startsWith('0x')) {
  //       codePoint = int.parse(codePointStr.substring(2), radix: 16);
  //     }
  //     // Format: e047 (hex không prefix)
  //     else if (RegExp(r'^[a-fA-F0-9]+$').hasMatch(codePointStr)) {
  //       codePoint = int.parse(codePointStr, radix: 16);
  //     }
  //     // Format: 57415 (decimal)
  //     else {
  //       codePoint = int.parse(codePointStr);
  //     }

  //     return IconData(codePoint, fontFamily: 'MaterialIcons');
  //   } catch (e) {
  //     debugPrint('Error parsing icon code point "$codePointStr": $e');
  //     return null;
  //   }
  // }
  // IconData? _parseIcon(String iconName) {
  //   if (iconName.isEmpty) return null;

  //   final iconMap = {
  //     'edit': Icons.edit,
  //     'delete': Icons.delete,
  //     'info': Icons.info,
  //     'settings': Icons.settings,
  //     'person': Icons.person,
  //     'home': Icons.home,
  //     'add': Icons.add,
  //     'remove': Icons.remove,
  //     'share': Icons.share,
  //     'save': Icons.save,
  //     'search': Icons.search,
  //     'list': Icons.list,
  //     'grid': Icons.grid_view,
  //     'calendar': Icons.calendar_today,
  //     'clock': Icons.access_time,
  //     'location': Icons.location_on,
  //     'phone': Icons.phone,
  //     'email': Icons.email,
  //     'attach': Icons.attach_file,
  //     'image': Icons.image,
  //     'camera': Icons.camera_alt,
  //     'video': Icons.videocam,
  //     'mic': Icons.mic,
  //     'star': Icons.star,
  //     'favorite': Icons.favorite,
  //     'bookmark': Icons.bookmark,
  //     'shopping': Icons.shopping_cart,
  //     'payment': Icons.payment,
  //     'download': Icons.download,
  //     'upload': Icons.upload,
  //     'cloud': Icons.cloud,
  //     'lock': Icons.lock,
  //     'unlock': Icons.lock_open,
  //     'key': Icons.key,
  //     'visibility': Icons.visibility,
  //     'visibility_off': Icons.visibility_off,
  //     'check': Icons.check,
  //     'close': Icons.close,
  //     'arrow_back': Icons.arrow_back,
  //     'arrow_forward': Icons.arrow_forward,
  //     'arrow_up': Icons.arrow_upward,
  //     'arrow_down': Icons.arrow_downward,
  //     'menu': Icons.menu,
  //     'more': Icons.more_vert,
  //     'filter': Icons.filter_list,
  //     'sort': Icons.sort,
  //     'refresh': Icons.refresh,
  //     'sync': Icons.sync,
  //     'print': Icons.print,
  //     'qr': Icons.qr_code,
  //     'barcode': Icons.barcode_reader,
  //     'notification': Icons.notifications,
  //     'message': Icons.message,
  //     'chat': Icons.chat,
  //     'call': Icons.call,
  //     'folder': Icons.folder,
  //     'file': Icons.insert_drive_file,
  //     'document': Icons.description,
  //     'dashboard': Icons.dashboard,
  //     'analytics': Icons.analytics,
  //     'chart': Icons.bar_chart,
  //     'pie_chart': Icons.pie_chart,
  //     'trending_up': Icons.trending_up,
  //     'trending_down': Icons.trending_down,
  //   };

  //   return iconMap[iconName.toLowerCase()];
  // }
}

class _MenuBottomSheet extends StatelessWidget {
  final CyberDataTable menuTable;
  final CyberDataRow sourceRow;
  final int sourceIndex;
  final bool isMenuClickToScreen;
  final MenuItemTapCallback? onMenuItemTap;

  const _MenuBottomSheet({
    required this.menuTable,
    required this.sourceRow,
    required this.sourceIndex,
    required this.isMenuClickToScreen,
    this.onMenuItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      behavior: HitTestBehavior.opaque,
      child: DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return GestureDetector(
            onTap: () {},
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Chọn hành động',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
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
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: menuTable.rowCount,
                      itemBuilder: (context, index) {
                        final menuRow = menuTable.rows[index];
                        return _MenuItemTile(
                          menuRow: menuRow,
                          sourceRow: sourceRow,
                          sourceIndex: sourceIndex,
                          isMenuClickToScreen: isMenuClickToScreen,
                          onTap: () {
                            Navigator.pop(context);
                            _handleMenuItemTap(
                              context,
                              menuRow,
                              sourceRow,
                              sourceIndex,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Handle menu item tap với auto navigation
  void _handleMenuItemTap(
    BuildContext context,
    CyberDataRow menuRow,
    CyberDataRow sourceRow,
    int sourceIndex,
  ) {
    try {
      // Auto navigation nếu enabled
      if (isMenuClickToScreen) {
        final pageName = menuRow['pagename'] as String?;

        if (pageName == null || pageName.isEmpty) {
          debugPrint('Warning: pageName is empty');
        } else {
          menuRow.V_Call(context);
        }
      }

      // Callback
      onMenuItemTap?.call(menuRow, sourceRow, sourceIndex);
    } catch (e) {
      debugPrint('Error handling menu item tap: $e');
    }
  }
}

class _MenuItemTile extends StatelessWidget {
  final CyberDataRow menuRow;
  final CyberDataRow sourceRow;
  final int sourceIndex;
  final bool isMenuClickToScreen;
  final VoidCallback onTap;

  const _MenuItemTile({
    required this.menuRow,
    required this.sourceRow,
    required this.sourceIndex,
    required this.isMenuClickToScreen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bar = menuRow['bar'] as String? ?? '';
    final iconName = menuRow['icon'] as String? ?? '';
    final backColorHex = menuRow['backcolor'] as String? ?? '';
    final textColorHex = menuRow['textcolor'] as String? ?? '';

    final backColor = _parseColor(backColorHex, Colors.transparent);
    final textColor = _parseColor(textColorHex, Colors.black87);
    final icon = _parseIcon(iconName);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: backColor,
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
        ),
        child: Row(
          children: [
            if (icon != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: textColor, size: 24),
              ),
            if (icon != null) const SizedBox(width: 12),
            Expanded(
              child: Text(
                bar,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: textColor.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hexString, Color defaultColor) {
    if (hexString.isEmpty) return defaultColor;

    try {
      String hex = hexString.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      return Color(int.parse(hex, radix: 16));
    } catch (e) {
      return defaultColor;
    }
  }

  IconData? _parseIcon(String iconName) {
    if (iconName.isEmpty) return null;

    final iconMap = {
      'edit': Icons.edit,
      'delete': Icons.delete,
      'info': Icons.info,
      'settings': Icons.settings,
      'person': Icons.person,
    };

    return iconMap[iconName.toLowerCase()];
  }
}
