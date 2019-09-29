import 'package:feature_discovery/src/rendering.dart';
import 'package:feature_discovery/src/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Content extends StatelessWidget {
  final FeatureOverlayState state;
  final double transitionProgress;

  /// Can be null.
  final Widget title;

  /// Can be null.
  final Widget description;

  final Color textColor;

  final OverflowMode overflowMode;
  final double backgroundRadius;
  final Offset backgroundCenter;

  final double width;

  const Content({
    Key key,
    @required this.title,
    @required this.description,
    @required this.state,
    @required this.transitionProgress,
    @required this.textColor,
    @required this.overflowMode,
    @required this.backgroundRadius,
    @required this.backgroundCenter,
    @required this.width,
  })  : assert(state != null),
        assert(width != null),
        assert(transitionProgress != null),
        assert(textColor != null),
        super(key: key);

  double get opacity {
    switch (state) {
      case FeatureOverlayState.closed:
        return 0;
      case FeatureOverlayState.opening:
        final double adjustedPercent =
            const Interval(0.6, 1, curve: Curves.easeOut)
                .transform(transitionProgress);
        return adjustedPercent;
      case FeatureOverlayState.completing:
      case FeatureOverlayState.dismissing:
        final double adjustedPercent =
            const Interval(0, 0.4, curve: Curves.easeOut)
                .transform(transitionProgress);
        return 1 - adjustedPercent;
      case FeatureOverlayState.opened:
        return 1;
    }
    throw ArgumentError.value(state);
  }

  @override
  Widget build(BuildContext context) {
    Widget result = Opacity(
      opacity: opacity,
      child: ConstrainedBox(
        constraints: BoxConstraints.loose(Size(
          width,
          double.infinity,
        )),
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
    );

    if (overflowMode == OverflowMode.clipContent)
      result = _ClipContent(
        backgroundCenter: backgroundCenter,
        backgroundRadius: backgroundRadius,
        child: result,
      );

    return result;
  }
}

// We need a custom RenderObject widget here as we need to convert the backgroundCenter into
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
  final Offset backgroundCenter;

  const _ClipContent({
    Key key,
    Widget child,
    this.backgroundCenter,
    this.backgroundRadius,
  }) : super(key: key, child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderClipContent(
        center: backgroundCenter, radius: backgroundRadius);
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderClipContent renderObject) {
    renderObject
      ..center = backgroundCenter
      ..radius = backgroundRadius;
    super.updateRenderObject(context, renderObject);
  }
}
