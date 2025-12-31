import 'package:cyberframework/cyberframework.dart';

/// CyberImage - Optimized version with memory management
class CyberImage extends StatefulWidget {
  final dynamic text;
  final String? label;
  final dynamic isUpload;
  final dynamic isView;
  final dynamic isDelete;
  final double? width;
  final double? height;
  final dynamic fit;
  final double borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final TextStyle? labelStyle;
  final bool isShowLabel;
  final ValueChanged<String>? onChanged;
  final Function(dynamic)? onLeaver;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final bool enabled;
  final dynamic isVisible;
  final bool enableCompression;
  final int compressionQuality;
  final int? maxWidth;
  final int? maxHeight;
  final IconData? uploadIcon;
  final IconData? viewIcon;
  final IconData? deleteIcon;
  final bool isCircle;

  const CyberImage({
    super.key,
    this.text,
    this.label,
    this.isUpload = false,
    this.isView = true,
    this.isDelete = false,
    this.width,
    this.height = 200,
    this.fit = "cover",
    this.borderRadius = 12.0,
    this.placeholder,
    this.errorWidget,
    this.labelStyle,
    this.isShowLabel = true,
    this.onChanged,
    this.onLeaver,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 2.0,
    this.enabled = true,
    this.isVisible = true,
    this.enableCompression = true,
    this.compressionQuality = 85,
    this.maxWidth = 1920,
    this.maxHeight = 1920,
    this.uploadIcon,
    this.viewIcon,
    this.deleteIcon,
    this.isCircle = false,
  });

  @override
  State<CyberImage> createState() => _CyberImageState();
}

class _CyberImageState extends State<CyberImage> {
  // Binding references
  CyberDataRow? _boundRow;
  String? _boundField;
  CyberDataRow? _visibilityBoundRow;
  String? _visibilityBoundField;
  CyberDataRow? _fitBoundRow;
  String? _fitBoundField;

  // State flags
  bool _isUpdating = false;
  bool _isLoading = false;

  // ⭐ Performance caches
  bool? _cachedVisibility;
  BoxFit? _cachedFit;
  String? _cachedImageValue;
  Uint8List? _cachedBytes; // Cache decoded base64

  @override
  void initState() {
    super.initState();
    _initializeBindings();
  }

  @override
  void didUpdateWidget(CyberImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ⭐ Check if bindings changed
    bool bindingsChanged = false;

    if (oldWidget.text != widget.text) {
      bindingsChanged = true;
    }
    if (oldWidget.isVisible != widget.isVisible) {
      bindingsChanged = true;
      _cachedVisibility = null;
    }
    if (oldWidget.fit != widget.fit) {
      bindingsChanged = true;
      _cachedFit = null;
    }

    if (bindingsChanged) {
      _removeAllListeners();
      _initializeBindings();
    }
  }

  @override
  void dispose() {
    _removeAllListeners();
    _clearCaches(); // ⭐ Clear all caches
    super.dispose();
  }

  // ⭐ Initialize all bindings and listeners
  void _initializeBindings() {
    _parseBinding();
    _parseVisibilityBinding();
    _parseFitBinding();
    _addAllListeners();
  }

  // ⭐ Add all listeners (no duplicates)
  void _addAllListeners() {
    if (_boundRow != null) {
      _boundRow!.addListener(_onBindingChanged);
    }
    if (_visibilityBoundRow != null && _visibilityBoundRow != _boundRow) {
      _visibilityBoundRow!.addListener(_onBindingChanged);
    }
    if (_fitBoundRow != null &&
        _fitBoundRow != _boundRow &&
        _fitBoundRow != _visibilityBoundRow) {
      _fitBoundRow!.addListener(_onBindingChanged);
    }
  }

  // ⭐ Remove all listeners safely
  void _removeAllListeners() {
    if (_boundRow != null) {
      _boundRow!.removeListener(_onBindingChanged);
    }
    if (_visibilityBoundRow != null && _visibilityBoundRow != _boundRow) {
      _visibilityBoundRow!.removeListener(_onBindingChanged);
    }
    if (_fitBoundRow != null &&
        _fitBoundRow != _boundRow &&
        _fitBoundRow != _visibilityBoundRow) {
      _fitBoundRow!.removeListener(_onBindingChanged);
    }
  }

  // ⭐ Clear all caches
  void _clearCaches() {
    _cachedVisibility = null;
    _cachedFit = null;
    _cachedImageValue = null;
    _cachedBytes = null; // Important: free memory
  }

  void _parseBinding() {
    if (widget.text == null) {
      _boundRow = null;
      _boundField = null;
      return;
    }

    if (widget.text is CyberBindingExpression) {
      final expr = widget.text as CyberBindingExpression;
      _boundRow = expr.row;
      _boundField = expr.fieldName;
      return;
    }

    _boundRow = null;
    _boundField = null;
  }

  void _parseVisibilityBinding() {
    if (widget.isVisible == null) {
      _visibilityBoundRow = null;
      _visibilityBoundField = null;
      return;
    }

    if (widget.isVisible is CyberBindingExpression) {
      final expr = widget.isVisible as CyberBindingExpression;
      _visibilityBoundRow = expr.row;
      _visibilityBoundField = expr.fieldName;
      return;
    }

    _visibilityBoundRow = null;
    _visibilityBoundField = null;
  }

  void _parseFitBinding() {
    if (widget.fit == null) {
      _fitBoundRow = null;
      _fitBoundField = null;
      return;
    }

    if (widget.fit is CyberBindingExpression) {
      final expr = widget.fit as CyberBindingExpression;
      _fitBoundRow = expr.row;
      _fitBoundField = expr.fieldName;
      return;
    }

    _fitBoundRow = null;
    _fitBoundField = null;
  }

  bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final lower = value.toLowerCase().trim();
      if (lower == "1" || lower == "true") return true;
      if (lower == "0" || lower == "false") return false;
      return false;
    }
    return false;
  }

  // ⭐ Cached visibility check
  bool _isVisible() {
    if (_cachedVisibility != null) return _cachedVisibility!;

    if (_visibilityBoundRow != null && _visibilityBoundField != null) {
      _cachedVisibility = _parseBool(
        _visibilityBoundRow![_visibilityBoundField!],
      );
    } else {
      _cachedVisibility = _parseBool(widget.isVisible);
    }

    return _cachedVisibility!;
  }

  // ⭐ Cached fit parsing
  BoxFit _parseFit() {
    if (_cachedFit != null) return _cachedFit!;

    dynamic fitValue;

    if (_fitBoundRow != null && _fitBoundField != null) {
      try {
        fitValue = _fitBoundRow![_fitBoundField!];
      } catch (e) {
        fitValue = widget.fit;
      }
    } else if (widget.fit != null && widget.fit is! CyberBindingExpression) {
      fitValue = widget.fit;
    } else {
      _cachedFit = BoxFit.cover;
      return _cachedFit!;
    }

    if (fitValue is BoxFit) {
      _cachedFit = fitValue;
      return _cachedFit!;
    }

    if (fitValue is String) {
      final fitString = fitValue.toLowerCase().trim();

      switch (fitString) {
        case 'fill':
          _cachedFit = BoxFit.fill;
          break;
        case 'contain':
          _cachedFit = BoxFit.contain;
          break;
        case 'cover':
          _cachedFit = BoxFit.cover;
          break;
        case 'fitwidth':
        case 'fit_width':
        case 'width':
          _cachedFit = BoxFit.fitWidth;
          break;
        case 'fitheight':
        case 'fit_height':
        case 'height':
          _cachedFit = BoxFit.fitHeight;
          break;
        case 'center':
        case 'none':
          _cachedFit = BoxFit.none;
          break;
        case 'scaledown':
        case 'scale_down':
        case 'scale':
          _cachedFit = BoxFit.scaleDown;
          break;
        default:
          _cachedFit = BoxFit.cover;
      }
      return _cachedFit!;
    }

    _cachedFit = BoxFit.cover;
    return _cachedFit!;
  }

  void _onBindingChanged() {
    if (_isUpdating) return;

    // ⭐ Invalidate caches
    _clearCaches();

    setState(() {});
  }

  String? _getCurrentValue() {
    if (widget.text is CyberBindingExpression) {
      final expr = widget.text as CyberBindingExpression;
      if (_boundRow != expr.row || _boundField != expr.fieldName) {
        _boundRow = expr.row;
        _boundField = expr.fieldName;
      }
    }

    dynamic rawValue;

    if (_boundRow != null && _boundField != null) {
      try {
        rawValue = _boundRow![_boundField!];
      } catch (e) {
        return null;
      }
    } else if (widget.text != null && widget.text is! CyberBindingExpression) {
      rawValue = widget.text;
    } else {
      return null;
    }

    return rawValue?.toString();
  }

  void _updateValue(String? newValue) {
    if (!widget.enabled) return;

    _isUpdating = true;

    // ⭐ Clear image cache when value changes
    if (_cachedImageValue != newValue) {
      _cachedImageValue = null;
      _cachedBytes = null;
    }

    if (_boundRow != null && _boundField != null) {
      _boundRow![_boundField!] = newValue ?? '';
    }

    widget.onChanged?.call(newValue ?? '');
    widget.onLeaver?.call(newValue);

    setState(() {
      _isUpdating = false;
    });
  }

  bool _canUpload() {
    if (widget.isUpload is CyberBindingExpression) {
      final expr = widget.isUpload as CyberBindingExpression;
      try {
        return _parseBool(expr.row[expr.fieldName]);
      } catch (e) {
        return false;
      }
    }
    return _parseBool(widget.isUpload);
  }

  bool _canView() {
    if (widget.isView is CyberBindingExpression) {
      final expr = widget.isView as CyberBindingExpression;
      try {
        return _parseBool(expr.row[expr.fieldName]);
      } catch (e) {
        return true;
      }
    }
    return _parseBool(widget.isView);
  }

  bool _canDelete() {
    if (widget.isDelete is CyberBindingExpression) {
      final expr = widget.isDelete as CyberBindingExpression;
      try {
        return _parseBool(expr.row[expr.fieldName]);
      } catch (e) {
        return false;
      }
    }
    return _parseBool(widget.isDelete);
  }

  Future<void> _handleImageTap() async {
    if (!widget.enabled) return;

    final imageValue = _getCurrentValue();
    final hasImage = imageValue != null && imageValue.isNotEmpty;

    final canUpload = _canUpload();
    final canView = _canView();
    final canDelete = _canDelete();

    if (!canUpload && !canView && !canDelete) return;

    if (canView && hasImage && !canUpload && !canDelete) {
      await _viewImage(imageValue);
      return;
    }

    await _showOptionsBottomSheet(hasImage, canUpload, canView, canDelete);
  }

  Future<void> _showOptionsBottomSheet(
    bool hasImage,
    bool canUpload,
    bool canView,
    bool canDelete,
  ) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ImageOptionsSheet(
        hasImage: hasImage,
        canUpload: canUpload,
        canView: canView,
        canDelete: canDelete,
        uploadIcon: widget.uploadIcon,
        viewIcon: widget.viewIcon,
        deleteIcon: widget.deleteIcon,
        onCamera: () async {
          Navigator.pop(context);
          await _captureFromCamera();
        },
        onGallery: () async {
          Navigator.pop(context);
          await _pickFromGallery();
        },
        onView: () async {
          Navigator.pop(context);
          final imageValue = _getCurrentValue();
          if (imageValue != null && imageValue.isNotEmpty) {
            await _viewImage(imageValue);
          }
        },
        onDelete: () async {
          Navigator.pop(context);
          await _deleteImage();
        },
      ),
    );
  }

  Future<void> _captureFromCamera() async {
    setState(() => _isLoading = true);

    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: widget.enableCompression
            ? widget.compressionQuality
            : 100,
        maxWidth: widget.enableCompression ? widget.maxWidth?.toDouble() : null,
        maxHeight: widget.enableCompression
            ? widget.maxHeight?.toDouble()
            : null,
      );

      if (image != null) {
        final base64 = await _fileToBase64(File(image.path));
        _updateValue(base64);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi chụp ảnh: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickFromGallery() async {
    setState(() => _isLoading = true);

    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: widget.enableCompression
            ? widget.compressionQuality
            : 100,
        maxWidth: widget.enableCompression ? widget.maxWidth?.toDouble() : null,
        maxHeight: widget.enableCompression
            ? widget.maxHeight?.toDouble()
            : null,
      );

      if (image != null) {
        final base64 = await _fileToBase64(File(image.path));
        _updateValue(base64);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi chọn ảnh: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String> _fileToBase64(File file) async {
    final bytes = await file.readAsBytes();
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }

  Future<void> _viewImage(String imageValue) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullscreenImageViewer(
          imageValue: imageValue,
          isCircle: widget.isCircle,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _deleteImage() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa ảnh này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _updateValue(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible()) {
      return const SizedBox.shrink();
    }

    // ⭐ Optimized ListenableBuilder
    final listeners = <Listenable>[];
    if (_boundRow != null) listeners.add(_boundRow!);
    if (_fitBoundRow != null && _fitBoundRow != _boundRow) {
      listeners.add(_fitBoundRow!);
    }

    Widget buildImage() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isShowLabel &&
              widget.label != null &&
              widget.label!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
              child: Text(
                widget.label!,
                style:
                    widget.labelStyle ??
                    const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF555555),
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          _buildImageContainer(),
        ],
      );
    }

    if (listeners.isNotEmpty) {
      return ListenableBuilder(
        listenable: Listenable.merge(listeners),
        builder: (context, child) => buildImage(),
      );
    }

    return buildImage();
  }

  Widget _buildImageContainer() {
    final imageValue = _getCurrentValue();
    final hasImage = imageValue != null && imageValue.isNotEmpty;

    Widget imageWidget;

    if (_isLoading) {
      imageWidget = _buildLoading();
    } else if (hasImage) {
      imageWidget = _buildImageWidget(imageValue);
    } else {
      imageWidget = _buildPlaceholder();
    }

    return GestureDetector(
      onTap: widget.enabled ? _handleImageTap : null,
      child: Container(
        width: widget.width ?? double.infinity,
        height: widget.height,
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? Colors.grey[100],
          border: widget.borderColor != null
              ? Border.all(
                  color: widget.borderColor!,
                  width: widget.borderWidth,
                )
              : null,
          borderRadius: widget.isCircle
              ? null
              : BorderRadius.circular(widget.borderRadius),
          shape: widget.isCircle ? BoxShape.circle : BoxShape.rectangle,
        ),
        child: ClipRRect(
          borderRadius: widget.isCircle
              ? BorderRadius.circular(widget.height ?? 200)
              : BorderRadius.circular(widget.borderRadius),
          child: imageWidget,
        ),
      ),
    );
  }

  // ⭐ Get cached decoded bytes
  Uint8List? _getDecodedBytes(String imageValue) {
    // Return cached if same image
    if (_cachedImageValue == imageValue && _cachedBytes != null) {
      return _cachedBytes;
    }

    // Decode and cache
    if (imageValue.startsWith('data:image')) {
      try {
        final base64String = imageValue.split(',').last;
        _cachedBytes = base64Decode(base64String);
        _cachedImageValue = imageValue;
        return _cachedBytes;
      } catch (e) {
        return null;
      }
    }

    // Try decode without prefix
    try {
      _cachedBytes = base64Decode(imageValue);
      _cachedImageValue = imageValue;
      return _cachedBytes;
    } catch (e) {
      return null;
    }
  }

  Widget _buildImageWidget(String imageValue) {
    final boxFit = _parseFit();

    try {
      // Asset image
      if (imageValue.startsWith('assets/') ||
          imageValue.startsWith('asset/') ||
          imageValue.contains('assets/')) {
        return Image.asset(
          imageValue,
          fit: boxFit,
          cacheWidth: widget.maxWidth, // ⭐ Memory constraint
          cacheHeight: widget.maxHeight,
          errorBuilder: (context, error, stackTrace) {
            return widget.errorWidget ?? _buildErrorWidget();
          },
        );
      }

      // Base64 image - ⭐ Use cached bytes
      if (imageValue.startsWith('data:image') ||
          !imageValue.startsWith('http://') &&
              !imageValue.startsWith('https://') &&
              !imageValue.startsWith('/') &&
              !imageValue.contains('\\')) {
        final bytes = _getDecodedBytes(imageValue);
        if (bytes == null) {
          return widget.errorWidget ?? _buildErrorWidget();
        }

        return Image.memory(
          bytes,
          fit: boxFit,
          cacheWidth: widget.maxWidth, // ⭐ Memory constraint
          cacheHeight: widget.maxHeight,
          errorBuilder: (context, error, stackTrace) {
            return widget.errorWidget ?? _buildErrorWidget();
          },
        );
      }

      // Network image - ⭐ With memory management
      if (imageValue.startsWith('http://') ||
          imageValue.startsWith('https://')) {
        return CachedNetworkImage(
          imageUrl: imageValue,
          fit: boxFit,
          memCacheWidth: widget.maxWidth, // ⭐ Limit memory cache
          memCacheHeight: widget.maxHeight, // ⭐ Prevent OOM
          maxWidthDiskCache: widget.maxWidth,
          maxHeightDiskCache: widget.maxHeight,
          placeholder: (context, url) => _buildLoading(),
          errorWidget: (context, url, error) {
            return widget.errorWidget ?? _buildErrorWidget();
          },
        );
      }

      // Local file
      if (imageValue.startsWith('/') || imageValue.contains('\\')) {
        return Image.file(
          File(imageValue),
          fit: boxFit,
          cacheWidth: widget.maxWidth,
          cacheHeight: widget.maxHeight,
          errorBuilder: (context, error, stackTrace) {
            return widget.errorWidget ?? _buildErrorWidget();
          },
        );
      }

      return widget.errorWidget ?? _buildErrorWidget();
    } catch (e) {
      return widget.errorWidget ?? _buildErrorWidget();
    }
  }

  Widget _buildPlaceholder() {
    return widget.placeholder ??
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                _canUpload() ? 'Nhấn để thêm ảnh' : 'Chưa có ảnh',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        );
  }

  Widget _buildLoading() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            'Không thể tải ảnh',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

// Image options sheet - unchanged
class _ImageOptionsSheet extends StatelessWidget {
  final bool hasImage;
  final bool canUpload;
  final bool canView;
  final bool canDelete;
  final IconData? uploadIcon;
  final IconData? viewIcon;
  final IconData? deleteIcon;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onView;
  final VoidCallback onDelete;

  const _ImageOptionsSheet({
    required this.hasImage,
    required this.canUpload,
    required this.canView,
    required this.canDelete,
    this.uploadIcon,
    this.viewIcon,
    this.deleteIcon,
    required this.onCamera,
    required this.onGallery,
    required this.onView,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    'Chọn hành động',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
            if (canUpload) ...[
              _buildOption(
                icon: uploadIcon ?? Icons.camera_alt,
                iconColor: Colors.blue,
                label: 'Chụp ảnh',
                subtitle: 'Sử dụng camera',
                onTap: onCamera,
              ),
              _buildOption(
                icon: uploadIcon ?? Icons.photo_library,
                iconColor: Colors.green,
                label: 'Chọn ảnh',
                subtitle: 'Từ thư viện ảnh',
                onTap: onGallery,
              ),
            ],
            if (canView && hasImage)
              _buildOption(
                icon: viewIcon ?? Icons.visibility,
                iconColor: Colors.purple,
                label: 'Xem ảnh',
                subtitle: 'Xem toàn màn hình',
                onTap: onView,
              ),
            if (canDelete && hasImage)
              _buildOption(
                icon: deleteIcon ?? Icons.delete,
                iconColor: Colors.red,
                label: 'Xóa ảnh',
                subtitle: 'Xóa ảnh hiện tại',
                onTap: onDelete,
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

// ⭐ Optimized fullscreen viewer
class _FullscreenImageViewer extends StatefulWidget {
  final String imageValue;
  final bool isCircle;

  const _FullscreenImageViewer({
    required this.imageValue,
    required this.isCircle,
  });

  @override
  State<_FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<_FullscreenImageViewer> {
  Uint8List? _cachedBytes;

  @override
  void dispose() {
    _cachedBytes = null; // ⭐ Clear cache on dispose
    super.dispose();
  }

  Uint8List? _getDecodedBytes() {
    if (_cachedBytes != null) return _cachedBytes;

    if (widget.imageValue.startsWith('data:image')) {
      try {
        final base64String = widget.imageValue.split(',').last;
        _cachedBytes = base64Decode(base64String);
        return _cachedBytes;
      } catch (e) {
        return null;
      }
    }

    try {
      _cachedBytes = base64Decode(widget.imageValue);
      return _cachedBytes;
    } catch (e) {
      return null;
    }
  }

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
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: _buildImage(),
        ),
      ),
    );
  }

  Widget _buildImage() {
    try {
      // Base64 - ⭐ Use cached bytes
      if (widget.imageValue.startsWith('data:image') ||
          !widget.imageValue.startsWith('http://') &&
              !widget.imageValue.startsWith('https://') &&
              !widget.imageValue.startsWith('/') &&
              !widget.imageValue.contains('\\')) {
        final bytes = _getDecodedBytes();
        if (bytes != null) {
          return Image.memory(
            bytes,
            fit: BoxFit.contain,
            // ⭐ No size constraints for fullscreen
          );
        }
      }

      // Network image
      if (widget.imageValue.startsWith('http://') ||
          widget.imageValue.startsWith('https://')) {
        return CachedNetworkImage(
          imageUrl: widget.imageValue,
          fit: BoxFit.contain,
          placeholder: (context, url) =>
              const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) =>
              const Icon(Icons.broken_image, size: 64, color: Colors.white),
        );
      }

      // Local file
      if (widget.imageValue.startsWith('/') ||
          widget.imageValue.contains('\\')) {
        return Image.file(File(widget.imageValue), fit: BoxFit.contain);
      }

      return const Icon(Icons.broken_image, size: 64, color: Colors.white);
    } catch (e) {
      return const Icon(Icons.broken_image, size: 64, color: Colors.white);
    }
  }
}
