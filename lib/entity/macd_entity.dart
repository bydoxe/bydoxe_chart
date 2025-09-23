import 'package:flutter/material.dart';

import 'kdj_entity.dart';
import 'rsi_entity.dart';
import 'wr_entity.dart';
import 'stoch_rsi_entity.dart';
import 'obv_entity.dart';

mixin MACDEntity on KDJEntity, RSIEntity, WREntity, OBVEntity, StochRSIEntity {
  double? dea;
  double? dif;
  double? macd;
}

enum GrowFallType {
  hollow,
  solid,
}

class MACDInputEntity {
  final int shortPeriod;
  final int longPeriod;
  final int MAPeriod;
  final bool difShow;
  final Color difColor;
  final bool deaShow;
  final Color deaColor;
  final bool macdShow;
  final GrowFallType macdLongGrowType;
  final Color macdLongGrowColor;
  final GrowFallType macdLongFallType;
  final Color macdLongFallColor;
  final GrowFallType macdShortGrowType;
  final Color macdShortGrowColor;
  final GrowFallType macdShortFallType;
  final Color macdShortFallColor;

  MACDInputEntity(
      {required this.shortPeriod,
      required this.longPeriod,
      required this.MAPeriod,
      required this.difShow,
      required this.difColor,
      required this.deaShow,
      required this.deaColor,
      required this.macdShow,
      required this.macdLongGrowType,
      required this.macdLongGrowColor,
      required this.macdLongFallType,
      required this.macdLongFallColor,
      required this.macdShortGrowType,
      required this.macdShortGrowColor,
      required this.macdShortFallType,
      required this.macdShortFallColor});

  @override
  String toString() {
    return 'Data{shortPeriod: $shortPeriod, longPeriod: $longPeriod, MAPeriod: $MAPeriod, difShow: $difShow, difColor: $difColor, deaShow: $deaShow, deaColor: $deaColor, macdShow: $macdShow, macdLongGrowType: $macdLongGrowType, macdLongGrowColor: $macdLongGrowColor, macdLongFallType: $macdLongFallType, macdLongFallColor: $macdLongFallColor, macdShortGrowType: $macdShortGrowType, macdShortGrowColor: $macdShortGrowColor, macdShortFallType: $macdShortFallType, macdShortFallColor: $macdShortFallColor}';
  }
}
