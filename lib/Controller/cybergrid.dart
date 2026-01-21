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

  /// Khoảng cách giữa các columns
  final double space;

  const CyberGridRow({
    required this.widthColumns,
    required this.children,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.enableHorizontalScroll = false,
    this.space = 8,
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
    this.rowSpace = 8,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    // Parse height definitions
    final heightDefs = _parseDefinitions(heightRows);

    // ✅ Auto-adjust: Lấy số lượng nhỏ hơn giữa heightDefs và rows
    final effectiveCount = heightDefs.length < rows.length
        ? heightDefs.length
        : rows.length;

    // Nếu không có gì để render
    if (effectiveCount == 0) {
      return Container(
        width: width ?? double.infinity,
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(color: backgroundColor),
      );
    }

    // Lấy subset phù hợp
    final effectiveHeightDefs = heightDefs.take(effectiveCount).toList();
    final effectiveRows = rows.take(effectiveCount).toList();

    // ✅ Check nếu tất cả rows đều là Auto -> Dùng wrap mode
    final allAuto = effectiveHeightDefs.every(
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
          ? _buildWrapContent(effectiveHeightDefs, effectiveRows)
          : _buildWithConstraints(effectiveHeightDefs, effectiveRows),
    );
  }

  /// Build mode: Wrap content (tất cả rows Auto)
  Widget _buildWrapContent(
    List<_GridDefinition> heightDefs,
    List<CyberGridRow> effectiveRows,
  ) {
    final children = <Widget>[];

    for (int i = 0; i < effectiveRows.length; i++) {
      if (i > 0 && rowSpace > 0) {
        children.add(SizedBox(height: rowSpace));
      }
      children.add(_buildRow(effectiveRows[i], null)); // null = auto height
    }

    return Column(
      mainAxisSize: MainAxisSize.min, // ✅ Quan trọng!
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  /// Build mode: With constraints (có star hoặc fixed)
  Widget _buildWithConstraints(
    List<_GridDefinition> heightDefs,
    List<CyberGridRow> effectiveRows,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = height ?? constraints.maxHeight;
        final totalSpacing = rowSpace * (effectiveRows.length - 1);
        final availableForRows = availableHeight - totalSpacing;

        // Calculate heights
        final rowHeights = _calculateSizes(heightDefs, availableForRows);

        final children = <Widget>[];

        for (int i = 0; i < effectiveRows.length; i++) {
          if (i > 0 && rowSpace > 0) {
            children.add(SizedBox(height: rowSpace));
          }

          // ✅ FIX: Nếu là Auto row, không set height constraint
          final rowWidget = heightDefs[i].type == _GridDefinitionType.auto
              ? _buildRow(effectiveRows[i], null)
              : _buildRow(effectiveRows[i], rowHeights[i]);

          children.add(rowWidget);
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

    // ✅ Auto-adjust: Lấy số lượng nhỏ hơn
    final effectiveColCount = widthDefs.length < row.children.length
        ? widthDefs.length
        : row.children.length;

    // Nếu không có gì để render
    if (effectiveColCount == 0) {
      return Container(
        height: rowHeight,
        margin: row.margin,
        padding: row.padding,
        decoration: BoxDecoration(color: row.backgroundColor),
      );
    }

    final effectiveWidthDefs = widthDefs.take(effectiveColCount).toList();
    final effectiveChildren = row.children.take(effectiveColCount).toList();

    Widget rowContent = Container(
      height: rowHeight, // null nếu auto
      margin: row.margin,
      padding: row.padding,
      decoration: BoxDecoration(color: row.backgroundColor),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return _buildRowContent(
            row,
            effectiveWidthDefs,
            effectiveChildren,
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
    List<Widget> effectiveChildren,
    double availableWidth,
    double? rowHeight,
  ) {
    // ✅ Tính toán width khả dụng sau khi trừ đi spacing
    final totalSpacing = row.space * (effectiveChildren.length - 1);
    final availableForColumns = availableWidth - totalSpacing;

    // Calculate widths
    final columnWidths = _calculateSizes(widthDefs, availableForColumns);

    // Build columns với spacing
    final children = <Widget>[];
    for (int i = 0; i < effectiveChildren.length; i++) {
      // Thêm spacing trước column (trừ column đầu tiên)
      if (i > 0 && row.space > 0) {
        children.add(SizedBox(width: row.space));
      }

      children.add(
        SizedBox(width: columnWidths[i], child: effectiveChildren[i]),
      );
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
