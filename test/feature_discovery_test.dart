import 'package:feature_discovery/feature_discovery.dart';
import 'package:flutter_test/flutter_test.dart';

import 'widgets.dart';

void main() {
  group("Logic", () {
    const List<String> steps = [
      "featureIdA", 
      "featureIdB",
      "featureIdC"
    ];
    final List<String> textsToMatch = steps
      .map((featureId) => 'Test has passed for $featureId')
      .toList();
    testWidgets(
      "Displaying two steps and dismissing before the third", 
      (WidgetTester tester) async {
        await tester.pumpWidget(TestWidget(steps: steps));
        final Finder finder = find.byType(TestIcon);
        expect(finder, findsNWidgets(steps.length));
        final Iterable<TestIconState> states = tester.stateList<TestIconState>(finder);
        FeatureDiscovery.discoverFeatures(states.first.context, steps);
        await tester.pumpAndSettle();
        expect(find.text(textsToMatch[0]), findsOneWidget);
        await tester.tap(finder.first);
        await tester.pumpAndSettle();
        expect(find.text(textsToMatch[0]), findsNothing);
        expect(find.text(textsToMatch[1]), findsOneWidget);
        FeatureDiscovery.dismiss(states.first.context);
        await tester.pumpAndSettle();
        expect(find.text(textsToMatch[1]), findsNothing);
        expect(find.text(textsToMatch[2]), findsNothing);
      }
    );
  });
}