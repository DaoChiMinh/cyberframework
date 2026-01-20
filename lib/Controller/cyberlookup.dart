import 'package:cyberframework/cyberframework.dart';

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

  // === CUSTOM DATA SOURCE ===
  /// Tên function custom để lấy dữ liệu (thay vì dùng CP_W10SysListoDir)
  /// Khi set, sẽ load toàn bộ data một lần và search local
  final dynamic cp_nameCus;

  /// Parameter cho custom function
  final dynamic parameterCus;

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
    this.cp_nameCus,
    this.parameterCus,
    this.label,
    this.hint,
    this.labelStyle,
    this.textStyle,
    this.icon,
    this.enabled = true,
    this.readOnly = false,
    this.allowClear = false,
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

  // === LOOKUP PARAMS BINDING ===
  CyberDataRow? _strFilterBoundRow;
  String? _strFilterBoundField;
  CyberDataRow? _tbNameBoundRow;
  String? _tbNameBoundField;
  CyberDataRow? _cp_nameCusBoundRow;
  String? _cp_nameCusBoundField;
  CyberDataRow? _parameterCusBoundRow;
  String? _parameterCusBoundField;

  // === FLAGS ===
  bool _isInternalUpdate = false;

  // === FILTER TRACKING - Để phát hiện thay đổi ===
  String? _lastStrFilter;

  @override
  void initState() {
    super.initState();

    // Khởi tạo internal controller
    _controller = _InternalLookupController();

    // Parse bindings
    _parseTextBinding();
    _parseDisplayBinding();
    _parseVisibilityBinding();
    _parseStrFilterBinding();
    _parseTbNameBinding();
    _parseCp_nameCusBinding();
    _parseParameterCusBinding();

    // Sync initial values
    _syncFromWidget();

    // Lưu filter ban đầu
    _lastStrFilter = _extractParam(widget.strFilter);

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
    if (widget.strFilter != oldWidget.strFilter) {
      _parseStrFilterBinding();
    }
    if (widget.tbName != oldWidget.tbName) {
      _parseTbNameBinding();
    }
    if (widget.cp_nameCus != oldWidget.cp_nameCus) {
      _parseCp_nameCusBinding();
    }
    if (widget.parameterCus != oldWidget.parameterCus) {
      _parseParameterCusBinding();
    }

    // Sync values
    _syncFromWidget();

    // Kiểm tra strFilter có thay đổi không
    final currentFilter = _extractParam(widget.strFilter);
    if (_lastStrFilter != currentFilter) {
      _lastStrFilter = currentFilter;
      // Nếu filter thay đổi, có thể clear values hoặc mark dirty
      // Tuỳ theo business logic của bạn
      // Ví dụ: clear values khi filter thay đổi
      if (currentFilter.isNotEmpty) {
        // Có thể clear hoặc không, tuỳ yêu cầu
        // _clearValues();
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();

    // Cleanup bindings
    _textBoundRow?.removeListener(_onTextBindingChanged);
    _displayBoundRow?.removeListener(_onDisplayBindingChanged);
    _strFilterBoundRow?.removeListener(_onStrFilterBindingChanged);
    _tbNameBoundRow?.removeListener(_onTbNameBindingChanged);
    _cp_nameCusBoundRow?.removeListener(_onCp_nameCusBindingChanged);
    _parameterCusBoundRow?.removeListener(_onParameterCusBindingChanged);

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

  void _parseStrFilterBinding() {
    // Cleanup old binding
    if (_strFilterBoundRow != null) {
      _strFilterBoundRow!.removeListener(_onStrFilterBindingChanged);
      _strFilterBoundRow = null;
      _strFilterBoundField = null;
    }

    // Parse new binding
    if (widget.strFilter is CyberBindingExpression) {
      final expr = widget.strFilter as CyberBindingExpression;
      _strFilterBoundRow = expr.row;
      _strFilterBoundField = expr.fieldName;
      _strFilterBoundRow!.addListener(_onStrFilterBindingChanged);
    }
  }

  void _parseTbNameBinding() {
    // Cleanup old binding
    if (_tbNameBoundRow != null) {
      _tbNameBoundRow!.removeListener(_onTbNameBindingChanged);
      _tbNameBoundRow = null;
      _tbNameBoundField = null;
    }

    // Parse new binding
    if (widget.tbName is CyberBindingExpression) {
      final expr = widget.tbName as CyberBindingExpression;
      _tbNameBoundRow = expr.row;
      _tbNameBoundField = expr.fieldName;
      _tbNameBoundRow!.addListener(_onTbNameBindingChanged);
    }
  }

  void _parseCp_nameCusBinding() {
    // Cleanup old binding
    if (_cp_nameCusBoundRow != null) {
      _cp_nameCusBoundRow!.removeListener(_onCp_nameCusBindingChanged);
      _cp_nameCusBoundRow = null;
      _cp_nameCusBoundField = null;
    }

    // Parse new binding
    if (widget.cp_nameCus is CyberBindingExpression) {
      final expr = widget.cp_nameCus as CyberBindingExpression;
      _cp_nameCusBoundRow = expr.row;
      _cp_nameCusBoundField = expr.fieldName;
      _cp_nameCusBoundRow!.addListener(_onCp_nameCusBindingChanged);
    }
  }

  void _parseParameterCusBinding() {
    // Cleanup old binding
    if (_parameterCusBoundRow != null) {
      _parameterCusBoundRow!.removeListener(_onParameterCusBindingChanged);
      _parameterCusBoundRow = null;
      _parameterCusBoundField = null;
    }

    // Parse new binding
    if (widget.parameterCus is CyberBindingExpression) {
      final expr = widget.parameterCus as CyberBindingExpression;
      _parameterCusBoundRow = expr.row;
      _parameterCusBoundField = expr.fieldName;
      _parameterCusBoundRow!.addListener(_onParameterCusBindingChanged);
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

  /// Sync khi strFilter binding thay đổi
  void _onStrFilterBindingChanged() {
    if (!mounted) return;

    final currentFilter = _extractParam(widget.strFilter);
    if (_lastStrFilter != currentFilter) {
      _lastStrFilter = currentFilter;

      // Tuỳ chọn: clear values khi filter thay đổi
      // if (currentFilter.isNotEmpty) {
      //   _clearValues();
      // }

      // Rebuild để UI có filter mới khi mở popup
      setState(() {});
    }
  }

  /// Sync khi tbName binding thay đổi
  void _onTbNameBindingChanged() {
    if (!mounted) return;
    // Rebuild để UI có tbName mới khi mở popup
    setState(() {});
  }

  /// Sync khi cp_nameCus binding thay đổi
  void _onCp_nameCusBindingChanged() {
    if (!mounted) return;
    // Rebuild để UI có cp_nameCus mới khi mở popup
    setState(() {});
  }

  /// Sync khi parameterCus binding thay đổi
  void _onParameterCusBindingChanged() {
    if (!mounted) return;
    // Rebuild để UI có parameterCus mới khi mở popup
    setState(() {});
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

    // Get lookup parameters - LUÔN EXTRACT GIÁ TRỊ MỚI NHẤT
    final tbName = _extractParam(widget.tbName);
    final strFilter = _extractParam(widget.strFilter);
    final displayField = _extractParam(widget.displayField);
    final valueField = _extractParam(widget.displayValue);
    final pageSize = widget.lookupPageSize;
    final cp_nameCus = _extractParam(widget.cp_nameCus);
    final parameterCus = _extractParam(widget.parameterCus);

    if (displayField.isEmpty || valueField.isEmpty) return;

    // Kiểm tra: nếu dùng custom function thì bắt buộc có cp_nameCus
    // Nếu không dùng custom thì bắt buộc có tbName
    if (cp_nameCus.isEmpty && tbName.isEmpty) return;

    // Get current value
    final currentTextValue = _controller.textValue;

    // Tạo unique key để force reload nếu strFilter khác null/trắng
    // Điều này đảm bảo popup sẽ load data mới mỗi lần mở
    final lookupKey = cp_nameCus.isNotEmpty
        ? '${cp_nameCus}_${parameterCus}_${DateTime.now().millisecondsSinceEpoch}'
        : (strFilter.isNotEmpty
              ? '${tbName}_${strFilter}_${DateTime.now().millisecondsSinceEpoch}'
              : tbName);

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LookupBottomSheet(
        key: ValueKey(lookupKey), // Force rebuild nếu filter thay đổi
        tbName: tbName,
        strFilter: strFilter,
        displayField: displayField,
        displayValue: valueField,
        currentTextValue: currentTextValue,
        pageSize: pageSize,
        cp_nameCus: cp_nameCus,
        parameterCus: parameterCus,
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
            widget.onLeaver!(result);
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

    // Dùng ListenableBuilder cho các bindings động
    final hasBindings =
        _visibilityBoundRow != null ||
        _strFilterBoundRow != null ||
        _tbNameBoundRow != null ||
        _cp_nameCusBoundRow != null ||
        _parameterCusBoundRow != null;

    if (hasBindings) {
      return ListenableBuilder(
        listenable: Listenable.merge([
          if (_visibilityBoundRow != null) _visibilityBoundRow!,
          if (_strFilterBoundRow != null) _strFilterBoundRow!,
          if (_tbNameBoundRow != null) _tbNameBoundRow!,
          if (_cp_nameCusBoundRow != null) _cp_nameCusBoundRow!,
          if (_parameterCusBoundRow != null) _parameterCusBoundRow!,
        ]),
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
// LOOKUP BOTTOM SHEET - VIRTUAL PAGING + CUSTOM DATA SOURCE
// ============================================================================

class _LookupBottomSheet extends StatefulWidget {
  final String tbName;
  final String strFilter;
  final String displayField;
  final String displayValue;
  final dynamic currentTextValue;
  final int pageSize;
  final String cp_nameCus;
  final String parameterCus;

  const _LookupBottomSheet({
    super.key,
    required this.tbName,
    required this.strFilter,
    required this.displayField,
    required this.displayValue,
    this.currentTextValue,
    this.pageSize = 50,
    this.cp_nameCus = '',
    this.parameterCus = '',
  });

  @override
  State<_LookupBottomSheet> createState() => _LookupBottomSheetState();
}

class _LookupBottomSheetState extends State<_LookupBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  late ScrollController _scrollController;

  // ALL DATA - dùng khi custom data source
  final List<CyberDataRow> _allRows = [];

  // FILTERED DATA - dùng cho hiển thị
  final List<CyberDataRow> _rows = [];

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 0;
  String _currentSearchText = '';

  bool _isMultiSelect = false;
  final Set<int> _selectedIndices = {};

  Timer? _searchDebounceTimer;

  // Custom data source mode
  bool get _isCustomMode => widget.cp_nameCus.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Chỉ listen scroll khi KHÔNG dùng custom mode
    if (!_isCustomMode) {
      _scrollController.addListener(_onScroll);
    }

    // QUAN TRỌNG: Mỗi khi mở popup, LUÔN load data mới
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
    _allRows.clear();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;

    _currentPage = 0;

    setState(() {
      _isLoading = true;
      _rows.clear();
      _allRows.clear();
      _selectedIndices.clear();
      _hasMoreData = true;
    });

    if (_isCustomMode) {
      // Custom mode: load toàn bộ data một lần
      await _loadCustomData();
    } else {
      // Standard mode: load page đầu tiên
      await _loadPage(_currentPage);
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Load data từ custom function (load toàn bộ một lần)
  Future<void> _loadCustomData() async {
    if (!mounted) return;

    try {
      final response = await context.callApi(
        functionName: widget.cp_nameCus,
        parameter: widget.parameterCus,
        showLoading: false,
      );

      if (!mounted) return;

      if (response.isValid()) {
        final ds = response.toCyberDataset();
        if (ds != null) {
          final dt = ds[0];

          if (dt != null) {
            final hasIschon = dt.containerColumn("ischon");
            final allRows = dt.rows;

            if (mounted) {
              setState(() {
                _isMultiSelect = hasIschon;
                _allRows.clear();
                _allRows.addAll(allRows);

                // Filter local nếu có search text
                _filterLocalData();

                // Custom mode: không có load more
                _hasMoreData = false;
              });
            }
          } else {
            if (mounted) {
              setState(() {
                _hasMoreData = false;
              });
            }
          }
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

  /// Filter data local khi ở custom mode
  void _filterLocalData() {
    if (_currentSearchText.isEmpty) {
      // Không có search text -> hiển thị tất cả
      _rows.clear();
      _rows.addAll(_allRows);
    } else {
      // Có search text -> filter
      final searchLower = _currentSearchText.toLowerCase();
      _rows.clear();

      for (var row in _allRows) {
        final displayText =
            row[widget.displayField]?.toString().toLowerCase() ?? '';
        final valueText =
            row[widget.displayValue]?.toString().toLowerCase() ?? '';

        if (displayText.contains(searchLower) ||
            valueText.contains(searchLower)) {
          _rows.add(row);
        }
      }
    }

    // Clear selected indices vì filtered list đã thay đổi
    _selectedIndices.clear();
  }

  Future<void> _loadMore() async {
    // Custom mode: không có load more
    if (_isCustomMode) return;

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
            "$pageIndex#${widget.pageSize}#$filter#${widget.strFilter}#${widget.tbName}##",
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

    if (_isCustomMode) {
      // Custom mode: search local ngay lập tức (không debounce)
      _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        if (_searchController.text == value) {
          setState(() {
            _currentSearchText = value;
            _filterLocalData();
          });
        }
      });
    } else {
      // Standard mode: search với API (có debounce)
      _searchDebounceTimer = Timer(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        if (_searchController.text == value &&
            (value.isEmpty || value.length > 3)) {
          _currentSearchText = value;
          _loadInitialData();
        }
      });
    }
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
          hintText: _isCustomMode
              ? 'Tìm trong danh sách...'
              : 'Nhập từ khóa tìm kiếm...',
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
    // Custom mode: không có loading more indicator
    final itemCount = _isCustomMode
        ? _rows.length
        : _rows.length + (_isLoadingMore ? 1 : 0);

    return ListView.separated(
      controller: _scrollController,
      cacheExtent: 500,
      itemCount: itemCount,
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
