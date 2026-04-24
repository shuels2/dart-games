import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 27: Skip turn shows Skip in dart indicators',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config);

    // Throw 1 dart first
    await throwDartViaMock(tester, 20);

    // Hide dartboard emulator so skip button is not obscured
    await tester.tap(find.byKey(DartboardEmulatorKeys.toggleFAB));
    await tester.pump();
    await tester.pump();

    // Skip remaining darts
    await UITestHelpers.clickSkipTurn(tester, config);

    // Verify all 3 dart indicators exist
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
    expect(d0Text.data, 's20'); // First dart was inner single (lowercase s)

    final d1Container = tester.widget<Container>(d1Finder);
    final d1Center = d1Container.child as Center;
    final d1Column = d1Center.child as Column;
    final d1Text = d1Column.children.first as Text;
    expect(d1Text.data, 'Skip'); // Second dart was skipped

    final d2Container = tester.widget<Container>(d2Finder);
    final d2Center = d2Container.child as Center;
    final d2Column = d2Center.child as Column;
    final d2Text = d2Column.children.first as Text;
    expect(d2Text.data, 'Skip'); // Third dart was skipped
  });
}
