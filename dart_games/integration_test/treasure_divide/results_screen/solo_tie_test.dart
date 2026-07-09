// integration_test/treasure_divide/results_screen/solo_tie_test.dart
//
// Phase 10 gap 4: Solo-mode tie — when two players finish with identical
// treasure totals, the results screen must show "DIVIDED TREASURE!" and
// "A TIE BETWEEN CAPTAINS", and winnerIds.length >= 2.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/dart_throw_helpers.dart';
import '../../shared/results_helpers.dart';

final _config = GameUIConfig.treasureDivide();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Results: solo tie shows "DIVIDED TREASURE!" and "A TIE BETWEEN CAPTAINS" '
      'when both players score identically',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    // 2-player solo game with 7 rounds (shortest, fastest to complete)
    await GameSetupHelpers.setupAndStartTreasureDivide(
      tester,
      _config,
      numberOfRounds: 7,
      playerNames: ['TieP1', 'TieP2'],
    );

    final provider = ProviderHelpers.getTreasureDivideProvider(tester);

    // Both players hit every dart each turn → identical hauls each round → tie
    int iterations = 0;
    while (!provider.hasWinner) {
      if (iterations++ > 100) {
        throw Exception('solo_tie_test: safety bound hit — game did not finish');
      }

      final roundIndex =
          ProviderHelpers.getTreasureDivideCurrentRoundIndex(tester);
      final target =
          ProviderHelpers.getTreasureDivideRoundTarget(tester, roundIndex);
      final dartsThisTurn = provider.currentGame?.dartsThisTurn ?? 3;

      // Throw a dart that hits the target
      Future<void> throwHit() async {
        if (target == -1) {
          await DartThrowHelpers.throwDartViaMock(tester, 20,
              multiplier: 'double');
        } else if (target == -2) {
          await DartThrowHelpers.throwDartViaMock(tester, 20,
              multiplier: 'triple');
        } else if (target == 25) {
          await DartThrowHelpers.throwDartViaMock(tester, 25,
              multiplier: 'bullseye');
        } else {
          await DartThrowHelpers.throwDartViaMock(tester, target);
        }
      }

      for (int i = 0; i < dartsThisTurn; i++) {
        await throwHit();
      }

      // Simulate takeout via mock API
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      if (provider.shouldPromptTakeout) {
        final mockApi = DartThrowHelpers.getMockApi(tester);
        mockApi?.simulateTakeoutFinished();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump();
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      // Drain known RenderFlex overflow noise from TD game screen
      tester.binding.takeException();
    }

    await ResultsHelpers.pumpUntilResults(tester, _config);

    // Allow stats update async callback to run
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    await tester.pump();

    // Provider reflects a tie
    final winnerIds = ProviderHelpers.getTreasureDivideWinnerIds(tester);
    expect(winnerIds.length, greaterThanOrEqualTo(2),
        reason:
            'Both players scored identically → winnerIds should contain 2 '
            '(got: ${winnerIds.length})');

    // Results screen shows the tie heading and label
    expect(find.text('DIVIDED TREASURE!'), findsWidgets,
        reason: 'Tied solo game should show "DIVIDED TREASURE!" heading');
    // The subtitle is rendered TWICE by the Stack overlay pattern in
    // _buildSoloTieWinner: once as a Visibility(maintainSize) layout
    // placeholder and once as the visible overlay painted on top so
    // pirate-hat overhang can't cover it. Both instances stay in the
    // widget tree, so accept ≥1 rather than exactly 1.
    expect(find.text('A TIE BETWEEN CAPTAINS'), findsWidgets,
        reason: 'Tied solo game should display "A TIE BETWEEN CAPTAINS" label');

    // EVERY tied player gets a `gamesWon = 1` recorded.
    // _updatePlayerStats reads `game.winnerIds` and marks
    // `won: winners.contains(id)` — on a Solo tie, winnerIds has both
    // players so both should be credited with a win.
    final p1 = ProviderHelpers.findPlayerByName(tester, 'TieP1');
    final p2 = ProviderHelpers.findPlayerByName(tester, 'TieP2');
    expect(p1, isNotNull, reason: 'Player TieP1 should be in the provider');
    expect(p2, isNotNull, reason: 'Player TieP2 should be in the provider');
    expect(p1!.gamesPlayed, 1,
        reason: 'TieP1.gamesPlayed should be 1 after the tied game');
    expect(p2!.gamesPlayed, 1,
        reason: 'TieP2.gamesPlayed should be 1 after the tied game');
    expect(p1.gamesWon, 1,
        reason: 'On a Solo tie EVERY tied player must get gamesWon = 1; '
            'TieP1.gamesWon = ${p1.gamesWon}');
    expect(p2.gamesWon, 1,
        reason: 'On a Solo tie EVERY tied player must get gamesWon = 1; '
            'TieP2.gamesWon = ${p2.gamesWon}');
  });
}
