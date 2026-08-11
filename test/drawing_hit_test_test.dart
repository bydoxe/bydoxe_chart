import 'package:bydoxe_chart/k_chart_plus.dart';
import 'package:flutter/material.dart' show Offset, Rect;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hits a point near a trend line', () {
    final tester = DrawingHitTester(
      mapper: _mapper(),
      drawings: const [
        ChartDrawingEntity(
          id: 1,
          type: ChartDrawingTool.trendLine,
          anchors: [
            ChartDrawingAnchor(time: 1000, price: 100),
            ChartDrawingAnchor(time: 1000 + 5 * _minute, price: 105),
          ],
        ),
      ],
    );

    final result = tester.hitTest(
      _mapper().anchorToOffset(
        const ChartDrawingAnchor(time: 1000 + 2 * _minute, price: 102),
      )!,
    );

    expect(result?.drawingId, 1);
    expect(result?.kind, DrawingHitTestKind.body);
  });

  test('misses a point far from a trend line', () {
    final mapper = _mapper();
    final tester = DrawingHitTester(
      mapper: mapper,
      drawings: const [
        ChartDrawingEntity(
          id: 1,
          type: ChartDrawingTool.trendLine,
          anchors: [
            ChartDrawingAnchor(time: 1000, price: 100),
            ChartDrawingAnchor(time: 1000 + 5 * _minute, price: 105),
          ],
        ),
      ],
    );

    final result = tester.hitTest(
      mapper.anchorToOffset(
        const ChartDrawingAnchor(time: 1000 + 2 * _minute, price: 112),
      )!,
    );

    expect(result, isNull);
  });

  test('hits rectangle edge before requiring selected body hit', () {
    final mapper = _mapper();
    final rectangle = ChartDrawingEntity(
      id: 2,
      type: ChartDrawingTool.rectangle,
      anchors: const [
        ChartDrawingAnchor(time: 1000 + 2 * _minute, price: 102),
        ChartDrawingAnchor(time: 1000 + 6 * _minute, price: 108),
      ],
    );
    final rectStart = mapper.anchorToOffset(rectangle.anchors[0])!;
    final rectEnd = mapper.anchorToOffset(rectangle.anchors[1])!;

    final edgeResult = DrawingHitTester(
      mapper: mapper,
      drawings: [rectangle],
    ).hitTest(Offset(rectStart.dx, (rectStart.dy + rectEnd.dy) / 2));

    final bodyResult = DrawingHitTester(
      mapper: mapper,
      drawings: [rectangle],
    ).hitTest(Offset(
        (rectStart.dx + rectEnd.dx) / 2, (rectStart.dy + rectEnd.dy) / 2));

    expect(edgeResult?.drawingId, 2);
    expect(edgeResult?.kind, DrawingHitTestKind.body);
    expect(bodyResult, isNull);
  });

  test('hits selected rectangle body', () {
    final mapper = _mapper();
    const rectangle = ChartDrawingEntity(
      id: 2,
      type: ChartDrawingTool.rectangle,
      anchors: [
        ChartDrawingAnchor(time: 1000 + 2 * _minute, price: 102),
        ChartDrawingAnchor(time: 1000 + 6 * _minute, price: 108),
      ],
    );

    final result = DrawingHitTester(
      mapper: mapper,
      drawings: const [rectangle],
      selectedDrawingId: 2,
    ).hitTest(
      mapper.anchorToOffset(
        const ChartDrawingAnchor(time: 1000 + 4 * _minute, price: 105),
      )!,
    );

    expect(result?.drawingId, 2);
    expect(result?.kind, DrawingHitTestKind.body);
  });

  test('selected handles have priority over drawing body', () {
    final mapper = _mapper();
    const drawing = ChartDrawingEntity(
      id: 3,
      type: ChartDrawingTool.trendLine,
      anchors: [
        ChartDrawingAnchor(time: 1000, price: 100),
        ChartDrawingAnchor(time: 1000 + 5 * _minute, price: 105),
      ],
    );

    final result = DrawingHitTester(
      mapper: mapper,
      drawings: const [drawing],
      selectedDrawingId: 3,
    ).hitTest(mapper.anchorToOffset(drawing.anchors.first)!);

    expect(result?.drawingId, 3);
    expect(result?.kind, DrawingHitTestKind.handle);
    expect(result?.handleIndex, 0);
  });
}

const int _minute = 60000;

ChartCoordinateMapper _mapper() {
  return ChartCoordinateMapper(
    datas: _candles(count: 20),
    mainRect: const Rect.fromLTWH(0, 20, 320, 180),
    scaleX: 1,
    scrollX: 0,
    pointWidth: 10,
    xFrontPadding: 0,
    mainMaxValue: 120,
    mainMinValue: 80,
  );
}

List<KLineEntity> _candles({required int count}) {
  return List.generate(
    count,
    (index) => KLineEntity.fromCustom(
      open: 100,
      close: 101,
      high: 102,
      low: 99,
      vol: 1,
      time: 1000 + index * _minute,
    ),
  );
}
