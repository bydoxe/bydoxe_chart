import 'package:flutter/material.dart';

mixin RSIEntity {
  /// RSI值
  double? rsi;

  /// Multiple RSI values for configurable periods (max 3 supported visually)
  List<double>? rsiValueList;
}

class RSIInputEntity {
  final int value;
  final Color color;

  RSIInputEntity({required this.value, required this.color});

  @override
  String toString() {
    return 'Data{value: $value, color: $color}';
  }
}
