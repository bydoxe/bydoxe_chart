import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
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

typedef ChartDrawingOverlayBuilder = Widget Function(
  BuildContext context,
  ChartDrawingEntity drawing,
  Rect drawingBounds,
);

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
  final double? priceLabelTickSize;
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
  final List<ChartDrawingEntity> drawings;
  final int? selectedDrawingId;
  final bool showDrawings;
  final bool drawingSelectionEnabled;
  final bool drawingMagnetEnabled;
  final bool drawingDefaultLocked;
  final ValueChanged<int?>? onSelectedDrawingChanged;
  final ChartDrawingTool drawingTool;
  final ChartDrawingStyle drawingStyle;
  final bool drawingEnabled;
  final ValueChanged<List<ChartDrawingEntity>>? onDrawingsChanged;
  final void Function(ChartDrawingEvent event)? onDrawingEvent;
  final ChartDrawingOverlayBuilder? selectedDrawingOverlayBuilder;
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
    this.priceLabelTickSize,
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
    this.drawings = const <ChartDrawingEntity>[],
    this.selectedDrawingId,
    this.showDrawings = true,
    this.drawingSelectionEnabled = false,
    this.drawingMagnetEnabled = false,
    this.drawingDefaultLocked = false,
    this.onSelectedDrawingChanged,
    this.drawingTool = ChartDrawingTool.none,
    this.drawingStyle = const ChartDrawingStyle(),
    this.drawingEnabled = false,
    this.onDrawingsChanged,
    this.onDrawingEvent,
    this.selectedDrawingOverlayBuilder,
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
  static const double _defaultScaleX = 1.0;
  static const double _minScaleX = 0.5;
  static const double _autoScaleMaxScaleX = 2.2;
  static const double _manualAxisMaxScaleX = 5.0;
  static const String _candlePaneLogoAsset =
      'packages/bydoxe_chart/assets/candle_pane_logo.png';

  final StreamController<InfoWindowEntity?> mInfoWindowStream =
      StreamController<InfoWindowEntity?>();
  double mScaleX = 1.0, mScrollX = 0.0, mSelectX = 0.0;
  double mHeight = 0, mWidth = 0;
  bool _mainAxisAutoScale = true;
  MainAxisRange? _mainAxisRangeOverride;
  MainAxisRange? _axisDragStartRange;
  double? _axisDragStartY;
  MainAxisRange? _scaleStartMainAxisRange;
  double? _scaleStartMainAxisAnchor;
  double _scaleStartScaleX = _defaultScaleX;
  double _scaleStartScrollX = 0.0;
  double _scaleStartFocalX = 0.0;
  final Set<int> _activePointerIds = <int>{};
  final Map<int, Offset> _activePointerPositions = <int, Offset>{};
  int? _mainAxisPanPointer;
  Offset? _lastMainAxisPanPosition;
  bool _manualPinchActive = false;
  double _manualPinchStartDistance = 0.0;
  double _manualPinchStartVerticalDistance = 0.0;
  double _manualPinchStartScaleX = _defaultScaleX;
  double _manualPinchStartScrollX = 0.0;
  MainAxisRange? _manualPinchStartRange;
  ui.Image? _candlePaneLogo;
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
  ChartDrawingEntity? _draftDrawing;
  ChartDrawingTool _draftTool = ChartDrawingTool.none;
  ChartDrawingAnchor? _draftPreviewAnchor;
  int? _draftPreviewPointer;
  Offset? _draftPreviewPointerDownPosition;
  bool _draftPreviewPointerMoved = false;
  DrawingDragSession? _drawingDragSession;

  @override
  void didUpdateWidget(covariant KChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.drawingEnabled ||
        widget.drawingTool == ChartDrawingTool.none ||
        widget.drawingTool != oldWidget.drawingTool) {
      _draftDrawing = null;
      _draftTool = ChartDrawingTool.none;
      _draftPreviewAnchor = null;
      _draftPreviewPointer = null;
      _draftPreviewPointerDownPosition = null;
      _draftPreviewPointerMoved = false;
    }
  }

  double getMinScrollX() {
    return mScaleX;
  }

  bool isScale = false, isDrag = false, isLongPress = false, isOnTap = false;

  @override
  void initState() {
    super.initState();
    _loadCandlePaneLogo();
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
    _candlePaneLogo?.dispose();
    super.dispose();
  }

  Future<void> _loadCandlePaneLogo() async {
    final data = await rootBundle.load(_candlePaneLogoAsset);
    final bytes = Uint8List.view(
      data.buffer,
      data.offsetInBytes,
      data.lengthInBytes,
    );
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    codec.dispose();
    if (!mounted) {
      frame.image.dispose();
      return;
    }
    setState(() {
      _candlePaneLogo?.dispose();
      _candlePaneLogo = frame.image;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.datas != null && widget.datas!.isEmpty) {
      mScrollX = mSelectX = 0.0;
      mScaleX = _defaultScaleX;
      _mainAxisAutoScale = true;
      _mainAxisRangeOverride = null;
      _axisDragStartRange = null;
      _axisDragStartY = null;
      _scaleStartMainAxisRange = null;
      _scaleStartMainAxisAnchor = null;
      _scaleStartScaleX = _defaultScaleX;
      _scaleStartScrollX = 0.0;
      _scaleStartFocalX = 0.0;
      _activePointerIds.clear();
      _activePointerPositions.clear();
      _mainAxisPanPointer = null;
      _lastMainAxisPanPosition = null;
      _resetManualPinchState();
    }
    final BaseDimension baseDimension = BaseDimension(
      mBaseHeight: widget.mBaseHeight,
      volHidden: widget.volHidden,
      secondaryStateLi: widget.secondaryStateLi,
      mainStateLi: widget.mainStateLi,
    );
    final displayDrawings = _displayDrawings();
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
      candlePaneLogo: _candlePaneLogo,
      fixedLength: widget.fixedLength,
      priceLabelTickSize: widget.priceLabelTickSize,
      maDayList: widget.maDayList,
      verticalTextAlignment: widget.verticalTextAlignment,
      nowPriceLabelAlignment: widget.nowPriceLabelAlignment,
      positionLines: widget.positionLines,
      positionLabelAlignment: widget.positionLabelAlignment,
      markers: widget.markers,
      drawings: displayDrawings,
      selectedDrawingId: widget.selectedDrawingId,
      showDrawings: widget.showDrawings,
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
        _preparePainterGeometry(
          _painter,
          Size(constraints.maxWidth, baseDimension.mDisplayHeight),
        );
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (event) {
            _activePointerIds.add(event.pointer);
            _activePointerPositions[event.pointer] = event.localPosition;
            if (_activePointerIds.length >= 2) {
              if (_isDrawingInputActive || !_mainAxisAutoScale) {
                _beginManualPinch(baseDimension);
              } else {
                _prepareForScaleGesture();
              }
              return;
            }
            if (_beginDraftPreviewPointer(
              event.pointer,
              event.localPosition,
              _painter,
            )) {
              return;
            }
            if (_activePointerIds.length == 1 &&
                _beginDrawingDragIfNeeded(event.localPosition, _painter)) {
              return;
            }
            if (_activePointerIds.length == 1 &&
                _isMainPanePanStart(event.localPosition, baseDimension)) {
              _mainAxisPanPointer = event.pointer;
              _lastMainAxisPanPosition = event.localPosition;
            }
          },
          onPointerMove: (event) {
            _activePointerPositions[event.pointer] = event.localPosition;
            if (_manualPinchActive) {
              _updateManualPinch(baseDimension);
              return;
            }
            if (_drawingDragSession != null) {
              _updateDrawingDrag(event.localPosition, _painter);
              return;
            }
            if (_updateDraftPreviewPointerMove(
              event.pointer,
              event.localPosition,
              _painter,
            )) {
              return;
            }
            if (_updateDraftPreviewIfNeeded(event.localPosition, _painter)) {
              return;
            }
            if (event.pointer != _mainAxisPanPointer ||
                _activePointerIds.length != 1 ||
                isLongPress) {
              return;
            }
            final previous = _lastMainAxisPanPosition;
            _lastMainAxisPanPosition = event.localPosition;
            if (previous == null) return;
            _panMainAxisByDistance(event.localPosition.dy - previous.dy);
          },
          onPointerHover: (event) {
            _updateDraftPreviewIfNeeded(event.localPosition, _painter);
          },
          onPointerUp: (event) {
            _finishDraftPreviewPointerIfNeeded(event.pointer);
            _finishPointerTracking(event.pointer);
          },
          onPointerCancel: (event) {
            _clearDraftPreviewPointer(event.pointer);
            _finishPointerTracking(event.pointer);
          },
          child: GestureDetector(
            onTapUp: (details) {
              // if (!widget.isTrendLine && widget.onSecondaryTap != null && _painter.isInSecondaryRect(details.localPosition)) {
              //   widget.onSecondaryTap!();
              // }

              if (!widget.isTrendLine &&
                  _painter.isInMainRect(details.localPosition)) {
                isOnTap = true;
                if (_handleDrawingTap(details.localPosition, _painter)) {
                  return;
                }
                // hit test position chips/buttons first
                final hit =
                    _hitTestPosition(details.localPosition, _painter) ?? false;
                if (!hit && widget.drawingSelectionEnabled) {
                  final drawingHit =
                      _painter.hitTestDrawing(details.localPosition);
                  if (drawingHit != null) {
                    widget.onSelectedDrawingChanged?.call(drawingHit.drawingId);
                    return;
                  }
                  widget.onSelectedDrawingChanged?.call(null);
                }
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
                  lines
                      .add(TrendLine(a.p1, p1, trendLineMax!, trendLineScale!));
                  waitingForOtherPairOfCords = false;
                } else {
                  waitingForOtherPairOfCords = true;
                }
                notifyChanged();
              }
            },
            onHorizontalDragDown: (details) {
              if (_isDrawingInputActive) return;
              isOnTap = false;
              _stopAnimation();
            },
            onHorizontalDragUpdate: (details) {
              if (_isDrawingInputActive) return;
              if (isScale || isLongPress) return;
              if (!isDrag) {
                _onDragChanged(true);
              }
              mScrollX = ((details.primaryDelta ?? 0) / mScaleX + mScrollX)
                  .clamp(0.0, ChartPainter.maxScrollX)
                  .toDouble();
              notifyChanged();
            },
            onHorizontalDragEnd: (DragEndDetails details) {
              if (_isDrawingInputActive) return;
              var velocity = details.velocity.pixelsPerSecond.dx;
              _onFling(velocity);
            },
            onHorizontalDragCancel: () => _onDragChanged(false),
            onScaleStart: (details) {
              if (_isDrawingInputActive &&
                  details.pointerCount <= 1 &&
                  _activePointerIds.length < 2) {
                return;
              }
              isScale = true;
              _scaleStartScaleX = mScaleX;
              _scaleStartScrollX = mScrollX;
              _scaleStartFocalX = details.localFocalPoint.dx;
              if (details.pointerCount > 1) {
                _prepareForScaleGesture();
              }
              _scaleStartMainAxisRange = _mainAxisAutoScale
                  ? null
                  : _resolveCurrentMainAxisRange(mWidth);
              _scaleStartMainAxisAnchor = _mainAxisAutoScale
                  ? null
                  : _resolveMainAxisValueAt(
                      details.localFocalPoint.dy,
                      _scaleStartMainAxisRange,
                      baseDimension,
                    );
            },
            onScaleUpdate: (details) {
              if (_isDrawingInputActive &&
                  details.pointerCount <= 1 &&
                  _activePointerIds.length < 2) {
                return;
              }
              if (_manualPinchActive && !_mainAxisAutoScale) return;
              final bool isManualAxisZoom = !_mainAxisAutoScale &&
                  (details.pointerCount > 1 ||
                      (details.scale - 1.0).abs() > 0.001);
              if (isLongPress && !isManualAxisZoom) return;
              if (isManualAxisZoom && isLongPress) {
                _clearLongPressState();
              }
              if (isDrag) {
                final bool isZoomGesture = details.pointerCount > 1 ||
                    (details.scale - 1.0).abs() > 0.001;
                if (!isZoomGesture) return;
                _prepareForScaleGesture();
              }
              final double maxScaleX = _mainAxisAutoScale
                  ? _autoScaleMaxScaleX
                  : _manualAxisMaxScaleX;
              final double nextScaleX = (_scaleStartScaleX * details.scale)
                  .clamp(_minScaleX, maxScaleX);
              if (_mainAxisAutoScale) {
                mScaleX = nextScaleX;
              } else {
                mScaleX = nextScaleX;
                mScrollX = _resolveAnchoredScrollX(
                  startScaleX: _scaleStartScaleX,
                  startScrollX: _scaleStartScrollX,
                  nextScaleX: nextScaleX,
                  anchorX: details.localFocalPoint.dx.isFinite
                      ? details.localFocalPoint.dx
                      : _scaleStartFocalX,
                );
              }
              final startRange = _scaleStartMainAxisRange;
              if (!_mainAxisAutoScale &&
                  startRange != null &&
                  details.pointerCount > 1 &&
                  details.verticalScale.isFinite &&
                  details.verticalScale > 0) {
                final double anchorValue = _resolveMainAxisValueAt(
                      details.localFocalPoint.dy,
                      startRange,
                      baseDimension,
                    ) ??
                    _scaleStartMainAxisAnchor ??
                    startRange.center;
                _mainAxisRangeOverride = startRange
                    .scaleFromAnchor(anchorValue, 1 / details.verticalScale)
                    .normalized();
              }
              notifyChanged();
            },
            onScaleEnd: (_) {
              isScale = false;
              _scaleStartMainAxisRange = null;
              _scaleStartMainAxisAnchor = null;
            },
            onLongPressStart: (details) {
              if (_isDrawingInputActive) return;
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
              if (_isDrawingInputActive) return;
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
              if (_isDrawingInputActive) return;
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
                if (!_mainAxisAutoScale)
                  _buildMainAxisResetButton(baseDimension),
                if (_buildSelectedDrawingOverlay(_painter) case final overlay?)
                  overlay,
              ],
            ),
          ),
        );
      },
    );
  }

  List<ChartDrawingEntity> _displayDrawings() {
    final draft = _draftDrawing;
    if (draft == null || !widget.drawingEnabled) {
      return widget.drawings;
    }
    return <ChartDrawingEntity>[
      ...widget.drawings,
      _draftWithPreviewAnchor(draft),
    ];
  }

  ChartDrawingEntity _draftWithPreviewAnchor(ChartDrawingEntity draft) {
    final previewAnchor = _draftPreviewAnchor;
    if (previewAnchor == null ||
        _draftTool == ChartDrawingTool.none ||
        draft.anchors.length >= _requiredAnchorCount(_draftTool) ||
        (draft.anchors.isNotEmpty &&
            _sameDrawingAnchor(draft.anchors.last, previewAnchor))) {
      return draft;
    }

    return draft.copyWith(
      anchors: <ChartDrawingAnchor>[
        ...draft.anchors,
        previewAnchor,
      ],
    );
  }

  bool get _isDrawingInputActive =>
      (widget.drawingEnabled && widget.drawingTool != ChartDrawingTool.none) ||
      _drawingDragSession != null;

  bool _handleDrawingTap(Offset position, ChartPainter painter) {
    if (!widget.drawingEnabled ||
        widget.drawingTool == ChartDrawingTool.none ||
        widget.onDrawingsChanged == null) {
      return false;
    }

    final anchor = painter.drawingAnchorAt(
      position,
      tool: widget.drawingTool,
      magnetEnabled: widget.drawingMagnetEnabled,
    );
    if (anchor == null) {
      return true;
    }

    switch (widget.drawingTool) {
      case ChartDrawingTool.verticalLine:
      case ChartDrawingTool.horizontalLine:
        _createDrawing([anchor], widget.drawingTool);
        return true;
      case ChartDrawingTool.trendLine:
      case ChartDrawingTool.extendedLine:
      case ChartDrawingTool.ray:
      case ChartDrawingTool.rectangle:
      case ChartDrawingTool.parallelChannel:
        _handleMultiAnchorDrawingTap(anchor, widget.drawingTool);
        return true;
      case ChartDrawingTool.none:
        return false;
    }
  }

  void _handleMultiAnchorDrawingTap(
    ChartDrawingAnchor anchor,
    ChartDrawingTool tool,
  ) {
    final draft = _draftDrawing;
    if (draft == null || _draftTool != tool) {
      setState(() {
        _draftTool = tool;
        _draftDrawing = DrawingController.createDrawing(
          id: -1,
          tool: tool,
          anchors: <ChartDrawingAnchor>[anchor],
          style: widget.drawingStyle,
          locked: widget.drawingDefaultLocked,
        );
        _draftPreviewAnchor = anchor;
      });
      widget.onDrawingEvent?.call(
        ChartDrawingEvent(
          type: ChartDrawingEventType.createStarted,
          drawing: _draftDrawing,
        ),
      );
      return;
    }

    final anchors = <ChartDrawingAnchor>[...draft.anchors, anchor];
    if (anchors.length < _requiredAnchorCount(tool)) {
      setState(() {
        _draftDrawing = draft.copyWith(anchors: anchors);
        _draftPreviewAnchor = anchor;
      });
      return;
    }

    _createDrawing(anchors, tool);
    setState(() {
      _draftDrawing = null;
      _draftTool = ChartDrawingTool.none;
      _draftPreviewAnchor = null;
    });
  }

  bool _updateDraftPreviewIfNeeded(Offset position, ChartPainter painter) {
    final draft = _draftDrawing;
    if (!widget.drawingEnabled ||
        draft == null ||
        _draftTool == ChartDrawingTool.none ||
        draft.anchors.length >= _requiredAnchorCount(_draftTool)) {
      return false;
    }

    final anchor = painter.drawingAnchorAt(
      position,
      tool: _draftTool,
      magnetEnabled: widget.drawingMagnetEnabled,
    );
    if (anchor == null || _sameDrawingAnchor(anchor, _draftPreviewAnchor)) {
      return true;
    }

    setState(() {
      _draftPreviewAnchor = anchor;
    });
    return true;
  }

  bool _beginDraftPreviewPointer(
    int pointer,
    Offset position,
    ChartPainter painter,
  ) {
    if (_draftDrawing == null ||
        _draftTool == ChartDrawingTool.none ||
        !_updateDraftPreviewIfNeeded(position, painter)) {
      return false;
    }

    _draftPreviewPointer = pointer;
    _draftPreviewPointerDownPosition = position;
    _draftPreviewPointerMoved = false;
    return true;
  }

  bool _updateDraftPreviewPointerMove(
    int pointer,
    Offset position,
    ChartPainter painter,
  ) {
    if (_draftPreviewPointer != pointer) {
      return false;
    }

    final downPosition = _draftPreviewPointerDownPosition;
    if (downPosition != null && (position - downPosition).distance > 2.0) {
      _draftPreviewPointerMoved = true;
    }
    _updateDraftPreviewIfNeeded(position, painter);
    return true;
  }

  void _finishDraftPreviewPointerIfNeeded(int pointer) {
    if (_draftPreviewPointer != pointer) {
      return;
    }

    final anchor = _draftPreviewAnchor;
    final tool = _draftTool;
    final lastAnchor = _draftDrawing?.anchors.isEmpty == false
        ? _draftDrawing!.anchors.last
        : null;
    final shouldCommit = _draftPreviewPointerMoved &&
        anchor != null &&
        tool != ChartDrawingTool.none &&
        !_sameDrawingAnchor(lastAnchor, anchor);
    _clearDraftPreviewPointer(pointer);
    if (shouldCommit) {
      _handleMultiAnchorDrawingTap(anchor, tool);
    }
  }

  void _clearDraftPreviewPointer(int pointer) {
    if (_draftPreviewPointer != pointer) {
      return;
    }

    _draftPreviewPointer = null;
    _draftPreviewPointerDownPosition = null;
    _draftPreviewPointerMoved = false;
  }

  bool _sameDrawingAnchor(ChartDrawingAnchor? a, ChartDrawingAnchor? b) {
    return a?.time == b?.time &&
        a?.price == b?.price &&
        a?.dataIndex == b?.dataIndex;
  }

  void _createDrawing(
    List<ChartDrawingAnchor> anchors,
    ChartDrawingTool tool,
  ) {
    final drawing = DrawingController.createDrawing(
      id: DrawingController.nextDrawingId(widget.drawings),
      tool: tool,
      anchors: anchors,
      style: widget.drawingStyle,
      locked: widget.drawingDefaultLocked,
    );
    final drawings = DrawingController.appendDrawing(widget.drawings, drawing);
    widget.onDrawingsChanged?.call(drawings);
    widget.onSelectedDrawingChanged?.call(drawing.id);
    widget.onDrawingEvent?.call(
      ChartDrawingEvent(
        type: ChartDrawingEventType.created,
        drawing: drawing,
        drawingId: drawing.id,
      ),
    );
  }

  bool _beginDrawingDragIfNeeded(Offset position, ChartPainter painter) {
    if (_isDrawingInputActive ||
        !widget.drawingSelectionEnabled ||
        widget.onDrawingsChanged == null) {
      return false;
    }

    final hit = painter.hitTestDrawing(position);
    if (hit == null) {
      return false;
    }

    final drawing =
        DrawingController.drawingById(widget.drawings, hit.drawingId);
    final startAnchor = painter.drawingAnchorAt(
      position,
      tool: drawing?.type ?? ChartDrawingTool.none,
      magnetEnabled: widget.drawingMagnetEnabled,
    );
    if (drawing == null || drawing.locked || startAnchor == null) {
      return false;
    }

    widget.onSelectedDrawingChanged?.call(drawing.id);
    _drawingDragSession = DrawingDragSession(
      drawingId: hit.drawingId,
      kind: hit.kind,
      handleIndex: hit.handleIndex,
      startPoint: position,
      startAnchor: startAnchor,
      startDrawings: widget.drawings,
    );
    _stopAnimation(needNotify: false);
    _clearLongPressState();
    return true;
  }

  void _updateDrawingDrag(Offset position, ChartPainter painter) {
    final session = _drawingDragSession;
    if (session == null || widget.onDrawingsChanged == null) {
      return;
    }

    final drawing = DrawingController.drawingById(
      session.startDrawings,
      session.drawingId,
    );
    if (drawing == null || drawing.locked) {
      return;
    }

    final currentAnchor = painter.drawingAnchorAt(
      position,
      tool: drawing.type,
      magnetEnabled: widget.drawingMagnetEnabled,
    );
    if (currentAnchor == null) {
      return;
    }

    final ChartDrawingEntity updated;
    switch (session.kind) {
      case DrawingHitTestKind.handle:
        updated = DrawingController.replaceAnchor(
          drawing: drawing,
          handleIndex: session.handleIndex ?? 0,
          anchor: currentAnchor,
        );
        break;
      case DrawingHitTestKind.body:
        updated = DrawingController.moveDrawing(
          drawing: drawing,
          deltaTime: currentAnchor.time - session.startAnchor.time,
          deltaPrice: currentAnchor.price - session.startAnchor.price,
        );
        break;
    }

    final drawings = DrawingController.updateDrawing(
      session.startDrawings,
      updated,
    );
    widget.onDrawingsChanged?.call(drawings);
    widget.onDrawingEvent?.call(
      ChartDrawingEvent(
        type: ChartDrawingEventType.updated,
        drawing: updated,
        drawingId: updated.id,
      ),
    );
  }

  bool _isMainPanePanStart(Offset position, BaseDimension baseDimension) {
    if (_mainAxisAutoScale || widget.isTrendLine) return false;
    final double top =
        widget.chartStyle.topPadding + baseDimension.totalLabelHeight;
    final double height = _resolveMainRectHeight(baseDimension);
    final Rect mainRect = Rect.fromLTWH(0, top, mWidth, height);
    if (!mainRect.contains(position)) return false;

    const double axisWidth = 56;
    if (widget.verticalTextAlignment == VerticalTextAlignment.left) {
      return position.dx > axisWidth;
    }
    return position.dx < mWidth - axisWidth;
  }

  void _finishPointerTracking(int pointer) {
    _activePointerIds.remove(pointer);
    _activePointerPositions.remove(pointer);
    if (_mainAxisPanPointer == pointer) {
      _mainAxisPanPointer = null;
      _lastMainAxisPanPosition = null;
    }
    if (_drawingDragSession != null) {
      _drawingDragSession = null;
    }
    if (_manualPinchActive && _activePointerPositions.length < 2) {
      isScale = false;
      _resetManualPinchState();
    }
    if (_activePointerIds.isEmpty) {
      _mainAxisPanPointer = null;
      _lastMainAxisPanPosition = null;
      _activePointerPositions.clear();
      _resetManualPinchState();
    }
  }

  Widget? _buildSelectedDrawingOverlay(ChartPainter painter) {
    final builder = widget.selectedDrawingOverlayBuilder;
    final selectedId = widget.selectedDrawingId;
    if (builder == null || selectedId == null) {
      return null;
    }

    ChartDrawingEntity? selectedDrawing;
    for (final drawing in widget.drawings) {
      if (drawing.id == selectedId) {
        selectedDrawing = drawing;
        break;
      }
    }
    if (selectedDrawing == null ||
        selectedDrawing.hidden ||
        selectedDrawing.type == ChartDrawingTool.none) {
      return null;
    }

    final bounds = painter.drawingBounds(selectedDrawing);
    if (bounds == null) {
      return null;
    }

    return builder(context, selectedDrawing, bounds);
  }

  void _preparePainterGeometry(ChartPainter painter, Size size) {
    painter.mDisplayHeight =
        size.height - painter.mTopPadding - painter.mBottomPadding;
    painter.mWidth = size.width;
    painter.initRect(size);
    painter.calculateValue();
  }

  int _requiredAnchorCount(ChartDrawingTool tool) {
    switch (tool) {
      case ChartDrawingTool.horizontalLine:
      case ChartDrawingTool.verticalLine:
        return 1;
      case ChartDrawingTool.trendLine:
      case ChartDrawingTool.extendedLine:
      case ChartDrawingTool.ray:
      case ChartDrawingTool.rectangle:
        return 2;
      case ChartDrawingTool.parallelChannel:
        return 3;
      case ChartDrawingTool.none:
        return 0;
    }
  }

  void _beginManualPinch(BaseDimension baseDimension) {
    final points = _firstTwoPointerPositions();
    if (points == null) return;
    _prepareForScaleGesture();
    isScale = true;
    _manualPinchActive = true;
    _manualPinchStartDistance = _distance(points.$1, points.$2);
    _manualPinchStartVerticalDistance = (points.$1.dy - points.$2.dy).abs();
    _manualPinchStartScaleX = mScaleX;
    _manualPinchStartScrollX = mScrollX;
    _manualPinchStartRange = _resolveCurrentMainAxisRange(mWidth);
    _scaleStartMainAxisRange = _manualPinchStartRange;
    final midpoint = _midpoint(points.$1, points.$2);
    _scaleStartMainAxisAnchor = _resolveMainAxisValueAt(
        midpoint.dy, _manualPinchStartRange, baseDimension);
  }

  void _updateManualPinch(BaseDimension baseDimension) {
    final points = _firstTwoPointerPositions();
    final startRange = _manualPinchStartRange;
    if (points == null ||
        startRange == null ||
        _manualPinchStartDistance <= 0) {
      return;
    }

    final midpoint = _midpoint(points.$1, points.$2);
    final double distance = _distance(points.$1, points.$2);
    if (distance <= 0) return;
    final double scale = distance / _manualPinchStartDistance;
    final double nextScaleX = (_manualPinchStartScaleX * scale)
        .clamp(_minScaleX, _manualAxisMaxScaleX);
    mScaleX = nextScaleX;
    mScrollX = _resolveAnchoredScrollX(
      startScaleX: _manualPinchStartScaleX,
      startScrollX: _manualPinchStartScrollX,
      nextScaleX: nextScaleX,
      anchorX: midpoint.dx,
    );

    final double verticalDistance = (points.$1.dy - points.$2.dy).abs();
    if (!_mainAxisAutoScale &&
        _manualPinchStartVerticalDistance > 0 &&
        verticalDistance > 0) {
      final double verticalScale =
          verticalDistance / _manualPinchStartVerticalDistance;
      final double anchorValue =
          _resolveMainAxisValueAt(midpoint.dy, startRange, baseDimension) ??
              _scaleStartMainAxisAnchor ??
              startRange.center;
      _mainAxisRangeOverride = startRange
          .scaleFromAnchor(anchorValue, 1 / verticalScale)
          .normalized();
    }
    notifyChanged();
  }

  (Offset, Offset)? _firstTwoPointerPositions() {
    if (_activePointerPositions.length < 2) return null;
    final values =
        _activePointerPositions.values.take(2).toList(growable: false);
    return (values[0], values[1]);
  }

  Offset _midpoint(Offset first, Offset second) {
    return Offset((first.dx + second.dx) / 2, (first.dy + second.dy) / 2);
  }

  double _distance(Offset first, Offset second) {
    final dx = first.dx - second.dx;
    final dy = first.dy - second.dy;
    return sqrt(dx * dx + dy * dy);
  }

  void _resetManualPinchState() {
    _manualPinchActive = false;
    _manualPinchStartDistance = 0.0;
    _manualPinchStartVerticalDistance = 0.0;
    _manualPinchStartScaleX = _defaultScaleX;
    _manualPinchStartScrollX = 0.0;
    _manualPinchStartRange = null;
  }

  void _prepareForScaleGesture() {
    _stopAnimation(needNotify: false);
    if (isDrag) {
      _onDragChanged(false);
    }
    _clearLongPressState();
    _axisDragStartRange = null;
    _axisDragStartY = null;
    _mainAxisPanPointer = null;
    _lastMainAxisPanPosition = null;
    isOnTap = false;
  }

  void _prepareForAxisDrag() {
    _stopAnimation(needNotify: false);
    if (isDrag) {
      _onDragChanged(false);
    }
    if (isScale) {
      isScale = false;
    }
    _clearLongPressState();
    _mainAxisPanPointer = null;
    _lastMainAxisPanPosition = null;
    isOnTap = false;
  }

  void _clearLongPressState() {
    if (!isLongPress) return;
    isLongPress = false;
    mInfoWindowStream.sink.add(null);
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
          _prepareForAxisDrag();
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
    const double axisWidth = 56;
    const double buttonWidth = 28;
    final double top =
        widget.chartStyle.topPadding + baseDimension.totalLabelHeight + 4;
    return Positioned(
      top: top,
      left: isLeftAxis ? axisWidth : null,
      right: isLeftAxis ? null : axisWidth,
      width: buttonWidth,
      height: 24,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _resetMainAxisScale,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _resolveResetButtonBackgroundColor(),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            Icons.double_arrow,
            size: 16,
            color: _resolveResetButtonIconColor(),
          ),
        ),
      ),
    );
  }

  bool get _isDarkChartBackground =>
      widget.chartColors.bgColor.computeLuminance() < 0.5;

  Color _resolveResetButtonBackgroundColor() {
    return (_isDarkChartBackground ? Colors.white : Colors.black)
        .withValues(alpha: _isDarkChartBackground ? 0.18 : 0.08);
  }

  Color _resolveResetButtonIconColor() {
    return (_isDarkChartBackground ? Colors.white : Colors.black)
        .withValues(alpha: _isDarkChartBackground ? 0.86 : 0.72);
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

  double? _resolveMainAxisValueAt(
    double y,
    MainAxisRange? range,
    BaseDimension baseDimension,
  ) {
    if (range == null || !range.isValid || !y.isFinite) return null;
    final double top =
        widget.chartStyle.topPadding + baseDimension.totalLabelHeight;
    final double height = max(1.0, _resolveMainRectHeight(baseDimension));
    final double ratio = ((y - top) / height).clamp(0.0, 1.0).toDouble();
    return range.max - range.span * ratio;
  }

  double _resolveAnchoredScrollX({
    required double startScaleX,
    required double startScrollX,
    required double nextScaleX,
    required double anchorX,
  }) {
    final data = widget.datas;
    if (data == null ||
        data.isEmpty ||
        mWidth <= 0 ||
        startScaleX <= 0 ||
        nextScaleX <= 0 ||
        !anchorX.isFinite) {
      return mScrollX;
    }

    final double startMinTranslateX = _resolveMinTranslateX(startScaleX);
    final double startTranslateX = startScrollX + startMinTranslateX;
    final double anchoredDataX = -startTranslateX + anchorX / startScaleX;
    final double nextMinTranslateX = _resolveMinTranslateX(nextScaleX);
    final double nextTranslateX = -anchoredDataX + anchorX / nextScaleX;
    final double maxScrollX = nextMinTranslateX.abs();
    return (nextTranslateX - nextMinTranslateX)
        .clamp(0.0, maxScrollX)
        .toDouble();
  }

  double _resolveMinTranslateX(double scaleX) {
    final data = widget.datas;
    if (data == null || data.isEmpty || scaleX <= 0) return 0.0;
    final double dataLen = data.length * widget.chartStyle.pointWidth;
    final double x = -dataLen +
        mWidth / scaleX -
        widget.chartStyle.pointWidth / 2 -
        widget.xFrontPadding;
    return x >= 0 ? 0.0 : x;
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
      _stopAnimation(needNotify: false);
      if (isDrag) {
        _onDragChanged(false);
      }
      mScaleX = _defaultScaleX;
      mScrollX = 0.0;
      mSelectX = 0.0;
      _mainAxisAutoScale = true;
      _mainAxisRangeOverride = null;
      _axisDragStartRange = null;
      _axisDragStartY = null;
      _scaleStartMainAxisRange = null;
      _scaleStartMainAxisAnchor = null;
      _scaleStartScaleX = _defaultScaleX;
      _scaleStartScrollX = 0.0;
      _scaleStartFocalX = 0.0;
      _resetManualPinchState();
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
              priceLabelTickSize: widget.priceLabelTickSize,
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
            priceLabelTickSize: widget.priceLabelTickSize,
          ),
        );
      },
    );
  }
}
