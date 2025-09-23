import 'package:flutter/material.dart';
import '../entity/candle_entity.dart';
import '../k_chart_widget.dart' show MainState;
import 'base_chart_renderer.dart';
import '../entity/ma_entity.dart';
import '../entity/boll_entity.dart';
import '../entity/sar_entity.dart';
import '../entity/avl_entity.dart';

enum VerticalTextAlignment { left, right }

enum NowPriceLabelAlignment { followVertical, left, right }

enum PositionLabelAlignment { followVertical, left, right }

//For TrendLine
double? trendLineMax;
double? trendLineScale;
double? trendLineContentRec;

class MainRenderer extends BaseChartRenderer<CandleEntity> {
  late double mCandleWidth;
  late double mCandleLineWidth;
  List<MainState> stateLi;
  bool isLine;

  //绘制的内容区域
  late Rect _contentRect;
  double _contentPadding = 5.0;
  List<int> maDayList;
  final ChartStyle chartStyle;
  final ChartColors chartColors;
  final double mLineStrokeWidth = 1.0;
  double scaleX;
  late Paint mLinePaint;
  final VerticalTextAlignment verticalTextAlignment;
  final double priceScale;
  final List<IndicatorMA>? indicatorMA;
  final List<IndicatorEMA>? indicatorEMA;
  final IndicatorBOLL? indicatorBOLL;
  final IndicatorSAR? indicatorSAR;
  final IndicatorAVL? indicatorAVL;

  MainRenderer(
    Rect mainRect,
    double maxValue,
    double minValue,
    double topPadding,
    this.stateLi,
    this.isLine,
    int fixedLength,
    this.chartStyle,
    this.chartColors,
    this.scaleX,
    this.verticalTextAlignment,
    this.priceScale, {
    this.maDayList = const [5, 10, 20],
    this.indicatorMA,
    this.indicatorEMA,
    this.indicatorBOLL,
    this.indicatorSAR,
    this.indicatorAVL,
  }) : super(
            chartRect: mainRect,
            maxValue: maxValue,
            minValue: minValue,
            topPadding: topPadding,
            fixedLength: fixedLength,
            gridColor: chartColors.gridColor) {
    mCandleWidth = this.chartStyle.candleWidth;
    mCandleLineWidth = this.chartStyle.candleLineWidth;
    mLinePaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = mLineStrokeWidth
      ..color = this.chartColors.kLineColor;
    _contentRect = Rect.fromLTRB(
        chartRect.left,
        chartRect.top + _contentPadding,
        chartRect.right,
        chartRect.bottom - _contentPadding);
    // keep original window
    double origMax = maxValue;
    double origMin = minValue;
    if (origMax == origMin) {
      origMax *= 1.5;
      origMin /= 2;
    }

    // symmetric scaling about center of current window
    final double center = (origMax + origMin) / 2.0;
    final double range = (origMax - origMin);
    // Baseline behavior: at load the window exactly fits extremes (range).
    // Allow only zoom-out beyond baseline; when zooming back, stop at baseline.
    final double safeScale = priceScale <= 0 ? 1.0 : priceScale;
    double newRange = range * safeScale; // >1 => zoom-out, <1 => zoom-in
    if (newRange < range) newRange = range; // clamp minimum to baseline
    double newMax = center + newRange / 2.0;
    double newMin = center - newRange / 2.0;

    // apply adjusted window
    this.maxValue = newMax;
    this.minValue = newMin;
    scaleY = _contentRect.height / (this.maxValue - this.minValue);
  }
  @override
  void drawText(Canvas canvas, CandleEntity data, double x) {
    if (isLine == true) return;
    double curY = chartRect.top - topPadding;
    for (int i = 0; i < stateLi.length; ++i) {
      TextSpan? span;
      if (stateLi[i] == MainState.MA) {
        // Render MA labels in rows of 3 for consistent spacing
        final List<List<InlineSpan>> rows = _createMaLabelRows(data);
        for (final row in rows) {
          final TextPainter tp = TextPainter(
              text: TextSpan(children: row), textDirection: TextDirection.ltr);
          tp.layout();

          final Offset offset = Offset(x, curY);
          canvas.drawRect(
              Rect.fromLTRB(
                offset.dx - 2,
                offset.dy - 2,
                tp.width + offset.dx + 2,
                tp.height + offset.dy + 2,
              ),
              Paint()..color = this.chartColors.bgColor);
          tp.paint(canvas, offset);
          // step down by the painted row height plus a small gap
          curY += tp.height + 2;
        }
        // MA handled, go to next state
        continue;
      } else if (stateLi[i] == MainState.EMA) {
        // Render EMA labels in rows of 3
        final List<List<InlineSpan>> rows = _createEmaLabelRows(data);
        for (final row in rows) {
          final TextPainter tp = TextPainter(
              text: TextSpan(children: row), textDirection: TextDirection.ltr);
          tp.layout();

          final Offset offset = Offset(x, curY);
          canvas.drawRect(
              Rect.fromLTRB(
                offset.dx - 2,
                offset.dy - 2,
                tp.width + offset.dx + 2,
                tp.height + offset.dy + 2,
              ),
              Paint()..color = this.chartColors.bgColor);
          tp.paint(canvas, offset);
          curY += tp.height + 2;
        }
        continue;
      } else if (stateLi[i] == MainState.BOLL) {
        final bool showUp = indicatorBOLL?.isShowUp ?? true;
        final bool showMb = indicatorBOLL?.isShowMb ?? true;
        final bool showDn = indicatorBOLL?.isShowDn ?? true;
        final int period = indicatorBOLL?.period ?? 20;
        final int bandwidth = indicatorBOLL?.bandwidth ?? 2;
        final Color upColor =
            indicatorBOLL?.upColor ?? this.chartColors.ma10Color;
        final Color mbColor =
            indicatorBOLL?.mbColor ?? this.chartColors.ma5Color;
        final Color dnColor =
            indicatorBOLL?.dnColor ?? this.chartColors.ma30Color;

        final List<InlineSpan> parts = [];
        // Prefix: BOLL(period, bandwidth) colored with UP color
        parts.add(TextSpan(
            text: "BOLL(${period}, ${bandwidth}) ",
            style: getTextStyle(upColor)));
        if (showUp && data.up != 0) {
          parts.add(TextSpan(
              text: "UP: ${format(data.up)} ", style: getTextStyle(upColor)));
        }
        if (showMb && data.mb != 0) {
          parts.add(TextSpan(
              text: "MB: ${format(data.mb)} ", style: getTextStyle(mbColor)));
        }
        if (showDn && data.dn != 0) {
          parts.add(TextSpan(
              text: "DN: ${format(data.dn)} ", style: getTextStyle(dnColor)));
        }
        span = TextSpan(children: parts);
      } else if (stateLi[i] == MainState.SAR) {
        final Color sarColor = indicatorSAR?.color ?? this.chartColors.sarColor;
        final String startStr = indicatorSAR?.start.toString() ?? '';
        final String maxStr = indicatorSAR?.maximum.toString() ?? '';
        final String priceStr = format(data.sar);
        span = TextSpan(
          text: "SAR(${startStr}, ${maxStr}): ${priceStr}",
          style: getTextStyle(sarColor),
        );
      } else if (stateLi[i] == MainState.AVL) {
        final Color avlColor = indicatorAVL?.color ?? this.chartColors.avgColor;
        // 현재 봉 평균가 (O+H+L+C)/4
        final double avg =
            (data.open + data.high + data.low + data.close) / 4.0;
        span = TextSpan(
          text: "AVL ${format(avg)}",
          style: getTextStyle(avlColor),
        );
      }
      if (span == null) return;
      TextPainter tp =
          TextPainter(text: span, textDirection: TextDirection.ltr);
      tp.layout();

      Offset offset = Offset(x, curY);

      canvas.drawRect(
          Rect.fromLTRB(
            offset.dx - 2,
            offset.dy - 2,
            tp.width + offset.dx + 2,
            tp.height + offset.dy + 2,
          ),
          Paint()..color = this.chartColors.bgColor);

      tp.paint(canvas, offset);
      curY += tp.height + 2;
    }
  }

  List<List<InlineSpan>> _createMaLabelRows(CandleEntity data) {
    final List<List<InlineSpan>> rows = [];
    final int total = (data.maValueList?.length ?? 0);
    final int count = total > 10 ? 10 : total;
    const int perRow = 3;
    List<InlineSpan> current = [];
    int labelsInRow = 0;
    for (int i = 0; i < count; i++) {
      if (data.maValueList?[i] != 0) {
        final Color color = (indicatorMA != null && i < (indicatorMA!.length))
            ? indicatorMA![i].color
            : this.chartColors.getMAColor(i);
        final String periodStr =
            (indicatorMA != null && i < indicatorMA!.length)
                ? indicatorMA![i].value.toString()
                : (i < maDayList.length
                    ? maDayList[i].toString()
                    : (i + 1).toString());

        current.add(TextSpan(
            text: "MA(${periodStr}): ${format(data.maValueList![i])}",
            style: getTextStyle(color)));
        labelsInRow++;
        if (labelsInRow < perRow && i != count - 1) {
          current.add(const TextSpan(text: "    "));
        }
        if (labelsInRow == perRow || i == count - 1) {
          rows.add(current);
          current = [];
          labelsInRow = 0;
        }
      }
    }
    return rows;
  }

  List<List<InlineSpan>> _createEmaLabelRows(CandleEntity data) {
    final List<List<InlineSpan>> rows = [];
    final List<double>? list = data.emaValueList;
    if (list == null) return rows;
    final int total = list.length;
    final int count = total > 10 ? 10 : total;
    const int perRow = 3;
    List<InlineSpan> current = [];
    int labelsInRow = 0;
    for (int i = 0; i < count; i++) {
      final Color color = (indicatorEMA != null && i < (indicatorEMA!.length))
          ? indicatorEMA![i].color
          : this.chartColors.getMAColor(i);
      final String periodStr =
          (indicatorEMA != null && i < indicatorEMA!.length)
              ? indicatorEMA![i].value.toString()
              : (i + 1).toString();
      current.add(TextSpan(
          text: "EMA(${periodStr}): ${format(list[i])}",
          style: getTextStyle(color)));
      labelsInRow++;
      if (labelsInRow < perRow && i != count - 1) {
        current.add(const TextSpan(text: "    "));
      }
      if (labelsInRow == perRow || i == count - 1) {
        rows.add(current);
        current = [];
        labelsInRow = 0;
      }
    }
    return rows;
  }

  @override
  void drawChart(CandleEntity lastPoint, CandleEntity curPoint, double lastX,
      double curX, Size size, Canvas canvas) {
    if (isLine) {
      drawPolyline(lastPoint.close, curPoint.close, canvas, lastX, curX);
    } else {
      drawCandle(curPoint, canvas, curX);

      /// draw chart main state
      for (int i = 0; i < stateLi.length; ++i) {
        if (stateLi[i] == MainState.MA) {
          drawMaLine(lastPoint, curPoint, canvas, lastX, curX);
        } else if (stateLi[i] == MainState.EMA) {
          drawEmaLine(lastPoint, curPoint, canvas, lastX, curX);
        } else if (stateLi[i] == MainState.BOLL) {
          drawBollLine(lastPoint, curPoint, canvas, lastX, curX);
        } else if (stateLi[i] == MainState.SAR) {
          drawSAR(lastPoint, curPoint, canvas, lastX, curX);
        } else if (stateLi[i] == MainState.AVL) {
          drawAvlLine(lastPoint, curPoint, canvas, lastX, curX);
        }
      }
    }
  }

  Shader? mLineFillShader;
  Path? mLinePath, mLineFillPath;
  Paint mLineFillPaint = Paint()
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  //画折线图
  drawPolyline(double lastPrice, double curPrice, Canvas canvas, double lastX,
      double curX) {
//    drawLine(lastPrice + 100, curPrice + 100, canvas, lastX, curX, ChartColors.kLineColor);
    mLinePath ??= Path();

//    if (lastX == curX) {
//      mLinePath.moveTo(lastX, getY(lastPrice));
//    } else {
////      mLinePath.lineTo(curX, getY(curPrice));
//      mLinePath.cubicTo(
//          (lastX + curX) / 2, getY(lastPrice), (lastX + curX) / 2, getY(curPrice), curX, getY(curPrice));
//    }
    if (lastX == curX) lastX = 0; //起点位置填充
    mLinePath!.moveTo(lastX, getY(lastPrice));
    mLinePath!.cubicTo((lastX + curX) / 2, getY(lastPrice), (lastX + curX) / 2,
        getY(curPrice), curX, getY(curPrice));

    //画阴影
    mLineFillShader ??= LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      tileMode: TileMode.clamp,
      colors: [
        this.chartColors.lineFillColor,
        this.chartColors.lineFillInsideColor
      ],
    ).createShader(Rect.fromLTRB(
        chartRect.left, chartRect.top, chartRect.right, chartRect.bottom));
    mLineFillPaint..shader = mLineFillShader;

    mLineFillPath ??= Path();

    mLineFillPath!.moveTo(lastX, chartRect.height + chartRect.top);
    mLineFillPath!.lineTo(lastX, getY(lastPrice));
    mLineFillPath!.cubicTo((lastX + curX) / 2, getY(lastPrice),
        (lastX + curX) / 2, getY(curPrice), curX, getY(curPrice));
    mLineFillPath!.lineTo(curX, chartRect.height + chartRect.top);
    mLineFillPath!.close();

    canvas.drawPath(mLineFillPath!, mLineFillPaint);
    mLineFillPath!.reset();

    canvas.drawPath(mLinePath!,
        mLinePaint..strokeWidth = (mLineStrokeWidth / scaleX).clamp(0.1, 1.0));
    mLinePath!.reset();
  }

  void drawMaLine(CandleEntity lastPoint, CandleEntity curPoint, Canvas canvas,
      double lastX, double curX) {
    final int total = (curPoint.maValueList?.length ?? 0);
    final int count = total > 10 ? 10 : total;
    for (int i = 0; i < count; i++) {
      final double? lastV = lastPoint.maValueList?[i];
      final double? curV = curPoint.maValueList?[i];
      if (lastV == null || curV == null || lastV == 0) continue;
      final Color color = (indicatorMA != null && i < indicatorMA!.length)
          ? indicatorMA![i].color
          : this.chartColors.getMAColor(i);
      drawLine(lastV, curV, canvas, lastX, curX, color);
    }
  }

  void drawEmaLine(CandleEntity lastPoint, CandleEntity curPoint, Canvas canvas,
      double lastX, double curX) {
    final List<double>? lastList = lastPoint.emaValueList;
    final List<double>? curList = curPoint.emaValueList;
    if (curList == null || lastList == null) return;
    final int total = curList.length;
    final int count = total > 10 ? 10 : total;
    for (int i = 0; i < count; i++) {
      final double lastV = lastList[i];
      final double curV = curList[i];
      if (lastV == 0) continue;
      final Color color = (indicatorEMA != null && i < indicatorEMA!.length)
          ? indicatorEMA![i].color
          : this.chartColors.getMAColor(i);
      drawLine(lastV, curV, canvas, lastX, curX, color);
    }
  }

  void drawBollLine(CandleEntity lastPoint, CandleEntity curPoint,
      Canvas canvas, double lastX, double curX) {
    if (lastPoint.up != 0 && (indicatorBOLL?.isShowUp ?? true)) {
      drawLine(lastPoint.up, curPoint.up, canvas, lastX, curX,
          indicatorBOLL?.upColor ?? this.chartColors.ma10Color);
    }
    if (lastPoint.mb != 0 && (indicatorBOLL?.isShowMb ?? true)) {
      drawLine(lastPoint.mb, curPoint.mb, canvas, lastX, curX,
          indicatorBOLL?.mbColor ?? this.chartColors.ma5Color);
    }
    if (lastPoint.dn != 0 && (indicatorBOLL?.isShowDn ?? true)) {
      drawLine(lastPoint.dn, curPoint.dn, canvas, lastX, curX,
          indicatorBOLL?.dnColor ?? this.chartColors.ma30Color);
    }
  }

  void drawSAR(CandleEntity lastPoint, CandleEntity curPoint, Canvas canvas,
      double lastX, double curX) {
    final sar = curPoint.sar;
    if (sar == null) return;
    final Color color = indicatorSAR?.color ?? this.chartColors.sarColor;
    final Paint p = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..color = color;
    canvas.drawCircle(Offset(curX, getY(sar)), 2.0, p);
  }

  void drawAvlLine(CandleEntity lastPoint, CandleEntity curPoint, Canvas canvas,
      double lastX, double curX) {
    // average price per candle (OHLC 평균)
    final double lastAvg =
        (lastPoint.open + lastPoint.high + lastPoint.low + lastPoint.close) /
            4.0;
    final double curAvg =
        (curPoint.open + curPoint.high + curPoint.low + curPoint.close) / 4.0;
    final Color color = indicatorAVL?.color ?? this.chartColors.avgColor;
    drawLine(lastAvg, curAvg, canvas, lastX, curX, color);
  }

  void drawCandle(CandleEntity curPoint, Canvas canvas, double curX) {
    var high = getY(curPoint.high);
    var low = getY(curPoint.low);
    var open = getY(curPoint.open);
    var close = getY(curPoint.close);
    double r = mCandleWidth / 2;
    double lineR = mCandleLineWidth / 2;
    if (open >= close) {
      // 实体高度>= CandleLineWidth
      if (open - close < mCandleLineWidth) {
        open = close + mCandleLineWidth;
      }
      chartPaint.color = this.chartColors.upColor;
      canvas.drawRect(
          Rect.fromLTRB(curX - r, close, curX + r, open), chartPaint);
      canvas.drawRect(
          Rect.fromLTRB(curX - lineR, high, curX + lineR, low), chartPaint);
    } else if (close > open) {
      // 实体高度>= CandleLineWidth
      if (close - open < mCandleLineWidth) {
        open = close - mCandleLineWidth;
      }
      chartPaint.color = this.chartColors.dnColor;
      canvas.drawRect(
          Rect.fromLTRB(curX - r, open, curX + r, close), chartPaint);
      canvas.drawRect(
          Rect.fromLTRB(curX - lineR, high, curX + lineR, low), chartPaint);
    }
  }

  @override
  void drawVerticalText(canvas, textStyle, int gridRows) {
    double rowSpace = chartRect.height / gridRows;
    for (var i = 0; i <= gridRows; ++i) {
      double value = (gridRows - i) * rowSpace / scaleY + minValue;
      TextSpan span = TextSpan(text: "${format(value)}", style: textStyle);
      TextPainter tp =
          TextPainter(text: span, textDirection: TextDirection.ltr);
      tp.layout();

      double offsetX;
      switch (verticalTextAlignment) {
        case VerticalTextAlignment.left:
          offsetX = 0;
          break;
        case VerticalTextAlignment.right:
          offsetX = chartRect.width - tp.width;
          break;
      }

      if (i == 0) {
        tp.paint(canvas, Offset(offsetX, topPadding));
      } else {
        tp.paint(
            canvas, Offset(offsetX, rowSpace * i - tp.height + topPadding));
      }
    }
  }

  @override
  void drawGrid(Canvas canvas, int gridRows, int gridColumns) {
//    final int gridRows = 4, gridColumns = 4;
    double rowSpace = chartRect.height / gridRows;
    for (int i = 0; i <= gridRows; i++) {
      canvas.drawLine(Offset(0, rowSpace * i + topPadding),
          Offset(chartRect.width, rowSpace * i + topPadding), gridPaint);
    }
    double columnSpace = chartRect.width / gridColumns;

    for (int i = 0; i <= columnSpace; i++) {
      canvas.drawLine(Offset(columnSpace * i, 0),
          Offset(columnSpace * i, chartRect.bottom), gridPaint);
    }
  }

  @override
  double getY(double y) {
    //For TrendLine
    updateTrendLineData();
    return (maxValue - y) * scaleY + _contentRect.top;
  }

  void updateTrendLineData() {
    trendLineMax = maxValue;
    trendLineScale = scaleY;
    trendLineContentRec = _contentRect.top;
  }
}
