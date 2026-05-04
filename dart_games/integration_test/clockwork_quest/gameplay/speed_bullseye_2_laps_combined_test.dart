import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test 30: Speed mode + bullseye + 2 laps - all options combined',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        speedMode: true, includeBullseye: true, laps: 2);

    final provider = ProviderHelpers.getClockworkQuestProvider(tester);
    final playerId = provider.getCurrentPlayerId()!;

    expect(provider.currentGame!.speedMode, isTrue);
    expect(provider.currentGame!.includeBullseye, isTrue);
    expect(provider.currentGame!.numberOfLaps, 2);
    expect(provider.currentGame!.maxTarget, 21);

    // Activate all 20 numbered gears
    for (int i = 1; i <= 20; i++) {
      provider.currentGame!.completedTargets[playerId]!.add(i);
    }
    provider.currentGame!.currentTarget[playerId] = 21;

    // Hit bullseye to complete first lap
    await throwBullseyeViaMock(tester);
    await clickDartsRemoved(tester);

    expect(provider.getPlayerLapsCompleted(playerId), 1);
    expect(provider.hasWinner, isFalse);

    // Activate all gears again for second lap
    for (int i = 1; i <= 20; i++) {
      provider.currentGame!.completedTargets[playerId]!.add(i);
    }
    provider.currentGame!.currentTarget[playerId] = 21;

    await throwBullseyeViaMock(tester);
    await clickDartsRemoved(tester);

    expect(provider.hasWinner, isTrue);
  });
}
