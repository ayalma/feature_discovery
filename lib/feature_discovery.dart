library feature_discovery;

// The library files (foundation.dart, widgets.dart, etc.) are in src
// because they should not appear for code completion because the
// members that should be exposed when using the package are exposed here.
export 'src/widgets.dart'
    show
        DescribedFeatureOverlay,
        OverflowMode,
        EnsureVisible,
        EnsureVisibleState;
export 'src/foundation.dart' show FeatureDiscovery, ContentOrientation;
