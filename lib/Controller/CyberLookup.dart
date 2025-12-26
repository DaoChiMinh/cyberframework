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
  final Function(dynamic)? onLeaver;
  final ValueChanged<dynamic>? onChanged;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool isShowLabel;
  final dynamic isVisible;
  final dynamic isCheckEmpty;
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
    this.onLeaver,
    this.onChanged,
    this.backgroundColor,
    this.borderColor,
    this.isShowLabel = true,
    this.isVisible = true,
    this.isCheckEmpty = false,
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
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _parseBindings();
    _parseVisibilityBinding();
    if (_boundTextRow != null) _boundTextRow!.addListener(_onBindingChanged);
    if (_boundDisplayRow != null && _boundDisplayRow != _boundTextRow) {
      _boundDisplayRow!.addListener(_onBindingChanged);
    }
    if (_visibilityBoundRow != null && _visibilityBoundRow != _boundTextRow) {
      _visibilityBoundRow!.addListener(_onBindingChanged);
    }
  }

  @override
  void dispose() {
    if (_boundTextRow != null) _boundTextRow!.removeListener(_onBindingChanged);
    if (_boundDisplayRow != null && _boundDisplayRow != _boundTextRow) {
      _boundDisplayRow!.removeListener(_onBindingChanged);
    }
    if (_visibilityBoundRow != null && _visibilityBoundRow != _boundTextRow) {
      _visibilityBoundRow!.removeListener(_onBindingChanged);
    }
    super.dispose();
  }

  void _parseBindings() {
    if (widget.text is CyberBindingExpression) {
      final expr = widget.text as CyberBindingExpression;
      _boundTextRow = expr.row;
      _boundTextField = expr.fieldName;
    }
    if (widget.display is CyberBindingExpression) {
      final expr = widget.display as CyberBindingExpression;
      _boundDisplayRow = expr.row;
      _boundDisplayField = expr.fieldName;
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

  bool _parseBool(dynamic value) {
    if (value == null) return true;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase().trim();
      if (lower == "1" || lower == "true") return true;
      if (lower == "0" || lower == "false") return false;
      return true;
    }
    return true;
  }

  bool _isCheckEmpty() {
    return _parseBool(widget.isCheckEmpty);
  }

  bool _isVisible() {
    if (_visibilityBoundRow != null && _visibilityBoundField != null) {
      return _parseBool(_visibilityBoundRow![_visibilityBoundField!]);
    }
    return _parseBool(widget.isVisible);
  }

  void _onBindingChanged() {
    if (_isUpdating) return;
    setState(() {});
  }

  dynamic _getCurrentTextValue() {
    if (widget.text is CyberBindingExpression) {
      final expr = widget.text as CyberBindingExpression;
      if (_boundTextRow != expr.row || _boundTextField != expr.fieldName) {
        _boundTextRow = expr.row;
        _boundTextField = expr.fieldName;
      }
    }
    if (_boundTextRow != null && _boundTextField != null) {
      try {
        return _boundTextRow![_boundTextField!];
      } catch (e) {
        return null;
      }
    } else if (widget.text != null && widget.text is! CyberBindingExpression) {
      return widget.text;
    }
    return null;
  }

  String _getCurrentDisplayValue() {
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
        return _boundDisplayRow![_boundDisplayField!]?.toString() ?? '';
      } catch (e) {
        return '';
      }
    } else if (widget.display != null &&
        widget.display is! CyberBindingExpression) {
      return widget.display?.toString() ?? '';
    }
    return '';
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

  void _updateValues(dynamic textValue, String displayValue) {
    if (!widget.enabled) return;
    _isUpdating = true;
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
    _isUpdating = false;
    setState(() {});
    if (widget.onLeaver != null) {
      Future.delayed(Duration.zero, () => widget.onLeaver!(_boundDisplayRow!));
    }
  }

  Future<void> _showLookup() async {
    if (!widget.enabled) return;
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
      ),
    );

    if (result != null) {
      _updateValues(
        result[displayValue],
        result[displayField]?.toString() ?? '',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible()) {
      return const SizedBox.shrink();
    }
    Widget buildLookup() {
      final displayText = _getCurrentDisplayValue();
      final hasValue = displayText.isNotEmpty;
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
                  if (_isCheckEmpty())
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
            onTap: widget.enabled ? _showLookup : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                // ✅ Background đồng bộ, bỏ border
                color: widget.enabled
                    ? (widget.backgroundColor ?? const Color(0xFFF5F5F5))
                    : const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      color: widget.enabled
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
                                ? (widget.enabled
                                      ? Colors.black87
                                      : Colors.grey)
                                : Colors.grey[500],
                          ),
                    ),
                  ),
                  Icon(
                    Icons.search,
                    color: widget.enabled ? Colors.grey[600] : Colors.grey[400],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final listeners = <Listenable>[];
    if (_boundTextRow != null) listeners.add(_boundTextRow!);
    if (_boundDisplayRow != null && _boundDisplayRow != _boundTextRow) {
      listeners.add(_boundDisplayRow!);
    }
    if (listeners.isNotEmpty) {
      return ListenableBuilder(
        listenable: Listenable.merge(listeners),
        builder: (context, child) => buildLookup(),
      );
    }
    return buildLookup();
  }
}

class _LookupBottomSheet extends StatefulWidget {
  final String tbName;
  final String strFilter;
  final String displayField;
  final String displayValue;
  final dynamic currentTextValue;

  const _LookupBottomSheet({
    required this.tbName,
    required this.strFilter,
    required this.displayField,
    required this.displayValue,
    this.currentTextValue,
  });

  @override
  State<_LookupBottomSheet> createState() => _LookupBottomSheetState();
}

class _LookupBottomSheetState extends State<_LookupBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  CyberDataTable? _dataTable;
  bool _isLoading = false;

  bool _isMultiSelect = false;
  final Set<int> _selectedIndices = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData({String? searchText}) async {
    setState(() {
      _isLoading = true;
      _selectedIndices.clear();
    });

    try {
      final filter = searchText ?? '';

      final response = await context.callApi(
        functionName: "CP_W10SysListoDir",
        parameter: "1#0#$filter#${widget.strFilter}#${widget.tbName}#01#dungnt",
        showLoading: false,
      );

      if (response.isValid()) {
        CyberDataset? ds = response.toCyberDataset();
        if (ds != null) {
          CyberDataTable? dt = ds[0];

          bool hasIschon = dt!.containerColumn("ischon");
          setState(() {
            _dataTable = dt;
            _isMultiSelect = hasIschon;
            _isLoading = false;
          });
        } else {
          setState(() {
            _dataTable = CyberDataTable(tableName: widget.tbName);
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _dataTable = CyberDataTable(tableName: widget.tbName);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _dataTable = CyberDataTable(tableName: widget.tbName);
        _isLoading = false;
      });
    }
  }

  void _onSearch(String value) {
    Future.delayed(Duration(milliseconds: 800), () {
      if (_searchController.text == value &&
          (value == "" || value.length > 3)) {
        _loadData(searchText: value);
      }
    });
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _onSelectRow(CyberDataRow row) {
    Navigator.pop(context, {
      widget.displayField: row[widget.displayField],
      widget.displayValue: row[widget.displayValue],
    });
  }

  void _onConfirmMultiSelect() {
    if (_selectedIndices.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Vui lòng chọn ít nhất 1 mục')));
      return;
    }
    List<String> displayValues = [];
    List<String> textValues = [];
    final sortedIndices = _selectedIndices.toList()..sort();
    for (var index in sortedIndices) {
      final row = _dataTable![index];
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _isMultiSelect ? 'Chọn nhiều mục' : 'Tìm kiếm',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                if (_isMultiSelect && _selectedIndices.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      'Đã chọn: ${_selectedIndices.length}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Nhập từ khóa tìm kiếm...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: _onSearch,
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _dataTable == null || _dataTable!.rowCount == 0
                ? Center(
                    child: Text(
                      'Không có dữ liệu',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    itemCount: _dataTable!.rowCount,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 1,
                      color: Colors.grey[200],
                    ),
                    itemBuilder: (context, index) {
                      final row = _dataTable![index];
                      final displayText =
                          row[widget.displayField]?.toString() ?? '';
                      final valueText =
                          row[widget.displayValue]?.toString() ?? '';
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
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            valueText,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
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
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          valueText,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        onTap: () => _onSelectRow(row),
                      );
                    },
                  ),
          ),
          if (_isMultiSelect) ...[
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: Offset(0, -5),
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
