import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';

void main() => runApp(MyApp());

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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: DescribedFeatureOverlay(
          showOverlay: false,
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
            showOverlay: false,
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
        showOverlay: false,
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
                  //TODO:
                },
              ),
            ),
          ],
        ),
        Positioned(
          top: 200.0,
          right: 0.0,
          child: DescribedFeatureOverlay(
            showOverlay: true,
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

class DescribedFeatureOverlay extends StatefulWidget {
  final bool showOverlay;
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final Widget child;

  const DescribedFeatureOverlay(
      {Key key,
      this.showOverlay,
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    screenSize = MediaQuery.of(context).size;
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

  @override
  Widget build(BuildContext context) {
    return AnchoredOverlay(
      showOverlay: widget.showOverlay,
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
                  onPressed: () {
                    //TODO:
                  },
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
