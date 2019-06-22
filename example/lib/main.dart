import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

final feature1 = "FEATURE_1";
final feature2 = "FEATURE_2";
final feature3 = "FEATURE_3";
final feature4 = "FEATURE_4";
final feature5 = "FEATURE_5";
final feature6 = "FEATURE_6";
final feature7 = "FEATURE_7";

void main() {
  timeDilation = 1.0;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Feature Discavery',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      builder: (context, child) {
        return FeatureDiscovery(
          child: child,
        );
      },
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: PreferredSize(
          child: Column(
            children: <Widget>[
              DescribedFeatureOverlay(
                featureId: feature7,
                icon: Icons.print,
                color: Colors.purple,
                contentLocation: ContentOrientation.below,
                title: 'Just how you want it',
                description:
                    'Tap the menu icon to switch account, change setting & more.Tap the menu icon to switch account, change setting & more.',
                child: IconButton(
                  icon: Icon(Icons.print),
                ),
              ),
            ],
          ),
          preferredSize: Size.fromHeight(80),
        ),
        leading: DescribedFeatureOverlay(
          featureId: feature1,
          icon: Icons.menu,
          color: Colors.green,
          title: 'Just how you want it',
          description:
              'Tap the menu icon to switch account, change setting & more.',
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
            title: 'Search your compounds',
            description:
                'Tap the magnifying glass to quickly scan your compounds',
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
        title: 'FAB feature',
        description: 'This is FAB and it does stuff.',
        child: FloatingActionButton(
          onPressed: () {},
          tooltip: 'Increment',
          child: Icon(Icons.add),
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
  GlobalKey<EnsureVisibleState> ensureKey;
  GlobalKey<EnsureVisibleState> ensureKey2;

  @override
  void initState() {
    ensureKey = GlobalKey<EnsureVisibleState>();
    ensureKey2 = GlobalKey<EnsureVisibleState>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FeatureDiscovery.discoverFeatures(
        context,
        [feature7, feature1, feature2, feature3, feature4, feature6, feature5],
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
                height: 600.0,
                color: Colors.orangeAccent,
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                child: DescribedFeatureOverlay(
                  featureId: feature5,
                  icon: Icons.drive_eta,
                  color: Colors.green,
                  doAction: (f) {
                    print('ha ha ha ');
                    f();
                  },
                  prepareAction: (done) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ensureKey.currentState.ensureVisible();
                      done();
                    });
                  },
                  title: 'Discover Featurs',
                  description:
                      'Find all available feature in this application with this button.',
                  child: EnsureVisible(
                    key: ensureKey,
                    child: RaisedButton(
                      child: Text('Do Feature Discavery'),
                      onPressed: () {
                        FeatureDiscovery.discoverFeatures(
                          context,
                          [
                            feature1,
                            feature2,
                            feature3,
                            feature4,
                            feature6,
                            feature5
                          ],
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
                icon: Icons.drive_eta,
                color: Colors.green,
                doAction: (f) {
                  print('ha ha ha ');
                  f();
                },
                prepareAction: (done) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ensureKey2.currentState.ensureVisible();
                    done();
                  });
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
              icon: Icons.drive_eta,
              color: Colors.green,
              doAction: (f) {
                print('ha ha ha ');
                f();
              },
              title: 'Find the fastest route',
              description:
                  'Get car, walking, cycling or public transit directions to this place.',
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
