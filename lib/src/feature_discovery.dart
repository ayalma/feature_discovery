import 'package:feature_discovery/src/layout.dart';
import 'package:flutter/material.dart';

class FeatureDiscovery extends StatefulWidget {
  const FeatureDiscovery({Key key, this.child}) : super(key: key);

  static String activeStep(BuildContext context) {
    return (context.inheritFromWidgetOfExactType(_InheritedFeatureDiscovery)
            as _InheritedFeatureDiscovery)
        .activeStepId;
  }

  static void discoverFeatures(BuildContext context, List<String> steps) {
    _FeatureDiscoveryState state =
        context.ancestorStateOfType(TypeMatcher<_FeatureDiscoveryState>())
            as _FeatureDiscoveryState;

    state.discoverFeatures(steps);
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

  void dismiss() {
    setState(() {
      _cleanupAfterSteps();
    });
  }

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
  final String featureId;
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final Widget child;

  const DescribedFeatureOverlay(
      {Key key,
      this.featureId,
      this.icon,
      this.color,
      this.title,
      this.description,
      this.child})
      : super(key: key);

  @override
  _DescribedFeatureOverlayState createState() =>
      _DescribedFeatureOverlayState();
}

class _DescribedFeatureOverlayState extends State<DescribedFeatureOverlay> {
  Size screenSize;
  bool showOverlay = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    screenSize = MediaQuery.of(context).size;
    showOverlayIfActiveStep();
  }

  void showOverlayIfActiveStep() {
    String activeStep = FeatureDiscovery.activeStep(context);
    setState(() {
      showOverlay = activeStep == widget.featureId;
    });
  }

  void activate() {
    FeatureDiscovery.markStepComplete(context, widget.featureId);
  }

  void dismiss() {
    FeatureDiscovery.dismiss(context);
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
          state: _OverlayState.opening,
          transitionPercent: 1.0,
          anchor: anchor,
          color: widget.color,
          screenSize: screenSize,
        ),
        _Content(
          state: _OverlayState.opening,
          transitionPercent: 1.0,
          anchor: anchor,
          screenSize: screenSize,
          touchTargetRadius: 44.0,
          touchTargetToContentPadding: 20.0,
        ),
        _TouchTarget(
          state: _OverlayState.opening,
          transitionPercent: 1.0,
          anchor: anchor,
          icon: widget.icon,
          color: widget.color,
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

  const _Background({
    this.anchor,
    this.color,
    this.screenSize,
    this.state,
    this.transitionPercent,
  });

  bool isCloseToTopOrBottom(Offset position) {
    return position.dy <= 88.0 || (screenSize.height - position.dy) <= 88.0;
  }

  bool isOnTopHalfOfScreen(Offset position) {
    return position.dy < (screenSize.height / 2.0);
  }

  bool isOnLeftHalfOfScreen(Offset position) {
    return position.dx < (screenSize.width / 2.0);
  }

  @override
  Widget build(BuildContext context) {
    final isBackgroundCentered = isCloseToTopOrBottom(anchor);
    final backgroundRadius =
        screenSize.width * (isBackgroundCentered ? 1.0 : 0.75);

    final backgroundPosition = isBackgroundCentered
        ? anchor
        : new Offset(
            screenSize.width / 2.0 +
                (isOnLeftHalfOfScreen(anchor) ? -20.0 : 20.0),
            anchor.dy +
                (isOnTopHalfOfScreen(anchor)
                    ? -(screenSize.width / 2) + 40.0
                    : (screenSize.width / 20.0) - 40.0));

    return CenterAbout(
      position: backgroundPosition,
      child: Container(
        width: 2 * backgroundRadius,
        height: 2 * backgroundRadius,
        decoration: BoxDecoration(
            shape: BoxShape.circle, color: color.withOpacity(0.96)),
      ),
    );
  }
}

class _TouchTarget extends StatelessWidget {
  final _OverlayState state;
  final double transitionPercent;
  final Offset anchor;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _TouchTarget({
    this.anchor,
    this.icon,
    this.color,
    this.onPressed,
    this.state,
    this.transitionPercent,
  });

  @override
  Widget build(BuildContext context) {
    final touchTargetRadius = 44.0;
    return CenterAbout(
      position: anchor,
      child: Container(
        height: 2 * touchTargetRadius,
        width: 2 * touchTargetRadius,
        child: RawMaterialButton(
          fillColor: Colors.white,
          shape: CircleBorder(),
          child: Icon(
            icon,
            color: color,
          ),
          onPressed: onPressed,
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
  final double touchTargetToContentPadding;
  final String title;
  final String description;

  const _Content(
      {Key key,
      this.anchor,
      this.screenSize,
      this.touchTargetRadius,
      this.touchTargetToContentPadding,
      this.title,
      this.description,
      this.state,
      this.transitionPercent})
      : super(key: key);

  bool isCloseToTopOrBottom(Offset position) {
    return position.dy <= 88.0 || (screenSize.height - position.dy) <= 88.0;
  }

  bool isOnTopHalfOfScreen(Offset position) {
    return position.dy < (screenSize.height / 2.0);
  }

  DescribedFeatureContentOrientation getContentOrientation(Offset position) {
    if (isCloseToTopOrBottom(position)) {
      if (isOnTopHalfOfScreen(position)) {
        return DescribedFeatureContentOrientation.below;
      } else {
        return DescribedFeatureContentOrientation.above;
      }
    } else {
      if (isOnTopHalfOfScreen(position)) {
        return DescribedFeatureContentOrientation.above;
      } else {
        return DescribedFeatureContentOrientation.below;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final contentOrientation = getContentOrientation(anchor);
    final contentOffsetMultiplier =
        contentOrientation == DescribedFeatureContentOrientation.below
            ? 1.0
            : -1.0;
    final contentY =
        anchor.dy + contentOffsetMultiplier * (touchTargetRadius + 20);
    final contentFractionalOffset = contentOffsetMultiplier.clamp(-1.0, 0.0);

    return Positioned(
      top: contentY,
      child: FractionalTranslation(
        translation: Offset(0.0, contentFractionalOffset),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.only(left: 40.0, right: 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 20.0,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 18.0,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
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

  static _InheritedFeatureDiscovery of(BuildContext context) {
    return context.inheritFromWidgetOfExactType(_InheritedFeatureDiscovery)
        as _InheritedFeatureDiscovery;
  }

  @override
  bool updateShouldNotify(_InheritedFeatureDiscovery old) {
    return old.activeStepId != activeStepId;
  }
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
