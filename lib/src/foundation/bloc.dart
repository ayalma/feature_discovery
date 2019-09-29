import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

class BlocProvider extends StatelessWidget {
  final Widget child;

  const BlocProvider({Key key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Provider<Bloc>(
      child: child,
      builder: (context) => Bloc(),
      dispose: (context, bloc) => bloc.dispose(),
    );
  }
}

class Bloc {
  /// This is used to retrieve the [Bloc] in [FeatureDiscovery] and [DescribedOverlayState].
  /// It can be public here because [Bloc] is not exposed when importing `feature_discovery`.
  static Bloc of(BuildContext context) {
    final Bloc bloc = Provider.of<Bloc>(context, listen: false);
    assert(bloc != null,
        "Don't forget to wrap your widget tree in a [FeatureDiscovery] widget.");
    return bloc;
  }

  // The different streams send the featureId that must display/complete.

  final StreamController<String> _dismissController =
      StreamController.broadcast();

  Stream<String> get outDismiss => _dismissController.stream;

  Sink<String> get _inDismiss => _dismissController.sink;

  final StreamController<String> _completeController =
      StreamController.broadcast();

  Stream<String> get outComplete => _completeController.stream;

  Sink<String> get _inComplete => _completeController.sink;

  final StreamController<String> _startController =
      StreamController.broadcast();

  Stream<String> get outStart => _startController.stream;

  Sink<String> get _inStart => _startController.sink;

  /// The steps consist of the feature ids of the features to be discovered.
  Iterable<String> _steps;

  int _activeStepIndex;

  String get activeFeatureId =>
      _activeStepIndex == null ? null : _steps?.elementAt(_activeStepIndex);

  /// This is used to determine if the active feature is already shown by
  /// another [DescribedFeatureOverlay] as [DescribedFeatureOverlay.allowShowingDuplicate]
  /// requires this.
  int _activeOverlays;

  int get activeOverlays => _activeOverlays;

  /// [DescribedFeatureOverlay]s use either `activeOverlays++` to add themselves
  /// to the active overlays or `activeOverlays--` to remove themselves.
  set activeOverlays(activeOverlays) {
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
    if (activeOverlays == 0) _inStart.add(activeFeatureId);
  }

  void dispose() {
    _dismissController.close();
    _completeController.close();
    _startController.close();
  }

  void discoverFeatures({Iterable<String> steps}) {
    assert(steps != null);
    _steps = steps;
    _activeStepIndex = 0;
    _activeOverlays = 0;

    _inStart.add(activeFeatureId);
  }

  void completeStep() {
    if (_steps == null) return;
    _inComplete.add(activeFeatureId);

    _activeStepIndex++;
    _activeOverlays = 0;

    if (_activeStepIndex < _steps.length) {
      _inStart.add(activeFeatureId);
      return;
    }

    // The last step has been completed, so we need to clear the steps.
    _steps = null;
    _activeStepIndex = null;
  }

  void dismiss() {
    _steps = null;
    _activeStepIndex = null;
    _activeOverlays = 0;

    _inDismiss.add(activeFeatureId);
  }
}
