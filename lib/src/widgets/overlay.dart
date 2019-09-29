import 'dart:async';
import 'dart:math';

import 'package:feature_discovery/src/foundation.dart';
import 'package:feature_discovery/src/rendering.dart';
import 'package:feature_discovery/src/widgets.dart';
import 'package:flutter/material.dart';

class DescribedFeatureOverlay extends StatefulWidget {
  /// This id should be unique among all the [DescribedFeatureOverlay] widgets.
  /// Otherwise, multiple overlays would show at once, which is currently
  /// only possible if [allowShowingDuplicate] is set to `true`.
  final String featureId;

  /// By default, for every feature id, i.e. for every step in the feature discovery,
  /// there can only be a single active overlay at a time as the default value
  /// for [allowShowingDuplicate] is `false`.
  ///
  /// This measure was taken primarily to prevent duplicate overlays from showing
  /// when the same widget is inserted into the widget tree multiple times,
  /// e.g. when there is an open [DropdownButton].
  ///
  /// If you want to display multiple overlays for the same step, i.e.
  /// for the same feature id, at once, you will have to set this to `true`.
  final bool allowShowingDuplicate;

  /// The color of the large circle, where the text sits on.
  /// If null, defaults to [ThemeData.primaryColor].
  final Color backgroundColor;

  /// Color of the target, that is the small circle behind the tap target.
  final Color targetColor;

  /// Color for title and text.
  final Color textColor;

  /// This is the first content widget, i.e. it is displayed above [description].
  ///
  /// It is intended for this to contain a [Text] widget, however, you can pass
  /// any [Widget].
  /// The overlay uses a [DefaultTextStyle] for the title, which is a combination
  /// of [TextTheme.title] from [Theme] and the [textColor].
  final Widget title;

  /// This is the second content widget, i.e. it is displayed below [description].
  ///
  /// It is intended for this to contain a [Text] widget, however, you can pass
  /// any [Widget].
  /// The overlay uses a [DefaultTextStyle] for the description, which is a combination
  /// of [TextTheme.body1] from [Theme] and the [textColor].
  final Widget description;

  /// This is usually an [Icon].
  /// The final tap target will already have a tap listener to finish each step.
  ///
  /// If you want to hit the tap target in integration tests, you should pass a [Key]
  /// to this [Widget] instead of as the [Key] of [DescribedFeatureOverlay].
  final Widget tapTarget;

  final Widget child;
  final ContentLocation contentLocation;
  final bool enablePulsingAnimation;

  /// Called just before the overlay is displayed.
  /// This function needs to return a [bool], either from an `async` scope
  /// or as a [Future].
  ///
  /// If this function returns `false`, this step will be marked complete
  /// and therefore be skipped, i.e. it will not be opened.
  /// In this case, we try to open the next step.
  ///
  /// When the [Future] finishes and evaluates to `true`, this step will be shown.
  final Future<bool> Function() onOpen;

  /// Called whenever the user taps outside the overlay area.
  /// This function needs to return a [bool], either from an `async` scope
  /// or as a [Future].
  ///
  /// If the function returns `false`, nothing happens. If it returns `true`,
  /// all of the current steps are dismissed.
  final Future<bool> Function() onDismiss;

  /// Called when the tap target is tapped.
  /// Whenever the [Future] this function returns is finished, the feature discovery
  /// will continue and the next step will try to open after a closing animation.
  final Future<void> Function() onComplete;

  /// Controls what happens with content that overflows the background's area.
  ///
  /// Defaults to [OverflowMode.ignore].
  ///
  /// Important consideration: if your content is overflowing the inner area, it will catch hit events
  /// and if you do not handle these correctly, the user might not be able to dismiss your feature
  /// overlay by tapping outside of the circle. If you use [OverflowMode.clipContent], the package takes
  /// care of hit testing and allows the user to tap outside the circle even if your content would
  /// appear there without clipping.
  ///
  /// See also:
  ///
  ///  * [OverflowMode], which has explanations for the different modes.
  final OverflowMode overflowMode;

  const DescribedFeatureOverlay({
    Key key,
    @required this.featureId,
    @required this.tapTarget,
    this.backgroundColor,
    this.targetColor = Colors.white,
    this.textColor = Colors.white,
    this.title,
    this.description,
    @required this.child,
    this.onComplete,
    this.onDismiss,
    this.onOpen,
    this.contentLocation = ContentLocation.trivial,
    this.enablePulsingAnimation = true,
    this.allowShowingDuplicate = false,
    this.overflowMode = OverflowMode.ignore,
  })  : assert(featureId != null),
        assert(tapTarget != null),
        assert(child != null),
        assert(contentLocation != null),
        assert(enablePulsingAnimation != null),
        assert(targetColor != null),
        assert(textColor != null),
        assert(overflowMode != null),
        super(key: key);

  @override
  _DescribedFeatureOverlayState createState() =>
      _DescribedFeatureOverlayState();
}

class _DescribedFeatureOverlayState extends State<DescribedFeatureOverlay>
    with TickerProviderStateMixin {
  Size _screenSize;

  FeatureOverlayState _state;

  double _transitionProgress;

  AnimationController _openController;
  AnimationController _completeController;
  AnimationController _dismissController;
  AnimationController _pulseController;

  Stream<String> _startStream;
  Stream<String> _dismissStream;
  Stream<String> _completeStream;
  StreamSubscription<String> _startStreamSubscription;
  StreamSubscription<String> _dismissStreamSubscription;
  StreamSubscription<String> _completeStreamSubscription;

  /// The local reference to the [Bloc] is needed because it is used in [dispose].
  Bloc bloc;

  @override
  void initState() {
    _state = FeatureOverlayState.closed;

    _transitionProgress = 1;

    _initAnimationControllers();

    super.initState();
  }

  @override
  void dispose() {
    _openController.dispose();
    _completeController.dispose();
    _dismissController.dispose();
    _pulseController.dispose();

    // If this widget is disposed while still showing an overlay,
    // it needs to remove itself from the active overlays.
    //
    // This is not done when closing the overlay because the Bloc
    // resets the activeOverlays and this would interfere with that.
    //
    // Dismissing and activating are not considered "showing" in this case
    // because the Bloc will already have dealt with the activeOverlays as
    // it triggered the completion or dismissal animation.
    if (_state != FeatureOverlayState.closed &&
        _state != FeatureOverlayState.dismissing &&
        _state != FeatureOverlayState.activating) {
      // If the _state is anything else, this overlay has to be showing,
      // otherwise something is wrong.
      assert(bloc.activeFeatureId == widget.featureId);

      bloc.activeOverlays--;
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(DescribedFeatureOverlay oldWidget) {
    if (oldWidget.enablePulsingAnimation != widget.enablePulsingAnimation) {
      if (widget.enablePulsingAnimation)
        _pulseController.forward(from: 0);
      else {
        _pulseController.stop();
        setState(() => _transitionProgress = 0);
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeDependencies() {
    _screenSize = MediaQuery.of(context).size;

    bloc = Bloc.of(context);
    final Stream<String> newDismissStream = bloc.outDismiss;
    final Stream<String> newCompleteStream = bloc.outComplete;
    final Stream<String> newStartStream = bloc.outStart;

    if (_dismissStream != newDismissStream) _setDismissStream(newDismissStream);
    if (_completeStream != newCompleteStream)
      _setCompleteStream(newCompleteStream);
    if (_startStream != newStartStream) _setStartStream(newStartStream);

    // If this widget was not in the tree when the feature discovery was started,
    // we need to open it immediately because the streams will not receive
    // any further events that could open the overlay.
    if (bloc.activeFeatureId == widget.featureId &&
        _state == FeatureOverlayState.closed) _open();

    super.didChangeDependencies();
  }

  void _setDismissStream(Stream<void> newStream) {
    _dismissStreamSubscription?.cancel();
    _dismissStream = newStream;
    _dismissStreamSubscription =
        _dismissStream.listen((String featureId) async {
      assert(featureId != null);

      if (featureId == widget.featureId && _state == FeatureOverlayState.opened)
        await _dismiss();
    });
  }

  void _setCompleteStream(Stream<void> newStream) {
    _completeStreamSubscription?.cancel();
    _completeStream = newStream;
    _completeStreamSubscription =
        _completeStream.listen((String featureId) async {
      assert(featureId != null);

      if (featureId == widget.featureId && _state == FeatureOverlayState.opened)
        await _complete();
    });
  }

  void _setStartStream(Stream<void> newStream) {
    _startStreamSubscription?.cancel();
    _startStream = newStream;
    _startStreamSubscription = _startStream.listen((String featureId) async {
      assert(featureId != null);

      if (featureId == widget.featureId && _state == FeatureOverlayState.closed)
        await _open();
    });
  }

  void _initAnimationControllers() {
    _openController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 250))
          ..addListener(
              () => setState(() => _transitionProgress = _openController.value))
          ..addStatusListener(
            (AnimationStatus status) {
              if (status == AnimationStatus.forward &&
                  _state == FeatureOverlayState.closed) {
                setState(() => _state = FeatureOverlayState.opening);
                return;
              }

              if (status == AnimationStatus.completed) {
                if (widget.enablePulsingAnimation == true)
                  _pulseController.forward(from: 0.0);

                assert(_state == FeatureOverlayState.opening);
                setState(() => _state = FeatureOverlayState.opened);
              }
            },
          );

    _pulseController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 1000))
          ..addListener(() {
            setState(() => _transitionProgress = _pulseController.value);
          })
          ..addStatusListener(
            (AnimationStatus status) {
              if (status == AnimationStatus.completed)
                _pulseController.forward(from: 0.0);
            },
          );

    _completeController = AnimationController(
        vsync: this, duration: Duration(milliseconds: 250))
      ..addListener(
          () => setState(() => _transitionProgress = _completeController.value))
      ..addStatusListener(
        (AnimationStatus status) {
          if (status == AnimationStatus.forward &&
              _state == FeatureOverlayState.opened)
            setState(() => _state = FeatureOverlayState.activating);
        },
      );

    _dismissController = AnimationController(
        vsync: this, duration: Duration(milliseconds: 250))
      ..addListener(
          () => setState(() => _transitionProgress = _dismissController.value))
      ..addStatusListener(
        (AnimationStatus status) {
          if (status == AnimationStatus.forward &&
              _state == FeatureOverlayState.opened)
            setState(() => _state = FeatureOverlayState.dismissing);
        },
      );
  }

  void _show() {
    // The activeStep might have changed by now because onOpen is asynchronous.
    if (FeatureDiscovery.activeFeatureId(context) != widget.featureId) return;

    _openController.forward(from: 0.0);
  }

  Future<void> _open() async {
    if (!widget.allowShowingDuplicate && bloc.activeOverlays > 0) return;

    bloc.activeOverlays++;

    if (widget.onOpen != null) {
      final bool shouldOpen = await widget.onOpen();
      assert(shouldOpen != null,
          "You must return true or false at the end of the [onOpen] function");
      if (shouldOpen)
        _show();
      else
        FeatureDiscovery.completeCurrentStep(context);
    } else
      _show();
  }

  Future<void> _complete() async {
    if (_completeController.isAnimating) return;

    if (widget.onComplete != null) await widget.onComplete();
    _openController.stop();
    _pulseController.stop();

    await _completeController.forward(from: 0.0);
    // This will be called after the animation is done because the TickerFuture
    // from forward is completed when the animation is complete.
    _close();
  }

  Future<void> _dismiss() async {
    // The method might be triggered multiple times, especially when swiping.
    if (_dismissController.isAnimating) return;

    if (widget.onDismiss != null) {
      final bool shouldDismiss = await widget.onDismiss();
      assert(shouldDismiss != null);
      if (!shouldDismiss) return;
    }
    _openController.stop();
    _pulseController.stop();

    await _dismissController.forward(from: 0.0);
    // This will be called after the animation is done because the TickerFuture
    // from forward is completed when the animation is complete.
    _close();
  }

  /// This method is used by both [_dismiss] and [_complete]
  /// to properly close the overlay after the animations are finished.
  void _close() {
    assert(_state == FeatureOverlayState.activating ||
        _state == FeatureOverlayState.dismissing);
    setState(() {
      _state = FeatureOverlayState.closed;
    });
  }

  bool _isCloseToTopOrBottom(Offset position) {
    return position.dy <= 88.0 || (_screenSize.height - position.dy) <= 88.0;
  }

  bool _isOnTopHalfOfScreen(Offset position) {
    return position.dy < (_screenSize.height / 2.0);
  }

  bool _isOnLeftHalfOfScreen(Offset position) {
    return position.dx < (_screenSize.width / 2.0);
  }

  double _backgroundRadius(Offset anchor) {
    final bool isBackgroundCentered = _isCloseToTopOrBottom(anchor);
    final double backgroundRadius = min(_screenSize.width, _screenSize.height) *
        (isBackgroundCentered ? 1.0 : 0.7);
    switch (_state) {
      case FeatureOverlayState.opening:
        final double adjustedPercent =
            const Interval(0.0, 0.8, curve: Curves.easeOut)
                .transform(_transitionProgress);
        return backgroundRadius * adjustedPercent;
      case FeatureOverlayState.activating:
        return backgroundRadius + _transitionProgress * 40.0;
      case FeatureOverlayState.dismissing:
        return backgroundRadius * (1 - _transitionProgress);
      case FeatureOverlayState.opened:
        return backgroundRadius;
      case FeatureOverlayState.closed:
        return 0;
    }
    throw ArgumentError.value(_state);
  }

  Offset _backgroundPosition(Offset anchor, ContentLocation contentLocation) {
    final double width = min(_screenSize.width, _screenSize.height);
    final bool isBackgroundCentered = _isCloseToTopOrBottom(anchor);

    if (isBackgroundCentered) {
      return anchor;
    } else {
      final startingBackgroundPosition = anchor;

      Offset endingBackgroundPosition;
      switch (contentLocation) {
        case ContentLocation.above:
          endingBackgroundPosition = Offset(
              width / 2.0 + (_isOnLeftHalfOfScreen(anchor) ? -20.0 : 20.0),
              anchor.dy - (width / 2.0) + 40.0);
          break;
        case ContentLocation.below:
          endingBackgroundPosition = Offset(
              width / 2.0 + (_isOnLeftHalfOfScreen(anchor) ? -20.0 : 20.0),
              anchor.dy + (width / 2.0) - 40.0);
          break;
        case ContentLocation.trivial:
          throw ArgumentError.value(contentLocation);
      }

      switch (_state) {
        case FeatureOverlayState.opening:
          final double adjustedPercent =
              const Interval(0.0, 0.8, curve: Curves.easeOut)
                  .transform(_transitionProgress);
          return Offset.lerp(startingBackgroundPosition,
              endingBackgroundPosition, adjustedPercent);
        case FeatureOverlayState.activating:
          return endingBackgroundPosition;
        case FeatureOverlayState.dismissing:
          return Offset.lerp(endingBackgroundPosition,
              startingBackgroundPosition, _transitionProgress);
        case FeatureOverlayState.opened:
          return endingBackgroundPosition;
        case FeatureOverlayState.closed:
          return startingBackgroundPosition;
      }
      throw ArgumentError.value(_state);
    }
  }

  ContentLocation _nonTrivialContentOrientation(Offset anchor) {
    if (widget.contentLocation != ContentLocation.trivial)
      return widget.contentLocation;

    // Calculates appropriate content location for ContentLocation.trivial.
    if (_isCloseToTopOrBottom(anchor))
      return _isOnTopHalfOfScreen(anchor)
          ? ContentLocation.below
          : ContentLocation.above;
    else
      return _isOnTopHalfOfScreen(anchor)
          ? ContentLocation.above
          : ContentLocation.below;
  }

  Offset _contentCenterPosition(Offset anchor) {
    final double width = min(_screenSize.width, _screenSize.height);
    final bool isBackgroundCentered = _isCloseToTopOrBottom(anchor);

    if (isBackgroundCentered)
      return anchor;
    else {
      final Offset startingBackgroundPosition = anchor;
      final Offset endingBackgroundPosition = Offset(
          width / 2.0 + (_isOnLeftHalfOfScreen(anchor) ? -20.0 : 20.0),
          anchor.dy +
              (_isOnTopHalfOfScreen(anchor)
                  ? -(width / 2) + 40.0
                  : (width / 20.0) - 40.0));

      switch (_state) {
        case FeatureOverlayState.opening:
          final double adjustedPercent =
              const Interval(0.0, 0.8, curve: Curves.easeOut)
                  .transform(_transitionProgress);
          return Offset.lerp(startingBackgroundPosition,
              endingBackgroundPosition, adjustedPercent);
        case FeatureOverlayState.activating:
          return endingBackgroundPosition;
        case FeatureOverlayState.dismissing:
          return Offset.lerp(endingBackgroundPosition,
              startingBackgroundPosition, _transitionProgress);
        case FeatureOverlayState.opened:
          return endingBackgroundPosition;
        case FeatureOverlayState.closed:
          return startingBackgroundPosition;
      }
      throw ArgumentError.value(_state);
    }
  }

  double _contentOffsetMultiplier(ContentLocation orientation) {
    assert(orientation != ContentLocation.trivial);

    if (orientation == ContentLocation.above) return -1;

    return 1;
  }

  Widget _buildOverlay(Offset anchor) {
    // This will be assigned either above or below, i.e. trivial from
    // widget.contentLocation will be converted to above or below.
    final ContentLocation contentLocation =
        _nonTrivialContentOrientation(anchor);
    assert(contentLocation != ContentLocation.trivial);

    final Offset backgroundCenter =
        _backgroundPosition(anchor, contentLocation);
    final double backgroundRadius = _backgroundRadius(anchor);

    final double contentOffsetMultiplier =
        _contentOffsetMultiplier(contentLocation);
    final Offset contentCenterPosition = _contentCenterPosition(anchor);

    final double contentWidth = min(_screenSize.width, _screenSize.height);

    final double dx = contentCenterPosition.dx - contentWidth;
    final Offset contentPosition = Offset(
      (dx.isNegative) ? 0.0 : dx,
      anchor.dy +
          contentOffsetMultiplier * (44 + 20), // 44 is the tap target's radius.
    );

    return Stack(
      children: <Widget>[
        GestureDetector(
          onTap: () => FeatureDiscovery.dismiss(context),
          // According to the spec, the user should be able to dismiss by swiping.
          onPanUpdate: (DragUpdateDetails _) =>
              FeatureDiscovery.dismiss(context),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.transparent,
          ),
        ),
        CustomMultiChildLayout(
          delegate: BackgroundContentLayoutDelegate(
            overflowMode: widget.overflowMode,
            contentPosition: contentPosition,
            backgroundCenter: backgroundCenter,
            backgroundRadius: backgroundRadius,
            anchor: anchor,
            contentOffsetMultiplier: contentOffsetMultiplier,
            state: _state,
          ),
          children: <Widget>[
            LayoutId(
              id: BackgroundContentLayout.background,
              child: _Background(
                transitionProgress: _transitionProgress,
                color: widget.backgroundColor ?? Theme.of(context).primaryColor,
                state: _state,
                overflowMode: widget.overflowMode,
              ),
            ),
            LayoutId(
              id: BackgroundContentLayout.content,
              child: Content(
                state: _state,
                transitionProgress: _transitionProgress,
                title: widget.title,
                description: widget.description,
                textColor: widget.textColor,
                overflowMode: widget.overflowMode,
                backgroundCenter: backgroundCenter,
                backgroundRadius: backgroundRadius,
                width: contentWidth,
              ),
            ),
          ],
        ),
        _Pulse(
          state: _state,
          transitionProgress: _transitionProgress,
          anchor: anchor,
          color: widget.targetColor,
        ),
        _TapTarget(
          state: _state,
          transitionProgress: _transitionProgress,
          anchor: anchor,
          color: widget.targetColor,
          onPressed: () => FeatureDiscovery.completeCurrentStep(context),
          child: widget.tapTarget,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnchoredOverlay(
      showOverlay: _state != FeatureOverlayState.closed,
      overlayBuilder: (BuildContext context, Offset anchor) {
        return _buildOverlay(anchor);
      },
      child: widget.child,
    );
  }
}

class _Background extends StatelessWidget {
  final FeatureOverlayState state;
  final double transitionProgress;
  final Color color;
  final OverflowMode overflowMode;

  const _Background({
    Key key,
    @required this.color,
    @required this.state,
    @required this.transitionProgress,
    @required this.overflowMode,
  })  : assert(color != null),
        assert(state != null),
        assert(transitionProgress != null),
        super(key: key);

  double get opacity {
    switch (state) {
      case FeatureOverlayState.opening:
        final double adjustedPercent =
            const Interval(0.0, 0.3, curve: Curves.easeOut)
                .transform(transitionProgress);
        return 0.96 * adjustedPercent;

      case FeatureOverlayState.activating:
        final double adjustedPercent =
            const Interval(0.1, 0.6, curve: Curves.easeOut)
                .transform(transitionProgress);

        return 0.96 * (1 - adjustedPercent);
      case FeatureOverlayState.dismissing:
        final double adjustedPercent =
            const Interval(0.2, 1.0, curve: Curves.easeOut)
                .transform(transitionProgress);
        return 0.96 * (1 - adjustedPercent);
      case FeatureOverlayState.opened:
        return 0.96;
      case FeatureOverlayState.closed:
        return 0;
    }
    throw ArgumentError.value(state);
  }

  @override
  Widget build(BuildContext context) {
    if (state == FeatureOverlayState.closed) {
      return Container();
    }

    return LayoutBuilder(
        builder: (context, constraints) => Container(
              // The size is controlled in BackgroundContentLayoutDelegate.
              width: constraints.biggest.width,
              height: constraints.biggest.height,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: color.withOpacity(opacity)),
            ));
  }
}

class _Pulse extends StatelessWidget {
  final FeatureOverlayState state;
  final double transitionProgress;
  final Offset anchor;
  final Color color;

  const _Pulse({
    Key key,
    @required this.state,
    @required this.transitionProgress,
    @required this.anchor,
    @required this.color,
  })  : assert(state != null),
        assert(transitionProgress != null),
        assert(anchor != null),
        assert(color != null),
        super(key: key);

  double get radius {
    switch (state) {
      case FeatureOverlayState.opened:
        double expandedPercent;
        if (transitionProgress >= 0.3 && transitionProgress <= 0.8) {
          expandedPercent = (transitionProgress - 0.3) / 0.5;
        } else {
          expandedPercent = 0.0;
        }
        return 44.0 + (35.0 * expandedPercent);
      case FeatureOverlayState.dismissing:
      case FeatureOverlayState.activating:
        return 0; //(44.0 + 35.0) * (1.0 - transitionProgress);
      case FeatureOverlayState.opening:
      case FeatureOverlayState.closed:
        return 0;
    }
    throw ArgumentError.value(state);
  }

  double get opacity {
    switch (state) {
      case FeatureOverlayState.opened:
        final double percentOpaque =
            1 - ((transitionProgress.clamp(0.3, 0.8) - 0.3) / 0.5);
        return (percentOpaque * 0.75).clamp(0, 1);
      case FeatureOverlayState.activating:
      case FeatureOverlayState.dismissing:
        return 0; //((1.0 - transitionProgress) * 0.5).clamp(0.0, 1.0);
      case FeatureOverlayState.opening:
      case FeatureOverlayState.closed:
        return 0;
    }
    throw ArgumentError.value(state);
  }

  @override
  Widget build(BuildContext context) {
    return state == FeatureOverlayState.closed
        ? Container()
        : CenterAbout(
            position: anchor,
            child: Container(
              width: radius * 2,
              height: radius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(opacity),
              ),
            ),
          );
  }
}

class _TapTarget extends StatelessWidget {
  final FeatureOverlayState state;
  final double transitionProgress;
  final Offset anchor;
  final Widget child;
  final Color color;
  final VoidCallback onPressed;

  const _TapTarget({
    Key key,
    @required this.anchor,
    @required this.child,
    @required this.onPressed,
    @required this.color,
    @required this.state,
    @required this.transitionProgress,
  })  : assert(anchor != null),
        assert(child != null),
        assert(state != null),
        assert(transitionProgress != null),
        assert(color != null),
        super(key: key);

  double get opacity {
    switch (state) {
      case FeatureOverlayState.opening:
        return const Interval(0, 0.3, curve: Curves.easeOut)
            .transform(transitionProgress);
      case FeatureOverlayState.activating:
      case FeatureOverlayState.dismissing:
        return 1 -
            const Interval(0.7, 1, curve: Curves.easeOut)
                .transform(transitionProgress);
      case FeatureOverlayState.closed:
        return 0;
      case FeatureOverlayState.opened:
        return 1;
    }
    throw ArgumentError.value(state);
  }

  double get radius {
    switch (state) {
      case FeatureOverlayState.closed:
        return 0;
      case FeatureOverlayState.opening:
        return 20 + 24 * transitionProgress;
      case FeatureOverlayState.opened:
        double expandedPercent;
        if (transitionProgress < 0.3)
          expandedPercent = transitionProgress / 0.3;
        else if (transitionProgress < 0.6)
          expandedPercent = 1 - ((transitionProgress - 0.3) / 0.3);
        else
          expandedPercent = 0;
        return 44 + (20 * expandedPercent);
      case FeatureOverlayState.activating:
      case FeatureOverlayState.dismissing:
        return 20 + 24 * (1 - transitionProgress);
    }
    throw ArgumentError.value(state);
  }

  @override
  Widget build(BuildContext context) {
    return CenterAbout(
      position: anchor,
      child: Container(
        height: 2 * radius,
        width: 2 * radius,
        child: Opacity(
          opacity: opacity,
          child: RawMaterialButton(
            fillColor: color,
            shape: const CircleBorder(),
            child: child,
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}

/// Controls how content that overflows the background should be handled.
///
/// The default for [DescribedFeatureOverlay] is [ignore].
///
/// Modes:
///
///  * [ignore] will render the content as is, even if it exceeds the
///    boundaries of the background circle.
///  * [clipContent] will not render any content that is outside the background's area,
///    i.e. clip the content.
///    Additionally, it will pass any hit events that occur outside of the inner area
///    to the UI below the overlay, so you do not have to worry about that.
///  * [extendBackground] will expand the background circle if necessary.
///    The radius will be increased until the content fits within the circle's area
///    and a padding of 4 will be added.
///  * [wrapBackground] does what [extendBackground] does if the content is larger than the background,
///    but it will shrink the background if it is smaller than the content additionally.
///    This will never be smaller than `min(screenWidth, screenHeight) + 4`
///    because the furthest point of empty content will be `min(screenWidth, screenHeight)` away from the center of the overlay
///    as it is given that dimension as its width for layout reasons.
enum OverflowMode {
  ignore,
  clipContent,
  extendBackground,
  wrapBackground,
}

// The Flutter SDK has a State class called OverlayState.
// Thus, this cannot be called OverlayState.
enum FeatureOverlayState {
  closed,
  opening,
  opened,
  activating,
  dismissing,
}
