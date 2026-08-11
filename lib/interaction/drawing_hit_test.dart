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
      case ChartDrawingTool.horizontalLine:
        return _hitHorizontalLine(point, drawing);
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

  bool _hitHorizontalLine(Offset point, ChartDrawingEntity drawing) {
    if (drawing.anchors.isEmpty) {
      return false;
    }
    final y = mapper.priceToY(drawing.anchors.first.price);
    return (point.dy - y).abs() <= lineTolerance;
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
        return drawing.anchors.take(2).map(mapper.anchorToOffset).toList();
      case ChartDrawingTool.horizontalLine:
        if (drawing.anchors.isEmpty) {
          return const <Offset?>[];
        }
        final y = mapper.priceToY(drawing.anchors.first.price);
        return <Offset>[
          Offset(mapper.mainPaneClipRect.left, y),
          Offset(mapper.mainPaneClipRect.right, y),
        ];
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
}
