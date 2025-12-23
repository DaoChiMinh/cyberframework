import 'package:cyberframework/cyberframework.dart';

/// CyberImage - Image control với binding, upload, view, delete
class CyberImage extends StatefulWidget {
  /// Binding đến field chứa image (URL, path, hoặc base64)
  final dynamic text;

  /// Label hiển thị phía trên
  final String? label;

  /// Cho phép upload ảnh (chụp/chọn)
  final dynamic isUpload;

  /// Cho phép view ảnh fullscreen
  final dynamic isView;

  /// Cho phép xóa ảnh
  final dynamic isDelete;

  /// Chiều rộng của image
  final double? width;

  /// Chiều cao của image
  final double? height;

  /// Fit mode của image - Có thể binding
  /// Values: "fill", "cover", "contain", "fitwidth", "fitheight", "center", "scaledown"
  /// hoặc BoxFit enum
  final dynamic fit;

  /// Border radius
  final double borderRadius;

  /// Placeholder khi chưa có ảnh
  final Widget? placeholder;

  /// Widget hiển thị khi lỗi
  final Widget? errorWidget;

  /// Style cho label
  final TextStyle? labelStyle;

  /// Có hiển thị label không
  final bool isShowLabel;

  /// Callback khi ảnh thay đổi (upload/delete)
  final ValueChanged<String>? onChanged;

  /// Callback khi rời khỏi control
  final Function(dynamic)? onLeaver;

  /// Màu nền
  final Color? backgroundColor;

  /// Border color
  final Color? borderColor;

  /// Border width
  final double borderWidth;

  /// Có enable hay không
  final bool enabled;

  /// Visibility binding
  final dynamic isVisible;

  /// Có nén ảnh khi upload không
  final bool enableCompression;

  /// Chất lượng nén (0-100)
  final int compressionQuality;

  /// Kích thước max sau khi nén
  final int? maxWidth;
  final int? maxHeight;

  /// Icon cho các action buttons
  final IconData? uploadIcon;
  final IconData? viewIcon;
  final IconData? deleteIcon;

  /// Shape của image (circle hoặc rectangle)
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
    this.fit = "cover", // Default is cover
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
  CyberDataRow? _boundRow;
  String? _boundField;
  CyberDataRow? _visibilityBoundRow;
  String? _visibilityBoundField;
  CyberDataRow? _fitBoundRow;
  String? _fitBoundField;
  bool _isUpdating = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _parseBinding();
    _parseVisibilityBinding();
    _parseFitBinding();

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

  @override
  void dispose() {
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
    super.dispose();
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

  bool _isVisible() {
    if (_visibilityBoundRow != null && _visibilityBoundField != null) {
      return _parseBool(_visibilityBoundRow![_visibilityBoundField!]);
    }
    return _parseBool(widget.isVisible);
  }

  /// Parse fit value to BoxFit
  BoxFit _parseFit() {
    dynamic fitValue;

    // Get fit value from binding or direct value
    if (_fitBoundRow != null && _fitBoundField != null) {
      try {
        fitValue = _fitBoundRow![_fitBoundField!];
      } catch (e) {
        fitValue = widget.fit;
      }
    } else if (widget.fit != null && widget.fit is! CyberBindingExpression) {
      fitValue = widget.fit;
    } else {
      return BoxFit.cover; // Default
    }

    // If already BoxFit, return it
    if (fitValue is BoxFit) {
      return fitValue;
    }

    // Parse string to BoxFit
    if (fitValue is String) {
      final fitString = fitValue.toLowerCase().trim();

      switch (fitString) {
        case 'fill':
          return BoxFit.fill;
        case 'contain':
          return BoxFit.contain;
        case 'cover':
          return BoxFit.cover;
        case 'fitwidth':
        case 'fit_width':
        case 'width':
          return BoxFit.fitWidth;
        case 'fitheight':
        case 'fit_height':
        case 'height':
          return BoxFit.fitHeight;
        case 'center':
        case 'none':
          return BoxFit.none;
        case 'scaledown':
        case 'scale_down':
        case 'scale':
          return BoxFit.scaleDown;
        default:
          return BoxFit.cover;
      }
    }

    return BoxFit.cover; // Default
  }

  void _onBindingChanged() {
    if (_isUpdating) return;
    setState(() {});
  }

  /// Get current image value
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

  /// Update image value
  void _updateValue(String? newValue) {
    if (!widget.enabled) return;

    _isUpdating = true;

    // Update binding
    if (_boundRow != null && _boundField != null) {
      _boundRow![_boundField!] = newValue ?? '';
    }

    // Callbacks
    widget.onChanged?.call(newValue ?? '');
    widget.onLeaver?.call(newValue);

    setState(() {
      _isUpdating = false;
    });
  }

  /// Check if can upload
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

  /// Check if can view
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

  /// Check if can delete
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

  /// Handle image tap
  Future<void> _handleImageTap() async {
    if (!widget.enabled) return;

    final imageValue = _getCurrentValue();
    final hasImage = imageValue != null && imageValue.isNotEmpty;

    final canUpload = _canUpload();
    final canView = _canView();
    final canDelete = _canDelete();

    // Nếu không có action nào thì return
    if (!canUpload && !canView && !canDelete) return;

    // Nếu chỉ có view và có ảnh thì view luôn
    if (canView && hasImage && !canUpload && !canDelete) {
      await _viewImage(imageValue);
      return;
    }

    // Show bottom sheet với options
    await _showOptionsBottomSheet(hasImage, canUpload, canView, canDelete);
  }

  /// Show options bottom sheet
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

  /// Capture from camera
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

  /// Pick from gallery
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

  /// Convert file to base64
  Future<String> _fileToBase64(File file) async {
    final bytes = await file.readAsBytes();
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }

  /// View image fullscreen
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

  /// Delete image with confirmation
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

    Widget buildImage() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label
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

          // Image container
          _buildImageContainer(),
        ],
      );
    }

    // Wrap with ListenableBuilder if has binding
    final listeners = <Listenable>[];
    if (_boundRow != null) listeners.add(_boundRow!);
    if (_fitBoundRow != null && _fitBoundRow != _boundRow) {
      listeners.add(_fitBoundRow!);
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

    // Wrap with GestureDetector
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

  Widget _buildImageWidget(String imageValue) {
    final boxFit = _parseFit();

    try {
      // Check if base64
      if (imageValue.startsWith('data:image')) {
        final base64String = imageValue.split(',').last;
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          fit: boxFit,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return widget.errorWidget ?? _buildErrorWidget();
          },
        );
      }

      // Check if URL
      if (imageValue.startsWith('http://') ||
          imageValue.startsWith('https://')) {
        return CachedNetworkImage(
          imageUrl: imageValue,
          fit: boxFit,
          width: double.infinity,
          height: double.infinity,
          placeholder: (context, url) => _buildLoading(),
          errorWidget: (context, url, error) {
            return widget.errorWidget ?? _buildErrorWidget();
          },
        );
      }

      // Check if local file path
      if (imageValue.startsWith('/') || imageValue.contains('\\')) {
        return Image.file(
          File(imageValue),
          fit: boxFit,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return widget.errorWidget ?? _buildErrorWidget();
          },
        );
      }

      // Try to decode as base64 without prefix
      try {
        final bytes = base64Decode(imageValue);
        return Image.memory(
          bytes,
          fit: boxFit,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return widget.errorWidget ?? _buildErrorWidget();
          },
        );
      } catch (e) {
        return widget.errorWidget ?? _buildErrorWidget();
      }
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

/// Image options bottom sheet
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
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
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

            // Options
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

/// Fullscreen image viewer
class _FullscreenImageViewer extends StatelessWidget {
  final String imageValue;
  final bool isCircle;

  const _FullscreenImageViewer({
    required this.imageValue,
    required this.isCircle,
  });

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
      // Check if base64
      if (imageValue.startsWith('data:image')) {
        final base64String = imageValue.split(',').last;
        final bytes = base64Decode(base64String);
        return Image.memory(bytes, fit: BoxFit.contain);
      }

      // Check if URL
      if (imageValue.startsWith('http://') ||
          imageValue.startsWith('https://')) {
        return CachedNetworkImage(
          imageUrl: imageValue,
          fit: BoxFit.contain,
          placeholder: (context, url) =>
              const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) =>
              const Icon(Icons.broken_image, size: 64, color: Colors.white),
        );
      }

      // Check if local file path
      if (imageValue.startsWith('/') || imageValue.contains('\\')) {
        return Image.file(File(imageValue), fit: BoxFit.contain);
      }

      // Try to decode as base64 without prefix
      try {
        final bytes = base64Decode(imageValue);
        return Image.memory(bytes, fit: BoxFit.contain);
      } catch (e) {
        return const Icon(Icons.broken_image, size: 64, color: Colors.white);
      }
    } catch (e) {
      return const Icon(Icons.broken_image, size: 64, color: Colors.white);
    }
  }
}
