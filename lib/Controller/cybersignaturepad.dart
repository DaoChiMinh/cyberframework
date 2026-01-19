import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:convert';

/// ============================================================================
/// CyberSignaturePad - Dialog để vẽ chữ ký
/// ============================================================================

class CyberSignaturePad extends StatefulWidget {
  final String? initialSignature;
  final Color penColor;
  final double penStrokeWidth;
  final Color backgroundColor;

  const CyberSignaturePad({
    super.key,
    this.initialSignature,
    this.penColor = Colors.black,
    this.penStrokeWidth = 3.0,
    this.backgroundColor = Colors.white,
  });

  @override
  State<CyberSignaturePad> createState() => _CyberSignaturePadState();
}

class _CyberSignaturePadState extends State<CyberSignaturePad> {
  final GlobalKey _signatureKey = GlobalKey();
  List<List<Offset>> _strokes = []; // Không final để có thể reassign
  List<Offset> _currentStroke = [];
  bool _hasDrawn = false;

  @override
  void initState() {
    super.initState();
    // Nếu có signature ban đầu, set flag đã có chữ ký
    if (widget.initialSignature != null &&
        widget.initialSignature!.isNotEmpty) {
      _hasDrawn = true;
    }
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _currentStroke = [details.localPosition]; // Tạo List mới
      _hasDrawn = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _currentStroke = [
        ..._currentStroke,
        details.localPosition,
      ]; // Tạo List mới
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      if (_currentStroke.isNotEmpty) {
        _strokes = [..._strokes, List.from(_currentStroke)]; // Tạo List mới
        _currentStroke = []; // Reset
      }
    });
  }

  void _clear() {
    setState(() {
      _strokes = []; // Tạo List mới thay vì .clear()
      _currentStroke = [];
      _hasDrawn = false;
    });
  }

  Future<String?> _captureSignature() async {
    try {
      final boundary =
          _signatureKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final bytes = byteData.buffer.asUint8List();
      return 'data:image/png;base64,${base64Encode(bytes)}';
    } catch (e) {
      debugPrint('Error capturing signature: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Ký tên',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Signature pad
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: RepaintBoundary(
                    key: _signatureKey,
                    child: GestureDetector(
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      child: CustomPaint(
                        painter: _SignaturePainter(
                          strokes: _strokes,
                          currentStroke: _currentStroke,
                          penColor: widget.penColor,
                          penStrokeWidth: widget.penStrokeWidth,
                          backgroundColor: widget.backgroundColor,
                        ),
                        child: Container(
                          // Container chỉ để set size, không set color
                          child: !_hasDrawn
                              ? Center(
                                  child: Text(
                                    'Vẽ chữ ký của bạn ở đây',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _clear,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Xóa'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _hasDrawn
                          ? () async {
                              final signature = await _captureSignature();
                              if (mounted) {
                                Navigator.pop(context, signature);
                              }
                            }
                          : null,
                      icon: const Icon(Icons.check),
                      label: const Text('Xác nhận'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ============================================================================
/// Signature Painter
/// ============================================================================

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;
  final Color penColor;
  final double penStrokeWidth;
  final Color backgroundColor;

  _SignaturePainter({
    required this.strokes,
    required this.currentStroke,
    required this.penColor,
    required this.penStrokeWidth,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background first
    final bgPaint = Paint()..color = backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final paint = Paint()
      ..color = penColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = penStrokeWidth
      ..style = PaintingStyle.stroke;

    // Draw completed strokes
    for (final stroke in strokes) {
      if (stroke.length < 2) continue;

      final path = Path();
      path.moveTo(stroke[0].dx, stroke[0].dy);

      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }

      canvas.drawPath(path, paint);
    }

    // Draw current stroke
    if (currentStroke.length >= 2) {
      final path = Path();
      path.moveTo(currentStroke[0].dx, currentStroke[0].dy);

      for (int i = 1; i < currentStroke.length; i++) {
        path.lineTo(currentStroke[i].dx, currentStroke[i].dy);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) {
    // Bây giờ có thể dùng reference comparison vì mỗi lần setState tạo List mới
    return oldDelegate.strokes != strokes ||
        oldDelegate.currentStroke != currentStroke ||
        oldDelegate.penColor != penColor ||
        oldDelegate.penStrokeWidth != penStrokeWidth ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
