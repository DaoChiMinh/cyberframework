import 'package:cyberframework/Controller/cyber_fullscreen_image_viewer.dart';
import 'package:cyberframework/Controller/cyber_image_cache_manager.dart';
import 'package:cyberframework/cyberframework.dart';

/// ============================================================================
/// CyberImage - Internal Controller + Binding Pattern
/// ============================================================================
///
/// TRIẾT LÝ:
/// 1. Thuộc tính `text` là PRIMARY SOURCE - có thể binding trực tiếp
/// 2. Controller (nếu có) chỉ để điều khiển programmatically
/// 3. Nếu không truyền controller → tự tạo internal controller
/// 4. Sync 2 chiều: text binding <-> controller <-> UI
///
/// CÁCH DÙNG:
///
/// // Cách 1: Chỉ binding (không cần controller)
/// CyberImage(
///   text: drEdit.bind("image_url"),
///   label: "Ảnh đại diện",
///   isUpload: true,
/// )
///
/// // Cách 2: Có controller để điều khiển
/// final imageCtrl = CyberImageController();
/// CyberImage(
///   controller: imageCtrl,
///   text: drEdit.bind("image_url"), // Vẫn binding được
///   label: "Ảnh đại diện",
/// )
/// imageCtrl.triggerUpload(); // Trigger action
///
/// ============================================================================

class CyberImage extends StatefulWidget {
  final CyberImageController? controller;

  /// Thuộc tính text - có thể binding với CyberDataRow
  /// Hỗ trợ: String, CyberBindingExpression, null
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

  /// Callbacks
  final ValueChanged<String>? onChanged;
  final Function(dynamic)? onLeaver;
  final VoidCallback? onUploadRequested;
  final VoidCallback? onViewRequested;
  final VoidCallback? onDeleteRequested;

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
    this.controller,
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
    this.onUploadRequested,
    this.onViewRequested,
    this.onDeleteRequested,
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
  /// Internal controller (tự tạo nếu không có từ bên ngoài)
  CyberImageController? _internalController;

  /// Binding references
  CyberDataRow? _boundRow;
  String? _boundField;

  /// Visibility binding
  CyberDataRow? _visibilityBoundRow;
  String? _visibilityBoundField;

  /// Fit binding
  CyberDataRow? _fitBoundRow;
  String? _fitBoundField;

  /// State flags
  bool _isSyncing = false;
  bool _isLoading = false;

  /// Cache
  bool? _cachedVisibility;
  BoxFit? _cachedFit;

  /// Global cache manager
  final _cacheManager = CyberImageCacheManager();

  /// Effective controller - luôn có giá trị
  CyberImageController get _effectiveController =>
      widget.controller ?? _internalController!;

  @override
  void initState() {
    super.initState();
    _initializeController();
    _initializeBindings();
  }

  void _initializeController() {
    // Tạo internal controller nếu chưa có
    if (widget.controller == null) {
      _internalController = CyberImageController();
    }

    // Sync initial value từ binding vào controller
    final initialValue = _getValueFromBinding();
    _effectiveController.syncFromBinding(initialValue);

    // Listen controller changes
    _effectiveController.addListener(_onControllerChanged);
  }

  void _initializeBindings() {
    _parseTextBinding();
    _parseVisibilityBinding();
    _parseFitBinding();
    _addAllListeners();
  }

  /// ============================================================================
  /// BINDING PARSING
  /// ============================================================================

  void _parseTextBinding() {
    if (widget.text is CyberBindingExpression) {
      final expr = widget.text as CyberBindingExpression;
      _boundRow = expr.row;
      _boundField = expr.fieldName;
    } else {
      _boundRow = null;
      _boundField = null;
    }
  }

  void _parseVisibilityBinding() {
    if (widget.isVisible is CyberBindingExpression) {
      final expr = widget.isVisible as CyberBindingExpression;
      _visibilityBoundRow = expr.row;
      _visibilityBoundField = expr.fieldName;
    } else {
      _visibilityBoundRow = null;
      _visibilityBoundField = null;
    }
  }

  void _parseFitBinding() {
    if (widget.fit is CyberBindingExpression) {
      final expr = widget.fit as CyberBindingExpression;
      _fitBoundRow = expr.row;
      _fitBoundField = expr.fieldName;
    } else {
      _fitBoundRow = null;
      _fitBoundField = null;
    }
  }

  /// ============================================================================
  /// LISTENER MANAGEMENT
  /// ============================================================================

  void _addAllListeners() {
    if (_boundRow != null) {
      _boundRow!.addListener(_onBindingChanged);
    }
    if (_visibilityBoundRow != null && _visibilityBoundRow != _boundRow) {
      _visibilityBoundRow!.addListener(_onVisibilityBindingChanged);
    }
    if (_fitBoundRow != null &&
        _fitBoundRow != _boundRow &&
        _fitBoundRow != _visibilityBoundRow) {
      _fitBoundRow!.addListener(_onFitBindingChanged);
    }
  }

  void _removeAllListeners() {
    if (_boundRow != null) {
      _boundRow!.removeListener(_onBindingChanged);
    }
    if (_visibilityBoundRow != null && _visibilityBoundRow != _boundRow) {
      _visibilityBoundRow!.removeListener(_onVisibilityBindingChanged);
    }
    if (_fitBoundRow != null &&
        _fitBoundRow != _boundRow &&
        _fitBoundRow != _visibilityBoundRow) {
      _fitBoundRow!.removeListener(_onFitBindingChanged);
    }
  }

  /// ============================================================================
  /// SYNC LOGIC: BINDING <-> CONTROLLER <-> UI
  /// ============================================================================

  /// Khi binding thay đổi → sync vào controller
  void _onBindingChanged() {
    if (_isSyncing || !mounted) return;

    final newValue = _getValueFromBinding();
    if (newValue != _effectiveController.imageUrl) {
      _isSyncing = true;
      _effectiveController.syncFromBinding(newValue);
      _isSyncing = false;

      if (mounted) {
        setState(() {});
      }
    }
  }

  /// Khi visibility binding thay đổi
  void _onVisibilityBindingChanged() {
    if (!mounted) return;
    _cachedVisibility = null;
    setState(() {});
  }

  /// Khi fit binding thay đổi
  void _onFitBindingChanged() {
    if (!mounted) return;
    _cachedFit = null;
    setState(() {});
  }

  /// Khi controller thay đổi → sync ra binding và UI
  void _onControllerChanged() {
    if (_isSyncing || !mounted) return;

    // Handle pending actions
    final action = _effectiveController.pendingAction;
    if (action != CyberImageAction.none) {
      _handlePendingAction(action);
      return;
    }

    // Handle URL change
    final controllerUrl = _effectiveController.imageUrl;
    final bindingUrl = _getValueFromBinding();

    if (controllerUrl != bindingUrl) {
      _isSyncing = true;

      // Sync controller → binding
      if (_boundRow != null && _boundField != null) {
        _boundRow![_boundField!] = controllerUrl ?? '';
      }

      _isSyncing = false;
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _handlePendingAction(CyberImageAction action) {
    if (!mounted) return;

    final imageUrl = _getCurrentValue();
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    switch (action) {
      case CyberImageAction.upload:
        _showOptionsBottomSheet(hasImage, true, false, false);
        break;
      case CyberImageAction.view:
        if (hasImage) {
          _viewImage(imageUrl);
        }
        break;
      case CyberImageAction.delete:
        _deleteImage();
        break;
      case CyberImageAction.none:
        break;
    }
  }

  /// ============================================================================
  /// VALUE GETTERS
  /// ============================================================================

  /// Lấy value từ binding (nếu có)
  String? _getValueFromBinding() {
    if (_boundRow != null && _boundField != null) {
      try {
        final value = _boundRow![_boundField!];
        return value?.toString();
      } catch (e) {
        return null;
      }
    } else if (widget.text != null && widget.text is! CyberBindingExpression) {
      // Static value
      return widget.text.toString();
    }
    return null;
  }

  /// Lấy current value (ưu tiên controller)
  String? _getCurrentValue() {
    // Priority 1: Controller value
    final controllerValue = _effectiveController.imageUrl;
    if (controllerValue != null && controllerValue.isNotEmpty) {
      return controllerValue;
    }

    // Priority 2: Binding value
    return _getValueFromBinding();
  }

  /// ============================================================================
  /// UPDATE VALUE
  /// ============================================================================

  void _updateValue(String? newValue) {
    if (!_effectiveController.enabled || !widget.enabled || _isSyncing) return;

    _isSyncing = true;

    // Update controller
    _effectiveController.loadUrl(newValue);

    // Update binding
    if (_boundRow != null && _boundField != null) {
      _boundRow![_boundField!] = newValue ?? '';
    }

    // Callbacks
    widget.onChanged?.call(newValue ?? '');
    widget.onLeaver?.call(newValue);

    _isSyncing = false;

    if (mounted) {
      setState(() {});
    }
  }

  /// ============================================================================
  /// VISIBILITY & FIT
  /// ============================================================================

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

  /// ============================================================================
  /// IMAGE ACTIONS
  /// ============================================================================

  Future<void> _handleImageTap() async {
    if (!_effectiveController.enabled || !widget.enabled) return;

    final imageValue = _getCurrentValue();
    final hasImage = imageValue != null && imageValue.isNotEmpty;

    final canUpload = _canUpload();
    final canView = _canView();
    final canDelete = _canDelete();

    if (!canUpload && !canView && !canDelete) return;

    // Simple case: chỉ view
    if (canView && hasImage && !canUpload && !canDelete) {
      widget.onViewRequested?.call();
      await _viewImage(imageValue);
      return;
    }

    if (!mounted) return;
    await _showOptionsBottomSheet(hasImage, canUpload, canView, canDelete);
  }

  Future<void> _showOptionsBottomSheet(
    bool hasImage,
    bool canUpload,
    bool canView,
    bool canDelete,
  ) async {
    if (!mounted) return;

    try {
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
              widget.onViewRequested?.call();
              await _viewImage(imageValue);
            }
          },
          onDelete: () async {
            Navigator.pop(context);
            widget.onDeleteRequested?.call();
            await _deleteImage();
          },
        ),
      );
    } catch (e) {
      debugPrint('Error showing bottom sheet: $e');
    }
  }

  Future<void> _captureFromCamera() async {
    widget.onUploadRequested?.call();

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
    widget.onUploadRequested?.call();

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
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CyberFullscreenImageViewer(
          imageValue: imageValue,
          isCircle: widget.isCircle,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _deleteImage() async {
    if (!mounted) return;

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

  /// ============================================================================
  /// WIDGET LIFECYCLE
  /// ============================================================================

  @override
  void didUpdateWidget(CyberImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Controller changed
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onControllerChanged);

      if (widget.controller == null && _internalController == null) {
        _internalController = CyberImageController();
      }

      final currentValue = _getValueFromBinding();
      _effectiveController.syncFromBinding(currentValue);
      _effectiveController.addListener(_onControllerChanged);
    }

    // Bindings changed
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

      // Sync new binding value to controller
      final newValue = _getValueFromBinding();
      _effectiveController.syncFromBinding(newValue);
    }
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_onControllerChanged);
    _removeAllListeners();
    _cachedVisibility = null;
    _cachedFit = null;
    _internalController?.dispose();
    super.dispose();
  }

  /// ============================================================================
  /// BUILD UI
  /// ============================================================================

  @override
  Widget build(BuildContext context) {
    if (!_isVisible()) {
      return const SizedBox.shrink();
    }

    final listeners = <Listenable>[];
    if (_boundRow != null) listeners.add(_boundRow!);
    if (_fitBoundRow != null && _fitBoundRow != _boundRow) {
      listeners.add(_fitBoundRow!);
    }
    if (_visibilityBoundRow != null &&
        _visibilityBoundRow != _boundRow &&
        _visibilityBoundRow != _fitBoundRow) {
      listeners.add(_visibilityBoundRow!);
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
    final isEnabled = _effectiveController.enabled && widget.enabled;

    Widget imageWidget;

    if (_isLoading) {
      imageWidget = _buildLoading();
    } else if (hasImage) {
      imageWidget = _buildImageWidget(imageValue);
    } else {
      imageWidget = _buildPlaceholder();
    }

    return GestureDetector(
      onTap: isEnabled ? _handleImageTap : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
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
      ),
    );
  }

  Uint8List? _getImageBytes(String imageValue) {
    return _cacheManager.getOrDecodeBase64(imageValue);
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
          cacheWidth: widget.maxWidth,
          cacheHeight: widget.maxHeight,
          errorBuilder: (context, error, stackTrace) {
            return widget.errorWidget ?? _buildErrorWidget();
          },
        );
      }

      // Network image
      if (imageValue.startsWith('http://') ||
          imageValue.startsWith('https://')) {
        return CachedNetworkImage(
          imageUrl: imageValue,
          fit: boxFit,
          memCacheWidth: widget.maxWidth,
          memCacheHeight: widget.maxHeight,
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

      // Base64
      final bytes = _getImageBytes(imageValue);
      if (bytes == null) {
        return widget.errorWidget ?? _buildErrorWidget();
      }

      return Image.memory(
        bytes,
        fit: boxFit,
        cacheWidth: widget.maxWidth,
        cacheHeight: widget.maxHeight,
        errorBuilder: (context, error, stackTrace) {
          return widget.errorWidget ?? _buildErrorWidget();
        },
      );
    } catch (e) {
      return widget.errorWidget ?? _buildErrorWidget();
    }
  }

  /// ✅ FIX: Placeholder responsive với kích thước nhỏ
  Widget _buildPlaceholder() {
    if (widget.placeholder != null) return widget.placeholder!;

    final height = widget.height ?? 200;
    final isSmall = height < 120;

    return Center(
      child: isSmall
          ? Icon(
              Icons.image_outlined,
              size: height * 0.4, // Scale icon theo height
              color: Colors.grey[400],
            )
          : Column(
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
    final height = widget.height ?? 200;
    final isSmall = height < 120;

    return Center(
      child: SizedBox(
        width: isSmall ? height * 0.3 : 40,
        height: isSmall ? height * 0.3 : 40,
        child: const CircularProgressIndicator(strokeWidth: 3),
      ),
    );
  }

  /// ✅ FIX: Error widget responsive với kích thước nhỏ
  Widget _buildErrorWidget() {
    final height = widget.height ?? 200;
    final isSmall = height < 120;

    return Center(
      child: isSmall
          ? Icon(
              Icons.broken_image,
              size: height * 0.4, // Scale icon theo height
              color: Colors.grey[400],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  'Lỗi tải ảnh',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
    );
  }
}

/// ============================================================================
/// Image Options Bottom Sheet
/// ============================================================================

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
