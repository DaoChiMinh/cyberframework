import 'package:flutter/material.dart';

// ============================================================================
// MODEL - CyberGridRow
// ============================================================================

/// Model cho mỗi row trong CyberGrid
class CyberGridRow {
  /// Khai báo chiều rộng các columns (VD: "*;Auto;100;2*")
  final String widthColumns;

  /// Danh sách các widget con
  final List<Widget> children;

  /// Padding bên trong row
  final EdgeInsets? padding;

  /// Margin bên ngoài row
  final EdgeInsets? margin;

  /// Màu nền của row
  final Color? backgroundColor;

  /// Có cho phép scroll ngang nếu nội dung tràn không
  final bool enableHorizontalScroll;

  const CyberGridRow({
    required this.widthColumns,
    required this.children,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.enableHorizontalScroll = false,
  });
}

// ============================================================================
// MAIN WIDGET - CyberGrid
// ============================================================================

class CyberGrid extends StatelessWidget {
  /// Chiều rộng (null = fill parent, số cụ thể = fixed width)
  final double? width;

  /// Chiều cao (null = fill parent, số cụ thể = fixed height)
  final double? height;

  /// Khai báo chiều cao các rows
  final String heightRows;

  /// Padding bên trong grid
  final EdgeInsets? padding;

  /// Margin bên ngoài grid
  final EdgeInsets? margin;

  /// Màu nền của grid
  final Color? backgroundColor;

  /// Khoảng cách giữa các rows
  final double rowSpace;

  /// Danh sách các rows
  final List<CyberGridRow> rows;

  const CyberGrid({
    super.key,
    this.width,
    this.height,
    required this.heightRows,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.rowSpace = 0,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    // Parse height definitions
    final heightDefs = _parseDefinitions(heightRows);

    // Validate
    if (heightDefs.length != rows.length) {
      return Container(
        margin: margin,
        padding: padding,
        color: Colors.red[100],
        child: Center(
          child: Text(
            'CyberGrid Error: heightRows (${heightDefs.length}) không khớp với rows (${rows.length})',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    // ✅ Check nếu tất cả rows đều là Auto -> Dùng wrap mode
    final allAuto = heightDefs.every(
      (def) => def.type == _GridDefinitionType.auto,
    );

    return Container(
      width: width ?? double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(color: backgroundColor),
      // ✅ Không set height nếu dùng wrap mode
      height: allAuto ? null : height,
      child: allAuto
          ? _buildWrapContent(heightDefs)
          : _buildWithConstraints(heightDefs),
    );
  }

  /// Build mode: Wrap content (tất cả rows Auto)
  Widget _buildWrapContent(List<_GridDefinition> heightDefs) {
    final children = <Widget>[];

    for (int i = 0; i < rows.length; i++) {
      if (i > 0 && rowSpace > 0) {
        children.add(SizedBox(height: rowSpace));
      }
      children.add(_buildRow(rows[i], null)); // null = auto height
    }

    return Column(
      mainAxisSize: MainAxisSize.min, // ✅ Quan trọng!
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  /// Build mode: With constraints (có star hoặc fixed)
  Widget _buildWithConstraints(List<_GridDefinition> heightDefs) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = height ?? constraints.maxHeight;
        final totalSpacing = rowSpace * (rows.length - 1);
        final availableForRows = availableHeight - totalSpacing;

        // Calculate heights
        final rowHeights = _calculateSizes(heightDefs, availableForRows);

        final children = <Widget>[];

        for (int i = 0; i < rows.length; i++) {
          if (i > 0 && rowSpace > 0) {
            children.add(SizedBox(height: rowSpace));
          }
          children.add(_buildRow(rows[i], rowHeights[i]));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        );
      },
    );
  }

  /// Build một row
  Widget _buildRow(CyberGridRow row, double? rowHeight) {
    final widthDefs = _parseDefinitions(row.widthColumns);

    // Validate
    if (widthDefs.length != row.children.length) {
      return Container(
        height: rowHeight,
        margin: row.margin,
        padding: row.padding,
        color: Colors.red[100],
        child: Center(
          child: Text(
            'Row Error: widthColumns (${widthDefs.length}) không khớp với children (${row.children.length})',
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ),
      );
    }

    Widget rowContent = Container(
      height: rowHeight, // null nếu auto
      margin: row.margin,
      padding: row.padding,
      decoration: BoxDecoration(color: row.backgroundColor),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return _buildRowContent(
            row,
            widthDefs,
            constraints.maxWidth,
            rowHeight,
          );
        },
      ),
    );

    return rowContent;
  }

  /// Build row content
  Widget _buildRowContent(
    CyberGridRow row,
    List<_GridDefinition> widthDefs,
    double availableWidth,
    double? rowHeight,
  ) {
    // Calculate widths
    final columnWidths = _calculateSizes(widthDefs, availableWidth);

    // Build columns
    final children = <Widget>[];
    for (int i = 0; i < row.children.length; i++) {
      children.add(SizedBox(width: columnWidths[i], child: row.children[i]));
    }

    Widget content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );

    // Wrap với scroll nếu needed
    if (row.enableHorizontalScroll) {
      content = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      );
    }

    // Wrap với vertical scroll nếu có rowHeight
    if (rowHeight != null) {
      content = SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: rowHeight),
          child: content,
        ),
      );
    }

    return content;
  }

  /// Parse definitions
  List<_GridDefinition> _parseDefinitions(String definitions) {
    if (definitions.isEmpty) return [];

    return definitions.split(';').map((def) {
      final trimmed = def.trim();

      if (trimmed.toLowerCase() == 'auto') {
        return _GridDefinition(type: _GridDefinitionType.auto);
      }

      if (trimmed.endsWith('*')) {
        final starValue = trimmed.replaceAll('*', '').trim();
        final coefficient = starValue.isEmpty
            ? 1.0
            : double.tryParse(starValue) ?? 1.0;
        return _GridDefinition(
          type: _GridDefinitionType.star,
          value: coefficient,
        );
      }

      final fixedSize = double.tryParse(trimmed);
      if (fixedSize != null) {
        return _GridDefinition(
          type: _GridDefinitionType.fixed,
          value: fixedSize,
        );
      }

      return _GridDefinition(type: _GridDefinitionType.auto);
    }).toList();
  }

  /// Calculate sizes
  List<double> _calculateSizes(
    List<_GridDefinition> definitions,
    double availableSize,
  ) {
    double totalFixed = 0;
    for (var def in definitions) {
      if (def.type == _GridDefinitionType.fixed) {
        totalFixed += def.value;
      }
    }

    double totalStarCoefficient = 0;
    for (var def in definitions) {
      if (def.type == _GridDefinitionType.star) {
        totalStarCoefficient += def.value;
      }
    }

    double remainingSpace = availableSize - totalFixed;

    final sizes = <double>[];

    for (var def in definitions) {
      switch (def.type) {
        case _GridDefinitionType.fixed:
          sizes.add(def.value);
          break;

        case _GridDefinitionType.star:
          if (totalStarCoefficient > 0) {
            final starSize =
                (remainingSpace * def.value) / totalStarCoefficient;
            sizes.add(starSize.clamp(0, double.infinity));
          } else {
            sizes.add(0);
          }
          break;

        case _GridDefinitionType.auto:
          sizes.add(0);
          break;
      }
    }

    return sizes;
  }
}

// ============================================================================
// INTERNAL - Grid Definition Model
// ============================================================================

enum _GridDefinitionType { auto, star, fixed }

class _GridDefinition {
  final _GridDefinitionType type;
  final double value;

  _GridDefinition({required this.type, this.value = 0});
}
