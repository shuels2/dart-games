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
        playerNames: ['Player A', 'Player B']);

    final playerId =
        ProviderHelpers.getLunarLanderCurrentPlayerId(tester)!;
    final provider = ProviderHelpers.getLunarLanderProvider(tester);

    // Programmatically set altitude low so a single S10 can win
    provider.currentGame!.currentAltitudes[playerId] = 10;
    provider.currentGame!.turnStartAltitude[playerId] = 10;
    provider.currentGame!.turnStartState = provider.currentGame!.state;
    provider.currentGame!.turnStartWinnerId = null;
    provider.notifyListeners();
    await PumpSequences.simpleUpdate(tester);

    // Throw S10 (winning — altitude 10 - 10 = 0) + 2 misses
    await throwDartViaMock(tester, 10);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);

    // Should be a winner after hitting S10
    expect(ProviderHelpers.lunarLanderHasWinner(tester), isTrue);

    // Edit: change dart 1 to Miss — should remove winner
    await openEditScore(tester);
    await EditScoreHelpers.setDart1(tester, 'Miss');
    await updateScore(tester);

    expect(ProviderHelpers.lunarLanderHasWinner(tester), isFalse);

    // Confirm darts removed
    await clickDartsRemoved(tester);

    // Verify game continues (not on results screen)
    expect(ProviderHelpers.isLunarLanderGameActive(tester), isTrue);

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
