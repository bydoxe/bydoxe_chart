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
  final paint = tester.widget<CustomPaint>(find.byType(CustomPaint).first);
  return (paint.painter as ChartPainter).mainAxisRangeOverride;
}
