import 'package:flutter/material.dart';

class IndicatorSAR {
  double start;
  double maximum;
  Color color;

  IndicatorSAR(
    this.start,
    this.maximum,
    this.color,
  );

  @override
  String toString() {
    return 'Data{start: $start, maximum: $maximum, color: $color}';
  }
}
