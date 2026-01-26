// ignore_for_file: file_names, non_constant_identifier_names

import 'package:cyberframework/cyberframework.dart';

// ============================================================================
// CyberTimelineSchedule - Timeline Schedule View Widget
// Tích hợp với CyberFramework
// ============================================================================

/// Chip builder callback type
/// [dr] - CyberDataRow chứa dữ liệu của chip
/// [index] - Index của chip trong dataSource
/// [chipInfo] - Thông tin tính toán vị trí (top, height, startTime, endTime)
typedef CyberChipBuilder =
    Widget Function(CyberDataRow dr, int index, CyberChipInfo chipInfo);

/// Callback khi tap vào vùng trống
typedef OnEmptyTapCallback = void Function(TimeOfDay time);

/// Callback khi tap vào chip
typedef OnChipTapCallback = void Function(CyberDataRow dr, int index);

/// Thông tin chip đã tính toán
class CyberChipInfo {
  /// Vị trí top tính từ đầu timeline (pixels)
  final double top;

  /// Chiều cao của chip (pixels)
  final double height;

  /// Thời gian bắt đầu của chip
  final TimeOfDay startTime;

  /// Thời gian kết thúc của chip
  final TimeOfDay endTime;

  /// Duration tính bằng phút
  final int durationMinutes;

  /// Index của dòng bắt đầu (0-based)
  final int startRowIndex;

  /// Index của dòng kết thúc (0-based)
  final int endRowIndex;

  /// Column index khi có overlap (0 = cột đầu tiên)
  final int columnIndex;

  /// Tổng số cột trong nhóm overlap
  final int totalColumns;

  /// Chip có overlap với chip khác không
  bool get hasOverlap => totalColumns > 1;

  const CyberChipInfo({
    required this.top,
    required this.height,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.startRowIndex,
    required this.endRowIndex,
    this.columnIndex = 0,
    this.totalColumns = 1,
  });

  CyberChipInfo copyWith({
    double? top,
    double? height,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    int? durationMinutes,
    int? startRowIndex,
    int? endRowIndex,
    int? columnIndex,
    int? totalColumns,
  }) {
    return CyberChipInfo(
      top: top ?? this.top,
      height: height ?? this.height,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      startRowIndex: startRowIndex ?? this.startRowIndex,
      endRowIndex: endRowIndex ?? this.endRowIndex,
      columnIndex: columnIndex ?? this.columnIndex,
      totalColumns: totalColumns ?? this.totalColumns,
    );
  }

  /// Format time thành string HH:mm
  String get startTimeStr =>
      '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';

  String get endTimeStr =>
      '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

  String get timeRangeStr => '$startTimeStr -> $endTimeStr';

  @override
  String toString() {
    return 'CyberChipInfo(top: $top, height: $height, time: $timeRangeStr, duration: ${durationMinutes}m, col: $columnIndex/$totalColumns)';
  }
}

/// Internal class để track chip và thông tin overlap
class _ChipData {
  final CyberDataRow row;
  final int index;
  CyberChipInfo info;

  _ChipData({required this.row, required this.index, required this.info});

  int get startMinutes => info.startTime.hour * 60 + info.startTime.minute;
  int get endMinutes => info.endTime.hour * 60 + info.endTime.minute;

  bool overlapsWith(_ChipData other) {
    return startMinutes < other.endMinutes && endMinutes > other.startMinutes;
  }
}

/// CyberTimelineSchedule - Widget hiển thị timeline schedule với các chip
///
/// Features:
/// - Hiển thị timeline theo khoảng thời gian tùy chỉnh
/// - Tự động tính toán vị trí và chiều cao của chip
/// - Hỗ trợ custom chip builder
/// - Overlap detection - tự động xếp chip cạnh nhau khi trùng giờ
/// - Scroll để xem toàn bộ timeline
/// - Current time indicator
/// - Reactive với CyberDataTable changes
///
/// Example:
/// ```dart
/// CyberTimelineSchedule(
///   startTime: '08:00',
///   endTime: '18:00',
///   intervalMinutes: 30,
///   rowHeight: 60,
///   dataSource: tbSchedule,
///   startTimeColumn: 'gio_bat_dau',
///   endTimeColumn: 'gio_ket_thuc',
///   chipBuilder: (dr, index, info) => CyberScheduleChip(
///     dr: dr,
///     chipInfo: info,
///     titleColumn: 'bien_so',
///     codeColumn: 'ma_phieu',
///     assigneeColumn: 'nhan_vien',
///     descriptionColumn: 'noi_dung',
///   ),
///   onChipTap: (dr, index) => print('Tapped: ${dr['bien_so']}'),
/// )
/// ```
class CyberTimelineSchedule extends StatefulWidget {
  // ============================================================================
  // REQUIRED PROPERTIES
  // ============================================================================

  /// Giờ bắt đầu của timeline (format: "HH:mm")
  /// Ví dụ: "08:00", "09:30"
  final String startTime;

  /// Giờ kết thúc của timeline (format: "HH:mm")
  /// Ví dụ: "18:00", "17:30"
  final String endTime;

  // ============================================================================
  // INTERVAL & SIZE PROPERTIES
  // ============================================================================

  /// Khoảng cách mỗi dòng tính bằng phút
  /// Ví dụ: 30 => 08:00, 08:30, 09:00, ...
  /// Default: 30
  final int intervalMinutes;

  /// Chiều cao mỗi dòng (pixels)
  /// Default: 60
  final int rowHeight;

  // ============================================================================
  // DATA SOURCE PROPERTIES
  // ============================================================================

  /// DataSource chứa danh sách các chip
  final CyberDataTable? dataSource;

  /// Tên column chứa giờ bắt đầu của chip (format: "HH:mm")
  /// Default: 'start_time'
  final String startTimeColumn;

  /// Tên column chứa giờ kết thúc của chip (format: "HH:mm")
  /// Default: 'end_time'
  final String endTimeColumn;

  // ============================================================================
  // CHIP BUILDER
  // ============================================================================

  /// Custom chip builder
  /// Nếu null, sẽ dùng default chip style
  ///
  /// Example:
  /// ```dart
  /// chipBuilder: (dr, index, info) => Container(
  ///   color: Colors.blue,
  ///   child: Text(dr['title']),
  /// )
  /// ```
  final CyberChipBuilder? chipBuilder;

  // ============================================================================
  // LAYOUT PROPERTIES
  // ============================================================================

  /// Padding bên trái cho time label
  /// Default: 60
  final double timeLabelWidth;

  /// Padding horizontal cho chip area
  /// Default: 8
  final double chipHorizontalPadding;

  /// Khoảng cách giữa các chip overlap
  /// Default: 4
  final double chipOverlapGap;

  /// Minimum width cho chip khi overlap
  /// Default: 100
  final double minChipWidth;

  // ============================================================================
  // STYLING PROPERTIES
  // ============================================================================

  /// Background color của timeline
  final Color? backgroundColor;

  /// Color của đường kẻ phân cách giữa các dòng
  final Color? dividerColor;

  /// Độ dày đường kẻ phân cách
  /// Default: 0.5
  final double dividerThickness;

  /// Style cho time label
  final TextStyle? timeLabelStyle;

  // ============================================================================
  // CURRENT TIME INDICATOR
  // ============================================================================

  /// Hiển thị indicator cho thời gian hiện tại
  /// Default: true
  final bool showCurrentTimeIndicator;

  /// Color của current time indicator
  /// Default: Colors.red
  final Color? currentTimeIndicatorColor;

  /// Thickness của current time line
  /// Default: 2
  final double currentTimeIndicatorThickness;

  // ============================================================================
  // CALLBACKS
  // ============================================================================

  /// Callback khi tap vào chip
  final OnChipTapCallback? onChipTap;

  /// Callback khi long press vào chip
  final OnChipTapCallback? onChipLongPress;

  /// Callback khi double tap vào chip
  final OnChipTapCallback? onChipDoubleTap;

  /// Callback khi tap vào vùng trống (truyền thời gian tại vị trí tap)
  final OnEmptyTapCallback? onEmptyTap;

  /// Callback khi long press vào vùng trống
  final OnEmptyTapCallback? onEmptyLongPress;

  // ============================================================================
  // SCROLL PROPERTIES
  // ============================================================================

  /// ScrollController (optional)
  final ScrollController? scrollController;

  /// Có auto scroll đến thời gian hiện tại không
  /// Default: false
  final bool autoScrollToCurrentTime;

  /// Physics cho scroll
  final ScrollPhysics? physics;

  // ============================================================================
  // ADDITIONAL WIDGETS
  // ============================================================================

  /// Header widget (hiển thị phía trên timeline)
  final Widget? header;

  /// Footer widget (hiển thị phía dưới timeline)
  final Widget? footer;

  /// Widget hiển thị khi không có data
  final Widget? emptyWidget;

  const CyberTimelineSchedule({
    super.key,
    required this.startTime,
    required this.endTime,
    this.intervalMinutes = 30,
    this.rowHeight = 60,
    this.dataSource,
    this.startTimeColumn = 'start_time',
    this.endTimeColumn = 'end_time',
    this.chipBuilder,
    this.timeLabelWidth = 60,
    this.chipHorizontalPadding = 8,
    this.chipOverlapGap = 4,
    this.minChipWidth = 100,
    this.backgroundColor,
    this.dividerColor,
    this.dividerThickness = 0.5,
    this.timeLabelStyle,
    this.showCurrentTimeIndicator = true,
    this.currentTimeIndicatorColor,
    this.currentTimeIndicatorThickness = 2,
    this.onChipTap,
    this.onChipLongPress,
    this.onChipDoubleTap,
    this.onEmptyTap,
    this.onEmptyLongPress,
    this.scrollController,
    this.autoScrollToCurrentTime = false,
    this.physics,
    this.header,
    this.footer,
    this.emptyWidget,
  });

  @override
  State<CyberTimelineSchedule> createState() => _CyberTimelineScheduleState();
}

class _CyberTimelineScheduleState extends State<CyberTimelineSchedule> {
  late ScrollController _scrollController;
  late List<TimeOfDay> _timeSlots;
  late TimeOfDay _startTimeOfDay;
  late TimeOfDay _endTimeOfDay;

  // Processed chip data with overlap info
  List<_ChipData> _processedChips = [];

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _initTimeSlots();
    _processChipData();

    // Listen to dataSource changes
    widget.dataSource?.addListener(_onDataSourceChanged);

    if (widget.autoScrollToCurrentTime) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentTime();
      });
    }
  }

  @override
  void didUpdateWidget(CyberTimelineSchedule oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if time settings changed
    if (oldWidget.startTime != widget.startTime ||
        oldWidget.endTime != widget.endTime ||
        oldWidget.intervalMinutes != widget.intervalMinutes) {
      _initTimeSlots();
    }

    // Check if dataSource changed
    if (oldWidget.dataSource != widget.dataSource) {
      oldWidget.dataSource?.removeListener(_onDataSourceChanged);
      widget.dataSource?.addListener(_onDataSourceChanged);
      _processChipData();
    }

    // Check if column mappings changed
    if (oldWidget.startTimeColumn != widget.startTimeColumn ||
        oldWidget.endTimeColumn != widget.endTimeColumn) {
      _processChipData();
    }
  }

  void _onDataSourceChanged() {
    _processChipData();
    if (mounted) {
      setState(() {});
    }
  }

  void _initTimeSlots() {
    _startTimeOfDay = _parseTime(widget.startTime);
    _endTimeOfDay = _parseTime(widget.endTime);
    _timeSlots = _generateTimeSlots();
  }

  TimeOfDay _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      debugPrint('❌ CyberTimelineSchedule: Invalid time format: $timeStr');
      return const TimeOfDay(hour: 8, minute: 0);
    }
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  List<TimeOfDay> _generateTimeSlots() {
    final slots = <TimeOfDay>[];
    var current = _startTimeOfDay;
    final endMinutes = _endTimeOfDay.hour * 60 + _endTimeOfDay.minute;

    while (true) {
      final currentMinutes = current.hour * 60 + current.minute;
      if (currentMinutes > endMinutes) break;

      slots.add(current);

      // Next slot
      final nextMinutes = currentMinutes + widget.intervalMinutes;
      current = TimeOfDay(hour: nextMinutes ~/ 60, minute: nextMinutes % 60);
    }

    return slots;
  }

  void _scrollToCurrentTime() {
    if (!_scrollController.hasClients) return;

    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = _startTimeOfDay.hour * 60 + _startTimeOfDay.minute;

    if (nowMinutes >= startMinutes) {
      final offset =
          ((nowMinutes - startMinutes) / widget.intervalMinutes) *
          widget.rowHeight;
      _scrollController.animateTo(
        offset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  /// Scroll đến thời gian chỉ định
  void scrollToTime(TimeOfDay time, {bool animate = true}) {
    if (!_scrollController.hasClients) return;

    final timeMinutes = time.hour * 60 + time.minute;
    final startMinutes = _startTimeOfDay.hour * 60 + _startTimeOfDay.minute;

    final offset =
        ((timeMinutes - startMinutes) / widget.intervalMinutes) *
        widget.rowHeight;

    if (animate) {
      _scrollController.animateTo(
        offset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(
        offset.clamp(0.0, _scrollController.position.maxScrollExtent),
      );
    }
  }

  /// Process chip data và tính overlap
  void _processChipData() {
    _processedChips.clear();

    if (widget.dataSource == null || widget.dataSource!.rowCount == 0) {
      return;
    }

    // Step 1: Calculate basic chip info
    for (int i = 0; i < widget.dataSource!.rowCount; i++) {
      final dr = widget.dataSource!.rows[i];
      final info = _calculateChipInfo(dr);

      if (info != null) {
        _processedChips.add(_ChipData(row: dr, index: i, info: info));
      }
    }

    // Step 2: Sort by start time
    _processedChips.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

    // Step 3: Calculate overlap columns
    _calculateOverlapColumns();
  }

  /// Tính toán vị trí và chiều cao cơ bản của chip
  CyberChipInfo? _calculateChipInfo(CyberDataRow dr) {
    try {
      final startStr = dr.getString(widget.startTimeColumn);
      final endStr = dr.getString(widget.endTimeColumn);

      if (startStr.isEmpty || endStr.isEmpty) return null;

      final chipStart = _parseTime(startStr);
      final chipEnd = _parseTime(endStr);

      final timelineStartMinutes =
          _startTimeOfDay.hour * 60 + _startTimeOfDay.minute;
      final chipStartMinutes = chipStart.hour * 60 + chipStart.minute;
      final chipEndMinutes = chipEnd.hour * 60 + chipEnd.minute;

      // Validate: chip phải nằm trong timeline range
      if (chipStartMinutes < timelineStartMinutes) return null;

      // Tính vị trí top
      final minutesFromStart = chipStartMinutes - timelineStartMinutes;
      final top =
          (minutesFromStart / widget.intervalMinutes) * widget.rowHeight;

      // Tính chiều cao
      final durationMinutes = chipEndMinutes - chipStartMinutes;
      if (durationMinutes <= 0) return null;

      final height =
          (durationMinutes / widget.intervalMinutes) * widget.rowHeight;

      // Tính row index
      final startRowIndex = minutesFromStart ~/ widget.intervalMinutes;
      final endRowIndex =
          (minutesFromStart + durationMinutes) ~/ widget.intervalMinutes;

      return CyberChipInfo(
        top: top.toDouble(),
        height: height.toDouble(),
        startTime: chipStart,
        endTime: chipEnd,
        durationMinutes: durationMinutes,
        startRowIndex: startRowIndex,
        endRowIndex: endRowIndex,
      );
    } catch (e) {
      debugPrint('❌ CyberTimelineSchedule: Error calculating chip info: $e');
      return null;
    }
  }

  /// Tính toán cột cho các chip overlap
  void _calculateOverlapColumns() {
    if (_processedChips.isEmpty) return;

    // Group chips by overlap
    final List<List<_ChipData>> overlapGroups = [];
    List<_ChipData> currentGroup = [_processedChips.first];

    for (int i = 1; i < _processedChips.length; i++) {
      final chip = _processedChips[i];
      bool overlapsWithGroup = false;

      // Check if overlaps with any chip in current group
      for (var groupChip in currentGroup) {
        if (chip.overlapsWith(groupChip)) {
          overlapsWithGroup = true;
          break;
        }
      }

      if (overlapsWithGroup) {
        currentGroup.add(chip);
      } else {
        // Finish current group and start new one
        overlapGroups.add(currentGroup);
        currentGroup = [chip];
      }
    }
    overlapGroups.add(currentGroup);

    // Assign column indices within each group
    for (var group in overlapGroups) {
      if (group.length == 1) {
        // No overlap
        group.first.info = group.first.info.copyWith(
          columnIndex: 0,
          totalColumns: 1,
        );
      } else {
        // Has overlap - assign columns
        final totalColumns = group.length;
        for (int i = 0; i < group.length; i++) {
          group[i].info = group[i].info.copyWith(
            columnIndex: i,
            totalColumns: totalColumns,
          );
        }
      }
    }
  }

  /// Tính vị trí của current time indicator
  double? _getCurrentTimeOffset() {
    if (!widget.showCurrentTimeIndicator) return null;

    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = _startTimeOfDay.hour * 60 + _startTimeOfDay.minute;
    final endMinutes = _endTimeOfDay.hour * 60 + _endTimeOfDay.minute;

    if (nowMinutes < startMinutes || nowMinutes > endMinutes) return null;

    return ((nowMinutes - startMinutes) / widget.intervalMinutes) *
        widget.rowHeight;
  }

  TimeOfDay _getTapTime(double tapY) {
    final minutesFromStart = (tapY / widget.rowHeight) * widget.intervalMinutes;
    final startMinutes = _startTimeOfDay.hour * 60 + _startTimeOfDay.minute;
    final tapMinutes = startMinutes + minutesFromStart.round();

    return TimeOfDay(
      hour: (tapMinutes ~/ 60).clamp(0, 23),
      minute: tapMinutes % 60,
    );
  }

  void _handleEmptyTap(TapDownDetails details) {
    if (widget.onEmptyTap == null) return;
    widget.onEmptyTap!(_getTapTime(details.localPosition.dy));
  }

  void _handleEmptyLongPress(LongPressStartDetails details) {
    if (widget.onEmptyLongPress == null) return;
    widget.onEmptyLongPress!(_getTapTime(details.localPosition.dy));
  }

  @override
  Widget build(BuildContext context) {
    final totalHeight = _timeSlots.length * widget.rowHeight.toDouble();
    final currentTimeOffset = _getCurrentTimeOffset();

    return Column(
      children: [
        // Header (nếu có)
        if (widget.header != null) widget.header!,

        // Timeline content
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: widget.physics,
            child: GestureDetector(
              onTapDown: _handleEmptyTap,
              onLongPressStart: _handleEmptyLongPress,
              child: Container(
                color: widget.backgroundColor ?? Colors.grey[200],
                child: Stack(
                  children: [
                    // Time rows (background)
                    _buildTimeRows(totalHeight),

                    // Chips layer
                    _buildChipsLayer(totalHeight),

                    // Current time indicator
                    if (currentTimeOffset != null)
                      _buildCurrentTimeIndicator(currentTimeOffset),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Footer (nếu có)
        if (widget.footer != null) widget.footer!,
      ],
    );
  }

  Widget _buildTimeRows(double totalHeight) {
    return SizedBox(
      height: totalHeight,
      child: Column(
        children: _timeSlots.map((time) {
          return _buildTimeRow(time);
        }).toList(),
      ),
    );
  }

  Widget _buildTimeRow(TimeOfDay time) {
    return Container(
      height: widget.rowHeight.toDouble(),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: widget.dividerColor ?? Colors.grey[400]!,
            width: widget.dividerThickness,
          ),
        ),
      ),
      child: Row(
        children: [
          // Time label
          SizedBox(
            width: widget.timeLabelWidth,
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Text(
                _formatTime(time),
                style:
                    widget.timeLabelStyle ??
                    TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ),

          // Empty space for chips
          const Expanded(child: SizedBox()),
        ],
      ),
    );
  }

  Widget _buildChipsLayer(double totalHeight) {
    if (_processedChips.isEmpty) {
      return widget.emptyWidget ?? const SizedBox.shrink();
    }

    return SizedBox(
      height: totalHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth =
              constraints.maxWidth -
              widget.timeLabelWidth -
              (widget.chipHorizontalPadding * 2);

          return Stack(
            children: _processedChips.map((chipData) {
              return _buildPositionedChip(chipData, availableWidth);
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildPositionedChip(_ChipData chipData, double availableWidth) {
    final info = chipData.info;

    // Calculate width and left position based on overlap
    double chipWidth;
    double leftOffset;

    if (info.totalColumns == 1) {
      // No overlap - full width
      chipWidth = availableWidth;
      leftOffset = widget.timeLabelWidth + widget.chipHorizontalPadding;
    } else {
      // Has overlap - divide width
      final totalGaps = (info.totalColumns - 1) * widget.chipOverlapGap;
      final widthPerChip = (availableWidth - totalGaps) / info.totalColumns;
      chipWidth = widthPerChip.clamp(widget.minChipWidth, double.infinity);
      leftOffset =
          widget.timeLabelWidth +
          widget.chipHorizontalPadding +
          (info.columnIndex * (widthPerChip + widget.chipOverlapGap));
    }

    return Positioned(
      left: leftOffset,
      width: chipWidth,
      top: info.top,
      height: info.height,
      child: _buildChip(chipData),
    );
  }

  Widget _buildChip(_ChipData chipData) {
    Widget chipWidget;

    if (widget.chipBuilder != null) {
      chipWidget = widget.chipBuilder!(
        chipData.row,
        chipData.index,
        chipData.info,
      );
    } else {
      chipWidget = _buildDefaultChip(chipData);
    }

    return GestureDetector(
      onTap: widget.onChipTap != null
          ? () => widget.onChipTap!(chipData.row, chipData.index)
          : null,
      onLongPress: widget.onChipLongPress != null
          ? () => widget.onChipLongPress!(chipData.row, chipData.index)
          : null,
      onDoubleTap: widget.onChipDoubleTap != null
          ? () => widget.onChipDoubleTap!(chipData.row, chipData.index)
          : null,
      child: chipWidget,
    );
  }

  Widget _buildDefaultChip(_ChipData chipData) {
    final dr = chipData.row;
    final info = chipData.info;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: Colors.blue[400],
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  dr.getString('title', 'No Title'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                info.timeRangeStr,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),

          // Description (if enough height)
          if (info.height > 50) ...[
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                dr.getString('description', ''),
                style: const TextStyle(color: Colors.white, fontSize: 12),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentTimeIndicator(double offset) {
    return Positioned(
      left: 0,
      right: 0,
      top: offset,
      child: Row(
        children: [
          // Circle indicator
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: widget.currentTimeIndicatorColor ?? Colors.red,
              shape: BoxShape.circle,
            ),
          ),

          // Line
          Expanded(
            child: Container(
              height: widget.currentTimeIndicatorThickness,
              color: widget.currentTimeIndicatorColor ?? Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    widget.dataSource?.removeListener(_onDataSourceChanged);
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }
}

// ============================================================================
// CyberScheduleChip - Widget chip mặc định giống hình mẫu
// ============================================================================

/// Widget chip schedule với layout giống hình mẫu
/// Hiển thị: biển số, mã, thời gian, người phụ trách, nội dung
///
/// Example:
/// ```dart
/// CyberScheduleChip(
///   dr: dr,
///   chipInfo: info,
///   titleColumn: 'bien_so',
///   codeColumn: 'ma_phieu',
///   assigneeColumn: 'nhan_vien',
///   descriptionColumn: 'noi_dung',
/// )
/// ```
class CyberScheduleChip extends StatelessWidget {
  final CyberDataRow dr;
  final CyberChipInfo chipInfo;

  /// Column mappings
  final String titleColumn;
  final String codeColumn;
  final String assigneeColumn;
  final String descriptionColumn;

  /// Styling
  final Color? backgroundColor;
  final Color? textColor;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  /// Show/hide elements
  final bool showTimeRange;
  final bool showCode;
  final bool showAssignee;

  const CyberScheduleChip({
    super.key,
    required this.dr,
    required this.chipInfo,
    this.titleColumn = 'title',
    this.codeColumn = 'code',
    this.assigneeColumn = 'assignee',
    this.descriptionColumn = 'description',
    this.backgroundColor,
    this.textColor,
    this.borderRadius,
    this.padding,
    this.margin,
    this.showTimeRange = true,
    this.showCode = true,
    this.showAssignee = true,
  });

  @override
  Widget build(BuildContext context) {
    final title = dr.getString(titleColumn);
    final code = dr.getString(codeColumn);
    final assignee = dr.getString(assigneeColumn);
    final description = dr.getString(descriptionColumn);
    final effectiveTextColor = textColor ?? Colors.white;

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFF42A5F5),
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row 1: Title (biển số) + Time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: effectiveTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (showTimeRange)
                  Text(
                    chipInfo.timeRangeStr,
                    style: TextStyle(color: effectiveTextColor, fontSize: 13),
                  ),
              ],
            ),

            // Row 2: Code + Assignee
            if ((showCode && code.isNotEmpty) ||
                (showAssignee && assignee.isNotEmpty)) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (showCode)
                    Expanded(
                      child: Text(
                        code,
                        style: TextStyle(
                          color: effectiveTextColor,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (showAssignee && assignee.isNotEmpty)
                    Text(
                      assignee,
                      style: TextStyle(color: effectiveTextColor, fontSize: 13),
                    ),
                ],
              ),
            ],

            // Row 3: Description (nếu có đủ chiều cao)
            if (description.isNotEmpty && chipInfo.height > 70) ...[
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  description,
                  style: TextStyle(color: effectiveTextColor, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
