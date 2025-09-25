import 'package:flutter/material.dart';

mixin KDJEntity {
  double? k;
  double? d;
  double? j;
}

class KDJInputEntity {
  final int calculatePeriod;
  final int maPeriod_1;
  final int maPeriod_2;
  final bool showK;
  final bool showD;
  final bool showJ;
  final Color kColor;
  final Color dColor;
  final Color jColor;

  KDJInputEntity({
    required this.calculatePeriod,
    required this.maPeriod_1,
    required this.maPeriod_2,
    required this.showK,
    required this.showD,
    required this.showJ,
    required this.kColor,
    required this.dColor,
    required this.jColor,
  });

  @override
  String toString() {
    return 'KDJInputEntity(calculatePeriod: $calculatePeriod, maPeriod_1: $maPeriod_1, maPeriod_2: $maPeriod_2, showK: $showK, showD: $showD, showJ: $showJ, kColor: $kColor, dColor: $dColor, jColor: $jColor)';
  }
}
