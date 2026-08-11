import 'package:flutter/material.dart' show Offset;

import '../entity/drawing_entity.dart';
import 'drawing_hit_test.dart';

enum ChartDrawingEventType {
  createStarted,
  created,
  updated,
  cancelled,
}

class ChartDrawingEvent {
  final ChartDrawingEventType type;
  final ChartDrawingEntity? drawing;
  final int? drawingId;

  const ChartDrawingEvent({
    required this.type,
    this.drawing,
    this.drawingId,
  });
}

class DrawingController {
  const DrawingController._();

  static int nextDrawingId(List<ChartDrawingEntity> drawings) {
    var maxId = 0;
    for (final drawing in drawings) {
      if (drawing.id > maxId) {
        maxId = drawing.id;
      }
    }
    return maxId + 1;
  }

  static ChartDrawingEntity createDrawing({
    required int id,
    required ChartDrawingTool tool,
    required List<ChartDrawingAnchor> anchors,
    required ChartDrawingStyle style,
  }) {
    return ChartDrawingEntity(
      id: id,
      type: tool,
      anchors: anchors,
      style: style,
    );
  }

  static List<ChartDrawingEntity> appendDrawing(
    List<ChartDrawingEntity> drawings,
    ChartDrawingEntity drawing,
  ) {
    return <ChartDrawingEntity>[
      ...drawings,
      drawing,
    ];
  }

  static List<ChartDrawingEntity> updateDrawing(
    List<ChartDrawingEntity> drawings,
    ChartDrawingEntity updated,
  ) {
    return drawings
        .map((drawing) => drawing.id == updated.id ? updated : drawing)
        .toList(growable: false);
  }

  static ChartDrawingEntity? drawingById(
    List<ChartDrawingEntity> drawings,
    int id,
  ) {
    for (final drawing in drawings) {
      if (drawing.id == id) {
        return drawing;
      }
    }
    return null;
  }

  static ChartDrawingEntity replaceAnchor({
    required ChartDrawingEntity drawing,
    required int handleIndex,
    required ChartDrawingAnchor anchor,
  }) {
    if (drawing.locked || drawing.anchors.isEmpty) {
      return drawing;
    }

    final index = handleIndex.clamp(0, drawing.anchors.length - 1);
    final anchors = drawing.anchors.toList(growable: false);
    anchors[index] = anchor;
    return drawing.copyWith(anchors: anchors);
  }

  static ChartDrawingEntity moveDrawing({
    required ChartDrawingEntity drawing,
    required int deltaTime,
    required double deltaPrice,
  }) {
    if (drawing.locked || drawing.anchors.isEmpty) {
      return drawing;
    }

    return drawing.copyWith(
      anchors: drawing.anchors
          .map(
            (anchor) => anchor.copyWith(
              time: anchor.time + deltaTime,
              price: anchor.price + deltaPrice,
              dataIndex: null,
            ),
          )
          .toList(growable: false),
    );
  }
}

class DrawingDragSession {
  final int drawingId;
  final DrawingHitTestKind kind;
  final int? handleIndex;
  final Offset startPoint;
  final ChartDrawingAnchor startAnchor;
  final List<ChartDrawingEntity> startDrawings;

  const DrawingDragSession({
    required this.drawingId,
    required this.kind,
    required this.startPoint,
    required this.startAnchor,
    required this.startDrawings,
    this.handleIndex,
  });
}
