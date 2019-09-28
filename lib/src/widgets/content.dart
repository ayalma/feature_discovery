import 'dart:math';

import 'package:feature_discovery/src/foundation.dart';
import 'package:feature_discovery/src/rendering.dart';
import 'package:feature_discovery/src/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Content extends StatelessWidget {
  final FeatureOverlayState state;
  final double transitionProgress;
  final Offset anchor;
  final Size screenSize;
  final double touchTargetRadius;

  // Can be null.
  final Widget title;

  // Can be null.
  final Widget description;

  final ContentOrientation orientation;
  final Color textColor;

  final OverflowMode overflowMode;
  final double backgroundRadius;
  final Offset backgroundPosition;

  const Content({
    Key key,
    this.anchor,
    this.screenSize,
    this.touchTargetRadius,
    this.title,
    this.description,
    this.state,
    this.transitionProgress,
    this.orientation,
    this.textColor,
    this.overflowMode,
    this.backgroundRadius,
    this.backgroundPosition,
  })  : assert(anchor != null),
        assert(screenSize != null),
        assert(touchTargetRadius != null),
        assert(state != null),
        assert(transitionProgress != null),
        assert(orientation != null),
        assert(textColor != null),
        super(key: key);

  bool isCloseToTopOrBottom(Offset position) {
    return position.dy <= 88.0 || (screenSize.height - position.dy) <= 88.0;
  }

  bool isOnTopHalfOfScreen(Offset position) {
    return position.dy < (screenSize.height / 2.0);
  }

  bool isOnLeftHalfOfScreen(Offset position) {
    return position.dx < (screenSize.width / 2.0);
  }

  _DescribedFeatureContentOrientation getContentOrientation(Offset position) {
    if (isCloseToTopOrBottom(position))
      return isOnTopHalfOfScreen(position)
          ? _DescribedFeatureContentOrientation.below
          : _DescribedFeatureContentOrientation.above;
    else
      return isOnTopHalfOfScreen(position)
          ? _DescribedFeatureContentOrientation.above
          : _DescribedFeatureContentOrientation.below;
  }

  double opacity() {
    switch (state) {
      case FeatureOverlayState.closed:
        return 0.0;
      case FeatureOverlayState.opening:
        final double adjustedPercent =
            const Interval(0.6, 1.0, curve: Curves.easeOut)
                .transform(transitionProgress);
        return adjustedPercent;
      case FeatureOverlayState.activating:
      case FeatureOverlayState.dismissing:
        final double adjustedPercent =
            const Interval(0.0, 0.4, curve: Curves.easeOut)
                .transform(transitionProgress);
        return 1.0 - adjustedPercent;
      default:
        return 1.0;
    }
  }

  Offset centerPosition() {
    final double width = min(screenSize.width, screenSize.height);
    final bool isBackgroundCentered = isCloseToTopOrBottom(anchor);

    if (isBackgroundCentered)
      return anchor;
    else {
      final Offset startingBackgroundPosition = anchor;
      final Offset endingBackgroundPosition = Offset(
          width / 2.0 + (isOnLeftHalfOfScreen(anchor) ? -20.0 : 20.0),
          anchor.dy +
              (isOnTopHalfOfScreen(anchor)
                  ? -(width / 2) + 40.0
                  : (width / 20.0) - 40.0));

      switch (state) {
        case FeatureOverlayState.opening:
          final double adjustedPercent =
              const Interval(0.0, 0.8, curve: Curves.easeOut)
                  .transform(transitionProgress);
          return Offset.lerp(startingBackgroundPosition,
              endingBackgroundPosition, adjustedPercent);
        case FeatureOverlayState.activating:
          return endingBackgroundPosition;
        case FeatureOverlayState.dismissing:
          return Offset.lerp(endingBackgroundPosition,
              startingBackgroundPosition, transitionProgress);
        default:
          return endingBackgroundPosition;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double contentOffsetMultiplier;

    switch (orientation) {
      case ContentOrientation.trivial:
        contentOffsetMultiplier = getContentOrientation(anchor) ==
                _DescribedFeatureContentOrientation.below
            ? 1.0
            : -1.0;
        break;
      case ContentOrientation.above:
        contentOffsetMultiplier = -1.0;
        break;
      case ContentOrientation.below:
        contentOffsetMultiplier = 1.0;
        break;
    }

    final double width = min(screenSize.width, screenSize.height);

    final double contentY =
        anchor.dy + contentOffsetMultiplier * (touchTargetRadius + 20);

    final double contentFractionalOffset =
        contentOffsetMultiplier.clamp(-1.0, 0.0);

    final double dx = centerPosition().dx - width;
    final double contentX = (dx.isNegative) ? 0.0 : dx;

    Widget result = FractionalTranslation(
      translation: Offset(0.0, contentFractionalOffset),
      child: Opacity(
        opacity: opacity(),
        child: Container(
          width: width,
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.only(left: 40.0, right: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (title != null)
                    DefaultTextStyle(
                      style: Theme.of(context)
                          .textTheme
                          .title
                          .copyWith(color: textColor),
                      child: title,
                    ),
                  if (title != null && description != null)
                    const SizedBox(height: 8.0),
                  if (description != null)
                    DefaultTextStyle(
                      style: Theme.of(context)
                          .textTheme
                          .body1
                          .copyWith(color: textColor.withOpacity(0.9)),
                      child: description,
                    )
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (overflowMode == OverflowMode.clipContent)
      result = _ClipContent(
        backgroundPosition: backgroundPosition,
        backgroundRadius: backgroundRadius,
        child: result,
      );

    result = Positioned(
      top: contentY,
      left: contentX,
      child: result,
    );

    return result;
  }
}

enum _DescribedFeatureContentOrientation {
  above,
  below,
}

// We need a custom RenderObject widget here as we need to convert the backgroundPosition into
// a local position. This can only be achieved using a RenderBox and using BuildContext in a
// build method of a regular widget, you do not have access to the RenderBox of the current
// paint call. Instead, you need to wait until the build phase is done to have access to that RenderObject.
// This means that we would need to rebuild the widget after it has been built once (every time) to get
// the local position, which is not only horribly inefficient, but looks choppy as well because
// the user would see the non-clipped layout first and immediately afterwards see the correct clipped
// layout.
// This is the reason why we need to clip in our custom RenderBox.
class _ClipContent extends SingleChildRenderObjectWidget {
  final double backgroundRadius;
  final Offset backgroundPosition;

  const _ClipContent({
    Key key,
    Widget child,
    this.backgroundPosition,
    this.backgroundRadius,
  }) : super(key: key, child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderClipContent(
        center: backgroundPosition, radius: backgroundRadius);
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderClipContent renderObject) {
    renderObject
      ..center = backgroundPosition
      ..radius = backgroundRadius;
    super.updateRenderObject(context, renderObject);
  }
}
