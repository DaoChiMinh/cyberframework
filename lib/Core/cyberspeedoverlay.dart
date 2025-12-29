import 'package:cyberframework/cyberframework.dart';

/// Widget overlay hiển thị tốc độ internet
class CyberSpeedOverlay extends StatefulWidget {
  final CyberSpeedMonitorService service;

  const CyberSpeedOverlay({super.key, required this.service});

  @override
  State<CyberSpeedOverlay> createState() => _CyberSpeedOverlayState();
}

class _CyberSpeedOverlayState extends State<CyberSpeedOverlay> {
  Offset _position = const Offset(10, 100);
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.service,
      builder: (context, _) {
        if (!widget.service.isVisible) {
          return const SizedBox.shrink();
        }

        return Positioned(
          left: _position.dx,
          top: _position.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _position = Offset(
                  (_position.dx + details.delta.dx).clamp(
                    0.0,
                    MediaQuery.of(context).size.width - 120,
                  ),
                  (_position.dy + details.delta.dy).clamp(
                    0.0,
                    MediaQuery.of(context).size.height - 50,
                  ),
                );
              });
            },
            onTap: () {
              setState(() {
                _showDetails = !_showDetails;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(70),
                borderRadius: BorderRadius.circular(_showDetails ? 12 : 20),
                border: Border.all(
                  color: widget.service.speedColor.withAlpha(50),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.service.speedColor.withAlpha(30),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: _showDetails ? _buildDetailView() : _buildCompactView(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactView() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.speed, color: widget.service.speedColor, size: 16),
        const SizedBox(width: 6),
        Text(
          widget.service.speedText,
          style: TextStyle(
            color: widget.service.speedColor,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.speed, color: widget.service.speedColor, size: 18),
            const SizedBox(width: 8),
            Text(
              setText('Tốc độ', 'Speed'),
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            const SizedBox(width: 8),
            // Close button
            GestureDetector(
              onTap: () => widget.service.stop(),
              child: const Icon(Icons.close, color: Colors.white54, size: 16),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          widget.service.speedText,
          style: TextStyle(
            color: widget.service.speedColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _getSpeedLabel(),
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ],
    );
  }

  String _getSpeedLabel() {
    final speed = widget.service.currentSpeed;
    if (speed == null) return setText('Đang kiểm tra...', 'Checking...');
    if (speed < 50) return setText('Rất chậm', 'Very Slow');
    if (speed < 200) return setText('Chậm', 'Slow');
    if (speed < 500) return setText('Trung bình', 'Average');
    if (speed < 1024) return setText('Nhanh', 'Fast');
    return setText('Rất nhanh', 'Very Fast');
  }
}

/// Extension để dễ dàng bật/tắt speed monitor
extension CyberSpeedMonitorExtension on BuildContext {
  /// Bắt đầu monitor tốc độ internet
  void startSpeedMonitor() {
    speedMonitor.start(this);
  }

  /// Dừng monitor
  void stopSpeedMonitor() {
    speedMonitor.stop();
  }

  /// Toggle hiển thị/ẩn
  void toggleSpeedMonitor() {
    if (speedMonitor.isRunning) {
      speedMonitor.toggleVisibility();
    } else {
      speedMonitor.start(this);
    }
  }
}
