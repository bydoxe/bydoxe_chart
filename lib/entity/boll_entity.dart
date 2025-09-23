import 'package:flutter/material.dart';

class IndicatorBOLL {
  int period;
  int bandwidth;
  bool isShowUp;
  bool isShowMb;
  bool isShowDn;
  Color upColor;
  Color mbColor;
  Color dnColor;

  IndicatorBOLL(
    this.period,
    this.bandwidth,
    this.isShowUp,
    this.isShowMb,
    this.isShowDn,
    this.upColor,
    this.mbColor,
    this.dnColor,
  );

  @override
  String toString() {
    return 'Data{period: $period, bandwidth: $bandwidth, upColor: $upColor, mbColor: $mbColor, dnColor: $dnColor}';
  }
}
