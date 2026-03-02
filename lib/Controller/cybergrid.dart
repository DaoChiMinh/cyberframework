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

  /// Khai báo chiều cao các rows (VD: "Auto;Auto;*;50")
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
    final heightDefs = _parseDefinitions(heightRows);

    final effectiveCount = heightDefs.length < rows.length
        ? heightDefs.length
        : rows.length;

    if (effectiveCount == 0) {
      return Container(
        width: width ?? double.infinity,
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(color: backgroundColor),
      );
    }

    final effectiveHeightDefs = heightDefs.take(effectiveCount).toList();
    final effectiveRows = rows.take(effectiveCount).toList();

    final allAuto = effectiveHeightDefs.every(
      (def) => def.type == _GridDefinitionType.auto,
    );

    return Container(
      width: width ?? double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(color: backgroundColor),
      height: allAuto ? null : height,
      child: allAuto
          ? _buildWrapContent(effectiveHeightDefs, effectiveRows)
          : _buildWithConstraints(effectiveHeightDefs, effectiveRows),
    );
  }

  // ---------------------------------------------------------------------------
  // Build mode: tất cả row đều Auto
  // ---------------------------------------------------------------------------

  Widget _buildWrapContent(
    List<_GridDefinition> heightDefs,
    List<CyberGridRow> effectiveRows,
  ) {
    final children = <Widget>[];
    for (int i = 0; i < effectiveRows.length; i++) {
      if (i > 0 && rowSpace > 0) children.add(SizedBox(height: rowSpace));
      children.add(_buildRow(effectiveRows[i], null));
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  // ---------------------------------------------------------------------------
  // Build mode: có star hoặc fixed height
  // ---------------------------------------------------------------------------

  Widget _buildWithConstraints(
    List<_GridDefinition> heightDefs,
    List<CyberGridRow> effectiveRows,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = height ?? constraints.maxHeight;
        final totalSpacing = rowSpace * (effectiveRows.length - 1);
        final availableForRows = availableHeight - totalSpacing;
        final rowHeights = _calculateSizes(heightDefs, availableForRows);

        final children = <Widget>[];
        for (int i = 0; i < effectiveRows.length; i++) {
          if (i > 0 && rowSpace > 0) children.add(SizedBox(height: rowSpace));
          final rowHeight = heightDefs[i].type == _GridDefinitionType.auto
              ? null
              : rowHeights[i];
          children.add(_buildRow(effectiveRows[i], rowHeight));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Build một row (wrapper container)
  // ---------------------------------------------------------------------------

  Widget _buildRow(CyberGridRow row, double? rowHeight) {
    final widthDefs = _parseDefinitions(row.widthColumns);

    final effectiveColCount = widthDefs.length < row.children.length
        ? widthDefs.length
        : row.children.length;

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

    return Container(
      height: rowHeight,
      margin: row.margin,
      padding: row.padding,
      decoration: BoxDecoration(color: row.backgroundColor),
      child: _buildRowContent(
        row,
        effectiveWidthDefs,
        effectiveChildren,
        rowHeight,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build nội dung bên trong row
  //
  // ✅ FIX CORE — Root cause: trước đây dùng LayoutBuilder + _calculateSizes
  // cho cả 3 loại column. Với star column, kích thước được tính từ
  // availableWidth mà KHÔNG trừ đi phần Auto column sẽ chiếm.
  // Kết quả: star columns được cấp quá nhiều px → Row tổng > container
  // → nội dung bị clip bên phải.
  //
  // Fix: Mỗi loại column dùng Flutter primitive phù hợp:
  //   Auto  → IntrinsicWidth   (co theo nội dung thực tế)
  //   Fixed → SizedBox(width)  (cố định px)
  //   Star  → Expanded(flex)   (Flutter tự chia phần còn lại sau Auto+Fixed)
  // ---------------------------------------------------------------------------

  Widget _buildRowContent(
    CyberGridRow row,
    List<_GridDefinition> widthDefs,
    List<Widget> effectiveChildren,
    double? rowHeight,
  ) {
    final children = <Widget>[];

    for (int i = 0; i < effectiveChildren.length; i++) {
      if (i > 0 && row.space > 0) {
        children.add(SizedBox(width: row.space));
      }

      final def = widthDefs[i];
      switch (def.type) {
        case _GridDefinitionType.auto:
          // Co giãn theo nội dung, không ép width
          children.add(IntrinsicWidth(child: effectiveChildren[i]));
          break;

        case _GridDefinitionType.fixed:
          // Cố định px
          children.add(SizedBox(width: def.value, child: effectiveChildren[i]));
          break;

        case _GridDefinitionType.star:
          // Expanded tự chia phần còn lại sau Auto + Fixed
          // flex là int nên nhân 100 để hỗ trợ 0.5*, 1.5*, 2.5*…
          children.add(
            Expanded(
              flex: (def.value * 100).round(),
              child: effectiveChildren[i],
            ),
          );
          break;
      }
    }

    Widget content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );

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

  // ---------------------------------------------------------------------------
  // Parse "Auto;*;100;2*" → List<_GridDefinition>
  // ---------------------------------------------------------------------------

  List<_GridDefinition> _parseDefinitions(String definitions) {
    if (definitions.isEmpty) return [];
    return definitions.split(';').where((s) => s.trim().isNotEmpty).map((def) {
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

  // ---------------------------------------------------------------------------
  // Tính kích thước — chỉ dùng cho ROW HEIGHTS.
  // Column widths không còn dùng hàm này nữa (đã chuyển sang Expanded).
  // ---------------------------------------------------------------------------

  List<double> _calculateSizes(
    List<_GridDefinition> definitions,
    double availableSize,
  ) {
    double totalFixed = 0;
    double totalStarCoefficient = 0;
    for (var def in definitions) {
      if (def.type == _GridDefinitionType.fixed) totalFixed += def.value;
      if (def.type == _GridDefinitionType.star)
        totalStarCoefficient += def.value;
    }
    final remainingSpace = availableSize - totalFixed;
    final sizes = <double>[];
    for (var def in definitions) {
      switch (def.type) {
        case _GridDefinitionType.fixed:
          sizes.add(def.value);
          break;
        case _GridDefinitionType.star:
          sizes.add(
            totalStarCoefficient > 0
                ? (remainingSpace * def.value / totalStarCoefficient).clamp(
                    0,
                    double.infinity,
                  )
                : 0.0,
          );
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
