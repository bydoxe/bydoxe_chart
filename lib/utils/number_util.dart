import 'dart:math';

class NumberUtil {
  static String calculateUnrealizedRoe(
      String entryPrice, String exitPrice, int leverage, String side) {
    final double entryPriceDouble = double.tryParse(entryPrice) ?? 0.0;
    final double exitPriceDouble = double.tryParse(exitPrice) ?? 0.0;

    final double priceDiff = side.toUpperCase() == 'LONG'
        ? exitPriceDouble - entryPriceDouble
        : entryPriceDouble - exitPriceDouble;

    final double parent = leverage == 0
        ? (entryPriceDouble == 0 ? 1.0 : entryPriceDouble)
        : (entryPriceDouble / leverage);
    final double roe =
        (priceDiff == 0 || parent == 0) ? 0.0 : (priceDiff / parent) * 100.0;
    return roe.toStringAsFixed(2);
  }

  static String format(double n) {
    if (n >= 1000000000) {
      n /= 1000000000;
      return "${n.toStringAsFixed(2)}B";
    } else if (n >= 1000000) {
      n /= 1000000;
      return "${n.toStringAsFixed(2)}M";
    } else if (n >= 10000) {
      n /= 1000;
      return "${n.toStringAsFixed(2)}K";
    } else {
      return n.toStringAsFixed(4);
    }
  }

  static int getDecimalLength(double b) {
    String s = b.toString();
    int dotIndex = s.indexOf(".");
    if (dotIndex < 0) {
      return 0;
    } else {
      return s.length - dotIndex - 1;
    }
  }

  static int getMaxDecimalLength(double a, double b, double c, double d) {
    int result = max(getDecimalLength(a), getDecimalLength(b));
    result = max(result, getDecimalLength(c));
    result = max(result, getDecimalLength(d));
    return result;
  }

  static bool checkNotNullOrZero(double? a) {
    if (a == null || a == 0) {
      return false;
    } else if (a.abs().toStringAsFixed(4) == "0.0000") {
      return false;
    } else {
      return true;
    }
  }
}
