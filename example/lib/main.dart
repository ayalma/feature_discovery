import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

const String feature1 = 'feature1',
    feature2 = 'feature2',
    feature3 = 'feature3',
    feature4 = 'feature4',
    feature5 = 'feature5',
    feature6 = 'feature6',
    feature7 = 'feature7';

void main() {
  // You can increase the timeDilation value if you want to see
  // the animations more slowly.
  timeDilation = 1.0;

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Feature Discovery',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        // Required: this widget works like an inherited widget.
        home: const FeatureDiscovery(
          child: MyHomePage(title: 'Flutter Feature Discovery'),
        ),
      );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    final action = () async {
      print('IconButton of $feature7 tapped.');
      return true;
    };
    const icon1 = Icon(Icons.drive_eta);
    const icon2 = Icon(Icons.menu);
    const icon3 = Icon(Icons.search);
    const icon4 = Icon(Icons.add);

    var feature1OverflowMode = OverflowMode.clipContent;
    var feature1EnablePulsingAnimation = false;

    var feature3ItemCount = 15;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Column(
            children: <Widget>[
              DescribedFeatureOverlay(
                featureId: feature7,
                tapTarget: icon1,
                backgroundColor: Colors.blue,
                contentLocation: ContentLocation.below,
                title: const Text('Find the fastest route'),
                description: const Text(
                    'Get car, walking, cycling, or public transit directions to this place'),
                onComplete: action,
                onOpen: () async {
                  print('The $feature7 overlay is about to be displayed.');
                  return true;
                },
                child: IconButton(
                  icon: icon1,
                  onPressed: action,
                ),
              ),
            ],
          ),
        ),
        leading: StatefulBuilder(
          builder:
              (BuildContext context, void Function(void Function()) setState) =>
                  DescribedFeatureOverlay(
            featureId: feature1,
            tapTarget: icon2,
            backgroundColor: Colors.teal,
            title: const Text(
                'This is overly long on purpose to test OverflowMode.clip!'),
            overflowMode: feature1OverflowMode,
            enablePulsingAnimation: feature1EnablePulsingAnimation,
            description: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                    'Also, notice how the pulsing animation is not playing because it is deactivated for this feature.'),
                FlatButton(
                    child: Text('Toggle enablePulsingAnimation',
                        style: Theme.of(context)
                            .textTheme
                            .button
                            .copyWith(color: Colors.white)),
                    onPressed: () => setState(() {
                          feature1EnablePulsingAnimation =
                              !feature1EnablePulsingAnimation;
                        })),
                const Text(
                    'Ignore the items below or tap the button to toggle between OverflowMode.clip and OverflowMode.doNothing!'),
                FlatButton(
                    child: Text('Toggle overflowMode',
                        style: Theme.of(context)
                            .textTheme
                            .button
                            .copyWith(color: Colors.white)),
                    onPressed: () => setState(() {
                          feature1OverflowMode =
                              feature1OverflowMode == OverflowMode.clipContent
                                  ? OverflowMode.ignore
                                  : OverflowMode.clipContent;
                        })),
                for (int n = 42; n > 0; n--)
                  const Text('Testing clipping (ignore or toggle)',
                      style: TextStyle(backgroundColor: Colors.black)),
              ],
            ),
            child: IconButton(
              icon: icon2,
              onPressed: () {},
            ),
          ),
        ),
        actions: <Widget>[
          DescribedFeatureOverlay(
            featureId: feature2,
            tapTarget: icon3,
            backgroundColor: Colors.green,
            title: const Text('Search your compounds'),
            description: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                    'Tap the magnifying glass to quickly scan your compounds'),
                FlatButton(
                  padding: const EdgeInsets.all(0),
                  child: Text('Understood',
                      style: Theme.of(context)
                          .textTheme
                          .button
                          .copyWith(color: Colors.white)),
                  onPressed: () =>
                      FeatureDiscovery.completeCurrentStep(context),
                ),
                FlatButton(
                  padding: const EdgeInsets.all(0),
                  child: Text('Dismiss',
                      style: Theme.of(context)
                          .textTheme
                          .button
                          .copyWith(color: Colors.white)),
                  onPressed: () => FeatureDiscovery.dismissAll(context),
                ),
              ],
            ),
            child: IconButton(
              icon: icon3,
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: const Content(),
      floatingActionButton: StatefulBuilder(
        builder:
            (BuildContext context, void Function(void Function()) setState) =>
                DescribedFeatureOverlay(
          featureId: feature3,
          tapTarget: icon4,
          backgroundColor: Colors.green,
          overflowMode: OverflowMode.extendBackground,
          title: const Text('FAB feature'),
          description: Column(children: <Widget>[
            const Text(
                'This is overly long to test OverflowMode.extendBackground. The green circle should be large enough to cover all of the text.'),
            FlatButton(
                child: Text('Add another item',
                    style: Theme.of(context)
                        .textTheme
                        .button
                        .copyWith(color: Colors.white)),
                onPressed: () => setState(() {
                      feature3ItemCount++;
                    })),
            for (int n = feature3ItemCount; n > 0; n--)
              const Text('Testing OverflowMode.extendBackground'),
          ]),
          child: FloatingActionButton(
            onPressed: () {},
            tooltip: 'Increment',
            child: icon4,
          ),
        ),
      ),
    );
  }
}

class Content extends StatefulWidget {
  const Content({Key key}) : super(key: key);

  @override
  _ContentState createState() => _ContentState();
}

class _ContentState extends State<Content> {
  GlobalKey<EnsureVisibleState> ensureKey;
  GlobalKey<EnsureVisibleState> ensureKey2;

  @override
  void initState() {
    ensureKey = GlobalKey<EnsureVisibleState>();
    ensureKey2 = GlobalKey<EnsureVisibleState>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FeatureDiscovery.discoverFeatures(
        context,
        const <String>{
          feature7,
          feature1,
          feature2,
          feature3,
          feature4,
          feature6,
          feature5
        },
      );
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var feature6ItemCount = 0;

    return Stack(
      children: <Widget>[
        SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Container(
                height: 200,
                width: double.infinity,
                child: const Text(
                    'Imagine there would be a beautiful picture here.'),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                color: Colors.blue,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'DISH REPUBLIC',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24.0,
                        ),
                      ),
                    ),
                    const Text(
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
                height: 600.0,
                color: Colors.orangeAccent,
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                child: DescribedFeatureOverlay(
                  featureId: feature5,
                  tapTarget: const Icon(Icons.drive_eta),
                  backgroundColor: Colors.green,
                  onComplete: () async {
                    print('Tapped tap target of $feature5.');
                    return true;
                  },
                  onOpen: () async {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ensureKey.currentState.ensureVisible(
                        preciseAlignment: 0.5,
                        duration: const Duration(milliseconds: 400),
                      );
                    });
                    return true;
                  },
                  title: const Text('Discover Features'),
                  description: const Text(
                      'Find all available features in this application with this button.'),
                  contentLocation: ContentLocation.below,
                  child: EnsureVisible(
                    key: ensureKey,
                    child: RaisedButton(
                      child: const Text('Start Feature Discovery'),
                      onPressed: () {
                        FeatureDiscovery.discoverFeatures(
                          context,
                          const <String>{
                            feature1,
                            feature2,
                            feature3,
                            feature4,
                            feature6,
                            feature5
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
              Container(
                height: 1500,
                color: Colors.blueAccent,
              ),
              StatefulBuilder(
                builder: (BuildContext context,
                        void Function(void Function()) setState) =>
                    DescribedFeatureOverlay(
                  featureId: feature6,
                  tapTarget: const Icon(Icons.drive_eta),
                  backgroundColor: Colors.green,
                  onComplete: () async {
                    print('Tapped tap target of $feature6.');
                    return true;
                  },
                  onOpen: () async {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ensureKey2.currentState.ensureVisible(
                          duration: const Duration(milliseconds: 600));
                    });
                    return true;
                  },
                  description: Column(children: <Widget>[
                    const Text(
                        'You can test OverflowMode.wrapBackground here.'),
                    FlatButton(
                        padding: const EdgeInsets.all(0),
                        child: Text('Add item',
                            style: Theme.of(context)
                                .textTheme
                                .button
                                .copyWith(color: Colors.white)),
                        onPressed: () => setState(() {
                              feature6ItemCount++;
                            })),
                    for (int n = feature6ItemCount; n > 0; n--)
                      const Text('Testing OverflowMode.wrapBackground'),
                  ]),
                  overflowMode: OverflowMode.wrapBackground,
                  child: EnsureVisible(
                    key: ensureKey2,
                    child: const Text(
                      'Custom text',
                    ),
                  ),
                ),
              ),
              Container(
                height: 300,
                color: Colors.red,
              ),
            ],
          ),
        ),
        Positioned(
          top: 200.0,
          right: 0.0,
          child: FractionalTranslation(
            translation: const Offset(-.5, -0.5),
            child: DescribedFeatureOverlay(
              featureId: feature4,
              tapTarget: const Icon(Icons.drive_eta),
              backgroundColor: Colors.green,
              onOpen: () async {
                print('Tapped tap target of $feature4.');
                return true;
              },
              title: const Text('Find the fastest route'),
              description: const Text(
                  'Get car, walking, cycling or public transit directions to this place.'),
              child: FloatingActionButton(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                child: const Icon(Icons.drive_eta),
                onPressed: () {
                  print('Floating action button tapped.');
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
