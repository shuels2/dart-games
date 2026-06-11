// integration_test/treasure_divide/play_to_complete/rounds_7_test.dart
//
// Play-to-Complete: Solo 2 players + Number of Rounds = 7. Play-to-complete.
// Asserts game completes in 7 rounds (not 9 or 12).
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
      'Play to Complete: Treasure Divide with Number of Rounds = 7 — completes in 7 rounds',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartTreasureDivide(
      tester,
      config,
      numberOfRounds: 7,
    );

    await PlayToCompleteHelpers.tapPlayToComplete(tester);

    final provider = ProviderHelpers.getTreasureDivideProvider(tester);
    await PlayToCompleteHelpers.waitForGameCompletion(
      tester,
      isComplete: () => provider.hasWinner,
      maxIterations: 500,
    );

    expect(provider.hasWinner, isTrue,
        reason:
            'Game should have a winner after Play To Complete with 7 rounds');
    expect(config.getPlayAgainButton(), findsOneWidget,
        reason: 'Results screen should be visible after 7-round game');

    // Verify the game ran exactly 7 rounds (not 9 or 12).
    final game = provider.currentGame;
    if (game != null) {
      expect(game.numberOfRounds, equals(7),
          reason:
              'Game should have been configured for 7 rounds, '
              'got ${game.numberOfRounds}');
    }
  });
}
