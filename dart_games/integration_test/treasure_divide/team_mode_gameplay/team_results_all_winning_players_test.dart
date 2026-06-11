// integration_test/treasure_divide/team_mode_gameplay/team_results_all_winning_players_test.dart
//
// Phase 10 gap 6: Team mode results — every player on the winning crew gets
// gamesWon=1 after a clear (non-tie) team victory.
//
// Strategy: in each turn, the active crew (team A) hits every dart while
// the next crew (team B) misses every dart. Because the turn order alternates
// between teams, team A accumulates gold and team B scores 0 → clear winner.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/dart_throw_helpers.dart';
import '../../shared/results_helpers.dart';
import '../../shared/element_finders.dart';

final _config = GameUIConfig.treasureDivide();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Team Mode Results: every winning-crew player has gamesWon=1 after clear victory',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    // 4 players, Team Random → 2 crews of 2; 7 rounds for speed
    await GameSetupHelpers.setupAndStartTreasureDivide(
      tester,
      _config,
      numberOfRounds: 7,
      teamMode: true,
      playerNames: ['WinA1', 'WinA2', 'WinB1', 'WinB2'],
    );

    final provider = ProviderHelpers.getTreasureDivideProvider(tester);

    expect(provider.currentGame!.teamPlayers.length, 2,
        reason: '4 players → 2 crews of 2 (random distribution)');

    // Remember the FIRST active team — this is "team A" (always hits)
    final winningTeamId = provider.currentGame!.activeTeamId;
    expect(winningTeamId, isNotNull, reason: 'Should have an active team at start');

    // Drive game: active crew hits, other crew misses (determined per turn)
    int iterations = 0;
    while (!provider.hasWinner) {
      if (iterations++ > 100) {
        throw Exception(
            'team_results_all_winning_players_test: safety bound hit — game did not finish');
      }

      final game = provider.currentGame!;
      final currentTeamId = game.activeTeamId;
      final roundIndex = game.currentRoundIndex;
      final target = game.targetSequence[roundIndex];
      final dartsThisTurn = game.dartsThisTurn;

      final isWinningTeam = (currentTeamId == winningTeamId);

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

      if (isWinningTeam) {
        // Winning crew hits all darts
        for (int i = 0; i < dartsThisTurn; i++) {
          await throwHit();
        }
      } else {
        // Other crew misses all darts → score 0 (or halved if they had any gold)
        for (int i = 0; i < dartsThisTurn; i++) {
          await DartThrowHelpers.throwMissViaMock(tester);
        }
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

    // Verify the winning team from the provider
    final winnerTeamIds =
        ProviderHelpers.getTreasureDivideWinnerTeamIds(tester);
    expect(winnerTeamIds.length, 1,
        reason:
            'Clear winner expected (winning crew hit, losing crew missed) — '
            'got winnerTeamIds: $winnerTeamIds');

    final actualWinnerTeamId = winnerTeamIds.first;

    // Winning crew crest should be on the results screen
    expect(ElementFinders.getTreasureDivideWinnerCrewCrest(), findsWidgets,
        reason: 'Winning crew crest should be visible on results screen');

    // Every player on the winning crew must have gamesWon=1
    final game = provider.currentGame!;
    final winningMembers = game.teamPlayers[actualWinnerTeamId] ?? [];
    expect(winningMembers, isNotEmpty,
        reason: 'Winning team must have players');

    for (final playerId in winningMembers) {
      // Find the player via their key on the results screen
      expect(find.byKey(TreasureDivideResultsKeys.winnerCrewPlayer(playerId)),
          findsOneWidget,
          reason:
              'Player $playerId on winning crew $actualWinnerTeamId should have '
              'a widget on the results screen');

      // Stats: gamesWon must be 1 for every winning crew member
      final player = ProviderHelpers.findPlayerById(tester, playerId);
      expect(player, isNotNull,
          reason: 'Player $playerId should be found in the player provider');
      expect(player!.gamesWon, 1,
          reason:
              'Player $playerId is on winning crew → gamesWon should be 1 '
              '(got ${player.gamesWon})');
      expect(player.gamesPlayed, 1,
          reason: 'Player $playerId should have gamesPlayed=1');
    }
  });
}
