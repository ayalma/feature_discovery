import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class EnsureVisible extends StatefulWidget {
  /// The child widget that we are wrapping
  final Widget child;

  /// The curve we will use to scroll ourselves into view.
  ///
  /// Defaults to Curves.ease.
  final Curve curve;

  /// The duration we will use to scroll ourselves into view
  ///
  /// Defaults to 100 milliseconds.
  final Duration duration;

  const EnsureVisible(
      {Key key,
      this.curve = Curves.ease,
      this.duration = const Duration(milliseconds: 100),
      this.child})
      : super(key: key);

  @override
  EnsureVisibleState createState() => EnsureVisibleState();

  static void ensureVisible(BuildContext context) {
    EnsureVisibleState state =
        context.ancestorStateOfType(TypeMatcher<EnsureVisibleState>())
            as EnsureVisibleState;

    state.ensureVisible();
  }
}

class EnsureVisibleState extends State<EnsureVisible> {
  ensureVisible() {
    final RenderObject object = context.findRenderObject();
    final RenderAbstractViewport viewport = RenderAbstractViewport.of(object);
    assert(viewport != null);

    ScrollableState scrollableState = Scrollable.of(context);
    assert(scrollableState != null);

    ScrollPosition position = scrollableState.position;
    double alignment;
    if (position.pixels > viewport.getOffsetToReveal(object, 0.0).offset) {
      // Move down to the top of the viewport
      alignment = 0.0;
    } else if (position.pixels <
        viewport.getOffsetToReveal(object, 1.0).offset) {
      // Move up to the bottom of the viewport
      alignment = 1.0;
    } else {
      // No scrolling is necessary to reveal the child
      return;
    }
    position.ensureVisible(
      object,
      alignment: alignment,
      duration: widget.duration,
      curve: widget.curve,
    );
  }

  Widget build(BuildContext context) => widget.child;
}
