import 'package:cyberframework/cyberframework.dart';

class CyberLookup extends StatefulWidget {
  final dynamic text;
  final dynamic display;
  final dynamic tbName;
  final dynamic strFilter;
  final dynamic displayField;
  final dynamic displayValue;
  final String? label;
  final String? hint;
  final TextStyle? labelStyle;
  final TextStyle? textStyle;
  final IconData? icon;
  final bool enabled;

  /// ✅ NEW: Read-only mode
  final bool readOnly;

  /// ✅ NEW: Allow clear button
  final bool allowClear;

  final Function(dynamic)? onLeaver;
  final ValueChanged<dynamic>? onChanged;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool isShowLabel;
  final dynamic isVisible;
  final dynamic isCheckEmpty;
  final int lookupPageSize;

  const CyberLookup({
    super.key,
    this.text,
    this.display,
    this.tbName,
    this.strFilter,
    this.displayField,
    this.displayValue,
    this.label,
    this.hint,
    this.labelStyle,
    this.textStyle,
    this.icon,
    this.enabled = true,
    this.readOnly = false,
    this.allowClear = true,
    this.onLeaver,
    this.onChanged,
    this.backgroundColor,
    this.borderColor,
    this.isShowLabel = true,
    this.isVisible = true,
    this.isCheckEmpty = false,
    this.lookupPageSize = 50,
  });

  @override
  State<CyberLookup> createState() => _CyberLookupState();
}

class _CyberLookupState extends State<CyberLookup> {
  CyberDataRow? _boundTextRow;
  String? _boundTextField;
  CyberDataRow? _boundDisplayRow;
  String? _boundDisplayField;
  CyberDataRow? _visibilityBoundRow;
  String? _visibilityBoundField;

  // ✅ Smart cache with version tracking
  String? _cachedDisplayValue;
  dynamic _cachedTextValue;
  bool? _cachedIsVisible;
  bool? _cachedIsCheckEmpty;
  int _cacheVersion = 0;

  @override
  void initState() {
    super.initState();
    _parseBindings();
    _parseVisibilityBinding();
  }

  @override
  void didUpdateWidget(CyberLookup oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.text != widget.text ||
        oldWidget.display != widget.display ||
        oldWidget.isVisible != widget.isVisible ||
        oldWidget.isCheckEmpty != widget.isCheckEmpty) {
      // ✅ FIX 3.1: Chỉ invalidate khi widget properties thay đổi
      _invalidateCache();
      _parseBindings();
      _parseVisibilityBinding();
    }
  }

  @override
  void dispose() {
    _invalidateCache();
    super.dispose();
  }

  /// ✅ FIX 3.1: Smart invalidation
  void _invalidateCache() {
    _cachedDisplayValue = null;
    _cachedTextValue = null;
    _cachedIsVisible = null;
    _cachedIsCheckEmpty = null;
    _cacheVersion++;
  }

  void _parseBindings() {
    if (widget.text is CyberBindingExpression) {
      final expr = widget.text as CyberBindingExpression;
      _boundTextRow = expr.row;
      _boundTextField = expr.fieldName;
    } else {
      _boundTextRow = null;
      _boundTextField = null;
    }

    if (widget.display is CyberBindingExpression) {
      final expr = widget.display as CyberBindingExpression;
      _boundDisplayRow = expr.row;
      _boundDisplayField = expr.fieldName;
    } else {
      _boundDisplayRow = null;
      _boundDisplayField = null;
    }
  }

  void _parseVisibilityBinding() {
    if (widget.isVisible == null) {
      _visibilityBoundRow = null;
      _visibilityBoundField = null;
      return;
    }

    if (widget.isVisible is CyberBindingExpression) {
      final expr = widget.isVisible as CyberBindingExpression;
      _visibilityBoundRow = expr.row;
      _visibilityBoundField = expr.fieldName;
      return;
    }

    _visibilityBoundRow = null;
    _visibilityBoundField = null;
  }

  /// ✅ FIX 3.2: _parseBool với default values khác nhau
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

  /// ✅ FIX 3.2: isCheckEmpty default = false
  bool _isCheckEmpty() {
    _cachedIsCheckEmpty ??= _parseBool(
      widget.isCheckEmpty,
      defaultValue: false, // ✅ Default false cho isCheckEmpty
    );
    return _cachedIsCheckEmpty!;
  }

  /// ✅ FIX 3.2: isVisible default = true
  bool _isVisible() {
    if (_cachedIsVisible != null) return _cachedIsVisible!;

    if (_visibilityBoundRow != null && _visibilityBoundField != null) {
      _cachedIsVisible = _parseBool(
        _visibilityBoundRow![_visibilityBoundField!],
        defaultValue: true, // ✅ Default true cho isVisible
      );
    } else {
      _cachedIsVisible = _parseBool(
        widget.isVisible,
        defaultValue: true, // ✅ Default true
      );
    }

    return _cachedIsVisible!;
  }

  dynamic _getCurrentTextValue() {
    if (_cachedTextValue != null) return _cachedTextValue;

    if (widget.text is CyberBindingExpression) {
      final expr = widget.text as CyberBindingExpression;
      if (_boundTextRow != expr.row || _boundTextField != expr.fieldName) {
        _boundTextRow = expr.row;
        _boundTextField = expr.fieldName;
      }
    }

    if (_boundTextRow != null && _boundTextField != null) {
      try {
        _cachedTextValue = _boundTextRow![_boundTextField!];
      } catch (e) {
        _cachedTextValue = null;
      }
    } else if (widget.text != null && widget.text is! CyberBindingExpression) {
      _cachedTextValue = widget.text;
    } else {
      _cachedTextValue = null;
    }

    return _cachedTextValue;
  }

  String _getCurrentDisplayValue() {
    if (_cachedDisplayValue != null) return _cachedDisplayValue!;

    if (widget.display is CyberBindingExpression) {
      final expr = widget.display as CyberBindingExpression;
      if (_boundDisplayRow != expr.row ||
          _boundDisplayField != expr.fieldName) {
        _boundDisplayRow = expr.row;
        _boundDisplayField = expr.fieldName;
      }
    }

    if (_boundDisplayRow != null && _boundDisplayField != null) {
      try {
        _cachedDisplayValue =
            _boundDisplayRow![_boundDisplayField!]?.toString() ?? '';
      } catch (e) {
        _cachedDisplayValue = '';
      }
    } else if (widget.display != null &&
        widget.display is! CyberBindingExpression) {
      _cachedDisplayValue = widget.display?.toString() ?? '';
    } else {
      _cachedDisplayValue = '';
    }

    return _cachedDisplayValue!;
  }

  String _getParamValue(dynamic param) {
    if (param is CyberBindingExpression) {
      try {
        return param.row[param.fieldName]?.toString() ?? '';
      } catch (e) {
        return '';
      }
    }
    return param?.toString() ?? '';
  }

  /// ✅ FIX 3.4: Removed _isUpdating flag
  void _updateValues(dynamic textValue, String displayValue) {
    if (!widget.enabled || !mounted) return;

    if (_boundTextRow != null && _boundTextField != null) {
      final originalValue = _boundTextRow![_boundTextField!];
      if (originalValue is String && textValue != null) {
        _boundTextRow![_boundTextField!] = textValue.toString();
      } else if (originalValue is int && textValue is int) {
        _boundTextRow![_boundTextField!] = textValue;
      } else if (originalValue is double && textValue is num) {
        _boundTextRow![_boundTextField!] = textValue.toDouble();
      } else {
        _boundTextRow![_boundTextField!] = textValue;
      }
    }

    if (_boundDisplayRow != null && _boundDisplayField != null) {
      _boundDisplayRow![_boundDisplayField!] = displayValue;
    }

    widget.onChanged?.call(textValue);

    // ✅ FIX 3.1: Invalidate cache sau khi update
    _invalidateCache();

    if (widget.onLeaver != null && _boundDisplayRow != null) {
      Future.delayed(Duration.zero, () {
        if (mounted) {
          widget.onLeaver!(_boundDisplayRow!);
        }
      });
    }
  }

  /// ✅ FIX 4.3: Clear values
  void _clearValues() {
    if (!widget.enabled || widget.readOnly || !mounted) return;

    _updateValues(null, '');
  }

  Future<void> _showLookup() async {
    if (!widget.enabled || widget.readOnly || !mounted) return;

    final tbName = _getParamValue(widget.tbName);
    final strFilter = _getParamValue(widget.strFilter);
    final displayField = _getParamValue(widget.displayField);
    final displayValue = _getParamValue(widget.displayValue);

    if (tbName.isEmpty || displayField.isEmpty || displayValue.isEmpty) return;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LookupBottomSheet(
        tbName: tbName,
        strFilter: strFilter,
        displayField: displayField,
        displayValue: displayValue,
        currentTextValue: _getCurrentTextValue(),
        pageSize: widget.lookupPageSize,
      ),
    );

    if (result != null && mounted) {
      _updateValues(
        result[displayValue],
        result[displayField]?.toString() ?? '',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget buildLookupWidget() {
      // ✅ FIX 3.1: KHÔNG invalidate cache mỗi build
      // Cache chỉ được invalidate khi:
      // - didUpdateWidget
      // - _updateValues
      // - ListenableBuilder notify (tự động rebuild)

      if (!_isVisible()) {
        return const SizedBox.shrink();
      }

      final displayText = _getCurrentDisplayValue();
      final hasValue = displayText.isNotEmpty;
      final checkEmpty = _isCheckEmpty();

      // ✅ FIX 4.3: Determine if widget is interactive
      final isInteractive = widget.enabled && !widget.readOnly;

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
                  // ✅ FIX 4.3: Clear button
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
                  // ✅ Search icon
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

    // ✅ Chỉ dùng ListenableBuilder khi có binding
    final listeners = <Listenable>[];
    if (_boundTextRow != null) listeners.add(_boundTextRow!);
    if (_boundDisplayRow != null && _boundDisplayRow != _boundTextRow) {
      listeners.add(_boundDisplayRow!);
    }
    if (_visibilityBoundRow != null &&
        _visibilityBoundRow != _boundTextRow &&
        _visibilityBoundRow != _boundDisplayRow) {
      listeners.add(_visibilityBoundRow!);
    }

    if (listeners.isEmpty) {
      return buildLookupWidget();
    }

    return ListenableBuilder(
      listenable: Listenable.merge(listeners),
      builder: (context, child) {
        // ✅ FIX 3.1: Invalidate cache khi listenable notify
        _invalidateCache();
        return buildLookupWidget();
      },
    );
  }
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
