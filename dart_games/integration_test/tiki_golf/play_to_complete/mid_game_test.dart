// integration_test/tiki_golf/play_to_complete/mid_game_test.dart
//
// Play-to-Complete: Solo 2 players. Throw 1-2 darts manually, then tap
// Play To Complete. Verifies PTC finishes from a mid-game state.
//
// Section 12B — play_to_complete test 2 (mid_game)
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/play_to_complete_helpers.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/dart_throw_helpers.dart';
import '../../shared/pump_sequences.dart';

final config = GameUIConfig.tikiGolf();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Play to Complete: Tiki Golf from mid-game state (after 1 dart thrown manually)',
      (WidgetTester tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_ptc_mid_game',
      () async {
        await UITestHelpers.resetServerState();
        await GameSetupHelpers.setupAndStartTikiGolf(tester, config);

        // Throw one dart manually (a miss) — this puts us mid-turn
        await DartThrowHelpers.throwMissViaMock(tester);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();

        // Now tap Play To Complete from mid-turn state
        await PlayToCompleteHelpers.tapPlayToComplete(tester);

        final provider = ProviderHelpers.getTikiGolfProvider(tester);
        await PlayToCompleteHelpers.waitForGameCompletion(
          tester,
          isComplete: () => provider.hasWinner,
        );

        expect(provider.hasWinner, isTrue,
            reason: 'Game should have a winner after Play To Complete from mid-game');
        expect(config.getPlayAgainButton(), findsOneWidget,
            reason: 'Results screen should be visible (Play Again button found)');
      },
    );
  });
}
