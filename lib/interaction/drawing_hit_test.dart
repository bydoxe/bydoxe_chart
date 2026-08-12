import 'dart:math' as math;

import 'package:flutter/material.dart' show Offset, Rect;

import '../entity/drawing_entity.dart';
import '../renderer/chart_coordinate_mapper.dart';

enum DrawingHitTestKind {
  body,
  handle,
}

class DrawingHitTestResult {
  final int drawingId;
  final DrawingHitTestKind kind;
  final int? handleIndex;

  const DrawingHitTestResult({
    required this.drawingId,
    required this.kind,
    this.handleIndex,
  });
}

class DrawingHitTester {
  final ChartCoordinateMapper mapper;
  final List<ChartDrawingEntity> drawings;
  final int? selectedDrawingId;
  final double lineTolerance;
  final double handleTolerance;

  const DrawingHitTester({
    required this.mapper,
    required this.drawings,
    this.selectedDrawingId,
    this.lineTolerance = 12.0,
    this.handleTolerance = 14.0,
  });

  DrawingHitTestResult? hitTest(Offset point) {
    if (!mapper.mainPaneClipRect.contains(point)) {
      return null;
    }

    final selectedHit = _hitSelectedHandles(point);
    if (selectedHit != null) {
      return selectedHit;
    }

    for (final drawing in drawings.reversed) {
      if (drawing.hidden || drawing.type == ChartDrawingTool.none) {
        continue;
      }
      if (_hitDrawingBody(point, drawing)) {
        return DrawingHitTestResult(
          drawingId: drawing.id,
          kind: DrawingHitTestKind.body,
        );
      }
    }

    return null;
  }

  DrawingHitTestResult? _hitSelectedHandles(Offset point) {
    final selectedId = selectedDrawingId;
    if (selectedId == null) {
      return null;
    }

    ChartDrawingEntity? selectedDrawing;
    for (final drawing in drawings) {
      if (drawing.id == selectedId) {
        selectedDrawing = drawing;
        break;
      }
    }
    if (selectedDrawing == null ||
        selectedDrawing.hidden ||
        selectedDrawing.type == ChartDrawingTool.none) {
      return null;
    }

    final handles = _handleOffsets(selectedDrawing);
    for (var i = 0; i < handles.length; i++) {
      final handle = handles[i];
      if (handle == null || !mapper.isOffsetVisible(handle)) {
        continue;
      }
      if ((point - handle).distance <= handleTolerance) {
        return DrawingHitTestResult(
          drawingId: selectedDrawing.id,
          kind: DrawingHitTestKind.handle,
          handleIndex: i,
        );
      }
    }
    return null;
  }

  bool _hitDrawingBody(Offset point, ChartDrawingEntity drawing) {
    switch (drawing.type) {
      case ChartDrawingTool.trendLine:
        return _hitTrendLine(point, drawing);
      case ChartDrawingTool.extendedLine:
        return _hitExtendedLine(point, drawing);
      case ChartDrawingTool.ray:
        return _hitRay(point, drawing);
      case ChartDrawingTool.horizontalLine:
        return _hitHorizontalLine(point, drawing);
      case ChartDrawingTool.verticalLine:
        return _hitVerticalLine(point, drawing);
      case ChartDrawingTool.parallelChannel:
        return _hitParallelChannel(point, drawing);
      case ChartDrawingTool.fibonacciRetracement:
        return _hitFibonacciRetracement(point, drawing);
      case ChartDrawingTool.rectangle:
        return _hitRectangle(point, drawing);
      case ChartDrawingTool.none:
        return false;
    }
  }

  bool _hitTrendLine(Offset point, ChartDrawingEntity drawing) {
    if (drawing.anchors.length < 2) {
      return false;
    }
    final start = mapper.anchorToOffset(drawing.anchors[0]);
    final end = mapper.anchorToOffset(drawing.anchors[1]);
    if (start == null || end == null) {
      return false;
    }
    return _distanceToSegment(point, start, end) <= lineTolerance;
  }

  bool _hitExtendedLine(Offset point, ChartDrawingEntity drawing) {
    if (drawing.anchors.length < 2) {
      return false;
    }
    final start = mapper.anchorToOffset(drawing.anchors[0]);
    final end = mapper.anchorToOffset(drawing.anchors[1]);
    if (start == null || end == null) {
      return false;
    }
    return _distanceToLine(point, start, end) <= lineTolerance;
  }

  bool _hitRay(Offset point, ChartDrawingEntity drawing) {
    if (drawing.anchors.length < 2) {
      return false;
    }
    final start = mapper.anchorToOffset(drawing.anchors[0]);
    final end = mapper.anchorToOffset(drawing.anchors[1]);
    if (start == null || end == null) {
      return false;
    }
    return _isInRayDirection(point, start, end) &&
        _distanceToLine(point, start, end) <= lineTolerance;
  }

  bool _hitHorizontalLine(Offset point, ChartDrawingEntity drawing) {
    if (drawing.anchors.isEmpty) {
      return false;
    }
    final y = mapper.priceToY(drawing.anchors.first.price);
    return (point.dy - y).abs() <= lineTolerance;
  }

  bool _hitVerticalLine(Offset point, ChartDrawingEntity drawing) {
    if (drawing.anchors.isEmpty) {
      return false;
    }
    final x = mapper.anchorToX(drawing.anchors.first);
    if (x == null) {
      return false;
    }
    return (point.dx - x).abs() <= lineTolerance;
  }

  bool _hitParallelChannel(Offset point, ChartDrawingEntity drawing) {
    if (drawing.anchors.length < 2) {
      return false;
    }
    final start = mapper.anchorToOffset(drawing.anchors[0]);
    final end = mapper.anchorToOffset(drawing.anchors[1]);
    if (start == null || end == null) {
      return false;
    }
    if (_distanceToLine(point, start, end) <= lineTolerance) {
      return true;
    }

    final third = drawing.anchors.length >= 3
        ? mapper.anchorToOffset(drawing.anchors[2])
        : null;
    if (third == null) {
      return false;
    }
    final parallelEnd = third + (end - start);
    return _distanceToLine(point, third, parallelEnd) <= lineTolerance;
  }

  bool _hitFibonacciRetracement(Offset point, ChartDrawingEntity drawing) {
    if (drawing.anchors.length < 2) {
      return false;
    }
    final start = mapper.anchorToOffset(drawing.anchors[0]);
    final end = mapper.anchorToOffset(drawing.anchors[1]);
    if (start == null || end == null) {
      return false;
    }

    final left = math.min(start.dx, end.dx);
    final right = math.max(start.dx, end.dx);
    if (point.dx < left - lineTolerance || point.dx > right + lineTolerance) {
      return false;
    }

    final startPrice = drawing.anchors[0].price;
    final endPrice = drawing.anchors[1].price;
    for (final level in chartDrawingFibonacciLevels) {
      final price = startPrice + (endPrice - startPrice) * level;
      final y = mapper.priceToY(price);
      if ((point.dy - y).abs() <= lineTolerance) {
        return true;
      }
    }
    return false;
  }

  bool _hitRectangle(Offset point, ChartDrawingEntity drawing) {
    if (drawing.anchors.length < 2) {
      return false;
    }
    final start = mapper.anchorToOffset(drawing.anchors[0]);
    final end = mapper.anchorToOffset(drawing.anchors[1]);
    if (start == null || end == null) {
      return false;
    }

    final rect = Rect.fromPoints(start, end);
    final inflated = rect.inflate(lineTolerance);
    if (!inflated.contains(point)) {
      return false;
    }

    final edgeDistance = math.min(
      math.min((point.dx - rect.left).abs(), (point.dx - rect.right).abs()),
      math.min((point.dy - rect.top).abs(), (point.dy - rect.bottom).abs()),
    );
    if (edgeDistance <= lineTolerance) {
      return true;
    }

    return drawing.id == selectedDrawingId && rect.contains(point);
  }

  List<Offset?> _handleOffsets(ChartDrawingEntity drawing) {
    switch (drawing.type) {
      case ChartDrawingTool.trendLine:
      case ChartDrawingTool.extendedLine:
      case ChartDrawingTool.ray:
        return drawing.anchors.take(2).map(mapper.anchorToOffset).toList();
      case ChartDrawingTool.horizontalLine:
      case ChartDrawingTool.verticalLine:
        return drawing.anchors.take(1).map(mapper.anchorToOffset).toList();
      case ChartDrawingTool.parallelChannel:
        return drawing.anchors.take(3).map(mapper.anchorToOffset).toList();
      case ChartDrawingTool.fibonacciRetracement:
        return drawing.anchors.take(2).map(mapper.anchorToOffset).toList();
      case ChartDrawingTool.rectangle:
        if (drawing.anchors.length < 2) {
          return const <Offset?>[];
        }
        final start = mapper.anchorToOffset(drawing.anchors[0]);
        final end = mapper.anchorToOffset(drawing.anchors[1]);
        if (start == null || end == null) {
          return const <Offset?>[];
        }
        final rect = Rect.fromPoints(start, end);
        return <Offset>[
          rect.topLeft,
          rect.topRight,
          rect.bottomRight,
          rect.bottomLeft,
        ];
      case ChartDrawingTool.none:
        return const <Offset?>[];
    }
  }

  double _distanceToSegment(Offset point, Offset start, Offset end) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final lengthSquared = dx * dx + dy * dy;
    if (lengthSquared == 0) {
      return (point - start).distance;
    }

    final projection =
        (((point.dx - start.dx) * dx) + ((point.dy - start.dy) * dy)) /
            lengthSquared;
    final clampedProjection = projection.clamp(0.0, 1.0);
    final closest = Offset(
      start.dx + clampedProjection * dx,
      start.dy + clampedProjection * dy,
    );
    return (point - closest).distance;
  }

  double _distanceToLine(Offset point, Offset start, Offset end) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final length = math.sqrt(dx * dx + dy * dy);
    if (length == 0) {
      return (point - start).distance;
    }
    return ((point.dx - start.dx) * dy - (point.dy - start.dy) * dx).abs() /
        length;
  }

  bool _isInRayDirection(Offset point, Offset start, Offset through) {
    final direction = through - start;
    final pointDirection = point - start;
    return direction.dx * pointDirection.dx +
            direction.dy * pointDirection.dy >=
        0;
  }
}
