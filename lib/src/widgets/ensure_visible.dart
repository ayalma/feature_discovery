import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class EnsureVisible extends StatefulWidget {
  /// The child widget that we are wrapping
  final Widget child;

  const EnsureVisible({Key? key, required this.child}) : super(key: key);

  @override
  EnsureVisibleState createState() => EnsureVisibleState();

  static void ensureVisible(BuildContext context) {
    context.findAncestorStateOfType<EnsureVisibleState>()!.ensureVisible();
  }
}

class EnsureVisibleState extends State<EnsureVisible> {
  /// If you omit [preciseAlignment] or pass `null`, the widget will just be scrolled into view,
  /// i.e. the scroll view will be scrolled just enough for the widget to appear at the bottom
  /// or top of the viewport.
  /// This will take a duration specified by [duration] and follow a curve specified by [curve].
  /// The [duration] defaults to 100 milliseconds and the [curve] to [Curves.ease].
  ///
  /// If you want to have the widget scrolled to a specific alignment, you need to set [preciseAlignment].
  /// This value represents to what extent your widget should be scrolled into the viewport:
  ///
  ///   * `preciseAlignment: 0` will scroll your widget to the start of your viewport.
  ///   * `preciseAlignment: 0.5` will scroll your widget to the center of your viewport.
  ///   * `preciseAlignment: 1` will scroll your widget to the end of your viewport.
  ///   * `preciseAlignment: null` or just omitting it will let the package handle the alignment
  ///     and will just scroll your widget into view.
  Future<void> ensureVisible({
    Duration duration = const Duration(milliseconds: 100),
    Curve curve = Curves.ease,
    double? preciseAlignment,
  }) async {
    assert(
        preciseAlignment == null ||
            (preciseAlignment > 0 && preciseAlignment < 1),
        'The alignment needs to be null or between 0 and 1.');

    final renderObject = context.findRenderObject();
    final viewport = RenderAbstractViewport.of(renderObject)!;

    final scrollableState = Scrollable.of(context)!;

    final position = scrollableState.position;
    double alignment;

    if (preciseAlignment != null) {
      alignment = preciseAlignment;
      // Only if the precise alignment exactly matches the current position no scrolling is necessary.
      if (position.pixels ==
          viewport.getOffsetToReveal(renderObject!, preciseAlignment).offset)
        return;
    } else if (position.pixels >
        viewport.getOffsetToReveal(renderObject!, 0).offset) {
      // Move down to the top of the viewport
      alignment = 0;
    } else if (position.pixels <
        viewport.getOffsetToReveal(renderObject, 1).offset) {
      // Move up to the bottom of the viewport
      alignment = 1;
    } else {
      // No scrolling is necessary to reveal the child
      return;
    }
    return await position.ensureVisible(
      renderObject,
      alignment: alignment,
      duration: duration,
      curve: curve,
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
