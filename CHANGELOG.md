# Changelog
## 0.14.1
* Updated Provider version

## 0.14.0
* Migrated to null safety

## 0.13.0+1
* Clear Preferences issue fixed
## 0.13.0

* Introduce a PersistenceProvider interface for storing step completion in any mechanism the user wants.
* Fully backward compatible, no need to change your code.
* All historic steps are honored and will not show again, just as you’d expect.

## 0.12.0+2

* Fixes FeatureDiscovery position issue

## 0.12.0+1

* Fixes a null pointer exception.

## 0.12.0

* **Breaking change:** `isDisplayed` is replaced by `hasPreviouslyCompleted`.
* **Fix:** the `onComplete` returned value will no longer be ignored, and the next overlay won't show if this function returns `false`.
* `FeatureDiscovery.completeCurrentStep` will force complete the current step and not execute the `onComplete` function.
* Deprecated methods in `FeatureDiscovery` have been removed.
* New parameter `recordStepsInSharedPreferences` in `FeatureDiscovery` to prevent step completions to be recorded in Shared Preferences.
* New parameter `sharedPreferencesPrefix` in `FeatureDiscovery`.

## 0.11.0

* Added `FeatureDiscovery.backgroundOpacity` in order to customize overlay background opacity when it is displayed.
  `backgroundOpacity` is optional. If ignored, the default value is 0.96.

## 0.10.0

* Added `FeatureDiscovery.isDisplayed` method to check status of feature
* Added Feature/animation durations customization
* Added `openDuration` flag that controls open animation duration.
* Added `pulseDuration` flag that controls tap target pulse animation duration.
* Added `completeDuration` flag that controls complete animation duration.
* Added `dismissDuration` flag that controls dismiss animation duration.

## 0.9.0

* Added `barrierDismissible` flag which decides whether the overlay should dismiss
  on touching outside or not.

## 0.8.0

* **Breaking change:**  `FeatureDiscovery.completeCurrentStep` is async now.
* Added preferences for each feature to show is understood by user or not
* Library will not show understood feature
* Added method for reset all preferences of features `FeatureDiscovery.clearPreferences`

## 0.7.0

* **Breaking change:** removed deprecated static methods in `FeatureDiscovery`.
* **Breaking change:** removed deprecated parameters in the `EnsureVisible` constructor.
* **Breaking change:** overlays will always be dismissed when calling `FeatureDiscovery.dismissAll`.
* *Deprecated* `activeFeatureId`; replaced by `currentFeatureIdOf` to emphasize that this is a getter.
* *Deprecated* `FeatureDiscovery.dismiss`; replaced by `dismissAll` to indicate that no next step
  will be shown.
* Added `assert` to require at least one step to be passed to `FeatureDiscovery.discoverFeatures`.
* Incorrect documentation of some static methods in `FeatureDiscovery` has been updated.
* Error messages have been improved : the error thrown when the widget tree isn't wrapped in
  a `FeatureDiscovery` widget is clearer.
* Incorrect behavior when `onDismiss` returned `Future<false>` has been fixed.

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
