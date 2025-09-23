import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bydoxe_chart/chart_translations.dart';
import 'package:bydoxe_chart/components/popup_info_view.dart';
import 'package:bydoxe_chart/k_chart_plus.dart';
import 'renderer/base_dimension.dart';

enum MainState { MA, BOLL, SAR, EMA, AVL }

enum SecondaryState { MACD, KDJ, RSI, WR, CCI }

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
  final IndicatorBOLL? indicatorBOLL;
  final IndicatorSAR? indicatorSAR;
  final IndicatorAVL? indicatorAVL;
  final List<IndicatorVolMA>? indicatorVolMA; // up to 2

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
  double _priceScale = 1.0;
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
      priceScale: _priceScale,
      indicatorMA: widget.indicatorMA,
      indicatorEMA: widget.indicatorEMA,
      indicatorBOLL: widget.indicatorBOLL,
      indicatorSAR: widget.indicatorSAR,
      indicatorAVL: widget.indicatorAVL,
      indicatorVolMA: widget.indicatorVolMA,
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
          },
          onScaleUpdate: (details) {
            if (isDrag || isLongPress) return;
            mScaleX = (_lastScale * details.scale).clamp(0.5, 2.2);
            notifyChanged();
          },
          onScaleEnd: (_) {
            isScale = false;
            _lastScale = mScaleX;
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
              // 우측 가격축 전용 수직 드래그 제스처 레이어(56px)
              Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                width: 56,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: (details) {
                    final double dy = details.primaryDelta ?? 0;
                    final double factor = 1.0 - dy * 0.005;
                    // allow zoom-in and zoom-out; renderer will clamp to extremes
                    _priceScale = (_priceScale * factor).clamp(0.2, 50.0);
                    notifyChanged();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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
