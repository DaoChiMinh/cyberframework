import 'package:cyberframework/cyberframework.dart';

class CyberLabel extends StatelessWidget {
  final dynamic text;
  final String? format;
  final TextStyle? style;
  final TextAlign? textalign;
  final Color? textcolor;
  final Color? backgroundColor;

  final dynamic isVisible;
  final bool isIcon;
  final double? iconSpacing;
  final double? iconSize;
  final Function(dynamic)? onLeaver;
  final bool? showRipple;
  final Color? rippleColor;

  final BorderRadius? rippleBorderRadius;
  final EdgeInsets? tapPadding;

  final int? maxLines;
  final TextOverflow? overflow;

  const CyberLabel({
    super.key,
    this.text,
    this.format,
    this.style,
    this.textalign,
    this.textcolor,
    this.backgroundColor,
    this.isVisible = true,
    this.isIcon = false,
    this.iconSpacing,
    this.iconSize,
    this.onLeaver,
    this.showRipple,
    this.rippleColor,
    this.rippleBorderRadius,
    this.tapPadding,
    this.maxLines,
    this.overflow,
  });

  /// Convert dynamic value sang bool
  bool _parseBool(dynamic value) {
    if (value == null) return true; // Default visible

    if (value is bool) return value;

    if (value is int) return value != 0;

    if (value is String) {
      final lower = value.toLowerCase().trim();
      if (lower == "1" || lower == "true") return true;
      if (lower == "0" || lower == "false") return false;
      return true; // Default visible nếu không parse được
    }

    return true; // Default visible
  }

  /// Check có event nào không
  bool get _hasEvents => onLeaver != null;

  /// ✅ Helper method để wrap background color
  Widget _wrapWithBackground(Widget child) {
    if (backgroundColor == null) {
      return child;
    }

    return ColoredBox(color: backgroundColor!, child: child);
  }

  @override
  Widget build(BuildContext context) {
    CyberDataRow? textBoundRow;
    String? textBoundField;
    CyberDataRow? visibilityBoundRow;
    String? visibilityBoundField;

    // Parse text binding
    if (text is CyberBindingExpression) {
      final expr = text as CyberBindingExpression;
      textBoundRow = expr.row;
      textBoundField = expr.fieldName;
    }

    // Parse visibility binding
    if (isVisible is CyberBindingExpression) {
      final expr = isVisible as CyberBindingExpression;
      visibilityBoundRow = expr.row;
      visibilityBoundField = expr.fieldName;
    }

    Widget buildLabel() {
      // ✅ Check visibility
      bool visible = true;
      if (visibilityBoundRow != null && visibilityBoundField != null) {
        visible = _parseBool(visibilityBoundRow[visibilityBoundField]);
      } else if (isVisible != null) {
        visible = _parseBool(isVisible);
      }

      // ✅ Nếu không visible thì return empty widget
      if (!visible) {
        return const SizedBox.shrink();
      }

      // ✅ Build content (text hoặc icon)
      dynamic value;
      if (textBoundRow != null && textBoundField != null) {
        value = textBoundRow[textBoundField];
      } else {
        value = text;
      }

      Widget contentWidget;

      if (isIcon) {
        // ✅ Icon mode - Parse text as icon code point
        contentWidget = _buildIconWidget(value);
      } else {
        // ✅ Text mode - Display as text
        contentWidget = _buildTextWidget(value);
      }

      // ✅ Nếu không có event thì return content với background
      if (!_hasEvents) {
        return _wrapWithBackground(contentWidget);
      }

      // ✅ Wrap với GestureDetector nếu có event
      final shouldShowRipple = showRipple ?? true;

      if (shouldShowRipple) {
        // Sử dụng InkWell để có ripple effect
        return _wrapWithBackground(
          InkWell(
            onTap: () => onLeaver?.call(""),
            splashColor:
                rippleColor?.withValues(alpha: 0.3) ??
                Theme.of(context).primaryColor.withValues(alpha: 0.2),
            highlightColor:
                rippleColor?.withValues(alpha: 0.1) ??
                Theme.of(context).primaryColor.withValues(alpha: 0.1),
            borderRadius: rippleBorderRadius ?? BorderRadius.circular(4),
            child: Padding(
              padding:
                  tapPadding ??
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: contentWidget,
            ),
          ),
        );
      } else {
        // Không có ripple, chỉ dùng GestureDetector
        return _wrapWithBackground(
          GestureDetector(
            onTap: () => onLeaver?.call(""),
            child: Padding(
              padding:
                  tapPadding ??
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: contentWidget,
            ),
          ),
        );
      }
    }

    // ✅ Nếu có bất kỳ binding nào (text hoặc visibility) thì listen
    if (textBoundRow != null || visibilityBoundRow != null) {
      // Nếu cả 2 cùng bind vào 1 row
      if (textBoundRow == visibilityBoundRow) {
        return ListenableBuilder(
          listenable: textBoundRow!,
          builder: (context, child) => buildLabel(),
        );
      }

      // Nếu bind vào 2 row khác nhau
      if (textBoundRow != null && visibilityBoundRow != null) {
        return ListenableBuilder(
          listenable: Listenable.merge([textBoundRow, visibilityBoundRow]),
          builder: (context, child) => buildLabel(),
        );
      }

      // Chỉ có 1 trong 2
      final row = textBoundRow ?? visibilityBoundRow;
      return ListenableBuilder(
        listenable: row!,
        builder: (context, child) => buildLabel(),
      );
    }

    return buildLabel();
  }

  /// Build text widget (mode thông thường)
  Widget _buildTextWidget(dynamic value) {
    String displayText;
    if (format != null && format!.isNotEmpty) {
      displayText = format!.format([value ?? '']);
    } else {
      displayText = value?.toString() ?? '';
    }

    return Text(
      displayText,
      style: style?.copyWith(color: textcolor) ?? TextStyle(color: textcolor),
      textAlign: textalign,
      maxLines: maxLines,
      overflow: overflow ?? (maxLines != null ? TextOverflow.ellipsis : null),
    );
  }

  /// Build icon widget (isIcon = true)
  Widget _buildIconWidget(dynamic value) {
    if (value == null) {
      return const SizedBox.shrink();
    }

    final valueStr = value.toString();
    final iconData = v_parseIcon(valueStr);

    if (iconData == null) {
      // Nếu không parse được, fallback to text
      return Text(
        valueStr,
        style: style?.copyWith(color: textcolor) ?? TextStyle(color: textcolor),
        textAlign: textalign,
        maxLines: maxLines,
        overflow: overflow ?? (maxLines != null ? TextOverflow.ellipsis : null),
      );
    }

    // ✅ Hiển thị icon
    return Icon(
      iconData,
      size: iconSize ?? (style?.fontSize ?? 24),
      color: textcolor ?? style?.color ?? Colors.black,
    );
  }
}

/// Extension để tạo clickable label từ String
extension CyberClickableLabelExtension on String {
  Widget toClickableLabel({
    Function(dynamic)? onTap,
    VoidCallback? onLongPress,
    VoidCallback? onDoubleTap,
    TextStyle? style,
    Color? textcolor,
    Color? backgroundColor,
    String? format,
    bool? showRipple,
    Color? rippleColor,
    bool isIcon = false,
    double? iconSize,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return CyberLabel(
      text: this,
      onLeaver: onTap,
      style: style,
      textcolor: textcolor,
      backgroundColor: backgroundColor,
      format: format,
      showRipple: showRipple,
      rippleColor: rippleColor,
      isIcon: isIcon,
      iconSize: iconSize,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  Widget toIconLabel({
    Function(dynamic)? onTap,
    double? size,
    Color? color,
    Color? backgroundColor,
    bool? showRipple,
    Color? rippleColor,
  }) {
    return CyberLabel(
      text: this,
      isIcon: true,
      iconSize: size,
      textcolor: color,
      backgroundColor: backgroundColor,
      onLeaver: onTap,
      showRipple: showRipple,
      rippleColor: rippleColor,
    );
  }
}
