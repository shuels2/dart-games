// integration_test/tiki_golf/play_to_complete/team_mode_test.dart
//
// Play-to-Complete: Team mode, 4 players (2 teams of 2), Random assignment.
// PTC completes; results screen shows winning team crest.
//
// The TikiGolfStrategy in team mode designates the first player of the first
// team as the winner (hits on dart 1 every hole); all others miss every dart.
// After 9 holes, the first team has the lowest total.
//
// Section 12B — play_to_complete test 5 (team_mode)
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/play_to_complete_helpers.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/element_finders.dart';

final config = GameUIConfig.tikiGolf();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Play to Complete: Tiki Golf Team mode (4 players, Random) — team results screen reached',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    // 4 players in Team+Random mode → 2 teams of 2 (per spec distribution table)
    await GameSetupHelpers.setupAndStartTikiGolf(
      tester,
      config,
      teamMode: true,
      playerNames: ['Alpha', 'Beta', 'Gamma', 'Delta'],
    );

    await PlayToCompleteHelpers.tapPlayToComplete(tester);

    final provider = ProviderHelpers.getTikiGolfProvider(tester);
    await PlayToCompleteHelpers.waitForGameCompletion(
      tester,
      isComplete: () => provider.hasWinner,
      maxIterations: 700, // 4 players × 9 holes with team turn ordering
    );

    expect(provider.hasWinner, isTrue,
        reason: 'Team game should have a winner after Play To Complete');
    expect(config.getPlayAgainButton(), findsOneWidget,
        reason: 'Results screen should be visible (Play Again button found)');

    // Verify team results: winning team crest should be displayed
    final winnerTeamCrest = ElementFinders.getTikiGolfWinnerTeamCrest();
    expect(winnerTeamCrest, findsOneWidget,
        reason:
            'Team results screen should show the winning team crest — proves team mode completed correctly');

    // Verify the winning team ID is set
    final winnerTeamId = ProviderHelpers.getTikiGolfWinnerTeamId(tester);
    expect(winnerTeamId, isNotNull,
        reason: 'Winner team ID should be set after team game completion');
  });
}
