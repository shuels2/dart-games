import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../../shared/ui_test_helpers.dart';
import '../../shared/edit_score_helpers.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Edit Score: winning turn edited to remove winner does not update stats',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        targetScore: 100, playerNames: ['Player A', 'Player B']);

    // Throw T20 + T20 + S20 = 60 + 60 + 20 = 140 pts (wins)
    await throwDartViaMock(tester, 20, multiplier: 'triple');
    await throwDartViaMock(tester, 20, multiplier: 'triple');
    await throwDartViaMock(tester, 20);

    expect(ProviderHelpers.carnivalDerbyHasWinner(tester), isTrue);

    // Edit to remove win: D5 + D5 + D5 = 30 pts (below 100, no win)
    // Use Double to avoid CD's scoreDisplayTransform conflict: D5 shows
    // "10" in the score box while the number button shows "5" — unique match.
    // Single values conflict because S5 shows "5" in both score box and button.
    await EditScoreHelpers.editScoreAndSave(tester, config,
        dart1: 'D5', dart2: 'D5', dart3: 'D5');

    expect(ProviderHelpers.carnivalDerbyHasWinner(tester), isFalse);

    await clickDartsRemoved(tester);

    // Game should continue
    expect(ProviderHelpers.isCarnivalDerbyGameActive(tester), isTrue);

    // Neither player should have stats updated
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
