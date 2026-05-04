import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/edit_score_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Edit score removes winner and stats are NOT updated',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        includeBullseye: true, playerNames: ['Player A', 'Player B']);

    final playerId =
        ProviderHelpers.getClockworkQuestCurrentPlayerId(tester)!;
    final provider = ProviderHelpers.getClockworkQuestProvider(tester);

    // Programmatically set player to target 21 (bullseye)
    provider.currentGame!.currentTarget[playerId] = 21;
    provider.currentGame!.turnStartCurrentTarget[playerId] = 21;
    provider.currentGame!.turnStartLapsCompleted[playerId] = 0;
    provider.currentGame!.turnStartState = provider.currentGame!.state;
    provider.currentGame!.turnStartWinnerId = null;
    provider.currentGame!.turnStartCompletedTargets[playerId] = [];
    provider.notifyListeners();
    await PumpSequences.simpleUpdate(tester);

    // Throw Bull (winning) + 2 misses
    await throwBullseyeViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    // Should be a winner after hitting bullseye
    expect(provider.hasWinner, isTrue);

    // Edit: change dart 1 to S1 (gear 1 already completed, won't advance) — should remove winner
    await EditScoreHelpers.editScoreAndSave(tester, config, dart1: 'S1');
    expect(provider.hasWinner, isFalse);

    // Confirm darts removed
    await clickDartsRemoved(tester);

    // Verify game continues (not on results screen)
    expect(ProviderHelpers.isClockworkQuestGameActive(tester), isTrue);

    // Verify stats NOT updated — no game recorded
    final playerA = ProviderHelpers.findPlayerByName(tester, 'Player A');
    expect(playerA, isNotNull);
    expect(playerA!.gamesPlayed, 0);
    expect(playerA.gamesWon, 0);
    expect(playerA.gameHistory.isEmpty, isTrue);

    final playerB = ProviderHelpers.findPlayerByName(tester, 'Player B');
    expect(playerB, isNotNull);
    expect(playerB!.gamesPlayed, 0);
    expect(playerB.gamesWon, 0);
    expect(playerB.gameHistory.isEmpty, isTrue);
  });
}
