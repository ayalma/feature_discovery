import 'dart:math';
import 'package:meta/meta.dart';

import 'package:feature_discovery/src/widgets.dart';
import 'package:flutter/rendering.dart';

enum BackgroundContentLayout {
  background,
  content,
}

class BackgroundContentLayoutDelegate extends MultiChildLayoutDelegate {
  /// This padding is applied to the calculated radius of the background
  /// for [OverflowMode.extendBackground] and [OverflowMode.wrapBackground].
  static const double outerContentPadding = 6.0;

  final OverflowMode overflowMode;

  final Offset contentPosition;

  final Offset backgroundCenter;
  final double backgroundRadius;

  final Offset anchor;

  BackgroundContentLayoutDelegate({
    @required this.overflowMode,
    @required this.contentPosition,
    @required this.backgroundCenter,
    @required this.backgroundRadius,
    @required this.anchor,
  })  : assert(overflowMode != null),
        assert(contentPosition != null),
        assert(backgroundCenter != null),
        assert(backgroundRadius != null),
        assert(anchor != null);

  @override
  void performLayout(Size size) {
    assert(hasChild(BackgroundContentLayout.background));
    assert(hasChild(BackgroundContentLayout.content));

    final contentSize =
        layoutChild(BackgroundContentLayout.content, const BoxConstraints());
    positionChild(BackgroundContentLayout.content, contentPosition);

    // Do calculations regarding the sizing of the background.
    final backgroundPoint = Point(backgroundCenter.dx, backgroundCenter.dy),
        anchorPoint = Point(anchor.dx, anchor.dy),
        contentPoint = Point(contentPosition.dx, contentPosition.dy);

    // 75 is the radius of the pulse when fully expanded.
    // Calculating the distance here is easy because the pulse is a circle.
    final distanceToOuterPulse = anchorPoint.distanceTo(backgroundPoint) + 75;

    // Calculate distance to the furthest point of the content.
    final Rect contentArea = Rect.fromLTWH(
        contentPoint.x, contentPoint.y, contentSize.width, contentSize.height);
    final double contentDx = max((contentArea.left - backgroundPoint.x).abs(),
            (contentArea.right - backgroundPoint.x)),
        contentDy = max((contentArea.top - backgroundPoint.y).abs(),
            (contentArea.bottom - backgroundPoint.y).abs());
    final distanceToOuterContent =
        sqrt(contentDx * contentDx + contentDy * contentDy);

    final calculatedRadius =
        max(distanceToOuterContent, distanceToOuterPulse) + outerContentPadding;

    // todo fix extendBackground
    // todo fix wrapBackground

    final matchedRadius = (calculatedRadius > backgroundRadius &&
                (overflowMode == OverflowMode.extendBackground ||
                    overflowMode == OverflowMode.wrapBackground)) ||
            (calculatedRadius < backgroundRadius &&
                overflowMode == OverflowMode.wrapBackground)
        ? calculatedRadius
        : backgroundRadius;

    layoutChild(
        BackgroundContentLayout.background,
        BoxConstraints.loose(Size(
          matchedRadius * 2,
          matchedRadius * 2,
        )));
    positionChild(
        BackgroundContentLayout.background,
        Offset(
          backgroundCenter.dx - matchedRadius,
          backgroundCenter.dy - matchedRadius,
        ));
  }

  @override
  bool shouldRelayout(BackgroundContentLayoutDelegate oldDelegate) {
    return oldDelegate.overflowMode != overflowMode ||
        oldDelegate.contentPosition != contentPosition ||
        oldDelegate.backgroundCenter != backgroundCenter ||
        oldDelegate.backgroundRadius != backgroundRadius;
  }
}
