// integration_test/tiki_golf/results_screen/team_tie_test.dart
//
// Team-mode tie: when two teams finish a Tiki Golf game with identical
// team best-ball totals, the results screen must show BOTH teams as tied
// champions, and EVERY player on EVERY tied team must receive a win.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:dart_games/constants/test_keys.dart';
import '../../shared/dart_throw_helpers.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/pump_sequences.dart';

// NOTE: this test deliberately calls GameSetupHelpers.setupAndStartTikiGolf
// directly instead of importing the sibling `../team_mode_gameplay/_helpers.dart`.
// Flutter web's kernel compiler resolves the entry test file's directory as
// the root of the org-dartlang-app:/ URI scheme, so cross-directory sibling
// imports (`../team_mode_gameplay/...`) fail to resolve — only `../../shared/`
// works because of the way Flutter handles relative test imports.

final _config = GameUIConfig.tikiGolf();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Results: team tie shows both winning teams and credits every member',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();

    // 4 players, random assignment → 2 teams of 2 (per spec randomDistribution).
    await GameSetupHelpers.setupAndStartTikiGolf(
      tester,
      _config,
      teamMode: true,
      playerNames: ['Alice', 'Bob', 'Carl', 'Dana'],
    );

    final provider = ProviderHelpers.getTikiGolfProvider(tester);
    expect(provider.currentGame!.teamPlayers.length, 2,
        reason: '4 players → 2 teams of 2 (random distribution)');

    // Every player birdies every hole → identical best-ball=1 each hole for
    // both teams → tied at 9 total strokes each.
    while (!provider.hasWinner) {
      final hole = ProviderHelpers.getTikiGolfCurrentHole(tester);
      final target = ProviderHelpers.getTikiGolfHoleTarget(tester, hole);
      await DartThrowHelpers.throwDartViaMock(tester, target);
      await DartThrowHelpers.clickDartsRemoved(tester);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
    }

    await tester.pump(const Duration(seconds: 5));
    await PumpSequences.fullRebuild(tester);

    // Provider reflects the team tie
    final winnerTeamIds = provider.currentGame!.winnerTeamIds!;
    expect(winnerTeamIds.length, 2,
        reason: 'Both teams should be tied winners on identical best-ball');

    // Results screen displays plural champions heading + TIED label
    expect(find.text('GOLDEN TIKI CHAMPIONS!'), findsOneWidget,
        reason: 'Tied team game should show plural champions heading');
    expect(find.text('TIED!'), findsOneWidget,
        reason: 'Tied team game should display a TIED! label');

    // Both winning team crests are present
    for (final teamId in winnerTeamIds) {
      expect(find.byKey(TikiGolfResultsKeys.tiedWinnerTeamCrest(teamId)),
          findsOneWidget,
          reason: 'Team crest for tied team $teamId should be on the screen');
    }

    // Stats: every player on a tied team gets a win
    final game = provider.currentGame!;
    final winningTeamSet = winnerTeamIds.toSet();
    final winningPlayerIds = <String>{
      for (final pid in game.playerIds)
        if (winningTeamSet.contains(game.playerTeamAssignments[pid])) pid,
    };
    expect(winningPlayerIds.length, 4,
        reason: 'All 4 players belong to a tied team');

    for (final name in ['Alice', 'Bob', 'Carl', 'Dana']) {
      final player = ProviderHelpers.findPlayerByName(tester, name)!;
      expect(player.gamesWon, 1,
          reason: '$name is on a tied team → gamesWon should be 1');
      expect(player.gamesPlayed, 1);
    }
  });
}

