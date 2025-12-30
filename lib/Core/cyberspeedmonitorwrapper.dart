// lib/Core/cyberspeedmonitorwrapper.dart

import 'package:cyberframework/Core/speed_monitor_base.dart';
import 'package:cyberframework/cyberframework.dart';

class CyberSpeedIndicator extends StatefulWidget {
  final bool showLabel;
  final bool autoStart;
  final TextStyle? textStyle;
  final EdgeInsets? padding;
  final bool compact;

  const CyberSpeedIndicator({
    super.key,
    this.showLabel = true,
    this.autoStart = true,
    this.textStyle,
    this.padding,
    this.compact = false,
  });

  @override
  State<CyberSpeedIndicator> createState() => _CyberSpeedIndicatorState();
}

class _CyberSpeedIndicatorState extends State<CyberSpeedIndicator>
    with SpeedMonitorMixin {
  @override
  void initState() {
    super.initState();
    if (widget.autoStart) {
      startMonitoring();
    }
  }

  @override
  void dispose() {
    disposeMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return Container(
        padding:
            widget.padding ??
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: speedColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: speedColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.speed, color: speedColor, size: 14),
            const SizedBox(width: 4),
            Text(
              speedText,
              style:
                  widget.textStyle ??
                  TextStyle(
                    color: speedColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding:
          widget.padding ??
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: speedColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: speedColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.speed, color: speedColor, size: 16),
          const SizedBox(width: 6),
          Text(
            speedText,
            style:
                widget.textStyle ??
                TextStyle(
                  color: speedColor,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (widget.showLabel) ...[
            const SizedBox(width: 6),
            Text(
              setText('Tốc độ', 'Speed'),
              style: TextStyle(
                color: speedColor.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CyberSpeedBanner extends StatefulWidget {
  final Color? backgroundColor;
  final EdgeInsets? padding;
  final bool showDismissButton;

  const CyberSpeedBanner({
    super.key,
    this.backgroundColor,
    this.padding,
    this.showDismissButton = true,
  });

  @override
  State<CyberSpeedBanner> createState() => _CyberSpeedBannerState();
}

class _CyberSpeedBannerState extends State<CyberSpeedBanner> {
  bool _isDismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding:
          widget.padding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.grey.shade100,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: CyberSpeedIndicator(
              showLabel: true,
              autoStart: true,
              compact: false,
              padding: EdgeInsets.zero,
            ),
          ),
          if (widget.showDismissButton)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              color: Colors.grey.shade600,
              onPressed: () {
                setState(() {
                  _isDismissed = true;
                });
              },
            ),
        ],
      ),
    );
  }
}
