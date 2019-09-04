# feature_discovery

A flutter package that implements material design feature discovery 

## Installing

For installing this package add below line to you'r dependency section in pubspec.yaml
```
dependencies:
  feature_discovery: ^0.5.0
```

Then run ```flutter pub get``` to retrieve package

## Using

This works like an inherited widget. 
Wrap the part of your app that uses ```DescribedFeatureOverlay``` widgets with a ```FeatureDiscovery``` widget:
```
return MaterialApp(
  title: 'Feature Discovery example app',
  theme: ThemeData(primarySwatch: Colors.blue),
  builder: (context, child) {
    return FeatureDiscovery( // adding feature discovery at this point make it available to all pages
      child: child,
    );
  },
  home: MyHomePage(title: 'Flutter Feature Discovery'),
);
```

Then wrap the widgets whose feature you want to prompt with a ```DescribedFeatureOverlay``` widget:
```
final Future<void> Function() onPressed = () async => print("IconButton pressed !");
const Icon icon = Icon(Icons.menu);
DescribedFeatureOverlay(
  featureId: 'featureId1', // unique id that identifies this overlay
  tapTarget: icon,
  title: 'Just how you want it',
  description: Text('Tap the menu icon to switch accounts, change settings & more.'),
  onTargetTap: onPressed // action executed when the user taps the icon
  onOpen: () async { // action executed just before the overlay appears
    print("The overlay is about to be displayed");
    return true;
  },
  child: IconButton( // The actual widget that is in your interface
    icon: icon,
    onPressed: onPressed
  ),
);
``` 

When you want to display the feature overlay, call:


``` 
FeatureDiscovery.discoverFeatures(
  context,
  const {'featureId1'}, // ids of your different overlays
);
```

### Note 

#### contentLocation :
we use this property for placing the text in proper position when lib can't do it (because of text width and height measurement issue in flutter )
  
ContentOrientation.below: move text under the target
ContentOrientation.above: move text above the target
ContentOrientation.trivial: let lib decide
    
## Bonus 

When you'r desired target is in scrollable content and is hidden when the feature discovery runs you can use ```EnsureVisible``` widget like that
    
```
GlobalKey<EnsureVisibleState> ensureKey2 = GlobalKey<EnsureVisibleState>();
DescribedFeatureOverlay(
  featureId: 'id',
  tapTarget: const Icon(Icons.drive_eta),
  onOpen: () async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ensureKey2.currentState.ensureVisible();
      return true;
    });
  },
  title: 'Test text',
  description: Text('This text is just for test and we dont care about it at all.'),
  child: EnsureVisible(
    key: ensureKey2,
    child: Text(
      'Custom text',
    ),
  ),
);
```

## Thank you [mattcarroll](https://medium.com/@mattcarroll) for your awesome video about feature discovery
