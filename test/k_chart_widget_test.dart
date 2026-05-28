import 'package:bydoxe_chart/k_chart_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('builds with horizontal, scale, and axis gesture layers',
      (tester) async {
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
            isTrendLine: false,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
