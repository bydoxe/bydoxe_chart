class MainAxisRange {
  final double min;
  final double max;

  const MainAxisRange({
    required this.min,
    required this.max,
  });

  double get center => (min + max) / 2.0;

  double get span => max - min;

  bool get isValid => min.isFinite && max.isFinite && max > min;

  MainAxisRange scaleFromAnchor(double anchor, double scale) {
    final safeScale = scale.isFinite && scale > 0 ? scale : 1.0;
    return MainAxisRange(
      min: anchor - (anchor - min) * safeScale,
      max: anchor + (max - anchor) * safeScale,
    ).normalized();
  }

  MainAxisRange panBy(double delta) {
    return MainAxisRange(
      min: min + delta,
      max: max + delta,
    );
  }

  MainAxisRange normalized() {
    if (isValid) return this;
    final midpoint = center.isFinite ? center : 0.0;
    const fallbackSpan = 1e-8;
    return MainAxisRange(
      min: midpoint - fallbackSpan / 2.0,
      max: midpoint + fallbackSpan / 2.0,
    );
  }
}
