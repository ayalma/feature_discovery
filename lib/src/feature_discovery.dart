import 'dart:async';

import 'package:flutter/material.dart' hide OverlayState;

class FeatureDiscovery extends StatefulWidget {

  // TODO: This method should not be available to the public
  static _FeatureDiscoveryState of(BuildContext context) {
    _FeatureDiscoveryState state = 
      (context.inheritFromWidgetOfExactType(_InheritedFeatureDiscovery)
        as _InheritedFeatureDiscovery)
        .state;
    assert(state != null,
      "Don't forget to wrap your widget tree in a [FeatureDiscovery] widget.");
    return state;
  }

  /// Steps are the featureIds of the overlays.
  /// Though they can be placed in any [Iterable], it is recommended to pass them as a [Set]
  /// because this ensures that every step is only shown once.
  static void discoverFeatures(BuildContext context, Iterable<String> steps)
    => of(context).discoverFeatures(steps.toList());

  /// This will schedule completion of the current discovery step and continue
  /// onto the step after the activation animation of the current overlay if successful.
  ///
  /// If the [DescribedFeatureOverlay] that is associated with the current step is
  /// not being displayed, this will fail. In that case, use [_completeStep].
  ///
  /// The [stepId] ensures that you are marking the correct feature for completion.
  /// If the provided [stepId] does not match the feature that is currently shown, i.e.
  /// the currently active step, nothing will happen.
  static void completeCurrentStep(BuildContext context)   
    => of(context).bloc._inComplete.add(null);

  /// This will schedule dismissal of the current discovery step and with that
  /// of the current feature discovery. The dismissal animation will play if successful.
  /// If you want to complete the step instead and with that continue the feature discovery,
  /// you will need to call [markStepComplete] instead.
  ///
  /// If the [DescribedFeatureOverlay] that is associated with the current step is
  /// not being displayed, this will fail. In that case, use [clear].
  static void dismissCurrentStep(BuildContext context)
    => of(context).bloc._inDismiss.add(null);

  final Widget child;
  
  const FeatureDiscovery({
    Key key, 
    @required this.child
  }) : super(key: key);

  @override
  _FeatureDiscoveryState createState() => _FeatureDiscoveryState();
}

class _FeatureDiscoveryState extends State<FeatureDiscovery> {
  
  Bloc _bloc;
  List<String> _steps;
  int _activeStepIndex;

  /// This variable ensures that each discovery step only shows one overlay.
  ///
  /// If one widget is placed multiple times in the widget tree, e.g. by
  /// [DropdownButton], this is necessary to avoid showing duplicate overlays.
  bool stepShown;

  String get activeStepId => _steps?.elementAt(_activeStepIndex);
  Bloc get bloc => _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = Bloc();
    bloc.outComplete.listen((_) {
      bloc._outAnimationFinished
        .take(1)
        .listen((_) => _completeStep());
    });
    bloc.outDismiss.listen((_) {
      bloc._outAnimationFinished
        .take(1)
        .listen((_) => _clear());
    });
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }

  void discoverFeatures(List<String> steps) {
    stepShown = false;
    _steps = steps;
    _activeStepIndex = 0;
    bloc._inStart.add(null);
  }

  void _completeStep() {
    if (_steps == null) return;

    _activeStepIndex++;

    if (_activeStepIndex >= _steps.length)
      _clear();
    else
      stepShown = false;
      bloc._inStart.add(null);
    
  }

  void _clear() async {
    _steps = null;
    _activeStepIndex = null;
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedFeatureDiscovery(
      state: this,
      child: widget.child,
    );
  }
}

class _InheritedFeatureDiscovery extends InheritedWidget {

  final _FeatureDiscoveryState state;

  const _InheritedFeatureDiscovery({
    Key key,
    @required Widget child,
    @required this.state
  }) : 
    assert(child != null),
    super(key: key, child: child);

  @override
  bool updateShouldNotify(_InheritedFeatureDiscovery old) => old.state.bloc != state.bloc;
}

class Bloc {

  final StreamController<void> _dismissController = StreamController.broadcast();
  Stream<void> get outDismiss => _dismissController.stream;
  Sink<void> get _inDismiss => _dismissController.sink;

  final StreamController<void> _completeController = StreamController.broadcast();
  Stream<void> get outComplete => _completeController.stream;
  Sink<void> get _inComplete => _completeController.sink;

  final StreamController<void> _startController = StreamController.broadcast();
  Stream<void> get outStart => _startController.stream;
  Sink<void> get _inStart => _startController.sink;

  final StreamController<void> _animationFinished = StreamController.broadcast();
  Stream<void> get _outAnimationFinished => _animationFinished.stream;

  void dispose () {
    _dismissController.close();
    _completeController.close();
    _startController.close();
    _animationFinished.close();
  }

  void animationIsFinished () => _animationFinished.sink.add(null);
}
