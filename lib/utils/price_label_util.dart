int getTickPrecision(double? tickSize) {
  if (tickSize == null || !tickSize.isFinite || tickSize <= 0) {
    return 0;
  }

  final normalized = tickSize.toStringAsFixed(8);
  final trimmed = normalized.replaceFirst(RegExp(r'0+$'), '');
  if (!trimmed.contains('.')) {
    return 0;
  }

  return trimmed.split('.').last.length;
}

double snapPriceToTick(double value, double? tickSize) {
  if (tickSize == null || !tickSize.isFinite || tickSize <= 0) {
    return value;
  }

  final precision = getTickPrecision(tickSize);
  final tickCount = (value / tickSize).round();
  final snapped = tickCount * tickSize;
  return double.parse(snapped.toStringAsFixed(precision));
}

String formatPriceLabel(
  double? value, {
  required int fixedLength,
  double? tickSize,
}) {
  if (value == null || value.isNaN) {
    return '0.00';
  }

  if (tickSize == null || !tickSize.isFinite || tickSize <= 0) {
    return value.toStringAsFixed(fixedLength);
  }

  final precision = getTickPrecision(tickSize);
  final decimalDigits = precision > fixedLength ? precision : fixedLength;
  final snapped = snapPriceToTick(value, tickSize);
  return snapped.toStringAsFixed(decimalDigits);
}
