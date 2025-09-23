import 'package:flutter/material.dart';

class IndicatorMA {
  int value;
  Color color;

  IndicatorMA(this.value, this.color);

  @override
  String toString() {
    return 'Data{value: $value, color: $color}';
  }
}

class IndicatorEMA {
  int value;
  Color color;

  IndicatorEMA(this.value, this.color);

  @override
  String toString() {
    return 'Data{value: $value, color: $color}';
  }
}
