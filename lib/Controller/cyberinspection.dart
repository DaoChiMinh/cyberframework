import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
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
//   // Hoặc custom item builder
//   itemBuilder: (row, isSelected, onTap) => MyCustomWidget(...),
// )
// ```
// ============================================================================

/// Controller để quản lý CyberCarInspection
class CyberCarInspectionController extends ChangeNotifier {
  String? _selectedDefectCode;

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
}

/// Callback để build custom item trong danh sách loại lỗi
typedef DefectTypeItemBuilder =
    Widget Function(CyberDataRow row, bool isSelected, VoidCallback onTap);

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

  /// Hiển thị thống kê
  final bool showSummary;

  /// Chiều cao placeholder khi không có ảnh
  final double placeholderHeight;

  /// Padding cho type selector
  final EdgeInsets typeSelectorPadding;

  /// Spacing giữa các item trong type selector
  final double itemSpacing;

  /// Run spacing cho type selector
  final double itemRunSpacing;

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
    this.showSummary = true,
    this.placeholderHeight = 300,
    this.typeSelectorPadding = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 8,
    ),
    this.itemSpacing = 12,
    this.itemRunSpacing = 8,
  });

  @override
  State<CyberCarInspection> createState() => _CyberCarInspectionState();
}

class _CyberCarInspectionState extends State<CyberCarInspection> {
  final GlobalKey _imageKey = GlobalKey();
  Size? _imageSize;
  late CyberCarInspectionController _controller;
  bool _isInternalController = false;

  ImageProvider? _imageProvider;
  dynamic _lastImageInput;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? CyberCarInspectionController();
    _isInternalController = widget.controller == null;
    _controller.addListener(_onControllerChanged);
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

    final hitRadius = widget.iconSize / 2 + 8;

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
        _buildImageWithDefects(),
        if (widget.showSummary && widget.dtData.rowCount > 0) ...[
          const SizedBox(height: 12),
          _buildSummary(),
        ],
      ],
    );
  }

  Widget _buildDefectTypeSelector() {
    return Container(
      padding: widget.typeSelectorPadding,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: widget.itemSpacing,
        runSpacing: widget.itemRunSpacing,
        children: widget.dtType.rows.map((row) {
          final code = row.getString(widget.codeField);
          final isSelected = _controller.selectedDefectCode == code;

          // Sử dụng custom itemBuilder nếu có
          if (widget.itemBuilder != null) {
            return widget.itemBuilder!(
              row,
              isSelected,
              () => _controller.selectedDefectCode = isSelected ? null : code,
            );
          }

          // Default item builder
          return _buildDefaultTypeItem(row, isSelected, code);
        }).toList(),
      ),
    );
  }

  Widget _buildDefaultTypeItem(CyberDataRow row, bool isSelected, String code) {
    final name = row.getString(widget.nameField);
    final _color = widget.colorField;
    final _iconcolor = widget.iconcolor;
    final icon = row.getString(widget.iconField);

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
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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

                  // if (widget.enabled && _controller.selectedDefectCode != null)
                  //   Positioned(
                  //     top: 8,
                  //     left: 8,
                  //     right: 8,
                  //     child: Container(
                  //       padding: const EdgeInsets.symmetric(
                  //         horizontal: 12,
                  //         vertical: 6,
                  //       ),
                  //       decoration: BoxDecoration(
                  //         color: Colors.blue.withOpacity(0.9),
                  //         borderRadius: BorderRadius.circular(20),
                  //       ),
                  //       child: const Row(
                  //         mainAxisSize: MainAxisSize.min,
                  //         children: [
                  //           Icon(
                  //             Icons.touch_app,
                  //             color: Colors.white,
                  //             size: 16,
                  //           ),
                  //           SizedBox(width: 6),
                  //           Text(
                  //             'Chạm vào vị trí lỗi trên hình',
                  //             style: TextStyle(
                  //               color: Colors.white,
                  //               fontSize: 12,
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //     ),
                  //   ),
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

  Widget _buildSummary() {
    final summary = <String, int>{};
    for (int i = 0; i < widget.dtData.rowCount; i++) {
      final row = widget.dtData[i];
      final code = row.getString(widget.dataCodeField);
      final defectType = _getDefectType(code);
      final name = defectType?.getString(widget.nameField) ?? code;
      summary[name] = (summary[name] ?? 0) + 1;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, size: 18, color: Colors.grey[700]),
              const SizedBox(width: 6),
              Text(
                'Tổng: ${widget.dtData.rowCount} điểm lỗi',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          if (summary.isNotEmpty) ...[
            const Divider(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: summary.entries
                  .map(
                    (e) => Text(
                      '${e.key}: ${e.value}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
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
