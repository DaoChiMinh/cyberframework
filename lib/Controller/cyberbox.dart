import 'package:flutter/material.dart';

/// Enum cho vertical và horizontal alignment
enum CyberAlign { start, center, end }

/// Class để định nghĩa size (có thể là số cụ thể hoặc fill parent)
class CyberSize {
  final double? _value;
  final bool _isFill;

  const CyberSize(this._value, this._isFill);

  /// Tạo size với giá trị cụ thể
  const CyberSize.fixed(double value) : _value = value, _isFill = false;

  /// Tạo size fill parent (*)
  const CyberSize.fill() : _value = null, _isFill = true;

  /// Tạo size wrap content (null)
  const CyberSize.wrap() : _value = null, _isFill = false;

  bool get isFill => _isFill;
  bool get isWrap => !_isFill && _value == null;
  double? get value => _value;

  /// Parse từ dynamic (hỗ trợ: số, "*", null)
  static CyberSize? parse(dynamic input) {
    if (input == null) return const CyberSize.wrap();
    if (input == '*') return const CyberSize.fill();
    if (input is String && input == '*') return const CyberSize.fill();
    if (input is num) return CyberSize.fixed(input.toDouble());
    if (input is CyberSize) return input;
    return null;
  }
}

/// CyberBox - Container linh hoạt với nhiều children
class CyberBox extends StatelessWidget {
  /// Chiều rộng (số cụ thể, "*" để fill, null để wrap content)
  final dynamic width;

  /// Chiều cao (số cụ thể, "*" để fill, null để wrap content)
  final dynamic height;

  /// Màu nền
  final Color? backgroundColor;

  /// Padding bên trong
  final EdgeInsets? padding;

  /// Border
  final BoxBorder? border;

  /// Bo góc border (ưu tiên dùng nếu có cả radius)
  final BorderRadius? borderRadius;

  /// Bo góc đơn giản (áp dụng đều cho 4 góc)
  final double? radius;

  /// Bo góc từng góc riêng biệt
  final double? topLeftRadius;
  final double? topRightRadius;
  final double? bottomLeftRadius;
  final double? bottomRightRadius;

  /// Danh sách các widget con
  final List<Widget> children;

  /// Căn chỉnh theo chiều dọc (start, center, end)
  final CyberAlign vAlign;

  /// Căn chỉnh theo chiều ngang (start, center, end)
  final CyberAlign hAlign;

  /// Callback khi click
  final VoidCallback? onClick;

  /// Khoảng cách giữa các children
  final double spacing;

  /// Có hiển thị hiệu ứng ripple khi click không
  final bool showRipple;

  /// Margin bên ngoài
  final EdgeInsets? margin;

  /// Shadow (box shadow)
  final List<BoxShadow>? shadows;

  const CyberBox({
    super.key,
    this.width,
    this.height,
    this.backgroundColor,
    this.padding,
    this.border,
    this.borderRadius,
    this.radius,
    this.topLeftRadius,
    this.topRightRadius,
    this.bottomLeftRadius,
    this.bottomRightRadius,
    this.children = const [],
    this.vAlign = CyberAlign.start,
    this.hAlign = CyberAlign.start,
    this.onClick,
    this.spacing = 0,
    this.showRipple = true,
    this.margin,
    this.shadows,
  });

  /// Tính toán BorderRadius cuối cùng
  BorderRadius? _getEffectiveBorderRadius() {
    // Ưu tiên dùng borderRadius nếu có
    if (borderRadius != null) return borderRadius;

    // Nếu có radius đơn giản, dùng cho cả 4 góc
    if (radius != null) {
      return BorderRadius.circular(radius!);
    }

    // Nếu có radius cho từng góc riêng biệt
    if (topLeftRadius != null ||
        topRightRadius != null ||
        bottomLeftRadius != null ||
        bottomRightRadius != null) {
      return BorderRadius.only(
        topLeft: Radius.circular(topLeftRadius ?? 0),
        topRight: Radius.circular(topRightRadius ?? 0),
        bottomLeft: Radius.circular(bottomLeftRadius ?? 0),
        bottomRight: Radius.circular(bottomRightRadius ?? 0),
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final parsedWidth = CyberSize.parse(width);
    final parsedHeight = CyberSize.parse(height);
    final effectiveBorderRadius = _getEffectiveBorderRadius();

    final mainAxisAlignment = _convertToMainAxisAlignment(vAlign);
    final crossAxisAlignment = _convertToCrossAxisAlignment(hAlign);

    // Build nội dung với children
    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: _buildChildrenWithSpacing(),
    );

    // Xử lý width và height
    final containerWidth = parsedWidth?.isFill == true
        ? double.infinity
        : parsedWidth?.value;

    final containerHeight = parsedHeight?.isFill == true
        ? double.infinity
        : parsedHeight?.value;

    // Wrap với Container để có background, border, padding
    content = Container(
      width: containerWidth,
      height: containerHeight,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: border,
        borderRadius: effectiveBorderRadius,
        boxShadow: shadows,
      ),
      child: content,
    );

    // Wrap với InkWell nếu có onClick
    if (onClick != null) {
      if (showRipple) {
        // Dùng Material + InkWell để có ripple effect
        content = Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onClick,
            borderRadius: effectiveBorderRadius,
            child: Container(
              width: containerWidth,
              height: containerHeight,
              margin: margin,
              padding: padding,
              decoration: BoxDecoration(
                color: backgroundColor,
                border: border,
                borderRadius: effectiveBorderRadius,
                boxShadow: shadows,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: mainAxisAlignment,
                crossAxisAlignment: crossAxisAlignment,
                children: _buildChildrenWithSpacing(),
              ),
            ),
          ),
        );
      } else {
        // Dùng GestureDetector không có ripple
        content = GestureDetector(onTap: onClick, child: content);
      }
    }

    return content;
  }

  /// Build children với spacing
  List<Widget> _buildChildrenWithSpacing() {
    if (children.isEmpty) return [];
    if (spacing <= 0) return children;

    final result = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        result.add(SizedBox(height: spacing));
      }
    }
    return result;
  }

  /// Convert CyberAlign sang MainAxisAlignment
  MainAxisAlignment _convertToMainAxisAlignment(CyberAlign align) {
    switch (align) {
      case CyberAlign.start:
        return MainAxisAlignment.start;
      case CyberAlign.center:
        return MainAxisAlignment.center;
      case CyberAlign.end:
        return MainAxisAlignment.end;
    }
  }

  /// Convert CyberAlign sang CrossAxisAlignment
  CrossAxisAlignment _convertToCrossAxisAlignment(CyberAlign align) {
    switch (align) {
      case CyberAlign.start:
        return CrossAxisAlignment.start;
      case CyberAlign.center:
        return CrossAxisAlignment.center;
      case CyberAlign.end:
        return CrossAxisAlignment.end;
    }
  }
}

/// Extension để tạo border dễ dàng hơn
extension CyberBoxBorder on CyberBox {
  /// Tạo border đơn giản
  static BoxBorder createBorder({
    Color color = Colors.grey,
    double width = 1.0,
  }) {
    return Border.all(color: color, width: width);
  }

  /// Tạo border chỉ một phía
  static BoxBorder createBorderSide({
    Color color = Colors.grey,
    double width = 1.0,
    bool top = false,
    bool right = false,
    bool bottom = false,
    bool left = false,
  }) {
    return Border(
      top: top ? BorderSide(color: color, width: width) : BorderSide.none,
      right: right ? BorderSide(color: color, width: width) : BorderSide.none,
      bottom: bottom ? BorderSide(color: color, width: width) : BorderSide.none,
      left: left ? BorderSide(color: color, width: width) : BorderSide.none,
    );
  }
}

/// Extension để tạo border radius dễ dàng hơn
extension CyberBoxRadius on CyberBox {
  /// Tạo border radius đều cho 4 góc
  static BorderRadius circular(double radius) {
    return BorderRadius.circular(radius);
  }

  /// Tạo border radius chỉ cho góc trên
  static BorderRadius onlyTop(double radius) {
    return BorderRadius.only(
      topLeft: Radius.circular(radius),
      topRight: Radius.circular(radius),
    );
  }

  /// Tạo border radius chỉ cho góc dưới
  static BorderRadius onlyBottom(double radius) {
    return BorderRadius.only(
      bottomLeft: Radius.circular(radius),
      bottomRight: Radius.circular(radius),
    );
  }

  /// Tạo border radius chỉ cho góc trái
  static BorderRadius onlyLeft(double radius) {
    return BorderRadius.only(
      topLeft: Radius.circular(radius),
      bottomLeft: Radius.circular(radius),
    );
  }

  /// Tạo border radius chỉ cho góc phải
  static BorderRadius onlyRight(double radius) {
    return BorderRadius.only(
      topRight: Radius.circular(radius),
      bottomRight: Radius.circular(radius),
    );
  }

  /// Tạo border radius tùy chỉnh cho từng góc
  static BorderRadius custom({
    double topLeft = 0,
    double topRight = 0,
    double bottomLeft = 0,
    double bottomRight = 0,
  }) {
    return BorderRadius.only(
      topLeft: Radius.circular(topLeft),
      topRight: Radius.circular(topRight),
      bottomLeft: Radius.circular(bottomLeft),
      bottomRight: Radius.circular(bottomRight),
    );
  }
}
