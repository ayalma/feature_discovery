import 'package:flutter/rendering.dart';

/// We use [RenderProxyBox] because we only want to clip and keep
/// the properties of the _Content children.
class RenderClipContent extends RenderProxyBox {
  Offset? _center;
  double? _radius;

  RenderClipContent({
    required Offset center,
    required double radius,
  })  : _center = center,
        _radius = radius;

  /// The inner area of the DescribedFeatureOverlay.
  Path get innerCircle => Path()
    ..addOval(Rect.fromCircle(
      center: globalToLocal(_center!),
      radius: _radius!,
    ));

  set center(Offset? center) {
    _center = center;
    markNeedsPaint();
  }

  set radius(double? radius) {
    _radius = radius;
    markNeedsPaint();
  }

  /// We need to make sure that the area outside of the background area can still be tapped
  /// in order to allow dismissal.
  /// The reason this is necessary is that the content that might be overflowing will catch
  /// the hit events even when it is clipped out in paint.
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // If the hit is inside of the inner area of the DescribedFeatureOverlay,
    // we want to catch the hit event and pass it to the children. Otherwise, we want to ignore it in order
    // to allow the GestureDetector in DescribedFeatureOverlay to catch it.
    if (innerCircle.contains(position) &&
        hitTestChildren(result, position: position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }

    return false;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.pushClipPath(needsCompositing, offset,
        Rect.fromLTWH(0, 0, size.width, size.height), innerCircle, super.paint);
  }
}
