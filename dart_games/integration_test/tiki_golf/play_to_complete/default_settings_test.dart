// integration_test/tiki_golf/play_to_complete/default_settings_test.dart
//
// Play-to-Complete: Solo 2 players, default Max Strokes 3, Mulligan OFF.
// Tap Play To Complete → game runs to completion → results screen reached.
//
// Section 12B — play_to_complete test 1 (default_settings)
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/play_to_complete_helpers.dart';
import '../../shared/game_setup_helpers.dart';

final config = GameUIConfig.tikiGolf();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Play to Complete: Tiki Golf with default settings (Solo, Max Strokes 3, Mulligan OFF)',
      (WidgetTester tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_ptc_default_settings',
      () async {
        await UITestHelpers.resetServerState();
        await GameSetupHelpers.setupAndStartTikiGolf(tester, config);

        await PlayToCompleteHelpers.tapPlayToComplete(tester);

        final provider = ProviderHelpers.getTikiGolfProvider(tester);
        await PlayToCompleteHelpers.waitForGameCompletion(
          tester,
          isComplete: () => provider.hasWinner,
        );

        expect(provider.hasWinner, isTrue,
            reason: 'Game should have a winner after Play To Complete');
        expect(config.getPlayAgainButton(), findsOneWidget,
            reason: 'Results screen should be visible (Play Again button found)');
      },
    );
  });
}
