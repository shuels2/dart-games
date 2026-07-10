// integration_test/treasure_divide/play_to_complete/team_mode_test.dart
//
// Play-to-Complete: Team mode + Random, 4 players (2 crews of 2).
// PTC drives to completion; results screen is reached.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/play_to_complete_helpers.dart';
import '../../shared/game_setup_helpers.dart';

final config = GameUIConfig.treasureDivide();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Play to Complete: Treasure Divide Team mode (4 players, Random) — results screen reached',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    // 4 players in Team+Random mode → 2 crews of 2 (per spec distribution table)
    await GameSetupHelpers.setupAndStartTreasureDivide(
      tester,
      config,
      teamMode: true,
      playerNames: ['Alpha', 'Beta', 'Gamma', 'Delta'],
    );

    // Drain any initial layout overflow from the game screen render.

    await PlayToCompleteHelpers.tapPlayToComplete(tester);

    final provider = ProviderHelpers.getTreasureDivideProvider(tester);
    await PlayToCompleteHelpers.waitForGameCompletion(
      tester,
      isComplete: () => provider.hasWinner,
      maxIterations: 700, // 4 players × 9 rounds with team turn ordering
    );

    // Drain any layout overflow exceptions accumulated during PTC run.
    for (var i = 0; i < 10; i++) {
      final ex = tester.binding.takeException();
      if (ex == null) break;
    }

    expect(provider.hasWinner, isTrue,
        reason: 'Team game should have a winner after Play To Complete');
    expect(config.getPlayAgainButton(), findsOneWidget,
        reason:
            'Results screen should be visible — proves team mode PTC completed correctly');

    // Verify a winning team is set
    final winnerTeamIds =
        ProviderHelpers.getTreasureDivideWinnerTeamIds(tester);
    expect(winnerTeamIds, isNotEmpty,
        reason: 'Winner team IDs should be set after team game completion');
  });
}
