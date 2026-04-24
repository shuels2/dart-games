import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 10: Gear widgets transition from inactive to active',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config);

    // Gear 1 starts as inactive (current target, not yet hit)
    expect(find.byKey(ClockworkQuestGameKeys.gear(1)), findsOneWidget);
    expect(find.byKey(ClockworkQuestGameKeys.gearActive(1)), findsNothing);

    // Hit target 1 to activate it
    await throwDartViaMock(tester, 1);

    // Gear 1 should now be active (key changes from gear(1) to gearActive(1))
    expect(find.byKey(ClockworkQuestGameKeys.gearActive(1)), findsOneWidget);
    expect(find.byKey(ClockworkQuestGameKeys.gear(1)), findsNothing);

    // Gear 2 should now be visible as inactive (next target)
    expect(find.byKey(ClockworkQuestGameKeys.gear(2)), findsOneWidget);
    expect(find.byKey(ClockworkQuestGameKeys.gearActive(2)), findsNothing);

    // Hit target 2 to activate it
    await throwDartViaMock(tester, 2);

    // Gear 2 should now be active
    expect(find.byKey(ClockworkQuestGameKeys.gearActive(2)), findsOneWidget);
    expect(find.byKey(ClockworkQuestGameKeys.gear(2)), findsNothing);

    // Gear 1 should still be active
    expect(find.byKey(ClockworkQuestGameKeys.gearActive(1)), findsOneWidget);
  });
}
