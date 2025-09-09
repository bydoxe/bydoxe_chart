import 'package:flutter/material.dart' show Color;

/// Action types for position line interactive buttons
enum PositionAction { close, tp, sl }

/// Position line configuration for KChartWidget
class PositionLineEntity {
  /// Unique identifier for callbacks and selection
  final int id;

  /// Price level to draw the position line
  final double price;

  /// Whether the position is long (true) or short (false).
  /// If null, color fallback will not consider direction.
  final bool? isLong;

  /// Optional label to display. If null, formatted price is shown.
  final String? label;

  /// Optional custom color for the line and label background.
  /// If null, color will be chosen from chart colors based on [isLong].
  final Color? color;

  /// Line width. Defaults to 1.0
  final double lineWidth;

  const PositionLineEntity({
    required this.id,
    required this.price,
    this.isLong,
    this.label,
    this.color,
    this.lineWidth = 1.0,
  });
}
