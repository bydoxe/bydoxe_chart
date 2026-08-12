import 'package:bydoxe_chart/k_chart_plus.dart';
import 'package:bydoxe_chart/renderer/main_axis_range.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('builds with horizontal, scale, and axis gesture layers',
      (tester) async {
    await _pumpChart(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('loads the bundled candle pane logo asset', (tester) async {
    await _pumpChart(tester);
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();

    final logo = _currentChartPainter(tester).candlePaneLogo;
    expect(logo, isNotNull);
    expect(logo!.width, 2815);
    expect(logo.height, 609);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pans the main axis after auto scale is disabled',
      (tester) async {
    await _pumpChart(tester);

    await tester.dragFrom(const Offset(20, 180), const Offset(0, 80));
    await tester.pump();
    final axisScaledRange = _currentMainAxisRange(tester);
    expect(axisScaledRange, isNotNull);

    await tester.dragFrom(const Offset(180, 180), const Offset(0, 60));
    await tester.pump();
    final pannedRange = _currentMainAxisRange(tester);

    expect(pannedRange, isNotNull);
    expect(pannedRange!.min, isNot(axisScaledRange!.min));
    expect(pannedRange.max, isNot(axisScaledRange.max));
    expect(tester.takeException(), isNull);
  });

  testWidgets('resets manual axis scale, zoom, and scroll to defaults',
      (tester) async {
    await _pumpChart(tester);

    await tester.dragFrom(const Offset(20, 180), const Offset(0, 80));
    await tester.pump();
    expect(_currentMainAxisRange(tester), isNotNull);

    final chartGesture = _chartScaleGesture(tester);
    chartGesture.onScaleStart!(
      ScaleStartDetails(
        focalPoint: const Offset(160, 200),
        localFocalPoint: const Offset(160, 200),
        pointerCount: 2,
      ),
    );
    chartGesture.onScaleUpdate!(
      ScaleUpdateDetails(
        focalPoint: const Offset(160, 200),
        localFocalPoint: const Offset(160, 200),
        scale: 10,
        pointerCount: 2,
      ),
    );
    chartGesture.onScaleEnd!(ScaleEndDetails());
    await tester.pump();

    expect(_currentScaleX(tester), 5.0);

    await tester.dragFrom(const Offset(180, 220), const Offset(80, 0));
    await tester.pump();
    expect(_currentScrollX(tester), greaterThan(0));

    await tester.tap(find.byIcon(Icons.double_arrow));
    await tester.pump();

    expect(_currentMainAxisRange(tester), isNull);
    expect(_currentScaleX(tester), 1.0);
    expect(_currentScrollX(tester), 0.0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('places manual axis reset button below summary by the price axis',
      (tester) async {
    await _pumpChart(
      tester,
      verticalTextAlignment: VerticalTextAlignment.right,
    );

    _disableAutoScale(tester);
    await tester.pump();

    final buttonFinder = find.byIcon(Icons.double_arrow);
    expect(buttonFinder, findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsNothing);

    final positioned = tester.widget<Positioned>(
      find.ancestor(of: buttonFinder, matching: find.byType(Positioned)).first,
    );
    expect(positioned.top, 36);
    expect(positioned.right, 56);
    expect(positioned.width, 28);
    expect(positioned.height, 24);

    final decoratedBox = tester.widget<DecoratedBox>(
      find
          .ancestor(of: buttonFinder, matching: find.byType(DecoratedBox))
          .first,
    );
    final decoration = decoratedBox.decoration as BoxDecoration;
    expect(decoration.border, isNull);
    expect(decoration.color?.a, closeTo(0.08, 0.01));
    expect(decoration.color?.r, closeTo(0.0, 0.01));
    expect(decoration.color?.g, closeTo(0.0, 0.01));
    expect(decoration.color?.b, closeTo(0.0, 0.01));
  });

  testWidgets('uses a light reset button background on dark charts',
      (tester) async {
    await _pumpChart(
      tester,
      chartColors: ChartColors(bgColor: const Color(0xff000000)),
    );

    _disableAutoScale(tester);
    await tester.pump();

    final decoratedBox = tester.widget<DecoratedBox>(
      find
          .ancestor(
              of: find.byIcon(Icons.double_arrow),
              matching: find.byType(DecoratedBox))
          .first,
    );
    final decoration = decoratedBox.decoration as BoxDecoration;
    expect(decoration.color?.a, closeTo(0.18, 0.01));
    expect(decoration.color?.r, closeTo(1.0, 0.01));
    expect(decoration.color?.g, closeTo(1.0, 0.01));
    expect(decoration.color?.b, closeTo(1.0, 0.01));
  });

  testWidgets('manual pinch zoom keeps the focal point anchored',
      (tester) async {
    await _pumpChart(tester, dataCount: 80);
    _disableAutoScale(tester);
    await tester.pump();

    const focalPoint = Offset(160, 200);
    final beforePainter = _currentChartPainter(tester);
    final beforeRange = _currentMainAxisRange(tester)!;
    final beforeDataX = _dataXAt(
      x: focalPoint.dx,
      scaleX: _currentScaleX(tester),
      scrollX: _currentScrollX(tester),
      dataCount: 80,
      width: beforePainter.mWidth,
    );
    final beforeAnchorValue = _mainAxisValueAt(
      focalPoint.dy,
      beforeRange,
      beforePainter.mMainRect,
    );

    final chartGesture = _chartScaleGesture(tester);
    chartGesture.onScaleStart!(
      ScaleStartDetails(
        focalPoint: focalPoint,
        localFocalPoint: focalPoint,
        pointerCount: 2,
      ),
    );
    chartGesture.onScaleUpdate!(
      ScaleUpdateDetails(
        focalPoint: focalPoint,
        localFocalPoint: focalPoint,
        scale: 2,
        verticalScale: 2,
        pointerCount: 2,
      ),
    );
    chartGesture.onScaleEnd!(ScaleEndDetails());
    await tester.pump();

    final afterPainter = _currentChartPainter(tester);
    final afterRange = _currentMainAxisRange(tester)!;
    final afterDataX = _dataXAt(
      x: focalPoint.dx,
      scaleX: _currentScaleX(tester),
      scrollX: _currentScrollX(tester),
      dataCount: 80,
      width: afterPainter.mWidth,
    );
    final afterAnchorValue = _mainAxisValueAt(
      focalPoint.dy,
      afterRange,
      afterPainter.mMainRect,
    );

    expect(_currentScaleX(tester), 2.0);
    expect(afterDataX, closeTo(beforeDataX, 0.001));
    expect(afterAnchorValue, closeTo(beforeAnchorValue, 0.001));
  });

  testWidgets('renders trade markers while zoomed without scaling errors',
      (tester) async {
    await _pumpChart(
      tester,
      dataCount: 80,
      markers: const [
        PositionMarkerEntity(
          id: 1,
          time: 1000 + 78 * 60000,
          type: MarkerType.buy,
          color: Color(0xff123456),
        ),
      ],
    );

    final chartGesture = _chartScaleGesture(tester);
    chartGesture.onScaleStart!(
      ScaleStartDetails(
        focalPoint: const Offset(160, 200),
        localFocalPoint: const Offset(160, 200),
        pointerCount: 2,
      ),
    );
    chartGesture.onScaleUpdate!(
      ScaleUpdateDetails(
        focalPoint: const Offset(160, 200),
        localFocalPoint: const Offset(160, 200),
        scale: 2,
        pointerCount: 2,
      ),
    );
    chartGesture.onScaleEnd!(ScaleEndDetails());
    await tester.pump();

    expect(_currentScaleX(tester), 2.0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('builds with display-only chart drawings', (tester) async {
    await _pumpChart(
      tester,
      drawings: const [
        ChartDrawingEntity(
          id: 1,
          type: ChartDrawingTool.trendLine,
          anchors: [
            ChartDrawingAnchor(time: 1000, price: 100),
            ChartDrawingAnchor(time: 1000 + 5 * 60000, price: 106),
          ],
          style: ChartDrawingStyle(strokeWidth: 2),
        ),
        ChartDrawingEntity(
          id: 2,
          type: ChartDrawingTool.horizontalLine,
          anchors: [
            ChartDrawingAnchor(time: 1000, price: 104),
          ],
        ),
        ChartDrawingEntity(
          id: 3,
          type: ChartDrawingTool.rectangle,
          anchors: [
            ChartDrawingAnchor(time: 1000 + 2 * 60000, price: 102),
            ChartDrawingAnchor(time: 1000 + 6 * 60000, price: 108),
          ],
          style: ChartDrawingStyle(fillColor: Color(0x22123456)),
        ),
      ],
      selectedDrawingId: 1,
    );

    expect(_currentChartPainter(tester).drawings, hasLength(3));
    expect(_currentChartPainter(tester).selectedDrawingId, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('builds selected drawing overlay from chart bounds',
      (tester) async {
    Rect? overlayBounds;
    Rect? overlayChartBounds;
    await _pumpChart(
      tester,
      drawings: const [
        ChartDrawingEntity(
          id: 1,
          type: ChartDrawingTool.trendLine,
          anchors: [
            ChartDrawingAnchor(time: 1000, price: 100),
            ChartDrawingAnchor(time: 1000 + 5 * 60000, price: 106),
          ],
        ),
      ],
      selectedDrawingId: 1,
      selectedDrawingOverlayBuilder: (context, drawing, bounds, chartBounds) {
        overlayBounds = bounds;
        overlayChartBounds = chartBounds;
        return const Positioned(
          left: 0,
          top: 0,
          child: SizedBox(key: Key('drawing-overlay'), width: 10, height: 10),
        );
      },
    );

    expect(find.byKey(const Key('drawing-overlay')), findsOneWidget);
    expect(overlayBounds, isNotNull);
    expect(overlayBounds!.width, greaterThan(0));
    expect(overlayBounds!.height, greaterThan(0));
    expect(overlayChartBounds, isNotNull);
    expect(overlayChartBounds!.width, greaterThan(overlayBounds!.width));
    expect(tester.takeException(), isNull);
  });

  testWidgets('calls selected drawing callback when drawing is tapped',
      (tester) async {
    int? selectedId;
    await _pumpChart(
      tester,
      drawings: const [
        ChartDrawingEntity(
          id: 11,
          type: ChartDrawingTool.horizontalLine,
          anchors: [
            ChartDrawingAnchor(time: 1000, price: 104),
          ],
        ),
      ],
      drawingSelectionEnabled: true,
      onSelectedDrawingChanged: (id) => selectedId = id,
    );

    final painter = _currentChartPainter(tester);
    await tester
        .tapAt(Offset(painter.mMainRect.center.dx, painter.getMainY(104)));
    await tester.pump();

    expect(selectedId, 11);
    expect(tester.takeException(), isNull);
  });

  testWidgets('calls selected drawing callback with null for empty tap',
      (tester) async {
    var callbackCalled = false;
    int? selectedId = 99;
    await _pumpChart(
      tester,
      drawings: const [
        ChartDrawingEntity(
          id: 11,
          type: ChartDrawingTool.horizontalLine,
          anchors: [
            ChartDrawingAnchor(time: 1000, price: 104),
          ],
        ),
      ],
      drawingSelectionEnabled: true,
      onSelectedDrawingChanged: (id) {
        callbackCalled = true;
        selectedId = id;
      },
    );

    final painter = _currentChartPainter(tester);
    await tester
        .tapAt(Offset(painter.mMainRect.center.dx, painter.getMainY(110)));
    await tester.pump();

    expect(callbackCalled, isTrue);
    expect(selectedId, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('creates horizontal line drawing from one tap', (tester) async {
    List<ChartDrawingEntity>? changedDrawings;
    await _pumpChart(
      tester,
      drawingEnabled: true,
      drawingTool: ChartDrawingTool.horizontalLine,
      onDrawingsChanged: (drawings) => changedDrawings = drawings,
    );

    final painter = _currentChartPainter(tester);
    await tester
        .tapAt(Offset(painter.mMainRect.center.dx, painter.getMainY(104)));
    await tester.pump();

    expect(changedDrawings, hasLength(1));
    expect(changedDrawings!.single.type, ChartDrawingTool.horizontalLine);
    expect(changedDrawings!.single.anchors, hasLength(1));
    expect(changedDrawings!.single.anchors.single.price, closeTo(104, 0.05));
    expect(tester.takeException(), isNull);
  });

  testWidgets('creates trend line drawing from two taps', (tester) async {
    List<ChartDrawingEntity>? changedDrawings;
    await _pumpChart(
      tester,
      drawingEnabled: true,
      drawingTool: ChartDrawingTool.trendLine,
      onDrawingsChanged: (drawings) => changedDrawings = drawings,
    );

    final painter = _currentChartPainter(tester);
    await tester.tapAt(Offset(80, painter.getMainY(102)));
    await tester.pump();
    expect(changedDrawings, isNull);

    await tester.tapAt(Offset(160, painter.getMainY(106)));
    await tester.pump();

    expect(changedDrawings, hasLength(1));
    expect(changedDrawings!.single.type, ChartDrawingTool.trendLine);
    expect(changedDrawings!.single.anchors, hasLength(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('creates rectangle drawing from two taps', (tester) async {
    List<ChartDrawingEntity>? changedDrawings;
    await _pumpChart(
      tester,
      drawingEnabled: true,
      drawingTool: ChartDrawingTool.rectangle,
      onDrawingsChanged: (drawings) => changedDrawings = drawings,
    );

    final painter = _currentChartPainter(tester);
    await tester.tapAt(Offset(80, painter.getMainY(102)));
    await tester.pump();
    await tester.tapAt(Offset(160, painter.getMainY(106)));
    await tester.pump();

    expect(changedDrawings, hasLength(1));
    expect(changedDrawings!.single.type, ChartDrawingTool.rectangle);
    expect(changedDrawings!.single.anchors, hasLength(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('creates vertical line drawing from one tap', (tester) async {
    List<ChartDrawingEntity>? changedDrawings;
    await _pumpChart(
      tester,
      drawingEnabled: true,
      drawingTool: ChartDrawingTool.verticalLine,
      onDrawingsChanged: (drawings) => changedDrawings = drawings,
    );

    final painter = _currentChartPainter(tester);
    await tester
        .tapAt(Offset(painter.mMainRect.center.dx, painter.getMainY(104)));
    await tester.pump();

    expect(changedDrawings, hasLength(1));
    expect(changedDrawings!.single.type, ChartDrawingTool.verticalLine);
    expect(changedDrawings!.single.anchors, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('creates parallel channel drawing from three taps',
      (tester) async {
    List<ChartDrawingEntity>? changedDrawings;
    await _pumpChart(
      tester,
      drawingEnabled: true,
      drawingTool: ChartDrawingTool.parallelChannel,
      onDrawingsChanged: (drawings) => changedDrawings = drawings,
    );

    final painter = _currentChartPainter(tester);
    await tester.tapAt(Offset(80, painter.getMainY(102)));
    await tester.pump();
    await tester.tapAt(Offset(160, painter.getMainY(106)));
    await tester.pump();
    expect(changedDrawings, isNull);

    await tester.tapAt(Offset(80, painter.getMainY(108)));
    await tester.pump();

    expect(changedDrawings, hasLength(1));
    expect(changedDrawings!.single.type, ChartDrawingTool.parallelChannel);
    expect(changedDrawings!.single.anchors, hasLength(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected handle drag updates drawing anchor', (tester) async {
    List<ChartDrawingEntity>? changedDrawings;
    const drawing = ChartDrawingEntity(
      id: 7,
      type: ChartDrawingTool.trendLine,
      anchors: [
        ChartDrawingAnchor(time: 1000 + 6 * 60000, price: 104),
        ChartDrawingAnchor(time: 1000 + 7 * 60000, price: 106),
      ],
    );
    await _pumpChart(
      tester,
      drawings: const [drawing],
      selectedDrawingId: 7,
      drawingSelectionEnabled: true,
      onDrawingsChanged: (drawings) => changedDrawings = drawings,
    );

    final painter = _currentChartPainter(tester);
    await tester.dragFrom(
      Offset(65, painter.getMainY(104)),
      const Offset(20, -20),
    );
    await tester.pump();

    expect(changedDrawings, hasLength(1));
    final updated = changedDrawings!.single;
    expect(updated.anchors.first.time, isNot(drawing.anchors.first.time));
    expect(
        updated.anchors.first.price, greaterThan(drawing.anchors.first.price));
    expect(tester.takeException(), isNull);
  });

  testWidgets('selected body drag moves all drawing anchors', (tester) async {
    List<ChartDrawingEntity>? changedDrawings;
    const drawing = ChartDrawingEntity(
      id: 8,
      type: ChartDrawingTool.trendLine,
      anchors: [
        ChartDrawingAnchor(time: 1000 + 6 * 60000, price: 104),
        ChartDrawingAnchor(time: 1000 + 7 * 60000, price: 106),
      ],
    );
    await _pumpChart(
      tester,
      drawings: const [drawing],
      selectedDrawingId: 8,
      drawingSelectionEnabled: true,
      onDrawingsChanged: (drawings) => changedDrawings = drawings,
    );

    final painter = _currentChartPainter(tester);
    await tester.dragFrom(
      Offset(70, painter.getMainY(105)),
      const Offset(20, -20),
    );
    await tester.pump();

    expect(changedDrawings, hasLength(1));
    final updated = changedDrawings!.single;
    expect(updated.anchors.first.time, isNot(drawing.anchors.first.time));
    expect(updated.anchors.last.time, isNot(drawing.anchors.last.time));
    expect(
        updated.anchors.first.price, greaterThan(drawing.anchors.first.price));
    expect(updated.anchors.last.price, greaterThan(drawing.anchors.last.price));
    expect(tester.takeException(), isNull);
  });

  testWidgets('two finger pinch still zooms while drawing mode is on',
      (tester) async {
    await _pumpChart(
      tester,
      dataCount: 80,
      drawingEnabled: true,
      drawingTool: ChartDrawingTool.trendLine,
      onDrawingsChanged: (_) {},
    );

    await _pinchWithPointers(
      tester,
      startA: const Offset(130, 210),
      startB: const Offset(190, 210),
      endA: const Offset(90, 210),
      endB: const Offset(230, 210),
    );

    expect(_currentScaleX(tester), greaterThan(1.0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('locked drawing does not move', (tester) async {
    List<ChartDrawingEntity>? changedDrawings;
    const drawing = ChartDrawingEntity(
      id: 9,
      type: ChartDrawingTool.trendLine,
      anchors: [
        ChartDrawingAnchor(time: 1000 + 6 * 60000, price: 104),
        ChartDrawingAnchor(time: 1000 + 7 * 60000, price: 106),
      ],
      locked: true,
    );
    await _pumpChart(
      tester,
      drawings: const [drawing],
      selectedDrawingId: 9,
      drawingSelectionEnabled: true,
      onDrawingsChanged: (drawings) => changedDrawings = drawings,
    );

    final painter = _currentChartPainter(tester);
    await tester.dragFrom(
      Offset(65, painter.getMainY(104)),
      const Offset(20, -20),
    );
    await tester.pump();

    expect(changedDrawings, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('manual pinch zoom works after pan reset and axis readjustment',
      (tester) async {
    await _pumpChart(tester, dataCount: 80);

    _disableAutoScale(tester);
    await tester.pump();
    final chartGesture = _chartScaleGesture(tester);
    chartGesture.onScaleStart!(
      ScaleStartDetails(
        focalPoint: const Offset(160, 200),
        localFocalPoint: const Offset(160, 200),
        pointerCount: 2,
      ),
    );
    chartGesture.onScaleUpdate!(
      ScaleUpdateDetails(
        focalPoint: const Offset(160, 200),
        localFocalPoint: const Offset(160, 200),
        scale: 2,
        verticalScale: 2,
        pointerCount: 2,
      ),
    );
    chartGesture.onScaleEnd!(ScaleEndDetails());
    await tester.pump();
    expect(_currentScaleX(tester), 2.0);

    await tester.tap(find.byIcon(Icons.double_arrow));
    await tester.pump();
    expect(_currentScaleX(tester), 1.0);
    expect(_currentMainAxisRange(tester), isNull);

    final horizontalGesture = _horizontalDragGesture(tester);
    horizontalGesture.onHorizontalDragUpdate!(
      DragUpdateDetails(
        globalPosition: const Offset(220, 200),
        localPosition: const Offset(220, 200),
        delta: const Offset(120, 0),
        primaryDelta: 120,
      ),
    );
    await tester.pump();
    expect(_currentScrollX(tester), greaterThan(0));

    _disableAutoScale(tester);
    await tester.pump();
    final readjustedRange = _currentMainAxisRange(tester);
    expect(readjustedRange, isNotNull);

    chartGesture.onScaleStart!(
      ScaleStartDetails(
        focalPoint: const Offset(160, 200),
        localFocalPoint: const Offset(160, 200),
        pointerCount: 2,
      ),
    );
    chartGesture.onScaleUpdate!(
      ScaleUpdateDetails(
        focalPoint: const Offset(160, 200),
        localFocalPoint: const Offset(160, 200),
        scale: 2,
        verticalScale: 2,
        pointerCount: 2,
      ),
    );
    chartGesture.onScaleEnd!(ScaleEndDetails());
    await tester.pump();

    final zoomedRange = _currentMainAxisRange(tester);
    expect(_currentScaleX(tester), 2.0);
    expect(zoomedRange, isNotNull);
    expect(zoomedRange!.span, lessThan(readjustedRange!.span));
    expect(tester.takeException(), isNull);
  });

  testWidgets('real pointer pinch works after pan reset and axis readjustment',
      (tester) async {
    await _pumpChart(tester, dataCount: 80);

    await tester.dragFrom(const Offset(20, 180), const Offset(0, 80));
    await tester.pump();
    expect(_currentMainAxisRange(tester), isNotNull);

    await _pinchWithPointers(
      tester,
      startA: const Offset(150, 195),
      startB: const Offset(170, 205),
      endA: const Offset(120, 180),
      endB: const Offset(200, 220),
    );
    expect(_currentScaleX(tester), greaterThan(1.0));

    await tester.tap(find.byIcon(Icons.double_arrow));
    await tester.pump();
    expect(_currentScaleX(tester), 1.0);
    expect(_currentMainAxisRange(tester), isNull);

    await tester.dragFrom(const Offset(180, 220), const Offset(80, 0));
    await tester.pump();
    expect(_currentScrollX(tester), greaterThan(0));

    await tester.dragFrom(const Offset(20, 180), const Offset(0, 80));
    await tester.pump();
    final readjustedRange = _currentMainAxisRange(tester);
    expect(readjustedRange, isNotNull);

    await _pinchWithPointers(
      tester,
      startA: const Offset(150, 195),
      startB: const Offset(170, 205),
      endA: const Offset(120, 180),
      endB: const Offset(200, 220),
    );

    final zoomedRange = _currentMainAxisRange(tester);
    expect(_currentScaleX(tester), greaterThan(1.0));
    expect(zoomedRange, isNotNull);
    expect(zoomedRange!.span, lessThan(readjustedRange!.span));
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpChart(
  WidgetTester tester, {
  VerticalTextAlignment verticalTextAlignment = VerticalTextAlignment.left,
  ChartColors? chartColors,
  int dataCount = 8,
  List<PositionMarkerEntity> markers = const <PositionMarkerEntity>[],
  List<ChartDrawingEntity> drawings = const <ChartDrawingEntity>[],
  int? selectedDrawingId,
  bool drawingSelectionEnabled = false,
  ValueChanged<int?>? onSelectedDrawingChanged,
  bool drawingEnabled = false,
  ChartDrawingTool drawingTool = ChartDrawingTool.none,
  ChartDrawingStyle drawingStyle = const ChartDrawingStyle(),
  ValueChanged<List<ChartDrawingEntity>>? onDrawingsChanged,
  void Function(ChartDrawingEvent event)? onDrawingEvent,
  ChartDrawingOverlayBuilder? selectedDrawingOverlayBuilder,
}) async {
  final data = List<KLineEntity>.generate(
    dataCount,
    (index) => KLineEntity.fromCustom(
      open: 100 + index.toDouble(),
      close: 101 + index.toDouble(),
      high: 103 + index.toDouble(),
      low: 99 + index.toDouble(),
      vol: 1000 + index.toDouble(),
      time: 1000 + index * 60000,
    ),
  );

  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: SizedBox(
        width: 320,
        height: 420,
        child: KChartWidget(
          data,
          ChartStyle(),
          chartColors ?? ChartColors(),
          mainStateLi: const {MainState.MA},
          verticalTextAlignment: verticalTextAlignment,
          markers: markers,
          drawings: drawings,
          selectedDrawingId: selectedDrawingId,
          drawingSelectionEnabled: drawingSelectionEnabled,
          onSelectedDrawingChanged: onSelectedDrawingChanged,
          drawingEnabled: drawingEnabled,
          drawingTool: drawingTool,
          drawingStyle: drawingStyle,
          onDrawingsChanged: onDrawingsChanged,
          onDrawingEvent: onDrawingEvent,
          selectedDrawingOverlayBuilder: selectedDrawingOverlayBuilder,
          isTrendLine: false,
        ),
      ),
    ),
  );
}

GestureDetector _chartScaleGesture(WidgetTester tester) {
  return tester.widget<GestureDetector>(
    find.byWidgetPredicate(
      (widget) => widget is GestureDetector && widget.onScaleUpdate != null,
    ),
  );
}

GestureDetector _axisGesture(WidgetTester tester) {
  return tester
      .widgetList<GestureDetector>(find.byType(GestureDetector))
      .singleWhere(
        (widget) =>
            widget.onVerticalDragStart != null &&
            widget.onVerticalDragUpdate != null,
      );
}

GestureDetector _horizontalDragGesture(WidgetTester tester) {
  return tester
      .widgetList<GestureDetector>(find.byType(GestureDetector))
      .singleWhere((widget) => widget.onHorizontalDragUpdate != null);
}

void _disableAutoScale(WidgetTester tester) {
  final axisGesture = _axisGesture(tester);
  axisGesture.onVerticalDragStart!(
    DragStartDetails(localPosition: const Offset(10, 100)),
  );
  axisGesture.onVerticalDragUpdate!(
    DragUpdateDetails(
      globalPosition: const Offset(300, 180),
      localPosition: const Offset(10, 180),
    ),
  );
}

Future<void> _pinchWithPointers(
  WidgetTester tester, {
  required Offset startA,
  required Offset startB,
  required Offset endA,
  required Offset endB,
}) async {
  final first = await tester.startGesture(startA, pointer: 41);
  final second = await tester.startGesture(startB, pointer: 42);
  await tester.pump();
  await first.moveTo(endA);
  await second.moveTo(endB);
  await tester.pump();
  await first.up();
  await second.up();
  await tester.pump();
}

MainAxisRange? _currentMainAxisRange(WidgetTester tester) {
  return _currentChartPainter(tester).mainAxisRangeOverride;
}

double _currentScaleX(WidgetTester tester) {
  return _currentChartPainter(tester).scaleX;
}

double _currentScrollX(WidgetTester tester) {
  return _currentChartPainter(tester).scrollX;
}

ChartPainter _currentChartPainter(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(find.byType(CustomPaint).first);
  return paint.painter as ChartPainter;
}

double _dataXAt({
  required double x,
  required double scaleX,
  required double scrollX,
  required int dataCount,
  required double width,
}) {
  return -(scrollX + _minTranslateX(scaleX, dataCount, width)) + x / scaleX;
}

double _minTranslateX(double scaleX, int dataCount, double width) {
  final dataLen = dataCount * ChartStyle().pointWidth;
  final x = -dataLen + width / scaleX - ChartStyle().pointWidth / 2 - 100;
  return x >= 0 ? 0.0 : x;
}

double _mainAxisValueAt(double y, MainAxisRange range, Rect mainRect) {
  final ratio = ((y - mainRect.top) / mainRect.height).clamp(0.0, 1.0);
  return range.max - range.span * ratio;
}
