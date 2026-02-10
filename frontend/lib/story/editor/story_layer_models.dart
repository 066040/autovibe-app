import 'dart:math';
import 'package:flutter/material.dart';

/// Layer tipi
enum StoryLayerType {
  text,
  image,
}

/// Text hizalama (Instagram uyumlu)
enum StoryTextAlign {
  left,
  center,
  right,
}

/// Ortak story layer modeli
class StoryLayer {
  // ---- Identity ----
  final String id;
  final StoryLayerType type;

  // ---- Transform ----
  Offset position;      // canvas üzerindeki konum (px)
  double scale;         // pinch ile (0.2 – 6)
  double rotation;      // radians

  // ---- TEXT ----
  String text;
  double fontSize;      // base size (scale ile büyür)
  String fontFamily;    // 'System', 'Roboto', 'Montserrat', ...
  Color color;
  bool bold;
  bool hasBackground;
  bool stroke;
  StoryTextAlign align;

  // ---- IMAGE / STICKER ----
  String imagePath;
  double baseWidth;     // px (scale ile büyür)

  // =========================
  // TEXT CONSTRUCTOR
  // =========================
  StoryLayer.text({
    required this.id,
    required this.position,
    this.scale = 1.0,
    this.rotation = 0.0,

    required this.text,
    this.fontSize = 42,
    this.fontFamily = 'System',
    this.color = Colors.white,
    this.bold = true,
    this.hasBackground = false,
    this.stroke = true,
    this.align = StoryTextAlign.center,
  })  : type = StoryLayerType.text,
        imagePath = '',
        baseWidth = 0;

  // =========================
  // IMAGE / STICKER CONSTRUCTOR
  // =========================
  StoryLayer.image({
    required this.id,
    required this.position,
    this.scale = 1.0,
    this.rotation = 0.0,

    required this.imagePath,
    this.baseWidth = 260,
  })  : type = StoryLayerType.image,
        text = '',
        fontSize = 0,
        fontFamily = 'System',
        color = Colors.white,
        bold = false,
        hasBackground = false,
        stroke = false,
        align = StoryTextAlign.center;

  // =========================
  // HELPERS
  // =========================

  bool get isText => type == StoryLayerType.text;
  bool get isImage => type == StoryLayerType.image;

  StoryLayer copy() {
    return StoryLayer._internal(
      id: id,
      type: type,
      position: position,
      scale: scale,
      rotation: rotation,
      text: text,
      fontSize: fontSize,
      fontFamily: fontFamily,
      color: color,
      bold: bold,
      hasBackground: hasBackground,
      stroke: stroke,
      align: align,
      imagePath: imagePath,
      baseWidth: baseWidth,
    );
  }

  // Private internal constructor (copy için)
  StoryLayer._internal({
    required this.id,
    required this.type,
    required this.position,
    required this.scale,
    required this.rotation,
    required this.text,
    required this.fontSize,
    required this.fontFamily,
    required this.color,
    required this.bold,
    required this.hasBackground,
    required this.stroke,
    required this.align,
    required this.imagePath,
    required this.baseWidth,
  });

  // Unique id üret
  static String newId() =>
      '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(9999)}';
}
