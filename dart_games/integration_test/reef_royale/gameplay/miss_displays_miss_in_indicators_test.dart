import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 28: Miss displays Miss in dart indicators',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config);

    // Throw a complete miss (bounceout)
    await throwMissViaMock(tester);

    // Throw a valid target hit
    await throwDartViaMock(tester, 20);

    // Throw another miss
    await throwMissViaMock(tester);

    // Verify dart indicators
    final d0Finder = find.byKey(ReefRoyaleGameKeys.dartIndicator(0));
    final d1Finder = find.byKey(ReefRoyaleGameKeys.dartIndicator(1));
    final d2Finder = find.byKey(ReefRoyaleGameKeys.dartIndicator(2));
    expect(d0Finder, findsOneWidget);
    expect(d1Finder, findsOneWidget);
    expect(d2Finder, findsOneWidget);

    // Extract text from dart indicators (Container > Center > Column > Text)
    final d0Container = tester.widget<Container>(d0Finder);
    final d0Center = d0Container.child as Center;
    final d0Column = d0Center.child as Column;
    final d0Text = d0Column.children.first as Text;
    expect(d0Text.data, 'Miss'); // Bounceout shows Miss

    final d1Container = tester.widget<Container>(d1Finder);
    final d1Center = d1Container.child as Center;
    final d1Column = d1Center.child as Column;
    final d1Text = d1Column.children.first as Text;
    expect(d1Text.data, 's20'); // Valid target shows sector (inner single)

    final d2Container = tester.widget<Container>(d2Finder);
    final d2Center = d2Container.child as Center;
    final d2Column = d2Center.child as Column;
    final d2Text = d2Column.children.first as Text;
    expect(d2Text.data, 'Miss'); // Second bounceout shows Miss
  });
}
