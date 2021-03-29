import 'package:feature_discovery/src/foundation.dart';
import 'package:flutter/material.dart';

import 'persistence_provider.dart';

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
  static Bloc _blocOf(BuildContext context) {
    try {
      return Bloc.of(context);
    } on BlocNotFoundError catch (e) {
      throw FlutterError(e.message +
          '\nEnsure that it also wraps the context of the ${context.widget.runtimeType} widget from which you have called a static method in FeatureDiscovery.');
    }
  }

  /// Steps are the featureIds of the overlays.
  /// Though they can be placed in any [Iterable], it is recommended to pass them as a [Set]
  /// because this ensures that every step is only shown once.
  static void discoverFeatures(BuildContext context, Iterable<String> steps) =>
      _blocOf(context).discoverFeatures(steps.toList());

  /// This will force the completion of the current step and continue
  /// onto the next step after the completion animation of the current overlay.
  ///
  /// The `onComplete` parameter will be ignored for every active overlay.
  static Future<void> completeCurrentStep(BuildContext context) async =>
      _blocOf(context).completeStep();

  /// This will return true iff
  /// this [featureId] has been recorded as completed
  /// in the Shared Preferences.
  static Future<bool> hasPreviouslyCompleted(
    BuildContext context,
    String featureId,
  ) =>
      _blocOf(context).hasPreviouslyCompleted(featureId);

  static Future<void> clearPreferences(
          BuildContext context, Iterable<String> steps) =>
      _blocOf(context).clearPreferences(steps);

  /// A method to dismiss all steps.
  ///
  /// The `onDismiss` parameter will be ignored for every active overlay.
  /// If you want to complete the current step and continue the feature discovery,
  /// call [completeCurrentStep] instead.
  static void dismissAll(BuildContext context) => _blocOf(context).dismiss();

  /// This returns the feature id of the current feature discovery step, i.e.
  /// of the [DescribedFeatureOverlay] that is currently supposed to be shown, or `null`.
  ///
  /// Note that this will also return the feature id of the current step of the steps
  /// you passed to [discoverFeatures] even when there is no [DescribedFeatureOverlay]
  /// in the tree to display the overlay.
  /// This means that you cannot use this to check if a feature overlay is being displayed.
  static String currentFeatureIdOf(BuildContext context) =>
      _blocOf(context).activeFeatureId;

  final Widget child;

  /// The [PersistenceProvider] implementation to use for persisting steps that have been
  /// previously completed.
  ///
  /// By default, this uses a [SharedPreferencesProvider] which uses the 3rd party
  /// SharedPreference plugin.
  final PersistenceProvider persistenceProvider;

  /// Instantiates a new [FeatureDiscovery] and stores completion of steps
  /// through the provided [persistenceProvider][PersistenceProvider].
  const FeatureDiscovery.withProvider({
    @required this.child,
    @required this.persistenceProvider,
    Key key,
  })  : assert(child != null),
        assert(persistenceProvider != null),
        super(key: key);

  /// Instantiates a new [FeatureDiscovery].
  ///
  /// If [recordStepsInSharedPreferences] is true, the completion of the steps
  /// will be recorded in the Shared Preferences.
  ///
  /// If [sharedPreferencesPrefix] is provided, it will added before the
  /// feature ids to form the keys for the Shared Preferences.
  ///
  /// The key for each step will be
  /// ```
  /// '${sharedPreferencesPrefix}${featureId}'
  /// ```
  ///
  /// [sharedPreferencesPrefix] is used only if [recordStepsInSharedPreferences]
  /// is true.
  factory FeatureDiscovery({
    @required Widget child,
    bool recordStepsInSharedPreferences = true,
    String sharedPreferencesPrefix,
    Key key,
  }) =>
      FeatureDiscovery.withProvider(
        key: key,
        persistenceProvider: recordStepsInSharedPreferences == true
            ? SharedPreferencesProvider(sharedPreferencesPrefix)
            : const NoPersistenceProvider(),
        child: child,
      );

  @override
  Widget build(BuildContext context) => BlocProvider(
        child: child,
        persistenceProvider: persistenceProvider,
      );
}
