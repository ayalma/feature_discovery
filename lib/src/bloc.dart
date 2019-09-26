import 'dart:async';

class Bloc {
  Iterable<String> _steps;
  int _activeStepIndex;

  // The different streams send the featureId that must display/complete

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

  String get _activeStepId => _steps?.elementAt(_activeStepIndex);

  void dispose() {
    _dismissController.close();
    _completeController.close();
    _startController.close();
  }

  void discoverFeatures({Iterable<String> steps}) {
    assert(steps != null);
    _steps = steps;
    _activeStepIndex = 0;
    _inStart.add(_activeStepId);
  }

  void completeStep() {
    if (_steps == null) return;
    _inComplete.add(_activeStepId);
    _activeStepIndex++;
    if (_activeStepIndex < _steps.length) _inStart.add(_activeStepId);
  }

  void dismiss() {
    _inDismiss.add(_activeStepId);
  }
}
