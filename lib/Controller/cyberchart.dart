import 'package:cyberframework/cyberframework.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

// ============================================================================
// DATA MODEL
// ============================================================================

/// Model class cho dữ liệu biểu đồ
class DataChartSeries {
  final dynamic xSeries;
  final dynamic ySeries;
  final Color? color;
  final CyberDataRow? dataRow;

  DataChartSeries({
    required this.xSeries,
    required this.ySeries,
    this.color,
    this.dataRow,
  });

  double get yValue {
    if (ySeries is num) return (ySeries as num).toDouble();
    if (ySeries is String) return double.tryParse(ySeries) ?? 0;
    return 0;
  }

  String get xLabel => xSeries?.toString() ?? '';
}

/// Cấu hình series cho multi-series chart
class ChartSeriesConfig {
  final String label;
  final Color color;
  final List<DataChartSeries> data;
  final String yField;

  ChartSeriesConfig({
    required this.label,
    required this.color,
    required this.data,
    this.yField = 'ySeries',
  });
}

// ============================================================================
// MAIN CARTESIAN CHART WIDGET
// ============================================================================

/// CyberChart - Biểu đồ Cartesian hỗ trợ nhiều loại
///
/// Các loại biểu đồ (chartType):
/// - 'C': Column chart (mặc định) - Biểu đồ cột dọc
/// - 'L': Line chart - Biểu đồ đường
/// - 'S': Stacked column - Biểu đồ cột chồng dọc
/// - 'SB': Stacked bar - Biểu đồ cột chồng ngang
/// - 'W': Waterfall chart - Biểu đồ thác nước
/// - 'B': Bar chart - Biểu đồ cột ngang
/// - 'A': Area chart - Biểu đồ vùng
/// - 'SA': Stacked area - Biểu đồ vùng chồng
class CyberChart extends StatefulWidget {
  /// Nguồn dữ liệu từ CyberDataTable
  final CyberDataTable dataSource;

  /// Cấu hình biểu đồ (chứa Type, Note, Color)
  final CyberDataRow? rowCaption;

  /// Loại biểu đồ: C, L, S, SB, W, B, A, SA
  final String chartType;

  /// Tiêu đề biểu đồ
  final String? title;

  /// Danh sách tên series (phân cách bởi dấu phẩy)
  final String? seriesNotes;

  /// Danh sách màu series (phân cách bởi dấu phẩy, hex color)
  final String? seriesColors;

  /// Hiển thị legend
  final bool showLegend;

  /// Vị trí legend
  final LegendPosition legendPosition;

  /// Hiển thị tooltip
  final bool enableTooltip;

  /// Hiển thị data labels
  final bool showDataLabels;

  /// Bật animation
  final bool enableAnimation;

  /// Thời gian animation (ms)
  final int animationDuration;

  /// Bật zoom/pan
  final bool enableZoomPan;

  /// Xoay ngang (cho bar chart)
  final bool isTransposed;

  /// Khoảng cách giữa các cột
  final double spacing;

  /// Bo góc cột
  final double borderRadius;

  /// Font size cho label trục X
  final double fontSizePrimaryAxis;

  /// Font size cho label trục Y
  final double fontSizeSecondaryAxis;

  /// Màu nền
  final Color? backgroundColor;

  /// Padding
  final EdgeInsets? margin;

  /// Callback khi tap vào điểm dữ liệu
  final void Function(DataChartSeries data, int seriesIndex, int pointIndex)?
  onPointTap;

  /// Trackball behavior
  final bool enableTrackball;

  /// Crosshair behavior
  final bool enableCrosshair;

  /// Format cho Y axis labels
  final String? yAxisLabelFormat;

  /// Minimum Y value
  final double? yAxisMinimum;

  /// Maximum Y value
  final double? yAxisMaximum;

  /// Interval cho Y axis
  final double? yAxisInterval;

  const CyberChart({
    super.key,
    required this.dataSource,
    this.rowCaption,
    this.chartType = 'C',
    this.title,
    this.seriesNotes,
    this.seriesColors,
    this.showLegend = true,
    this.legendPosition = LegendPosition.bottom,
    this.enableTooltip = true,
    this.showDataLabels = false,
    this.enableAnimation = true,
    this.animationDuration = 1500,
    this.enableZoomPan = true,
    this.isTransposed = false,
    this.spacing = 0.2,
    this.borderRadius = 0,
    this.fontSizePrimaryAxis = 12,
    this.fontSizeSecondaryAxis = 12,
    this.backgroundColor,
    this.margin,
    this.onPointTap,
    this.enableTrackball = false,
    this.enableCrosshair = false,
    this.yAxisLabelFormat,
    this.yAxisMinimum,
    this.yAxisMaximum,
    this.yAxisInterval,
  });

  @override
  State<CyberChart> createState() => _CyberChartState();
}

class _CyberChartState extends State<CyberChart> {
  late List<ChartSeriesConfig> _seriesConfigs;
  VoidCallback? _dataSourceListener;

  @override
  void initState() {
    super.initState();
    _buildSeriesData();
    _setupListener();
  }

  @override
  void didUpdateWidget(CyberChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataSource != widget.dataSource) {
      _removeListener(oldWidget.dataSource);
      _buildSeriesData();
      _setupListener();
    } else if (oldWidget.chartType != widget.chartType ||
        oldWidget.seriesNotes != widget.seriesNotes ||
        oldWidget.seriesColors != widget.seriesColors) {
      _buildSeriesData();
    }
  }

  @override
  void dispose() {
    _removeListener(widget.dataSource);
    super.dispose();
  }

  void _setupListener() {
    _dataSourceListener = () {
      if (mounted) {
        setState(() {
          _buildSeriesData();
        });
      }
    };
    widget.dataSource.addListener(_dataSourceListener!);
  }

  void _removeListener(CyberDataTable dataSource) {
    if (_dataSourceListener != null) {
      dataSource.removeListener(_dataSourceListener!);
      _dataSourceListener = null;
    }
  }

  /// Lấy loại chart từ rowCaption hoặc widget property
  String get _chartType {
    if (widget.rowCaption != null && widget.rowCaption!.hasField('Type')) {
      return widget.rowCaption!['Type'].toString().trim().toUpperCase();
    }
    return widget.chartType.toUpperCase();
  }

  /// Lấy danh sách tên series
  List<String> get _seriesNames {
    String notes = '';
    if (widget.rowCaption != null && widget.rowCaption!.hasField('Note')) {
      notes = widget.rowCaption!['Note'].toString();
    } else if (widget.seriesNotes != null) {
      notes = widget.seriesNotes!;
    }
    return notes.split(',').map((e) => e.trim()).toList();
  }

  /// Lấy danh sách màu series
  List<Color> get _seriesColors {
    String colors = '';
    if (widget.rowCaption != null && widget.rowCaption!.hasField('Color')) {
      colors = widget.rowCaption!['Color'].toString();
    } else if (widget.seriesColors != null) {
      colors = widget.seriesColors!;
    }
    return colors.split(',').map((e) => e.trim().parseColor()).toList();
  }

  /// Xây dựng dữ liệu cho các series
  void _buildSeriesData() {
    _seriesConfigs = [];
    final dataSource = widget.dataSource;
    if (dataSource.rows.isEmpty) return;

    // Tìm các series unique
    final Set<String> uniqueSeries = {};
    for (var dr in dataSource.rows) {
      final seri = dr.hasField('seri')
          ? dr['seri'].toString().toUpperCase()
          : '';
      uniqueSeries.add(seri);
    }

    // Đếm số lượng ySeries columns
    int ySeriesCount = 1;
    while (dataSource.containerColumn('ySeries$ySeriesCount')) {
      ySeriesCount++;
    }

    final names = _seriesNames;
    final colors = _seriesColors;

    // Default colors nếu không được cung cấp
    final defaultColors = [
      const Color(0xFF4285F4), // Blue
      const Color(0xFFEA4335), // Red
      const Color(0xFFFBBC05), // Yellow
      const Color(0xFF34A853), // Green
      const Color(0xFF9C27B0), // Purple
      const Color(0xFFFF9800), // Orange
      const Color(0xFF00BCD4), // Cyan
      const Color(0xFFE91E63), // Pink
    ];

    int seriesIndex = 0;

    for (var seri in uniqueSeries) {
      for (int yIndex = 0; yIndex < ySeriesCount; yIndex++) {
        final yField = yIndex == 0 ? 'ySeries' : 'ySeries$yIndex';
        final List<DataChartSeries> data = [];

        for (var dr in dataSource.rows) {
          final drSeri = dr.hasField('seri')
              ? dr['seri'].toString().toUpperCase()
              : '';
          if (drSeri != seri) continue;

          Color? pointColor;
          if (dr.hasField('color')) {
            pointColor = dr['color'].toString().parseColor();
          }

          data.add(
            DataChartSeries(
              xSeries: dr.hasField('xSeries') ? dr['xSeries'] : '',
              ySeries: dr.hasField(yField) ? dr[yField] : 0,
              color: pointColor,
              dataRow: dr,
            ),
          );
        }

        if (data.isNotEmpty) {
          final label = seriesIndex < names.length
              ? names[seriesIndex]
              : 'Series ${seriesIndex + 1}';
          final color = seriesIndex < colors.length
              ? colors[seriesIndex]
              : defaultColors[seriesIndex % defaultColors.length];

          _seriesConfigs.add(
            ChartSeriesConfig(
              label: label,
              color: color,
              data: data,
              yField: yField,
            ),
          );
          seriesIndex++;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chartType = _chartType;
    final isTransposed =
        widget.isTransposed || chartType == 'SB' || chartType == 'B';

    return SfCartesianChart(
      title: widget.title != null
          ? ChartTitle(text: widget.title!)
          : ChartTitle(text: ''),
      backgroundColor: widget.backgroundColor,
      margin: widget.margin ?? const EdgeInsets.all(10),
      legend: Legend(
        isVisible: widget.showLegend,
        position: widget.legendPosition,
        overflowMode: LegendItemOverflowMode.wrap,
      ),
      tooltipBehavior: TooltipBehavior(enable: widget.enableTooltip),
      zoomPanBehavior: widget.enableZoomPan
          ? ZoomPanBehavior(
              enablePinching: true,
              enablePanning: true,
              enableDoubleTapZooming: true,
              zoomMode: ZoomMode.xy,
            )
          : null,
      trackballBehavior: widget.enableTrackball
          ? TrackballBehavior(
              enable: true,
              activationMode: ActivationMode.singleTap,
            )
          : null,
      crosshairBehavior: widget.enableCrosshair
          ? CrosshairBehavior(
              enable: true,
              activationMode: ActivationMode.singleTap,
            )
          : null,
      isTransposed: isTransposed,
      primaryXAxis: CategoryAxis(
        labelPlacement: LabelPlacement.betweenTicks,
        labelStyle: TextStyle(
          fontSize: widget.fontSizePrimaryAxis,
          fontWeight: FontWeight.bold,
        ),
        majorGridLines: const MajorGridLines(width: 0),
      ),
      primaryYAxis: NumericAxis(
        labelStyle: TextStyle(
          fontSize: widget.fontSizeSecondaryAxis,
          fontWeight: FontWeight.bold,
        ),
        minimum: widget.yAxisMinimum,
        maximum: widget.yAxisMaximum,
        interval: widget.yAxisInterval,
      ),
      series: _buildSeries(chartType),
    );
  }

  /// Xây dựng danh sách series dựa trên loại chart
  List<CartesianSeries<DataChartSeries, dynamic>> _buildSeries(
    String chartType,
  ) {
    switch (chartType) {
      case 'L':
        return _buildLineSeries();
      case 'S':
      case 'SB':
        return _buildStackedColumnSeries();
      case 'W':
        return _buildWaterfallSeries();
      case 'B':
        return _buildBarSeries();
      case 'A':
        return _buildAreaSeries();
      case 'SA':
        return _buildStackedAreaSeries();
      case 'C':
      default:
        return _buildColumnSeries();
    }
  }

  /// Column Series
  List<CartesianSeries<DataChartSeries, dynamic>> _buildColumnSeries() {
    return _seriesConfigs.map((config) {
      return ColumnSeries<DataChartSeries, dynamic>(
        dataSource: config.data,
        xValueMapper: (data, _) => data.xLabel,
        yValueMapper: (data, _) => data.yValue,
        pointColorMapper: (data, _) => data.color ?? config.color,
        name: config.label,
        enableTooltip: widget.enableTooltip,
        animationDuration: widget.enableAnimation
            ? widget.animationDuration.toDouble()
            : 0,
        dataLabelSettings: DataLabelSettings(isVisible: widget.showDataLabels),
        spacing: widget.spacing,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        onPointTap: widget.onPointTap != null
            ? (ChartPointDetails details) {
                if (details.pointIndex != null) {
                  final seriesIdx = _seriesConfigs.indexOf(config);
                  widget.onPointTap!(
                    config.data[details.pointIndex!],
                    seriesIdx,
                    details.pointIndex!,
                  );
                }
              }
            : null,
      );
    }).toList();
  }

  /// Bar Series (horizontal column)
  List<CartesianSeries<DataChartSeries, dynamic>> _buildBarSeries() {
    return _seriesConfigs.map((config) {
      return ColumnSeries<DataChartSeries, dynamic>(
        dataSource: config.data,
        xValueMapper: (data, _) => data.xLabel,
        yValueMapper: (data, _) => data.yValue,
        pointColorMapper: (data, _) => data.color ?? config.color,
        name: config.label,
        enableTooltip: widget.enableTooltip,
        animationDuration: widget.enableAnimation
            ? widget.animationDuration.toDouble()
            : 0,
        dataLabelSettings: DataLabelSettings(isVisible: widget.showDataLabels),
        spacing: widget.spacing,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        onPointTap: widget.onPointTap != null
            ? (ChartPointDetails details) {
                if (details.pointIndex != null) {
                  final seriesIdx = _seriesConfigs.indexOf(config);
                  widget.onPointTap!(
                    config.data[details.pointIndex!],
                    seriesIdx,
                    details.pointIndex!,
                  );
                }
              }
            : null,
      );
    }).toList();
  }

  /// Line Series
  List<CartesianSeries<DataChartSeries, dynamic>> _buildLineSeries() {
    return _seriesConfigs.map((config) {
      return LineSeries<DataChartSeries, dynamic>(
        dataSource: config.data,
        xValueMapper: (data, _) => data.xLabel,
        yValueMapper: (data, _) => data.yValue,
        color: config.color,
        name: config.label,
        enableTooltip: widget.enableTooltip,
        animationDuration: widget.enableAnimation
            ? widget.animationDuration.toDouble()
            : 0,
        dataLabelSettings: DataLabelSettings(isVisible: widget.showDataLabels),
        markerSettings: const MarkerSettings(
          isVisible: true,
          shape: DataMarkerType.circle,
        ),
        onPointTap: widget.onPointTap != null
            ? (ChartPointDetails details) {
                if (details.pointIndex != null) {
                  final seriesIdx = _seriesConfigs.indexOf(config);
                  widget.onPointTap!(
                    config.data[details.pointIndex!],
                    seriesIdx,
                    details.pointIndex!,
                  );
                }
              }
            : null,
      );
    }).toList();
  }

  /// Stacked Column Series
  List<CartesianSeries<DataChartSeries, dynamic>> _buildStackedColumnSeries() {
    return _seriesConfigs.map((config) {
      return StackedColumnSeries<DataChartSeries, dynamic>(
        dataSource: config.data,
        xValueMapper: (data, _) => data.xLabel,
        yValueMapper: (data, _) => data.yValue,
        pointColorMapper: (data, _) => data.color ?? config.color,
        name: config.label,
        enableTooltip: widget.enableTooltip,
        animationDuration: widget.enableAnimation
            ? widget.animationDuration.toDouble()
            : 0,
        dataLabelSettings: DataLabelSettings(isVisible: widget.showDataLabels),
        spacing: widget.spacing,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        onPointTap: widget.onPointTap != null
            ? (ChartPointDetails details) {
                if (details.pointIndex != null) {
                  final seriesIdx = _seriesConfigs.indexOf(config);
                  widget.onPointTap!(
                    config.data[details.pointIndex!],
                    seriesIdx,
                    details.pointIndex!,
                  );
                }
              }
            : null,
      );
    }).toList();
  }

  /// Area Series
  List<CartesianSeries<DataChartSeries, dynamic>> _buildAreaSeries() {
    return _seriesConfigs.map((config) {
      return AreaSeries<DataChartSeries, dynamic>(
        dataSource: config.data,
        xValueMapper: (data, _) => data.xLabel,
        yValueMapper: (data, _) => data.yValue,
        color: config.color.withValues(alpha: 0.6),
        borderColor: config.color,
        borderWidth: 2,
        name: config.label,
        enableTooltip: widget.enableTooltip,
        animationDuration: widget.enableAnimation
            ? widget.animationDuration.toDouble()
            : 0,
        dataLabelSettings: DataLabelSettings(isVisible: widget.showDataLabels),
        onPointTap: widget.onPointTap != null
            ? (ChartPointDetails details) {
                if (details.pointIndex != null) {
                  final seriesIdx = _seriesConfigs.indexOf(config);
                  widget.onPointTap!(
                    config.data[details.pointIndex!],
                    seriesIdx,
                    details.pointIndex!,
                  );
                }
              }
            : null,
      );
    }).toList();
  }

  /// Stacked Area Series
  List<CartesianSeries<DataChartSeries, dynamic>> _buildStackedAreaSeries() {
    return _seriesConfigs.map((config) {
      return StackedAreaSeries<DataChartSeries, dynamic>(
        dataSource: config.data,
        xValueMapper: (data, _) => data.xLabel,
        yValueMapper: (data, _) => data.yValue,
        color: config.color.withValues(alpha: 0.6),
        borderColor: config.color,
        borderWidth: 2,
        name: config.label,
        enableTooltip: widget.enableTooltip,
        animationDuration: widget.enableAnimation
            ? widget.animationDuration.toDouble()
            : 0,
        dataLabelSettings: DataLabelSettings(isVisible: widget.showDataLabels),
        onPointTap: widget.onPointTap != null
            ? (ChartPointDetails details) {
                if (details.pointIndex != null) {
                  final seriesIdx = _seriesConfigs.indexOf(config);
                  widget.onPointTap!(
                    config.data[details.pointIndex!],
                    seriesIdx,
                    details.pointIndex!,
                  );
                }
              }
            : null,
      );
    }).toList();
  }

  /// Waterfall Series
  List<CartesianSeries<DataChartSeries, dynamic>> _buildWaterfallSeries() {
    if (_seriesConfigs.isEmpty) return [];

    final config = _seriesConfigs.first;
    return [
      WaterfallSeries<DataChartSeries, dynamic>(
        dataSource: config.data,
        xValueMapper: (data, _) => data.xLabel,
        yValueMapper: (data, _) => data.yValue,
        color: config.color,
        name: config.label,
        enableTooltip: widget.enableTooltip,
        animationDuration: widget.enableAnimation
            ? widget.animationDuration.toDouble()
            : 0,
        dataLabelSettings: DataLabelSettings(isVisible: widget.showDataLabels),
        spacing: widget.spacing,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        connectorLineSettings: const WaterfallConnectorLineSettings(
          width: 1,
          color: Colors.grey,
        ),
        onPointTap: widget.onPointTap != null
            ? (ChartPointDetails details) {
                if (details.pointIndex != null) {
                  widget.onPointTap!(
                    config.data[details.pointIndex!],
                    0,
                    details.pointIndex!,
                  );
                }
              }
            : null,
      ),
    ];
  }
}

// ============================================================================
// STANDALONE SERIES WIDGETS
// ============================================================================

/// CyberColumnSeries - Biểu đồ cột đơn giản
class CyberColumnSeries extends StatefulWidget {
  final CyberDataTable dataSource;
  final String? title;
  final Color? color;
  final bool showLegend;
  final bool enableTooltip;
  final bool showDataLabels;
  final bool enableAnimation;
  final double spacing;
  final double borderRadius;
  final String? formatLabels;
  final void Function(DataChartSeries data, int index)? onPointTap;

  const CyberColumnSeries({
    super.key,
    required this.dataSource,
    this.title,
    this.color,
    this.showLegend = false,
    this.enableTooltip = true,
    this.showDataLabels = false,
    this.enableAnimation = true,
    this.spacing = 0.2,
    this.borderRadius = 0,
    this.formatLabels,
    this.onPointTap,
  });

  @override
  State<CyberColumnSeries> createState() => _CyberColumnSeriesState();
}

class _CyberColumnSeriesState extends State<CyberColumnSeries> {
  late List<DataChartSeries> _data;
  VoidCallback? _listener;

  @override
  void initState() {
    super.initState();
    _buildData();
    _setupListener();
  }

  @override
  void dispose() {
    _removeListener();
    super.dispose();
  }

  void _setupListener() {
    _listener = () {
      if (mounted) {
        setState(() => _buildData());
      }
    };
    widget.dataSource.addListener(_listener!);
  }

  void _removeListener() {
    if (_listener != null) {
      widget.dataSource.removeListener(_listener!);
    }
  }

  void _buildData() {
    _data = widget.dataSource.rows.map((dr) {
      return DataChartSeries(
        xSeries: dr.hasField('xSeries') ? dr['xSeries'] : '',
        ySeries: dr.hasField('ySeries') ? dr['ySeries'] : 0,
        color: dr.hasField('color')
            ? dr['color'].toString().parseColor()
            : null,
        dataRow: dr,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      title: widget.title != null
          ? ChartTitle(text: widget.title!)
          : ChartTitle(text: ''),
      legend: Legend(isVisible: widget.showLegend),
      tooltipBehavior: TooltipBehavior(enable: widget.enableTooltip),
      primaryXAxis: CategoryAxis(),
      primaryYAxis: NumericAxis(),
      series: <CartesianSeries<DataChartSeries, dynamic>>[
        ColumnSeries<DataChartSeries, dynamic>(
          dataSource: _data,
          xValueMapper: (data, _) => data.xLabel,
          yValueMapper: (data, _) => data.yValue,
          pointColorMapper: (data, _) =>
              data.color ?? widget.color ?? Colors.blue,
          enableTooltip: widget.enableTooltip,
          animationDuration: widget.enableAnimation ? 1500 : 0,
          dataLabelSettings: DataLabelSettings(
            isVisible: widget.showDataLabels,
          ),
          spacing: widget.spacing,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          onPointTap: widget.onPointTap != null
              ? (ChartPointDetails details) {
                  if (details.pointIndex != null) {
                    widget.onPointTap!(
                      _data[details.pointIndex!],
                      details.pointIndex!,
                    );
                  }
                }
              : null,
        ),
      ],
    );
  }
}

/// CyberLineSeries - Biểu đồ đường đơn giản
class CyberLineSeries extends StatefulWidget {
  final CyberDataTable dataSource;
  final String? title;
  final Color? color;
  final bool showLegend;
  final bool enableTooltip;
  final bool showDataLabels;
  final bool enableAnimation;
  final bool showMarkers;
  final double lineWidth;
  final void Function(DataChartSeries data, int index)? onPointTap;

  const CyberLineSeries({
    super.key,
    required this.dataSource,
    this.title,
    this.color,
    this.showLegend = false,
    this.enableTooltip = true,
    this.showDataLabels = false,
    this.enableAnimation = true,
    this.showMarkers = true,
    this.lineWidth = 2,
    this.onPointTap,
  });

  @override
  State<CyberLineSeries> createState() => _CyberLineSeriesState();
}

class _CyberLineSeriesState extends State<CyberLineSeries> {
  late List<DataChartSeries> _data;
  VoidCallback? _listener;

  @override
  void initState() {
    super.initState();
    _buildData();
    _setupListener();
  }

  @override
  void dispose() {
    _removeListener();
    super.dispose();
  }

  void _setupListener() {
    _listener = () {
      if (mounted) {
        setState(() => _buildData());
      }
    };
    widget.dataSource.addListener(_listener!);
  }

  void _removeListener() {
    if (_listener != null) {
      widget.dataSource.removeListener(_listener!);
    }
  }

  void _buildData() {
    _data = widget.dataSource.rows.map((dr) {
      return DataChartSeries(
        xSeries: dr.hasField('xSeries') ? dr['xSeries'] : '',
        ySeries: dr.hasField('ySeries') ? dr['ySeries'] : 0,
        color: dr.hasField('color')
            ? dr['color'].toString().parseColor()
            : null,
        dataRow: dr,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      title: widget.title != null
          ? ChartTitle(text: widget.title!)
          : ChartTitle(text: ''),
      legend: Legend(isVisible: widget.showLegend),
      tooltipBehavior: TooltipBehavior(enable: widget.enableTooltip),
      primaryXAxis: CategoryAxis(),
      primaryYAxis: NumericAxis(),
      series: <CartesianSeries<DataChartSeries, dynamic>>[
        LineSeries<DataChartSeries, dynamic>(
          dataSource: _data,
          xValueMapper: (data, _) => data.xLabel,
          yValueMapper: (data, _) => data.yValue,
          color: widget.color ?? Colors.blue,
          width: widget.lineWidth,
          enableTooltip: widget.enableTooltip,
          animationDuration: widget.enableAnimation ? 1500 : 0,
          dataLabelSettings: DataLabelSettings(
            isVisible: widget.showDataLabels,
          ),
          markerSettings: MarkerSettings(
            isVisible: widget.showMarkers,
            shape: DataMarkerType.circle,
          ),
          onPointTap: widget.onPointTap != null
              ? (ChartPointDetails details) {
                  if (details.pointIndex != null) {
                    widget.onPointTap!(
                      _data[details.pointIndex!],
                      details.pointIndex!,
                    );
                  }
                }
              : null,
        ),
      ],
    );
  }
}

/// CyberAreaSeries - Biểu đồ vùng đơn giản
class CyberAreaSeries extends StatefulWidget {
  final CyberDataTable dataSource;
  final String? title;
  final Color? color;
  final bool showLegend;
  final bool enableTooltip;
  final bool showDataLabels;
  final bool enableAnimation;
  final double opacity;
  final void Function(DataChartSeries data, int index)? onPointTap;

  const CyberAreaSeries({
    super.key,
    required this.dataSource,
    this.title,
    this.color,
    this.showLegend = false,
    this.enableTooltip = true,
    this.showDataLabels = false,
    this.enableAnimation = true,
    this.opacity = 0.6,
    this.onPointTap,
  });

  @override
  State<CyberAreaSeries> createState() => _CyberAreaSeriesState();
}

class _CyberAreaSeriesState extends State<CyberAreaSeries> {
  late List<DataChartSeries> _data;
  VoidCallback? _listener;

  @override
  void initState() {
    super.initState();
    _buildData();
    _setupListener();
  }

  @override
  void dispose() {
    _removeListener();
    super.dispose();
  }

  void _setupListener() {
    _listener = () {
      if (mounted) {
        setState(() => _buildData());
      }
    };
    widget.dataSource.addListener(_listener!);
  }

  void _removeListener() {
    if (_listener != null) {
      widget.dataSource.removeListener(_listener!);
    }
  }

  void _buildData() {
    _data = widget.dataSource.rows.map((dr) {
      return DataChartSeries(
        xSeries: dr.hasField('xSeries') ? dr['xSeries'] : '',
        ySeries: dr.hasField('ySeries') ? dr['ySeries'] : 0,
        color: dr.hasField('color')
            ? dr['color'].toString().parseColor()
            : null,
        dataRow: dr,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.color ?? Colors.blue;
    return SfCartesianChart(
      title: widget.title != null
          ? ChartTitle(text: widget.title!)
          : ChartTitle(text: ''),
      legend: Legend(isVisible: widget.showLegend),
      tooltipBehavior: TooltipBehavior(enable: widget.enableTooltip),
      primaryXAxis: CategoryAxis(),
      primaryYAxis: NumericAxis(),
      series: <CartesianSeries<DataChartSeries, dynamic>>[
        AreaSeries<DataChartSeries, dynamic>(
          dataSource: _data,
          xValueMapper: (data, _) => data.xLabel,
          yValueMapper: (data, _) => data.yValue,
          color: baseColor.withValues(alpha: widget.opacity),
          borderColor: baseColor,
          borderWidth: 2,
          enableTooltip: widget.enableTooltip,
          animationDuration: widget.enableAnimation ? 1500 : 0,
          dataLabelSettings: DataLabelSettings(
            isVisible: widget.showDataLabels,
          ),
          onPointTap: widget.onPointTap != null
              ? (ChartPointDetails details) {
                  if (details.pointIndex != null) {
                    widget.onPointTap!(
                      _data[details.pointIndex!],
                      details.pointIndex!,
                    );
                  }
                }
              : null,
        ),
      ],
    );
  }
}

/// CyberStackedColumnSeries - Biểu đồ cột chồng
class CyberStackedColumnSeries extends StatefulWidget {
  final CyberDataTable dataSource;
  final String? title;
  final String? seriesNotes;
  final String? seriesColors;
  final bool showLegend;
  final bool enableTooltip;
  final bool showDataLabels;
  final bool enableAnimation;
  final double spacing;
  final bool isTransposed;
  final void Function(DataChartSeries data, int seriesIndex, int index)?
  onPointTap;

  const CyberStackedColumnSeries({
    super.key,
    required this.dataSource,
    this.title,
    this.seriesNotes,
    this.seriesColors,
    this.showLegend = true,
    this.enableTooltip = true,
    this.showDataLabels = false,
    this.enableAnimation = true,
    this.spacing = 0.2,
    this.isTransposed = false,
    this.onPointTap,
  });

  @override
  State<CyberStackedColumnSeries> createState() =>
      _CyberStackedColumnSeriesState();
}

class _CyberStackedColumnSeriesState extends State<CyberStackedColumnSeries> {
  late List<ChartSeriesConfig> _seriesConfigs;
  VoidCallback? _listener;

  @override
  void initState() {
    super.initState();
    _buildData();
    _setupListener();
  }

  @override
  void dispose() {
    _removeListener();
    super.dispose();
  }

  void _setupListener() {
    _listener = () {
      if (mounted) {
        setState(() => _buildData());
      }
    };
    widget.dataSource.addListener(_listener!);
  }

  void _removeListener() {
    if (_listener != null) {
      widget.dataSource.removeListener(_listener!);
    }
  }

  void _buildData() {
    _seriesConfigs = [];
    final dataSource = widget.dataSource;
    if (dataSource.rows.isEmpty) return;

    int ySeriesCount = 1;
    while (dataSource.containerColumn('ySeries$ySeriesCount')) {
      ySeriesCount++;
    }

    final names = (widget.seriesNotes ?? '')
        .split(',')
        .map((e) => e.trim())
        .toList();
    final colors = (widget.seriesColors ?? '')
        .split(',')
        .map((e) => e.trim().parseColor())
        .toList();

    final defaultColors = [
      const Color(0xFF4285F4),
      const Color(0xFFEA4335),
      const Color(0xFFFBBC05),
      const Color(0xFF34A853),
    ];

    for (int i = 0; i < ySeriesCount; i++) {
      final yField = i == 0 ? 'ySeries' : 'ySeries$i';
      final List<DataChartSeries> data = [];

      for (var dr in dataSource.rows) {
        data.add(
          DataChartSeries(
            xSeries: dr.hasField('xSeries') ? dr['xSeries'] : '',
            ySeries: dr.hasField(yField) ? dr[yField] : 0,
            dataRow: dr,
          ),
        );
      }

      if (data.isNotEmpty) {
        _seriesConfigs.add(
          ChartSeriesConfig(
            label: i < names.length ? names[i] : 'Series ${i + 1}',
            color: i < colors.length
                ? colors[i]
                : defaultColors[i % defaultColors.length],
            data: data,
            yField: yField,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      title: widget.title != null
          ? ChartTitle(text: widget.title!)
          : ChartTitle(text: ''),
      legend: Legend(
        isVisible: widget.showLegend,
        position: LegendPosition.bottom,
      ),
      tooltipBehavior: TooltipBehavior(enable: widget.enableTooltip),
      isTransposed: widget.isTransposed,
      primaryXAxis: CategoryAxis(),
      primaryYAxis: NumericAxis(),
      series: _seriesConfigs.map((config) {
        return StackedColumnSeries<DataChartSeries, dynamic>(
          dataSource: config.data,
          xValueMapper: (data, _) => data.xLabel,
          yValueMapper: (data, _) => data.yValue,
          color: config.color,
          name: config.label,
          enableTooltip: widget.enableTooltip,
          animationDuration: widget.enableAnimation ? 1500 : 0,
          dataLabelSettings: DataLabelSettings(
            isVisible: widget.showDataLabels,
          ),
          spacing: widget.spacing,
          onPointTap: widget.onPointTap != null
              ? (ChartPointDetails details) {
                  if (details.pointIndex != null) {
                    widget.onPointTap!(
                      config.data[details.pointIndex!],
                      _seriesConfigs.indexOf(config),
                      details.pointIndex!,
                    );
                  }
                }
              : null,
        );
      }).toList(),
    );
  }
}

/// CyberWaterfallSeries - Biểu đồ thác nước
class CyberWaterfallSeries extends StatefulWidget {
  final CyberDataTable dataSource;
  final String? title;
  final Color? color;
  final Color? negativeColor;
  final Color? totalColor;
  final bool showLegend;
  final bool enableTooltip;
  final bool showDataLabels;
  final bool enableAnimation;
  final bool showConnectorLine;
  final double spacing;
  final void Function(DataChartSeries data, int index)? onPointTap;

  const CyberWaterfallSeries({
    super.key,
    required this.dataSource,
    this.title,
    this.color,
    this.negativeColor,
    this.totalColor,
    this.showLegend = false,
    this.enableTooltip = true,
    this.showDataLabels = false,
    this.enableAnimation = true,
    this.showConnectorLine = true,
    this.spacing = 0.2,
    this.onPointTap,
  });

  @override
  State<CyberWaterfallSeries> createState() => _CyberWaterfallSeriesState();
}

class _CyberWaterfallSeriesState extends State<CyberWaterfallSeries> {
  late List<DataChartSeries> _data;
  VoidCallback? _listener;

  @override
  void initState() {
    super.initState();
    _buildData();
    _setupListener();
  }

  @override
  void dispose() {
    _removeListener();
    super.dispose();
  }

  void _setupListener() {
    _listener = () {
      if (mounted) {
        setState(() => _buildData());
      }
    };
    widget.dataSource.addListener(_listener!);
  }

  void _removeListener() {
    if (_listener != null) {
      widget.dataSource.removeListener(_listener!);
    }
  }

  void _buildData() {
    _data = widget.dataSource.rows.map((dr) {
      return DataChartSeries(
        xSeries: dr.hasField('xSeries') ? dr['xSeries'] : '',
        ySeries: dr.hasField('ySeries') ? dr['ySeries'] : 0,
        dataRow: dr,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      title: widget.title != null
          ? ChartTitle(text: widget.title!)
          : ChartTitle(text: ''),
      legend: Legend(isVisible: widget.showLegend),
      tooltipBehavior: TooltipBehavior(enable: widget.enableTooltip),
      primaryXAxis: CategoryAxis(),
      primaryYAxis: NumericAxis(),
      series: <CartesianSeries<DataChartSeries, dynamic>>[
        WaterfallSeries<DataChartSeries, dynamic>(
          dataSource: _data,
          xValueMapper: (data, _) => data.xLabel,
          yValueMapper: (data, _) => data.yValue,
          color: widget.color ?? Colors.blue,
          negativePointsColor: widget.negativeColor ?? Colors.red,
          totalSumColor: widget.totalColor ?? Colors.green,
          //totalPointsColor: widget.totalColor ?? Colors.green,
          enableTooltip: widget.enableTooltip,
          animationDuration: widget.enableAnimation ? 1500 : 0,
          dataLabelSettings: DataLabelSettings(
            isVisible: widget.showDataLabels,
          ),
          spacing: widget.spacing,
          connectorLineSettings: WaterfallConnectorLineSettings(
            width: widget.showConnectorLine ? 1 : 0,
            color: Colors.grey,
          ),
          onPointTap: widget.onPointTap != null
              ? (ChartPointDetails details) {
                  if (details.pointIndex != null) {
                    widget.onPointTap!(
                      _data[details.pointIndex!],
                      details.pointIndex!,
                    );
                  }
                }
              : null,
        ),
      ],
    );
  }
}
