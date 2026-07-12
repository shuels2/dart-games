// integration_test/treasure_divide/play_to_complete/default_settings_test.dart
//
// Play-to-Complete: Solo 2 players, default settings (9 rounds, Quarter It OFF,
// Custom Targets OFF). Tap SAIL TO VICTORY → game runs to completion → results
// screen reached.
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
      'Play to Complete: Treasure Divide with default settings (Solo, 9 rounds, Quarter It OFF)',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartTreasureDivide(tester, config);

    await PlayToCompleteHelpers.tapPlayToComplete(tester);

    final provider = ProviderHelpers.getTreasureDivideProvider(tester);
    await PlayToCompleteHelpers.waitForGameCompletion(
      tester,
      isComplete: () => provider.hasWinner,
      maxIterations: 500,
    );

    expect(provider.hasWinner, isTrue,
        reason: 'Game should have a winner after Play To Complete');
    expect(config.getPlayAgainButton(), findsOneWidget,
        reason:
            'Results screen should be visible (Play Again / SAIL AGAIN button found)');
  });
}
