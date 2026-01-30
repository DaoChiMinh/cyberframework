import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:cyberframework/cyberframework.dart';

// =============================================================================
// CYBER CHART CIR - Circular Charts for CyberFramework
// Compatible with syncfusion_flutter_charts ^32.1.21
// =============================================================================

/// Model dữ liệu cho chart series
// class DataChartSeries {
//   dynamic xSeries;
//   dynamic ySeries;
//   CyberDataRow? dataRow;
//   Color color;

//   DataChartSeries({
//     this.xSeries,
//     this.ySeries,
//     this.dataRow,
//     this.color = const Color(0xFFCCCCCC),
//   });
// }

/// Widget biểu đồ tròn tương đương CyberMauiChartCir
///
/// Supported chart types (via rowCaption['Type']):
/// - 'P'  : Pie Chart (biểu đồ tròn)
/// - 'U'  : Doughnut Chart (biểu đồ tròn rỗng giữa)
/// - 'SP' : Semi-Pie Chart (biểu đồ nửa hình tròn)
/// - 'R'  : Radial Bar Chart (biểu đồ thanh xuyên tâm)
class CyberChartCir extends StatefulWidget {
  final CyberDataTable? dataSource;
  final CyberDataRow? rowCaption;
  final int fontSizeLabelPrimaryAxis;
  final int fontSizeLabelSecondaryAxis;
  final bool showLegend;
  final LegendPosition legendPosition;
  final String? title;
  final bool enableTooltip;
  final bool enableSelection;
  final ValueChanged<DataChartSeries?>? onPointTap;
  final Color? backgroundColor;
  final EdgeInsets? margin;

  const CyberChartCir({
    super.key,
    this.dataSource,
    this.rowCaption,
    this.fontSizeLabelPrimaryAxis = 12,
    this.fontSizeLabelSecondaryAxis = 12,
    this.showLegend = true,
    this.legendPosition = LegendPosition.bottom,
    this.title,
    this.enableTooltip = true,
    this.enableSelection = false,
    this.onPointTap,
    this.backgroundColor,
    this.margin,
  });

  @override
  State<CyberChartCir> createState() => _CyberChartCirState();
}

class _CyberChartCirState extends State<CyberChartCir> {
  List<DataChartSeries> _chartData = [];
  VoidCallback? _dataSourceListener;

  @override
  void initState() {
    super.initState();
    _processDataSource();
    _attachListener();
  }

  @override
  void didUpdateWidget(CyberChartCir oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataSource != widget.dataSource) {
      _detachListener(oldWidget.dataSource);
      _processDataSource();
      _attachListener();
    } else if (oldWidget.rowCaption != widget.rowCaption) {
      setState(() {});
    }
  }

  void _attachListener() {
    if (widget.dataSource != null) {
      _dataSourceListener = () {
        if (mounted) {
          _processDataSource();
          setState(() {});
        }
      };
      widget.dataSource!.addListener(_dataSourceListener!);
    }
  }

  void _detachListener(CyberDataTable? oldDataSource) {
    if (oldDataSource != null && _dataSourceListener != null) {
      oldDataSource.removeListener(_dataSourceListener!);
      _dataSourceListener = null;
    }
  }

  void _processDataSource() {
    _chartData.clear();

    if (widget.dataSource == null) return;

    for (var dr in widget.dataSource!.rows) {
      final color = dr.hasField('color')
          ? (dr['color']?.toString() ?? '#cccccc').parseColor()
          : const Color(0xFFCCCCCC);

      _chartData.add(
        DataChartSeries(
          xSeries: dr['xSeries'],
          ySeries: dr['ySeries'],
          dataRow: dr,
          color: color,
        ),
      );
    }
  }

  String _getChartType() {
    if (widget.rowCaption == null) return 'P';
    return widget.rowCaption!['Type']?.toString().trim().toUpperCase() ?? 'P';
  }

  void _handlePointTap(ChartPointDetails details) {
    if (widget.onPointTap != null && details.pointIndex != null) {
      final index = details.pointIndex!;
      if (index >= 0 && index < _chartData.length) {
        widget.onPointTap!(_chartData[index]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chartType = _getChartType();

    return SfCircularChart(
      backgroundColor: widget.backgroundColor,
      margin: widget.margin ?? const EdgeInsets.all(10),
      title: widget.title != null
          ? ChartTitle(
              text: widget.title!,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            )
          : ChartTitle(text: ''),
      legend: Legend(
        isVisible: widget.showLegend,
        position: widget.legendPosition,
        overflowMode: LegendItemOverflowMode.wrap,
        textStyle: TextStyle(
          fontSize: widget.fontSizeLabelSecondaryAxis.toDouble(),
        ),
      ),
      tooltipBehavior: TooltipBehavior(
        enable: widget.enableTooltip,
        format: 'point.x: point.y',
      ),
      series: _buildSeries(chartType),
    );
  }

  List<CircularSeries<DataChartSeries, dynamic>> _buildSeries(
    String chartType,
  ) {
    final dataLabelStyle = TextStyle(
      fontSize: widget.fontSizeLabelPrimaryAxis.toDouble(),
    );

    switch (chartType) {
      case 'P': // Pie Chart
        return [
          PieSeries<DataChartSeries, dynamic>(
            dataSource: _chartData,
            xValueMapper: (data, _) => data.xSeries,
            yValueMapper: (data, _) => data.ySeries,
            pointColorMapper: (data, _) => data.color,
            dataLabelSettings: DataLabelSettings(
              isVisible: true,
              labelPosition: ChartDataLabelPosition.outside,
              textStyle: dataLabelStyle,
              connectorLineSettings: const ConnectorLineSettings(
                type: ConnectorType.curve,
                length: '10%',
              ),
            ),
            enableTooltip: widget.enableTooltip,
            animationDuration: 1000,
            explode: widget.enableSelection,
            explodeIndex: 0,
            selectionBehavior: SelectionBehavior(
              enable: widget.enableSelection,
            ),
            onPointTap: _handlePointTap,
          ),
        ];

      case 'U': // Doughnut Chart
        return [
          DoughnutSeries<DataChartSeries, dynamic>(
            dataSource: _chartData,
            xValueMapper: (data, _) => data.xSeries,
            yValueMapper: (data, _) => data.ySeries,
            pointColorMapper: (data, _) => data.color,
            innerRadius: '40%',
            dataLabelSettings: DataLabelSettings(
              isVisible: true,
              labelPosition: ChartDataLabelPosition.outside,
              textStyle: dataLabelStyle,
              connectorLineSettings: const ConnectorLineSettings(
                type: ConnectorType.curve,
                length: '10%',
              ),
            ),
            enableTooltip: widget.enableTooltip,
            animationDuration: 1000,
            explode: widget.enableSelection,
            selectionBehavior: SelectionBehavior(
              enable: widget.enableSelection,
            ),
            onPointTap: _handlePointTap,
          ),
        ];

      case 'SP': // Semi-Pie Chart
        return [
          PieSeries<DataChartSeries, dynamic>(
            dataSource: _chartData,
            xValueMapper: (data, _) => data.xSeries,
            yValueMapper: (data, _) => data.ySeries,
            pointColorMapper: (data, _) => data.color,
            startAngle: 180,
            endAngle: 360,
            dataLabelSettings: DataLabelSettings(
              isVisible: true,
              labelPosition: ChartDataLabelPosition.outside,
              textStyle: dataLabelStyle,
            ),
            enableTooltip: widget.enableTooltip,
            animationDuration: 1000,
            selectionBehavior: SelectionBehavior(
              enable: widget.enableSelection,
            ),
            onPointTap: _handlePointTap,
          ),
        ];

      case 'R': // Radial Bar Chart
        return [
          RadialBarSeries<DataChartSeries, dynamic>(
            dataSource: _chartData,
            xValueMapper: (data, _) => data.xSeries,
            yValueMapper: (data, _) => data.ySeries,
            pointColorMapper: (data, _) => data.color,
            innerRadius: '30%',
            cornerStyle: CornerStyle.bothCurve,
            trackColor: Colors.grey.shade200,
            trackOpacity: 0.3,
            dataLabelSettings: DataLabelSettings(
              isVisible: true,
              textStyle: dataLabelStyle,
            ),
            enableTooltip: widget.enableTooltip,
            animationDuration: 1000,
            selectionBehavior: SelectionBehavior(
              enable: widget.enableSelection,
            ),
            onPointTap: _handlePointTap,
          ),
        ];

      default:
        return [
          PieSeries<DataChartSeries, dynamic>(
            dataSource: _chartData,
            xValueMapper: (data, _) => data.xSeries,
            yValueMapper: (data, _) => data.ySeries,
            pointColorMapper: (data, _) => data.color,
            dataLabelSettings: const DataLabelSettings(isVisible: true),
            animationDuration: 1000,
            onPointTap: _handlePointTap,
          ),
        ];
    }
  }

  @override
  void dispose() {
    _detachListener(widget.dataSource);
    _chartData.clear();
    super.dispose();
  }
}

// =============================================================================
// CYBER PIE SERIES - Standalone Pie Chart Widget
// =============================================================================

class CyberPieSeries extends StatefulWidget {
  final CyberDataTable? dataSource;
  final bool showDataLabels;
  final bool enableAnimation;
  final bool enableTooltip;
  final int startAngle;
  final int endAngle;
  final double fontSize;
  final bool showLegend;
  final LegendPosition legendPosition;
  final String? title;
  final bool explode;
  final int? explodeIndex;
  final double explodeOffset;
  final ValueChanged<DataChartSeries?>? onPointTap;
  final Color? backgroundColor;

  const CyberPieSeries({
    super.key,
    this.dataSource,
    this.showDataLabels = false,
    this.enableAnimation = true,
    this.enableTooltip = true,
    this.startAngle = 0,
    this.endAngle = 360,
    this.fontSize = 15,
    this.showLegend = true,
    this.legendPosition = LegendPosition.bottom,
    this.title,
    this.explode = false,
    this.explodeIndex,
    this.explodeOffset = 10,
    this.onPointTap,
    this.backgroundColor,
  });

  @override
  State<CyberPieSeries> createState() => _CyberPieSeriesState();
}

class _CyberPieSeriesState extends State<CyberPieSeries> {
  List<DataChartSeries> _data = [];
  VoidCallback? _dataSourceListener;

  @override
  void initState() {
    super.initState();
    _loadData();
    _attachListener();
  }

  @override
  void didUpdateWidget(CyberPieSeries oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataSource != widget.dataSource) {
      _detachListener(oldWidget.dataSource);
      _loadData();
      _attachListener();
    }
  }

  void _attachListener() {
    if (widget.dataSource != null) {
      _dataSourceListener = () {
        if (mounted) {
          _loadData();
          setState(() {});
        }
      };
      widget.dataSource!.addListener(_dataSourceListener!);
    }
  }

  void _detachListener(CyberDataTable? oldDataSource) {
    if (oldDataSource != null && _dataSourceListener != null) {
      oldDataSource.removeListener(_dataSourceListener!);
      _dataSourceListener = null;
    }
  }

  void _loadData() {
    _data.clear();
    if (widget.dataSource == null) return;

    for (var item in widget.dataSource!.rows) {
      _data.add(
        DataChartSeries(
          xSeries: item['xSeries'],
          ySeries: item['ySeries'],
          dataRow: item,
          color: item.hasField('color')
              ? (item['color']?.toString() ?? '#cccccc').parseColor()
              : const Color(0xFFCCCCCC),
        ),
      );
    }
  }

  void _handlePointTap(ChartPointDetails details) {
    if (widget.onPointTap != null && details.pointIndex != null) {
      final index = details.pointIndex!;
      if (index >= 0 && index < _data.length) {
        widget.onPointTap!(_data[index]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SfCircularChart(
      backgroundColor: widget.backgroundColor,
      title: widget.title != null
          ? ChartTitle(
              text: widget.title!,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            )
          : ChartTitle(text: ''),
      legend: Legend(
        isVisible: widget.showLegend,
        position: widget.legendPosition,
        overflowMode: LegendItemOverflowMode.wrap,
      ),
      tooltipBehavior: TooltipBehavior(enable: widget.enableTooltip),
      series: <PieSeries<DataChartSeries, dynamic>>[
        PieSeries<DataChartSeries, dynamic>(
          dataSource: _data,
          xValueMapper: (data, _) => data.xSeries,
          yValueMapper: (data, _) => data.ySeries,
          pointColorMapper: (data, _) => data.color,
          startAngle: widget.startAngle,
          endAngle: widget.endAngle,
          explode: widget.explode,
          explodeIndex: widget.explodeIndex,
          explodeOffset: '${widget.explodeOffset}%',
          dataLabelSettings: DataLabelSettings(
            isVisible: widget.showDataLabels,
            labelPosition: ChartDataLabelPosition.outside,
            textStyle: TextStyle(fontSize: widget.fontSize),
            connectorLineSettings: const ConnectorLineSettings(
              type: ConnectorType.curve,
            ),
          ),
          enableTooltip: widget.enableTooltip,
          animationDuration: widget.enableAnimation ? 1000 : 0,
          onPointTap: _handlePointTap,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _detachListener(widget.dataSource);
    _data.clear();
    super.dispose();
  }
}

// =============================================================================
// CYBER DOUGHNUT SERIES - Standalone Doughnut Chart Widget
// =============================================================================

class CyberDoughnutSeries extends StatefulWidget {
  final CyberDataTable? dataSource;
  final bool showDataLabels;
  final bool enableAnimation;
  final bool enableTooltip;
  final double innerRadius;
  final double fontSize;
  final bool showLegend;
  final LegendPosition legendPosition;
  final String? title;
  final Widget? centerWidget;
  final bool explode;
  final int? explodeIndex;
  final ValueChanged<DataChartSeries?>? onPointTap;
  final Color? backgroundColor;
  final CornerStyle cornerStyle;

  const CyberDoughnutSeries({
    super.key,
    this.dataSource,
    this.showDataLabels = false,
    this.enableAnimation = true,
    this.enableTooltip = true,
    this.innerRadius = 0.4,
    this.fontSize = 15,
    this.showLegend = true,
    this.legendPosition = LegendPosition.bottom,
    this.title,
    this.centerWidget,
    this.explode = false,
    this.explodeIndex,
    this.onPointTap,
    this.backgroundColor,
    this.cornerStyle = CornerStyle.bothFlat,
  });

  @override
  State<CyberDoughnutSeries> createState() => _CyberDoughnutSeriesState();
}

class _CyberDoughnutSeriesState extends State<CyberDoughnutSeries> {
  List<DataChartSeries> _data = [];
  VoidCallback? _dataSourceListener;

  @override
  void initState() {
    super.initState();
    _loadData();
    _attachListener();
  }

  @override
  void didUpdateWidget(CyberDoughnutSeries oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataSource != widget.dataSource) {
      _detachListener(oldWidget.dataSource);
      _loadData();
      _attachListener();
    }
  }

  void _attachListener() {
    if (widget.dataSource != null) {
      _dataSourceListener = () {
        if (mounted) {
          _loadData();
          setState(() {});
        }
      };
      widget.dataSource!.addListener(_dataSourceListener!);
    }
  }

  void _detachListener(CyberDataTable? oldDataSource) {
    if (oldDataSource != null && _dataSourceListener != null) {
      oldDataSource.removeListener(_dataSourceListener!);
      _dataSourceListener = null;
    }
  }

  void _loadData() {
    _data.clear();
    if (widget.dataSource == null) return;

    for (var item in widget.dataSource!.rows) {
      _data.add(
        DataChartSeries(
          xSeries: item['xSeries'],
          ySeries: item['ySeries'],
          dataRow: item,
          color: item.hasField('color')
              ? (item['color']?.toString() ?? '#cccccc').parseColor()
              : const Color(0xFFCCCCCC),
        ),
      );
    }
  }

  void _handlePointTap(ChartPointDetails details) {
    if (widget.onPointTap != null && details.pointIndex != null) {
      final index = details.pointIndex!;
      if (index >= 0 && index < _data.length) {
        widget.onPointTap!(_data[index]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SfCircularChart(
      backgroundColor: widget.backgroundColor,
      title: widget.title != null
          ? ChartTitle(
              text: widget.title!,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            )
          : ChartTitle(text: ''),
      legend: Legend(
        isVisible: widget.showLegend,
        position: widget.legendPosition,
        overflowMode: LegendItemOverflowMode.wrap,
      ),
      tooltipBehavior: TooltipBehavior(enable: widget.enableTooltip),
      annotations: widget.centerWidget != null
          ? <CircularChartAnnotation>[
              CircularChartAnnotation(widget: widget.centerWidget!),
            ]
          : null,
      series: <DoughnutSeries<DataChartSeries, dynamic>>[
        DoughnutSeries<DataChartSeries, dynamic>(
          dataSource: _data,
          xValueMapper: (data, _) => data.xSeries,
          yValueMapper: (data, _) => data.ySeries,
          pointColorMapper: (data, _) => data.color,
          innerRadius: '${(widget.innerRadius * 100).toInt()}%',
          cornerStyle: widget.cornerStyle,
          explode: widget.explode,
          explodeIndex: widget.explodeIndex,
          dataLabelSettings: DataLabelSettings(
            isVisible: widget.showDataLabels,
            labelPosition: ChartDataLabelPosition.outside,
            textStyle: TextStyle(fontSize: widget.fontSize),
            connectorLineSettings: const ConnectorLineSettings(
              type: ConnectorType.curve,
            ),
          ),
          enableTooltip: widget.enableTooltip,
          animationDuration: widget.enableAnimation ? 1000 : 0,
          onPointTap: _handlePointTap,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _detachListener(widget.dataSource);
    _data.clear();
    super.dispose();
  }
}

// =============================================================================
// CYBER RADIAL BAR SERIES - Standalone Radial Bar Chart Widget (NEW)
// =============================================================================

class CyberRadialBarSeries extends StatefulWidget {
  final CyberDataTable? dataSource;
  final bool showDataLabels;
  final bool enableAnimation;
  final bool enableTooltip;
  final double innerRadius;
  final double fontSize;
  final bool showLegend;
  final LegendPosition legendPosition;
  final String? title;
  final Widget? centerWidget;
  final CornerStyle cornerStyle;
  final double gap;
  final double trackOpacity;
  final Color? trackColor;
  final double? maximumValue;
  final ValueChanged<DataChartSeries?>? onPointTap;
  final Color? backgroundColor;

  const CyberRadialBarSeries({
    super.key,
    this.dataSource,
    this.showDataLabels = true,
    this.enableAnimation = true,
    this.enableTooltip = true,
    this.innerRadius = 0.3,
    this.fontSize = 12,
    this.showLegend = true,
    this.legendPosition = LegendPosition.bottom,
    this.title,
    this.centerWidget,
    this.cornerStyle = CornerStyle.bothCurve,
    this.gap = 10,
    this.trackOpacity = 0.3,
    this.trackColor,
    this.maximumValue,
    this.onPointTap,
    this.backgroundColor,
  });

  @override
  State<CyberRadialBarSeries> createState() => _CyberRadialBarSeriesState();
}

class _CyberRadialBarSeriesState extends State<CyberRadialBarSeries> {
  List<DataChartSeries> _data = [];
  VoidCallback? _dataSourceListener;

  @override
  void initState() {
    super.initState();
    _loadData();
    _attachListener();
  }

  @override
  void didUpdateWidget(CyberRadialBarSeries oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataSource != widget.dataSource) {
      _detachListener(oldWidget.dataSource);
      _loadData();
      _attachListener();
    }
  }

  void _attachListener() {
    if (widget.dataSource != null) {
      _dataSourceListener = () {
        if (mounted) {
          _loadData();
          setState(() {});
        }
      };
      widget.dataSource!.addListener(_dataSourceListener!);
    }
  }

  void _detachListener(CyberDataTable? oldDataSource) {
    if (oldDataSource != null && _dataSourceListener != null) {
      oldDataSource.removeListener(_dataSourceListener!);
      _dataSourceListener = null;
    }
  }

  void _loadData() {
    _data.clear();
    if (widget.dataSource == null) return;

    for (var item in widget.dataSource!.rows) {
      _data.add(
        DataChartSeries(
          xSeries: item['xSeries'],
          ySeries: item['ySeries'],
          dataRow: item,
          color: item.hasField('color')
              ? (item['color']?.toString() ?? '#cccccc').parseColor()
              : const Color(0xFFCCCCCC),
        ),
      );
    }
  }

  void _handlePointTap(ChartPointDetails details) {
    if (widget.onPointTap != null && details.pointIndex != null) {
      final index = details.pointIndex!;
      if (index >= 0 && index < _data.length) {
        widget.onPointTap!(_data[index]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SfCircularChart(
      backgroundColor: widget.backgroundColor,
      title: widget.title != null
          ? ChartTitle(
              text: widget.title!,
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            )
          : ChartTitle(text: ''),
      legend: Legend(
        isVisible: widget.showLegend,
        position: widget.legendPosition,
        overflowMode: LegendItemOverflowMode.wrap,
      ),
      tooltipBehavior: TooltipBehavior(enable: widget.enableTooltip),
      annotations: widget.centerWidget != null
          ? <CircularChartAnnotation>[
              CircularChartAnnotation(widget: widget.centerWidget!),
            ]
          : null,
      series: <RadialBarSeries<DataChartSeries, dynamic>>[
        RadialBarSeries<DataChartSeries, dynamic>(
          dataSource: _data,
          xValueMapper: (data, _) => data.xSeries,
          yValueMapper: (data, _) => data.ySeries,
          pointColorMapper: (data, _) => data.color,
          innerRadius: '${(widget.innerRadius * 100).toInt()}%',
          cornerStyle: widget.cornerStyle,
          gap: '${widget.gap}%',
          trackOpacity: widget.trackOpacity,
          trackColor: widget.trackColor ?? Colors.grey.shade300,
          maximumValue: widget.maximumValue,
          dataLabelSettings: DataLabelSettings(
            isVisible: widget.showDataLabels,
            textStyle: TextStyle(fontSize: widget.fontSize),
          ),
          enableTooltip: widget.enableTooltip,
          animationDuration: widget.enableAnimation ? 1500 : 0,
          onPointTap: _handlePointTap,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _detachListener(widget.dataSource);
    _data.clear();
    super.dispose();
  }
}

// =============================================================================
// EXTENSION: Color helper
// =============================================================================
