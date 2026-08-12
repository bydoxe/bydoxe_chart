import 'dart:async' show StreamSink;
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:bydoxe_chart/utils/number_util.dart';
import 'package:bydoxe_chart/utils/price_label_util.dart';
import '../entity/info_window_entity.dart';
import '../entity/drawing_entity.dart';
import '../entity/k_line_entity.dart';
import '../interaction/drawing_hit_test.dart';
import '../utils/date_format_util.dart';
import 'base_chart_painter.dart';
import 'chart_coordinate_mapper.dart';
import 'drawing_renderer.dart';
import '../entity/position_line_entity.dart';
import 'base_chart_renderer.dart';
import 'base_dimension.dart';
import 'main_renderer.dart';
import 'secondary_renderer.dart';
import 'vol_renderer.dart';
import '../entity/ma_entity.dart';
import '../entity/boll_entity.dart';
import '../entity/sar_entity.dart';
import '../utils/data_util.dart';
import '../entity/avl_entity.dart';
import '../entity/vol_ma_entity.dart';
import '../entity/wr_entity.dart';
import '../entity/rsi_entity.dart';
import '../entity/macd_entity.dart';
import '../entity/stoch_rsi_entity.dart';
import '../entity/obv_entity.dart';
import '../entity/kdj_entity.dart';
import 'main_axis_range.dart';

class TrendLine {
  final Offset p1;
  final Offset p2;
  final double maxHeight;
  final double scale;

  TrendLine(this.p1, this.p2, this.maxHeight, this.scale);
}

class _DrawingAxisValue {
  final double value;
  final double position;

  const _DrawingAxisValue(this.value, this.position);
}

double? trendLineX;

double getTrendLineX() {
  return trendLineX ?? 0;
}

class ChartPainter extends BaseChartPainter {
  final List<TrendLine> lines; //For TrendLine
  final bool isTrendLine; //For TrendLine
  bool isrecordingCord = false; //For TrendLine
  final double selectY; //For TrendLine
  static get maxScrollX => BaseChartPainter.maxScrollX;
  late BaseChartRenderer mMainRenderer;
  BaseChartRenderer? mVolRenderer;
  Set<BaseChartRenderer> mSecondaryRendererList = {};
  StreamSink<InfoWindowEntity?> sink;
  Color? upColor, dnColor;
  Color? ma5Color, ma10Color, ma30Color;
  Color? volColor;
  Color? macdColor, difColor, deaColor, jColor;
  int fixedLength;
  final double? priceLabelTickSize;
  List<int> maDayList;
  final ChartColors chartColors;
  late Paint selectPointPaint, selectorBorderPaint, nowPricePaint;
  final ChartStyle chartStyle;
  final bool hideGrid;
  final bool showNowPrice;
  final ui.Image? candlePaneLogo;
  final MainAxisRange? mainAxisRangeOverride;
  final VerticalTextAlignment verticalTextAlignment;
  final NowPriceLabelAlignment nowPriceLabelAlignment;
  final BaseDimension baseDimension;
  final List<PositionLineEntity> positionLines;
  final PositionLabelAlignment positionLabelAlignment;
  final List<PositionMarkerEntity> markers;
  final List<ChartDrawingEntity> drawings;
  final int? selectedDrawingId;
  final bool showDrawings;
  int? activePositionId;
  final List<IndicatorMA>? indicatorMA;
  final List<IndicatorEMA>? indicatorEMA;
  final List<RSIInputEntity>? indicatorRSI;
  final WRInputEntity? indicatorWR;
  final OBVInputEntity? indicatorOBV;
  final StochRSIInputEntity? indicatorStochRSI;
  final IndicatorBOLL? indicatorBOLL;
  final IndicatorSAR? indicatorSAR;
  final IndicatorAVL? indicatorAVL;
  final List<IndicatorVolMA>? indicatorVolMA;
  final MACDInputEntity? indicatorMACD;
  final KDJInputEntity? indicatorKDJ;
  Map<int, Rect> _hitLeftChip = {};
  Map<int, Rect> _hitBtnClose = {};
  Map<int, Rect> _hitBtnTp = {};
  Map<int, Rect> _hitBtnSl = {};
  Rect? _nowPriceChipRect;
  bool _nowPricePinned = false;

  Rect? get nowPriceChipRect => _nowPriceChipRect;
  bool get nowPricePinned => _nowPricePinned;

  // getters to expose hit-test rects
  Map<int, Rect> get hitLeftChip => _hitLeftChip;
  Map<int, Rect> get hitBtnClose => _hitBtnClose;
  Map<int, Rect> get hitBtnTp => _hitBtnTp;
  Map<int, Rect> get hitBtnSl => _hitBtnSl;

  ChartPainter(
    this.chartStyle,
    this.chartColors, {
    required this.lines, //For TrendLine
    required this.isTrendLine, //For TrendLine
    required this.selectY, //For TrendLine
    required this.sink,
    required datas,
    required scaleX,
    required scrollX,
    required isLongPass,
    required selectX,
    required xFrontPadding,
    required this.baseDimension,
    isOnTap,
    isTapShowInfoDialog,
    required this.verticalTextAlignment,
    required this.nowPriceLabelAlignment,
    required this.positionLines,
    required this.positionLabelAlignment,
    required this.markers,
    this.drawings = const <ChartDrawingEntity>[],
    this.selectedDrawingId,
    this.showDrawings = true,
    this.activePositionId,
    this.indicatorMA,
    this.indicatorEMA,
    this.indicatorRSI,
    this.indicatorWR,
    this.indicatorOBV,
    this.indicatorStochRSI,
    this.indicatorBOLL,
    this.indicatorSAR,
    this.indicatorAVL,
    this.indicatorVolMA,
    this.indicatorMACD,
    this.indicatorKDJ,
    mainStateLi,
    volHidden,
    secondaryStateLi,
    bool isLine = false,
    this.hideGrid = false,
    this.showNowPrice = true,
    this.candlePaneLogo,
    this.fixedLength = 2,
    this.priceLabelTickSize,
    this.maDayList = const [5, 10, 20],
    this.mainAxisRangeOverride,
  }) : super(chartStyle,
            datas: datas,
            scaleX: scaleX,
            scrollX: scrollX,
            isLongPress: isLongPass,
            baseDimension: baseDimension,
            isOnTap: isOnTap,
            isTapShowInfoDialog: isTapShowInfoDialog,
            selectX: selectX,
            mainStateLi: mainStateLi,
            volHidden: volHidden,
            secondaryStateLi: secondaryStateLi,
            xFrontPadding: xFrontPadding,
            isLine: isLine,
            mainAxisRangeOverride: mainAxisRangeOverride) {
    selectPointPaint = Paint()
      ..isAntiAlias = true
      ..strokeWidth = 0.5
      ..color = this.chartColors.selectFillColor;
    selectorBorderPaint = Paint()
      ..isAntiAlias = true
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke
      ..color = this.chartColors.selectBorderColor;
    nowPricePaint = Paint()
      ..strokeWidth = this.chartStyle.nowPriceLineWidth
      ..isAntiAlias = true;
  }

  @override
  void initChartRenderer() {
    if (datas != null && datas!.isNotEmpty) {
      // Recalculate SAR with indicator parameters if provided
      if (indicatorSAR != null) {
        double startP = indicatorSAR!.start;
        double maxP = indicatorSAR!.maximum;
        // If values look like AF (<=1.0), convert to percent units expected by calcSARWithParams
        if (startP <= 1.0 && maxP <= 1.0) {
          startP *= 100.0;
          maxP *= 100.0;
        }
        DataUtil.calcSARWithParams(
          datas!,
          startPercent: startP,
          stepPercent: startP,
          maxPercent: maxP,
        );
      }
      var t = datas![0];
      final detectedFixedLength =
          NumberUtil.getMaxDecimalLength(t.open, t.close, t.high, t.low);
      fixedLength = math.max(fixedLength, detectedFixedLength);
    }
    mMainRenderer = MainRenderer(
      mMainRect,
      mMainMaxValue,
      mMainMinValue,
      mTopPadding,
      mainStateLi.toList(),
      isLine,
      fixedLength,
      this.chartStyle,
      this.chartColors,
      this.scaleX,
      verticalTextAlignment,
      priceLabelTickSize: priceLabelTickSize,
      maDayList: maDayList,
      indicatorMA: indicatorMA,
      indicatorEMA: indicatorEMA,
      indicatorBOLL: indicatorBOLL,
      indicatorSAR: indicatorSAR,
      indicatorAVL: indicatorAVL,
    );
    if (mVolRect != null) {
      mVolRenderer = VolRenderer(mVolRect!, mVolMaxValue, mVolMinValue,
          mChildPadding, fixedLength, this.chartStyle, this.chartColors,
          indicatorVolMA: indicatorVolMA);
    }
    mSecondaryRendererList.clear();
    for (int i = 0; i < mSecondaryRectList.length; ++i) {
      mSecondaryRendererList.add(SecondaryRenderer(
        mSecondaryRectList[i].mRect,
        mSecondaryRectList[i].mMaxValue,
        mSecondaryRectList[i].mMinValue,
        mChildPadding,
        secondaryStateLi.elementAt(i),
        fixedLength,
        chartStyle,
        chartColors,
        indicatorMACD: indicatorMACD,
        indicatorRSI: indicatorRSI,
        indicatorWR: indicatorWR,
        indicatorStochRSI: indicatorStochRSI,
        indicatorOBV: indicatorOBV,
        indicatorKDJ: indicatorKDJ,
      ));
    }
  }

  @override
  void drawBg(Canvas canvas, Size size) {
    Paint mBgPaint = Paint()..color = chartColors.bgColor;
    Rect mainRect =
        Rect.fromLTRB(0, 0, mMainRect.width, mMainRect.height + mTopPadding);
    canvas.drawRect(mainRect, mBgPaint);

    if (mVolRect != null) {
      Rect volRect = Rect.fromLTRB(
          0, mVolRect!.top - mChildPadding, mVolRect!.width, mVolRect!.bottom);
      canvas.drawRect(volRect, mBgPaint);
    }

    for (int i = 0; i < mSecondaryRectList.length; ++i) {
      Rect? mSecondaryRect = mSecondaryRectList[i].mRect;
      Rect secondaryRect = Rect.fromLTRB(0, mSecondaryRect.top - mChildPadding,
          mSecondaryRect.width, mSecondaryRect.bottom);
      canvas.drawRect(secondaryRect, mBgPaint);
    }
    Rect dateRect =
        Rect.fromLTRB(0, size.height - mBottomPadding, size.width, size.height);
    canvas.drawRect(dateRect, mBgPaint);

    _drawCandlePaneWatermark(canvas);
  }

  void _drawCandlePaneWatermark(Canvas canvas) {
    final image = candlePaneLogo;
    if (image == null || mMainRect.width <= 0 || mMainRect.height <= 0) return;

    final double targetWidth = mMainRect.width * 0.50;
    if (targetWidth < 80) return;

    final bool isLightBackground = chartColors.bgColor.computeLuminance() > 0.5;
    final double targetHeight = targetWidth * image.height / image.width;
    final Rect sourceRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final Rect targetRect = Rect.fromLTWH(
      mMainRect.left + (mMainRect.width - targetWidth) / 2,
      mMainRect.top + (mMainRect.height - targetHeight) / 2,
      targetWidth,
      targetHeight,
    );
    final Paint paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high
      ..colorFilter = ColorFilter.mode(
        (isLightBackground ? Colors.black : Colors.white)
            .withValues(alpha: isLightBackground ? 0.26 : 0.14),
        BlendMode.srcIn,
      );

    canvas.save();
    canvas.clipRect(mMainRect);
    canvas.drawImageRect(image, sourceRect, targetRect, paint);
    canvas.restore();
  }

  @override
  void drawGrid(canvas) {
    if (!hideGrid) {
      mMainRenderer.drawGrid(canvas, mGridRows, mGridColumns);
      mVolRenderer?.drawGrid(canvas, mGridRows, mGridColumns);
      mSecondaryRendererList.forEach((element) {
        element.drawGrid(canvas, mGridRows, mGridColumns);
      });
    }
  }

  @override
  void drawChart(Canvas canvas, Size size) {
    _drawTransformedInRect(canvas, mMainRect, (canvas) {
      for (int i = mStartIndex; datas != null && i <= mStopIndex; i++) {
        KLineEntity? curPoint = datas?[i];
        if (curPoint == null) continue;
        KLineEntity lastPoint = i == 0 ? curPoint : datas![i - 1];
        double curX = getX(i);
        double lastX = i == 0 ? curX : getX(i - 1);

        mMainRenderer.drawChart(lastPoint, curPoint, lastX, curX, size, canvas);
      }
    });
    _drawDrawings(canvas);
    _drawMarkers(canvas);

    final volRenderer = mVolRenderer;
    final volRect = mVolRect;
    if (volRenderer != null && volRect != null) {
      _drawTransformedInRect(canvas, volRect, (canvas) {
        for (int i = mStartIndex; datas != null && i <= mStopIndex; i++) {
          KLineEntity? curPoint = datas?[i];
          if (curPoint == null) continue;
          KLineEntity lastPoint = i == 0 ? curPoint : datas![i - 1];
          double curX = getX(i);
          double lastX = i == 0 ? curX : getX(i - 1);

          volRenderer.drawChart(lastPoint, curPoint, lastX, curX, size, canvas);
        }
      });
    }

    for (final renderer in mSecondaryRendererList) {
      _drawTransformedInRect(canvas, renderer.chartRect, (canvas) {
        for (int i = mStartIndex; datas != null && i <= mStopIndex; i++) {
          KLineEntity? curPoint = datas?[i];
          if (curPoint == null) continue;
          KLineEntity lastPoint = i == 0 ? curPoint : datas![i - 1];
          double curX = getX(i);
          double lastX = i == 0 ? curX : getX(i - 1);

          renderer.drawChart(lastPoint, curPoint, lastX, curX, size, canvas);
        }
      });
    }

    canvas.save();
    canvas.translate(mTranslateX * scaleX, 0.0);
    canvas.scale(scaleX, 1.0);
    if ((isLongPress == true || (isTapShowInfoDialog && isOnTap)) &&
        isTrendLine == false) {
      drawCrossLine(canvas, size);
    }
    if (isTrendLine == true) drawTrendLines(canvas, size);
    canvas.restore();
  }

  void _drawMarkers(Canvas canvas) {
    if (markers.isEmpty) return;
    canvas.save();
    canvas.clipRect(mMainRect);
    for (int i = mStartIndex; datas != null && i <= mStopIndex; i++) {
      final KLineEntity? curPoint = datas?[i];
      if (curPoint == null) continue;
      final double curX = translateXtoX(getX(i));
      _drawMarkerForCandle(canvas, curX, i, curPoint);
    }
    canvas.restore();
  }

  void _drawDrawings(Canvas canvas) {
    if (!showDrawings || drawings.isEmpty || datas == null || datas!.isEmpty) {
      return;
    }

    DrawingRenderer(
      mapper: _drawingCoordinateMapper(),
      drawings: drawings,
      selectedDrawingId: selectedDrawingId,
    ).draw(canvas);
  }

  DrawingHitTestResult? hitTestDrawing(Offset point) {
    if (!showDrawings || drawings.isEmpty || datas == null || datas!.isEmpty) {
      return null;
    }
    return DrawingHitTester(
      mapper: _drawingCoordinateMapper(),
      drawings: drawings,
      selectedDrawingId: selectedDrawingId,
    ).hitTest(point);
  }

  Rect? drawingBounds(ChartDrawingEntity drawing) {
    if (!showDrawings ||
        drawing.hidden ||
        drawing.type == ChartDrawingTool.none ||
        datas == null ||
        datas!.isEmpty) {
      return null;
    }

    final mapper = _drawingCoordinateMapper();
    switch (drawing.type) {
      case ChartDrawingTool.trendLine:
      case ChartDrawingTool.extendedLine:
      case ChartDrawingTool.ray:
        return _boundsFromAnchors(mapper, drawing.anchors.take(2));
      case ChartDrawingTool.horizontalLine:
        if (drawing.anchors.isEmpty) return null;
        final y = mapper.priceToY(drawing.anchors.first.price);
        return Rect.fromLTRB(
          mapper.mainPaneClipRect.left,
          y,
          mapper.mainPaneClipRect.right,
          y,
        );
      case ChartDrawingTool.verticalLine:
        if (drawing.anchors.isEmpty) return null;
        final x = mapper.anchorToX(drawing.anchors.first);
        if (x == null) return null;
        return Rect.fromLTRB(
          x,
          mapper.mainPaneClipRect.top,
          x,
          mapper.mainPaneClipRect.bottom,
        );
      case ChartDrawingTool.parallelChannel:
        final points = drawing.anchors
            .take(3)
            .map(mapper.anchorToOffset)
            .whereType<Offset>()
            .toList(growable: true);
        if (points.length >= 3) {
          points.add(points[2] + (points[1] - points[0]));
        }
        return _boundsFromOffsets(points);
      case ChartDrawingTool.fibonacciRetracement:
        return _boundsFromAnchors(mapper, drawing.anchors.take(2));
      case ChartDrawingTool.rectangle:
        return _boundsFromAnchors(mapper, drawing.anchors.take(2));
      case ChartDrawingTool.none:
        return null;
    }
  }

  ChartDrawingAnchor? drawingAnchorAt(
    Offset point, {
    ChartDrawingTool tool = ChartDrawingTool.none,
    bool magnetEnabled = false,
  }) {
    if (datas == null || datas!.isEmpty || !mMainRect.contains(point)) {
      return null;
    }
    final mapper = _drawingCoordinateMapper();
    final time = mapper.timeAtX(point.dx);
    if (time == null) {
      return null;
    }
    final anchor = ChartDrawingAnchor(
      time: time,
      price: mapper.yToPrice(point.dy),
      dataIndex: mapper.nearestDataIndexForX(point.dx),
    );
    if (!magnetEnabled || tool == ChartDrawingTool.none) {
      return anchor;
    }
    return _snapDrawingAnchor(point, anchor, tool, mapper);
  }

  ChartDrawingAnchor _snapDrawingAnchor(
    Offset point,
    ChartDrawingAnchor anchor,
    ChartDrawingTool tool,
    ChartCoordinateMapper mapper,
  ) {
    final nearestIndex = mapper.nearestDataIndexForX(point.dx);
    if (nearestIndex == null) {
      return anchor;
    }

    final entity = datas![nearestIndex];
    final time = entity.time;
    if (time == null) {
      return anchor;
    }

    final highY = mapper.priceToY(entity.high);
    final lowY = mapper.priceToY(entity.low);
    final price = (highY - point.dy).abs() <= (lowY - point.dy).abs()
        ? entity.high
        : entity.low;

    return anchor.copyWith(
      time: time,
      price: price,
      dataIndex: nearestIndex,
    );
  }

  ChartCoordinateMapper _drawingCoordinateMapper() {
    return ChartCoordinateMapper(
      datas: datas!,
      mainRect: mMainRect,
      scaleX: scaleX,
      scrollX: scrollX,
      pointWidth: mPointWidth,
      xFrontPadding: xFrontPadding,
      mainMaxValue: mMainMaxValue,
      mainMinValue: mMainMinValue,
    );
  }

  Rect? _boundsFromAnchors(
    ChartCoordinateMapper mapper,
    Iterable<ChartDrawingAnchor> anchors,
  ) {
    return _boundsFromOffsets(
      anchors.map(mapper.anchorToOffset).whereType<Offset>(),
    );
  }

  Rect? _boundsFromOffsets(Iterable<Offset> points) {
    final list = points.toList(growable: false);
    if (list.isEmpty) {
      return null;
    }

    var left = list.first.dx;
    var right = list.first.dx;
    var top = list.first.dy;
    var bottom = list.first.dy;
    for (final point in list.skip(1)) {
      left = math.min(left, point.dx);
      right = math.max(right, point.dx);
      top = math.min(top, point.dy);
      bottom = math.max(bottom, point.dy);
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  void _drawTransformedInRect(
      Canvas canvas, Rect clipRect, void Function(Canvas canvas) draw) {
    canvas.save();
    canvas.clipRect(clipRect);
    canvas.translate(mTranslateX * scaleX, 0.0);
    canvas.scale(scaleX, 1.0);
    draw(canvas);
    canvas.restore();
  }

  void _drawMarkerForCandle(Canvas canvas, double x, int i, KLineEntity k) {
    if (markers.isEmpty) return;
    final int t0 = k.time ?? 0;
    final int t1 =
        (i + 1 < datas!.length) ? (datas![i + 1].time ?? (t0 + 1)) : (1 << 62);

    // 동일 분봉 내에서 타입별 최신 1개씩 선택: BUY, SELL 각각 최신
    PositionMarkerEntity? chosenBuy;
    PositionMarkerEntity? chosenSell;
    for (final m in markers) {
      if (m.time >= t0 && m.time < t1) {
        if (m.type == MarkerType.buy) {
          if (chosenBuy == null || m.time >= chosenBuy.time) {
            chosenBuy = m;
          }
        } else {
          if (chosenSell == null || m.time >= chosenSell.time) {
            chosenSell = m;
          }
        }
      }
    }
    if (chosenBuy == null && chosenSell == null) return;

    void drawOne(PositionMarkerEntity chosen) {
      final Color color = chosen.color ??
          ((chosen.type == MarkerType.buy)
              ? chartColors.upColor
              : chartColors.dnColor);
      final String label = (chosen.type == MarkerType.buy) ? 'B' : 'S';
      // bubble with tail pointing to candle (smaller)
      final TextPainter tp = getMarkerTextPainter(label);
      const double padH = 3.0;
      const double padV = 1.5;
      const double radius = 2.0;
      const double tailH = 4.0;
      final double bubbleW = tp.width + 2 * padH;
      final double bubbleH = tp.height + 2 * padV;
      final double bx = x - bubbleW / 2;
      double by;
      if (chosen.type == MarkerType.buy) {
        final double lowY = getMainY(k.low);
        by = lowY + 2 + tailH;
        final Path tail = Path()
          ..moveTo(x, lowY + 2)
          ..lineTo(x - 3, by - 2)
          ..lineTo(x + 3, by - 2)
          ..close();
        canvas.drawPath(
            tail,
            Paint()
              ..color = color
              ..isAntiAlias = true);
      } else {
        final double highY = getMainY(k.high);
        by = highY - bubbleH - 2 - tailH;
        final Path tail = Path()
          ..moveTo(x, highY - 2)
          ..lineTo(x - 3, by + bubbleH + 2)
          ..lineTo(x + 3, by + bubbleH + 2)
          ..close();
        canvas.drawPath(
            tail,
            Paint()
              ..color = color
              ..isAntiAlias = true);
      }
      final RRect bubble = RRect.fromRectAndRadius(
          Rect.fromLTWH(bx, by, bubbleW, bubbleH), Radius.circular(radius));
      canvas.drawRRect(
          bubble,
          Paint()
            ..color = color
            ..isAntiAlias = true);
      tp.paint(canvas, Offset(bx + padH, by + padV));
    }

    // BUY, SELL 둘 다 있으면 모두 표기. 타입별 최신 1개만 표시
    if (chosenBuy != null) drawOne(chosenBuy);
    if (chosenSell != null) drawOne(chosenSell);
  }

  @override
  void drawVerticalText(canvas) {
    var textStyle = getTextStyle(this.chartColors.defaultTextColor);
    if (!hideGrid) {
      mMainRenderer.drawVerticalText(canvas, textStyle, mGridRows);
    }
    mVolRenderer?.drawVerticalText(canvas, textStyle, mGridRows);
    mSecondaryRendererList.forEach((element) {
      element.drawVerticalText(canvas, textStyle, mGridRows);
    });
  }

  @override
  void drawDate(Canvas canvas, Size size) {
    if (datas == null) return;

    double columnSpace = size.width / mGridColumns;
    double startX = getX(mStartIndex) - mPointWidth / 2;
    double stopX = getX(mStopIndex) + mPointWidth / 2;
    double x = 0.0;
    double y = 0.0;
    for (var i = 0; i <= mGridColumns; ++i) {
      double translateX = xToTranslateX(columnSpace * i);

      if (translateX >= startX && translateX <= stopX) {
        int index = indexOfTranslateX(translateX);

        if (datas?[index] == null) continue;
        TextPainter tp = getTextPainter(getDate(datas![index].time), null);
        y = size.height - (mBottomPadding - tp.height) / 2 - tp.height;
        x = columnSpace * i - tp.width / 2;
        // Prevent date text out of canvas
        if (x < 0) x = 0;
        if (x > size.width - tp.width) x = size.width - tp.width;
        tp.paint(canvas, Offset(x, y));
      }
    }

//    double translateX = xToTranslateX(0);
//    if (translateX >= startX && translateX <= stopX) {
//      TextPainter tp = getTextPainter(getDate(datas[mStartIndex].id));
//      tp.paint(canvas, Offset(0, y));
//    }
//    translateX = xToTranslateX(size.width);
//    if (translateX >= startX && translateX <= stopX) {
//      TextPainter tp = getTextPainter(getDate(datas[mStopIndex].id));
//      tp.paint(canvas, Offset(size.width - tp.width, y));
//    }
  }

  /// draw the cross line. when user focus
  @override
  void drawCrossLineText(Canvas canvas, Size size) {
    var index = calculateSelectedX(selectX);
    KLineEntity point = getItem(index);

    TextPainter tp = getTextPainter(point.close, chartColors.crossTextColor);
    double textHeight = tp.height;
    double textWidth = tp.width;

    double w1 = 5;
    double w2 = 3;
    double r = textHeight / 2 + w2;
    double y = getMainY(point.close);
    double x;
    bool isLeft = false;
    if (translateXtoX(getX(index)) < mWidth / 2) {
      isLeft = false;
      x = 1;
      Path path = new Path();
      path.moveTo(x, y - r);
      path.lineTo(x, y + r);
      path.lineTo(textWidth + 2 * w1, y + r);
      path.lineTo(textWidth + 2 * w1 + w2, y);
      path.lineTo(textWidth + 2 * w1, y - r);
      path.close();
      canvas.drawPath(path, selectPointPaint);
      canvas.drawPath(path, selectorBorderPaint);
      tp.paint(canvas, Offset(x + w1, y - textHeight / 2));
    } else {
      isLeft = true;
      x = mWidth - textWidth - 1 - 2 * w1 - w2;
      Path path = new Path();
      path.moveTo(x, y);
      path.lineTo(x + w2, y + r);
      path.lineTo(mWidth - 2, y + r);
      path.lineTo(mWidth - 2, y - r);
      path.lineTo(x + w2, y - r);
      path.close();
      canvas.drawPath(path, selectPointPaint);
      canvas.drawPath(path, selectorBorderPaint);
      tp.paint(canvas, Offset(x + w1 + w2, y - textHeight / 2));
    }

    TextPainter dateTp =
        getTextPainter(getDate(point.time), chartColors.crossTextColor);
    textWidth = dateTp.width;
    r = textHeight / 2;
    x = translateXtoX(getX(index));
    y = size.height - mBottomPadding;

    if (x < textWidth + 2 * w1) {
      x = 1 + textWidth / 2 + w1;
    } else if (mWidth - x < textWidth + 2 * w1) {
      x = mWidth - 1 - textWidth / 2 - w1;
    }
    double baseLine = textHeight / 2;
    canvas.drawRect(
        Rect.fromLTRB(x - textWidth / 2 - w1, y, x + textWidth / 2 + w1,
            y + baseLine + r),
        selectPointPaint);
    canvas.drawRect(
        Rect.fromLTRB(x - textWidth / 2 - w1, y, x + textWidth / 2 + w1,
            y + baseLine + r),
        selectorBorderPaint);

    dateTp.paint(canvas, Offset(x - textWidth / 2, y));
    //Long press to display the details of this data
    sink.add(InfoWindowEntity(point, isLeft: isLeft));
  }

  @override
  void drawText(Canvas canvas, KLineEntity data, double x) {
    //Long press to display the data in the press
    if (isLongPress || (isTapShowInfoDialog && isOnTap)) {
      var index = calculateSelectedX(selectX);
      data = getItem(index);
    }
    //Release to display the last data
    mMainRenderer.drawText(canvas, data, x);
    mVolRenderer?.drawText(canvas, data, x);
    mSecondaryRendererList.forEach((element) {
      element.drawText(canvas, data, x);
    });
  }

  @override
  void drawMaxAndMin(Canvas canvas) {
    if (isLine == true) return;
    //plot maxima and minima
    double x = translateXtoX(getX(mMainMinIndex));
    double y = getMainY(mMainLowMinValue);
    if (x < mWidth / 2) {
      //draw right
      TextPainter tp = getTextPainter(
          "── " +
              formatPriceLabel(
                mMainLowMinValue,
                fixedLength: fixedLength,
                tickSize: priceLabelTickSize,
              ),
          chartColors.minColor);
      tp.paint(canvas, Offset(x, y - tp.height / 2));
    } else {
      TextPainter tp = getTextPainter(
          formatPriceLabel(
                mMainLowMinValue,
                fixedLength: fixedLength,
                tickSize: priceLabelTickSize,
              ) +
              " ──",
          chartColors.minColor);
      tp.paint(canvas, Offset(x - tp.width, y - tp.height / 2));
    }
    x = translateXtoX(getX(mMainMaxIndex));
    y = getMainY(mMainHighMaxValue);
    if (x < mWidth / 2) {
      //draw right
      TextPainter tp = getTextPainter(
          "── " +
              formatPriceLabel(
                mMainHighMaxValue,
                fixedLength: fixedLength,
                tickSize: priceLabelTickSize,
              ),
          chartColors.maxColor);
      tp.paint(canvas, Offset(x, y - tp.height / 2));
    } else {
      TextPainter tp = getTextPainter(
          formatPriceLabel(
                mMainHighMaxValue,
                fixedLength: fixedLength,
                tickSize: priceLabelTickSize,
              ) +
              " ──",
          chartColors.maxColor);
      tp.paint(canvas, Offset(x - tp.width, y - tp.height / 2));
    }
  }

  @override
  void drawNowPrice(Canvas canvas) {
    if (!this.showNowPrice) {
      return;
    }

    if (datas == null) {
      return;
    }

    double value = datas!.last.close;
    double y = getMainY(value);

    //view display area boundary value drawing
    if (y > getMainY(mMainLowMinValue)) {
      y = getMainY(mMainLowMinValue);
    }

    if (y < getMainY(mMainHighMaxValue)) {
      y = getMainY(mMainHighMaxValue);
    }

    // Use a unified color regardless of up/down
    final Color nowColor = this.chartColors.nowPriceUpColor;

    // paddings unified with position right chip (reduced)
    const double padH = 5.0;
    const double padV = 2.0;
    final double radius = 4.0;

    // compute label text painter (slightly smaller font)
    TextPainter tp = getChipTextPainter(
      formatPriceLabel(
        value,
        fixedLength: fixedLength,
        tickSize: priceLabelTickSize,
      ),
      nowColor,
    );

    // label horizontal position by alignment (chip size aware)
    final double chipWidth = tp.width + 2 * padH;
    final double chipHeight = tp.height + 2 * padV;
    double labelLeft;
    switch (nowPriceLabelAlignment) {
      case NowPriceLabelAlignment.followVertical:
        switch (verticalTextAlignment) {
          case VerticalTextAlignment.left:
            labelLeft = mWidth - chipWidth;
            break;
          case VerticalTextAlignment.right:
            labelLeft = 0;
            break;
        }
        break;
      case NowPriceLabelAlignment.left:
        labelLeft = 0;
        break;
      case NowPriceLabelAlignment.right:
        labelLeft = mWidth - chipWidth;
        break;
    }

    // draw dashed guide from last candle price x to chip edge only (default)
    // but if lastX is off-screen to the left, pin label at 70% width and draw both sides
    final int lastIndex = datas!.length - 1;
    final double lastX = translateXtoX(getX(lastIndex));

    bool offLeft = lastX < 0 || lastX > mWidth;
    if (offLeft) {
      // place label centered at 70% of width
      final double targetCenter = mWidth * 0.70;
      labelLeft = (targetCenter - chipWidth / 2).clamp(0.0, mWidth - chipWidth);
    }

    final double top = y - chipHeight / 2;
    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(labelLeft, top, chipWidth, chipHeight),
      Radius.circular(radius),
    );

    // fill with selectFillColor and draw border with nowColor
    final Paint bgPaint = Paint()
      ..color = this.chartColors.selectFillColor
      ..isAntiAlias = true;
    final Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = nowColor
      ..isAntiAlias = true;

    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, borderPaint);
    tp.paint(canvas, Offset(labelLeft + padH, top + padV));

    // draw arrow icon when pinned (offLeft)
    _nowPricePinned = offLeft;
    if (offLeft) {
      final double arrowW = 8;
      final double arrowH = chipHeight * 0.5;
      final double ax = labelLeft + chipWidth + 4;
      final double ay = y - arrowH / 2;
      final Path pth = Path()
        ..moveTo(ax, ay)
        ..lineTo(ax, ay + arrowH)
        ..lineTo(ax + arrowW, ay + arrowH / 2)
        ..close();
      final Paint arrowPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = nowColor
        ..isAntiAlias = true;
      canvas.drawPath(pth, arrowPaint);
      // expand hit rect to include arrow
      _nowPriceChipRect =
          Rect.fromLTWH(labelLeft, top, chipWidth + 4 + arrowW, chipHeight);
    } else {
      _nowPriceChipRect = Rect.fromLTWH(labelLeft, top, chipWidth, chipHeight);
    }

    // dashed parameters (denser)
    final Paint linePaint = Paint()
      ..color = nowColor
      ..strokeWidth = this.chartStyle.nowPriceLineWidth
      ..isAntiAlias = true;
    final double seg = this.chartStyle.nowPriceLineLength * 0.5;
    final double gap = this.chartStyle.nowPriceLineSpan * 0.5;

    if (offLeft) {
      // draw left side from 0 -> labelLeft
      double start = 0;
      final double stop = labelLeft;
      while (start < stop) {
        final double next = (start + seg).clamp(start, stop);
        canvas.drawLine(Offset(start, y), Offset(next, y), linePaint);
        start = next + gap;
      }
      // draw right side from labelRight -> mWidth
      double startR = labelLeft + chipWidth;
      final double stopR = mWidth;
      while (startR < stopR) {
        final double next = (startR + seg).clamp(startR, stopR);
        canvas.drawLine(Offset(startR, y), Offset(next, y), linePaint);
        startR = next + gap;
      }
    } else {
      // default: from lastX to chip edge
      double endX;
      if (labelLeft == 0) {
        endX = labelLeft + chipWidth; // to right edge when left-aligned
      } else {
        endX = labelLeft; // to left edge when right-aligned
      }

      final double fromX = lastX.clamp(0, mWidth);
      final double toX = endX.clamp(0, mWidth);

      double start = fromX < toX ? fromX : toX;
      final double stop = fromX < toX ? toX : fromX;
      while (start < stop) {
        final double next = (start + seg).clamp(start, stop);
        canvas.drawLine(Offset(start, y), Offset(next, y), linePaint);
        start = next + gap;
      }
    }
  }

  void drawPositionLines(Canvas canvas, Size size) {
    if (positionLines.isEmpty) return;
    _hitLeftChip.clear();
    _hitBtnClose.clear();
    _hitBtnTp.clear();
    _hitBtnSl.clear();
    for (final p in positionLines) {
      // screen-space Y coordinate for position price
      final double y = getMainY(p.price);
      // If position price is outside current main chart Y-range, skip rendering (overflow hidden)
      if (y < mMainRect.top || y > mMainRect.bottom) {
        continue;
      }
      final double clampedY =
          y.clamp(mMainRect.top, mMainRect.bottom).toDouble();

      final Color posColor = p.color ??
          ((p.isLong == null)
              ? chartColors.avgColor
              : (p.isLong! ? chartColors.upColor : chartColors.dnColor));

      // 1) dashed horizontal guide across the screen
      final double seg = chartStyle.nowPriceLineLength * 0.5;
      final double gap = chartStyle.nowPriceLineSpan * 0.5;
      final double space = seg + gap;
      double startX = 0;
      final Paint linePaint = Paint()
        ..color = posColor
        ..strokeWidth = p.lineWidth
        ..isAntiAlias = true;
      if (activePositionId == p.id) {
        // solid line when active
        canvas.drawLine(Offset(0, clampedY), Offset(size.width, clampedY),
            linePaint..strokeWidth = p.lineWidth);
      } else {
        while (startX < size.width) {
          canvas.drawLine(Offset(startX, clampedY),
              Offset(startX + seg, clampedY), linePaint);
          startX += space;
        }
      }

      // common metrics (reduced)
      const double padH = 5.0;
      const double padV = 2.0;
      final double radius = 4.0;

      // 2) right-side price chip (bg=chart bg, colored border & text)
      final String priceText = formatPriceLabel(
        p.price,
        fixedLength: fixedLength,
        tickSize: priceLabelTickSize,
      );
      final TextPainter priceTP = getChipTextPainter(priceText, posColor);
      final double priceChipHeight = priceTP.height + 2 * padV;
      double priceTop = clampedY - priceChipHeight / 2;
      // keep price chip fully inside main chart rect
      priceTop = priceTop
          .clamp(mMainRect.top, mMainRect.bottom - priceChipHeight)
          .toDouble();
      final double priceWidth = priceTP.width + 2 * padH;
      final double priceLeft = size.width - priceWidth; // right-aligned
      final RRect priceRRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(priceLeft, priceTop, priceWidth, priceChipHeight),
          Radius.circular(radius));
      final Paint priceBorder = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = posColor
        ..isAntiAlias = true;
      // fill with chart background, then draw border
      canvas.drawRRect(
          priceRRect,
          Paint()
            ..color = chartColors.bgColor
            ..isAntiAlias = true);
      canvas.drawRRect(priceRRect, priceBorder);
      priceTP.paint(canvas, Offset(priceLeft + padH, priceTop + padV));

      // 3) left-side split chip: [ filled side | outlined label ]
      final double cur = datas!.last.close;
      final String side =
          (p.isLong == null) ? '' : (p.isLong! ? 'LONG' : 'SHORT');
      final String roeStr = NumberUtil.calculateUnrealizedRoe(
        formatPriceLabel(
          p.price,
          fixedLength: fixedLength,
          tickSize: priceLabelTickSize,
        ),
        formatPriceLabel(
          cur,
          fixedLength: fixedLength,
          tickSize: priceLabelTickSize,
        ),
        p.leverage,
        side,
      );
      final String leftText = side.isEmpty ? '' : ('$side $roeStr%');
      final String rightText = p.label ?? '';

      final TextPainter leftTP = getChipTextPainter(leftText, Colors.white);
      final TextPainter rightTP = getChipTextPainter(rightText, posColor);
      final double chipTextHeight =
          (leftTP.height > rightTP.height ? leftTP.height : rightTP.height);
      final double chipHeight = chipTextHeight + 2 * padV;
      double chipTop = clampedY - chipHeight / 2;
      // keep left chip fully inside main chart rect
      chipTop = chipTop
          .clamp(mMainRect.top, mMainRect.bottom - chipHeight)
          .toDouble();

      final double leftPartW = (leftText.isEmpty ? 0 : leftTP.width + 2 * padH);
      final double rightPartW =
          (rightText.isEmpty ? 0 : rightTP.width + 2 * padH);
      final double chipW = leftPartW + rightPartW;
      if (chipW > 0) {
        final double chipLeft = 0; // left-aligned at screen edge
        final Rect leftRect =
            Rect.fromLTWH(chipLeft, chipTop, leftPartW, chipHeight);
        final Rect rightRect = Rect.fromLTWH(
            chipLeft + leftPartW, chipTop, rightPartW, chipHeight);
        final RRect chipRRect = RRect.fromRectAndRadius(
            Rect.fromLTWH(chipLeft, chipTop, chipW, chipHeight),
            Radius.circular(radius));

        // draw outer border
        final Paint chipBorder = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = posColor
          ..isAntiAlias = true;
        canvas.drawRRect(chipRRect, chipBorder);

        // fill left part with posColor
        if (leftPartW > 0) {
          canvas.drawRRect(
              RRect.fromRectAndRadius(leftRect, Radius.circular(radius)),
              Paint()
                ..color = posColor
                ..isAntiAlias = true);
          leftTP.paint(
              canvas, Offset(leftRect.left + padH, leftRect.top + padV));
          _hitLeftChip[p.id] = leftRect;
        }

        // right part background = chart bg color for contrast
        if (rightPartW > 0) {
          canvas.drawRRect(
              RRect.fromRectAndRadius(rightRect, Radius.circular(radius)),
              Paint()
                ..color = chartColors.bgColor
                ..isAntiAlias = true);
          rightTP.paint(
              canvas, Offset(rightRect.left + padH, rightRect.top + padV));
        }

        // if active, draw action buttons next to right part
        if (activePositionId == p.id) {
          double btnLeft = chipLeft + chipW + 6;
          final Size btnSize = Size(28, chipHeight);
          Rect btnRectClose =
              Rect.fromLTWH(btnLeft, chipTop, btnSize.width, btnSize.height);
          Rect btnRectTp = Rect.fromLTWH(
              btnRectClose.right + 4, chipTop, btnSize.width, btnSize.height);
          Rect btnRectSl = Rect.fromLTWH(
              btnRectTp.right + 4, chipTop, btnSize.width, btnSize.height);

          final Paint btnBorder = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = posColor
            ..isAntiAlias = true;
          final Paint btnBg = Paint()
            ..color = chartColors.bgColor
            ..isAntiAlias = true;

          // Close button (×)
          canvas.drawRRect(
              RRect.fromRectAndRadius(btnRectClose, Radius.circular(radius)),
              btnBg);
          canvas.drawRRect(
              RRect.fromRectAndRadius(btnRectClose, Radius.circular(radius)),
              btnBorder);
          getChipTextPainter('×', posColor).paint(
              canvas,
              Offset(
                  btnRectClose.left +
                      (btnSize.width -
                              getChipTextPainter('×', posColor).width) /
                          2,
                  chipTop + padV));

          // TP button
          canvas.drawRRect(
              RRect.fromRectAndRadius(btnRectTp, Radius.circular(radius)),
              btnBg);
          canvas.drawRRect(
              RRect.fromRectAndRadius(btnRectTp, Radius.circular(radius)),
              btnBorder);
          getChipTextPainter('TP', posColor).paint(
              canvas,
              Offset(
                  btnRectTp.left +
                      (btnSize.width -
                              getChipTextPainter('TP', posColor).width) /
                          2,
                  chipTop + padV));

          // SL button
          canvas.drawRRect(
              RRect.fromRectAndRadius(btnRectSl, Radius.circular(radius)),
              btnBg);
          canvas.drawRRect(
              RRect.fromRectAndRadius(btnRectSl, Radius.circular(radius)),
              btnBorder);
          getChipTextPainter('SL', posColor).paint(
              canvas,
              Offset(
                  btnRectSl.left +
                      (btnSize.width -
                              getChipTextPainter('SL', posColor).width) /
                          2,
                  chipTop + padV));

          _hitBtnClose[p.id] = btnRectClose;
          _hitBtnTp[p.id] = btnRectTp;
          _hitBtnSl[p.id] = btnRectSl;
        }
      }
    }
  }

  @override
  void drawOverlays(Canvas canvas, Size size) {
    drawPositionLines(canvas, size);
    _drawSelectedDrawingAxisRange(canvas, size);
  }

  void _drawSelectedDrawingAxisRange(Canvas canvas, Size size) {
    if (!showDrawings ||
        selectedDrawingId == null ||
        drawings.isEmpty ||
        datas == null ||
        datas!.isEmpty) {
      return;
    }

    ChartDrawingEntity? selectedDrawing;
    for (final drawing in drawings) {
      if (drawing.id == selectedDrawingId) {
        selectedDrawing = drawing;
        break;
      }
    }
    if (selectedDrawing == null ||
        selectedDrawing.hidden ||
        selectedDrawing.type == ChartDrawingTool.none ||
        selectedDrawing.anchors.isEmpty) {
      return;
    }

    final priceAnchors = _drawingPriceAxisAnchors(selectedDrawing);
    final timeAnchors = _drawingTimeAxisAnchors(selectedDrawing);
    if (priceAnchors.isEmpty && timeAnchors.isEmpty) {
      return;
    }

    final mapper = _drawingCoordinateMapper();
    final color = selectedDrawing.style.color;
    _drawDrawingPriceAxisRange(canvas, priceAnchors, color, mapper);
    _drawDrawingTimeAxisRange(canvas, size, timeAnchors, color, mapper);
  }

  List<ChartDrawingAnchor> _drawingPriceAxisAnchors(
    ChartDrawingEntity drawing,
  ) {
    if (drawing.type == ChartDrawingTool.fibonacciRetracement &&
        drawing.anchors.length >= 2) {
      final start = drawing.anchors[0];
      final end = drawing.anchors[1];
      return chartDrawingFibonacciLevels
          .map(
            (level) => start.copyWith(
              price: start.price + (end.price - start.price) * level,
            ),
          )
          .toList(growable: false);
    }
    return _drawingTimeAxisAnchors(drawing);
  }

  List<ChartDrawingAnchor> _drawingTimeAxisAnchors(ChartDrawingEntity drawing) {
    switch (drawing.type) {
      case ChartDrawingTool.horizontalLine:
      case ChartDrawingTool.verticalLine:
        return drawing.anchors.take(1).toList(growable: false);
      case ChartDrawingTool.trendLine:
      case ChartDrawingTool.extendedLine:
      case ChartDrawingTool.ray:
      case ChartDrawingTool.rectangle:
      case ChartDrawingTool.fibonacciRetracement:
        return drawing.anchors.take(2).toList(growable: false);
      case ChartDrawingTool.parallelChannel:
        return drawing.anchors.take(3).toList(growable: false);
      case ChartDrawingTool.none:
        return const <ChartDrawingAnchor>[];
    }
  }

  void _drawDrawingPriceAxisRange(
    Canvas canvas,
    List<ChartDrawingAnchor> anchors,
    Color color,
    ChartCoordinateMapper mapper,
  ) {
    final values = <_DrawingAxisValue>[];
    for (final anchor in anchors) {
      final y = mapper.priceToY(anchor.price);
      if (!y.isFinite || y < mMainRect.top || y > mMainRect.bottom) {
        continue;
      }
      values.add(_DrawingAxisValue(anchor.price, y));
    }
    if (values.isEmpty) {
      return;
    }

    values.sort((a, b) => a.position.compareTo(b.position));
    final sideWidth = 34.0;
    final sideLeft = verticalTextAlignment == VerticalTextAlignment.right
        ? mWidth - sideWidth
        : 0.0;
    if (values.length >= 2) {
      final rangeTop = values.first.position;
      final rangeBottom = values.last.position;
      canvas.drawRect(
        Rect.fromLTRB(sideLeft, rangeTop, sideLeft + sideWidth, rangeBottom),
        Paint()
          ..isAntiAlias = true
          ..style = PaintingStyle.fill
          ..color = color.withValues(alpha: 0.18),
      );
    }

    for (final value in values) {
      _drawDrawingPriceAxisChip(canvas, value.value, value.position, color);
    }
  }

  void _drawDrawingPriceAxisChip(
    Canvas canvas,
    double price,
    double y,
    Color color,
  ) {
    const padH = 5.0;
    const padV = 2.0;
    const radius = 3.0;
    final label = formatPriceLabel(
      price,
      fixedLength: fixedLength,
      tickSize: priceLabelTickSize,
    );
    final tp = getChipTextPainter(label, Colors.white);
    final chipWidth = tp.width + padH * 2;
    final chipHeight = tp.height + padV * 2;
    final left = verticalTextAlignment == VerticalTextAlignment.right
        ? mWidth - chipWidth
        : 0.0;
    final top = (y - chipHeight / 2)
        .clamp(mMainRect.top, mMainRect.bottom - chipHeight)
        .toDouble();
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, chipWidth, chipHeight),
      const Radius.circular(radius),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.fill
        ..color = color,
    );
    tp.paint(canvas, Offset(left + padH, top + padV));
  }

  void _drawDrawingTimeAxisRange(
    Canvas canvas,
    Size size,
    List<ChartDrawingAnchor> anchors,
    Color color,
    ChartCoordinateMapper mapper,
  ) {
    final values = <_DrawingAxisValue>[];
    for (final anchor in anchors) {
      final x = mapper.anchorToX(anchor);
      if (x == null ||
          !x.isFinite ||
          x < mMainRect.left ||
          x > mMainRect.right) {
        continue;
      }
      values.add(_DrawingAxisValue(anchor.time.toDouble(), x));
    }
    if (values.isEmpty) {
      return;
    }

    values.sort((a, b) => a.position.compareTo(b.position));
    final top = size.height - mBottomPadding;
    if (values.length >= 2) {
      canvas.drawRect(
        Rect.fromLTRB(
            values.first.position, top, values.last.position, size.height),
        Paint()
          ..isAntiAlias = true
          ..style = PaintingStyle.fill
          ..color = color.withValues(alpha: 0.18),
      );
    }

    for (final value in values) {
      _drawDrawingTimeAxisChip(
        canvas,
        DateTime.fromMillisecondsSinceEpoch(value.value.toInt()),
        value.position,
        top,
        size.width,
        color,
      );
    }
  }

  void _drawDrawingTimeAxisChip(
    Canvas canvas,
    DateTime time,
    double x,
    double top,
    double width,
    Color color,
  ) {
    const padH = 5.0;
    const padV = 2.0;
    const radius = 3.0;
    final label = dateFormat(time, mFormats);
    final tp = getChipTextPainter(label, Colors.white);
    final chipWidth = tp.width + padH * 2;
    final chipHeight = tp.height + padV * 2;
    final left = width <= chipWidth
        ? 0.0
        : (x - chipWidth / 2).clamp(0.0, width - chipWidth).toDouble();
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, chipWidth, chipHeight),
      const Radius.circular(radius),
    );
    canvas.drawRRect(
      rrect,
      Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.fill
        ..color = color,
    );
    tp.paint(canvas, Offset(left + padH, top + padV));
  }

  //For TrendLine
  void drawTrendLines(Canvas canvas, Size size) {
    var index = calculateSelectedX(selectX);
    Paint paintY = Paint()
      ..color = chartColors.trendLineColor
      ..strokeWidth = 1
      ..isAntiAlias = true;
    double x = getX(index);
    trendLineX = x;

    double y = selectY;
    // getMainY(point.close);

    // K-line chart vertical line
    canvas.drawLine(Offset(x, mTopPadding),
        Offset(x, size.height - mBottomPadding), paintY);
    Paint paintX = Paint()
      ..color = chartColors.trendLineColor
      ..strokeWidth = 1
      ..isAntiAlias = true;
    Paint paint = Paint()
      ..color = chartColors.trendLineColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(-mTranslateX, y),
        Offset(-mTranslateX + mWidth / scaleX, y), paintX);
    if (scaleX >= 1) {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(x, y), height: 15.0 * scaleX, width: 15.0),
        paint,
      );
    } else {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(x, y), height: 10.0, width: 10.0 / scaleX),
        paint,
      );
    }
    if (lines.isNotEmpty) {
      lines.forEach((element) {
        var y1 = -((element.p1.dy - 35) / element.scale) + element.maxHeight;
        var y2 = -((element.p2.dy - 35) / element.scale) + element.maxHeight;
        var a = (trendLineMax! - y1) * trendLineScale! + trendLineContentRec!;
        var b = (trendLineMax! - y2) * trendLineScale! + trendLineContentRec!;
        var p1 = Offset(element.p1.dx, a);
        var p2 = Offset(element.p2.dx, b);
        canvas.drawLine(
            p1,
            element.p2 == Offset(-1, -1) ? Offset(x, y) : p2,
            Paint()
              ..color = Colors.yellow
              ..strokeWidth = 2);
      });
    }
  }

  ///draw cross lines
  void drawCrossLine(Canvas canvas, Size size) {
    var index = calculateSelectedX(selectX);
    KLineEntity point = getItem(index);
    Paint paintY = Paint()
      ..color = this.chartColors.vCrossColor
      ..strokeWidth = this.chartStyle.vCrossWidth
      ..isAntiAlias = true;
    double x = getX(index);
    double y = getMainY(point.close);
    // K-line chart vertical line
    canvas.drawLine(Offset(x, mTopPadding),
        Offset(x, size.height - mBottomPadding), paintY);

    Paint paintX = Paint()
      ..color = this.chartColors.hCrossColor
      ..strokeWidth = this.chartStyle.hCrossWidth
      ..isAntiAlias = true;
    // K-line chart horizontal line
    canvas.drawLine(Offset(-mTranslateX, y),
        Offset(-mTranslateX + mWidth / scaleX, y), paintX);
    if (scaleX >= 1) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), height: 2.0 * scaleX, width: 2.0),
        paintX,
      );
    } else {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), height: 2.0, width: 2.0 / scaleX),
        paintX,
      );
    }
  }

  TextPainter getTextPainter(text, color) {
    if (color == null) {
      color = this.chartColors.defaultTextColor;
    }
    TextSpan span = TextSpan(text: "$text", style: getTextStyle(color));
    TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    return tp;
  }

  // smaller text painter for markers
  TextPainter getMarkerTextPainter(String text) {
    final TextSpan span = TextSpan(
      text: text,
      style: TextStyle(fontSize: 8.0, color: Colors.white),
    );
    final TextPainter tp =
        TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    return tp;
  }

  String getDate(int? date) => dateFormat(
        DateTime.fromMillisecondsSinceEpoch(
            date ?? DateTime.now().millisecondsSinceEpoch),
        mFormats,
      );

  double getMainY(double y) => mMainRenderer.getY(y);

  /// Whether the point is in the SecondaryRect
  // bool isInSecondaryRect(Offset point) {
  //   // return mSecondaryRect.contains(point) == true);
  //   return false;
  // }

  /// Whether the point is in MainRect
  bool isInMainRect(Offset point) {
    return mMainRect.contains(point);
  }

  // helper: smaller font for chips only
  TextPainter getChipTextPainter(String text, Color color) {
    final TextSpan span = TextSpan(
      text: text,
      style: TextStyle(fontSize: 9.0, color: color),
    );
    final TextPainter tp =
        TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout();
    return tp;
  }
}
