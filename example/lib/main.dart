import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

const String feature1 = "FEATURE_1";
const String feature2 = "FEATURE_2";
const String feature3 = "FEATURE_3";
const String feature4 = "FEATURE_4";
const String feature5 = "FEATURE_5";
const String feature6 = "FEATURE_6";
const String feature7 = "FEATURE_7";

void main() {
  timeDilation = 1.0;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Feature Discovery',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      builder: (context, child) {
        return FeatureDiscovery(
          child: child,
        );
      },
      home: const MyHomePage(title: 'Flutter Feature Discovery'),
    );
  }
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
    final Future<void> Function() action = () async => print("IconButton pressed!");
    const Icon icon1 = Icon(Icons.drive_eta);
    const Icon icon2 = Icon(Icons.menu);
    const Icon icon3 = Icon(Icons.search);
    const Icon icon4 = Icon(Icons.add);
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
                contentLocation: ContentOrientation.below,
                title: 'Find the fastest route',
                description: 'Get car, walking, cycling or public transit directions to this place',
                onTargetTap: action,
                onOpen: () async {
                  print("The overlay is about to be displayed");
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
        leading: DescribedFeatureOverlay(
          featureId: feature1,
          tapTarget: icon2,
          backgroundColor: Colors.teal.shade800,
          title: 'Just how you want it',
          description: 'Tap the menu icon to switch accounts, change settings & more.',
          child: IconButton(
            icon: icon2,
            onPressed: () {},
          ),
        ),
        actions: <Widget>[
          DescribedFeatureOverlay(
            featureId: feature2,
            tapTarget: icon3,
            backgroundColor: Colors.green,
            title: 'Search your compounds',
            description: 'Tap the magnifying glass to quickly scan your compounds',
            child: IconButton(
              icon: icon3,
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: const Content(),
      floatingActionButton: DescribedFeatureOverlay(
        featureId: feature3,
        tapTarget: icon4,
        backgroundColor: Colors.green,
        title: 'FAB feature',
        description: 'This is FAB and it does stuff.',
        child: FloatingActionButton(
          onPressed: () {},
          tooltip: 'Increment',
          child: icon4,
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
        const {
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
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Container(
                height: 200,
                width: double.infinity,
                child: const Text("Imagine there is a beautiful picture here"),
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
                  onTargetTap: () async => print('Tapped tap target.'),
                  onOpen: () async {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ensureKey.currentState.ensureVisible();
                    });
                    return true;
                  },
                  title: 'Discover Features',
                  description:
                      'Find all available feature in this application with this button.',
                  child: EnsureVisible(
                    key: ensureKey,
                    child: RaisedButton(
                      child: Text('Do Feature Discovery'),
                      onPressed: () {
                        FeatureDiscovery.discoverFeatures(
                          context,
                          const {
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
              DescribedFeatureOverlay(
                featureId: feature6,
                tapTarget: const Icon(Icons.drive_eta),
                backgroundColor: Colors.green,
                onTargetTap: () async => print('Tapped tap target.'),
                onOpen: () async {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ensureKey2.currentState.ensureVisible();
                  });
                  return true;
                },
                title: 'Test text',
                description:
                    'This text is just for test and we dont care about it at all.',
                child: EnsureVisible(
                  key: ensureKey2,
                  child: Text(
                    'Custom text',
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
                print('Tapped tap target.');
                return true;
              },
              title: 'Find the fastest route',
              description:
                  'Get car, walking, cycling or public transit directions to this place.',
              child: FloatingActionButton(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
                child: const Icon(Icons.drive_eta),
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
