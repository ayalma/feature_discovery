import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widgets.dart';

List<String> textsToMatch(List<String> featureIds) {
  assert(featureIds != null);
  return featureIds.map((featureId) => 'Test has passed for $featureId').toList();
}

void main() {
  group('Basic behavior', () {
    const List<String> steps = [
      'featureIdA',
      'featureIdB',
      'featureIdC',
      'featureIdD',
    ];
    final List<String> texts = textsToMatch(steps);
    testWidgets('Displaying two steps and dismissing before the third', (WidgetTester tester) async {
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
      FeatureDiscovery.dismiss(context);
      await tester.pumpAndSettle();
      // No overlay should remain
      texts.forEach((t) => expect(find.text(t), findsNothing));
    });
  });

  group('Non-existent featureIds', () {
    const List<String> featureIds = ['featA', 'featB', 'featC'];
    final List<String> texts = textsToMatch(featureIds);
    testWidgets("Calling [discoverFeatures] with two ids that aren't associated with an overlay", (WidgetTester tester) async {
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

  group('Duplicate featureIds', () {
    const List<String> featureIds = [
      'featureIdA',
      'featureIdB',
      'featureIdB',
      'featureIdC',
    ];
    const List<String> steps = [
      'featureIdA',
      'featureIdB',
      'featureIdC',
    ];
    final List<String> texts = textsToMatch(steps);
    testWidgets('Two overlays have the same featureId', (WidgetTester tester) async {
      await tester.pumpWidget(const TestWidget(featureIds: featureIds));
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
      // First overlay should have disappeared, and overlays 2 and 3 should be displayed.
      expect(find.text(texts[0]), findsNothing);
      expect(find.text(texts[1]), findsNWidgets(2));
      FeatureDiscovery.completeCurrentStep(context);
      await tester.pumpAndSettle();
      // Overlays 2 and 3 should have disappeared, and the last overlay should appear.
      expect(find.text(texts[1]), findsNothing);
      expect(find.text(texts[2]), findsOneWidget);
    });
  });

  group('OverflowMode', () {
    throw UnimplementedError('@creativecreatorormaybenot');
  });
}
