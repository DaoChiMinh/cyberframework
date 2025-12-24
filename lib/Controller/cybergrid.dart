import 'package:flutter/material.dart';

// ============================================================================
// MODEL - CyberGridRow
// ============================================================================

/// Model cho mỗi row trong CyberGrid
class CyberGridRow {
  /// Khai báo chiều rộng các columns (VD: "*;Auto;100;2*")
  /// - "*" hoặc "1*": Fill 1 phần
  /// - "2*", "3*": Fill 2, 3 phần
  /// - "Auto": Tự động theo nội dung
  /// - Số cụ thể: Chiều rộng cố định
  final String widthColumns;

  /// Danh sách các widget con (số lượng phải khớp với số columns)
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

/// CyberGrid - Grid layout giống MAUI/WPF
///
/// Usage:
/// ```dart
/// CyberGrid(
///   heightRows: "Auto;*;100;2*",
///   rowSpace: 8,
///   rows: [
///     CyberGridRow(
///       widthColumns: "*;Auto;200",
///       children: [widget1, widget2, widget3],
///     ),
///     CyberGridRow(
///       widthColumns: "2*;*",
///       children: [widget4, widget5],
///     ),
///   ],
/// )
/// ```
class CyberGrid extends StatelessWidget {
  /// Chiều rộng (null = fill parent, số cụ thể = fixed width)
  final double? width;

  /// Chiều cao (null = fill parent, số cụ thể = fixed height)
  final double? height;

  /// Khai báo chiều cao các rows (VD: "Auto;*;100;2*")
  /// - "*" hoặc "1*": Fill 1 phần
  /// - "2*", "3*": Fill 2, 3 phần
  /// - "Auto": Tự động theo nội dung
  /// - Số cụ thể: Chiều cao cố định
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
    return Container(
      width: width ?? double.infinity,
      height: height ?? double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(color: backgroundColor),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return _CyberGridLayout(
            heightRows: heightRows,
            rowSpace: rowSpace,
            rows: rows,
            availableHeight: constraints.maxHeight - (padding?.vertical ?? 0),
          );
        },
      ),
    );
  }
}

// ============================================================================
// INTERNAL - Grid Layout Logic
// ============================================================================

class _CyberGridLayout extends StatelessWidget {
  final String heightRows;
  final double rowSpace;
  final List<CyberGridRow> rows;
  final double availableHeight;

  const _CyberGridLayout({
    required this.heightRows,
    required this.rowSpace,
    required this.rows,
    required this.availableHeight,
  });

  @override
  Widget build(BuildContext context) {
    final heightDefs = _parseDefinitions(heightRows);

    // Validate số lượng rows
    if (heightDefs.length != rows.length) {
      return Center(
        child: Text(
          'Error: heightRows (${heightDefs.length}) không khớp với số rows (${rows.length})',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    return Column(children: _buildRows(heightDefs));
  }

  /// Build các rows với chiều cao đã tính toán
  List<Widget> _buildRows(List<_GridDefinition> heightDefs) {
    // Tính tổng spacing
    final totalSpacing = rowSpace * (rows.length - 1);
    final availableForRows = availableHeight - totalSpacing;

    // Tính chiều cao cho từng row
    final rowHeights = _calculateSizes(heightDefs, availableForRows);

    final result = <Widget>[];

    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      final rowHeight = rowHeights[i];

      // Add spacing trước row (trừ row đầu tiên)
      if (i > 0 && rowSpace > 0) {
        result.add(SizedBox(height: rowSpace));
      }

      // Add row
      result.add(_buildRow(row, rowHeight));
    }

    return result;
  }

  /// Build một row
  Widget _buildRow(CyberGridRow row, double rowHeight) {
    Widget rowContent = Container(
      margin: row.margin,
      padding: row.padding,
      decoration: BoxDecoration(color: row.backgroundColor),
      child: SizedBox(
        height: rowHeight - (row.padding?.vertical ?? 0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return _CyberGridRowLayout(
              row: row,
              availableWidth: constraints.maxWidth,
              rowHeight: rowHeight - (row.padding?.vertical ?? 0),
            );
          },
        ),
      ),
    );

    return rowContent;
  }

  /// Parse definitions string (VD: "Auto;*;100;2*")
  List<_GridDefinition> _parseDefinitions(String definitions) {
    if (definitions.isEmpty) return [];

    return definitions.split(';').map((def) {
      final trimmed = def.trim();

      // Auto
      if (trimmed.toLowerCase() == 'auto') {
        return _GridDefinition(type: _GridDefinitionType.auto);
      }

      // Star (*, 1*, 2*, 3*, etc.)
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

      // Fixed size
      final fixedSize = double.tryParse(trimmed);
      if (fixedSize != null) {
        return _GridDefinition(
          type: _GridDefinitionType.fixed,
          value: fixedSize,
        );
      }

      // Default to Auto nếu không parse được
      return _GridDefinition(type: _GridDefinitionType.auto);
    }).toList();
  }

  /// Tính toán kích thước cho các rows/columns
  List<double> _calculateSizes(
    List<_GridDefinition> definitions,
    double availableSize,
  ) {
    // Bước 1: Tính tổng fixed size
    double totalFixed = 0;
    for (var def in definitions) {
      if (def.type == _GridDefinitionType.fixed) {
        totalFixed += def.value;
      }
    }

    // Bước 2: Tính tổng star coefficient
    double totalStarCoefficient = 0;
    for (var def in definitions) {
      if (def.type == _GridDefinitionType.star) {
        totalStarCoefficient += def.value;
      }
    }

    // Bước 3: Tính không gian còn lại cho star và auto
    double remainingSpace = availableSize - totalFixed;

    // Bước 4: Tính kích thước cho từng definition
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
          // Auto: Dùng không gian còn lại chia đều
          // Hoặc có thể implement logic phức tạp hơn để measure actual content
          sizes.add(0); // Placeholder, sẽ được adjust sau
          break;
      }
    }

    return sizes;
  }
}

// ============================================================================
// INTERNAL - Row Layout Logic
// ============================================================================

class _CyberGridRowLayout extends StatelessWidget {
  final CyberGridRow row;
  final double availableWidth;
  final double rowHeight;

  const _CyberGridRowLayout({
    required this.row,
    required this.availableWidth,
    required this.rowHeight,
  });

  @override
  Widget build(BuildContext context) {
    final widthDefs = _parseDefinitions(row.widthColumns);

    // Validate số lượng columns
    if (widthDefs.length != row.children.length) {
      return Center(
        child: Text(
          'Error: widthColumns (${widthDefs.length}) không khớp với số children (${row.children.length})',
          style: const TextStyle(color: Colors.red, fontSize: 12),
        ),
      );
    }

    // Tính chiều rộng cho từng column
    final columnWidths = _calculateSizes(widthDefs, availableWidth);

    // Build row content
    Widget rowContent = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _buildColumns(columnWidths),
    );

    // Wrap với scroll nếu enabled
    if (row.enableHorizontalScroll) {
      rowContent = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildColumns(columnWidths),
          ),
        ),
      );
    }

    // Wrap với vertical scroll nếu nội dung cao hơn rowHeight
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: rowHeight),
        child: rowContent,
      ),
    );
  }

  /// Build các columns
  List<Widget> _buildColumns(List<double> columnWidths) {
    final result = <Widget>[];

    for (int i = 0; i < row.children.length; i++) {
      final child = row.children[i];
      final width = columnWidths[i];

      result.add(SizedBox(width: width, child: child));
    }

    return result;
  }

  /// Parse definitions (giống như trong _CyberGridLayout)
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

  /// Tính toán kích thước (giống như trong _CyberGridLayout)
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

enum _GridDefinitionType {
  auto, // Tự động theo nội dung
  star, // Chia đều không gian còn lại
  fixed, // Kích thước cố định
}

class _GridDefinition {
  final _GridDefinitionType type;
  final double value; // Dùng cho star coefficient hoặc fixed size

  _GridDefinition({required this.type, this.value = 0});
}
