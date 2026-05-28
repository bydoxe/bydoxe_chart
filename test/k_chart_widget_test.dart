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
}

Future<void> _pumpChart(
  WidgetTester tester, {
  VerticalTextAlignment verticalTextAlignment = VerticalTextAlignment.left,
  ChartColors? chartColors,
  int dataCount = 8,
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
