# Changelog

## 0.7.0

* **Breaking changes:**
  * Deprecated static methods of `FeatureDiscovery` class have been removed.
  * Deprecated paramaters in the constructor of `EnsureVisible` have been removed.
* **Deprecations:**
  * `activeFeatureId` has been deprecated and replaced by `currentFeatureIdOf`, to emphasize that this is a getter.
  * `dismiss` has been deprecated and replaced by `dismissAll` to be clear on the fact that no next step will be shown.

## 0.6.1

* Update version constraint to `^4.0.1` for `provider` dependency.

## 0.6.0

* **Breaking change**: Renamed `ContentOrientation` to `ContentLocation`.
* **Breaking change**: Made `onComplete` of type `Future<bool> Function()` to match `onOpen`
  and `onDismiss`.
* Methods `completeStep` and `markStepComplete` have been deprecated
  and `completeCurrentStep` should now be used.
* Method `clear` is deprecated and `dismiss` should now be used.
* Added an `OverflowMode` enum and the `overflowMode` parameter to `DescribedFeatureOverlay`
  to control how the overlay should handle content that exceeds the background's boundaries.
* Added `FeatureDiscovery.activeFeatureId`, which allows you to get the feature id of the
  current feature discovery step.
* Added `duration`, `curve`, and `preciseAligment` parameters to `EnsureVisibleState.ensureVisible`.
* Deprecated `EnsureVisible.duration` and `EnsureVisible.curve` as parameters because they should
  be passed when calling `EnsureVisibleState.ensureVisible`. This is not a breaking change.
* Made the return type of `EnsureVisibleState.ensureVisible` be `Future<void>`. This is not
  a breaking change because the previous return type was `void`, which you cannot work with.
* Made the `enablePulsingAnimation` respond to rebuilds, allowing to change it
  after the overlay has been shown.
* Added GIF demo of the package to the `README.md` file of the package and the example.
* Updated example.
* Added `OverflowMode` to `README.md`.
* Added `CONTRIBUTING.md` and mentioned it in `README.md`.

## 0.5.0

* **Breaking change**: Instead of the `icon` parameter, you now need to use the `tapTarget`
  parameter, which takes a `Widget` instead of `IconData`.
  Before: `DescribedFeatureOverlay(icon: Icons.add, ..)`
  After: `DescribedFeatureOverlay(tapTarget: const Icon(Icons.add), ..)`
* **Breaking change**: `title` and `description` parameters now take a `Widget`.
* **Breaking change**: Callbacks are now `onOpen`, `onDismiss`, and `onComplete`.
  `onOpen` and `onDismiss` need to return `Future<bool>` when specified to decide
  if the step should be open or dismissed respectively.
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
