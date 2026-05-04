import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/services/victory_music_service.dart';
import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/provider_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Edit Score: non-winning turn edited to create winner updates stats',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        targetScore: 100, playerNames: ['Player A', 'Player B']);

    // Throw S20 + S20 + S20 = 60 pts (no win)
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);
    await throwDartViaMock(tester, 20);

    expect(ProviderHelpers.carnivalDerbyHasWinner(tester), isFalse);

    // Edit to win: T20 + T20 + S20 = 60 + 60 + 20 = 140, >= 100 wins
    // Use CD-specific helpers to avoid ring-button layout ambiguity
    await openEditScore(tester);
    await setDartInEditScore(tester, 0, 'Triple'); // D1: S20 -> T20
    await setDartInEditScore(tester, 1, 'Triple'); // D2: S20 -> T20
    await updateScore(tester);

    expect(ProviderHelpers.carnivalDerbyHasWinner(tester), isTrue);

    await clickDartsRemoved(tester);

    // Wait for victory animations and stats API calls
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    await PumpSequences.fullRebuild(tester);

    expect(VictoryMusicService().isInitialized, isTrue);

    // Winner (Player A) should have gamesPlayed=1, gamesWon=1
    final winner = ProviderHelpers.findPlayerByName(tester, 'Player A');
    expect(winner, isNotNull);
    expect(winner!.gamesPlayed, 1);
    expect(winner.gamesWon, 1);
    expect(winner.gameHistory.length, 1);
    expect(winner.gameHistory.first.gameName, 'Carnival Derby');

    // Loser (Player B) should have gamesPlayed=1, gamesWon=0
    final loser = ProviderHelpers.findPlayerByName(tester, 'Player B');
    expect(loser, isNotNull);
    expect(loser!.gamesPlayed, 1);
    expect(loser.gamesWon, 0);
    expect(loser.gameHistory.length, 1);
    expect(loser.gameHistory.first.gameName, 'Carnival Derby');
  });
}
