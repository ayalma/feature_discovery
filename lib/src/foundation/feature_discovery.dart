import 'package:feature_discovery/src/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Specifies how the content should be positioned relative to the tap target.
///
/// Orientations:
///
///  * [trivial], which lets the library decide where the content should be placed.
///    Make sure to test this for every overlay because the trivial positioning can fail sometimes.
///  * [above], which will layout the content above the tap target.
///  * [below], which will layout the content below the tap target.
enum ContentLocation {
  above,
  below,
  trivial,
}

class FeatureDiscovery extends StatelessWidget {
  /// Steps are the featureIds of the overlays.
  /// Though they can be placed in any [Iterable], it is recommended to pass them as a [Set]
  /// because this ensures that every step is only shown once.
  static void discoverFeatures(BuildContext context, Iterable<String> steps) =>
      Bloc.of(context).discoverFeatures(steps: steps.toList());

  /// This will schedule completion of the current discovery step and continue
  /// onto the step after the activation animation of the current overlay if successful.
  ///
  /// The [stepId] ensures that you are marking the correct feature for completion.
  /// If the provided [stepId] does not match the feature that is currently shown, i.e.
  /// the currently active step, nothing will happen.
  static void completeCurrentStep(BuildContext context) =>
      Bloc.of(context).completeStep();

  /// This will schedule dismissal of the current discovery step and with that
  /// of the current feature discovery. The dismissal animation will play if successful.
  /// If you want to complete the step and continue the feature discovery,
  /// call [completeCurrentStep] instead.
  static void dismiss(BuildContext context) => Bloc.of(context).dismiss();

  /// Deprecated methods, kept for retrocompatibility.
  @Deprecated('Use [dismiss] instead')
  static void clear(BuildContext context) => dismiss(context);

  @Deprecated('Use [completeCurrentStep] instead')
  static void completeStep(BuildContext context) =>
      completeCurrentStep(context);

  @Deprecated(
      'Use [completeCurrentStep] instead ; [stepId] argument will not be used')
  static void markStepComplete(BuildContext context, String stepId) =>
      completeCurrentStep(context);

  final Widget child;

  const FeatureDiscovery({Key key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Provider<Bloc>(
      builder: (context) => Bloc(),
      dispose: (context, bloc) => bloc.dispose(),
      child: child,
    );
  }
}
