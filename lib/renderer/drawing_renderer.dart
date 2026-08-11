import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../entity/drawing_entity.dart';
import 'chart_coordinate_mapper.dart';

class DrawingRenderer {
  final ChartCoordinateMapper mapper;
  final List<ChartDrawingEntity> drawings;
  final int? selectedDrawingId;

  const DrawingRenderer({
    required this.mapper,
    required this.drawings,
    this.selectedDrawingId,
  });

  void draw(Canvas canvas) {
    if (drawings.isEmpty) {
      return;
    }

    canvas.save();
    canvas.clipRect(mapper.mainPaneClipRect);
    for (final drawing in drawings) {
      if (drawing.hidden || drawing.type == ChartDrawingTool.none) {
        continue;
      }
      _drawDrawing(canvas, drawing);
    }
    canvas.restore();
  }

  void _drawDrawing(Canvas canvas, ChartDrawingEntity drawing) {
    switch (drawing.type) {
      case ChartDrawingTool.trendLine:
        _drawTrendLine(canvas, drawing);
        break;
      case ChartDrawingTool.horizontalLine:
        _drawHorizontalLine(canvas, drawing);
        break;
      case ChartDrawingTool.rectangle:
        _drawRectangle(canvas, drawing);
        break;
      case ChartDrawingTool.none:
        break;
    }
  }

  void _drawTrendLine(Canvas canvas, ChartDrawingEntity drawing) {
    if (drawing.anchors.length < 2) {
      return;
    }
    final start = mapper.anchorToOffset(drawing.anchors[0]);
    final end = mapper.anchorToOffset(drawing.anchors[1]);
    if (start == null || end == null) {
      return;
    }

    _drawLine(canvas, start, end, _strokePaint(drawing), drawing.style);
    _drawSelectionHandles(canvas, drawing, [start, end]);
  }

  void _drawHorizontalLine(Canvas canvas, ChartDrawingEntity drawing) {
    if (drawing.anchors.isEmpty) {
      return;
    }
    final y = mapper.priceToY(drawing.anchors.first.price);
    final start = Offset(mapper.mainPaneClipRect.left, y);
    final end = Offset(mapper.mainPaneClipRect.right, y);

    _drawLine(canvas, start, end, _strokePaint(drawing), drawing.style);
    _drawSelectionHandles(canvas, drawing, [start, end]);
  }

  void _drawRectangle(Canvas canvas, ChartDrawingEntity drawing) {
    if (drawing.anchors.length < 2) {
      return;
    }
    final start = mapper.anchorToOffset(drawing.anchors[0]);
    final end = mapper.anchorToOffset(drawing.anchors[1]);
    if (start == null || end == null) {
      return;
    }

    final rect = Rect.fromPoints(start, end);
    final fillColor = drawing.style.fillColor;
    if (fillColor != null) {
      canvas.drawRect(
        rect,
        Paint()
          ..isAntiAlias = true
          ..style = PaintingStyle.fill
          ..color = fillColor,
      );
    }

    _drawRectOutline(canvas, rect, _strokePaint(drawing), drawing.style);
    _drawSelectionHandles(canvas, drawing, [
      rect.topLeft,
      rect.topRight,
      rect.bottomRight,
      rect.bottomLeft,
    ]);
  }

  Paint _strokePaint(ChartDrawingEntity drawing) {
    final isSelected = drawing.id == selectedDrawingId;
    return Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected
          ? drawing.style.strokeWidth + 1.0
          : drawing.style.strokeWidth
      ..color = drawing.style.color;
  }

  void _drawSelectionHandles(
    Canvas canvas,
    ChartDrawingEntity drawing,
    List<Offset> points,
  ) {
    if (drawing.id != selectedDrawingId) {
      return;
    }

    final fillPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..color = Colors.white;
    final strokePaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = drawing.style.color;

    for (final point in points) {
      if (!mapper.isOffsetVisible(point)) {
        continue;
      }
      canvas.drawCircle(point, 4.0, fillPaint);
      canvas.drawCircle(point, 4.0, strokePaint);
    }
  }

  void _drawRectOutline(
    Canvas canvas,
    Rect rect,
    Paint paint,
    ChartDrawingStyle style,
  ) {
    final dashPattern = _normalizedDashPattern(style);
    if (dashPattern == null) {
      canvas.drawRect(rect, paint);
      return;
    }

    _drawLine(canvas, rect.topLeft, rect.topRight, paint, style);
    _drawLine(canvas, rect.topRight, rect.bottomRight, paint, style);
    _drawLine(canvas, rect.bottomRight, rect.bottomLeft, paint, style);
    _drawLine(canvas, rect.bottomLeft, rect.topLeft, paint, style);
  }

  void _drawLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
    ChartDrawingStyle style,
  ) {
    final dashPattern = _normalizedDashPattern(style);
    if (dashPattern == null) {
      canvas.drawLine(start, end, paint);
      return;
    }

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance == 0) {
      return;
    }

    final direction = Offset(dx / distance, dy / distance);
    var traveled = 0.0;
    var drawSegment = true;
    var patternIndex = 0;
    while (traveled < distance) {
      final segmentLength = dashPattern[patternIndex % dashPattern.length];
      final next = math.min(distance, traveled + segmentLength);
      if (drawSegment) {
        canvas.drawLine(
          start + direction * traveled,
          start + direction * next,
          paint,
        );
      }
      traveled = next;
      drawSegment = !drawSegment;
      patternIndex++;
    }
  }

  List<double>? _normalizedDashPattern(ChartDrawingStyle style) {
    final pattern =
        style.dashPattern?.where((value) => value > 0).toList(growable: false);
    return pattern == null || pattern.isEmpty ? null : pattern;
  }
}
