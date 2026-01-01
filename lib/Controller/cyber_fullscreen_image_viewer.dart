import 'dart:typed_data';
import 'package:cyberframework/Controller/cyber_image_cache_manager.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

/// ✅ Optimized Fullscreen Image Viewer
/// Uses global cache - no duplicate decoding!
class CyberFullscreenImageViewer extends StatefulWidget {
  final String imageValue;
  final bool isCircle;

  const CyberFullscreenImageViewer({
    super.key,
    required this.imageValue,
    this.isCircle = false,
  });

  @override
  State<CyberFullscreenImageViewer> createState() =>
      _CyberFullscreenImageViewerState();
}

class _CyberFullscreenImageViewerState
    extends State<CyberFullscreenImageViewer> {
  // ⭐ Use global cache manager
  final _cacheManager = CyberImageCacheManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Optional: Share, Download, etc.
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () => _showMoreOptions(),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: _buildImage(),
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    try {
      // Asset image
      if (widget.imageValue.startsWith('assets/') ||
          widget.imageValue.startsWith('asset/') ||
          widget.imageValue.contains('assets/')) {
        return Image.asset(
          widget.imageValue,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
        );
      }

      // Network image
      if (widget.imageValue.startsWith('http://') ||
          widget.imageValue.startsWith('https://')) {
        return CachedNetworkImage(
          imageUrl: widget.imageValue,
          fit: BoxFit.contain,
          placeholder: (context, url) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          errorWidget: (context, url, error) => _buildErrorWidget(),
        );
      }

      // Local file
      if (widget.imageValue.startsWith('/') ||
          widget.imageValue.contains('\\')) {
        return Image.file(
          File(widget.imageValue),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
        );
      }

      // ⭐ Base64 - USE GLOBAL CACHE (no duplicate decode!)
      final bytes = _getBytesFromCache();
      if (bytes != null) {
        return Image.memory(
          bytes,
          fit: BoxFit.contain,
          // ⭐ NO size constraints for fullscreen viewing
          errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
        );
      }

      return _buildErrorWidget();
    } catch (e) {
      return _buildErrorWidget();
    }
  }

  /// ⭐ Get bytes from GLOBAL cache (reuse from CyberImage)
  /// KHÔNG decode riêng - ủy thác cho cache manager!
  Uint8List? _getBytesFromCache() {
    // ✅ Cache manager decode + cache tập trung
    return _cacheManager.getOrDecodeBase64(widget.imageValue);
  }

  Widget _buildErrorWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 64, color: Colors.white54),
          SizedBox(height: 16),
          Text(
            'Không thể tải ảnh',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Options
              _buildOption(
                icon: Icons.share,
                label: 'Chia sẻ',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement share
                },
              ),
              _buildOption(
                icon: Icons.download,
                label: 'Tải xuống',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement download
                },
              ),
              _buildOption(
                icon: Icons.info_outline,
                label: 'Thông tin',
                onTap: () {
                  Navigator.pop(context);
                  _showImageInfo();
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  void _showImageInfo() {
    final bytes = _getBytesFromCache();
    final size = bytes?.length ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thông tin ảnh'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kích thước: ${_formatBytes(size)}'),
            const SizedBox(height: 8),
            Text('Loại: ${_getImageType()}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _getImageType() {
    if (widget.imageValue.startsWith('http')) return 'Network';
    if (widget.imageValue.startsWith('assets')) return 'Asset';
    if (widget.imageValue.startsWith('data:image')) return 'Base64';
    if (widget.imageValue.startsWith('/')) return 'File';
    return 'Unknown';
  }
}
