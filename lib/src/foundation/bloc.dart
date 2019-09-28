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
    Bloc bloc = Provider.of<Bloc>(context, listen: false);
    assert(bloc != null,
        "Don't forget to wrap your widget tree in a [FeatureDiscovery] widget.");
    return bloc;
  }

  Iterable<String> _steps;
  int _activeStepIndex;

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

  String get activeStepId => _steps?.elementAt(_activeStepIndex);

  void dispose() {
    _dismissController.close();
    _completeController.close();
    _startController.close();
  }

  void discoverFeatures({Iterable<String> steps}) {
    assert(steps != null);
    _steps = steps;
    _activeStepIndex = 0;
    _inStart.add(activeStepId);
  }

  void completeStep() {
    if (_steps == null) return;
    _inComplete.add(activeStepId);
    _activeStepIndex++;
    if (_activeStepIndex < _steps.length) _inStart.add(activeStepId);
  }

  void dismiss() {
    _inDismiss.add(activeStepId);
  }
}
