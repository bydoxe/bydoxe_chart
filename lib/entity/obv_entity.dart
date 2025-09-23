import 'package:flutter/material.dart';

mixin OBVEntity {
  double? obv;
  double? obvMA;
  double? obvEMA;
}

class OBVInputEntity {
  final Color obvColor;
  final bool obvMAShow;
  final int obvMAValue;
  final Color obvMAColor;
  final bool obvEMAShow;
  final int obvEMAValue;
  final Color obvEMAColor;

  OBVInputEntity(
      {required this.obvColor,
      required this.obvMAShow,
      required this.obvMAValue,
      required this.obvMAColor,
      required this.obvEMAShow,
      required this.obvEMAValue,
      required this.obvEMAColor});

  @override
  String toString() {
    return 'OBVInputEntity(obvColor: $obvColor, obvMAShow: $obvMAShow, obvMAValue: $obvMAValue, obvMAColor: $obvMAColor, obvEMAShow: $obvEMAShow, obvEMAValue: $obvEMAValue, obvEMAColor: $obvEMAColor)';
  }
}
