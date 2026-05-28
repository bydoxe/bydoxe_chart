import 'package:bydoxe_chart/renderer/main_axis_range.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('scales a range around the provided anchor', () {
    const range = MainAxisRange(min: 90, max: 130);

    final zoomedOut = range.scaleFromAnchor(110, 2);
    expect(zoomedOut.min, 70);
    expect(zoomedOut.max, 150);

    final zoomedIn = range.scaleFromAnchor(110, 0.5);
    expect(zoomedIn.min, 100);
    expect(zoomedIn.max, 120);
  });

  test('pans a range by value delta', () {
    const range = MainAxisRange(min: 90, max: 130);

    final moved = range.panBy(12);

    expect(moved.min, 102);
    expect(moved.max, 142);
  });

  test('normalizes invalid ranges instead of returning zero span', () {
    const range = MainAxisRange(min: 10, max: 10);

    final normalized = range.normalized();

    expect(normalized.isValid, isTrue);
    expect(normalized.center, 10);
  });
}
