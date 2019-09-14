import 'dart:math';

import 'package:feature_discovery/src/layout.dart';
import 'package:flutter/material.dart';

part 'described_feature_overlay.dart';

class FeatureDiscovery extends StatefulWidget {
  const FeatureDiscovery({Key key, this.child}) : super(key: key);

  static String activeStep(BuildContext context) {
    return _InheritedFeatureDiscovery.of(context).activeStepId;
  }

  /// Steps are the featureIds of the overlays.
  /// Though they can be placed in any [Iterable], it is recommended to pass them as a [Set]
  /// because this ensures that every step is only shown once.
  static void discoverFeatures(BuildContext context, Iterable<String> steps) {
    _FeatureDiscoveryState.of(context).discoverFeatures(steps.toList());
  }

  /// This will schedule completion of the current discovery step and continue
  /// onto the step after the activation animation of the current overlay if successful.
  ///
  /// If the [DescribedFeatureOverlay] that is associated with the current step is
  /// not being displayed, this will fail. In that case, use [completeStep].
  ///
  /// The [stepId] ensures that you are marking the correct feature for completion.
  /// If the provided [stepId] does not match the feature that is currently shown, i.e.
  /// the currently active step, nothing will happen.
  static void markStepComplete(BuildContext context, String stepId) {
    _FeatureDiscoveryState.of(context).markStepComplete(stepId);
  }

  /// It is recommend to use [markStepComplete] whenever you can as it shows an animation for context.
  ///
  /// This will force complete the current step and move on to the next step without any animations.
  static void completeStep(BuildContext context) {
    _FeatureDiscoveryState.of(context).completeStep();
  }

  /// This will schedule dismissal of the current discovery step and with that
  /// of the current feature discovery. The dismissal animation will play if successful.
  /// If you want to complete the step instead and with that continue the feature discovery,
  /// you will need to call [markStepComplete] instead.
  ///
  /// If the [DescribedFeatureOverlay] that is associated with the current step is
  /// not being displayed, this will fail. In that case, use [clear].
  static void dismiss(BuildContext context) {
    _FeatureDiscoveryState.of(context).dismiss();
  }

  /// This will force clear the current feature discovery and cancel the whole
  /// process without an animation.
  /// If you want to dismiss the current step regularly, call [dismiss].
  static void clear(BuildContext context) {
    _FeatureDiscoveryState.of(context).clear();
  }

  final Widget child;

  @override
  _FeatureDiscoveryState createState() => _FeatureDiscoveryState();
}

class _FeatureDiscoveryState extends State<FeatureDiscovery> {
  static _FeatureDiscoveryState of(BuildContext context) {
    _FeatureDiscoveryState fdState =
        context.ancestorStateOfType(TypeMatcher<_FeatureDiscoveryState>())
            as _FeatureDiscoveryState;
    assert(fdState != null,
        "Don't forget to wrap your widget tree in a [FeatureDiscovery] widget.");
    return fdState;
  }

  List<String> steps;
  int activeStepIndex;

  /// This variable ensures that each discovery step only shows one overlay.
  ///
  /// If one widget is placed multiple times in the widget tree, e.g. by
  /// [DropdownButton], this is necessary to avoid showing duplicate overlays.
  bool stepShown;

  bool stepShouldDismiss, stepShouldComplete;

  @override
  void initState() {
    // This is necessary to be able to evaluate the boolean expressions in _InheritedFeatureDiscovery.shouldUpdate.
    stepShouldDismiss = false;
    stepShouldComplete = false;

    super.initState();
  }

  void discoverFeatures(List<String> steps) {
    setState(() {
      stepShown = false;
      stepShouldComplete = false;
      stepShouldDismiss = false;
      this.steps = steps;
      activeStepIndex = 0;
    });
  }

  void markStepComplete(String stepId) {
    if (steps == null || stepId != steps[activeStepIndex]) return;

    setState(() => stepShouldComplete = true);
  }

  void completeStep() {
    if (steps == null) return;

    activeStepIndex++;

    if (activeStepIndex >= steps.length)
      clear();
    else
      setState(() {
        stepShown = false;
        stepShouldComplete = false;
      });
  }

  void dismiss() {
    setState(() => stepShouldDismiss = true);
  }

  void clear() {
    setState(() {
      steps = null;
      activeStepIndex = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedFeatureDiscovery(
      activeStepId: steps?.elementAt(activeStepIndex),
      stepShouldDismiss: stepShouldDismiss,
      stepShouldComplete: stepShouldComplete,
      child: widget.child,
    );
  }
}

class _InheritedFeatureDiscovery extends InheritedWidget {
  final String activeStepId;
  final bool stepShouldDismiss, stepShouldComplete;

  const _InheritedFeatureDiscovery({
    Key key,
    @required Widget child,
    this.activeStepId,
    this.stepShouldComplete,
    this.stepShouldDismiss,
  })  : assert(child != null),
        super(key: key, child: child);

  static _InheritedFeatureDiscovery of(BuildContext context) =>
      context.inheritFromWidgetOfExactType(_InheritedFeatureDiscovery)
          as _InheritedFeatureDiscovery;

  @override
  bool updateShouldNotify(_InheritedFeatureDiscovery old) =>
      old.activeStepId != activeStepId ||
      (old.stepShouldComplete || old.stepShouldDismiss) !=
          (stepShouldComplete || stepShouldDismiss);
}
