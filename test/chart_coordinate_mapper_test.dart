import 'package:bydoxe_chart/k_chart_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps candle time and data index to the same x position', () {
    final mapper = _mapper(_candles(count: 10));

    expect(
      mapper.timeToX(1000 + 4 * _minute),
      mapper.dataIndexToX(4),
    );
  });

  test('uses time before stale data index when mapping anchors', () {
    final mapper = _mapper(_candles(count: 40, intervalMs: _hour));
    const anchor = ChartDrawingAnchor(
      time: 1000 + _hour ~/ 2,
      price: 100,
      dataIndex: 30,
    );

    expect(mapper.anchorToX(anchor), mapper.timeToX(anchor.time));
    expect(mapper.anchorToX(anchor), isNot(mapper.dataIndexToX(30)));
  });

  test('interpolates time inside a larger interval for cross-interval drawings',
      () {
    final mapper = _mapper(_candles(count: 3, intervalMs: _hour));

    expect(mapper.timeToFractionalIndex(1000 + _hour ~/ 2), 0.5);
    expect(mapper.timeToX(1000 + _hour ~/ 2), mapper.fractionalIndexToX(0.5));
  });

  test('extrapolates offscreen time anchors outside loaded data', () {
    final mapper = _mapper(_candles(count: 3, intervalMs: _hour));

    expect(mapper.timeToFractionalIndex(1000 - _hour), -1.0);
    expect(mapper.timeToFractionalIndex(1000 + 3 * _hour), 3.0);
  });

  test('round trips price and y using the main price range', () {
    final mapper = _mapper(
      _candles(count: 10),
      mainMinValue: 90,
      mainMaxValue: 110,
    );

    final y = mapper.priceToY(103.5);

    expect(mapper.yToPrice(y), closeTo(103.5, 0.000001));
  });

  test('changes x positions when zoom and scroll change', () {
    final datas = _candles(count: 60);
    final normal = _mapper(datas, scaleX: 1, scrollX: 0);
    final zoomed = _mapper(datas, scaleX: 2, scrollX: 10);

    expect(
      normal.timeToX(1000 + 30 * _minute),
      isNot(zoomed.timeToX(1000 + 30 * _minute)),
    );
  });

  test('converts screen x back to nearest index and time', () {
    final mapper = _mapper(_candles(count: 10));
    final x = mapper.fractionalIndexToX(2.25);

    expect(mapper.nearestDataIndexForX(x), 2);
    expect(mapper.timeAtX(x), 1000 + (2.25 * _minute).round());
  });
}

const int _minute = 60000;
const int _hour = 60 * _minute;

ChartCoordinateMapper _mapper(
  List<KLineEntity> datas, {
  double scaleX = 1,
  double scrollX = 0,
  double mainMinValue = 80,
  double mainMaxValue = 120,
}) {
  return ChartCoordinateMapper(
    datas: datas,
    mainRect: const Rect.fromLTWH(0, 20, 320, 180),
    scaleX: scaleX,
    scrollX: scrollX,
    pointWidth: 10,
    xFrontPadding: 0,
    mainMaxValue: mainMaxValue,
    mainMinValue: mainMinValue,
  );
}

List<KLineEntity> _candles({
  required int count,
  int intervalMs = _minute,
}) {
  return List.generate(
    count,
    (index) => KLineEntity.fromCustom(
      open: 100,
      close: 101,
      high: 102,
      low: 99,
      vol: 1,
      time: 1000 + index * intervalMs,
    ),
  );
}
