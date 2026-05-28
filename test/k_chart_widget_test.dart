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

    final chartGesture = tester.widget<GestureDetector>(
      find.byWidgetPredicate(
        (widget) => widget is GestureDetector && widget.onScaleUpdate != null,
      ),
    );
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

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump();

    expect(_currentMainAxisRange(tester), isNull);
    expect(_currentScaleX(tester), 1.0);
    expect(_currentScrollX(tester), 0.0);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpChart(WidgetTester tester) async {
  final data = List<KLineEntity>.generate(
    8,
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
          ChartColors(),
          mainStateLi: const {MainState.MA},
          isTrendLine: false,
        ),
      ),
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
