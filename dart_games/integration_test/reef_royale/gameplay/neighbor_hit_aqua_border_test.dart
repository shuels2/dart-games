import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 19: Neighbor hit shows aqua border',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    await setupAndStartGame(tester, config, neighborNumbers: true);

    // Neighbors badge should be visible in appbar
    expect(find.byKey(ReefRoyaleGameKeys.neighborsBadge), findsOneWidget);

    // Throw 1 (neighbor of 20 on dartboard) -> resolves to target 20, neighbor hit -> aqua
    await throwDartViaMock(tester, 1);
    verifyDartIndicatorColor(tester, ReefRoyaleGameKeys.dartIndicator(0), 0xFF00CED1);

    // D2: Direct hit on 20 -> green
    await throwDartViaMock(tester, 20);
    verifyDartIndicatorColor(tester, ReefRoyaleGameKeys.dartIndicator(1), 0xFF48D1CC);

    // D3: Non-target number (9, not neighbor of any target: 9's neighbors are 14 and 12) -> pink
    await throwDartViaMock(tester, 9);
    verifyDartIndicatorColor(tester, ReefRoyaleGameKeys.dartIndicator(2), 0x80FF6B6B);
  });
}
