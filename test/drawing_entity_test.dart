import 'package:bydoxe_chart/k_chart_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serializes and deserializes drawing entities', () {
    final drawing = ChartDrawingEntity(
      id: 7,
      type: ChartDrawingTool.trendLine,
      anchors: const [
        ChartDrawingAnchor(time: 1000, price: 101.5, dataIndex: 1),
        ChartDrawingAnchor(time: 2000, price: 102.75, dataIndex: 2),
      ],
      style: const ChartDrawingStyle(
        color: Color(0xff123456),
        strokeWidth: 2.5,
        fillColor: Color(0x33123456),
        dashPattern: [4, 2],
      ),
      locked: true,
      label: 'entry guide',
      meta: const {'symbol': 'BTCUSDT', 'interval': '1m'},
    );

    final decoded = ChartDrawingEntity.fromJson(drawing.toJson());

    expect(decoded.schemaVersion, chartDrawingSchemaVersion);
    expect(decoded.id, 7);
    expect(decoded.type, ChartDrawingTool.trendLine);
    expect(decoded.anchors, hasLength(2));
    expect(decoded.anchors.first.time, 1000);
    expect(decoded.anchors.first.price, 101.5);
    expect(decoded.anchors.first.dataIndex, 1);
    expect(decoded.style.color.toARGB32(), 0xff123456);
    expect(decoded.style.strokeWidth, 2.5);
    expect(decoded.style.fillColor?.toARGB32(), 0x33123456);
    expect(decoded.style.dashPattern, [4, 2]);
    expect(decoded.locked, isTrue);
    expect(decoded.hidden, isFalse);
    expect(decoded.label, 'entry guide');
    expect(decoded.meta, {'symbol': 'BTCUSDT', 'interval': '1m'});
  });

  test('falls back to none for unknown drawing types', () {
    final drawing = ChartDrawingEntity.fromJson(const {
      'id': 1,
      'type': 'futureFancyTool',
      'anchors': [],
    });

    expect(drawing.type, ChartDrawingTool.none);
  });

  test('keeps optional fields when copying', () {
    const drawing = ChartDrawingEntity(
      id: 3,
      type: ChartDrawingTool.rectangle,
      anchors: [
        ChartDrawingAnchor(time: 1000, price: 1),
      ],
      label: 'box',
      meta: {'persisted': true},
    );

    final changed = drawing.copyWith(
      hidden: true,
      label: null,
      meta: null,
    );

    expect(changed.id, 3);
    expect(changed.type, ChartDrawingTool.rectangle);
    expect(changed.hidden, isTrue);
    expect(changed.label, isNull);
    expect(changed.meta, isNull);
  });

  test('parses invalid json safely', () {
    final drawing = ChartDrawingEntity.fromJson(const {
      'id': 'not-a-number',
      'type': 17,
      'anchors': 'bad anchors',
      'style': {'color': 'bad color', 'strokeWidth': 'bad width'},
      'locked': 'yes',
      'hidden': 1,
      'label': 42,
      'meta': 'bad meta',
    });

    expect(drawing.id, 0);
    expect(drawing.type, ChartDrawingTool.none);
    expect(drawing.anchors, isEmpty);
    expect(drawing.style.color.toARGB32(), const Color(0xfff89215).toARGB32());
    expect(drawing.style.strokeWidth, 1.0);
    expect(drawing.locked, isFalse);
    expect(drawing.hidden, isFalse);
    expect(drawing.label, isNull);
    expect(drawing.meta, isNull);
  });
}
