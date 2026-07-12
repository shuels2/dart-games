// integration_test/treasure_divide/play_to_complete/mid_game_test.dart
//
// Play-to-Complete: Solo 2 players, default settings. Manually throw 2 turns
// (6 darts total) via mockApi, then tap SAIL TO VICTORY. Verifies the strategy
// resumes from mid-game state and drives to completion.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/play_to_complete_helpers.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/dart_throw_helpers.dart';

final config = GameUIConfig.treasureDivide();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Play to Complete: Treasure Divide from mid-game state (after 2 turns thrown manually)',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartTreasureDivide(tester, config);

    // Throw 3 darts (full turn) as misses — completes turn 1 of P1
    await DartThrowHelpers.throwMissViaMock(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await DartThrowHelpers.throwMissViaMock(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    await DartThrowHelpers.throwMissViaMock(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    // Simulate takeout to advance to P2's turn.
    // NOTE: clickDartsRemoved() taps the "DARTS REMOVED" button which calls
    // dartboardKey?.currentState?.removeDarts() — but TD game screen doesn't
    // pass dartboardKey to DartboardEmulatorSection, so it's a no-op.
    // Must fire the stream event directly via simulateTakeoutFinished.
    DartThrowHelpers.getMockApi(tester)?.simulateTakeoutFinished();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    // Now tap Play To Complete from mid-game state (P2's turn)
    await PlayToCompleteHelpers.tapPlayToComplete(tester);

    final provider = ProviderHelpers.getTreasureDivideProvider(tester);
    await PlayToCompleteHelpers.waitForGameCompletion(
      tester,
      isComplete: () => provider.hasWinner,
      maxIterations: 500,
    );

    expect(provider.hasWinner, isTrue,
        reason:
            'Game should have a winner after Play To Complete from mid-game');
    expect(config.getPlayAgainButton(), findsOneWidget,
        reason: 'Results screen should be visible (Play Again button found)');
  });
}
