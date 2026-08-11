import 'package:flutter/material.dart' show Offset, Rect;

import '../entity/drawing_entity.dart';
import '../entity/k_line_entity.dart';

class ChartCoordinateMapper {
  final List<KLineEntity> datas;
  final Rect mainRect;
  final double scaleX;
  final double scrollX;
  final double pointWidth;
  final double xFrontPadding;
  final double mainMaxValue;
  final double mainMinValue;

  const ChartCoordinateMapper({
    required this.datas,
    required this.mainRect,
    required this.scaleX,
    required this.scrollX,
    required this.pointWidth,
    required this.xFrontPadding,
    required this.mainMaxValue,
    required this.mainMinValue,
  });

  double get width => mainRect.width;

  double get dataLength => datas.length * pointWidth;

  double get minTranslateX {
    if (datas.isEmpty || scaleX <= 0) {
      return 0.0;
    }
    final x = -dataLength + width / scaleX - pointWidth / 2 - xFrontPadding;
    return x >= 0 ? 0.0 : x;
  }

  double get translateX => scrollX + minTranslateX;

  Rect get mainPaneClipRect => mainRect;

  Offset? anchorToOffset(ChartDrawingAnchor anchor) {
    final x = anchorToX(anchor);
    if (x == null) {
      return null;
    }
    return Offset(x, priceToY(anchor.price));
  }

  double? anchorToX(ChartDrawingAnchor anchor) {
    return timeToX(anchor.time) ?? dataIndexToX(anchor.dataIndex);
  }

  double? timeToX(int time, {bool extrapolate = true}) {
    final index = timeToFractionalIndex(time, extrapolate: extrapolate);
    return index == null ? null : fractionalIndexToX(index);
  }

  double? timeToFractionalIndex(int time, {bool extrapolate = true}) {
    if (datas.isEmpty) {
      return null;
    }
    if (datas.length == 1) {
      return datas.first.time == null ? null : 0.0;
    }

    final firstTime = datas.first.time;
    final lastTime = datas.last.time;
    if (firstTime == null || lastTime == null) {
      return nearestDataIndexForTime(time)?.toDouble();
    }

    final isAscending = lastTime >= firstTime;
    if (_isBeforeFirst(time, firstTime, isAscending)) {
      return extrapolate ? _interpolateIndex(0, 1, time) : null;
    }
    if (_isAfterLast(time, lastTime, isAscending)) {
      return extrapolate
          ? _interpolateIndex(datas.length - 2, datas.length - 1, time)
          : null;
    }

    var low = 0;
    var high = datas.length - 1;
    while (high - low > 1) {
      final mid = low + (high - low) ~/ 2;
      final midTime = datas[mid].time;
      if (midTime == null) {
        return nearestDataIndexForTime(time)?.toDouble();
      }

      if (midTime == time) {
        return mid.toDouble();
      }
      if (_isAtOrBefore(midTime, time, isAscending)) {
        low = mid;
      } else {
        high = mid;
      }
    }

    return _interpolateIndex(low, high, time);
  }

  double? dataIndexToX(int? index) {
    if (index == null || datas.isEmpty) {
      return null;
    }
    if (index < 0 || index >= datas.length) {
      return null;
    }
    return fractionalIndexToX(index.toDouble());
  }

  double fractionalIndexToX(double index) {
    return dataXToScreenX(indexToDataX(index));
  }

  double indexToDataX(double index) {
    return index * pointWidth + pointWidth / 2;
  }

  double dataXToScreenX(double dataX) {
    return (dataX + translateX) * scaleX;
  }

  double screenXToDataX(double x) {
    return -translateX + x / scaleX;
  }

  double screenXToFractionalIndex(double x) {
    return (screenXToDataX(x) - pointWidth / 2) / pointWidth;
  }

  int? nearestDataIndexForX(double x) {
    if (datas.isEmpty) {
      return null;
    }
    return screenXToFractionalIndex(x).round().clamp(0, datas.length - 1);
  }

  int? nearestDataIndexForTime(int time) {
    if (datas.isEmpty) {
      return null;
    }
    if (datas.length == 1) {
      return 0;
    }

    var nearestIndex = 0;
    var nearestDistance = _timeDistance(datas.first.time, time);
    for (var i = 1; i < datas.length; i++) {
      final distance = _timeDistance(datas[i].time, time);
      if (distance < nearestDistance) {
        nearestIndex = i;
        nearestDistance = distance;
      }
    }
    return nearestIndex;
  }

  int? timeAtX(double x, {bool extrapolate = true}) {
    if (datas.isEmpty) {
      return null;
    }
    if (datas.length == 1) {
      return datas.first.time;
    }

    final index = screenXToFractionalIndex(x);
    if (!extrapolate && (index < 0 || index > datas.length - 1)) {
      return null;
    }

    final left = index.floor().clamp(0, datas.length - 2);
    final right = left + 1;
    final leftTime = datas[left].time;
    final rightTime = datas[right].time;
    if (leftTime == null || rightTime == null) {
      return datas[nearestDataIndexForX(x)!].time;
    }

    final ratio = index - left;
    return (leftTime + (rightTime - leftTime) * ratio).round();
  }

  double priceToY(double price) {
    final range = _resolvedPriceRange();
    return (range.max - price) * range.scaleY + mainRect.top;
  }

  double yToPrice(double y) {
    final range = _resolvedPriceRange();
    return range.max - (y - mainRect.top) / range.scaleY;
  }

  bool isXVisible(double x) {
    return x >= mainRect.left && x <= mainRect.right;
  }

  bool isYVisible(double y) {
    return y >= mainRect.top && y <= mainRect.bottom;
  }

  bool isOffsetVisible(Offset offset) {
    return mainRect.contains(offset);
  }

  _PriceRange _resolvedPriceRange() {
    var maxValue = mainMaxValue;
    var minValue = mainMinValue;
    if (maxValue == minValue) {
      maxValue *= 1.5;
      minValue /= 2;
    }
    var span = maxValue - minValue;
    if (span.abs() < 0.000000001 || !span.isFinite) {
      span = 1.0;
      maxValue += 0.5;
      minValue -= 0.5;
    }
    return _PriceRange(
      max: maxValue,
      min: minValue,
      scaleY: mainRect.height / span,
    );
  }

  double _interpolateIndex(int left, int right, int time) {
    final leftTime = datas[left].time;
    final rightTime = datas[right].time;
    if (leftTime == null || rightTime == null || leftTime == rightTime) {
      return left.toDouble();
    }
    final ratio = (time - leftTime) / (rightTime - leftTime);
    return left + ratio;
  }

  bool _isBeforeFirst(int time, int firstTime, bool isAscending) {
    return isAscending ? time < firstTime : time > firstTime;
  }

  bool _isAfterLast(int time, int lastTime, bool isAscending) {
    return isAscending ? time > lastTime : time < lastTime;
  }

  bool _isAtOrBefore(int candidate, int target, bool isAscending) {
    return isAscending ? candidate < target : candidate > target;
  }

  int _timeDistance(int? time, int target) {
    if (time == null) {
      return 1 << 62;
    }
    return (time - target).abs();
  }
}

class _PriceRange {
  final double max;
  final double min;
  final double scaleY;

  const _PriceRange({
    required this.max,
    required this.min,
    required this.scaleY,
  });
}
