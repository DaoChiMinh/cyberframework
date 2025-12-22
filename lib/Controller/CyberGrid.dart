import 'package:flutter/material.dart';

class CyberGrid extends StatelessWidget {
  final List<GridRow> children;
  final double? columhspac;
  final double? rowSpac;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  const CyberGrid({
    super.key,
    required this.children,
    this.columhspac = 3.0,
    this.rowSpac = 12,
    this.padding,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.transparent,
        //borderRadius: BorderRadius.circular(0),
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: _buildRows(),
        ),
      ),
    );
    // return Padding(
    //   padding: padding ?? EdgeInsets.zero,
    //   child: Column(
    //     mainAxisSize: MainAxisSize.min,
    //     crossAxisAlignment: CrossAxisAlignment.stretch,
    //     children: _buildRows(),
    //   ),
    // );
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
