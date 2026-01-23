import 'package:cyberframework/cyberframework.dart';

// ============================================================================
// CYBER CAR INSPECTION CONTROL
// ============================================================================
//
// Sử dụng:
// ```dart
// CyberCarInspection(
//   image: NetworkImage('url') hoặc AssetImage('path'),
//   dtType: dtLoaiLoi,   // CyberDataTable: Ma_Loi, Ten_Loi, Mau_Sac, Icon
//   dtData: dtDiemLoi,   // CyberDataTable: Ma_Loi, X, Y, WidthImg, HeightImg
//   onDataChanged: () => setState(() {}),
// )
// ```
//
// Thao tác:
// - Chọn loại lỗi → Click vị trí trống → Thêm điểm mới vào dtData
// - Click vào icon lỗi đã có → Xóa điểm khỏi dtData
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

/// Widget chính CyberCarInspection
class CyberCarInspection extends StatefulWidget {
  /// Hình ảnh xe (ImageProvider)
  final ImageProvider? image;

  /// Bảng loại lỗi
  /// Columns: Ma_Loi (String), Ten_Loi (String), Mau_Sac (int 0xFFxxxxxx), Icon (String)
  final CyberDataTable dtType;

  /// Bảng dữ liệu điểm lỗi
  /// Columns: Ma_Loi (String), X (double), Y (double), WidthImg (double), HeightImg (double)
  final CyberDataTable dtData;

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

  const CyberCarInspection({
    super.key,
    this.image,
    required this.dtType,
    required this.dtData,
    this.controller,
    this.enabled = true,
    this.iconSize = 28,
    this.onDataChanged,
    this.borderRadius = 8,
    this.showTypeSelector = true,
    this.showSummary = true,
  });

  @override
  State<CyberCarInspection> createState() => _CyberCarInspectionState();
}

class _CyberCarInspectionState extends State<CyberCarInspection> {
  final GlobalKey _imageKey = GlobalKey();
  Size? _imageSize;
  late CyberCarInspectionController _controller;
  bool _isInternalController = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? CyberCarInspectionController();
    _isInternalController = widget.controller == null;
    _controller.addListener(_onControllerChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) => _updateImageSize());
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (_isInternalController) {
      _controller.dispose();
    }
    super.dispose();
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

  /// Xử lý tap trên hình ảnh
  void _handleTap(TapDownDetails details) {
    if (!widget.enabled) return;

    _updateImageSize();
    if (_imageSize == null) return;

    final tapPosition = details.localPosition;

    // Kiểm tra tap vào điểm lỗi đã có không
    final tappedIndex = _findTappedPointIndex(tapPosition);

    if (tappedIndex != null) {
      // Click vào điểm lỗi → Xóa
      _removePoint(tappedIndex);
    } else if (_controller.selectedDefectCode != null) {
      // Click vị trí trống + đã chọn loại lỗi → Thêm mới
      _addPoint(tapPosition);
    }
  }

  /// Tìm index của điểm lỗi tại vị trí tap
  int? _findTappedPointIndex(Offset tapPosition) {
    if (_imageSize == null) return null;

    final hitRadius = widget.iconSize / 2 + 8;

    for (int i = 0; i < widget.dtData.rowCount; i++) {
      final row = widget.dtData[i];

      final x = row.getDouble('X');
      final y = row.getDouble('Y');
      final widthImg = row.getDouble('WidthImg');
      final heightImg = row.getDouble('HeightImg');

      // Tính vị trí thực tế
      final actualX = widthImg > 0 ? (x / widthImg) * _imageSize!.width : x;
      final actualY = heightImg > 0 ? (y / heightImg) * _imageSize!.height : y;

      final distance = (Offset(actualX, actualY) - tapPosition).distance;
      if (distance <= hitRadius) {
        return i;
      }
    }
    return null;
  }

  /// Thêm điểm lỗi mới
  void _addPoint(Offset position) {
    final newRow = widget.dtData.newRow();
    newRow['Ma_Loi'] = _controller.selectedDefectCode;
    newRow['X'] = position.dx;
    newRow['Y'] = position.dy;
    newRow['WidthImg'] = _imageSize!.width;
    newRow['HeightImg'] = _imageSize!.height;

    widget.dtData.addRow(newRow);

    setState(() {});
    widget.onDataChanged?.call();
  }

  /// Xóa điểm lỗi
  void _removePoint(int index) {
    widget.dtData.removeAt(index);

    setState(() {});
    widget.onDataChanged?.call();
  }

  /// Lấy thông tin loại lỗi từ dtType
  CyberDataRow? _getDefectType(String code) {
    return widget.dtType.findRow((row) => row.getString('Ma_Loi') == code);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Selector loại lỗi
        if (widget.enabled && widget.showTypeSelector) ...[
          _buildDefectTypeSelector(),
          const SizedBox(height: 8),
        ],

        // Hình ảnh với các điểm lỗi
        _buildImageWithDefects(),

        // Thống kê
        if (widget.showSummary && widget.dtData.rowCount > 0) ...[
          const SizedBox(height: 12),
          _buildSummary(),
        ],
      ],
    );
  }

  Widget _buildDefectTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: widget.dtType.rows.map((row) {
          final code = row.getString('Ma_Loi');
          final name = row.getString('Ten_Loi');
          final color = row.getInt('Mau_Sac');
          final icon = row.getString('Icon');
          final isSelected = _controller.selectedDefectCode == code;

          return InkWell(
            onTap: () {
              _controller.selectedDefectCode = isSelected ? null : code;
            },
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
                  _DefectIcon(
                    color: color != 0 ? Color(color) : Colors.grey,
                    icon: icon,
                    size: 24,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected ? Colors.blue[700] : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
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
                  // Hình ảnh
                  if (widget.image != null)
                    Image(
                      image: widget.image!,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    )
                  else
                    _buildPlaceholder(),

                  // Các điểm lỗi
                  if (_imageSize != null) ..._buildDefectMarkers(),

                  // Hướng dẫn
                  if (widget.enabled && _controller.selectedDefectCode != null)
                    Positioned(
                      top: 8,
                      left: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.touch_app,
                              color: Colors.white,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Chạm vào vị trí lỗi trên hình',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: 300,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text('Chưa có hình ảnh', style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  List<Widget> _buildDefectMarkers() {
    final markers = <Widget>[];

    for (int i = 0; i < widget.dtData.rowCount; i++) {
      final row = widget.dtData[i];

      final code = row.getString('Ma_Loi');
      final x = row.getDouble('X');
      final y = row.getDouble('Y');
      final widthImg = row.getDouble('WidthImg');
      final heightImg = row.getDouble('HeightImg');

      // Tính vị trí thực tế
      final actualX = widthImg > 0 ? (x / widthImg) * _imageSize!.width : x;
      final actualY = heightImg > 0 ? (y / heightImg) * _imageSize!.height : y;

      // Lấy thông tin loại lỗi
      final defectType = _getDefectType(code);
      final color = defectType?.getInt('Mau_Sac') ?? 0xFF888888;
      final icon = defectType?.getString('Icon') ?? '';

      // Điều chỉnh để icon nằm giữa điểm
      final adjustedX = (actualX - widget.iconSize / 2).clamp(
        0.0,
        _imageSize!.width - widget.iconSize,
      );
      final adjustedY = (actualY - widget.iconSize / 2).clamp(
        0.0,
        _imageSize!.height - widget.iconSize,
      );

      markers.add(
        Positioned(
          left: adjustedX,
          top: adjustedY,
          child: _DefectIcon(
            color: Color(color),
            icon: icon,
            size: widget.iconSize,
          ),
        ),
      );
    }

    return markers;
  }

  Widget _buildSummary() {
    // Nhóm theo loại lỗi
    final summary = <String, int>{};
    for (int i = 0; i < widget.dtData.rowCount; i++) {
      final row = widget.dtData[i];
      final code = row.getString('Ma_Loi');
      final defectType = _getDefectType(code);
      final name = defectType?.getString('Ten_Loi') ?? code;
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

/// Widget hiển thị icon loại lỗi
class _DefectIcon extends StatelessWidget {
  final Color color;
  final String icon;
  final double size;

  const _DefectIcon({required this.color, required this.icon, this.size = 28});

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

    switch (icon.toLowerCase()) {
      case 'loi_lom':
      case 'circle':
        return Container(
          width: size * 0.55,
          height: size * 0.55,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: iconColor, width: 2),
          ),
        );

      case 'troc_rop':
      case 'dots':
        return SizedBox(
          width: size * 0.6,
          height: size * 0.6,
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            children: List.generate(
              9,
              (_) => Container(
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ),
        );

      case 'bien_mau':
      case 'lines':
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            3,
            (i) => Container(
              width: size * 0.55,
              height: 2.5,
              margin: EdgeInsets.only(bottom: i < 2 ? 2 : 0),
              color: iconColor,
            ),
          ),
        );

      case 'vet_xuoc':
      case 'star':
        return Icon(Icons.star, color: iconColor, size: size * 0.6);

      case 'bui_son':
      case 'plus':
        return Icon(Icons.add, color: iconColor, size: size * 0.65);

      case 'khac':
      case 'hash':
        return Text(
          '#',
          style: TextStyle(
            color: iconColor,
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
          ),
        );

      default:
        return Icon(Icons.circle, color: iconColor, size: size * 0.5);
    }
  }
}
