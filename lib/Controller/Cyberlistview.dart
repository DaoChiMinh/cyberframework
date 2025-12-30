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

  /// Separator giữa các item (chỉ dùng khi columnCount = 1)
  final Widget? separator;

  /// Padding cho ListView/GridView
  final EdgeInsets? padding;

  /// ScrollController tùy chỉnh
  final ScrollController? scrollController;

  /// Debounce time cho search (milliseconds)
  final int searchDebounceTime;

  /// Số cột hiển thị (1 = ListView, >1 = GridView) - Không có hiệu lực khi horizontal = true
  final int columnCount;

  /// Khoảng cách ngang giữa các cột (chỉ dùng khi columnCount > 1)
  final double crossAxisSpacing;

  /// Khoảng cách dọc giữa các hàng (chỉ dùng khi columnCount > 1)
  final double mainAxisSpacing;

  /// Tỷ lệ width/height của item (chỉ dùng khi columnCount > 1 và autoItemHeight = false)
  final double childAspectRatio;

  /// Cuộn theo chiều ngang (horizontal = true thì columnCount không có hiệu lực)
  final bool horizontal;

  /// Tự động điều chỉnh chiều cao item theo nội dung (chỉ dùng khi columnCount > 1 và horizontal = false)
  final bool autoItemHeight;

  /// Chiều cao của ListView - Có thể là double hoặc "*" để tự động theo nội dung
  /// - null: Dùng Expanded (chiếm hết không gian còn lại)
  /// - "*": Tự động theo chiều cao nội dung (shrinkWrap)
  /// - double: Chiều cao cố định
  final dynamic height;

  /// Danh sách tên cột để tìm kiếm (chỉ dùng khi không có onLoadData)
  /// Khi có onLoadData, tìm kiếm sẽ gọi hàm onLoadData
  /// Khi không có onLoadData, tìm kiếm sẽ filter local data theo các cột này
  final List<String>? columnsFilter;

  const CyberListView({
    super.key,
    this.dataSource,
    this.onLoadData,
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
    this.columnCount = 1,
    this.crossAxisSpacing = 8.0,
    this.mainAxisSpacing = 8.0,
    this.childAspectRatio = 1.0,
    this.horizontal = false,
    this.autoItemHeight = false,
    this.height,
    this.columnsFilter,
  }) : assert(columnCount >= 1, 'columnCount phải >= 1');

  @override
  State<CyberListView> createState() => _CyberListViewState();
}

class _CyberListViewState extends State<CyberListView> {
  late ScrollController _scrollController;
  final TextEditingController _searchController = TextEditingController();
  late final ChangeNotifier _emptyNotifier = ChangeNotifier();
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 0;
  String _currentSearchText = '';

  /// ✅ Filtered data cho local search (khi không có onLoadData)
  CyberDataTable? _filteredDataTable;

  /// ✅ Working DataTable - Point đến filtered hoặc external dataSource
  CyberDataTable get _dataTable {
    // Nếu có onLoadData, luôn dùng external dataSource
    if (widget.onLoadData != null) {
      return widget.dataSource ?? CyberDataTable(tableName: 'Empty');
    }

    // Nếu không có onLoadData, dùng filtered data (nếu có) hoặc original data
    return _filteredDataTable ??
        widget.dataSource ??
        CyberDataTable(tableName: 'Empty');
  }

  /// ✅ Check xem có dùng shrinkWrap không (khi height = "*")
  bool get _useShrinkWrap => widget.height == "*";

  /// ✅ Get physics phù hợp
  ScrollPhysics? get _scrollPhysics {
    if (_useShrinkWrap) {
      return const NeverScrollableScrollPhysics();
    }
    return null; // Dùng default physics
  }

  @override
  void initState() {
    super.initState();
    if (!mounted) return;
    _scrollController = widget.scrollController ?? ScrollController();

    // Chỉ add listener khi không dùng shrinkWrap
    if (!_useShrinkWrap) {
      _scrollController.addListener(_onScroll);
    }

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
    if (!mounted) return;
    // ✅ Rebuild khi dataSource thay đổi reference
    if (widget.dataSource != oldWidget.dataSource) {
      // Reset filtered data khi dataSource mới
      _filteredDataTable = null;
      _currentSearchText = '';
      _searchController.clear();
      if (mounted) {
        setState(() {});
      }
    }

    // ✅ Update scroll listener nếu height thay đổi
    if (widget.height != oldWidget.height) {
      if (oldWidget.height == "*" && widget.height != "*") {
        _scrollController.addListener(_onScroll);
      } else if (oldWidget.height != "*" && widget.height == "*") {
        _scrollController.removeListener(_onScroll);
      }
    }
  }

  @override
  void dispose() {
    if (!mounted) return;
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    _searchController.dispose();
    _emptyNotifier.dispose();
    _filterDebounceTimer?.cancel();
    super.dispose();
  }

  /// Load dữ liệu ban đầu - Reset về page 0
  Future<void> _loadInitialData() async {
    if (!mounted) return;
    if (widget.onLoadData == null) return;
    if (mounted) {
      setState(() {
        _isLoading = true;
        _currentPage = 0;
        _hasMoreData = true;
      });
    }

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
      if (mounted) {
        setState(() {
          _hasMoreData = newDataTable.rowCount >= widget.pageSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _showError('Lỗi khi load dữ liệu: $e');
    }
  }

  /// Load more data - Tự động tăng pageIndex
  Future<void> _loadMore() async {
    if (!mounted) return;
    if (_isLoadingMore || !_hasMoreData || widget.onLoadData == null) return;
    if (mounted) {
      setState(() => _isLoadingMore = true);
    }
    try {
      final nextPage = _currentPage + 1;
      final moreDataTable = await widget.onLoadData!(
        _currentPage,
        widget.pageSize,
        _currentSearchText,
      );
      if (!mounted) return;
      _currentPage = nextPage;
      // ✅ Append vào external dataSource
      if (widget.dataSource != null) {
        for (var row in moreDataTable.rows) {
          widget.dataSource!.addRow(row.copy());
        }
      }
      if (mounted) {
        setState(() {
          _hasMoreData = moreDataTable.rowCount >= widget.pageSize;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _currentPage--;
        });
      }
      _showError('Lỗi khi load thêm dữ liệu: $e');
    }
  }

  /// Refresh - Reset về page 0
  Future<void> _refresh() async {
    if (!mounted) return;
    if (_currentSearchText.isNotEmpty) {
      _searchController.clear();
      _currentSearchText = '';

      // Reset filtered data nếu dùng local search
      if (widget.onLoadData == null) {
        if (mounted) {
          setState(() {
            _filteredDataTable = null;
          });
        }
        return;
      }
    }

    await _loadInitialData();
  }

  /// Search - Reset về page 0 hoặc filter local data
  void _onSearchChanged(String searchText) {
    if (!mounted) return;
    _currentSearchText = searchText;

    // ✅ Nếu có onLoadData, gọi API
    if (widget.onLoadData != null) {
      _loadInitialData();
      return;
    }

    // ✅ Nếu không có onLoadData, filter local data
    _filterLocalData(searchText);
  }

  Timer? _filterDebounceTimer;

  /// ✅ Filter dữ liệu local theo columnsFilter
  void _filterLocalData(String searchText) {
    if (!mounted) return;
    _filterDebounceTimer?.cancel();

    _filterDebounceTimer = Timer(
      Duration(milliseconds: widget.searchDebounceTime),
      () {
        if (!mounted) return;

        // Filter logic here
        final filtered = _performFilter(searchText);

        if (mounted) {
          setState(() {
            _filteredDataTable = filtered;
          });
        }
      },
    );
    // // Nếu không có dataSource hoặc không có columnsFilter, skip
    // if (widget.dataSource == null ||
    //     widget.columnsFilter == null ||
    //     widget.columnsFilter!.isEmpty) {
    //   setState(() {
    //     _filteredDataTable = null;
    //   });
    //   return;
    // }

    // // Nếu search text rỗng, reset về data gốc
    // if (searchText.trim().isEmpty) {
    //   setState(() {
    //     _filteredDataTable = null;
    //   });
    //   return;
    // }

    // // Filter data
    // final filtered = CyberDataTable(tableName: widget.dataSource!.tableName);
    // final lowerSearch = searchText.toLowerCase().trim();

    // for (var row in widget.dataSource!.rows) {
    //   bool matches = false;

    //   // Check từng cột trong columnsFilter
    //   for (var columnName in widget.columnsFilter!) {
    //     final value = row[columnName]?.toString().toLowerCase() ?? '';
    //     if (value.contains(lowerSearch)) {
    //       matches = true;
    //       break;
    //     }
    //   }

    //   if (matches) {
    //     filtered.addRow(row.copy());
    //   }
    // }

    // setState(() {
    //   _filteredDataTable = filtered;
    // });
  }

  CyberDataTable? _performFilter(String searchText) {
    // Move filter logic to separate method
    if (widget.dataSource == null ||
        widget.columnsFilter == null ||
        widget.columnsFilter!.isEmpty) {
      return null;
    }

    if (searchText.trim().isEmpty) {
      return null;
    }

    final filtered = CyberDataTable(tableName: widget.dataSource!.tableName);
    final lowerSearch = searchText.toLowerCase().trim();

    for (var row in widget.dataSource!.rows) {
      bool matches = false;
      for (var columnName in widget.columnsFilter!) {
        final value = row[columnName]?.toString().toLowerCase() ?? '';
        if (value.contains(lowerSearch)) {
          matches = true;
          break;
        }
      }
      if (matches) {
        filtered.addRow(row.copy());
      }
    }

    return filtered;
  }

  /// Scroll listener - Trigger load more
  void _onScroll() {
    if (!mounted) return;
    final position = _scrollController.position;
    final threshold = widget.horizontal
        ? position.maxScrollExtent * 0.9
        : position.maxScrollExtent * 0.9;

    if (position.pixels >= threshold) {
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
    if (!mounted) return;
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Build nội dung chính
    Widget content = Column(
      mainAxisSize: widget.height == "*" ? MainAxisSize.min : MainAxisSize.max,
      children: [
        if (widget.showSearchBox) _buildSearchBar(),
        _buildListViewContainer(),
      ],
    );

    // ✅ Xử lý height
    if (widget.height is double) {
      // Height cố định - wrap bằng SizedBox
      return SizedBox(height: widget.height as double, child: content);
    } else if (widget.height == "*") {
      // Auto height - trả về content trực tiếp (đã có MainAxisSize.min)
      return content;
    } else {
      // height = null - cần Expanded từ parent, nhưng trả về content để flexible
      return content;
    }
  }

  /// ✅ Build container cho ListView với height phù hợp
  Widget _buildListViewContainer() {
    final listViewContent = _isLoading
        ? _buildLoading()
        : _dataTable.rowCount == 0
        ? _buildEmpty()
        : widget.horizontal
        ? _buildHorizontalList()
        : widget.columnCount > 1
        ? _buildGridList()
        : _buildList();

    // Case 1: height = "*" -> Tự động theo nội dung (không dùng Expanded)
    if (widget.height == "*") {
      return listViewContent;
    }

    // Case 2: height = số cụ thể hoặc null -> Expanded để chiếm space còn lại
    return Expanded(child: listViewContent);
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

  /// Build ListView (columnCount = 1, vertical)
  Widget _buildList() {
    final listView = AnimatedBuilder(
      animation: widget.dataSource ?? _emptyNotifier,
      builder: (context, child) {
        final rows = _dataTable.rows;

        return ListView.separated(
          controller: _scrollController,
          padding: widget.padding ?? const EdgeInsets.all(8),
          itemCount: rows.length + (_isLoadingMore ? 1 : 0),
          shrinkWrap: _useShrinkWrap,
          physics: _scrollPhysics,
          separatorBuilder: (context, index) =>
              widget.separator ??
              Divider(height: 1, thickness: 1, color: Colors.grey[200]),
          itemBuilder: (context, index) {
            if (index >= rows.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final row = rows[index];

            // ✅ BUILD ITEM WITH KEY (giống horizontal list)
            final itemWidget =
                widget.dtSwipeActions != null &&
                    widget.dtSwipeActions!.rowCount > 0
                ? _buildSlidableItem(row, index)
                : _buildItem(row, index);

            // ✅ ADD KEY FOR BETTER PERFORMANCE
            return KeyedSubtree(key: ValueKey(row.hashCode), child: itemWidget);
          },
        );
      },
    );

    if (_useShrinkWrap) {
      return listView;
    }

    return RefreshIndicator(onRefresh: _refresh, child: listView);
  }

  /// Build Horizontal ListView
  Widget _buildHorizontalList() {
    return AnimatedBuilder(
      animation: widget.dataSource ?? _emptyNotifier,
      builder: (context, child) {
        final rows = _dataTable.rows;

        return ListView.separated(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: widget.padding ?? const EdgeInsets.all(8),
          itemCount: rows.length + (_isLoadingMore ? 1 : 0),
          shrinkWrap: _useShrinkWrap,
          physics: _scrollPhysics,
          separatorBuilder: (context, index) =>
              widget.separator ?? const SizedBox(width: 8),
          itemBuilder: (context, index) {
            if (index >= rows.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final row = rows[index];
            final itemWidget =
                widget.dtSwipeActions != null &&
                    widget.dtSwipeActions!.rowCount > 0
                ? _buildSlidableItem(row, index)
                : _buildItem(row, index);

            return KeyedSubtree(
              key: ValueKey(row.hashCode), // ✅ Unique key
              child: itemWidget,
            );
            // Note: Swipe actions không hoạt động tốt trong horizontal scroll
            // Nên chỉ dùng tap/long press
            //return _buildItem(row, index);
          },
        );
      },
    );
  }

  /// Build GridView (columnCount > 1, vertical)
  Widget _buildGridList() {
    final gridView = AnimatedBuilder(
      animation: widget.dataSource ?? _emptyNotifier,
      builder: (context, child) {
        final rows = _dataTable.rows;

        // ✅ Dùng auto height layout nếu enabled
        if (widget.autoItemHeight) {
          return _buildAutoHeightGrid(rows);
        }

        // ✅ Dùng GridView chuẩn với childAspectRatio
        final totalItems = rows.length + (_isLoadingMore ? 1 : 0);

        return GridView.builder(
          controller: _scrollController,
          padding: widget.padding ?? const EdgeInsets.all(8),
          shrinkWrap: _useShrinkWrap,
          physics: _scrollPhysics,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.columnCount,
            crossAxisSpacing: widget.crossAxisSpacing,
            mainAxisSpacing: widget.mainAxisSpacing,
            childAspectRatio: widget.childAspectRatio,
          ),
          itemCount: totalItems,
          itemBuilder: (context, index) {
            if (index >= rows.length) {
              return const Center(child: CircularProgressIndicator());
            }

            final row = rows[index];

            // Note: Swipe actions không hoạt động tốt trong GridView
            // Nên chỉ dùng tap/long press
            return _buildItem(row, index);
          },
        );
      },
    );

    // Chỉ wrap RefreshIndicator khi không dùng shrinkWrap
    if (_useShrinkWrap) {
      return gridView;
    }

    return RefreshIndicator(onRefresh: _refresh, child: gridView);
  }

  /// ✅ Build Grid với Auto Height - Dùng ListView + Row
  Widget _buildAutoHeightGrid(List<CyberDataRow> rows) {
    final rowCount = (rows.length / widget.columnCount).ceil();

    return ListView.separated(
      controller: _scrollController,
      padding: widget.padding ?? const EdgeInsets.all(8),
      itemCount: rowCount + (_isLoadingMore ? 1 : 0),
      shrinkWrap: _useShrinkWrap,
      physics: _scrollPhysics,
      separatorBuilder: (context, index) =>
          SizedBox(height: widget.mainAxisSpacing),
      itemBuilder: (context, rowIndex) {
        if (rowIndex >= rowCount) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final startIndex = rowIndex * widget.columnCount;
        final endIndex = (startIndex + widget.columnCount).clamp(
          0,
          rows.length,
        );
        final rowItems = rows.sublist(startIndex, endIndex);

        return _buildAutoHeightGridRow(rowItems, startIndex);
      },
    );
  }

  /// ✅ Build một row trong auto height grid
  Widget _buildAutoHeightGridRow(List<CyberDataRow> rowItems, int startIndex) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Render các items có data
        for (int i = 0; i < rowItems.length; i++) ...[
          Expanded(child: _buildItem(rowItems[i], startIndex + i)),
          if (i < rowItems.length - 1) SizedBox(width: widget.crossAxisSpacing),
        ],

        // Thêm empty space nếu row không đủ items
        for (int i = rowItems.length; i < widget.columnCount; i++) ...[
          if (i > 0) SizedBox(width: widget.crossAxisSpacing),
          const Expanded(child: SizedBox()),
        ],
      ],
    );
  }

  Widget _buildItem(CyberDataRow row, int index) {
    return InkWell(
      onTap: (widget.onItemTap != null || widget.isClickToScreen)
          ? () => _handleItemTap(row, index)
          : null,
      onLongPress: () => _handleItemLongPress(row, index),
      child: widget.itemBuilder(context, row, index),
    );
  }

  void _handleItemTap(CyberDataRow row, int index) {
    if (widget.onItemTap != null) {
      widget.onItemTap?.call(row, index);
      return;
    }

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
        onTap: (widget.onItemTap != null || widget.isClickToScreen)
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
          //debugPrint('Warning: pageName is empty');
        } else {
          menuRow.V_Call(context);
        }
      }

      // Callback
      onMenuItemTap?.call(menuRow, sourceRow, sourceIndex);
    } catch (e) {
      //debugPrint('Error handling menu item tap: $e');
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
    final iconName = menuRow['iconname'] as String? ?? '';
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
