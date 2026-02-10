import 'package:flutter/material.dart';

class DraggableLayer extends StatefulWidget {
  final Offset pos;
  final double scale;
  final double rotation;
  final Widget child;
  final bool selected;
  final bool canDelete; // İsteğe bağlı
  final VoidCallback onTap;
  final ValueChanged<Offset> onPos;
  final ValueChanged<double> onScale;
  final ValueChanged<double> onRotation;
  final VoidCallback? onDragEnd; // ✅ EKLENEN KISIM

  const DraggableLayer({
    super.key,
    required this.pos,
    required this.scale,
    required this.rotation,
    required this.child,
    required this.selected,
    required this.onTap,
    required this.onPos,
    required this.onScale,
    required this.onRotation,
    this.canDelete = false,
    this.onDragEnd, // ✅ Constructor'a eklendi
  });

  @override
  State<DraggableLayer> createState() => _DraggableLayerState();
}

class _DraggableLayerState extends State<DraggableLayer> {
  double _baseScale = 1.0;
  double _baseRotation = 0.0;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.pos.dx,
      top: widget.pos.dy,
      child: GestureDetector(
        onTap: widget.onTap,
        onScaleStart: (details) {
          _baseScale = widget.scale;
          _baseRotation = widget.rotation;
        },
        onScaleUpdate: (details) {
          // 1. Pozisyon Güncelleme (Drag)
          // focalPointDelta: O anki hareketin ne kadar yer değiştirdiği
          if (details.pointerCount == 1 || details.pointerCount == 2) {
             widget.onPos(widget.pos + details.focalPointDelta);
          }

          // 2. Scale Güncelleme (Zoom)
          if (details.pointerCount == 2) {
            widget.onScale(_baseScale * details.scale);
            
            // 3. Rotasyon Güncelleme
            widget.onRotation(_baseRotation + details.rotation);
          }
        },
        onScaleEnd: (details) {
          // ✅ Sürükleme bittiğinde burası çalışır
          if (widget.onDragEnd != null) {
            widget.onDragEnd!();
          }
        },
        child: Transform(
          transform: Matrix4.identity()
            ..scale(widget.scale)
            ..rotateZ(widget.rotation),
          alignment: Alignment.center,
          child: Container(
            decoration: widget.selected
                ? BoxDecoration(
                    border: Border.all(color: Colors.white, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  )
                : null,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}