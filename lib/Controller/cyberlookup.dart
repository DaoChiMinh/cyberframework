import 'package:cyberframework/cyberframework.dart';

/// CyberLookup - Lookup control với Internal Controller + Binding
///
/// Hỗ trợ binding 2 chiều cho text value và display value:
/// ```dart
/// CyberLookup(
///   text: drEdit.bind('ma_kh'),           // Binding text value
///   display: drEdit.bind('ten_kh'),        // Binding display value
///   tbName: 'dmkh',
///   displayField: 'ten_kh',
///   displayValue: 'ma_kh',
/// )
/// ```
class CyberLookup extends StatefulWidget {
  // === DATA BINDING ===
  /// Text value - có thể binding: dr.bind('ma_kh')
  final dynamic text;

  /// Display value - có thể binding: dr.bind('ten_kh')
  final dynamic display;

  /// Callback khi giá trị thay đổi
  final ValueChanged<dynamic>? onChanged;

  // === LOOKUP PARAMETERS ===
  /// Tên bảng lookup - có thể binding
  final dynamic tbName;

  /// Filter string - có thể binding
  final dynamic strFilter;

  /// Tên field hiển thị
  final dynamic displayField;

  /// Tên field giá trị
  final dynamic displayValue;

  /// Số record mỗi trang
  final int lookupPageSize;

  // === UI PROPERTIES ===
  final String? label;
  final String? hint;
  final TextStyle? labelStyle;
  final TextStyle? textStyle;
  final IconData? icon;
  final bool enabled;
  final bool readOnly;
  final bool allowClear;
  final bool isShowLabel;
  final dynamic isVisible;
  final dynamic isCheckEmpty;
  final Color? backgroundColor;
  final Color? borderColor;

  // === CALLBACKS ===
  final Function(dynamic)? onLeaver;

  const CyberLookup({
    super.key,
    this.text,
    this.display,
    this.onChanged,
    this.tbName,
    this.strFilter,
    this.displayField,
    this.displayValue,
    this.lookupPageSize = 50,
    this.label,
    this.hint,
    this.labelStyle,
    this.textStyle,
    this.icon,
    this.enabled = true,
    this.readOnly = false,
    this.allowClear = true,
    this.isShowLabel = true,
    this.isVisible = true,
    this.isCheckEmpty = false,
    this.backgroundColor,
    this.borderColor,
    this.onLeaver,
  });

  @override
  State<CyberLookup> createState() => _CyberLookupState();
}

// ============================================================================
// INTERNAL STATE - QUẢN LÝ CONTROLLER VÀ BINDING
// ============================================================================

class _CyberLookupState extends State<CyberLookup> {
  // === INTERNAL CONTROLLER ===
  late final _InternalLookupController _controller;

  // === BINDING CONTEXT ===
  CyberDataRow? _textBoundRow;
  String? _textBoundField;
  CyberDataRow? _displayBoundRow;
  String? _displayBoundField;

  // === VISIBILITY BINDING ===
  CyberDataRow? _visibilityBoundRow;
  String? _visibilityBoundField;

  // === FLAGS ===
  bool _isInternalUpdate = false;

  @override
  void initState() {
    super.initState();

    // Khởi tạo internal controller
    _controller = _InternalLookupController();

    // Parse bindings
    _parseTextBinding();
    _parseDisplayBinding();
    _parseVisibilityBinding();

    // Sync initial values
    _syncFromWidget();

    // Listen to controller changes
    _controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(CyberLookup oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Re-parse bindings nếu properties thay đổi
    if (widget.text != oldWidget.text) {
      _parseTextBinding();
    }
    if (widget.display != oldWidget.display) {
      _parseDisplayBinding();
    }
    if (widget.isVisible != oldWidget.isVisible) {
      _parseVisibilityBinding();
    }

    // Sync values
    _syncFromWidget();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();

    // Cleanup bindings
    _textBoundRow?.removeListener(_onTextBindingChanged);
    _displayBoundRow?.removeListener(_onDisplayBindingChanged);

    super.dispose();
  }

  // ============================================================================
  // BINDING PARSERS
  // ============================================================================

  void _parseTextBinding() {
    // Cleanup old binding
    if (_textBoundRow != null) {
      _textBoundRow!.removeListener(_onTextBindingChanged);
      _textBoundRow = null;
      _textBoundField = null;
    }

    // Parse new binding
    if (widget.text is CyberBindingExpression) {
      final expr = widget.text as CyberBindingExpression;
      _textBoundRow = expr.row;
      _textBoundField = expr.fieldName;
      _textBoundRow!.addListener(_onTextBindingChanged);
    }
  }

  void _parseDisplayBinding() {
    // Cleanup old binding
    if (_displayBoundRow != null) {
      _displayBoundRow!.removeListener(_onDisplayBindingChanged);
      _displayBoundRow = null;
      _displayBoundField = null;
    }

    // Parse new binding
    if (widget.display is CyberBindingExpression) {
      final expr = widget.display as CyberBindingExpression;
      _displayBoundRow = expr.row;
      _displayBoundField = expr.fieldName;
      _displayBoundRow!.addListener(_onDisplayBindingChanged);
    }
  }

  void _parseVisibilityBinding() {
    if (widget.isVisible is CyberBindingExpression) {
      final expr = widget.isVisible as CyberBindingExpression;
      _visibilityBoundRow = expr.row;
      _visibilityBoundField = expr.fieldName;
    } else {
      _visibilityBoundRow = null;
      _visibilityBoundField = null;
    }
  }

  // ============================================================================
  // SYNC LOGIC
  // ============================================================================

  /// Sync từ widget properties vào controller
  void _syncFromWidget() {
    if (_isInternalUpdate) return;

    _isInternalUpdate = true;

    // Sync text value
    final textValue = _extractValue(widget.text);
    if (_controller.textValue != textValue) {
      _controller._textValue = textValue;
    }

    // Sync display value
    final displayValue = _extractDisplayValue(widget.display);
    if (_controller.displayValue != displayValue) {
      _controller._displayValue = displayValue;
    }

    _isInternalUpdate = false;
  }

  /// Sync từ text binding vào controller
  void _onTextBindingChanged() {
    if (_isInternalUpdate || !mounted) return;
    if (_textBoundRow == null || _textBoundField == null) return;

    _isInternalUpdate = true;

    final newValue = _textBoundRow![_textBoundField!];
    if (_controller.textValue != newValue) {
      _controller._textValue = newValue;
      _controller.notifyListeners();
    }

    _isInternalUpdate = false;
  }

  /// Sync từ display binding vào controller
  void _onDisplayBindingChanged() {
    if (_isInternalUpdate || !mounted) return;
    if (_displayBoundRow == null || _displayBoundField == null) return;

    _isInternalUpdate = true;

    final newValue = _displayBoundRow![_displayBoundField!]?.toString() ?? '';
    if (_controller.displayValue != newValue) {
      _controller._displayValue = newValue;
      _controller.notifyListeners();
    }

    _isInternalUpdate = false;
  }

  /// Sync từ controller vào bindings (khi user chọn lookup)
  void _syncToBindings(dynamic textValue, String displayValue) {
    if (_isInternalUpdate) return;

    _isInternalUpdate = true;

    // Update controller
    _controller._textValue = textValue;
    _controller._displayValue = displayValue;

    // Update bindings
    if (_textBoundRow != null && _textBoundField != null) {
      _textBoundRow![_textBoundField!] = textValue;
    }
    if (_displayBoundRow != null && _displayBoundField != null) {
      _displayBoundRow![_displayBoundField!] = displayValue;
    }

    // Callback
    widget.onChanged?.call(textValue);

    _isInternalUpdate = false;
    _controller.notifyListeners();
  }

  /// Listen to controller changes
  void _onControllerChanged() {
    if (!mounted || _isInternalUpdate) return;
    setState(() {}); // Rebuild UI
  }

  // ============================================================================
  // VALUE EXTRACTORS
  // ============================================================================

  dynamic _extractValue(dynamic value) {
    if (value is CyberBindingExpression) {
      try {
        return value.row[value.fieldName];
      } catch (e) {
        return null;
      }
    }
    return value;
  }

  String _extractDisplayValue(dynamic value) {
    if (value is CyberBindingExpression) {
      try {
        return value.row[value.fieldName]?.toString() ?? '';
      } catch (e) {
        return '';
      }
    }
    return value?.toString() ?? '';
  }

  String _extractParam(dynamic param) {
    if (param is CyberBindingExpression) {
      try {
        return param.row[param.fieldName]?.toString() ?? '';
      } catch (e) {
        return '';
      }
    }
    return param?.toString() ?? '';
  }

  // ============================================================================
  // VISIBILITY HELPERS
  // ============================================================================

  bool _parseBool(dynamic value, {required bool defaultValue}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase().trim();
      if (lower == "1" || lower == "true") return true;
      if (lower == "0" || lower == "false") return false;
      return defaultValue;
    }
    return defaultValue;
  }

  bool _isVisible() {
    if (_visibilityBoundRow != null && _visibilityBoundField != null) {
      return _parseBool(
        _visibilityBoundRow![_visibilityBoundField!],
        defaultValue: true,
      );
    }
    return _parseBool(widget.isVisible, defaultValue: true);
  }

  bool _isCheckEmpty() {
    return _parseBool(widget.isCheckEmpty, defaultValue: false);
  }

  // ============================================================================
  // ACTIONS
  // ============================================================================

  /// Clear values
  void _clearValues() {
    if (!_isInteractive()) return;

    _syncToBindings(null, '');

    // Callback
    if (widget.onLeaver != null) {
      Future.delayed(Duration.zero, () {
        if (mounted) {
          widget.onLeaver!(null);
        }
      });
    }
  }

  /// Show lookup modal
  Future<void> _showLookup() async {
    if (!_isInteractive() || !mounted) return;

    // Get lookup parameters
    final tbName = _extractParam(widget.tbName);
    final strFilter = _extractParam(widget.strFilter);
    final displayField = _extractParam(widget.displayField);
    final valueField = _extractParam(widget.displayValue);
    final pageSize = widget.lookupPageSize;

    if (tbName.isEmpty || displayField.isEmpty || valueField.isEmpty) return;

    // Get current value
    final currentTextValue = _controller.textValue;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LookupBottomSheet(
        tbName: tbName,
        strFilter: strFilter,
        displayField: displayField,
        displayValue: valueField,
        currentTextValue: currentTextValue,
        pageSize: pageSize,
      ),
    );

    if (result != null && mounted) {
      final textValue = result[valueField];
      final displayValue = result[displayField]?.toString() ?? '';

      _syncToBindings(textValue, displayValue);

      // Callback
      if (widget.onLeaver != null) {
        Future.delayed(Duration.zero, () {
          if (mounted) {
            widget.onLeaver!(textValue);
          }
        });
      }
    }
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  bool _isInteractive() {
    return widget.enabled && !widget.readOnly;
  }

  String _getCurrentDisplayValue() {
    return _controller.displayValue;
  }

  bool _hasValue() {
    return _getCurrentDisplayValue().isNotEmpty;
  }

  // ============================================================================
  // BUILD UI
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    Widget buildLookupWidget() {
      if (!_isVisible()) {
        return const SizedBox.shrink();
      }

      final displayText = _getCurrentDisplayValue();
      final hasValue = _hasValue();
      final checkEmpty = _isCheckEmpty();
      final isInteractive = _isInteractive();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isShowLabel &&
              widget.label != null &&
              widget.label!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
              child: Row(
                children: [
                  Text(
                    widget.label!,
                    maxLines: 1,
                    style:
                        widget.labelStyle ??
                        const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF555555),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  if (checkEmpty)
                    const Text(
                      ' *',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          InkWell(
            onTap: isInteractive ? _showLookup : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isInteractive
                    ? (widget.backgroundColor ?? const Color(0xFFF5F5F5))
                    : const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(8),
                border: widget.borderColor != null
                    ? Border.all(color: widget.borderColor!)
                    : null,
              ),
              child: Row(
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      color: isInteractive
                          ? Colors.grey[600]
                          : Colors.grey[400],
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      hasValue ? displayText : (widget.hint ?? 'Chọn...'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          widget.textStyle ??
                          TextStyle(
                            fontSize: 16,
                            color: hasValue
                                ? (isInteractive ? Colors.black87 : Colors.grey)
                                : Colors.grey[500],
                          ),
                    ),
                  ),
                  if (widget.allowClear && hasValue && isInteractive) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _clearValues,
                      borderRadius: BorderRadius.circular(12),
                      child: Icon(
                        Icons.clear,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Icon(
                    Icons.search,
                    color: isInteractive ? Colors.grey[600] : Colors.grey[400],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Chỉ dùng ListenableBuilder khi có visibility binding
    if (_visibilityBoundRow != null) {
      return ListenableBuilder(
        listenable: _visibilityBoundRow!,
        builder: (context, child) => buildLookupWidget(),
      );
    }

    return buildLookupWidget();
  }
}

// ============================================================================
// INTERNAL CONTROLLER
// ============================================================================

class _InternalLookupController extends ChangeNotifier {
  dynamic _textValue;
  String _displayValue = '';

  dynamic get textValue => _textValue;
  String get displayValue => _displayValue;
  bool get hasValue => _displayValue.isNotEmpty;
}

// ============================================================================
// LOOKUP BOTTOM SHEET - VIRTUAL PAGING
// ============================================================================

class _LookupBottomSheet extends StatefulWidget {
  final String tbName;
  final String strFilter;
  final String displayField;
  final String displayValue;
  final dynamic currentTextValue;
  final int pageSize;

  const _LookupBottomSheet({
    required this.tbName,
    required this.strFilter,
    required this.displayField,
    required this.displayValue,
    this.currentTextValue,
    this.pageSize = 50,
  });

  @override
  State<_LookupBottomSheet> createState() => _LookupBottomSheetState();
}

class _LookupBottomSheetState extends State<_LookupBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  late ScrollController _scrollController;

  final List<CyberDataRow> _rows = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 0;
  String _currentSearchText = '';

  bool _isMultiSelect = false;
  final Set<int> _selectedIndices = {};

  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _searchDebounceTimer?.cancel();
    _selectedIndices.clear();
    _rows.clear();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    _currentPage = 0;

    setState(() {
      _isLoading = true;
      _rows.clear();
      _selectedIndices.clear();
      _hasMoreData = true;
    });

    await _loadPage(_currentPage);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (!mounted || _isLoadingMore || !_hasMoreData) return;

    setState(() {
      _isLoadingMore = true;
    });

    final nextPage = _currentPage + 1;
    await _loadPage(nextPage);

    if (mounted) {
      setState(() {
        _currentPage = nextPage;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadPage(int pageIndex) async {
    if (!mounted) return;

    try {
      final filter = _currentSearchText;

      final response = await context.callApi(
        functionName: "CP_W10SysListoDir",
        parameter:
            "$pageIndex#${widget.pageSize}#$filter#${widget.strFilter}#${widget.tbName}#01#dungnt",
        showLoading: false,
      );

      if (!mounted) return;

      if (response.isValid()) {
        final ds = response.toCyberDataset();
        if (ds != null) {
          final dt = ds[0];

          if (dt != null) {
            final hasIschon = dt.containerColumn("ischon");
            final newRows = dt.rows;

            if (mounted) {
              setState(() {
                if (pageIndex == 0) {
                  _rows.clear();
                  _isMultiSelect = hasIschon;
                }
                _rows.addAll(newRows);
                _hasMoreData = newRows.length >= widget.pageSize;
              });
            }
          } else {
            if (mounted) {
              setState(() {
                _hasMoreData = false;
              });
            }
          }
        } else {
          if (mounted) {
            setState(() {
              _hasMoreData = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _hasMoreData = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasMoreData = false;
        });
      }
    }
  }

  void _onScroll() {
    if (!mounted) return;

    final position = _scrollController.position;
    final threshold = position.maxScrollExtent * 0.9;

    if (position.pixels >= threshold) {
      _loadMore();
    }
  }

  void _onSearch(String value) {
    _searchDebounceTimer?.cancel();

    _searchDebounceTimer = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      if (_searchController.text == value &&
          (value.isEmpty || value.length > 3)) {
        _currentSearchText = value;
        _loadInitialData();
      }
    });
  }

  Future<void> _refresh() async {
    if (!mounted) return;

    _currentSearchText = '';
    _searchController.clear();
    await _loadInitialData();
  }

  void _toggleSelection(int index) {
    if (!mounted) return;

    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _onSelectRow(CyberDataRow row) {
    if (!mounted) return;

    Navigator.pop(context, {
      widget.displayField: row[widget.displayField],
      widget.displayValue: row[widget.displayValue],
    });
  }

  void _onConfirmMultiSelect() {
    if (!mounted) return;

    if (_selectedIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ít nhất 1 mục')),
      );
      return;
    }

    final displayValues = <String>[];
    final textValues = <String>[];
    final sortedIndices = _selectedIndices.toList()..sort();

    for (var index in sortedIndices) {
      if (index >= _rows.length) continue;

      final row = _rows[index];
      final displayVal = row[widget.displayField]?.toString() ?? '';
      final textVal = row[widget.displayValue]?.toString() ?? '';
      if (displayVal.isNotEmpty) displayValues.add(displayVal);
      if (textVal.isNotEmpty) textValues.add(textVal);
    }

    Navigator.pop(context, {
      widget.displayField: displayValues.join(';'),
      widget.displayValue: textValues.join(';'),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHandle(),
          _buildHeader(),
          _buildSearchBar(),
          const SizedBox(height: 16),
          Expanded(child: _buildContent()),
          if (_isMultiSelect) _buildConfirmButton(),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _isMultiSelect ? 'Chọn nhiều mục' : 'Tìm kiếm',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          if (_isMultiSelect && _selectedIndices.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                'Đã chọn: ${_selectedIndices.length}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Nhập từ khóa tìm kiếm...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _onSearch('');
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: _onSearch,
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_rows.isEmpty) {
      return Center(
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

    return RefreshIndicator(onRefresh: _refresh, child: _buildListView());
  }

  Widget _buildListView() {
    return ListView.separated(
      controller: _scrollController,
      cacheExtent: 500,
      itemCount: _rows.length + (_isLoadingMore ? 1 : 0),
      separatorBuilder: (context, index) =>
          Divider(height: 1, thickness: 1, color: Colors.grey[200]),
      itemBuilder: (context, index) {
        if (index >= _rows.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final row = _rows[index];
        final displayText = row[widget.displayField]?.toString() ?? '';
        final valueText = row[widget.displayValue]?.toString() ?? '';
        final isSelected = _isMultiSelect
            ? _selectedIndices.contains(index)
            : valueText == widget.currentTextValue?.toString();

        if (_isMultiSelect) {
          return CheckboxListTile(
            value: _selectedIndices.contains(index),
            onChanged: (checked) => _toggleSelection(index),
            title: Text(
              displayText,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              valueText,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            selected: isSelected,
            selectedTileColor: Colors.blue[50],
            controlAffinity: ListTileControlAffinity.leading,
          );
        }

        return ListTile(
          selected: isSelected,
          selectedTileColor: Colors.blue[50],
          title: Text(
            displayText,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            valueText,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          onTap: () => _onSelectRow(row),
        );
      },
    );
  }

  Widget _buildConfirmButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _onConfirmMultiSelect,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Xác nhận (${_selectedIndices.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
