import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../entity/drawing_entity.dart';
import 'chart_coordinate_mapper.dart';

class DrawingRenderer {
  static const Color _anchorFillColor = Color(0xff3f8cff);
  static const Color _anchorStrokeColor = Color(0xff9bc7ff);

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
      case ChartDrawingTool.extendedLine:
        _drawExtendedLine(canvas, drawing);
        break;
      case ChartDrawingTool.ray:
        _drawRay(canvas, drawing);
        break;
      case ChartDrawingTool.horizontalLine:
        _drawHorizontalLine(canvas, drawing);
        break;
      case ChartDrawingTool.verticalLine:
        _drawVerticalLine(canvas, drawing);
        break;
      case ChartDrawingTool.parallelChannel:
        _drawParallelChannel(canvas, drawing);
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
      _drawSelectionHandles(canvas, drawing, _anchorOffsets(drawing.anchors));
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

  void _drawExtendedLine(Canvas canvas, ChartDrawingEntity drawing) {
    if (drawing.anchors.length < 2) {
      _drawSelectionHandles(canvas, drawing, _anchorOffsets(drawing.anchors));
      return;
    }
    final start = mapper.anchorToOffset(drawing.anchors[0]);
    final end = mapper.anchorToOffset(drawing.anchors[1]);
    if (start == null || end == null) {
      return;
    }

    final segment = _lineAcrossRect(start, end);
    if (segment == null) {
      return;
    }
    _drawLine(
      canvas,
      segment.$1,
      segment.$2,
      _strokePaint(drawing),
      drawing.style,
    );
    _drawSelectionHandles(canvas, drawing, [start, end]);
  }

  void _drawRay(Canvas canvas, ChartDrawingEntity drawing) {
    if (drawing.anchors.length < 2) {
      _drawSelectionHandles(canvas, drawing, _anchorOffsets(drawing.anchors));
      return;
    }
    final start = mapper.anchorToOffset(drawing.anchors[0]);
    final end = mapper.anchorToOffset(drawing.anchors[1]);
    if (start == null || end == null) {
      return;
    }

    final rayEnd = _rayEndInRect(start, end);
    if (rayEnd == null) {
      return;
    }
    _drawLine(canvas, start, rayEnd, _strokePaint(drawing), drawing.style);
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

  void _drawVerticalLine(Canvas canvas, ChartDrawingEntity drawing) {
    if (drawing.anchors.isEmpty) {
      return;
    }
    final x = mapper.anchorToX(drawing.anchors.first);
    if (x == null) {
      return;
    }
    final start = Offset(x, mapper.mainPaneClipRect.top);
    final end = Offset(x, mapper.mainPaneClipRect.bottom);

    _drawLine(canvas, start, end, _strokePaint(drawing), drawing.style);
    _drawSelectionHandles(canvas, drawing, [start, end]);
  }

  void _drawParallelChannel(Canvas canvas, ChartDrawingEntity drawing) {
    if (drawing.anchors.length < 2) {
      _drawSelectionHandles(canvas, drawing, _anchorOffsets(drawing.anchors));
      return;
    }
    final start = mapper.anchorToOffset(drawing.anchors[0]);
    final end = mapper.anchorToOffset(drawing.anchors[1]);
    if (start == null || end == null) {
      return;
    }

    final paint = _strokePaint(drawing);
    _drawLine(canvas, start, end, paint, drawing.style);

    final third = drawing.anchors.length >= 3
        ? mapper.anchorToOffset(drawing.anchors[2])
        : null;
    if (third == null) {
      _drawSelectionHandles(canvas, drawing, [start, end]);
      return;
    }

    final parallelEnd = third + (end - start);
    _drawLine(canvas, third, parallelEnd, paint, drawing.style);
    _drawLine(canvas, start, third, paint, drawing.style);
    _drawLine(canvas, end, parallelEnd, paint, drawing.style);
    _drawSelectionHandles(canvas, drawing, [start, end, third]);
  }

  void _drawRectangle(Canvas canvas, ChartDrawingEntity drawing) {
    if (drawing.anchors.length < 2) {
      _drawSelectionHandles(canvas, drawing, _anchorOffsets(drawing.anchors));
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
    final isSelected = drawing.id == selectedDrawingId || drawing.id < 0;
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
    if (drawing.id != selectedDrawingId && drawing.id >= 0) {
      return;
    }

    final fillPaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.fill
      ..color = _anchorFillColor;
    final strokePaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = _anchorStrokeColor;

    for (final point in points) {
      if (!mapper.isOffsetVisible(point)) {
        continue;
      }
      canvas.drawCircle(point, 5.0, fillPaint);
      canvas.drawCircle(point, 5.0, strokePaint);
    }
  }

  List<Offset> _anchorOffsets(Iterable<ChartDrawingAnchor> anchors) {
    return anchors.map(mapper.anchorToOffset).whereType<Offset>().toList();
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

  (Offset, Offset)? _lineAcrossRect(Offset start, Offset end) {
    final points = _lineRectIntersections(start, end);
    if (points.length < 2) {
      return null;
    }
    return (points.first, points.last);
  }

  Offset? _rayEndInRect(Offset start, Offset through) {
    final points = _lineRectIntersections(start, through);
    if (points.isEmpty) {
      return null;
    }

    final direction = through - start;
    Offset? best;
    var bestProjection = 0.0;
    for (final point in points) {
      final projection = (point.dx - start.dx) * direction.dx +
          (point.dy - start.dy) * direction.dy;
      if (projection >= 0 && (best == null || projection > bestProjection)) {
        best = point;
        bestProjection = projection;
      }
    }
    return best;
  }

  List<Offset> _lineRectIntersections(Offset start, Offset end) {
    final rect = mapper.mainPaneClipRect;
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    if (dx == 0 && dy == 0) {
      return const <Offset>[];
    }

    final points = <Offset>[];
    void addIfValid(double t) {
      final point = Offset(start.dx + dx * t, start.dy + dy * t);
      if (point.dx >= rect.left - 0.01 &&
          point.dx <= rect.right + 0.01 &&
          point.dy >= rect.top - 0.01 &&
          point.dy <= rect.bottom + 0.01 &&
          !points.any((existing) => (existing - point).distance < 0.01)) {
        points.add(point);
      }
    }

    if (dx != 0) {
      addIfValid((rect.left - start.dx) / dx);
      addIfValid((rect.right - start.dx) / dx);
    }
    if (dy != 0) {
      addIfValid((rect.top - start.dy) / dy);
      addIfValid((rect.bottom - start.dy) / dy);
    }

    points.sort((a, b) {
      final da = (a - start).distanceSquared;
      final db = (b - start).distanceSquared;
      return da.compareTo(db);
    });
    return points;
  }
}
