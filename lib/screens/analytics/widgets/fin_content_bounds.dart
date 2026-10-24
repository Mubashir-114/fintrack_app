import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Reports content painted beneath FIN without changing its layout constraints.
/// Background surfaces are intentionally excluded; text, imagery, charts and
/// semantic controls retain a small clearance around their actual paint bounds.
class FinContentBounds extends SingleChildRenderObjectWidget {
  const FinContentBounds({
    super.key,
    required this.bounds,
    required super.child,
  });

  final ValueNotifier<List<Rect>> bounds;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _ContentBounds(bounds);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderObject renderObject,
  ) {
    (renderObject as _ContentBounds).bounds = bounds;
  }
}

class _ContentBounds extends RenderProxyBox {
  _ContentBounds(this.bounds);
  ValueNotifier<List<Rect>> bounds;
  bool _pending = false;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _measureAfterFrame();
  }

  // Observe frames already requested by content or scrolling. Never request a
  // frame ourselves: resting screens and reduced motion stay quiescent.
  void _measureAfterFrame() {
    if (_pending) return;
    _pending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pending = false;
      if (!attached) return;
      final occupied = <Rect>[];
      void visit(RenderObject object) {
        if (!object.attached) return;
        final protectsControl =
            object is RenderSemanticsAnnotations &&
            (object.properties.button == true ||
                object.properties.textField == true);
        final protectsPaint =
            object is RenderParagraph ||
            object is RenderImage ||
            object.runtimeType.toString().contains('Chart') ||
            (object is RenderCustomPaint &&
                object.painter != null &&
                !object.painter.runtimeType.toString().contains('ShapeBorder'));
        if ((protectsControl || protectsPaint) &&
            object is RenderBox &&
            object.hasSize) {
          final rect = MatrixUtils.transformRect(
            object.getTransformTo(this),
            object.paintBounds,
          ).inflate(8);
          if (rect.isFinite && !rect.isEmpty) occupied.add(rect);
          if (protectsControl) return;
        }
        object.visitChildren(visit);
      }

      visit(this);
      if (!listEquals(bounds.value, occupied)) bounds.value = occupied;
      _measureAfterFrame();
    });
  }
}
