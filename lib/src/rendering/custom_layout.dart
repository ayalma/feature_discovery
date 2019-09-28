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

    layoutChild(
        BackgroundContentLayout.background,
        BoxConstraints.loose(Size(
          backgroundRadius * 2,
          backgroundRadius * 2,
        )));
    positionChild(
        BackgroundContentLayout.background,
        Offset(
          backgroundCenter.dx - backgroundRadius,
          backgroundCenter.dy - backgroundRadius,
        ));

    layoutChild(BackgroundContentLayout.content, BoxConstraints());
    positionChild(BackgroundContentLayout.content, contentPosition);
  }

  @override
  bool shouldRelayout(BackgroundContentLayoutDelegate oldDelegate) {
    return oldDelegate.overflowMode != overflowMode ||
        oldDelegate.contentPosition != contentPosition ||
        oldDelegate.backgroundCenter != backgroundCenter ||
        oldDelegate.backgroundRadius != backgroundRadius;
  }
}
