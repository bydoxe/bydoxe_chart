import 'package:flutter/material.dart' show Color;

const int chartDrawingSchemaVersion = 1;

enum ChartDrawingTool {
  none,
  trendLine,
  extendedLine,
  ray,
  horizontalLine,
  verticalLine,
  parallelChannel,
  rectangle,
}

class ChartDrawingAnchor {
  final int time;
  final double price;
  final int? dataIndex;

  const ChartDrawingAnchor({
    required this.time,
    required this.price,
    this.dataIndex,
  });

  factory ChartDrawingAnchor.fromJson(Map<String, dynamic> json) {
    return ChartDrawingAnchor(
      time: _readInt(json['time']) ?? 0,
      price: _readDouble(json['price']) ?? 0,
      dataIndex: _readInt(json['dataIndex']),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'time': time,
      'price': price,
      if (dataIndex != null) 'dataIndex': dataIndex,
    };
  }

  ChartDrawingAnchor copyWith({
    int? time,
    double? price,
    Object? dataIndex = _copyUnset,
  }) {
    return ChartDrawingAnchor(
      time: time ?? this.time,
      price: price ?? this.price,
      dataIndex: dataIndex == _copyUnset ? this.dataIndex : dataIndex as int?,
    );
  }
}

class ChartDrawingStyle {
  final Color color;
  final double strokeWidth;
  final Color? fillColor;
  final List<double>? dashPattern;

  const ChartDrawingStyle({
    this.color = const Color(0xfff89215),
    this.strokeWidth = 1.0,
    this.fillColor,
    this.dashPattern,
  });

  factory ChartDrawingStyle.fromJson(Map<String, dynamic> json) {
    final dashPatternJson = json['dashPattern'];
    final dashPattern = dashPatternJson is List
        ? dashPatternJson
            .map(_readDouble)
            .whereType<double>()
            .toList(growable: false)
        : null;

    return ChartDrawingStyle(
      color:
          Color(_readInt(json['color']) ?? const Color(0xfff89215).toARGB32()),
      strokeWidth: _readDouble(json['strokeWidth']) ?? 1.0,
      fillColor: _readInt(json['fillColor']) == null
          ? null
          : Color(_readInt(json['fillColor'])!),
      dashPattern:
          dashPattern == null || dashPattern.isEmpty ? null : dashPattern,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'color': color.toARGB32(),
      'strokeWidth': strokeWidth,
      if (fillColor != null) 'fillColor': fillColor!.toARGB32(),
      if (dashPattern != null) 'dashPattern': dashPattern,
    };
  }

  ChartDrawingStyle copyWith({
    Color? color,
    double? strokeWidth,
    Object? fillColor = _copyUnset,
    Object? dashPattern = _copyUnset,
  }) {
    return ChartDrawingStyle(
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      fillColor: fillColor == _copyUnset ? this.fillColor : fillColor as Color?,
      dashPattern: dashPattern == _copyUnset
          ? this.dashPattern
          : dashPattern as List<double>?,
    );
  }
}

class ChartDrawingEntity {
  final int schemaVersion;
  final int id;
  final ChartDrawingTool type;
  final List<ChartDrawingAnchor> anchors;
  final ChartDrawingStyle style;
  final bool locked;
  final bool hidden;
  final String? label;
  final Map<String, dynamic>? meta;

  const ChartDrawingEntity({
    this.schemaVersion = chartDrawingSchemaVersion,
    required this.id,
    required this.type,
    required this.anchors,
    this.style = const ChartDrawingStyle(),
    this.locked = false,
    this.hidden = false,
    this.label,
    this.meta,
  });

  factory ChartDrawingEntity.fromJson(Map<String, dynamic> json) {
    final anchorsJson = json['anchors'];
    final anchors = anchorsJson is List
        ? anchorsJson
            .whereType<Map>()
            .map((item) => ChartDrawingAnchor.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList(growable: false)
        : const <ChartDrawingAnchor>[];

    final styleJson = json['style'];

    return ChartDrawingEntity(
      schemaVersion:
          _readInt(json['schemaVersion']) ?? chartDrawingSchemaVersion,
      id: _readInt(json['id']) ?? 0,
      type: _chartDrawingToolFromJson(json['type']),
      anchors: anchors,
      style: styleJson is Map
          ? ChartDrawingStyle.fromJson(Map<String, dynamic>.from(styleJson))
          : const ChartDrawingStyle(),
      locked: json['locked'] == true,
      hidden: json['hidden'] == true,
      label: json['label'] is String ? json['label'] as String : null,
      meta: json['meta'] is Map
          ? Map<String, dynamic>.from(json['meta'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'id': id,
      'type': type.name,
      'anchors': anchors.map((anchor) => anchor.toJson()).toList(),
      'style': style.toJson(),
      'locked': locked,
      'hidden': hidden,
      if (label != null) 'label': label,
      if (meta != null) 'meta': meta,
    };
  }

  ChartDrawingEntity copyWith({
    int? schemaVersion,
    int? id,
    ChartDrawingTool? type,
    List<ChartDrawingAnchor>? anchors,
    ChartDrawingStyle? style,
    bool? locked,
    bool? hidden,
    Object? label = _copyUnset,
    Object? meta = _copyUnset,
  }) {
    return ChartDrawingEntity(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      id: id ?? this.id,
      type: type ?? this.type,
      anchors: anchors ?? this.anchors,
      style: style ?? this.style,
      locked: locked ?? this.locked,
      hidden: hidden ?? this.hidden,
      label: label == _copyUnset ? this.label : label as String?,
      meta: meta == _copyUnset ? this.meta : meta as Map<String, dynamic>?,
    );
  }
}

const Object _copyUnset = Object();

ChartDrawingTool _chartDrawingToolFromJson(Object? value) {
  if (value is ChartDrawingTool) {
    return value;
  }
  if (value is String) {
    for (final tool in ChartDrawingTool.values) {
      if (tool.name == value) {
        return tool;
      }
    }
  }
  return ChartDrawingTool.none;
}

int? _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

double? _readDouble(Object? value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}
