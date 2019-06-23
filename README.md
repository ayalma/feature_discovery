# feature_discovery

A flutter package that implements material design feature discovery 

## Installing


For installing this lib add below line to you'r dependency section in pubspec.yaml
```
    dependencies:
      feature_discovery: ^0.4.1

```

Then run  ```flutter pub get``` to retrieve package


## Using

For using this library first add featureDiscovery to material app builder property like that
```
return MaterialApp(
      title: 'Feature Discavery',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      builder: (context, child) {
        return FeatureDiscovery( // adding feature discovery at this point make it available to all pages
          child: child,
        );
      },
      home: MyHomePage(title: 'Flutter Feature Discavery'),
    );

```

### Note :
 Adding feature discovery at this point make it available to all pages
 
Then wrap you'r desired widget with ```DescribedFeatureOverlay``` widget
like that :
```
   DescribedFeatureOverlay(
                featureId: 'featureId1',
                icon: Icons.print,
                color: Colors.purple,
                contentLocation: ContentOrientation.below, // look at note 
                title: 'Just how you want it',
                description:
                    'Tap the menu icon to switch account, change setting & more.Tap the menu icon to switch account, change setting & more.',
                child: IconButton(
                  icon: Icon(Icons.print),
                ),
              ),
``` 

Then in initState method of you'r widget call 


``` 
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FeatureDiscovery.discoverFeatures(
        context,
        ['featureId1'],
      );
    });

```
### Note 

#### contentLocation :
   we use this property for placing the content text in proper position when 
    lib can't do it (because of text width and height measurement  issue in flutter )
    
   ContentOrientation.below : move content to  below of target
   ContentOrientation.above : move content to above of target
   ContentOrientation.trivial : let lib decide
    
## Bonus 

   When you'r desired target is in scrollable content and is hidden when the feature discovery runs
    you can use ```EnsureVisible``` widget like that
    
   ```
       var  ensureKey2 = GlobalKey<EnsureVisibleState>();
       DescribedFeatureOverlay(
                    featureId: 'id',
                    icon: Icons.drive_eta,
                    color: Colors.green,
                    doAction: (f) {
                      // do what you want ...
                      f();
                    },
                    prepareAction: (done) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        ensureKey2.currentState.ensureVisible(); // this line scroll to target before feature discovery 
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
    
   ```
## Thank you [mattcarroll](https://medium.com/@mattcarroll) for you'r awesome video about feature discovery
 

This project is a starting point for a Dart
[package](https://flutter.dev/developing-packages/),
a library module containing code that can be shared easily across
multiple Flutter or Dart projects.

For help getting started with Flutter, view our 
[online documentation](https://flutter.dev/docs), which offers tutorials, 
samples, guidance on mobile development, and a full API reference.
