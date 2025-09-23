import 'package:flutter/material.dart';
import 'package:bydoxe_chart/k_chart_plus.dart';
import '../entity/vol_ma_entity.dart';

class VolRenderer extends BaseChartRenderer<VolumeEntity> {
  late double mVolWidth;
  final ChartStyle chartStyle;
  final ChartColors chartColors;
  final List<IndicatorVolMA>? indicatorVolMA; // up to 2

  VolRenderer(Rect mainRect, double maxValue, double minValue,
      double topPadding, int fixedLength, this.chartStyle, this.chartColors,
      {this.indicatorVolMA})
      : super(
          chartRect: mainRect,
          maxValue: maxValue,
          minValue: minValue,
          topPadding: topPadding,
          fixedLength: fixedLength,
          gridColor: chartColors.gridColor,
        ) {
    mVolWidth = this.chartStyle.volWidth;
  }

  @override
  void drawChart(VolumeEntity lastPoint, VolumeEntity curPoint, double lastX,
      double curX, Size size, Canvas canvas) {
    double r = mVolWidth / 2;
    double top = getVolY(curPoint.vol);
    double bottom = chartRect.bottom;
    if (curPoint.vol != 0) {
      canvas.drawRect(
          Rect.fromLTRB(curX - r, top, curX + r, bottom),
          chartPaint
            ..color = curPoint.close > curPoint.open
                ? this.chartColors.upColor
                : this.chartColors.dnColor);
    }

    // draw custom up to 2 MAs using volMaValueList and indicator colors
    if (indicatorVolMA != null && indicatorVolMA!.isNotEmpty) {
      final configs = indicatorVolMA!.take(2).toList();
      final lastList = lastPoint.volMaValueList;
      final curList = curPoint.volMaValueList;
      if (lastList != null && curList != null) {
        for (int idx = 0; idx < configs.length; idx++) {
          if (idx < lastList.length && idx < curList.length) {
            final double lastVal = lastList[idx];
            final double curVal = curList[idx];
            if (lastVal != 0 || curVal != 0) {
              drawLine(
                  lastVal, curVal, canvas, lastX, curX, configs[idx].color);
            }
          }
        }
      }
    }
  }

  double getVolY(double value) =>
      (maxValue - value) * (chartRect.height / maxValue) + chartRect.top;

  @override
  void drawText(Canvas canvas, VolumeEntity data, double x) {
    final List<InlineSpan> parts = [];
    parts.add(TextSpan(
        text: "VOL:${NumberUtil.format(data.vol)}    ",
        style: getTextStyle(this.chartColors.nowPriceUpColor)));

    // custom up to 2 MAs labels based on volMaValueList
    if (indicatorVolMA != null && indicatorVolMA!.isNotEmpty) {
      final configs = indicatorVolMA!.take(2).toList();
      final list = data.volMaValueList;
      for (int idx = 0; idx < configs.length; idx++) {
        final int p = configs[idx].value;
        String valueStr = '';
        if (list != null && idx < list.length && list[idx] != 0) {
          valueStr = NumberUtil.format(list[idx]);
        }
        parts.add(TextSpan(
            text: "MA(${p}): ${valueStr}    ",
            style: getTextStyle(configs[idx].color)));
      }
    }

    TextPainter tp = TextPainter(
        text: TextSpan(children: parts), textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, Offset(x, chartRect.top - topPadding));
  }

  @override
  void drawVerticalText(canvas, textStyle, int gridRows) {
    TextSpan span =
        TextSpan(text: "${NumberUtil.format(maxValue)}", style: textStyle);
    TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(
        canvas, Offset(chartRect.width - tp.width, chartRect.top - topPadding));
  }

  @override
  void drawGrid(Canvas canvas, int gridRows, int gridColumns) {
    canvas.drawLine(Offset(0, chartRect.bottom),
        Offset(chartRect.width, chartRect.bottom), gridPaint);
    double columnSpace = chartRect.width / gridColumns;
    for (int i = 0; i <= columnSpace; i++) {
      //vol垂直线
      canvas.drawLine(Offset(columnSpace * i, chartRect.top - topPadding),
          Offset(columnSpace * i, chartRect.bottom), gridPaint);
    }
  }
}
