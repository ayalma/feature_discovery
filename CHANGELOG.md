## 0.5.0

* Fixed `DescribedFeatureOverlay`'s constantly rebuilding even if they were never displayed.
* Fixed `DescribedFeatureOverlay`'s rebuilding after dismissing them.
* **Warning**: `Theme.of(context)` is now used to determine text styles
* Title and description can now be null.
* Added option to disable pulsing animation.
* Added parameter that is called when the overlay is dismissed.
* Added parameters to change text color, target color, and icon color.
* Added possibility to pass any `Iterable` for the steps to `FeatureDiscovery.discoverFeatures`.
* Added the `@required` annotation to parameters that cannot be null.
* Ensured that overlay for each step is only shown once at a time.
* Removed unnecessary files.
* Formatted files.
* Updated the plugin description.

## 0.4.1

* Fixed animation bugs.

## 0.4.0

* Added `ContentOrientation`.

## 0.3.0

* Consider landscape and portrait orientation in `DescribedFeatureDiscoveryWidget`.

## 0.2.0

* Add `EnsureVisible` widget to scroll to target when it is in a scrollable container.

## 0.1.1

* Applied Pub health suggestions.

## 0.1.0

* Applied Pub health suggestions.

## 0.0.1

* Initial release.
