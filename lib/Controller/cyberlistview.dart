import 'package:cyberframework/cyberframework.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter/cupertino.dart';

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

/// Callback khi xóa item - trả về true nếu xóa thành công, false nếu không xóa
typedef DeleteCallback = Future<bool> Function(CyberDataRow row, int index);

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

  /// Bật tính năng xóa bằng swipe
  final bool isDelete;

  /// Callback khi xóa item - trả về true để xóa, false để hủy
  final DeleteCallback? onDelete;

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
  final Object? refreshKey;

  /// Border radius cho từng item
  final BorderRadius? itemBorderRadius;

  /// Background color cho từng item
  final Color? itemBackgroundColor;

  /// 🎯 Số lượng items tối đa giữ trong memory
  /// - 0 = không giới hạn (để tránh OutOfMemory, nên set > 0)
  /// - > 0 = giới hạn số items, tự động remove old items khi vượt quá
  /// Default: 500 (khuyến nghị cho mobile)
  final int maxItemsInMemory;

  /// 🎯 Chiều cao ước tính của mỗi item (dùng để optimize scroll performance)
  /// Nếu null, Flutter sẽ tự tính toán (có thể chậm hơn)
  final double? estimatedItemHeight;

  // ============================================================================
  // CYBER ACTION PROPERTIES
  // ============================================================================

  /// Danh sách các CyberButtonAction để hiển thị trong CyberAction
  final List<CyberButtonAction>? cyberActions;

  /// Kiểu hiển thị CyberAction
  final CyberActionType cyberActionType;

  /// Vị trí top của CyberAction
  final double? cyberActionTop;

  /// Vị trí left của CyberAction
  final double? cyberActionLeft;

  /// Vị trí bottom của CyberAction
  final double? cyberActionBottom;

  /// Vị trí right của CyberAction
  final double? cyberActionRight;

  /// Căn giữa theo chiều dọc
  final bool cyberActionCenterVer;

  /// Căn giữa theo chiều ngang
  final bool cyberActionCenterHor;

  /// Hướng mở rộng của CyberAction
  final CyberActionDirection cyberActionDirection;

  /// Khoảng cách giữa các action items
  final double cyberActionSpacing;

  /// Màu nền của main button
  final Color? cyberActionMainButtonColor;

  /// Icon của main button
  final String? cyberActionMainButtonIcon;

  /// Size của main button
  final double? cyberActionMainButtonSize;

  /// Màu icon của main button
  final Color? cyberActionMainIconColor;

  /// Animation duration (milliseconds)
  final int cyberActionAnimationDuration;

  /// Hiển thị backdrop khi menu mở
  final bool cyberActionShowBackdrop;

  /// Màu backdrop
  final Color? cyberActionBackdropColor;

  /// Hiển thị background container
  final bool cyberActionShowBackground;

  /// Màu nền container
  final Color? cyberActionBackgroundColor;

  /// Opacity của background container
  final double cyberActionBackgroundOpacity;

  /// Border radius của container
  final double cyberActionBorderRadius;

  /// Border width của container
  final double? cyberActionBorderWidth;

  /// Border color của container
  final Color? cyberActionBorderColor;

  /// Padding của container
  final EdgeInsets cyberActionPadding;

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
    this.isDelete = false,
    this.onDelete,
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
    this.refreshKey,
    this.itemBorderRadius,
    this.itemBackgroundColor,
    this.maxItemsInMemory = 500,
    this.estimatedItemHeight,
    // CyberAction properties
    this.cyberActions,
    this.cyberActionType = CyberActionType.autoShow,
    this.cyberActionTop,
    this.cyberActionLeft,
    this.cyberActionBottom = 16.0,
    this.cyberActionRight = 16.0,
    this.cyberActionCenterVer = false,
    this.cyberActionCenterHor = false,
    this.cyberActionDirection = CyberActionDirection.vertical,
    this.cyberActionSpacing = 18,
    this.cyberActionMainButtonColor,
    this.cyberActionMainButtonIcon,
    this.cyberActionMainButtonSize = 56.0,
    this.cyberActionMainIconColor,
    this.cyberActionAnimationDuration = 300,
    this.cyberActionShowBackdrop = false,
    this.cyberActionBackdropColor,
    this.cyberActionShowBackground = true,
    this.cyberActionBackgroundColor,
    this.cyberActionBackgroundOpacity = 0.85,
    this.cyberActionBorderRadius = 18.0,
    this.cyberActionBorderWidth,
    this.cyberActionBorderColor,
    this.cyberActionPadding = const EdgeInsets.symmetric(
      horizontal: 26,
      vertical: 6,
    ),
  }) : assert(columnCount >= 1, 'columnCount phải >= 1');

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

  /// 🎯 OPTIMIZATION: Version counters thay vì hashCode
  int _dataSourceVersion = 0;
  int _filterVersion = 0;

  /// ✅ Filtered indices thay vì filtered data table
  List<int>? _filteredIndices;

  /// 🎯 OPTIMIZATION: Cache working rows với size limit
  List<CyberDataRow>? _cachedWorkingRows;
  int _cachedDataSourceVersion = -1;
  int _cachedFilterVersion = -1;

  /// 🎯 NEW: Search haystack cache để giảm garbage collection
  final Map<int, String> _searchHaystackCache = {};

  /// ✅ Timer cho search debounce
  Timer? _searchDebounceTimer;

  /// 🎯 OPTIMIZATION: Working rows với cache size limit
  List<CyberDataRow> get _workingRows {
    // Check cache với version counters
    if (_cachedWorkingRows != null &&
        _cachedDataSourceVersion == _dataSourceVersion &&
        _cachedFilterVersion == _filterVersion) {
      return _cachedWorkingRows!;
    }

    // Rebuild cache
    List<CyberDataRow> result;

    if (widget.onLoadData != null) {
      result = widget.dataSource?.rows ?? [];
    } else if (_filteredIndices != null && widget.dataSource != null) {
      result = _filteredIndices!
          .map((i) => widget.dataSource!.rows[i])
          .toList(growable: false);
    } else {
      result = widget.dataSource?.rows ?? [];
    }

    // 🎯 OPTIMIZATION: Chỉ cache nếu list không quá lớn (< 1000 items)
    if (result.length < 1000) {
      _cachedWorkingRows = result;
      _cachedDataSourceVersion = _dataSourceVersion;
      _cachedFilterVersion = _filterVersion;
    } else {
      // Không cache list quá lớn để tránh tốn RAM
      _cachedWorkingRows = null;
    }

    return result;
  }

  /// 🎯 OPTIMIZATION: Increment version counters
  void _incrementDataVersion() {
    _dataSourceVersion++;
  }

  void _incrementFilterVersion() {
    _filterVersion++;
  }

  /// ✅ Invalidate cache
  void _invalidateCache() {
    _cachedWorkingRows = null;
    _cachedDataSourceVersion = -1;
    _cachedFilterVersion = -1;
  }

  /// 🎯 NEW: Clear search haystack cache
  void _clearSearchCache() {
    _searchHaystackCache.clear();
  }

  /// 🎯 NEW: Get search haystack for a row (cached)
  String _getSearchHaystack(CyberDataRow row) {
    if (widget.columnsFilter == null || widget.columnsFilter!.isEmpty) {
      return '';
    }

    final cacheKey = row.hashCode;

    // Return cached if exists
    if (_searchHaystackCache.containsKey(cacheKey)) {
      return _searchHaystackCache[cacheKey]!;
    }

    // Build and cache haystack
    final haystack = widget.columnsFilter!
        .map((col) => row[col]?.toString() ?? '')
        .join(' ')
        .toLowerCase();

    // 🎯 Limit cache size để tránh memory leak
    if (_searchHaystackCache.length < 5000) {
      _searchHaystackCache[cacheKey] = haystack;
    }

    return haystack;
  }

  /// ✅ Check xem có dùng shrinkWrap không
  bool get _useShrinkWrap => widget.height == "*";

  /// ✅ Get physics phù hợp
  ScrollPhysics? get _scrollPhysics {
    if (_useShrinkWrap) {
      return const NeverScrollableScrollPhysics();
    }
    return null;
  }

  /// ✅ Check có hiển thị swipe actions không (bao gồm cả delete)
  bool get _hasSwipeActions {
    return (widget.dtSwipeActions != null &&
            widget.dtSwipeActions!.rowCount > 0) ||
        widget.isDelete;
  }

  @override
  void initState() {
    super.initState();
    if (!mounted) return;
    _scrollController = widget.scrollController ?? ScrollController();

    if (!_useShrinkWrap) {
      _scrollController.addListener(_onScroll);
    }

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

    // ✅ Kiểm tra refreshKey thay đổi (ví dụ khi đổi tab)
    if (widget.refreshKey != oldWidget.refreshKey) {
      // Reset tất cả state
      _filteredIndices = null;
      _currentSearchText = '';
      _currentPage = 0;
      _hasMoreData = true;
      _searchController.clear();
      _incrementDataVersion();
      _incrementFilterVersion();
      _invalidateCache();
      _clearSearchCache();

      // Reload data nếu có onLoadData
      if (widget.onLoadData != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadInitialData();
        });
      } else {
        // Nếu không có onLoadData, chỉ refresh UI
        if (mounted) {
          setState(() {});
        }
      }
      return;
    }

    // Check dataSource thay đổi
    if (widget.dataSource != oldWidget.dataSource) {
      _filteredIndices = null;
      _currentSearchText = '';
      _searchController.clear();
      _incrementDataVersion();
      _invalidateCache();
      _clearSearchCache();
      if (mounted) {
        setState(() {});
      }
    }

    // Check height thay đổi
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
    _scrollController.removeListener(_onScroll);
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    _searchController.dispose();
    _searchDebounceTimer?.cancel();
    _filteredIndices = null;
    _invalidateCache();
    _clearSearchCache();
    super.dispose();
  }

  /// 🎯 OPTIMIZATION: Giảm số lần setState
  Future<void> _loadInitialData() async {
    if (!mounted) return;
    if (widget.onLoadData == null) return;

    _currentPage = 0;

    // 🎯 Chỉ 1 setState ở đầu
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasMoreData = true;
      });
    }

    try {
      final requestSearch = _currentSearchText;
      final newDataTable = await widget.onLoadData!(
        _currentPage,
        widget.pageSize,
        _currentSearchText,
      );

      if (!mounted || requestSearch != _currentSearchText) return;

      if (widget.dataSource != null) {
        widget.dataSource!.clear();
        widget.dataSource!.loadDatafromTb(newDataTable);
      }

      _incrementDataVersion();
      _invalidateCache();
      _clearSearchCache();

      // 🎯 Chỉ 1 setState ở cuối
      if (mounted) {
        setState(() {
          _hasMoreData = newDataTable.rowCount >= widget.pageSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      // 🎯 1 setState cho error
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _showError('Lỗi khi load dữ liệu: $e');
    }
  }

  /// 🎯 CRITICAL FIX: Load more với scroll offset compensation
  Future<void> _loadMore() async {
    if (!mounted) return;
    if (_isLoadingMore || !_hasMoreData || widget.onLoadData == null) return;

    if (mounted) {
      setState(() => _isLoadingMore = true);
    }

    try {
      final nextPage = _currentPage + 1;
      final moreDataTable = await widget.onLoadData!(
        nextPage,
        widget.pageSize,
        _currentSearchText,
      );

      if (!mounted) return;

      // 🎯 FIX: Không giảm _currentPage, chỉ increment khi load thành công
      _currentPage = nextPage;

      if (widget.dataSource != null) {
        // 🎯 CRITICAL FIX: Trim với scroll offset compensation
        await _trimOldItemsIfNeeded(moreDataTable.rowCount);

        widget.dataSource!.batch(() {
          for (var row in moreDataTable.rows) {
            widget.dataSource!.addRow(row);
          }
        });
      }

      _incrementDataVersion();
      _invalidateCache();
      _clearSearchCache();

      if (mounted) {
        setState(() {
          _hasMoreData = moreDataTable.rowCount >= widget.pageSize;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
      _showError('Lỗi khi load thêm dữ liệu: $e');
    }
  }

  /// 🎯 CRITICAL FIX: Trim old items với scroll compensation
  Future<void> _trimOldItemsIfNeeded(int newItemCount) async {
    // 🎯 FIX: maxItemsInMemory = 0 nghĩa là không giới hạn
    if (widget.maxItemsInMemory <= 0) return;
    if (widget.dataSource == null) return;

    final totalAfterAdd = widget.dataSource!.rowCount + newItemCount;

    if (totalAfterAdd <= widget.maxItemsInMemory) return;

    final removeCount = totalAfterAdd - widget.maxItemsInMemory;

    // 🎯 Calculate scroll offset compensation
    double offsetCompensation = 0;
    if (_scrollController.hasClients && widget.estimatedItemHeight != null) {
      offsetCompensation = removeCount * widget.estimatedItemHeight!;
    }

    // ✅ EFFICIENT BULK REMOVE - O(n) instead of O(n²)
    try {
      // Priority 1: Use removeFirstN (fastest, O(n))
      widget.dataSource!.removeFirstN(removeCount);
    } catch (e) {
      // Priority 2: Use removeRange (also O(n))
      try {
        widget.dataSource!.removeRange(0, removeCount);
      } catch (e2) {
        // Priority 3: Fallback to manual remove (O(n²) but rare)
        debugPrint('⚠️ Warning: Using slow remove. Error: $e2');
        widget.dataSource!.batch(() {
          for (int i = 0; i < removeCount; i++) {
            widget.dataSource!.removeAt(0);
          }
        });
      }
    }

    // 🎯 Compensate scroll offset để không bị nhảy
    if (offsetCompensation > 0 && _scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          final newOffset = (_scrollController.offset - offsetCompensation)
              .clamp(0.0, _scrollController.position.maxScrollExtent);
          _scrollController.jumpTo(newOffset);
        }
      });
    }
  }

  Future<void> _refresh() async {
    if (!mounted) return;

    if (_currentSearchText.isNotEmpty) {
      _searchController.clear();
      _currentSearchText = '';

      if (widget.onLoadData == null) {
        if (mounted) {
          setState(() {
            _filteredIndices = null;
            _incrementFilterVersion();
            _invalidateCache();
            _clearSearchCache();
          });
        }
        return;
      }
    }

    await _loadInitialData();
  }

  /// ✅ Search với debounce
  void _onSearchChanged(String searchText) {
    if (!mounted) return;

    _searchDebounceTimer?.cancel();

    _searchDebounceTimer = Timer(
      Duration(milliseconds: widget.searchDebounceTime),
      () {
        if (!mounted) return;

        _currentSearchText = searchText;

        if (widget.onLoadData != null) {
          _loadInitialData();
          return;
        }

        _filterLocalData(searchText);
      },
    );
  }

  /// 🎯 OPTIMIZATION: Filter với cached haystack
  void _filterLocalData(String searchText) {
    if (!mounted) return;

    // 🎯 Warning nếu dataset quá lớn
    if (widget.dataSource != null && widget.dataSource!.rowCount > 10000) {
      _showError(
        'Dataset quá lớn (${widget.dataSource!.rowCount} items). Search có thể chậm.',
      );
    }

    final indices = _performFilterIndices(searchText);

    if (mounted) {
      setState(() {
        _filteredIndices = indices;
        _incrementFilterVersion();
        _invalidateCache();
      });
    }
  }

  /// 🎯 CRITICAL FIX: Filter dùng cached haystack
  List<int>? _performFilterIndices(String searchText) {
    if (widget.dataSource == null ||
        widget.columnsFilter == null ||
        widget.columnsFilter!.isEmpty) {
      return null;
    }

    if (searchText.trim().isEmpty) {
      return null;
    }

    final filteredIndices = <int>[];
    final lowerSearch = searchText.toLowerCase().trim();
    final sourceRows = widget.dataSource!.rows;

    for (int i = 0; i < sourceRows.length; i++) {
      final row = sourceRows[i];

      // 🎯 FIX: Dùng cached haystack thay vì tạo mới mỗi lần
      final haystack = _getSearchHaystack(row);

      if (haystack.contains(lowerSearch)) {
        filteredIndices.add(i);
      }
    }

    return filteredIndices;
  }

  void _onScroll() {
    if (!mounted) return;
    final position = _scrollController.position;
    final threshold = position.maxScrollExtent * 0.9;

    if (position.pixels >= threshold) {
      _loadMore();
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> refresh() async {
    if (!mounted) return;
    await _refresh();
  }

  /// 🎯 CRITICAL FIX: Delete với filter rebuild
  Future<void> _handleDeleteItem(CyberDataRow row, int index) async {
    if (!mounted) return;

    final confirmed = await setText(
      "Bạn chắc chắn muốn xóa dữ liệu?",
      "Are you sure you want to delete the data?",
    ).V_MsgBox(context, type: CyberMsgBoxType.warning);

    if (confirmed != true || !mounted) return;

    bool canDelete = true;
    if (widget.onDelete != null) {
      try {
        canDelete = await widget.onDelete!(row, index);
      } catch (e) {
        _showError('Lỗi khi xóa: $e');
        return;
      }
    }

    if (canDelete && mounted) {
      if (widget.dataSource != null) {
        final sourceIndex = widget.dataSource!.rows.indexOf(row);
        if (sourceIndex >= 0) {
          widget.dataSource!.removeAt(sourceIndex);
          _incrementDataVersion();

          // 🎯 CRITICAL FIX: Rebuild filter nếu đang filter local
          if (_filteredIndices != null && widget.onLoadData == null) {
            // Clear search cache vì data đã thay đổi
            _clearSearchCache();
            // Rebuild filter với current search text
            _filterLocalData(_currentSearchText);
          } else {
            _invalidateCache();
            _clearSearchCache();
            if (mounted) {
              setState(() {});
            }
          }
        }
      }
    }
  }

  /// ✅ Tính extent ratio an toàn
  double _calculateSwipeExtentRatio() {
    int totalActions = 0;
    if (widget.dtSwipeActions != null) {
      totalActions += widget.dtSwipeActions!.rowCount;
    }
    if (widget.isDelete) {
      totalActions += 1;
    }

    if (totalActions == 0) {
      return 0.25;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final totalWidth = totalActions * 80.0;

    return (totalWidth / screenWidth).clamp(0.1, 0.8);
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Column(
      mainAxisSize: widget.height == "*" ? MainAxisSize.min : MainAxisSize.max,
      children: [
        if (widget.showSearchBox) _buildSearchBar(),
        _buildListViewContainer(),
      ],
    );

    if (widget.cyberActions != null && widget.cyberActions!.isNotEmpty) {
      content = Stack(children: [content, _buildCyberAction()]);
    }

    if (widget.height is double) {
      return SizedBox(height: widget.height as double, child: content);
    } else if (widget.height == "*") {
      return content;
    } else {
      return content;
    }
  }

  /// ✅ Build CyberAction
  Widget _buildCyberAction() {
    if (widget.cyberActions == null || widget.cyberActions!.isEmpty) {
      return const SizedBox.shrink();
    }

    return CyberAction(
      children: widget.cyberActions!,
      type: widget.cyberActionType,
      top: widget.cyberActionTop,
      left: widget.cyberActionLeft,
      bottom: widget.cyberActionBottom,
      right: widget.cyberActionRight,
      isCenterVer: widget.cyberActionCenterVer,
      isCenterHor: widget.cyberActionCenterHor,
      direction: widget.cyberActionDirection,
      spacing: widget.cyberActionSpacing,
      mainButtonColor: widget.cyberActionMainButtonColor,
      mainButtonIcon: widget.cyberActionMainButtonIcon,
      mainButtonSize: widget.cyberActionMainButtonSize,
      mainIconColor: widget.cyberActionMainIconColor,
      animationDuration: widget.cyberActionAnimationDuration,
      showBackdrop: widget.cyberActionShowBackdrop,
      backdropColor: widget.cyberActionBackdropColor,
      isShowBackgroundColor: widget.cyberActionShowBackground,
      backgroundColor: widget.cyberActionBackgroundColor,
      backgroundOpacity: widget.cyberActionBackgroundOpacity,
      borderRadius: widget.cyberActionBorderRadius,
      containerBorderWidth: widget.cyberActionBorderWidth,
      containerBorderColor: widget.cyberActionBorderColor,
      containerPadding: widget.cyberActionPadding,
    );
  }

  Widget _buildListViewContainer() {
    final listViewContent = _isLoading
        ? _buildLoading()
        : _workingRows.isEmpty
        ? _buildEmpty()
        : widget.horizontal
        ? _buildHorizontalList()
        : widget.columnCount > 1
        ? _buildGridList()
        : _buildList();

    if (widget.height == "*") {
      return listViewContent;
    }

    return Expanded(child: listViewContent);
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: CupertinoColors.systemFill.resolveFrom(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: setText('Tìm kiếm', "Search"),
                  hintStyle: TextStyle(
                    color: CupertinoColors.systemGrey.resolveFrom(context),
                    fontSize: 16,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 8, right: 4),
                    child: Icon(
                      CupertinoIcons.search,
                      color: CupertinoColors.systemGrey.resolveFrom(context),
                      size: 20,
                    ),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              CupertinoIcons.xmark_circle_fill,
                              color: CupertinoColors.systemGrey.resolveFrom(
                                context,
                              ),
                              size: 18,
                            ),
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  isDense: true,
                ),
                onChanged: (value) {
                  if (mounted) {
                    setState(() {});
                  }
                  _onSearchChanged(value);
                },
              ),
            ),
          ),
          if (widget.dtToolbarActions != null &&
              widget.dtToolbarActions!.rowCount > 0)
            ..._buildToolbarActions(),
        ],
      ),
    );
  }

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

  void _handleToolbarActionTap(CyberDataRow actionRow) {
    if (widget.isToolbarActionClickToScreen) {
      actionRow.V_Call(context);
    }
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
                    ? setText(
                        'Không tìm thấy kết quả cho "$_currentSearchText"',
                        'No results found for "$_currentSearchText"',
                      )
                    : setText('Không có dữ liệu', "No data available"),
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        );
  }

  /// 🎯 OPTIMIZATION: ListView với optimization flags + itemExtent
  Widget _buildList() {
    final rows = _workingRows;

    final listView = ListView.separated(
      controller: _scrollController,
      padding: widget.padding ?? const EdgeInsets.all(8),
      itemCount: rows.length + (_isLoadingMore ? 1 : 0),
      shrinkWrap: _useShrinkWrap,
      physics: _scrollPhysics,
      // 🎯 OPTIMIZATION FLAGS (vẫn hiệu quả)
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      cacheExtent: 500,
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
        final itemWidget = _hasSwipeActions
            ? _buildSlidableItem(row, index)
            : _buildItem(row, index);

        return KeyedSubtree(key: ValueKey(row.identityKey), child: itemWidget);
      },
    );

    final wrappedListView = SlidableAutoCloseBehavior(child: listView);

    if (_useShrinkWrap) {
      return wrappedListView;
    }

    return RefreshIndicator(onRefresh: _refresh, child: wrappedListView);
  }

  /// 🎯 OPTIMIZATION: Horizontal ListView (FIXED)
  Widget _buildHorizontalList() {
    final rows = _workingRows;

    final listView = ListView.separated(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      padding: widget.padding ?? const EdgeInsets.all(8),
      itemCount: rows.length + (_isLoadingMore ? 1 : 0),
      shrinkWrap: _useShrinkWrap,
      physics: _scrollPhysics,
      // 🎯 OPTIMIZATION FLAGS
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      cacheExtent: 500,
      // ❌ KHÔNG dùng itemExtent
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
        final itemWidget = _hasSwipeActions
            ? _buildSlidableItem(row, index)
            : _buildItem(row, index);

        return KeyedSubtree(key: ValueKey(row.identityKey), child: itemWidget);
      },
    );

    return SlidableAutoCloseBehavior(child: listView);
  }

  /// 🎯 OPTIMIZATION: GridView với optimization flags
  Widget _buildGridList() {
    final rows = _workingRows;

    if (widget.autoItemHeight) {
      return _buildAutoHeightGrid(rows);
    }

    final totalItems = rows.length + (_isLoadingMore ? 1 : 0);

    final gridView = GridView.builder(
      controller: _scrollController,
      padding: widget.padding ?? const EdgeInsets.all(8),
      shrinkWrap: _useShrinkWrap,
      physics: _scrollPhysics,
      // 🎯 OPTIMIZATION FLAGS
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      cacheExtent: 500,
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
        return _buildItem(row, index);
      },
    );

    if (_useShrinkWrap) {
      return gridView;
    }

    return RefreshIndicator(onRefresh: _refresh, child: gridView);
  }

  Widget _buildAutoHeightGrid(List<CyberDataRow> rows) {
    final rowCount = (rows.length / widget.columnCount).ceil();

    return ListView.separated(
      controller: _scrollController,
      padding: widget.padding ?? const EdgeInsets.all(8),
      itemCount: rowCount + (_isLoadingMore ? 1 : 0),
      shrinkWrap: _useShrinkWrap,
      physics: _scrollPhysics,
      // 🎯 OPTIMIZATION FLAGS
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      cacheExtent: 500,
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

  Widget _buildAutoHeightGridRow(List<CyberDataRow> rowItems, int startIndex) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < rowItems.length; i++) ...[
          Expanded(child: _buildItem(rowItems[i], startIndex + i)),
          if (i < rowItems.length - 1) SizedBox(width: widget.crossAxisSpacing),
        ],
        for (int i = rowItems.length; i < widget.columnCount; i++) ...[
          if (i > 0) SizedBox(width: widget.crossAxisSpacing),
          const Expanded(child: SizedBox()),
        ],
      ],
    );
  }

  /// 🎯 OPTIMIZATION: Sử dụng _CyberListItem widget riêng
  Widget _buildItem(CyberDataRow row, int index) {
    return _CyberListItem(
      row: row,
      index: index,
      itemBuilder: widget.itemBuilder,
      borderRadius: widget.itemBorderRadius,
      backgroundColor: widget.itemBackgroundColor,
      isClickToScreen: widget.isClickToScreen,
      onItemTap: widget.onItemTap,
      onItemLongPress: widget.onItemLongPress,
      onTap: (widget.onItemTap != null || widget.isClickToScreen)
          ? () => _handleItemTap(row, index)
          : null,
      onLongPress: () => _handleItemLongPress(row, index),
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

  /// ✅ Slidable item
  Widget _buildSlidableItem(CyberDataRow row, int index) {
    return ClipRRect(
      borderRadius: widget.itemBorderRadius ?? BorderRadius.zero,
      child: Slidable(
        key: Key('item_${row.hashCode}_$index'),
        closeOnScroll: true,
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: _calculateSwipeExtentRatio(),
          children: _buildSwipeActions(row, index),
        ),
        child: _CyberSlidableItem(
          row: row,
          index: index,
          itemBuilder: widget.itemBuilder,
          backgroundColor: widget.itemBackgroundColor,
          isClickToScreen: widget.isClickToScreen,
          onItemTap: widget.onItemTap,
          onItemLongPress: widget.onItemLongPress,
          onTap: (widget.onItemTap != null || widget.isClickToScreen)
              ? () => _handleItemTap(row, index)
              : null,
          onLongPress: () => _handleItemLongPress(row, index),
        ),
      ),
    );
  }

  /// ✅ Build swipe actions
  List<Widget> _buildSwipeActions(CyberDataRow sourceRow, int sourceIndex) {
    final actions = <Widget>[];

    if (widget.dtSwipeActions != null && widget.dtSwipeActions!.rowCount > 0) {
      for (var i = 0; i < widget.dtSwipeActions!.rows.length; i++) {
        final swipeRow = widget.dtSwipeActions!.rows[i];
        final label = swipeRow['bar'] as String? ?? '';
        final iconName = swipeRow['icon'] as String? ?? '';
        final backColorHex = swipeRow['backcolor'] as String? ?? '';
        final textColorHex = swipeRow['textcolor'] as String? ?? '';

        final backgroundColor = _parseColor(backColorHex, Colors.blue);
        final foregroundColor = _parseColor(textColorHex, Colors.white);
        final icon = v_parseIcon(iconName);

        final isLastAction =
            (i == widget.dtSwipeActions!.rows.length - 1) && !widget.isDelete;
        final actionBorderRadius = _getActionBorderRadius(isLastAction);

        actions.add(
          CustomSlidableAction(
            onPressed: (context) {
              _handleSwipeActionTap(swipeRow, sourceRow, sourceIndex);
            },
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            borderRadius: actionBorderRadius,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) Icon(icon, size: 24),
                if (icon != null) const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }
    }

    if (widget.isDelete) {
      final deleteActionBorderRadius = _getActionBorderRadius(true);

      actions.add(
        CustomSlidableAction(
          onPressed: (context) {
            _handleDeleteItem(sourceRow, sourceIndex);
          },
          backgroundColor: const Color(0xFFFF6B35),
          foregroundColor: Colors.white,
          borderRadius: deleteActionBorderRadius,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CyberLabel(
                isIcon: true,
                text: "e92b",
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                setText('Xóa', 'Delete'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      );
    }

    return actions;
  }

  BorderRadius _getActionBorderRadius(bool isLastAction) {
    if (widget.itemBorderRadius == null) {
      return BorderRadius.zero;
    }

    if (isLastAction) {
      return BorderRadius.only(
        topRight: widget.itemBorderRadius!.topRight,
        bottomRight: widget.itemBorderRadius!.bottomRight,
      );
    }

    return BorderRadius.zero;
  }

  void _handleSwipeActionTap(
    CyberDataRow swipeRow,
    CyberDataRow sourceRow,
    int sourceIndex,
  ) {
    if (widget.isSwipeActionClickToScreen) {
      swipeRow.V_Call(context);
    }
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

// ============================================================================
// 🎯 OPTIMIZATION: SEPARATE STATELESS WIDGET FOR LIST ITEMS
// ============================================================================

/// 🎯 Widget riêng cho mỗi list item (không có Slidable)
class _CyberListItem extends StatelessWidget {
  final CyberDataRow row;
  final int index;
  final ItemBuilder itemBuilder;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final bool isClickToScreen;
  final ItemTapCallback? onItemTap;
  final ItemLongPressCallback? onItemLongPress;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _CyberListItem({
    required this.row,
    required this.index,
    required this.itemBuilder,
    this.borderRadius,
    this.backgroundColor,
    this.isClickToScreen = false,
    this.onItemTap,
    this.onItemLongPress,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (BuildContext itemContext) {
        final itemContent = itemBuilder(context, row, index);

        final wrappedContent = (backgroundColor != null || borderRadius != null)
            ? Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: borderRadius,
                ),
                clipBehavior: borderRadius != null ? Clip.antiAlias : Clip.none,
                child: itemContent,
              )
            : itemContent;

        return InkWell(
          onTap:
              onTap ??
              () {
                Slidable.of(itemContext)?.close();
              },
          onLongPress: onLongPress,
          borderRadius: borderRadius,
          child: wrappedContent,
        );
      },
    );
  }
}

/// 🎯 Widget riêng cho Slidable item
class _CyberSlidableItem extends StatelessWidget {
  final CyberDataRow row;
  final int index;
  final ItemBuilder itemBuilder;
  final Color? backgroundColor;
  final bool isClickToScreen;
  final ItemTapCallback? onItemTap;
  final ItemLongPressCallback? onItemLongPress;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _CyberSlidableItem({
    required this.row,
    required this.index,
    required this.itemBuilder,
    this.backgroundColor,
    this.isClickToScreen = false,
    this.onItemTap,
    this.onItemLongPress,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (BuildContext slidableContext) {
        final itemContent = itemBuilder(context, row, index);

        final wrappedContent = backgroundColor != null
            ? Container(color: backgroundColor, child: itemContent)
            : itemContent;

        return InkWell(
          onTap:
              onTap ??
              () {
                Slidable.of(slidableContext)?.close();
              },
          onLongPress: onLongPress,
          child: wrappedContent,
        );
      },
    );
  }
}

// ============================================================================
// MENU BOTTOM SHEET
// ============================================================================

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

  void _handleMenuItemTap(
    BuildContext context,
    CyberDataRow menuRow,
    CyberDataRow sourceRow,
    int sourceIndex,
  ) {
    try {
      if (isMenuClickToScreen) {
        final pageName = menuRow['pagename'] as String?;
        if (pageName != null && pageName.isNotEmpty) {
          menuRow.V_Call(context);
        }
      }
      onMenuItemTap?.call(menuRow, sourceRow, sourceIndex);
    } catch (e) {
      // Silent error handling
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
    final icon = v_parseIcon(iconName);

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
}
