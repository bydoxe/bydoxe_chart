import 'package:flutter/material.dart';

class StochRSIInputEntity {
  final int lengthRSI;
  final int lengthStoch;
  final int smoothK;
  final int smoothD;
  final bool stochRSIShow;
  final Color stochRSIKColor;
  final bool stochRSIDShow;
  final Color stochRSIDColor;

  StochRSIInputEntity(
      {required this.lengthRSI,
      required this.lengthStoch,
      required this.smoothK,
      required this.smoothD,
      required this.stochRSIShow,
      required this.stochRSIKColor,
      required this.stochRSIDShow,
      required this.stochRSIDColor});

  @override
  String toString() {
    return 'StochRSIInputEntity(lengthRSI: $lengthRSI, lengthStoch: $lengthStoch, smoothK: $smoothK, smoothD: $smoothD, stochRSIShow: $stochRSIShow, stochRSIKColor: $stochRSIKColor, stochRSIDShow: $stochRSIDShow, stochRSIDColor: $stochRSIDColor)';
  }
}

mixin StochRSIEntity {
  double? stochK;
  double? stochD;
}
