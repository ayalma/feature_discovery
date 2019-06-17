import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

final feature1 = "FEATURE_1";
final feature2 = "FEATURE_2";
final feature3 = "FEATURE_3";
final feature4 = "FEATURE_4";

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Feature Discavery',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Feature Discavery'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return FeatureDiscovery(
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          leading: DescribedFeatureOverlay(
            featureId: feature1,
            icon: Icons.menu,
            color: Colors.green,
            title: 'The Title',
            description: 'The Description',
            child: IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {},
            ),
          ),
          actions: <Widget>[
            DescribedFeatureOverlay(
              featureId: feature2,
              icon: Icons.search,
              color: Colors.green,
              title: 'The Title',
              description: 'The Description',
              child: IconButton(
                icon: Icon(Icons.search),
                onPressed: () {},
              ),
            ),
          ],
        ),
        body: Content(),
        floatingActionButton: DescribedFeatureOverlay(
          featureId: feature3,
          icon: Icons.menu,
          color: Colors.green,
          title: 'The Title',
          description: 'The Description',
          child: FloatingActionButton(
            onPressed: () {},
            tooltip: 'Increment',
            child: Icon(Icons.add),
          ),
        ),
      ),
    );
  }
}

class Content extends StatefulWidget {
  @override
  _ContentState createState() => _ContentState();
}

class _ContentState extends State<Content> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: <Widget>[
            Image.network(
              'https://www.balboaisland.com/wp-content/uploads/dish-republic-balboa-island-newport-beach-ca-496x303.jpg',
              fit: BoxFit.cover,
              width: double.infinity,
              height: 200.0,
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.0),
              color: Colors.blue,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      'DISH REPUBLIC',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24.0,
                      ),
                    ),
                  ),
                  Text(
                    'Eat',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.0,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              child: RaisedButton(
                child: Text('Do Feature Discavery'),
                onPressed: () {
                  FeatureDiscovery.discoverFeatures(
                    context, [feature1, feature2, feature3, feature4],);
                },
              ),
            ),
          ],
        ),
        Positioned(
          top: 200.0,
          right: 0.0,
          child: DescribedFeatureOverlay(
            featureId: feature4,
            icon: Icons.drive_eta,
            color: Colors.green,
            title: 'The Title',
            description: 'The Description',
            child: FractionalTranslation(
              translation: const Offset(-.5, -0.5),
              child: FloatingActionButton(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                child: Icon(Icons.drive_eta),
                onPressed: () {
                  //TODO:
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

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

class _InheritedFeatureDiscovery extends InheritedWidget {
  final String activeStepId;

  const _InheritedFeatureDiscovery({
    Key key,
    @required Widget child,
    this.activeStepId,
  })
      : assert(child != null),
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

  const DescribedFeatureOverlay({Key key,
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
    screenSize = MediaQuery
        .of(context)
        .size;
    showOverlayIfActiveStep();
  }

  void showOverlayIfActiveStep() {
    String activeStep = FeatureDiscovery.activeStep(context);
    setState(() {
      showOverlay = activeStep == widget.featureId;
    });
  }


  bool isCloseToTopOrBottom(Offset position) {
    return position.dy <= 88.0 || (screenSize.height - position.dy) <= 88.0;
  }

  bool isOnTopHalfOfScreen(Offset position) {
    return position.dy < (screenSize.height / 2.0);
  }

  bool isOnLeftHalfOfScreen(Offset position) {
    return position.dx < (screenSize.width / 2.0);
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


  void activate() {
    FeatureDiscovery.markStepComplete(context, widget.featureId);
  }

  void dismiss() {
    FeatureDiscovery.dismiss(context);
  }

  @override
  Widget build(BuildContext context) {
    return AnchoredOverlay(
      showOverlay: showOverlay,
      overlayBuilder: (BuildContext context, Offset anchor) {
        final touchTargetRadius = 44.0;

        final contentOrientation = getContentOrientation(anchor);
        final contentOffsetMultiplier =
        contentOrientation == DescribedFeatureContentOrientation.below
            ? 1.0
            : -1.0;
        final contentY =
            anchor.dy + contentOffsetMultiplier * (touchTargetRadius + 20);
        final contentFractionalOffset =
        contentOffsetMultiplier.clamp(-1.0, 0.0);
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
            CenterAbout(
              position: backgroundPosition,
              child: Container(
                width: 2 * backgroundRadius,
                height: 2 * backgroundRadius,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withOpacity(0.96)),
              ),
            ),
            Positioned(
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
                            widget.title,
                            style: TextStyle(
                              fontSize: 20.0,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Text(
                          widget.description,
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
            ),
            CenterAbout(
              position: anchor,
              child: Container(
                height: 2 * touchTargetRadius,
                width: 2 * touchTargetRadius,
                child: RawMaterialButton(
                  fillColor: Colors.white,
                  shape: CircleBorder(),
                  child: Icon(
                    widget.icon,
                    color: widget.color,
                  ),
                  onPressed: activate,
                ),
              ),
            )
          ],
        );
      },
      child: widget.child,
    );
  }
}

enum DescribedFeatureContentOrientation {
  above,
  below,
}
