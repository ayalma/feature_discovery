import 'dart:math' as Math;

import 'package:feature_discovery/src/layout.dart';
import 'package:flutter/material.dart';

class FeatureDiscovery extends StatefulWidget {
  const FeatureDiscovery({Key key, this.child}) : super(key: key);

  static String activeStep(BuildContext context) {
    return (context.inheritFromWidgetOfExactType(_InheritedFeatureDiscovery)
            as _InheritedFeatureDiscovery)
        .activeStepId;
  }

  /// Steps are the featureIds of the overlays.
  /// Though they can be placed in any [Iterable], it is recommended to pass them as a [Set], as they have to be unique
  static void discoverFeatures(BuildContext context, Iterable<String> steps) {
    assert(steps.toSet().length == steps.length, "Feature ids must be unique"); 
    _FeatureDiscoveryState state =
        context.ancestorStateOfType(TypeMatcher<_FeatureDiscoveryState>())
            as _FeatureDiscoveryState;

    state.discoverFeatures(steps.toList());
  }

  static void markStepComplete(BuildContext context, String stepId) {
    _FeatureDiscoveryState state =
        context.ancestorStateOfType(TypeMatcher<_FeatureDiscoveryState>())
            as _FeatureDiscoveryState;
    state.markStepComplete(stepId);
  }

  static dismiss(BuildContext context) {
    _FeatureDiscoveryState state =
        context.ancestorStateOfType(TypeMatcher<_FeatureDiscoveryState>())
            as _FeatureDiscoveryState;

    state.dismiss();
  }

  final Widget child;

  @override
  _FeatureDiscoveryState createState() => _FeatureDiscoveryState();
}

class _FeatureDiscoveryState extends State<FeatureDiscovery> {
  List<String> steps;
  int activeStepIndex;

  void discoverFeatures(List<String> steps) {
    setState(() {
      this.steps = steps;
      activeStepIndex = 0;
    });
  }

  void markStepComplete(String stepId) {
    if (steps != null && steps[activeStepIndex] == stepId) {
      setState(() {
        ++activeStepIndex;
        if (activeStepIndex >= steps.length) {
          _cleanupAfterSteps();
        }
      });
    }
  }

  void dismiss() => setState(() => _cleanupAfterSteps());

  void _cleanupAfterSteps() {
    steps = null;
    activeStepIndex = null;
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedFeatureDiscovery(
      activeStepId: steps?.elementAt(activeStepIndex),
      child: widget.child,
    );
  }
}

class DescribedFeatureOverlay extends StatefulWidget {
  /// This id must be unique among all the [DescribedFeatureOverlay]s widgets.
  final String featureId;
  final IconData icon;
  @Deprecated("Replaced by backgroundColor")
  final Color color;
  /// If null, default to [ThemeData.primaryColor]
  final Color backgroundColor;
  /// If null, default to current [IconTheme]
  final Color iconColor;
  final Color targetColor;
  final Color textColor;
  final String title;
  final String description;
  /// Called when the target is pressed.
  final Function(VoidCallback onActionCompleted) doAction;
  /// Called just before the FeatureOverlay is displayed.
  /// The function parameter is actually the callback that triggers the display of the overlay.
  /// If not null, the callback MUST be called in order for the overlay to be displayed.
  final Function(VoidCallback onActionCompleted) prepareAction;
  final Widget child;
  final ContentOrientation contentLocation;
  final bool enablePulsingAnimation;
  /// Function to execute when the overlay is dismissed (when the user taps outside of it).
  /// If not null, the callback MUST be called in order for the overlay to be dismissed.
  final Function(VoidCallback onActionCompleted) onDismissAction;

  const DescribedFeatureOverlay({
    Key key,
    @required this.featureId,
    @required this.icon,
    this.color,
    this.backgroundColor,
    this.iconColor,
    this.targetColor = Colors.white,
    this.textColor = Colors.white,
    this.title,
    this.description,
    @required this.child,
    this.doAction,
    this.prepareAction,
    this.contentLocation = ContentOrientation.trivial,
    this.enablePulsingAnimation = true,
    this.onDismissAction
  }) : 
    assert(featureId != null),
    assert(icon != null),
    assert(child != null),
    assert(contentLocation != null),
    assert(enablePulsingAnimation != null),
    assert(targetColor != null),
    assert(textColor != null),
    assert(color == null || backgroundColor == null), // both are the same
    super(key: key);

  @override
  _DescribedFeatureOverlayState createState() => _DescribedFeatureOverlayState();
}

class _DescribedFeatureOverlayState extends State<DescribedFeatureOverlay>
    with TickerProviderStateMixin {
  Size screenSize;
  double statusBarHeight;
  bool showOverlay = false;
  _OverlayState state = _OverlayState.closed;
  double transitionPercent = 1.0;

  AnimationController openController;
  AnimationController activationController;
  AnimationController dismissController;
  AnimationController pulseController;

  @override
  void initState() {
    super.initState();
    initAnimationControllers();
    openController.forward();
  }

  @override
  void dispose() {
    openController.dispose();
    activationController.dispose();
    dismissController.dispose();
    pulseController?.dispose();
    super.dispose();
  }

  void initAnimationControllers() {
    openController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 250))
          ..addListener(() => setState(() => transitionPercent = openController.value))
          ..addStatusListener(
            (AnimationStatus status) {
              if (status == AnimationStatus.forward) setState(() => state = _OverlayState.opening);
              else if (status == AnimationStatus.completed) pulseController?.forward(from: 0.0);
            },
          );

    if (widget.enablePulsingAnimation) {
      pulseController =
          AnimationController(vsync: this, duration: Duration(milliseconds: 1000))
            ..addListener(() => setState(() => transitionPercent = pulseController.value))
            ..addStatusListener(
              (AnimationStatus status) {
                if (status == AnimationStatus.forward)
                  setState(() => state = _OverlayState.pulsing);
                else if (status == AnimationStatus.completed)
                  pulseController.forward(from: 0.0);
              },
            );
    }
    activationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 250)
    )
      ..addListener(() => setState(() => transitionPercent = activationController.value))
      ..addStatusListener(
        (AnimationStatus status) {
          switch (status) {
            case AnimationStatus.forward:
              setState(() => state = _OverlayState.activating);
              break;
            case AnimationStatus.completed:
              void Function() callback = 
                () => FeatureDiscovery.markStepComplete(context, widget.featureId);
              widget.doAction == null ? callback() : widget.doAction(callback);
              break;
            default: break;
          }
        },
      );

    dismissController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 250))
          ..addListener(() => setState(() => transitionPercent = dismissController.value))
          ..addStatusListener(
            (AnimationStatus status) {
              if (status == AnimationStatus.forward)
                setState(() => state = _OverlayState.dismissing);
              else if (status == AnimationStatus.completed) {
                void Function() callback = () => FeatureDiscovery.dismiss(context);
                widget.onDismissAction == null ? callback() : widget.onDismissAction(callback);
              }
            },
          );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    screenSize = MediaQuery.of(context).size;
    statusBarHeight = MediaQuery.of(context).viewInsets.top;
    showOverlayIfActiveStep();
  }

  void showOverlayIfActiveStep() {
    String activeStep = FeatureDiscovery.activeStep(context);

    void Function() callback = () {
      setState(() => showOverlay = activeStep == widget.featureId);
      if (activeStep == widget.featureId) openController.forward(from: 0.0);
    };
    if (widget.prepareAction != null && activeStep == widget.featureId)
      widget.prepareAction(callback);
    else callback();
  }

  void activate() {
    pulseController?.stop();
    activationController.forward(from: 0.0);
  }

  void dismiss() async {
    pulseController?.stop();
    dismissController.forward(from: 0.0);
  }

  Widget _buildOverlay(Offset anchor) {
    return Stack(
      children: <Widget>[
        GestureDetector(
          onTap: dismiss,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.transparent,
          ),
        ),
        _Background(
          state: state,
          transitionPercent: transitionPercent,
          anchor: anchor,
          color: (widget.backgroundColor ?? widget.color) ?? Theme.of(context).primaryColor,
          screenSize: screenSize,
          orientation: widget.contentLocation,
        ),
        _Content(
          state: state,
          transitionPercent: transitionPercent,
          anchor: anchor,
          screenSize: screenSize,
          // this parameter is not used
          // statusBarHeight: statusBarHeight,
          touchTargetRadius: 44.0,
          // this parameter is not used
          // touchTargetToContentPadding: 20.0,
          title: widget.title,
          description: widget.description,
          orientation: widget.contentLocation,
          textColor: widget.textColor,
        ),
        _Pulse(
          state: state,
          transitionPercent: transitionPercent,
          anchor: anchor,
          color: widget.targetColor,
        ),
        _TouchTarget(
          state: state,
          transitionPercent: transitionPercent,
          anchor: anchor,
          icon: widget.icon,
          iconColor: widget.iconColor,
          backgroundColor: widget.targetColor,
          onPressed: activate,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnchoredOverlay(
      showOverlay: showOverlay,
      overlayBuilder: (BuildContext context, Offset anchor) {
        return _buildOverlay(anchor);
      },
      child: widget.child,
    );
  }
}

class _Background extends StatelessWidget {
  final _OverlayState state;
  final double transitionPercent;
  final Offset anchor;
  final Color color;
  final Size screenSize;
  final ContentOrientation orientation;

  const _Background({
    Key key,
    @required this.anchor,
    @required this.color,
    @required this.screenSize,
    @required this.state,
    @required this.transitionPercent,
    @required this.orientation,
  }) : 
    assert(anchor != null),
    assert(color != null),
    assert(screenSize != null),
    assert(state != null),
    assert(transitionPercent != null),
    assert(orientation != null),
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

  double radius() {
    final isBackgroundCentered = isCloseToTopOrBottom(anchor);
    final backgroundRadius = Math.min(screenSize.width, screenSize.height) *
        (isBackgroundCentered ? 1.0 : 0.7);
    switch (state) {
      case _OverlayState.opening:
        final adjustedPercent = const Interval(0.0, 0.8, curve: Curves.easeOut)
            .transform(transitionPercent);
        return backgroundRadius * adjustedPercent;
      case _OverlayState.activating:
        return backgroundRadius + transitionPercent * 40.0;
      case _OverlayState.dismissing:
        return backgroundRadius * (1 - transitionPercent);
      default:
        return backgroundRadius;
    }
  }

  Offset backgroundPosition() {
    final width = Math.min(screenSize.width, screenSize.height);
    final isBackgroundCentered = isCloseToTopOrBottom(anchor);

    if (isBackgroundCentered) {
      return anchor;
    } else {
      final startingBackgroundPosition = anchor;

      var endingBackgroundPosition;
      switch (orientation) {
        case ContentOrientation.trivial:
          endingBackgroundPosition = Offset(
              width / 2.0 + (isOnLeftHalfOfScreen(anchor) ? -20.0 : 20.0),
              anchor.dy +
                  (isOnTopHalfOfScreen(anchor)
                      ? -(width / 2.0) + 40.0
                      : (width / 2.0) - 40.0));
          break;
        case ContentOrientation.above:
          endingBackgroundPosition = Offset(
              width / 2.0 + (isOnLeftHalfOfScreen(anchor) ? -20.0 : 20.0),
              anchor.dy - (width / 2.0) + 40.0);
          break;
        case ContentOrientation.below:
          endingBackgroundPosition = Offset(
              width / 2.0 + (isOnLeftHalfOfScreen(anchor) ? -20.0 : 20.0),
              anchor.dy + (width / 2.0) - 40.0);
          break;
      }

      switch (state) {
        case _OverlayState.opening:
          final adjustedPercent =
              const Interval(0.0, 0.8, curve: Curves.easeOut)
                  .transform(transitionPercent);
          return Offset.lerp(startingBackgroundPosition,
              endingBackgroundPosition, adjustedPercent);
        case _OverlayState.activating:
          return endingBackgroundPosition;
        case _OverlayState.dismissing:
          return Offset.lerp(endingBackgroundPosition,
              startingBackgroundPosition, transitionPercent);
        default:
          return endingBackgroundPosition;
      }
    }
  }

  double backgroundOpacity() {
    switch (state) {
      case _OverlayState.opening:
        final adjustedPercent = const Interval(0.0, 0.3, curve: Curves.easeOut)
            .transform(transitionPercent);
        return 0.96 * adjustedPercent;

      case _OverlayState.activating:
        final adjustedPercent = const Interval(0.1, 0.6, curve: Curves.easeOut)
            .transform(transitionPercent);

        return 0.96 * (1 - adjustedPercent);
      case _OverlayState.dismissing:
        final adjustedPercent = const Interval(0.2, 1.0, curve: Curves.easeOut)
            .transform(transitionPercent);
        return 0.96 * (1 - adjustedPercent);
      default:
        return 0.96;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (state == _OverlayState.closed) {
      return Container();
    }

    return CenterAbout(
      position: backgroundPosition(),
      child: Container(
        width: 2 * radius(),
        height: 2 * radius(),
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(backgroundOpacity())),
      ),
    );
  }
}

class _Pulse extends StatelessWidget {
  final _OverlayState state;
  final double transitionPercent;
  final Offset anchor;
  final Color color;

  const _Pulse({
    Key key,
    @required this.state,
    @required this.transitionPercent,
    @required this.anchor,
    @required this.color
  }) : 
    assert(state != null),
    assert(transitionPercent != null),
    assert(anchor != null),
    assert(color != null),
    super(key: key);

  double radius() {
    switch (state) {
      case _OverlayState.pulsing:
        double expandedPercent;
        if (transitionPercent >= 0.3 && transitionPercent <= 0.8) {
          expandedPercent = (transitionPercent - 0.3) / 0.5;
        } else {
          expandedPercent = 0.0;
        }
        return 44.0 + (35.0 * expandedPercent);
      case _OverlayState.dismissing:
      case _OverlayState.activating:
        return 0.0; //(44.0 + 35.0) * (1.0 - transitionPercent);
      default:
        return 0.0;
    }
  }

  double opacity() {
    switch (state) {
      case _OverlayState.pulsing:
        final percentOpaque =
            1.0 - ((transitionPercent.clamp(0.3, 0.8) - 0.3) / 0.5);
        return (percentOpaque * 0.75).clamp(0.0, 1.0);
      case _OverlayState.activating:
      case _OverlayState.dismissing:
        return 0.0; //((1.0 - transitionPercent) * 0.5).clamp(0.0, 1.0);
      default:
        return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return state == _OverlayState.closed
      ? Container(height: 0, width: 0)
      : CenterAbout(
        position: anchor,
        child: Container(
          width: radius() * 2,
          height: radius() * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(opacity()),
          ),
        ),
      );
  }
}

class _TouchTarget extends StatelessWidget {
  final _OverlayState state;
  final double transitionPercent;
  final Offset anchor;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback onPressed;

  const _TouchTarget({
    Key key,
    @required this.anchor,
    @required this.icon,
    // The two parameters below can technically be null, so assertions are not made for them,
    // but they are annotated as required to not forget them during development
    // (as this is an internal widget and those parameters should always be specified, even when null)
    @required this.iconColor,
    @required this.onPressed,
    @required this.backgroundColor,
    @required this.state,
    @required this.transitionPercent,
  }) : 
    assert(anchor != null),
    assert(icon != null),
    assert(state != null),
    assert(transitionPercent != null),
    assert(backgroundColor != null),
    super(key: key);

  double opacity() {
    switch (state) {
      case _OverlayState.opening:
        return const Interval(0.0, 0.3, curve: Curves.easeOut)
            .transform(transitionPercent);
      case _OverlayState.activating:
      case _OverlayState.dismissing:
        return 1.0 -
            const Interval(0.7, 1.0, curve: Curves.easeOut)
                .transform(transitionPercent);
      default:
        return 1.0;
    }
  }

  double radius() {
    switch (state) {
      case _OverlayState.closed:
        return 0.0;
      case _OverlayState.opening:
        return 20.0 + 24.0 * transitionPercent;
      case _OverlayState.pulsing:
        double expandedPercent;
        if (transitionPercent < 0.3)
          expandedPercent = transitionPercent / 0.3;
        else if (transitionPercent < 0.6)
          expandedPercent = 1.0 - ((transitionPercent - 0.3) / 0.3);
        else expandedPercent = 0.0;
        return 44.0 + (20.0 * expandedPercent);
      case _OverlayState.activating:
      case _OverlayState.dismissing:
        return 20.0 + 24.0 * (1 - transitionPercent);
      default:
        return 44.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CenterAbout(
      position: anchor,
      child: Container(
        height: 2 * radius(),
        width: 2 * radius(),
        child: Opacity(
          opacity: opacity(),
          child: RawMaterialButton(
            fillColor: backgroundColor,
            shape: const CircleBorder(),
            child: Icon(
              icon,
              color: iconColor,
            ),
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  final _OverlayState state;
  final double transitionPercent;
  final Offset anchor;
  final Size screenSize;
  final double touchTargetRadius;
  // this parameter is not used
  // final double touchTargetToContentPadding;
  /// Can be null
  final String title;
  /// Can be null
  final String description;
  // not used
  // final double statusBarHeight;
  final ContentOrientation orientation;
  final Color textColor;

  const _Content(
      {Key key,
      @required this.anchor,
      @required this.screenSize,
      @required this.touchTargetRadius,
      //this.touchTargetToContentPadding,
      @required this.title,
      @required this.description,
      @required this.state,
      @required this.transitionPercent,
      //this.statusBarHeight,
      @required this.orientation,
      @required this.textColor,
    }) : 
      assert(anchor != null),
      assert(screenSize != null),
      assert(touchTargetRadius != null),
      assert(state != null),
      assert(transitionPercent != null),
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

  DescribedFeatureContentOrientation getContentOrientation(Offset position) {
    if (isCloseToTopOrBottom(position)) return 
      isOnTopHalfOfScreen(position)
        ? DescribedFeatureContentOrientation.below
        : DescribedFeatureContentOrientation.above;
    else return 
      isOnTopHalfOfScreen(position)
        ? DescribedFeatureContentOrientation.above
        : DescribedFeatureContentOrientation.below;
  }

  double opacity() {
    switch (state) {
      case _OverlayState.closed:
        return 0.0;
      case _OverlayState.opening:
        final adjustedPercent = const Interval(0.6, 1.0, curve: Curves.easeOut)
            .transform(transitionPercent);
        return adjustedPercent;
      case _OverlayState.activating:
      case _OverlayState.dismissing:
        final adjustedPercent = const Interval(0.0, 0.4, curve: Curves.easeOut)
            .transform(transitionPercent);
        return 1.0 - adjustedPercent;
      default:
        return 1.0;
    }
  }

  Offset centerPosition() {
    final width = Math.min(screenSize.width, screenSize.height);
    final isBackgroundCentered = isCloseToTopOrBottom(anchor);

    if (isBackgroundCentered) return anchor;
    else {
      final startingBackgroundPosition = anchor;
      final endingBackgroundPosition = Offset(
          width / 2.0 + (isOnLeftHalfOfScreen(anchor) ? -20.0 : 20.0),
          anchor.dy +
              (isOnTopHalfOfScreen(anchor)
                  ? -(width / 2) + 40.0
                  : (width / 20.0) - 40.0));

      switch (state) {
        case _OverlayState.opening:
          final adjustedPercent =
              const Interval(0.0, 0.8, curve: Curves.easeOut)
                  .transform(transitionPercent);
          return Offset.lerp(startingBackgroundPosition,
              endingBackgroundPosition, adjustedPercent);
        case _OverlayState.activating:
          return endingBackgroundPosition;
        case _OverlayState.dismissing:
          return Offset.lerp(endingBackgroundPosition,
              startingBackgroundPosition, transitionPercent);
        default:
          return endingBackgroundPosition;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final contentOrientation = getContentOrientation(anchor);
    var contentOffsetMultiplier;

    switch (orientation) {
      case ContentOrientation.trivial:
        contentOffsetMultiplier =
            contentOrientation == DescribedFeatureContentOrientation.below
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

    final width = Math.min(screenSize.width, screenSize.height);

    final contentY =
        anchor.dy + contentOffsetMultiplier * (touchTargetRadius + 20);

    final contentFractionalOffset = contentOffsetMultiplier.clamp(-1.0, 0.0);

    final dx = centerPosition().dx - width;
    final contentX = (dx.isNegative) ? 0.0 : dx;
    return Positioned(
      top: contentY,
      left: contentX,
      child: FractionalTranslation(
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
                    title == null
                      ? const SizedBox(height: 0)
                      : Text(
                        title,
                        style: Theme.of(context).textTheme.title
                          .copyWith(color: textColor)
                      ),
                    const SizedBox(height: 8.0),
                    description == null
                      ? const SizedBox(height: 0)
                      : Text(
                        description,
                        style: Theme.of(context).textTheme.body1
                          .copyWith(color: textColor.withOpacity(0.9)),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InheritedFeatureDiscovery extends InheritedWidget {
  final String activeStepId;

  const _InheritedFeatureDiscovery({
    Key key,
    @required Widget child,
    this.activeStepId,
  })  : assert(child != null),
        super(key: key, child: child);

  static _InheritedFeatureDiscovery of(BuildContext context)
    => context.inheritFromWidgetOfExactType(_InheritedFeatureDiscovery)
      as _InheritedFeatureDiscovery;

  @override
  bool updateShouldNotify(_InheritedFeatureDiscovery old)
    => old.activeStepId != activeStepId;
}

enum DescribedFeatureContentOrientation {
  above,
  below,
}

enum _OverlayState {
  closed,
  opening,
  pulsing,
  activating,
  dismissing,
}

enum ContentOrientation {
  above,
  below,
  trivial,
}
