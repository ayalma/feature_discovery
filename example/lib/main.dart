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
    return OverlayBuilder(
      showOverlay: false,
      overlayBuilder: (context) {
        return CenterAbout(
          position: Offset(200.0, 300.0),
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.purple,
            ),
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          leading: IconButton(icon: Icon(Icons.menu), onPressed: () {}),
          actions: <Widget>[
            IconButton(icon: Icon(Icons.search), onPressed: () {})
          ],
        ),
        body: Content(),
        floatingActionButton: AnchoredOverlay(
          showOverlay: true,
          overlayBuilder: (BuildContext context, Offset anchor) {
            return CenterAbout(
              position: anchor,
              child: Text('Hello?'),
            );
          },
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
                  //TODO:
                },
              ),
            ),
          ],
        ),
        Positioned(
          top: 200.0,
          right: 0.0,
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
      ],
    );
  }
}
