import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:bydoxe_chart/chart_translations.dart';
import 'package:bydoxe_chart/components/popup_info_view.dart';
import 'package:bydoxe_chart/k_chart_plus.dart';
import 'renderer/base_dimension.dart';
import 'renderer/main_axis_range.dart';

enum MainState { MA, BOLL, SAR, EMA, AVL }

enum SecondaryState { MACD, KDJ, RSI, WR, OBV, STOCHRSI }

class TimeFormat {
  static const List<String> YEAR_MONTH_DAY = [yyyy, '-', mm, '-', dd];
  static const List<String> YEAR_MONTH_DAY_WITH_HOUR = [
    yyyy,
    '-',
    mm,
    '-',
    dd,
    ' ',
    HH,
    ':',
    nn
  ];
}

class KChartWidget extends StatefulWidget {
  final List<KLineEntity>? datas;
  final Set<MainState> mainStateLi;
  final bool volHidden;
  final Set<SecondaryState> secondaryStateLi;
  // final Function()? onSecondaryTap;
  final bool isLine;
  final bool
      isTapShowInfoDialog; //Whether to enable click to display detailed data
  final bool hideGrid;
  final bool showNowPrice;
  final bool showInfoDialog;
  final bool materialInfoDialog; // Material Style Information Popup
  final ChartTranslations chartTranslations;
  final List<String> timeFormat;
  final double mBaseHeight;

  // It will be called when the screen scrolls to the end.
  // If true, it will be scrolled to the end of the right side of the screen.
  // If it is false, it will be scrolled to the end of the left side of the screen.
  final Function(bool)? onLoadMore;

  /// 양 끝(좌/우) 도달 시, 해당 방향과 함께 페이징 기준 타임스탬프를 전달합니다.
  /// - isLeft=true: 현재 첫 봉 시간 - 1ms
  /// - isLeft=false: 현재 마지막 봉 시간 + 1ms
  final void Function(bool isLeft, int ts)? onEdgeLoadTs;

  final int fixedLength;
  final List<int> maDayList;
  final int flingTime;
  final double flingRatio;
  final Curve flingCurve;
  final Function(bool)? isOnDrag;
  final ChartColors chartColors;
  final ChartStyle chartStyle;
  final VerticalTextAlignment verticalTextAlignment;
  final NowPriceLabelAlignment nowPriceLabelAlignment;
  final List<PositionLineEntity> positionLines;
  final PositionLabelAlignment positionLabelAlignment;
  final void Function(int id, PositionAction action)? onPositionAction;
  final List<PositionMarkerEntity> markers;
  final bool isTrendLine;
  final double xFrontPadding;
  final List<IndicatorMA>? indicatorMA;
  final List<IndicatorEMA>? indicatorEMA;
  final List<RSIInputEntity>? indicatorRSI;
  final IndicatorBOLL? indicatorBOLL;
  final IndicatorSAR? indicatorSAR;
  final IndicatorAVL? indicatorAVL;
  final List<IndicatorVolMA>? indicatorVolMA; // up to 2
  final MACDInputEntity? indicatorMACD;
  final WRInputEntity? indicatorWR;
  final OBVInputEntity? indicatorOBV;
  final StochRSIInputEntity? indicatorStochRSI;
  final KDJInputEntity? indicatorKDJ;

  KChartWidget(
    this.datas,
    this.chartStyle,
    this.chartColors, {
    required this.isTrendLine,
    this.xFrontPadding = 100,
    this.mainStateLi = const <MainState>{},
    this.secondaryStateLi = const <SecondaryState>{},
    // this.onSecondaryTap,
    this.volHidden = false,
    this.isLine = false,
    this.isTapShowInfoDialog = false,
    this.hideGrid = false,
    this.showNowPrice = true,
    this.showInfoDialog = true,
    this.materialInfoDialog = true,
    this.chartTranslations = const ChartTranslations(),
    this.timeFormat = TimeFormat.YEAR_MONTH_DAY,
    this.onLoadMore,
    this.onEdgeLoadTs,
    this.fixedLength = 2,
    this.maDayList = const [5, 10, 20],
    this.flingTime = 600,
    this.flingRatio = 0.5,
    this.flingCurve = Curves.decelerate,
    this.isOnDrag,
    this.verticalTextAlignment = VerticalTextAlignment.left,
    this.nowPriceLabelAlignment = NowPriceLabelAlignment.followVertical,
    this.positionLines = const <PositionLineEntity>[],
    this.positionLabelAlignment = PositionLabelAlignment.left,
    this.onPositionAction,
    this.markers = const <PositionMarkerEntity>[],
    this.mBaseHeight = 360,
    this.indicatorMA,
    this.indicatorEMA,
    this.indicatorBOLL,
    this.indicatorSAR,
    this.indicatorAVL,
    this.indicatorVolMA,
    this.indicatorMACD,
    this.indicatorRSI,
    this.indicatorWR,
    this.indicatorOBV,
    this.indicatorStochRSI,
    this.indicatorKDJ,
  });

  @override
  _KChartWidgetState createState() => _KChartWidgetState();
}

class _KChartWidgetState extends State<KChartWidget>
    with TickerProviderStateMixin {
  final StreamController<InfoWindowEntity?> mInfoWindowStream =
      StreamController<InfoWindowEntity?>();
  double mScaleX = 1.0, mScrollX = 0.0, mSelectX = 0.0;
  double mHeight = 0, mWidth = 0;
  bool _mainAxisAutoScale = true;
  MainAxisRange? _mainAxisRangeOverride;
  MainAxisRange? _axisDragStartRange;
  double? _axisDragStartY;
  MainAxisRange? _scaleStartMainAxisRange;
  AnimationController? _controller;
  Animation<double>? aniX;

  //For TrendLine
  List<TrendLine> lines = [];
  int? activePositionId;
  double? changeInXPosition;
  double? changeInYPosition;
  double mSelectY = 0.0;
  bool waitingForOtherPairOfCords = false;
  bool enableCordRecord = false;

  double getMinScrollX() {
    return mScaleX;
  }

  double _lastScale = 1.0;
  bool isScale = false, isDrag = false, isLongPress = false, isOnTap = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    mInfoWindowStream.sink.close();
    mInfoWindowStream.close();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.datas != null && widget.datas!.isEmpty) {
      mScrollX = mSelectX = 0.0;
      mScaleX = 1.0;
      _mainAxisAutoScale = true;
      _mainAxisRangeOverride = null;
      _axisDragStartRange = null;
      _axisDragStartY = null;
      _scaleStartMainAxisRange = null;
    }
    final BaseDimension baseDimension = BaseDimension(
      mBaseHeight: widget.mBaseHeight,
      volHidden: widget.volHidden,
      secondaryStateLi: widget.secondaryStateLi,
      mainStateLi: widget.mainStateLi,
    );
    final _painter = ChartPainter(
      widget.chartStyle,
      widget.chartColors,
      baseDimension: baseDimension,
      lines: lines, //For TrendLine
      sink: mInfoWindowStream.sink,
      xFrontPadding: widget.xFrontPadding,
      isTrendLine: widget.isTrendLine, //For TrendLine
      selectY: mSelectY, //For TrendLine
      datas: widget.datas,
      scaleX: mScaleX,
      scrollX: mScrollX,
      selectX: mSelectX,
      isLongPass: isLongPress,
      isOnTap: isOnTap,
      isTapShowInfoDialog: widget.isTapShowInfoDialog,
      mainStateLi: widget.mainStateLi,
      volHidden: widget.volHidden,
      secondaryStateLi: widget.secondaryStateLi,
      isLine: widget.isLine,
      hideGrid: widget.hideGrid,
      showNowPrice: widget.showNowPrice,
      fixedLength: widget.fixedLength,
      maDayList: widget.maDayList,
      verticalTextAlignment: widget.verticalTextAlignment,
      nowPriceLabelAlignment: widget.nowPriceLabelAlignment,
      positionLines: widget.positionLines,
      positionLabelAlignment: widget.positionLabelAlignment,
      markers: widget.markers,
      activePositionId: activePositionId,
      mainAxisRangeOverride: _mainAxisAutoScale ? null : _mainAxisRangeOverride,
      indicatorMA: widget.indicatorMA,
      indicatorEMA: widget.indicatorEMA,
      indicatorRSI: widget.indicatorRSI,
      indicatorBOLL: widget.indicatorBOLL,
      indicatorSAR: widget.indicatorSAR,
      indicatorAVL: widget.indicatorAVL,
      indicatorVolMA: widget.indicatorVolMA,
      indicatorMACD: widget.indicatorMACD,
      indicatorWR: widget.indicatorWR,
      indicatorOBV: widget.indicatorOBV,
      indicatorStochRSI: widget.indicatorStochRSI,
      indicatorKDJ: widget.indicatorKDJ,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        mHeight = constraints.maxHeight;
        mWidth = constraints.maxWidth;
        return GestureDetector(
          onTapUp: (details) {
            // if (!widget.isTrendLine && widget.onSecondaryTap != null && _painter.isInSecondaryRect(details.localPosition)) {
            //   widget.onSecondaryTap!();
            // }

            if (!widget.isTrendLine &&
                _painter.isInMainRect(details.localPosition)) {
              isOnTap = true;
              // hit test position chips/buttons first
              final hit =
                  _hitTestPosition(details.localPosition, _painter) ?? false;
              // if not hit on position elements, check now price chip when pinned
              if (!hit && _painter.nowPricePinned == true) {
                final Rect? chipRect = _painter.nowPriceChipRect;
                if (chipRect != null &&
                    chipRect.contains(details.localPosition)) {
                  // jump to latest: scroll to rightmost
                  setState(() {
                    // Jump to latest candle (rightmost): scrollX = 0
                    mScrollX = 0;
                  });
                  notifyChanged();
                  return;
                }
              }
              if (hit == true) {
                return;
              }
              // if any active position exists and tap didn't hit chips/buttons, close it
              if (activePositionId != null) {
                setState(() {
                  activePositionId = null;
                  _painter.activePositionId = null;
                });
                return;
              }
              if (mSelectX != details.localPosition.dx &&
                  widget.isTapShowInfoDialog) {
                mSelectX = details.localPosition.dx;
                notifyChanged();
              }
            }
            // tap outside main rect closes active position as well
            if (activePositionId != null &&
                !_painter.isInMainRect(details.localPosition)) {
              setState(() {
                activePositionId = null;
                _painter.activePositionId = null;
              });
              return;
            }
            if (widget.isTrendLine && !isLongPress && enableCordRecord) {
              enableCordRecord = false;
              Offset p1 = Offset(getTrendLineX(), mSelectY);
              if (!waitingForOtherPairOfCords) {
                lines.add(TrendLine(
                    p1, Offset(-1, -1), trendLineMax!, trendLineScale!));
              }

              if (waitingForOtherPairOfCords) {
                var a = lines.last;
                lines.removeLast();
                lines.add(TrendLine(a.p1, p1, trendLineMax!, trendLineScale!));
                waitingForOtherPairOfCords = false;
              } else {
                waitingForOtherPairOfCords = true;
              }
              notifyChanged();
            }
          },
          onHorizontalDragDown: (details) {
            isOnTap = false;
            _stopAnimation();
            _onDragChanged(true);
          },
          onHorizontalDragUpdate: (details) {
            if (isScale || isLongPress) return;
            mScrollX = ((details.primaryDelta ?? 0) / mScaleX + mScrollX)
                .clamp(0.0, ChartPainter.maxScrollX)
                .toDouble();
            notifyChanged();
          },
          onHorizontalDragEnd: (DragEndDetails details) {
            var velocity = details.velocity.pixelsPerSecond.dx;
            _onFling(velocity);
          },
          onHorizontalDragCancel: () => _onDragChanged(false),
          onScaleStart: (_) {
            isScale = true;
            _scaleStartMainAxisRange = _mainAxisAutoScale
                ? null
                : _resolveCurrentMainAxisRange(mWidth);
          },
          onScaleUpdate: (details) {
            if (isDrag || isLongPress) return;
            mScaleX = (_lastScale * details.scale).clamp(0.5, 2.2);
            final startRange = _scaleStartMainAxisRange;
            if (!_mainAxisAutoScale &&
                startRange != null &&
                details.verticalScale.isFinite &&
                details.verticalScale > 0) {
              if (details.pointerCount > 1) {
                _mainAxisRangeOverride = startRange
                    .scaleFromAnchor(
                        startRange.center, 1 / details.verticalScale)
                    .normalized();
              } else {
                _panMainAxisByDistance(details.focalPointDelta.dy,
                    shouldNotify: false);
              }
            }
            notifyChanged();
          },
          onScaleEnd: (_) {
            isScale = false;
            _lastScale = mScaleX;
            _scaleStartMainAxisRange = null;
          },
          onLongPressStart: (details) {
            isOnTap = false;
            isLongPress = true;
            if ((mSelectX != details.localPosition.dx ||
                    mSelectY != details.globalPosition.dy) &&
                !widget.isTrendLine) {
              mSelectX = details.localPosition.dx;
              notifyChanged();
            }
            //For TrendLine
            if (widget.isTrendLine && changeInXPosition == null) {
              mSelectX = changeInXPosition = details.localPosition.dx;
              mSelectY = changeInYPosition = details.globalPosition.dy;
              notifyChanged();
            }
            //For TrendLine
            if (widget.isTrendLine && changeInXPosition != null) {
              changeInXPosition = details.localPosition.dx;
              changeInYPosition = details.globalPosition.dy;
              notifyChanged();
            }
          },
          onLongPressMoveUpdate: (details) {
            if ((mSelectX != details.localPosition.dx ||
                    mSelectY != details.globalPosition.dy) &&
                !widget.isTrendLine) {
              mSelectX = details.localPosition.dx;
              mSelectY = details.localPosition.dy;
              notifyChanged();
            }
            if (widget.isTrendLine) {
              mSelectX =
                  mSelectX + (details.localPosition.dx - changeInXPosition!);
              changeInXPosition = details.localPosition.dx;
              mSelectY =
                  mSelectY + (details.globalPosition.dy - changeInYPosition!);
              changeInYPosition = details.globalPosition.dy;
              notifyChanged();
            }
          },
          onLongPressEnd: (details) {
            isLongPress = false;
            enableCordRecord = true;
            mInfoWindowStream.sink.add(null);
            notifyChanged();
          },
          child: Stack(
            children: <Widget>[
              CustomPaint(
                size: Size(double.infinity, baseDimension.mDisplayHeight),
                painter: _painter,
              ),
              if (widget.showInfoDialog) _buildInfoDialog(),
              _buildMainAxisGestureLayer(baseDimension),
              if (!_mainAxisAutoScale) _buildMainAxisResetButton(baseDimension),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainAxisGestureLayer(BaseDimension baseDimension) {
    final bool isLeftAxis =
        widget.verticalTextAlignment == VerticalTextAlignment.left;
    final double top =
        widget.chartStyle.topPadding + baseDimension.totalLabelHeight;
    final double height = _resolveMainRectHeight(baseDimension);
    return Positioned(
      top: top,
      left: isLeftAxis ? 0 : null,
      right: isLeftAxis ? null : 0,
      width: 56,
      height: height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: (details) {
          final range = _resolveCurrentMainAxisRange(mWidth);
          if (range == null) return;
          _mainAxisAutoScale = false;
          _mainAxisRangeOverride = range;
          _axisDragStartRange = range;
          _axisDragStartY = details.localPosition.dy;
        },
        onVerticalDragUpdate: (details) {
          final startRange = _axisDragStartRange;
          final startY = _axisDragStartY;
          if (startRange == null || startY == null) return;
          final double deltaRatio =
              (details.localPosition.dy - startY) / max(1.0, height);
          final double scale = exp(deltaRatio * 2.0);
          _mainAxisRangeOverride =
              startRange.scaleFromAnchor(startRange.center, scale);
          notifyChanged();
        },
        onVerticalDragEnd: (_) {
          _axisDragStartRange = null;
          _axisDragStartY = null;
        },
        onVerticalDragCancel: () {
          _axisDragStartRange = null;
          _axisDragStartY = null;
        },
      ),
    );
  }

  Widget _buildMainAxisResetButton(BaseDimension baseDimension) {
    final bool isLeftAxis =
        widget.verticalTextAlignment == VerticalTextAlignment.left;
    final double top = max(
      0,
      widget.chartStyle.topPadding +
          baseDimension.totalLabelHeight +
          _resolveMainRectHeight(baseDimension) -
          30,
    ).toDouble();
    return Positioned(
      top: top,
      left: isLeftAxis ? 4 : null,
      right: isLeftAxis ? null : 4,
      width: 28,
      height: 24,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _resetMainAxisScale,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: widget.chartColors.selectFillColor,
            border: Border.all(
              color: widget.chartColors.selectBorderColor,
              width: 0.5,
            ),
          ),
          child: Icon(
            Icons.refresh,
            size: 14,
            color: widget.chartColors.defaultTextColor,
          ),
        ),
      ),
    );
  }

  double _resolveMainRectHeight(BaseDimension baseDimension) {
    final double topPadding =
        widget.chartStyle.topPadding + baseDimension.totalLabelHeight;
    final double displayHeight = baseDimension.mDisplayHeight -
        topPadding -
        widget.chartStyle.bottomPadding;
    return displayHeight -
        baseDimension.mVolumeHeight -
        baseDimension.totalSecondaryHeight;
  }

  MainAxisRange? _resolveCurrentMainAxisRange(double width) {
    final override = _mainAxisRangeOverride;
    if (!_mainAxisAutoScale && override != null && override.isValid) {
      return override;
    }
    return _resolveVisibleMainAutoRange(width);
  }

  MainAxisRange? _resolveVisibleMainAutoRange(double width) {
    final data = widget.datas;
    if (data == null || data.isEmpty || width <= 0 || mScaleX <= 0) {
      return null;
    }

    final pointWidth = widget.chartStyle.pointWidth;
    final itemCount = data.length;
    final dataLen = itemCount * pointWidth;
    double minTranslateX =
        -dataLen + width / mScaleX - pointWidth / 2 - widget.xFrontPadding;
    if (minTranslateX >= 0) minTranslateX = 0.0;
    final translateX = mScrollX + minTranslateX;

    double getX(int position) => position * pointWidth + pointWidth / 2;
    double xToTranslateX(double x) => -translateX + x / mScaleX;
    int indexOfTranslateX(double translateX) {
      int start = 0;
      int end = itemCount - 1;
      while (end - start > 1) {
        final mid = start + (end - start) ~/ 2;
        final midValue = getX(mid);
        if (translateX < midValue) {
          end = mid;
        } else if (translateX > midValue) {
          start = mid;
        } else {
          return mid;
        }
      }
      if (end == start || end == -1) return start;
      final startValue = getX(start);
      final endValue = getX(end);
      return (translateX - startValue).abs() < (translateX - endValue).abs()
          ? start
          : end;
    }

    final startIndex =
        indexOfTranslateX(xToTranslateX(0)).clamp(0, itemCount - 1).toInt();
    final stopIndex =
        indexOfTranslateX(xToTranslateX(width)).clamp(0, itemCount - 1).toInt();
    final from = min(startIndex, stopIndex);
    final to = max(startIndex, stopIndex);

    double minValue = double.infinity;
    double maxValue = -double.infinity;
    for (int i = from; i <= to; i++) {
      final item = data[i];
      var itemMin = item.low;
      var itemMax = item.high;
      for (final state in widget.mainStateLi) {
        if (state == MainState.MA) {
          final values = item.maValueList;
          if (values != null) {
            for (final value in values) {
              if (value == 0) continue;
              itemMin = min(itemMin, value);
              itemMax = max(itemMax, value);
            }
          }
        } else if (state == MainState.BOLL) {
          final up = item.up;
          final dn = item.dn;
          if (up != null) itemMax = max(itemMax, up);
          if (dn != null) itemMin = min(itemMin, dn);
        } else if (state == MainState.SAR &&
            widget.chartStyle.includeSarInScale) {
          final sar = item.sar;
          if (sar != null) {
            itemMin = min(itemMin, sar);
            itemMax = max(itemMax, sar);
          }
        }
      }
      minValue = min(minValue, itemMin);
      maxValue = max(maxValue, itemMax);
    }

    final range = MainAxisRange(min: minValue, max: maxValue).normalized();
    return range.isValid ? range : null;
  }

  void _panMainAxisByDistance(double distance, {bool shouldNotify = true}) {
    if (distance.abs() < 0.001) return;
    final range = _resolveCurrentMainAxisRange(mWidth);
    if (range == null) return;
    final double height = max(
        1.0,
        _resolveMainRectHeight(BaseDimension(
          mBaseHeight: widget.mBaseHeight,
          volHidden: widget.volHidden,
          secondaryStateLi: widget.secondaryStateLi,
          mainStateLi: widget.mainStateLi,
        )));
    final double deltaValue = (distance / height) * range.span;
    _mainAxisAutoScale = false;
    _mainAxisRangeOverride = range.panBy(deltaValue);
    if (shouldNotify) {
      notifyChanged();
    }
  }

  void _resetMainAxisScale() {
    setState(() {
      _mainAxisAutoScale = true;
      _mainAxisRangeOverride = null;
      _axisDragStartRange = null;
      _axisDragStartY = null;
      _scaleStartMainAxisRange = null;
    });
  }

  // hit test against painter-stored rects
  bool? _hitTestPosition(Offset pos, ChartPainter painter) {
    // expose painter maps through getters
    final left = painter.hitLeftChip;
    final close = painter.hitBtnClose;
    final tp = painter.hitBtnTp;
    final sl = painter.hitBtnSl;

    for (final e in left.entries) {
      if (e.value.contains(pos)) {
        // toggle active id
        setState(() {
          activePositionId = (activePositionId == e.key) ? null : e.key;
          painter.activePositionId = activePositionId;
        });
        return true;
      }
    }
    for (final e in close.entries) {
      if (e.value.contains(pos)) {
        widget.onPositionAction?.call(e.key, PositionAction.close);
        setState(() {
          activePositionId = null;
          painter.activePositionId = null;
        });
        return true;
      }
    }
    for (final e in tp.entries) {
      if (e.value.contains(pos)) {
        widget.onPositionAction?.call(e.key, PositionAction.tp);
        setState(() {
          activePositionId = null;
          painter.activePositionId = null;
        });
        return true;
      }
    }
    for (final e in sl.entries) {
      if (e.value.contains(pos)) {
        widget.onPositionAction?.call(e.key, PositionAction.sl);
        setState(() {
          activePositionId = null;
          painter.activePositionId = null;
        });
        return true;
      }
    }
    return null;
  }

  void _stopAnimation({bool needNotify = true}) {
    if (_controller != null && _controller!.isAnimating) {
      _controller!.stop();
      _onDragChanged(false);
      if (needNotify) {
        notifyChanged();
      }
    }
  }

  void _onDragChanged(bool isOnDrag) {
    isDrag = isOnDrag;
    if (widget.isOnDrag != null) {
      widget.isOnDrag!(isDrag);
    }
  }

  void _onFling(double x) {
    _controller = AnimationController(
        duration: Duration(milliseconds: widget.flingTime), vsync: this);
    aniX = null;
    aniX = Tween<double>(begin: mScrollX, end: x * widget.flingRatio + mScrollX)
        .animate(CurvedAnimation(
            parent: _controller!.view, curve: widget.flingCurve));
    aniX!.addListener(() {
      mScrollX = aniX!.value;
      if (mScrollX <= 0) {
        mScrollX = 0;
        if (widget.onLoadMore != null) {
          widget.onLoadMore!(true);
        }
        // 좌측 끝 도달 시 공통 콜백(onEdgeLoadTs)만 사용
        // 공통 콜백: 좌측 끝 기준 타임스탬프 전달 (요청 사양)
        // true => lastTimeMs + 1
        if (widget.onEdgeLoadTs != null &&
            widget.datas != null &&
            widget.datas!.isNotEmpty) {
          final int lastTimeMs = widget.datas!.last.time ?? 0;
          widget.onEdgeLoadTs!(true, lastTimeMs + 1);
        }
        _stopAnimation();
      } else if (mScrollX >= ChartPainter.maxScrollX) {
        mScrollX = ChartPainter.maxScrollX;
        if (widget.onLoadMore != null) {
          widget.onLoadMore!(false);
        }
        // 공통 콜백: 우측 끝 기준 타임스탬프 전달 (요청 사양)
        // false => firstTimeMs - 1
        if (widget.onEdgeLoadTs != null &&
            widget.datas != null &&
            widget.datas!.isNotEmpty) {
          final int firstTimeMs = widget.datas!.first.time ?? 0;
          widget.onEdgeLoadTs!(false, firstTimeMs - 1);
        }
        _stopAnimation();
      }
      notifyChanged();
    });
    aniX!.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        _onDragChanged(false);
        notifyChanged();
      }
    });
    _controller!.forward();
  }

  void notifyChanged() => setState(() {});

  late List<String> infos;

  Widget _buildInfoDialog() {
    return StreamBuilder<InfoWindowEntity?>(
      stream: mInfoWindowStream.stream,
      builder: (context, snapshot) {
        if ((!isLongPress && !isOnTap) ||
            widget.isLine == true ||
            !snapshot.hasData ||
            snapshot.data?.kLineEntity == null) return SizedBox();
        KLineEntity entity = snapshot.data!.kLineEntity;
        final dialogWidth = mWidth / 3;
        if (snapshot.data!.isLeft) {
          return Positioned(
            top: 25,
            left: 10.0,
            child: PopupInfoView(
              entity: entity,
              width: dialogWidth,
              chartColors: widget.chartColors,
              chartTranslations: widget.chartTranslations,
              materialInfoDialog: widget.materialInfoDialog,
              timeFormat: widget.timeFormat,
              fixedLength: widget.fixedLength,
            ),
          );
        }
        return Positioned(
          top: 25,
          right: 10.0,
          child: PopupInfoView(
            entity: entity,
            width: dialogWidth,
            chartColors: widget.chartColors,
            chartTranslations: widget.chartTranslations,
            materialInfoDialog: widget.materialInfoDialog,
            timeFormat: widget.timeFormat,
            fixedLength: widget.fixedLength,
          ),
        );
      },
    );
  }
}
