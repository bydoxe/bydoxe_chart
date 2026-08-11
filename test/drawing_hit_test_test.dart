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

  test('hits a point near an extended line beyond its second anchor', () {
    final mapper = _mapper();
    final tester = DrawingHitTester(
      mapper: mapper,
      drawings: const [
        ChartDrawingEntity(
          id: 4,
          type: ChartDrawingTool.extendedLine,
          anchors: [
            ChartDrawingAnchor(time: 1000, price: 100),
            ChartDrawingAnchor(time: 1000 + 5 * _minute, price: 105),
          ],
        ),
      ],
    );

    final result = tester.hitTest(
      mapper.anchorToOffset(
        const ChartDrawingAnchor(time: 1000 + 8 * _minute, price: 108),
      )!,
    );

    expect(result?.drawingId, 4);
    expect(result?.kind, DrawingHitTestKind.body);
  });

  test('ray only hits in the forward direction', () {
    final mapper = _mapper();
    final tester = DrawingHitTester(
      mapper: mapper,
      drawings: const [
        ChartDrawingEntity(
          id: 5,
          type: ChartDrawingTool.ray,
          anchors: [
            ChartDrawingAnchor(time: 1000 + 5 * _minute, price: 105),
            ChartDrawingAnchor(time: 1000 + 7 * _minute, price: 107),
          ],
        ),
      ],
    );

    final forward = tester.hitTest(
      mapper.anchorToOffset(
        const ChartDrawingAnchor(time: 1000 + 9 * _minute, price: 109),
      )!,
    );
    final backward = tester.hitTest(
      mapper.anchorToOffset(
        const ChartDrawingAnchor(time: 1000 + 3 * _minute, price: 103),
      )!,
    );

    expect(forward?.drawingId, 5);
    expect(backward, isNull);
  });

  test('hits a vertical line', () {
    final mapper = _mapper();
    const drawing = ChartDrawingEntity(
      id: 6,
      type: ChartDrawingTool.verticalLine,
      anchors: [
        ChartDrawingAnchor(time: 1000 + 4 * _minute, price: 100),
      ],
    );
    final x = mapper.anchorToX(drawing.anchors.first)!;

    final result = DrawingHitTester(
      mapper: mapper,
      drawings: const [drawing],
    ).hitTest(Offset(x + 2, 120));

    expect(result?.drawingId, 6);
  });

  test('hits a parallel channel boundary', () {
    final mapper = _mapper();
    const drawing = ChartDrawingEntity(
      id: 7,
      type: ChartDrawingTool.parallelChannel,
      anchors: [
        ChartDrawingAnchor(time: 1000, price: 100),
        ChartDrawingAnchor(time: 1000 + 5 * _minute, price: 105),
        ChartDrawingAnchor(time: 1000, price: 110),
      ],
    );

    final result = DrawingHitTester(
      mapper: mapper,
      drawings: const [drawing],
    ).hitTest(
      mapper.anchorToOffset(
        const ChartDrawingAnchor(time: 1000 + 3 * _minute, price: 113),
      )!,
    );

    expect(result?.drawingId, 7);
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
