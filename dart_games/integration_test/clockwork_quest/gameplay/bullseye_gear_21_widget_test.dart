import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 18: Bullseye ON - gear 21 widget shown as inactive',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config, includeBullseye: true);

    // The bullseye gear (gear 21) should be on screen as inactive
    expect(find.byKey(ClockworkQuestGameKeys.gear(21)), findsOneWidget);
    expect(find.byKey(ClockworkQuestGameKeys.gearActive(21)), findsNothing);

    // Set player to target 21 and hit bullseye
    final provider = ProviderHelpers.getClockworkQuestProvider(tester);
    final playerId = provider.getCurrentPlayerId()!;
    provider.currentGame!.currentTarget[playerId] = 21;
    // Mark gears 1-20 as completed so gear 21 is the current target
    for (int i = 1; i <= 20; i++) {
      provider.currentGame!.completedTargets[playerId]!.add(i);
    }
    provider.notifyListeners();
    await PumpSequences.simpleUpdate(tester);

    await throwBullseyeViaMock(tester);

    // Hitting gear 21 completes the game (last target in single lap)
    expect(provider.hasWinner, isTrue);
  });
}
