import 'package:flutter/material.dart';

class CyberGrid extends StatelessWidget {
  final List<GridRow> children;
  final double? columhspac;
  final double? rowSpac;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;

  /// Chiều cao tổng của grid
  /// null hoặc "*" = fill toàn bộ parent
  /// Number = chiều cao cố định
  final dynamic height;

  /// Định nghĩa chiều cao cho từng row
  /// Format: "*,*" hoặc "*,Auto,*" hoặc "*,60,*"
  /// * = tự động chia đều phần còn lại
  /// Auto = tự động theo content
  /// Number = chiều cao cố định
  final String? heightRows;

  const CyberGrid({
    super.key,
    required this.children,
    this.columhspac = 3.0,
    this.rowSpac = 12,
    this.padding,
    this.backgroundColor,
    this.height,
    this.heightRows,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? EdgeInsets.all(8.0);

    // Check if height is "*" or null (fill parent)
    final bool shouldFillParent =
        height == null || height == "*" || (height is String && height == "*");

    // Parse numeric height if provided
    final double? numericHeight = _parseHeight();

    Widget content = DecoratedBox(
      decoration: BoxDecoration(color: backgroundColor ?? Colors.transparent),
      child: Padding(
        padding: effectivePadding,
        child: numericHeight != null && heightRows != null
            ? _buildWithHeightRows(effectivePadding, numericHeight)
            : (shouldFillParent && heightRows != null)
            ? _buildWithHeightRowsExpanded(effectivePadding)
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _buildRows(),
              ),
      ),
    );

    // Wrap with Expanded if should fill parent
    if (shouldFillParent && heightRows != null) {
      return content;
    } else if (shouldFillParent) {
      return Expanded(child: content);
    } else if (numericHeight != null) {
      return SizedBox(height: numericHeight, child: content);
    }

    return content;
  }

  /// Parse height to double
  double? _parseHeight() {
    if (height == null ||
        height == "*" ||
        (height is String && height == "*")) {
      return null;
    }

    if (height is double) return height;
    if (height is int) return height.toDouble();
    if (height is String) {
      return double.tryParse(height);
    }

    return null;
  }

  /// Build rows với height management
  Widget _buildWithHeightRows(
    EdgeInsetsGeometry effectivePadding,
    double totalHeight,
  ) {
    // Calculate available height (trừ padding)
    final paddingVertical = effectivePadding is EdgeInsets
        ? effectivePadding.top + effectivePadding.bottom
        : 16.0;

    final availableHeight = totalHeight - paddingVertical;

    // Parse heightRows
    final rowHeights = _parseHeightRows(heightRows!, availableHeight);

    // Build rows with calculated heights
    final List<Widget> rows = [];

    for (int i = 0; i < children.length && i < rowHeights.length; i++) {
      final rowHeight = rowHeights[i];

      if (rowHeight == -1) {
        // Auto height
        rows.add(children[i]);
      } else {
        // Fixed or star height
        rows.add(SizedBox(height: rowHeight, child: children[i]));
      }

      // Add spacing
      if (i < children.length - 1 && rowSpac != null) {
        rows.add(SizedBox(height: rowSpac));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  /// Build rows với height management (fill parent mode)
  Widget _buildWithHeightRowsExpanded(EdgeInsetsGeometry effectivePadding) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final paddingVertical = effectivePadding is EdgeInsets
            ? effectivePadding.top + effectivePadding.bottom
            : 16.0;

        final availableHeight = constraints.maxHeight - paddingVertical;

        // Parse heightRows
        final rowHeights = _parseHeightRows(heightRows!, availableHeight);

        // Build rows with calculated heights
        final List<Widget> rows = [];

        for (int i = 0; i < children.length && i < rowHeights.length; i++) {
          final rowHeight = rowHeights[i];

          if (rowHeight == -1) {
            // Auto height
            rows.add(children[i]);
          } else if (rowHeight == -2) {
            // Star height in fill parent mode - use Expanded
            rows.add(Expanded(child: children[i]));
          } else {
            // Fixed height
            rows.add(SizedBox(height: rowHeight, child: children[i]));
          }

          // Add spacing
          if (i < children.length - 1 && rowSpac != null) {
            rows.add(SizedBox(height: rowSpac));
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      },
    );
  }

  /// Parse heightRows definition và calculate heights
  List<double> _parseHeightRows(String definition, double availableHeight) {
    final parts = definition.split(',').map((s) => s.trim()).toList();
    final List<_RowHeight> rowDefs = [];

    // Parse definitions
    for (var part in parts) {
      if (part.toLowerCase() == 'auto') {
        rowDefs.add(_RowHeight(type: _HeightType.auto));
      } else if (part.endsWith('*')) {
        final multiplier = part == '*'
            ? 1.0
            : double.tryParse(part.substring(0, part.length - 1)) ?? 1.0;
        rowDefs.add(_RowHeight(type: _HeightType.star, value: multiplier));
      } else {
        final fixedHeight = double.tryParse(part) ?? 0.0;
        rowDefs.add(_RowHeight(type: _HeightType.fixed, value: fixedHeight));
      }
    }

    // Check if we're in fill parent mode (infinite height from LayoutBuilder)
    final bool isFillParentMode =
        availableHeight == double.infinity || availableHeight > 999999;

    if (isFillParentMode) {
      return _calculateHeightsForFillMode(rowDefs);
    } else {
      return _calculateHeights(rowDefs, availableHeight);
    }
  }

  /// Calculate heights for fill parent mode
  List<double> _calculateHeightsForFillMode(List<_RowHeight> defs) {
    final List<double> heights = [];

    for (var def in defs) {
      if (def.type == _HeightType.fixed) {
        heights.add(def.value);
      } else if (def.type == _HeightType.auto) {
        heights.add(-1); // Marker for auto
      } else if (def.type == _HeightType.star) {
        heights.add(-2); // Marker for Expanded (star in fill mode)
      }
    }

    return heights;
  }

  /// Calculate actual heights for rows
  List<double> _calculateHeights(List<_RowHeight> defs, double available) {
    double usedHeight = 0.0;
    double totalStarMultiplier = 0.0;
    final List<double> heights = List.filled(defs.length, 0.0);

    // Subtract spacing from available height
    final totalSpacing = rowSpac != null ? rowSpac! * (defs.length - 1) : 0.0;
    available -= totalSpacing;

    // First pass: calculate fixed heights
    for (int i = 0; i < defs.length; i++) {
      if (defs[i].type == _HeightType.fixed) {
        heights[i] = defs[i].value;
        usedHeight += defs[i].value;
      } else if (defs[i].type == _HeightType.auto) {
        heights[i] = -1; // Marker for auto
      } else if (defs[i].type == _HeightType.star) {
        totalStarMultiplier += defs[i].value;
      }
    }

    // Second pass: calculate star heights
    if (totalStarMultiplier > 0) {
      final remainingHeight = available - usedHeight;
      final starUnit = remainingHeight / totalStarMultiplier;

      for (int i = 0; i < defs.length; i++) {
        if (defs[i].type == _HeightType.star) {
          heights[i] = starUnit * defs[i].value;
        }
      }
    }

    return heights;
  }

  List<Widget> _buildRows() {
    final List<Widget> rows = [];

    for (int i = 0; i < children.length; i++) {
      rows.add(children[i]);

      // Thêm spacing giữa các rows
      if (i < children.length - 1 && rowSpac != null) {
        rows.add(SizedBox(height: rowSpac));
      }
    }

    return rows;
  }
}

class GridRow extends StatelessWidget {
  final String widthColumn;
  final List<Widget> columns;
  final MainAxisAlignment? mainAxisAlignment;
  final CrossAxisAlignment? crossAxisAlignment;
  final double? spacing;

  const GridRow({
    super.key,
    required this.widthColumn,
    required this.columns,
    this.mainAxisAlignment,
    this.crossAxisAlignment,
    this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidths = _parseWidthColumn(
          widthColumn,
          constraints.maxWidth,
        );

        return Row(
          mainAxisAlignment: mainAxisAlignment ?? MainAxisAlignment.start,
          crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.center,
          children: _buildColumns(columnWidths),
        );
      },
    );
  }

  List<Widget> _buildColumns(List<double> widths) {
    final List<Widget> widgets = [];

    for (int i = 0; i < columns.length && i < widths.length; i++) {
      if (widths[i] == -1) {
        widgets.add(columns[i]);
      } else {
        widgets.add(SizedBox(width: widths[i], child: columns[i]));
      }

      if (i < columns.length - 1 && spacing != null) {
        widgets.add(SizedBox(width: spacing));
      }
    }

    return widgets;
  }

  List<double> _parseWidthColumn(String definition, double availableWidth) {
    final parts = definition.split(',').map((s) => s.trim()).toList();
    final List<_ColumnWidth> columnDefs = [];

    // Parse definitions
    for (var part in parts) {
      if (part.toLowerCase() == 'auto') {
        columnDefs.add(_ColumnWidth(type: _WidthType.auto));
      } else if (part.endsWith('*')) {
        final multiplier = part == '*'
            ? 1.0
            : double.tryParse(part.substring(0, part.length - 1)) ?? 1.0;
        columnDefs.add(_ColumnWidth(type: _WidthType.star, value: multiplier));
      } else {
        final fixedWidth = double.tryParse(part) ?? 0.0;
        columnDefs.add(_ColumnWidth(type: _WidthType.fixed, value: fixedWidth));
      }
    }

    return _calculateWidths(columnDefs, availableWidth);
  }

  List<double> _calculateWidths(List<_ColumnWidth> defs, double available) {
    double usedWidth = 0.0;
    double totalStarMultiplier = 0.0;
    final List<double> widths = List.filled(defs.length, 0.0);

    final totalSpacing = spacing != null ? spacing! * (defs.length - 1) : 0.0;
    available -= totalSpacing;

    for (int i = 0; i < defs.length; i++) {
      if (defs[i].type == _WidthType.fixed) {
        widths[i] = defs[i].value;
        usedWidth += defs[i].value;
      } else if (defs[i].type == _WidthType.auto) {
        widths[i] = -1; // Marker for auto
      } else if (defs[i].type == _WidthType.star) {
        totalStarMultiplier += defs[i].value;
      }
    }

    if (totalStarMultiplier > 0) {
      final remainingWidth = available - usedWidth;
      final starUnit = remainingWidth / totalStarMultiplier;

      for (int i = 0; i < defs.length; i++) {
        if (defs[i].type == _WidthType.star) {
          widths[i] = starUnit * defs[i].value;
        }
      }
    }

    return widths;
  }
}

class _ColumnWidth {
  final _WidthType type;
  final double value;
  _ColumnWidth({required this.type, this.value = 0.0});
}

enum _WidthType { auto, star, fixed }

class _RowHeight {
  final _HeightType type;
  final double value;
  _RowHeight({required this.type, this.value = 0.0});
}

enum _HeightType { auto, star, fixed }
