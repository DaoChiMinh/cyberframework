import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// ============================================================================
/// CyberFullscreenSignatureViewer - Xem chữ ký toàn màn hình
/// ============================================================================

class CyberFullscreenSignatureViewer extends StatelessWidget {
  final String signatureValue;

  const CyberFullscreenSignatureViewer({
    super.key,
    required this.signatureValue,
  });

  Uint8List? _decodeBase64(String base64String) {
    try {
      String base64Data = base64String;
      if (base64String.contains(',')) {
        base64Data = base64String.split(',').last;
      }
      return base64Decode(base64Data);
    } catch (e) {
      debugPrint('Error decoding base64: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Chữ ký'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: _buildSignatureImage(),
        ),
      ),
    );
  }

  Widget _buildSignatureImage() {
    try {
      final bytes = _decodeBase64(signatureValue);
      if (bytes == null) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 64, color: Colors.white54),
              SizedBox(height: 16),
              Text(
                'Không thể hiển thị chữ ký',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Lỗi hiển thị chữ ký',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          },
        ),
      );
    } catch (e) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image, size: 64, color: Colors.white54),
            const SizedBox(height: 16),
            Text('Lỗi: $e', style: const TextStyle(color: Colors.white70)),
          ],
        ),
      );
    }
  }
}
