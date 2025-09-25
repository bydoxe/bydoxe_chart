import 'package:flutter/material.dart';
import '../entity/macd_entity.dart';
import '../k_chart_widget.dart' show SecondaryState;
import '../entity/rsi_entity.dart';
import '../entity/kdj_entity.dart';
import '../entity/obv_entity.dart';
import '../entity/stoch_rsi_entity.dart';
import '../entity/wr_entity.dart';
import 'base_chart_renderer.dart';

class SecondaryRenderer extends BaseChartRenderer<MACDEntity> {
  late double mMACDWidth;
  SecondaryState state;
  final ChartStyle chartStyle;
  final ChartColors chartColors;
  final MACDInputEntity? indicatorMACD;
  final List<RSIInputEntity>? indicatorRSI;
  final WRInputEntity? indicatorWR;
  final OBVInputEntity? indicatorOBV;
  final StochRSIInputEntity? indicatorStochRSI;
  final KDJInputEntity? indicatorKDJ;

  SecondaryRenderer(
      Rect mainRect,
      double maxValue,
      double minValue,
      double topPadding,
      this.state,
      int fixedLength,
      this.chartStyle,
      this.chartColors,
      {this.indicatorMACD,
      this.indicatorRSI,
      this.indicatorWR,
      this.indicatorOBV,
      this.indicatorStochRSI,
      this.indicatorKDJ})
      : super(
          chartRect: mainRect,
          maxValue: maxValue,
          minValue: minValue,
          topPadding: topPadding,
          fixedLength: fixedLength,
          gridColor: chartColors.gridColor,
        ) {
    // Match MACD histogram bar width to VOL bar width
    mMACDWidth = this.chartStyle.volWidth;
  }

  @override
  void drawChart(MACDEntity lastPoint, MACDEntity curPoint, double lastX,
      double curX, Size size, Canvas canvas) {
    switch (state) {
      case SecondaryState.MACD:
        drawMACD(curPoint, canvas, curX, lastPoint, lastX);
        break;
      case SecondaryState.KDJ:
        final bool showK = indicatorKDJ?.showK ?? true;
        final bool showD = indicatorKDJ?.showD ?? true;
        final bool showJ = indicatorKDJ?.showJ ?? true;
        final Color kColor = indicatorKDJ?.kColor ?? this.chartColors.kColor;
        final Color dColor = indicatorKDJ?.dColor ?? this.chartColors.dColor;
        final Color jColor = indicatorKDJ?.jColor ?? this.chartColors.jColor;
        if (showK) {
          _drawLineValue(lastPoint.k, curPoint.k, canvas, lastX, curX, kColor);
        }
        if (showD) {
          _drawLineValue(lastPoint.d, curPoint.d, canvas, lastX, curX, dColor);
        }
        if (showJ) {
          _drawLineValue(lastPoint.j, curPoint.j, canvas, lastX, curX, jColor);
        }
        break;
      case SecondaryState.RSI:
        _drawRSILines(lastPoint, curPoint, canvas, lastX, curX);
        break;
      case SecondaryState.WR:
        final Color wrColor = indicatorWR?.color ?? this.chartColors.rsiColor;
        drawLine(lastPoint.r, curPoint.r, canvas, lastX, curX, wrColor);
        break;
      case SecondaryState.OBV:
        if (curPoint.obv != null) {
          _drawLineValue(lastPoint.obv, curPoint.obv, canvas, lastX, curX,
              indicatorOBV?.obvColor ?? this.chartColors.volColor);
        }
        if (indicatorOBV?.obvMAShow == true && curPoint.obvMA != null) {
          _drawLineValue(lastPoint.obvMA, curPoint.obvMA, canvas, lastX, curX,
              indicatorOBV?.obvMAColor ?? this.chartColors.ma10Color);
        }
        if (indicatorOBV?.obvEMAShow == true && curPoint.obvEMA != null) {
          _drawLineValue(lastPoint.obvEMA, curPoint.obvEMA, canvas, lastX, curX,
              indicatorOBV?.obvEMAColor ?? this.chartColors.macdColor);
        }
        break;
      case SecondaryState.STOCHRSI:
        if (indicatorStochRSI?.stochRSIShow == true &&
            curPoint.stochK != null) {
          _drawLineValue(lastPoint.stochK, curPoint.stochK, canvas, lastX, curX,
              indicatorStochRSI!.stochRSIKColor);
        }
        if (indicatorStochRSI?.stochRSIDShow == true &&
            curPoint.stochD != null) {
          _drawLineValue(lastPoint.stochD, curPoint.stochD, canvas, lastX, curX,
              indicatorStochRSI!.stochRSIDColor);
        }
        break;
    }
    // OBV overlay removed. OBV only renders in its own state.
  }

  void _drawLineValue(double? lastV, double? curV, Canvas canvas, double lastX,
      double curX, Color color) {
    if (lastV == null || curV == null) return;
    drawLine(lastV, curV, canvas, lastX, curX, color);
  }

  void _drawRSILines(MACDEntity lastPoint, MACDEntity curPoint, Canvas canvas,
      double lastX, double curX) {
    // Prefer multi-RSI list if available; otherwise fall back to single rsi
    final List<double>? lastList = lastPoint.rsiValueList;
    final List<double>? curList = curPoint.rsiValueList;
    if (lastList == null || curList == null) {
      final Color c = (indicatorRSI != null && indicatorRSI!.isNotEmpty)
          ? indicatorRSI!.first.color
          : this.chartColors.rsiColor;
      drawLine(lastPoint.rsi, curPoint.rsi, canvas, lastX, curX, c);
      return;
    }
    final int total = curList.length;
    final int count = total > 3 ? 3 : total;
    for (int i = 0; i < count; i++) {
      final double lastV = lastList[i];
      final double curV = curList[i];
      if (lastV == 0 && curV == 0) continue;
      // choose color from indicatorRSI if provided, else fallback palette
      final Color color = (indicatorRSI != null && i < indicatorRSI!.length)
          ? indicatorRSI![i].color
          : ((i == 0)
              ? this.chartColors.rsiColor
              : (i == 1)
                  ? this.chartColors.kColor
                  : this.chartColors.dColor);
      drawLine(lastV, curV, canvas, lastX, curX, color);
    }
  }

  void drawMACD(MACDEntity curPoint, Canvas canvas, double curX,
      MACDEntity lastPoint, double lastX) {
    final double cur = curPoint.macd ?? 0;
    final double prev = lastPoint.macd ?? 0;
    final double zeroY = getY(0);
    final double barCenterX = curX;
    final double half = mMACDWidth / 2;

    // Decide histogram style/color based on sign and growth
    bool isLong = cur >= 0;
    bool isGrow = cur >= prev;
    Color barColor;
    GrowFallType barType;
    if (indicatorMACD != null) {
      if (isLong) {
        if (isGrow) {
          barColor = indicatorMACD!.macdLongGrowColor;
          barType = indicatorMACD!.macdLongGrowType;
        } else {
          barColor = indicatorMACD!.macdLongFallColor;
          barType = indicatorMACD!.macdLongFallType;
        }
      } else {
        if (isGrow) {
          barColor = indicatorMACD!.macdShortGrowColor;
          barType = indicatorMACD!.macdShortGrowType;
        } else {
          barColor = indicatorMACD!.macdShortFallColor;
          barType = indicatorMACD!.macdShortFallType;
        }
      }
    } else {
      barColor = isLong ? this.chartColors.upColor : this.chartColors.dnColor;
      barType = GrowFallType.solid;
    }

    final double valueY = getY(cur);
    final Rect barRect = isLong
        ? Rect.fromLTRB(barCenterX - half, valueY, barCenterX + half, zeroY)
        : Rect.fromLTRB(barCenterX - half, zeroY, barCenterX + half, valueY);

    final Paint p = Paint()
      ..isAntiAlias = true
      ..color = barColor
      ..style = (barType == GrowFallType.solid)
          ? PaintingStyle.fill
          : PaintingStyle.stroke
      ..strokeWidth = 1.0;
    if (indicatorMACD == null || indicatorMACD!.macdShow) {
      canvas.drawRect(barRect, p);
    }

    // DIF/DEA lines (toggle)
    if (indicatorMACD == null || indicatorMACD!.difShow) {
      if (lastPoint.dif != 0) {
        drawLine(lastPoint.dif, curPoint.dif, canvas, lastX, curX,
            indicatorMACD?.difColor ?? this.chartColors.difColor);
      }
    }
    if (indicatorMACD == null || indicatorMACD!.deaShow) {
      if (lastPoint.dea != 0) {
        drawLine(lastPoint.dea, curPoint.dea, canvas, lastX, curX,
            indicatorMACD?.deaColor ?? this.chartColors.deaColor);
      }
    }
  }

  @override
  void drawText(Canvas canvas, MACDEntity data, double x) {
    List<TextSpan>? children;
    switch (state) {
      case SecondaryState.MACD:
        final Color difColor =
            indicatorMACD?.difColor ?? this.chartColors.difColor;
        final Color deaColor =
            indicatorMACD?.deaColor ?? this.chartColors.deaColor;
        children = [
          if ((indicatorMACD == null || indicatorMACD!.difShow) &&
              data.dif != 0)
            TextSpan(
                text: "DIF: ${format(data.dif)}    ",
                style: getTextStyle(difColor)),
          if ((indicatorMACD == null || indicatorMACD!.deaShow) &&
              data.dea != 0)
            TextSpan(
                text: "DEA: ${format(data.dea)}    ",
                style: getTextStyle(deaColor)),
          if ((indicatorMACD == null || indicatorMACD!.macdShow) &&
              data.macd != 0)
            TextSpan(
                text: "MACD: ${format(data.macd)}    ",
                style: getTextStyle(difColor)),
        ];
        break;
      case SecondaryState.KDJ:
        final bool showK = indicatorKDJ?.showK ?? true;
        final bool showD = indicatorKDJ?.showD ?? true;
        final bool showJ = indicatorKDJ?.showJ ?? true;
        final Color kColor = indicatorKDJ?.kColor ?? this.chartColors.kColor;
        final Color dColor = indicatorKDJ?.dColor ?? this.chartColors.dColor;
        final Color jColor = indicatorKDJ?.jColor ?? this.chartColors.jColor;
        children = [
          if (showK && data.k != null)
            TextSpan(
                text: "K:${format(data.k)}    ", style: getTextStyle(kColor)),
          if (showD && data.d != null)
            TextSpan(
                text: "D:${format(data.d)}    ", style: getTextStyle(dColor)),
          if (showJ && data.j != null)
            TextSpan(
                text: "J:${format(data.j)}    ", style: getTextStyle(jColor)),
        ];
        break;
      case SecondaryState.RSI:
        children = [];
        final List<double>? list = data.rsiValueList;
        if (indicatorRSI != null && indicatorRSI!.isNotEmpty && list != null) {
          final int count = indicatorRSI!.length > 3 ? 3 : indicatorRSI!.length;
          for (int i = 0; i < count; i++) {
            if (i >= list.length) break;
            final double v = list[i];
            if (v == 0) continue;
            final RSIInputEntity cfg = indicatorRSI![i];
            children.add(TextSpan(
                text: "RSI(${cfg.value}): ${format(v)}    ",
                style: getTextStyle(cfg.color)));
          }
          if (children.isEmpty) {
            children.add(TextSpan(
                text: "RSI",
                style: getTextStyle(this.chartColors.defaultTextColor)));
          }
        } else {
          if (data.rsi != 0 && data.rsi != null) {
            children = [
              TextSpan(
                  text: "RSI: ${format(data.rsi)}    ",
                  style: getTextStyle(this.chartColors.rsiColor)),
            ];
          } else {
            children = [
              TextSpan(
                  text: "RSI",
                  style: getTextStyle(this.chartColors.defaultTextColor)),
            ];
          }
        }
        break;
      case SecondaryState.WR:
        final int period = indicatorWR?.value ?? 14;
        final Color wrColor = indicatorWR?.color ?? this.chartColors.rsiColor;
        children = [
          TextSpan(
              text: "Wm %R(${period}): ${format(data.r)}    ",
              style: getTextStyle(wrColor)),
        ];
        break;
      case SecondaryState.STOCHRSI:
        children = [];
        if (indicatorStochRSI?.stochRSIShow == true && data.stochK != null) {
          children.add(TextSpan(
              text: "STOCHRSI: ${format(data.stochK)}    ",
              style: getTextStyle(indicatorStochRSI!.stochRSIKColor)));
        }
        if (indicatorStochRSI?.stochRSIDShow == true && data.stochD != null) {
          children.add(TextSpan(
              text: "MASTOCHRSI: ${format(data.stochD)}    ",
              style: getTextStyle(indicatorStochRSI!.stochRSIDColor)));
        }
        break;
      case SecondaryState.OBV:
        // OBV labels are appended after the switch based on indicatorOBV
        children = [];
        break;
    }
    // OBV labels (only in OBV state)
    if (state == SecondaryState.OBV &&
        indicatorOBV != null &&
        data.obv != null) {
      final List<InlineSpan> obvLabels = [];
      obvLabels.add(TextSpan(
          text: "  OBV: ${format(data.obv)}    ",
          style: getTextStyle(indicatorOBV!.obvColor)));
      if (indicatorOBV!.obvMAShow && data.obvMA != null) {
        obvLabels.add(TextSpan(
            text: "MA(${indicatorOBV!.obvMAValue}): ${format(data.obvMA)}    ",
            style: getTextStyle(indicatorOBV!.obvMAColor)));
      }
      if (indicatorOBV!.obvEMAShow && data.obvEMA != null) {
        obvLabels.add(TextSpan(
            text:
                "EMA(${indicatorOBV!.obvEMAValue}): ${format(data.obvEMA)}    ",
            style: getTextStyle(indicatorOBV!.obvEMAColor)));
      }
      final List<TextSpan> base = children;
      children = [...base, ...obvLabels.cast<TextSpan>()];
    }
    TextPainter tp = TextPainter(
        text: TextSpan(children: children), textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, Offset(x, chartRect.top - topPadding));
  }

  @override
  void drawVerticalText(canvas, textStyle, int gridRows) {
    if (state == SecondaryState.RSI) {
      // Fix RSI scale to [0, 100]
      final TextPainter maxTp = TextPainter(
          text: TextSpan(text: "100", style: textStyle),
          textDirection: TextDirection.ltr);
      maxTp.layout();
      final TextPainter minTp = TextPainter(
          text: TextSpan(text: "0", style: textStyle),
          textDirection: TextDirection.ltr);
      minTp.layout();
      maxTp.paint(canvas,
          Offset(chartRect.width - maxTp.width, chartRect.top - topPadding));
      minTp.paint(
          canvas,
          Offset(
              chartRect.width - minTp.width, chartRect.bottom - minTp.height));
      return;
    }
    TextPainter maxTp = TextPainter(
        text: TextSpan(text: "${format(maxValue)}", style: textStyle),
        textDirection: TextDirection.ltr);
    maxTp.layout();
    TextPainter minTp = TextPainter(
        text: TextSpan(text: "${format(minValue)}", style: textStyle),
        textDirection: TextDirection.ltr);
    minTp.layout();

    maxTp.paint(canvas,
        Offset(chartRect.width - maxTp.width, chartRect.top - topPadding));
    minTp.paint(canvas,
        Offset(chartRect.width - minTp.width, chartRect.bottom - minTp.height));
  }

  @override
  void drawGrid(Canvas canvas, int gridRows, int gridColumns) {
    // canvas.drawLine(Offset(0, chartRect.top), Offset(chartRect.width, chartRect.top), gridPaint); //hidden line
    canvas.drawLine(Offset(0, chartRect.bottom),
        Offset(chartRect.width, chartRect.bottom), gridPaint);
    double columnSpace = chartRect.width / gridColumns;
    for (int i = 0; i <= columnSpace; i++) {
      //mSecondaryRect垂直线
      canvas.drawLine(Offset(columnSpace * i, chartRect.top - topPadding),
          Offset(columnSpace * i, chartRect.bottom), gridPaint);
    }
  }
}
