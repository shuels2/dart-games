import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Edit Score: editing winning dart to non-winning removes winner',
      (tester) async {
    await UITestHelpers.resetServerState();
    // Target=100, DF OFF
    await setupAndStartGame(
      tester,
      config,
      targetScore: 100,
      doubleFinishEnabled: false,
      playerNames: ['Player A', 'Player B'],
    );

    final p1Id =
        ProviderHelpers.getGladiatorArenaCurrentPlayerId(tester)!;

    // Get P1 to 80: Turn1=60, Turn2=20
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await clickDartsRemoved(tester);

    await completeTurnWithMisses(tester);

    await throwDartViaMock(tester, 20);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    await completeTurnWithMisses(tester);

    // P1 at 80. Throw winning: Miss + Miss + D10 = 20 → 100 WIN
    await throwMissViaMock(tester); // dart 1
    await throwMissViaMock(tester); // dart 2
    await throwDartViaMock(tester, 10, multiplier: 'double'); // D10 = 20 → WIN

    // Before darts removed, edit dart 3 to S1 (non-winning)
    await openEditScore(tester, config);
    await setDart3(tester, 'S1'); // 80 + 0 + 0 + 1 = 81, not a win
    await updateScore(tester);

    // Now the game should not have a winner
    expect(ProviderHelpers.gladiatorArenaHasWinner(tester), isFalse,
        reason: 'Game should not have winner after editing winning dart away');
    expect(ProviderHelpers.isGladiatorArenaGameActive(tester), isTrue,
        reason: 'Game should still be active');

    // Stats should not have been recorded
    final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A');
    final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B');
    expect(playerA?.gamesPlayed ?? 0, 0,
        reason: 'Stats should not be recorded when winner is removed');
    expect(playerB?.gamesPlayed ?? 0, 0,
        reason: 'Stats should not be recorded when winner is removed');

    // Click darts removed to continue
    await clickDartsRemoved(tester);

    // Should still be on game screen
    expect(ElementFinders.getGladiatorArenaSkipTurnButton(), findsOneWidget);
  });
}
