// @dart=2.2

import 'dart:math';
import 'package:flutter/animation.dart';

import 'package:feature_discovery/src/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

enum BackgroundContentLayout {
  background,
  content,
}

class BackgroundContentLayoutDelegate extends MultiChildLayoutDelegate {
  /// This padding is applied to the calculated radius of the background
  /// for [OverflowMode.extendBackground] and [OverflowMode.wrapBackground].
  ///
  /// If there was no padding, the background circle might touch the content
  /// right at the edge, which can potentially look bad.
  static const double outerContentPadding = 4.0;

  final OverflowMode overflowMode;

  final Offset contentPosition;
  final double contentOffsetMultiplier;

  final Offset backgroundCenter;

  /// This radius does not reflect the rendered value.
  /// Instead, it is a default value that is used for [OverflowMode.ignore],
  /// [OverflowMode.clipContent], and considered for [OverflowMode.extendBackground].
  ///
  /// [OverflowMode.wrapBackground] completely ignores this value.
  ///
  /// Furthermore, the value is further adjusted based on [transitionProgress] and [state].
  final double backgroundRadius;

  final Offset anchor;

  final FeatureOverlayState state;
  final double transitionProgress;

  BackgroundContentLayoutDelegate({
    @required this.overflowMode,
    @required this.contentPosition,
    @required this.backgroundCenter,
    @required this.backgroundRadius,
    @required this.anchor,
    @required this.contentOffsetMultiplier,
    @required this.state,
    @required this.transitionProgress,
  })  : assert(overflowMode != null),
        assert(contentPosition != null),
        assert(backgroundCenter != null),
        assert(backgroundRadius != null),
        assert(state != null),
        assert(anchor != null);

  @override
  void performLayout(Size size) {
    assert(hasChild(BackgroundContentLayout.background));
    assert(hasChild(BackgroundContentLayout.content));

    final contentSize =
        layoutChild(BackgroundContentLayout.content, const BoxConstraints());

    // Do calculations regarding the sizing of the background.
    final backgroundPoint = Point(backgroundCenter.dx, backgroundCenter.dy),
        anchorPoint = Point(anchor.dx, anchor.dy),
        contentPoint = Point(
      contentPosition.dx,
      // If the content is rendered above the tap target, it needs to be shifted up.
      contentPosition.dy +
          contentOffsetMultiplier.clamp(-1, 0) * contentSize.height,
    );

    double matchedRadius;

    // The background radius is not affected when the overflow mode is ignore or clipContent.
    if (overflowMode == OverflowMode.ignore ||
        overflowMode == OverflowMode.clipContent)
      matchedRadius = backgroundRadius;
    else {
      // 75 is the radius of the pulse when fully expanded.
      // Calculating the distance here is easy because the pulse is a circle.
      final distanceToOuterPulse = anchorPoint.distanceTo(backgroundPoint) + 75;

      // Calculate distance to the furthest point of the content.
      final contentArea = Rect.fromLTWH(contentPoint.x, contentPoint.y,
          contentSize.width, contentSize.height);
      // This is equal to finding the max out of the distances to the corners of the Rect.
      // It is just the more Math-esque approach.
      // See the commented out code below for an intuitive approach.
      final contentDx = max((contentArea.left - backgroundPoint.x).abs(),
              (contentArea.right - backgroundPoint.x)),
          contentDy = max((contentArea.top - backgroundPoint.y).abs(),
              (contentArea.bottom - backgroundPoint.y).abs());
//    // We take the corners of the content because these are the furthest away in every scenario.
//    final List<Point> contentAreaCorners = <Offset>[
//      contentArea.topRight,
//      contentArea.topLeft,
//      contentArea.bottomLeft,
//      contentArea.bottomRight
//    ].map<Point>((offset) => Point(offset.dx, offset.dy)).toList();
//
//    final double distanceToOuterContent = contentAreaCorners
//        .map<double>((point) => point.distanceTo(backgroundPoint))
//        .reduce(max);
      final distanceToOuterContent =
          sqrt(contentDx * contentDx + contentDy * contentDy);

      final calculatedRadius =
          max(distanceToOuterContent, distanceToOuterPulse) +
              outerContentPadding;

      matchedRadius = (calculatedRadius > backgroundRadius &&
                  (overflowMode == OverflowMode.extendBackground ||
                      overflowMode == OverflowMode.wrapBackground)) ||
              (calculatedRadius < backgroundRadius &&
                  overflowMode == OverflowMode.wrapBackground)
          ? calculatedRadius
          : backgroundRadius;
    }

    // This transforms the matched radius based on the current overlay
    // state and transition progress.
    switch (state) {
      case FeatureOverlayState.opening:
        matchedRadius *= const Interval(0, 0.8, curve: Curves.easeOut)
            .transform(transitionProgress);
        break;
      case FeatureOverlayState.completing:
        matchedRadius += transitionProgress * 40;
        break;
      case FeatureOverlayState.dismissing:
        matchedRadius *= 1 - transitionProgress;
        break;
      case FeatureOverlayState.opened:
        break;
      case FeatureOverlayState.closed:
        matchedRadius = 0;
        break;
      default:
        // The switch statement should be exhaustive.
        throw ArgumentError.value(state);
    }

    layoutChild(
        BackgroundContentLayout.background,
        BoxConstraints.loose(Size(
          matchedRadius * 2,
          matchedRadius * 2,
        )));

    // Positioning does not give us any information to work with,
    // so we can do it at the end. The order does not matter either.
    positionChild(
      BackgroundContentLayout.content,
      Offset(
        contentPoint.x,
        contentPoint.y,
      ),
    );
    positionChild(
        BackgroundContentLayout.background,
        Offset(
          backgroundCenter.dx - matchedRadius,
          backgroundCenter.dy - matchedRadius,
        ));
  }

  @override
  bool shouldRelayout(BackgroundContentLayoutDelegate oldDelegate) =>
      oldDelegate.overflowMode != overflowMode ||
      oldDelegate.contentPosition != contentPosition ||
      oldDelegate.backgroundCenter != backgroundCenter ||
      oldDelegate.backgroundRadius != backgroundRadius;
}
