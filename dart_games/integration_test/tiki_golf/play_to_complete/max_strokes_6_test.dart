// integration_test/tiki_golf/play_to_complete/max_strokes_6_test.dart
//
// Play-to-Complete: Solo 2 players, Max Strokes = 6.
// PTC handles the variable dart count (up to 6 per turn) correctly.
//
// The strategy hits on dart 1 for the winner (target) and misses all 6 darts
// for the loser. shouldAutoTakeout is driven by currentTurnEnded regardless
// of max dart count, so PTC must handle both early exits (dart 1 hit) and
// late exits (all 6 darts thrown = splash).
//
// Section 12B — play_to_complete test 3 (max_strokes_6)
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/play_to_complete_helpers.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/settings_helpers.dart';

final config = GameUIConfig.tikiGolf();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Play to Complete: Tiki Golf with Max Strokes = 6 handles variable dart count',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartTikiGolf(
      tester,
      config,
      maxStrokes: 6,
    );

    await PlayToCompleteHelpers.tapPlayToComplete(tester);

    final provider = ProviderHelpers.getTikiGolfProvider(tester);
    await PlayToCompleteHelpers.waitForGameCompletion(
      tester,
      isComplete: () => provider.hasWinner,
      maxIterations: 800, // more iterations for 6-dart turns x 9 holes x 2 players
    );

    expect(provider.hasWinner, isTrue,
        reason:
            'Game should have a winner when Max Strokes = 6 — proves PTC handles variable dart counts');
    expect(config.getPlayAgainButton(), findsOneWidget,
        reason: 'Results screen should be visible');
    // Verify the max strokes setting was actually 6
    expect(ProviderHelpers.getTikiGolfMaxStrokes(tester), 6,
        reason: 'Max strokes should be 6 as configured');
  });
}
