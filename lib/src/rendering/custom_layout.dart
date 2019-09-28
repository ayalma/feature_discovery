import 'dart:math';

import 'package:feature_discovery/src/widgets.dart';
import 'package:flutter/rendering.dart';

enum BackgroundContentLayout {
  background,
  content,
}

class BackgroundContentLayoutDelegate extends MultiChildLayoutDelegate {
  final OverflowMode overflowMode;

  final Offset contentPosition;

  final Offset backgroundCenter;
  final double backgroundRadius;

  BackgroundContentLayoutDelegate({
    this.overflowMode,
    this.contentPosition,
    this.backgroundCenter,
    this.backgroundRadius,
  })  : assert(overflowMode != null),
        assert(contentPosition != null),
        assert(backgroundCenter != null),
        assert(backgroundRadius != null);

  @override
  void performLayout(Size size) {
    assert(hasChild(BackgroundContentLayout.background));
    assert(hasChild(BackgroundContentLayout.content));

    final contentSize =
        layoutChild(BackgroundContentLayout.content, BoxConstraints());
    positionChild(BackgroundContentLayout.content, contentPosition);

    final backgroundDiameter = overflowMode == OverflowMode.extendBackground
        ? (Point(contentPosition.dx, contentPosition.dy)
                .distanceTo(Point(backgroundCenter.dx, backgroundCenter.dy)) +
            max(contentSize.height, contentSize.width) * 2)
        : backgroundRadius * 2;

    layoutChild(
        BackgroundContentLayout.background,
        BoxConstraints.loose(Size(
          backgroundDiameter,
          backgroundDiameter,
        )));
    positionChild(
        BackgroundContentLayout.background,
        Offset(
          backgroundCenter.dx - backgroundDiameter / 2,
          backgroundCenter.dy - backgroundDiameter / 2,
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
