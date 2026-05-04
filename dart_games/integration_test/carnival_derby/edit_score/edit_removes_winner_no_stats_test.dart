import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import '../../shared/ui_test_helpers.dart';
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

    // Edit to remove win: S1 + S1 + S1 = 3 pts (no win)
    // Use CD-specific helpers to avoid ring-button layout ambiguity
    await openEditScore(tester);
    await setDartInEditScore(tester, 0, 'Single (outer)', number: 1); // D1: T20 -> S1
    await setDartInEditScore(tester, 1, 'Single (outer)', number: 1); // D2: T20 -> S1
    await setDartInEditScore(tester, 2, 'Single (outer)', number: 1); // D3: S20 -> S1
    await updateScore(tester);

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
