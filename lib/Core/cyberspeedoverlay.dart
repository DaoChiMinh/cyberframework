// lib/Core/cyberspeedoverlay.dart

import 'package:cyberframework/cyberframework.dart';

/// Widget overlay hiển thị tốc độ internet
class CyberSpeedOverlay extends StatefulWidget {
  final CyberSpeedMonitorService service;

  const CyberSpeedOverlay({super.key, required this.service});

  @override
  State<CyberSpeedOverlay> createState() => _CyberSpeedOverlayState();
}

class _CyberSpeedOverlayState extends State<CyberSpeedOverlay> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.service,
      builder: (context, _) {
        if (!widget.service.isVisible) {
          return const SizedBox.shrink();
        }

        final position = widget.service.position;
        final screenSize = MediaQuery.of(context).size;

        return Positioned(
          left: position.dx,
          top: position.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              // ✅ Clamp position within screen bounds
              final newPosition = Offset(
                (position.dx + details.delta.dx).clamp(
                  0.0,
                  screenSize.width - 120,
                ),
                (position.dy + details.delta.dy).clamp(
                  0.0,
                  screenSize.height - 50,
                ),
              );
              widget.service.updatePosition(newPosition);
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
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(_showDetails ? 12 : 20),
                border: Border.all(
                  color: widget.service.speedColor.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.service.speedColor.withValues(alpha: 0.3),
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
    final speed = widget.service.currentSpeed;
    final speedLabel = speed == null
        ? setText('Đang kiểm tra...', 'Checking...')
        : speed < 50
        ? setText('Rất chậm', 'Very Slow')
        : speed < 200
        ? setText('Chậm', 'Slow')
        : speed < 500
        ? setText('Trung bình', 'Average')
        : speed < 1024
        ? setText('Nhanh', 'Fast')
        : setText('Rất nhanh', 'Very Fast');

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
          speedLabel,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ],
    );
  }
}
