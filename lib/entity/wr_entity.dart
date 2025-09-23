import 'package:flutter/material.dart';

mixin WREntity {
  /// %R值
  double? r;
}

class WRInputEntity {
  final int value;
  final Color color;

  WRInputEntity({required this.value, required this.color});

  @override
  String toString() {
    return 'WRInputEntity(value: $value, color: $color)';
  }
}
