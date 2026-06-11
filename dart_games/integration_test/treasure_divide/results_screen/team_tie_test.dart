// integration_test/treasure_divide/results_screen/team_tie_test.dart
//
// Phase 10 gap 5: Team-mode tie — 4 players in 2 crews of 2, all hitting
// every dart → identical crew totals → "DIVIDED TREASURE!" + "A TIE BETWEEN CREWS"
// and winnerTeamIds.length >= 2.
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
      'Results: team tie shows "DIVIDED TREASURE!" and "A TIE BETWEEN CREWS" '
      'when both crews score identically',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    // 4 players, Team Random → 2 crews of 2; 7 rounds for speed
    await GameSetupHelpers.setupAndStartTreasureDivide(
      tester,
      _config,
      numberOfRounds: 7,
      teamMode: true,
      playerNames: ['TeamTieP1', 'TeamTieP2', 'TeamTieP3', 'TeamTieP4'],
    );

    final provider = ProviderHelpers.getTreasureDivideProvider(tester);

    expect(provider.currentGame!.teamPlayers.length, 2,
        reason: '4 players → 2 crews of 2 (random distribution)');

    // Both crews hit every dart → identical crew totals → guaranteed tie
    int iterations = 0;
    while (!provider.hasWinner) {
      if (iterations++ > 100) {
        throw Exception(
            'team_tie_test: safety bound hit — game did not finish');
      }

      final roundIndex =
          ProviderHelpers.getTreasureDivideCurrentRoundIndex(tester);
      final target =
          ProviderHelpers.getTreasureDivideRoundTarget(tester, roundIndex);
      final dartsThisTurn = provider.currentGame?.dartsThisTurn ?? 3;

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

    // Provider reflects a team tie
    final winnerTeamIds =
        ProviderHelpers.getTreasureDivideWinnerTeamIds(tester);
    expect(winnerTeamIds.length, greaterThanOrEqualTo(2),
        reason:
            'Both crews scored identically → winnerTeamIds should contain 2 '
            '(got: ${winnerTeamIds.length})');

    // Results screen shows the tie heading and label
    expect(find.text('DIVIDED TREASURE!'), findsWidgets,
        reason: 'Tied team game should show "DIVIDED TREASURE!" heading');
    expect(find.text('A TIE BETWEEN CREWS'), findsOneWidget,
        reason:
            'Tied team game should display "A TIE BETWEEN CREWS" label');
  });
}
