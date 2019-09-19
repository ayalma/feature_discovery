import 'dart:async';
import 'dart:math' as Math;

import 'package:feature_discovery/src/layout.dart';
import 'package:flutter/material.dart';

part 'described_feature_overlay.dart';

enum ContentOrientation {
  above,
  below,
  trivial,
}

class FeatureDiscovery extends StatefulWidget {

  static _Bloc _blocOf(BuildContext context) {
    FeatureDiscovery state = context.ancestorWidgetOfExactType(FeatureDiscovery);
    assert(state != null, "Don't forget to wrap your widget tree in a [FeatureDiscovery] widget.");
    return state._bloc;
  }

  /// Steps are the featureIds of the overlays.
  /// Though they can be placed in any [Iterable], it is recommended to pass them as a [Set]
  /// because this ensures that every step is only shown once.
  static void discoverFeatures(BuildContext context, Iterable<String> steps)
    => _blocOf(context)._discoverFeatures(steps: steps.toList());

  /// This will schedule completion of the current discovery step and continue
  /// onto the step after the activation animation of the current overlay if successful.
  /// 
  /// The [stepId] ensures that you are marking the correct feature for completion.
  /// If the provided [stepId] does not match the feature that is currently shown, i.e.
  /// the currently active step, nothing will happen.
  static void completeCurrentStep(BuildContext context)   
    => _blocOf(context)._completeStep();

  /// This will schedule dismissal of the current discovery step and with that
  /// of the current feature discovery. The dismissal animation will play if successful.
  /// If you want to complete the step and continue the feature discovery,
  /// call [completeCurrentStep] instead.
  static void dismiss(BuildContext context)
    => _blocOf(context)._dismiss();

  // Deprecated methods (kept for retrocompatibility)
  @Deprecated("Use [dismiss] instead")
  static void clear(BuildContext context) => dismiss(context);
  @Deprecated("Use [completeCurrentStep] instead")
  static void completeStep(BuildContext context) => completeCurrentStep(context);
  @Deprecated("Use [completeCurrentStep] instead ; [stepId] argument will not be used")
  static void markStepComplete(BuildContext context, String stepId) => completeCurrentStep(context);

  final Widget child;
  final _Bloc _bloc;
  
  FeatureDiscovery({
    Key key, 
    @required this.child
  }) : 
    _bloc = _Bloc(),
    super(key: key);

  @override
  _FeatureDiscoveryState createState() => _FeatureDiscoveryState();
}

class _FeatureDiscoveryState extends State<FeatureDiscovery> {
  
  @override
  void dispose() {
    widget._bloc?._dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _Bloc {

  Iterable<String> _steps;
  int _activeStepIndex;

  // The different streams send the featureId that must display/complete

  final StreamController<String> _dismissController = StreamController.broadcast();
  Stream<String> get outDismiss => _dismissController.stream;
  Sink<String> get _inDismiss => _dismissController.sink;

  final StreamController<String> _completeController = StreamController.broadcast();
  Stream<String> get outComplete => _completeController.stream;
  Sink<String> get _inComplete => _completeController.sink;

  final StreamController<String> _startController = StreamController.broadcast();
  Stream<String> get outStart => _startController.stream;
  Sink<String> get _inStart => _startController.sink;

  String get _activeStepId => _steps?.elementAt(_activeStepIndex);

  void _dispose() {
    _dismissController.close();
    _completeController.close();
    _startController.close();
  }

  void _discoverFeatures({Iterable<String> steps}) {
    assert(steps != null);
    _steps = steps;
    _activeStepIndex = 0;
    _inStart.add(_activeStepId);
  }

  void _completeStep() {
    if (_steps == null) return;
    _inComplete.add(_activeStepId);
    _activeStepIndex++;
    if (_activeStepIndex < _steps.length)
      _inStart.add(_activeStepId);    
  }

  void _dismiss() {
    _inDismiss.add(_activeStepId);
  }

}
