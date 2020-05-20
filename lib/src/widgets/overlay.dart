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

  /// The opacity of the large circle, where the text sits on.
  /// If null, defaults to 0.96.
  final double backgroundOpacity;

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
  // TODO(creativecreatorormaybenot): Update TextTheme.title link to headline6 when Flutter stable deprecates body1.
  final Widget title;

  /// This is the second content widget, i.e. it is displayed below [description].
  ///
  /// It is intended for this to contain a [Text] widget, however, you can pass
  /// any [Widget].
  /// The overlay uses a [DefaultTextStyle] for the description, which is a combination
  /// of [TextTheme.body1] from [Theme] and the [textColor].
  // TODO(creativecreatorormaybenot): Update TextTheme.body1 link to bodyText2 when Flutter stable deprecates body1.
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
  /// Whenever the [Future] this function returns finishes with `true`, the feature discovery
  /// will continue and the next step will try to open after a closing animation.
  /// If it completes with `false`, nothing happens.
  final Future<bool> Function() onComplete;

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

  /// Duration for overlay open animation.
  final Duration openDuration;

  /// Duration for target pulse animation.
  final Duration pulseDuration;

  /// Duration for overlay complete animation.
  final Duration completeDuration;

  /// Duration for overlay dismiss animation.
  final Duration dismissDuration;
  
  /// Controls whether the overlay should be dismissed on touching outside or not.
  ///
  /// The default value for [barrierDismissible] is `true`.
  final bool barrierDismissible;

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
    this.onOpen,
    this.onComplete,
    this.onDismiss,
    this.contentLocation = ContentLocation.trivial,
    this.enablePulsingAnimation = true,
    this.allowShowingDuplicate = false,
    this.overflowMode = OverflowMode.ignore,
    this.backgroundOpacity,
    this.openDuration = const Duration(milliseconds: 250),
    this.pulseDuration = const Duration(milliseconds: 1000),
    this.completeDuration = const Duration(milliseconds: 250),
    this.dismissDuration = const Duration(milliseconds: 250),
    this.barrierDismissible = true,
  })  : assert(featureId != null),
        assert(tapTarget != null),
        assert(child != null),
        assert(contentLocation != null),
        assert(enablePulsingAnimation != null),
        assert(targetColor != null),
        assert(textColor != null),
        assert(overflowMode != null),
        assert(openDuration != null),
        assert(pulseDuration != null),
        assert(completeDuration != null),
        assert(dismissDuration != null),
        assert(barrierDismissible != null),
        assert(
          barrierDismissible == true || onDismiss == null,
          'Cannot provide both a barrierDismissible and onDismiss function\n'
          'The onDismiss function will never get executed when barrierDismissible is set to false.',
        ),
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

  /// The usual order is open, complete, then dismiss across the project,
  /// but pulse does not exist for most other occurrences.
  AnimationController _pulseController;
  AnimationController _completeController;
  AnimationController _dismissController;

  /// The local reference to the [Bloc] is needed because it is used in [dispose].
  Bloc _bloc;

  Stream<EventType> _eventsStream;
  StreamSubscription<EventType> _eventsSubscription;

  /// If either [_complete] or [_dismiss] were called previously,
  /// the overlay is awaiting the closure of itself. This is necessary
  /// because [DescribedFeatureOverlay.onComplete] and [DescribedFeatureOverlay.onDismiss]
  /// are `async` and while those are evaluated, the methods should not execute again.
  bool _awaitingClosure;

  @override
  void initState() {
    _state = FeatureOverlayState.closed;

    _awaitingClosure = false;

    _transitionProgress = 1;

    _initAnimationControllers();

    super.initState();
  }

  @override
  void didUpdateWidget(DescribedFeatureOverlay oldWidget) {
    if (oldWidget.enablePulsingAnimation != widget.enablePulsingAnimation) {
      if (widget.enablePulsingAnimation) {
        _pulseController.forward(from: 0);
      } else {
        _pulseController.stop();
        setState(() => _transitionProgress = 0);
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void didChangeDependencies() {
    _screenSize = MediaQuery.of(context).size;

    try {
      _bloc = Bloc.of(context);

      final newEventsStream = _bloc.eventsOut;
      if (_eventsStream != newEventsStream) _setStream(newEventsStream);

      // If this widget was not in the tree when the feature discovery was started,
      // we need to open it immediately because the streams will not receive
      // any further events that could open the overlay.
      if (_bloc.activeFeatureId == widget.featureId &&
          _state == FeatureOverlayState.closed) _open();
    } on BlocNotFoundError catch (e) {
      throw FlutterError(e.message +
          '\nEnsure that all the DescribedFeatureOverlay widgets are below it.');
    }

    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _openController.dispose();
    _pulseController.dispose();
    _completeController.dispose();
    _dismissController.dispose();

    _eventsSubscription.cancel();

    // If this widget is disposed while still showing an overlay,
    // it needs to remove itself from the active overlays.
    //
    // This is not done when closing the overlay because the Bloc
    // resets the activeOverlays and this would interfere with that.
    //
    // Dismissing and completing are not considered "showing" in this case
    // because the Bloc will already have dealt with the activeOverlays as
    // it triggered the completion or dismissal animation.
    if (_state != FeatureOverlayState.closed &&
        _state != FeatureOverlayState.dismissing &&
        _state != FeatureOverlayState.completing) {
      // If the _state is anything else, this overlay has to be showing,
      // otherwise something is wrong.
      assert(_bloc.activeFeatureId == widget.featureId);

      _bloc.activeOverlays--;
    }
    super.dispose();
  }

  void _setStream(Stream<EventType> newStream) {
    _eventsSubscription?.cancel();
    _eventsStream = newStream;
    _eventsSubscription = _eventsStream.listen((EventType event) async {
      assert(event != null);

      switch (event) {
        case EventType.open:
          // Only try opening when the active feature id matches the id of this widget.
          if (_bloc.activeFeatureId != widget.featureId) return;
          await _open();
          break;
        case EventType.complete:
        case EventType.dismiss:
          // This overlay was the active feature before this event if it is either opening or already opened.
          if (_state != FeatureOverlayState.opened &&
              _state != FeatureOverlayState.opening) return;

          if (event == EventType.complete) {
            await _complete();
          } else {
            await _dismiss(force: true);
          }
          break;
        default:
          throw ArgumentError.value(event);
      }
    });
  }

  void _initAnimationControllers() {
    _openController = AnimationController(vsync: this, duration: widget.openDuration)
      ..addListener(() => setState(() => _transitionProgress = _openController.value));

    _pulseController = AnimationController(vsync: this, duration: widget.pulseDuration)
      ..addListener(() => setState(() => _transitionProgress = _pulseController.value))
      ..addStatusListener(
        (AnimationStatus status) {
          if (status == AnimationStatus.completed) {
            _pulseController.forward(from: 0);
          }
        },
      );

    _completeController = AnimationController(
        vsync: this, duration: widget.completeDuration)
      ..addListener(() =>
          setState(() => _transitionProgress = _completeController.value));

    _dismissController = AnimationController(
        vsync: this, duration: widget.dismissDuration)
      ..addListener(
          () => setState(() => _transitionProgress = _dismissController.value));
  }

  Future<void> _open() async {
    if (!widget.allowShowingDuplicate && _bloc.activeOverlays > 0) return;

    _bloc.activeOverlays++;

    if (widget.onOpen != null) {
      final shouldOpen = await widget.onOpen();
      assert(shouldOpen != null,
          'You need to return a [Future] that completes with true or false in [onOpen].');
      if (!shouldOpen) {
        await FeatureDiscovery.completeCurrentStep(context);
        return;
      }
    }

    // The activeStep might have changed by now because onOpen is asynchronous.
    // For example, the step might have been completed programmatically.
    if (_bloc.activeFeatureId != widget.featureId) return;

    // setState will be called in the animation listener.
    _state = FeatureOverlayState.opening;
    await _openController.forward(from: 0);
    // This will be called after the animation is done because the TickerFuture
    // from forward is completed when the animation is complete.
    setState(() => _state = FeatureOverlayState.opened);

    if (widget.enablePulsingAnimation == true) {
      _pulseController.forward(from: 0);
    }
  }

  Future<void> _complete() async {
    // The method might be triggered multiple times.
    if (_awaitingClosure) return;

    _awaitingClosure = true;

    if (widget.onComplete != null) {
      bool shouldComplete;
      try {
        shouldComplete = await widget.onComplete();
      } finally {
        _awaitingClosure = false;
      }

      assert(shouldComplete != null,
          'You need to return a [Future] that completes with true or false in [onComplete].');
      if (!shouldComplete) return;
    }
    _openController.stop();
    _pulseController.stop();

    // setState will be called in the animation listener.
    _state = FeatureOverlayState.completing;
    await _completeController.forward(from: 0);
    // This will be called after the animation is done because the TickerFuture
    // from forward is completed when the animation is complete.
    _close();
  }

  Future<void> _dismiss({bool force = false}) async {
    // The method might be triggered multiple times, especially when swiping.
    if (_awaitingClosure) return;

    _awaitingClosure = true;

    if (!force && widget.onDismiss != null) {
      bool shouldDismiss;
      try {
        shouldDismiss = await widget.onDismiss();
      } finally {
        _awaitingClosure = false;
      }

      assert(shouldDismiss != null,
          'You need to return a [Future] that completes with true or false in [onDismiss].');
      if (!shouldDismiss) return;
    }
    _openController.stop();
    _pulseController.stop();

    // The point of this is to work with the transition progress
    // from the opening animation if the opening animation was still
    // playing when dismiss was called.
    // Otherwise, the overlay would jump from opening to opened and
    // run the dismissal animation from there.
    //
    // We do not do this in _complete because the completion animation
    // does not animate backwards, i.e. the circle just grows when completing.
    // On the flip side, the dismiss animation can be seen as a reversed open animation.
    // This is not perfect because e.g. the curves are different, but it looks
    // at least a bit better and will almost never happen anyway.
    final previousState = _state;

    // setState will be called in the animation listener.
    _state = FeatureOverlayState.dismissing;
    await _dismissController.forward(
        from: previousState == FeatureOverlayState.opening
            ? 1 - _transitionProgress
            : 0);
    // This will be called after the animation is done because the TickerFuture
    // from forward is completed when the animation is complete.
    _close();
  }

  /// This method is used by both [_dismiss] and [_complete]
  /// to properly close the overlay after the animations are finished.
  void _close() {
    assert(_state == FeatureOverlayState.completing ||
        _state == FeatureOverlayState.dismissing);

    _awaitingClosure = false;
    setState(() {
      _state = FeatureOverlayState.closed;
    });
  }

  bool _isCloseToTopOrBottom(Offset position) =>
      position.dy <= 88.0 || (_screenSize.height - position.dy) <= 88.0;

  bool _isOnTopHalfOfScreen(Offset position) =>
      position.dy < (_screenSize.height / 2.0);

  bool _isOnLeftHalfOfScreen(Offset position) =>
      position.dx < (_screenSize.width / 2.0);

  /// The value returned from here will be adjusted in [BackgroundContentLayoutDelegate]
  /// in order to match the transition progress and overlay state.
  double _backgroundRadius(Offset anchor) {
    final isBackgroundCentered = _isCloseToTopOrBottom(anchor);
    final backgroundRadius = min(_screenSize.width, _screenSize.height) *
        (isBackgroundCentered ? 1.0 : 0.7);
    return backgroundRadius;
  }

  Offset _backgroundPosition(Offset anchor, ContentLocation contentLocation) {
    final width = min(_screenSize.width, _screenSize.height);
    final isBackgroundCentered = _isCloseToTopOrBottom(anchor);

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
          final adjustedPercent =
              const Interval(0.0, 0.8, curve: Curves.easeOut)
                  .transform(_transitionProgress);
          return Offset.lerp(startingBackgroundPosition,
              endingBackgroundPosition, adjustedPercent);
        case FeatureOverlayState.completing:
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
    if (widget.contentLocation != ContentLocation.trivial) {
      return widget.contentLocation;
    }

    // Calculates appropriate content location for ContentLocation.trivial.
    if (_isCloseToTopOrBottom(anchor)) {
      return _isOnTopHalfOfScreen(anchor)
          ? ContentLocation.below
          : ContentLocation.above;
    } else {
      return _isOnTopHalfOfScreen(anchor)
          ? ContentLocation.above
          : ContentLocation.below;
    }
  }

  Offset _contentCenterPosition(Offset anchor) {
    final width = min(_screenSize.width, _screenSize.height);
    final isBackgroundCentered = _isCloseToTopOrBottom(anchor);

    if (isBackgroundCentered) {
      return anchor;
    } else {
      final startingBackgroundPosition = anchor;
      final endingBackgroundPosition = Offset(
          width / 2.0 + (_isOnLeftHalfOfScreen(anchor) ? -20.0 : 20.0),
          anchor.dy +
              (_isOnTopHalfOfScreen(anchor)
                  ? -(width / 2) + 40.0
                  : (width / 20.0) - 40.0));

      switch (_state) {
        case FeatureOverlayState.opening:
          final adjustedPercent =
              const Interval(0.0, 0.8, curve: Curves.easeOut)
                  .transform(_transitionProgress);
          return Offset.lerp(startingBackgroundPosition,
              endingBackgroundPosition, adjustedPercent);
        case FeatureOverlayState.completing:
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
    final contentLocation = _nonTrivialContentOrientation(anchor);
    assert(contentLocation != ContentLocation.trivial);

    final backgroundCenter = _backgroundPosition(anchor, contentLocation);
    final backgroundRadius = _backgroundRadius(anchor);

    final contentOffsetMultiplier = _contentOffsetMultiplier(contentLocation);
    final contentCenterPosition = _contentCenterPosition(anchor);

    final contentWidth = min(_screenSize.width, _screenSize.height);

    final dx = contentCenterPosition.dx - contentWidth;
    final contentPosition = Offset(
      (dx.isNegative) ? 0.0 : dx,
      anchor.dy +
          contentOffsetMultiplier * (44 + 20), // 44 is the tap target's radius.
    );

    // Will try to dismiss this overlay,
    // then will call the bloc's dismiss function
    // only if this overlay has been successfully dismissed.
    void tryDismissThisThenAll() async {
      await _dismiss();
      if (_state == FeatureOverlayState.closed) {
        _bloc.dismiss();
      }
    }

    Widget background = Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.transparent,
    );

    if (widget.barrierDismissible) {
      background = GestureDetector(
        onTap: tryDismissThisThenAll,
        // According to the spec, the user should be able to dismiss by swiping.
        onPanUpdate: (DragUpdateDetails _) => tryDismissThisThenAll(),
        child: background,
      );
    }

    return Stack(
      children: <Widget>[
        background,
        CustomMultiChildLayout(
          delegate: BackgroundContentLayoutDelegate(
            overflowMode: widget.overflowMode,
            contentPosition: contentPosition,
            backgroundCenter: backgroundCenter,
            backgroundRadius: backgroundRadius,
            anchor: anchor,
            contentOffsetMultiplier: contentOffsetMultiplier,
            state: _state,
            transitionProgress: _transitionProgress,
          ),
          children: <Widget>[
            LayoutId(
              id: BackgroundContentLayout.background,
              child: _Background(
                transitionProgress: _transitionProgress,
                color: widget.backgroundColor ?? Theme.of(context).primaryColor,
                defaultOpacity: widget.backgroundOpacity ?? 0.96,
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
  Widget build(BuildContext context) => AnchoredOverlay(
        showOverlay: _state != FeatureOverlayState.closed,
        overlayBuilder: (BuildContext context, Offset anchor) =>
            _buildOverlay(anchor),
        child: widget.child,
      );
}

class _Background extends StatelessWidget {
  final FeatureOverlayState state;
  final double transitionProgress;
  final Color color;
  final OverflowMode overflowMode;
  final double defaultOpacity;

  const _Background(
      {Key key,
      @required this.color,
      @required this.state,
      @required this.transitionProgress,
      @required this.overflowMode,
      @required this.defaultOpacity})
      : assert(color != null),
        assert(state != null),
        assert(transitionProgress != null),
        super(key: key);

  double get opacity {
    switch (state) {
      case FeatureOverlayState.opening:
        final adjustedPercent = const Interval(0.0, 0.3, curve: Curves.easeOut).transform(transitionProgress);
        return defaultOpacity * adjustedPercent;

      case FeatureOverlayState.completing:
        final adjustedPercent = const Interval(0.1, 0.6, curve: Curves.easeOut).transform(transitionProgress);

        return defaultOpacity * (1 - adjustedPercent);
      case FeatureOverlayState.dismissing:
        final adjustedPercent = const Interval(0.2, 1.0, curve: Curves.easeOut).transform(transitionProgress);
        return defaultOpacity * (1 - adjustedPercent);
      case FeatureOverlayState.opened:
        return defaultOpacity;
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
      case FeatureOverlayState.completing:
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
        final percentOpaque =
            1 - ((transitionProgress.clamp(0.3, 0.8) - 0.3) / 0.5);
        return (percentOpaque * 0.75).clamp(0, 1);
      case FeatureOverlayState.completing:
      case FeatureOverlayState.dismissing:
        return 0; //((1.0 - transitionProgress) * 0.5).clamp(0.0, 1.0);
      case FeatureOverlayState.opening:
      case FeatureOverlayState.closed:
        return 0;
    }
    throw ArgumentError.value(state);
  }

  @override
  Widget build(BuildContext context) => state == FeatureOverlayState.closed
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
      case FeatureOverlayState.completing:
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
        if (transitionProgress < 0.3) {
          expandedPercent = transitionProgress / 0.3;
        } else if (transitionProgress < 0.6) {
          expandedPercent = 1 - ((transitionProgress - 0.3) / 0.3);
        } else {
          expandedPercent = 0;
        }
        return 44 + (20 * expandedPercent);
      case FeatureOverlayState.completing:
      case FeatureOverlayState.dismissing:
        return 20 + 24 * (1 - transitionProgress);
    }
    throw ArgumentError.value(state);
  }

  @override
  Widget build(BuildContext context) => CenterAbout(
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

/// The Flutter SDK has a State class called OverlayState.
/// Thus, this cannot be called OverlayState.
enum FeatureOverlayState {
  closed,
  opening,
  opened,
  completing,
  dismissing,
}
