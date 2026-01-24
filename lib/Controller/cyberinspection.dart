import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cyberframework/Module/file_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cyberframework/cyberframework.dart';

// ============================================================================
// CYBER CAR INSPECTION CONTROL
// ============================================================================
//
// Sử dụng:
// ```dart
// CyberCarInspection(
//   image: 'https://example.com/car.png',
//   dtType: dtLoaiLoi,
//   dtData: dtDiemLoi,
//   // Custom column keys
//   codeField: 'Ma_Loi',
//   nameField: 'Ten_Loi',
//   colorField: 'Mau_Sac',
//   iconField: 'Icon',
//   // Binding base64 to CyberDataRow
//   strBase64: drEdit.bind('hinh_anh'),
//   // Show download/share buttons
//   showDownload: true,
//   showShare: true,
//   // Hoặc custom item builder
//   itemBuilder: (row, isSelected, count, onTap) => MyCustomWidget(...),
// )
// ```
// ============================================================================

/// Controller để quản lý CyberCarInspection
class CyberCarInspectionController extends ChangeNotifier {
  String? _selectedDefectCode;
  _CyberCarInspectionState? _state;

  String? get selectedDefectCode => _selectedDefectCode;

  set selectedDefectCode(String? value) {
    if (_selectedDefectCode != value) {
      _selectedDefectCode = value;
      notifyListeners();
    }
  }

  void clearSelection() {
    selectedDefectCode = null;
  }

  /// Attach state (internal use)
  void _attachState(_CyberCarInspectionState state) {
    _state = state;
  }

  /// Detach state (internal use)
  void _detachState() {
    _state = null;
  }

  /// Export hình ảnh thành base64
  Future<String?> exportToBase64() async {
    return await _state?.exportToBase64();
  }

  /// Download hình ảnh
  Future<void> download(BuildContext context) async {
    await _state?._downloadImage(context);
  }

  /// Share hình ảnh
  Future<void> share(BuildContext context) async {
    await _state?._shareImage(context);
  }
}

/// Callback để build custom item trong danh sách loại lỗi
/// [count] là số lượng điểm lỗi của loại này
typedef DefectTypeItemBuilder =
    Widget Function(
      CyberDataRow row,
      bool isSelected,
      int count,
      VoidCallback onTap,
    );

/// Callback để build custom marker trên hình ảnh
typedef DefectMarkerBuilder =
    Widget Function(CyberDataRow dataRow, CyberDataRow? typeRow, double size);

/// Widget chính CyberCarInspection
class CyberCarInspection extends StatefulWidget {
  /// Hình ảnh xe - hỗ trợ nhiều loại:
  /// - String: URL, file path, hoặc base64
  /// - Uint8List: byte array
  /// - List<int>: byte array
  /// - ImageProvider: NetworkImage, AssetImage, FileImage, MemoryImage
  final dynamic image;

  /// Bảng loại lỗi
  final CyberDataTable dtType;

  /// Bảng dữ liệu điểm lỗi
  final CyberDataTable dtData;

  // ========================
  // COLUMN KEYS - dtType
  // ========================

  /// Tên cột mã lỗi trong dtType (default: 'Ma_Loi')
  final String codeField;

  /// Tên cột tên lỗi trong dtType (default: 'Ten_Loi')
  final String nameField;

  /// Tên cột màu sắc trong dtType (default: 'Mau_Sac')
  final String colorField;

  /// Tên cột icon trong dtType (default: 'Icon')
  final String iconField;
  final String iconcolor;
  // ========================
  // COLUMN KEYS - dtData
  // ========================

  /// Tên cột mã lỗi trong dtData (default: 'Ma_Loi')
  final String dataCodeField;

  /// Tên cột X trong dtData (default: 'X')
  final String xField;

  /// Tên cột Y trong dtData (default: 'Y')
  final String yField;

  /// Tên cột chiều rộng ảnh trong dtData (default: 'WidthImg')
  final String widthField;

  /// Tên cột chiều cao ảnh trong dtData (default: 'HeightImg')
  final String heightField;

  // ========================
  // CUSTOM BUILDERS
  // ========================

  /// Custom builder cho item trong danh sách loại lỗi
  /// Nếu null, sử dụng default builder
  final DefectTypeItemBuilder? itemBuilder;

  /// Custom builder cho marker trên hình ảnh
  /// Nếu null, sử dụng default builder
  final DefectMarkerBuilder? markerBuilder;

  // ========================
  // OTHER OPTIONS
  // ========================

  /// Controller (optional)
  final CyberCarInspectionController? controller;

  /// Cho phép chỉnh sửa
  final bool enabled;

  /// Kích thước icon lỗi
  final double iconSize;

  /// Callback khi dữ liệu thay đổi
  final VoidCallback? onDataChanged;

  /// Border radius
  final double borderRadius;

  /// Hiển thị phần chọn loại lỗi
  final bool showTypeSelector;

  /// Chiều cao placeholder khi không có ảnh
  final double placeholderHeight;

  /// Padding cho type selector
  final EdgeInsets typeSelectorPadding;

  /// Spacing giữa các item trong type selector
  final double itemSpacing;

  /// Run spacing cho type selector
  final double itemRunSpacing;

  // ========================
  // EXPORT OPTIONS
  // ========================

  /// Hiển thị nút tải xuống
  final bool showDownload;

  /// Hiển thị nút chia sẻ
  final bool showShare;

  /// Binding base64 vào CyberDataRow
  /// Hỗ trợ: CyberBindingExpression, String
  /// Khi capture hình sẽ tự động cập nhật giá trị base64
  final dynamic strBase64;

  /// Callback khi export thành công
  final void Function(String base64)? onExported;

  /// Tên file khi export (không có extension)
  final String exportFileName;

  const CyberCarInspection({
    super.key,
    this.image,
    required this.dtType,
    required this.dtData,
    // Column keys - dtType
    this.codeField = 'Ma_Loi',
    this.nameField = 'Ten_Loi',
    this.colorField = 'backcolor',
    this.iconField = 'Icon',
    this.iconcolor = 'textcolor',
    // Column keys - dtData
    this.dataCodeField = 'Ma_Loi',
    this.xField = 'X',
    this.yField = 'Y',
    this.widthField = 'WidthImg',
    this.heightField = 'HeightImg',
    // Custom builders
    this.itemBuilder,
    this.markerBuilder,
    // Other options
    this.controller,
    this.enabled = true,
    this.iconSize = 28,
    this.onDataChanged,
    this.borderRadius = 8,
    this.showTypeSelector = true,
    this.placeholderHeight = 300,
    this.typeSelectorPadding = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 8,
    ),
    this.itemSpacing = 12,
    this.itemRunSpacing = 8,
    // Export options
    this.showDownload = false,
    this.showShare = false,
    this.strBase64,
    this.onExported,
    this.exportFileName = 'car_inspection',
  });

  @override
  State<CyberCarInspection> createState() => _CyberCarInspectionState();
}

class _CyberCarInspectionState extends State<CyberCarInspection> {
  final GlobalKey _imageKey = GlobalKey();
  final GlobalKey _captureKey = GlobalKey(); // Key để capture toàn bộ widget
  Size? _imageSize;
  late CyberCarInspectionController _controller;
  bool _isInternalController = false;
  bool _isExporting = false;

  ImageProvider? _imageProvider;
  dynamic _lastImageInput;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? CyberCarInspectionController();
    _isInternalController = widget.controller == null;
    _controller.addListener(_onControllerChanged);
    _controller._attachState(this); // Attach state vào controller
    _updateImageProvider();

    WidgetsBinding.instance.addPostFrameCallback((_) => _updateImageSize());
  }

  @override
  void didUpdateWidget(CyberCarInspection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.image != _lastImageInput) {
      _updateImageProvider();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller._detachState(); // Detach state từ controller
    if (_isInternalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _updateImageProvider() {
    _lastImageInput = widget.image;
    _imageProvider = _resolveImageProvider(widget.image);
  }

  ImageProvider? _resolveImageProvider(dynamic image) {
    if (image == null) return null;

    if (image is ImageProvider) return image;

    if (image is Uint8List) return MemoryImage(image);

    if (image is List<int>) return MemoryImage(Uint8List.fromList(image));

    if (image is String) {
      final str = image.trim();
      if (str.isEmpty) return null;

      // Base64 với data URI prefix
      if (str.startsWith('data:image')) {
        try {
          final base64Str = str.split(',').last;
          return MemoryImage(base64Decode(base64Str));
        } catch (e) {
          debugPrint('❌ Error decoding data URI: $e');
          return null;
        }
      }

      // URL
      if (str.startsWith('http://') || str.startsWith('https://')) {
        return NetworkImage(str);
      }

      // File path
      if (str.startsWith('/') ||
          str.contains(':\\') ||
          str.startsWith('file://')) {
        final filePath = str.startsWith('file://') ? str.substring(7) : str;
        final file = File(filePath);
        if (file.existsSync()) return FileImage(file);
        return null;
      }

      // Asset path
      if (str.startsWith('assets/') || str.startsWith('asset/')) {
        return AssetImage(str);
      }

      // Base64 thuần
      if (_isValidBase64(str)) {
        try {
          return MemoryImage(base64Decode(str));
        } catch (e) {
          debugPrint('❌ Error decoding base64: $e');
          return null;
        }
      }

      return AssetImage(str);
    }

    return null;
  }

  bool _isValidBase64(String str) {
    final cleaned = str.replaceAll(RegExp(r'\s'), '');
    if (cleaned.isEmpty || cleaned.length < 20) return false;

    final base64Regex = RegExp(r'^[A-Za-z0-9+/]*={0,2}$');
    if (!base64Regex.hasMatch(cleaned)) return false;

    final imagePatterns = ['iVBOR', '/9j/', 'R0lGOD', 'UklGR', 'Qk0'];
    return imagePatterns.any((p) => cleaned.startsWith(p));
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  void _updateImageSize() {
    final RenderBox? box =
        _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      setState(() => _imageSize = box.size);
    }
  }

  void _handleTap(TapDownDetails details) {
    if (!widget.enabled) return;

    _updateImageSize();
    if (_imageSize == null) return;

    final tapPosition = details.localPosition;
    final tappedIndex = _findTappedPointIndex(tapPosition);

    if (tappedIndex != null) {
      _removePoint(tappedIndex);
    } else if (_controller.selectedDefectCode != null) {
      _addPoint(tapPosition);
    }
  }

  int? _findTappedPointIndex(Offset tapPosition) {
    if (_imageSize == null) return null;

    // Chỉ xóa khi click vào trong phạm vi icon
    final hitRadius = widget.iconSize / 2;

    for (int i = 0; i < widget.dtData.rowCount; i++) {
      final row = widget.dtData[i];

      final x = row.getDouble(widget.xField);
      final y = row.getDouble(widget.yField);
      final widthImg = row.getDouble(widget.widthField);
      final heightImg = row.getDouble(widget.heightField);

      final actualX = widthImg > 0 ? (x / widthImg) * _imageSize!.width : x;
      final actualY = heightImg > 0 ? (y / heightImg) * _imageSize!.height : y;

      final distance = (Offset(actualX, actualY) - tapPosition).distance;
      if (distance <= hitRadius) return i;
    }
    return null;
  }

  void _addPoint(Offset position) {
    final newRow = widget.dtData.newRow();
    newRow[widget.dataCodeField] = _controller.selectedDefectCode;
    newRow[widget.xField] = position.dx;
    newRow[widget.yField] = position.dy;
    newRow[widget.widthField] = _imageSize!.width;
    newRow[widget.heightField] = _imageSize!.height;

    widget.dtData.addRow(newRow);

    setState(() {});
    widget.onDataChanged?.call();
  }

  void _removePoint(int index) {
    widget.dtData.removeAt(index);
    setState(() {});
    widget.onDataChanged?.call();
  }

  CyberDataRow? _getDefectType(String code) {
    return widget.dtType.findRow(
      (row) => row.getString(widget.codeField) == code,
    );
  }

  /// Đếm số lượng điểm lỗi theo mã
  int _countDefectsByCode(String code) {
    int count = 0;
    for (int i = 0; i < widget.dtData.rowCount; i++) {
      if (widget.dtData[i].getString(widget.dataCodeField) == code) {
        count++;
      }
    }
    return count;
  }

  // ============================================================================
  // EXPORT METHODS
  // ============================================================================

  /// Capture widget thành hình ảnh PNG bytes
  Future<Uint8List?> _captureImage() async {
    try {
      final boundary =
          _captureKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) {
        debugPrint('❌ Cannot find RenderRepaintBoundary');
        return null;
      }

      // Đợi render hoàn tất
      await Future.delayed(const Duration(milliseconds: 100));

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        debugPrint('❌ Cannot convert image to bytes');
        return null;
      }

      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('❌ Capture error: $e');
      return null;
    }
  }

  /// Cập nhật base64 vào binding
  void _updateBase64Binding(String base64) {
    if (widget.strBase64 != null) {
      if (widget.strBase64 is CyberBindingExpression) {
        (widget.strBase64 as CyberBindingExpression).value = base64;
      }
    }
    widget.onExported?.call(base64);
  }

  /// Export và trả về base64
  Future<String?> exportToBase64() async {
    if (_isExporting) return null;

    setState(() => _isExporting = true);

    try {
      final bytes = await _captureImage();
      if (bytes == null) return null;

      final base64 = base64Encode(bytes);
      _updateBase64Binding(base64);

      return base64;
    } finally {
      setState(() => _isExporting = false);
    }
  }

  /// Download hình ảnh
  Future<void> _downloadImage(BuildContext context) async {
    if (_isExporting) return;

    setState(() => _isExporting = true);

    try {
      final bytes = await _captureImage();
      if (bytes == null) {
        if (context.mounted) {
          setText(
            'Không thể xuất hình ảnh',
            'Cannot export image',
          ).showToast(toastType: CyberToastType.error);
        }
        return;
      }

      // Cập nhật base64 binding
      final base64 = base64Encode(bytes);
      _updateBase64Binding(base64);

      // Download file
      if (context.mounted) {
        await FileHandler.downloadFile(
          source: base64,
          fileExtension: '.png',
          customFileName:
              '${widget.exportFileName}_${DateTime.now().millisecondsSinceEpoch}.png',
          context: context,
        );
      }
    } catch (e) {
      debugPrint('❌ Download error: $e');
      if (context.mounted) {
        setText(
          'Lỗi tải xuống',
          'Download error',
        ).showToast(toastType: CyberToastType.error);
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  /// Share hình ảnh
  Future<void> _shareImage(BuildContext context) async {
    if (_isExporting) return;

    setState(() => _isExporting = true);

    try {
      final bytes = await _captureImage();
      if (bytes == null) {
        if (context.mounted) {
          setText(
            'Không thể xuất hình ảnh',
            'Cannot export image',
          ).showToast(toastType: CyberToastType.error);
        }
        return;
      }

      // Cập nhật base64 binding
      final base64 = base64Encode(bytes);
      _updateBase64Binding(base64);

      // Share file
      if (context.mounted) {
        await FileHandler.shareFile(
          source: base64,
          fileExtension: '.png',
          fileName:
              '${widget.exportFileName}_${DateTime.now().millisecondsSinceEpoch}.png',
          subject: setText('Hình ảnh kiểm tra xe', 'Car Inspection Image'),
          context: context,
        );
      }
    } catch (e) {
      debugPrint('❌ Share error: $e');
      if (context.mounted) {
        setText(
          'Lỗi chia sẻ',
          'Share error',
        ).showToast(toastType: CyberToastType.error);
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.enabled && widget.showTypeSelector) ...[
          _buildDefectTypeSelector(),
          const SizedBox(height: 8),
        ],
        // Wrap với RepaintBoundary để capture
        RepaintBoundary(key: _captureKey, child: _buildImageWithDefects()),
        // Export buttons
        if (widget.showDownload || widget.showShare) ...[
          const SizedBox(height: 8),
          _buildExportButtons(context),
        ],
      ],
    );
  }

  /// Build export buttons (Download & Share)
  Widget _buildExportButtons(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (widget.showDownload)
            _buildExportButton(
              icon: Icons.download,
              label: setText('Tải xuống', 'Download'),
              onTap: () => _downloadImage(context),
            ),
          if (widget.showDownload && widget.showShare) const SizedBox(width: 8),
          if (widget.showShare)
            _buildExportButton(
              icon: Icons.share,
              label: setText('Chia sẻ', 'Share'),
              onTap: () => _shareImage(context),
            ),
        ],
      ),
    );
  }

  Widget _buildExportButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isExporting ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _isExporting
                ? Colors.grey[200]
                : Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isExporting
                  ? Colors.grey[300]!
                  : Colors.blue.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isExporting)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(icon, size: 18, color: Colors.blue[700]),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: _isExporting ? Colors.grey : Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefectTypeSelector() {
    final totalDefects = widget.dtData.rowCount;
    final hasSelection = _controller.selectedDefectCode != null;

    return Container(
      padding: widget.typeSelectorPadding,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tổng số điểm lỗi
          Row(
            children: [
              Icon(Icons.error_outline, size: 18, color: Colors.grey[700]),
              const SizedBox(width: 6),
              Text(
                'Tổng: $totalDefects điểm lỗi',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Danh sách loại lỗi
          Wrap(
            spacing: widget.itemSpacing,
            runSpacing: widget.itemRunSpacing,
            children: widget.dtType.rows.map((row) {
              final code = row.getString(widget.codeField);
              final isSelected = _controller.selectedDefectCode == code;
              final count = _countDefectsByCode(code);

              // Sử dụng custom itemBuilder nếu có
              if (widget.itemBuilder != null) {
                return widget.itemBuilder!(
                  row,
                  isSelected,
                  count,
                  () =>
                      _controller.selectedDefectCode = isSelected ? null : code,
                );
              }

              // Default item builder
              return _buildDefaultTypeItem(row, isSelected, code, count);
            }).toList(),
          ),

          // Hướng dẫn khi đã chọn loại lỗi
          if (hasSelection) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 6),
                  Text(
                    'Chạm vào vị trí lỗi trên hình',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDefaultTypeItem(
    CyberDataRow row,
    bool isSelected,
    String code,
    int count,
  ) {
    final name = row.getString(widget.nameField);
    final _color = widget.colorField;
    final _iconcolor = widget.iconcolor;
    final icon = row.getString(widget.iconField);

    // Hiển thị tên với số lượng nếu count > 0
    final displayName = count > 0 ? '$name ($count)' : name;

    return InkWell(
      onTap: () => _controller.selectedDefectCode = isSelected ? null : code,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: Colors.blue, width: 1.5)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DefectIcon(
              color: row[_color].toString().parseColor(
                defaultColor: Colors.grey,
              ),
              iconcolor: row[_iconcolor].toString().parseColor(
                defaultColor: Colors.grey,
              ),
              icon: icon,
              size: 24,
            ),
            const SizedBox(width: 6),
            Text(
              displayName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected || count > 0
                    ? FontWeight.w600
                    : FontWeight.normal,
                color: isSelected ? Colors.blue[700] : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWithDefects() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapDown: _handleTap,
          child: Container(
            key: _imageKey,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: Stack(
                children: [
                  if (_imageProvider != null)
                    Image(
                      image: _imageProvider!,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) =>
                          _buildPlaceholder(error: true),
                      frameBuilder:
                          (context, child, frame, wasSynchronouslyLoaded) {
                            if (frame != null) {
                              WidgetsBinding.instance.addPostFrameCallback(
                                (_) => _updateImageSize(),
                              );
                            }
                            return child;
                          },
                    )
                  else
                    _buildPlaceholder(),

                  if (_imageSize != null) ..._buildDefectMarkers(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder({bool error = false}) {
    return Container(
      width: double.infinity,
      height: widget.placeholderHeight,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            error ? Icons.broken_image : Icons.directions_car,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            error ? 'Không thể tải hình ảnh' : 'Chưa có hình ảnh',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDefectMarkers() {
    final markers = <Widget>[];

    for (int i = 0; i < widget.dtData.rowCount; i++) {
      final row = widget.dtData[i];

      final code = row.getString(widget.dataCodeField);
      final x = row.getDouble(widget.xField);
      final y = row.getDouble(widget.yField);
      final widthImg = row.getDouble(widget.widthField);
      final heightImg = row.getDouble(widget.heightField);

      final actualX = widthImg > 0 ? (x / widthImg) * _imageSize!.width : x;
      final actualY = heightImg > 0 ? (y / heightImg) * _imageSize!.height : y;

      final defectType = _getDefectType(code);

      // FIX: Đảm bảo upper bound không bao giờ nhỏ hơn 0
      // Tránh lỗi ArgumentError khi imageSize nhỏ hơn iconSize
      final maxX = math.max(0.0, _imageSize!.width - widget.iconSize);
      final maxY = math.max(0.0, _imageSize!.height - widget.iconSize);

      final adjustedX = (actualX - widget.iconSize / 2).clamp(0.0, maxX);
      final adjustedY = (actualY - widget.iconSize / 2).clamp(0.0, maxY);

      Widget marker;

      // Sử dụng custom markerBuilder nếu có
      if (widget.markerBuilder != null) {
        marker = widget.markerBuilder!(row, defectType, widget.iconSize);
      } else {
        // Default marker
        final _color = defectType?.getString(widget.colorField) ?? '';
        final _iconcolor = defectType?.getString(widget.iconcolor) ?? '';
        final icon = defectType?.getString(widget.iconField) ?? '';

        marker = DefectIcon(
          color: _color.toString().parseColor(defaultColor: Colors.grey),
          iconcolor: _iconcolor.toString().parseColor(
            defaultColor: Colors.grey,
          ),
          icon: icon,
          size: widget.iconSize,
        );
      }

      markers.add(Positioned(left: adjustedX, top: adjustedY, child: marker));
    }

    return markers;
  }
}

/// Widget hiển thị icon loại lỗi - Public để có thể reuse
class DefectIcon extends StatelessWidget {
  final Color color;
  final String icon;
  final double size;
  final Color iconcolor;
  const DefectIcon({
    super.key,
    required this.color,
    required this.icon,
    required this.iconcolor,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 2,
            offset: const Offset(1, 1),
          ),
        ],
      ),
      child: Center(child: _buildIconContent()),
    );
  }

  Widget _buildIconContent() {
    final isLight = color.computeLuminance() > 0.5;
    final iconColor = isLight ? Colors.black87 : Colors.white;
    return CyberLabel(
      text: icon,
      isIcon: true,
      style: TextStyle(fontSize: size * 0.65, color: iconColor),
    );
  }
}

// ============================================================================
// HELPER
// ============================================================================

class CyberImageHelper {
  static String bytesToBase64(Uint8List bytes) => base64Encode(bytes);

  static String bytesToDataUri(
    Uint8List bytes, {
    String mimeType = 'image/png',
  }) {
    return 'data:$mimeType;base64,${base64Encode(bytes)}';
  }

  static Uint8List base64ToBytes(String base64Str) {
    String cleaned = base64Str;
    if (base64Str.startsWith('data:image')) {
      cleaned = base64Str.split(',').last;
    }
    return base64Decode(cleaned);
  }

  static Future<Uint8List?> fileToBytes(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) return await file.readAsBytes();
    } catch (e) {
      debugPrint('❌ Error reading file: $e');
    }
    return null;
  }

  static Future<String?> fileToBase64(String filePath) async {
    final bytes = await fileToBytes(filePath);
    return bytes != null ? bytesToBase64(bytes) : null;
  }

  static Future<bool> bytesToFile(Uint8List bytes, String filePath) async {
    try {
      await File(filePath).writeAsBytes(bytes);
      return true;
    } catch (e) {
      debugPrint('❌ Error writing file: $e');
      return false;
    }
  }
}
