import 'package:flutter/material.dart';

class CyberGrid extends StatelessWidget {
  final List<GridRow> children;
  final double? columhspac;
  final double? rowSpac;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  
  /// Chiều cao tổng của grid
  final double? height;
  
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
    
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
      ),
      child: Padding(
        padding: effectivePadding,
        child: height != null && heightRows != null
            ? _buildWithHeightRows(effectivePadding)
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _buildRows(),
              ),
      ),
    );
  }

  /// Build rows với height management
  Widget _buildWithHeightRows(EdgeInsetsGeometry effectivePadding) {
    // Calculate available height (trừ padding)
    final paddingVertical = effectivePadding is EdgeInsets 
        ? effectivePadding.top + effectivePadding.bottom 
        : 16.0;
    
    final availableHeight = height! - paddingVertical;
    
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
        rows.add(
          SizedBox(
            height: rowHeight,
            child: children[i],
          ),
        );
      }
      
      // Add spacing
      if (i < children.length - 1 && rowSpac != null) {
        rows.add(SizedBox(height: rowSpac));
      }
    }
    
    return SizedBox(
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: rows,
      ),
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
    
    return _calculateHeights(rowDefs, availableHeight);
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
