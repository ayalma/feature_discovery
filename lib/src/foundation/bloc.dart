import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'persistence_provider.dart';

class BlocProvider extends StatelessWidget {
  final Widget child;
  final PersistenceProvider persistenceProvider;

  const BlocProvider({
    Key? key,
    required this.child,
    required this.persistenceProvider,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Provider<Bloc>(
        child: child,
        create: (BuildContext context) => Bloc._(
          persistenceProvider: persistenceProvider,
        ),
        dispose: (BuildContext context, Bloc bloc) => bloc._dispose(),
      );
}

class Bloc {
  /// This is used to retrieve the [Bloc] in [FeatureDiscovery] and [DescribedOverlayState].
  /// It can be public here because [Bloc] is not exposed when importing `feature_discovery`.
  static Bloc of(BuildContext context) {
    try {
      return Provider.of<Bloc>(context, listen: false);
    } on ProviderNotFoundException {
      throw BlocNotFoundError(
          'Could not find a FeatureDiscovery widget above this context.'
          '\nFeatureDiscovery works like an inherited widget. You must wrap your widget tree in it.');
    }
  }

  final PersistenceProvider persistenceProvider;

  Bloc._({
    required this.persistenceProvider,
  });

  /// This [StreamController] allows to send events of type [EventType].
  /// The [DescribedFeatureOverlay]s will be able to handle these events by checking the
  /// [activeFeatureId] against its own feature id or by considering its current [FeatureOverlayState].
  final _eventsController = StreamController<EventType>.broadcast();

  Stream<EventType> get eventsOut => _eventsController.stream;

  Sink<EventType> get _eventsIn => _eventsController.sink;

  /// The steps consist of the feature ids of the features to be discovered.
  List<String?>? _steps;

  /// Steps that have been previously completed.
  Set<String?>? _stepsToIgnore;

  int? _activeStepIndex;

  String? get activeFeatureId => _steps == null ||
          _activeStepIndex == null ||
          _activeStepIndex! >= _steps!.length ||
          _activeStepIndex! < 0
      ? null
      : _steps![_activeStepIndex!];

  /// This is used to determine if the active feature is already shown by
  /// another [DescribedFeatureOverlay] as [DescribedFeatureOverlay.allowShowingDuplicate]
  /// requires this.
  late int _activeOverlays;

  int get activeOverlays => _activeOverlays;

  /// [DescribedFeatureOverlay]s use either `activeOverlays++` to add themselves
  /// to the active overlays or `activeOverlays--` to remove themselves.
  set activeOverlays(int activeOverlays) {
    // Callers (DescribedFeatureOverlay's) can only either add or remove
    // themselves, i.e. the difference will always be 1.
    assert((_activeOverlays - activeOverlays).abs() == 1);

    _activeOverlays = activeOverlays;

    // There is the possibility that two DescribedFeatureOverlays with the same
    // feature id were active when the feature id was added to _inStart initially.
    // However, any of them could have had allowShowingDuplicate set to false,
    // in which case that overlay would not have been opened.
    //
    // If the overlay that was showing the active step was disposed now,
    // which is the only possible cause for activeOverlays == 0 in the setter,
    // then we can possibly show that other overlay again because it is not
    // a duplicate anymore.
    if (activeOverlays == 0) _eventsIn.add(EventType.open);
  }

  void _dispose() {
    _eventsController.close();
  }

  void discoverFeatures(Iterable<String> steps) async {
    assert(steps.isNotEmpty,
        'You need to pass at least one step to [FeatureDiscovery.discoverFeatures].');

    _steps = steps as List<String?>?;
    _stepsToIgnore = await _alreadyCompletedSteps;
    _steps = _steps!.where((s) => !_stepsToIgnore!.contains(s)).toList();
    _activeStepIndex = -1;

    await _nextStep();
  }

  Future<void> completeStep() async {
    if (_steps == null) return;
    // This will ignore the [onComplete] function of all overlays.
    _eventsIn.add(EventType.complete);
    await _nextStep();
  }

  Future<void> _nextStep() async {
    if (activeFeatureId != null) unawaited(_saveCompletionOf(activeFeatureId));
    _activeStepIndex = _activeStepIndex! + 1;
    _activeOverlays = 0;

    if (_activeStepIndex! < _steps!.length) {
      _eventsIn.add(EventType.open);
    } else {
      // The last step has been completed, so we need to clear the steps.
      _steps = null;
      _activeStepIndex = null;
    }
  }

  void dismiss() {
    // This will ignore the [onDismiss] function of all overlays.
    _eventsIn.add(EventType.dismiss);
    _steps = null;
    _activeStepIndex = null;
    _activeOverlays = 0;
  }

  /// Will mark [featureId] as completed in the Shared Preferences.
  Future<void> _saveCompletionOf(String? featureId) async {
    await persistenceProvider.completeStep(featureId);
    _stepsToIgnore?.add(featureId);
  }

  Future<Set<String?>> get _alreadyCompletedSteps =>
      persistenceProvider.completedSteps(_steps);

  /// Returns true iff this step has been previously
  /// recorded as completed in the Shared Preferences
  /// with [saveCompletionOf].
  Future<bool> hasPreviouslyCompleted(String featureId) async {
    _stepsToIgnore ??= await _alreadyCompletedSteps;
    return _stepsToIgnore!.contains(featureId);
  }

  Future<void> clearPreferences(Iterable<String> steps) async =>
      persistenceProvider.clearSteps(steps);
}

/// These are the different types of the event that [Bloc]
/// can send to [DescribedFeatureOverlay]:
///
///  * [open] signals that the overlay should attempt to open itself.
///    This happens when calling [FeatureDiscovery.discoverFeatures]
///    or after a previous step is completed (see below).
///  * [complete] signals that the overlay should attempt to complete itself, which happens
///    when the end user taps the tap target or [FeatureDiscovery.completeCurrentStep] is called.
///  * [dismiss] signals that the overlay should attempt to dismiss itself, which happens
///    when the end user taps or swipes outside of the overlay or
///    [FeatureDiscovery.dismiss] is called manually.
enum EventType {
  open,
  complete,
  dismiss,
}

class BlocNotFoundError extends Error {
  final String message;

  BlocNotFoundError(this.message) : super();
}

void unawaited(Future future) async {
  await future;
}
