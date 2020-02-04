import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widgets.dart';

List<String> textsToMatch(List<String> featureIds) {
  assert(featureIds != null);
  return featureIds
      .map((featureId) => 'Test has passed for $featureId')
      .toList();
}

void main() {
  group('Basic behavior', () {
    const steps = <String>[
      'featureIdA',
      'featureIdB',
      'featureIdC',
      'featureIdD',
    ];
    final List<String> texts = textsToMatch(steps);
    testWidgets('Displaying two steps and dismissing before the third',
        (WidgetTester tester) async {
      await tester.pumpWidget(const TestWidget(featureIds: steps));
      final Finder finder = find.byType(TestIcon);
      expect(finder, findsNWidgets(steps.length));
      final BuildContext context = tester.firstState(finder).context;
      // Should be no overlays before calling discoverFeatures
      texts.forEach((t) => expect(find.text(t), findsNothing));
      FeatureDiscovery.discoverFeatures(context, steps);
      await tester.pumpAndSettle();
      // First overlay should appear
      expect(find.text(texts[0]), findsOneWidget);
      // Test with a tap on the target
      await tester.tap(finder.first);
      await tester.pumpAndSettle();
      // First overlay should have disappeared, and second appeared
      expect(find.text(texts[0]), findsNothing);
      expect(find.text(texts[1]), findsOneWidget);
      // Test with [completeCurrentStep]
      FeatureDiscovery.completeCurrentStep(context);
      await tester.pumpAndSettle();
      expect(find.text(texts[1]), findsNothing);
      expect(find.text(texts[2]), findsOneWidget);
      // Dismiss all
      FeatureDiscovery.dismissAll(context);
      await tester.pumpAndSettle();
      // No overlay should remain
      texts.forEach((t) => expect(find.text(t), findsNothing));
    });
  });

  group('Non-existent feature ids', () {
    const featureIds = <String>['featA', 'featB', 'featC'];
    final texts = textsToMatch(featureIds);
    testWidgets(
        "Calling [discoverFeatures] with two ids that aren't associated with an overlay",
        (WidgetTester tester) async {
      await tester.pumpWidget(TestWidget(
          // Only one overlay will be placed in the tree
          featureIds: featureIds.sublist(1, 2)));
      final Finder finder = find.byType(TestIcon);
      expect(finder, findsOneWidget);
      final BuildContext context = tester.firstState(finder).context;
      FeatureDiscovery.discoverFeatures(context, featureIds);
      await tester.pumpAndSettle();
      // First overlay should NOT appear
      expect(find.text(texts[0]), findsNothing);
      FeatureDiscovery.completeCurrentStep(context);
      await tester.pumpAndSettle();
      // Second overlay should appear
      expect(find.text(texts[1]), findsOneWidget);
      FeatureDiscovery.completeCurrentStep(context);
      await tester.pumpAndSettle();
      // No overlay should remain on screen
      texts.forEach((t) => expect(find.text(t), findsNothing));
    });
  });

  group('Duplicate feature ids', () {
    for (final bool allowShowingDuplicate in <bool>[true, false]) {
      const featureIds = <String>[
        'featureIdA',
        'featureIdB',
        'featureIdB',
        'featureIdC',
      ],
          steps = <String>[
        'featureIdA',
        'featureIdB',
        'featureIdC',
      ];

      final texts = textsToMatch(steps);

      testWidgets('allowShowingDuplicate == $allowShowingDuplicate',
          (WidgetTester tester) async {
        await tester.pumpWidget(TestWidget(
          featureIds: featureIds,
          allowShowingDuplicate: allowShowingDuplicate,
        ));

        final Finder finder = find.byType(TestIcon);
        expect(finder, findsNWidgets(featureIds.length));
        final BuildContext context = tester.firstState(finder).context;
        texts.forEach((t) => expect(find.text(t), findsNothing));

        FeatureDiscovery.discoverFeatures(context, steps);
        await tester.pumpAndSettle();
        // First overlay should appear.
        expect(find.text(texts[0]), findsOneWidget);

        FeatureDiscovery.completeCurrentStep(context);
        await tester.pumpAndSettle();
        // First overlay should have disappeared, and either both
        // overlay 2 and 3 should be displayed or just one of them
        // depending on allowShowingDuplicate.
        expect(find.text(texts[0]), findsNothing);
        expect(find.text(texts[1]),
            allowShowingDuplicate ? findsNWidgets(2) : findsOneWidget);

        FeatureDiscovery.completeCurrentStep(context);
        await tester.pumpAndSettle();
        // Overlays 2 and 3 should have disappeared, and the last overlay should appear.
        expect(find.text(texts[1]), findsNothing);
        expect(find.text(texts[2]), findsOneWidget);
      });
    }

    testWidgets('Show other overlay after duplicate has been removed',
        (WidgetTester tester) async {
      const String featureId = 'feature';
      const IconData featureIcon = Icons.content_copy;
      const String staticFeatureTitle = 'Static',
          disposableFeatureTitle = 'Disposable';

      await tester.pumpWidget(const WidgetWithDisposableFeature(
        featureId: featureId,
        featureIcon: featureIcon,
        staticFeatureTitle: staticFeatureTitle,
        disposableFeatureTitle: disposableFeatureTitle,
      ));

      final Finder stateFinder = find.byType(WidgetWithDisposableFeature);
      expect(stateFinder, findsOneWidget);
      final WidgetWithDisposableFeatureState state =
          tester.firstState(stateFinder);

      // Need some widget to return a context that has the Bloc widget as an ancestor.
      final Finder overlayFinder = find.byType(DescribedFeatureOverlay);
      final BuildContext context = tester.firstState(overlayFinder).context;

      // Feature titles should only be visible once feature discovery has been started.
      expect(find.text(staticFeatureTitle), findsNothing);
      expect(find.text(disposableFeatureTitle), findsNothing);

      FeatureDiscovery.discoverFeatures(context, <String>[featureId]);
      await tester.pumpAndSettle();

      // Only one of the overlays should be displayed as allowShowingDuplicate is false.
      expect(find.byIcon(featureIcon), findsOneWidget);
      // That overlay should be the disposable one because that one receives the Bloc event first.
      // The reason that should happen is because the disposable widget is first in the Column children list.
      //
      // "Disposable widget" here is referring to the widget that is shown based on the _showDisposableFeature
      // flag in WidgetWithDisposableFeatureState and has the disposableFeatureTitle.
      expect(find.text(disposableFeatureTitle), findsOneWidget);
      expect(find.text(staticFeatureTitle), findsNothing);

      // The disposable feature will now be disposed, which should show the static feature.
      state.disposeFeature();
      await tester.pumpAndSettle();

      expect(find.text(disposableFeatureTitle), findsNothing);
      expect(find.text(staticFeatureTitle), findsOneWidget);
    });
  });

  group('OverflowMode', () {
    const IconData icon = Icons.error;
    const String featureId = 'feature';

    // Declares what OverflowMode's should allow the button to be tapped.
    const Map<OverflowMode, bool> modes = <OverflowMode, bool>{
      OverflowMode.ignore: false,
      OverflowMode.extendBackground: false,
      OverflowMode.wrapBackground: false,
      OverflowMode.clipContent: true,
    };

    for (final MapEntry<OverflowMode, bool> modeEntry in modes.entries) {
      testWidgets(modeEntry.key.toString(), (WidgetTester tester) async {
        BuildContext context;

        bool triggered = false;

        // The surface size is set to ensure that the minimum overlay background size
        // does not cover the button, but the content does.
        // The values here are somewhat arbitrary, but the main focus is ensuring that
        // the minimum value (3e2 width in this case) is a lot smaller than the maximum value (4e3 height)
        // because the background will use the minimum screen dimension as its radius and the icon needs
        // to be outside of the background area because that would cover the icon for every entry mode.
        //
        // The Container that makes the content of the feature overlay of the test widget has a static
        // height of 9e3, which ensures that the content definitely covers the 4e3 surface size height
        // if OverflowMode.clipContent is not enabled.
        await (TestWidgetsFlutterBinding.ensureInitialized()
                as TestWidgetsFlutterBinding)
            .setSurfaceSize(const Size(3e2, 4e3));

        await tester.pumpWidget(
          OverflowingDescriptionFeature(
            // This will be called when the content does not cover the icon.
            onDismiss: () {
              triggered = true;
            },
            onContext: (builderContext) => context = builderContext,
            featureId: featureId,
            icon: icon,
            mode: modeEntry.key,
          ),
        );

        FeatureDiscovery.discoverFeatures(context, <String>[featureId]);
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(icon));
        expect(triggered, modeEntry.value);
      });
    }
  });
}
