import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:dart_games/services/victory_music_service.dart';
import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/edit_score_helpers.dart';
import '_helpers.dart';

/// MANDATORY: Edit Score — editing a non-winning turn (Splash on last hole)
/// to a winning value (Birdie) and then confirming takeout causes the game
/// to end with updated stats persisted.
///
/// In Tiki Golf, hasWinner is determined during confirmTurnEnd → _endGame,
/// not during processDartThrow. So the flow is:
///  1. Both players through holes 1-8 (birdies, 8 strokes each).
///  2. Alice hole 9: Splash → confirm → Alice total = 12.
///  3. Bob hole 9: throw 3 misses → Splash (currentTurnEnded=true, no winner yet).
///  4. Edit Bob's hole 9 score to Birdie (dart 1 = target).
///  5. Confirm Bob's takeout → _endGame → Bob wins (total 9 vs Alice 12).
///  6. Verify VictoryMusicService initialized + winner stats persisted.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Edit Score: non-winning turn edited to winning score persists stats',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester,
        maxStrokes: 3, playerNames: ['Alice', 'Bob']);

    final provider = ProviderHelpers.getTikiGolfProvider(tester);
    final players = ProviderHelpers.getSelectedPlayers(tester);
    final aliceId = players.firstWhere((p) => p.name == 'Alice').id;
    final bobId = players.firstWhere((p) => p.name == 'Bob').id;

    // Helper: throw the target dart for the current hole
    Future<void> throwCurrentTarget() async {
      final hole = ProviderHelpers.getTikiGolfCurrentHole(tester);
      final target = ProviderHelpers.getTikiGolfHoleTarget(tester, hole);
      await throwDartViaMock(tester, target);
    }

    // Drive through holes 1-8 for both players (all birdies)
    int safety = 0;
    while (!provider.hasWinner &&
        provider.currentGame!.currentHole < 9 &&
        safety < 200) {
      safety++;
      await throwCurrentTarget();
      await clickDartsRemoved(tester);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
    }

    expect(provider.currentGame!.currentHole, 9,
        reason: 'Should be on hole 9 after driving through holes 1-8');
    expect(provider.hasWinner, isFalse,
        reason: 'Should not have winner yet on hole 9');

    // Alice on hole 9: Splash (3 misses, strokes=4, total=12)
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // Confirm Alice's takeout → advance to Bob
    await clickDartsRemoved(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(provider.hasWinner, isFalse,
        reason: 'Still no winner after Alice — Bob still needs to play hole 9');

    // Bob on hole 9: throw 3 misses → Splash (currentTurnEnded=true)
    // Game NOT over yet — winner set only at confirmTurnEnd → _endGame
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(provider.shouldPromptTakeout, isTrue,
        reason: "Bob's turn ended (Splash) — modal should prompt takeout");
    expect(provider.hasWinner, isFalse,
        reason: 'Winner not yet set — confirmTurnEnd has not been called');

    // Edit Bob's hole 9: change dart 1 to target (Birdie, strokes=1)
    // Bob's total after edit: 8 + 1 = 9 (beats Alice's 12)
    final hole9Target = ProviderHelpers.getTikiGolfHoleTarget(tester, 9);
    await EditScoreHelpers.editScoreAndSave(
      tester,
      config,
      dart1: 'S$hole9Target',
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // After edit: Bob's hole 9 score is now 1 (Birdie), currentTurnEnded still true
    final bobHole9Score =
        ProviderHelpers.getTikiGolfPlayerHoleScore(tester, bobId, 9);
    expect(bobHole9Score, 1,
        reason: "Bob's hole 9 should be 1 (Birdie) after edit");
    expect(provider.hasWinner, isFalse,
        reason: 'Winner still not set — confirmTurnEnd not called yet');

    // Confirm Bob's takeout → confirmTurnEnd → _endGame → hasWinner=true
    await clickDartsRemoved(tester);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await PumpSequences.fullRebuild(tester);

    expect(VictoryMusicService().isInitialized, isTrue,
        reason: 'VictoryMusicService should be initialized after results');

    // Bob should be the winner (total 9 vs Alice 12)
    final winnerId = ProviderHelpers.getTikiGolfWinnerId(tester);
    expect(winnerId, bobId,
        reason:
            'Bob should win with total=9 vs Alice total=12 after edit');

    // Winner (Bob) should have gamesPlayed=1, gamesWon=1
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    await PumpSequences.fullRebuild(tester);

    final winnerPlayer = ProviderHelpers.findPlayerById(tester, bobId);
    expect(winnerPlayer, isNotNull);
    expect(winnerPlayer!.gamesPlayed, 1,
        reason: 'Bob gamesPlayed should be 1');
    expect(winnerPlayer.gamesWon, 1, reason: 'Bob gamesWon should be 1');
    expect(winnerPlayer.gameHistory.length, 1,
        reason: 'Bob should have 1 game in history');
    expect(winnerPlayer.gameHistory.first.gameName, 'Tiki Golf');

    // Loser (Alice) should have gamesPlayed=1, gamesWon=0
    final loserPlayer = ProviderHelpers.findPlayerById(tester, aliceId);
    expect(loserPlayer, isNotNull);
    expect(loserPlayer!.gamesPlayed, 1,
        reason: 'Alice gamesPlayed should be 1');
    expect(loserPlayer.gamesWon, 0, reason: 'Alice gamesWon should be 0');
  });
}
