// integration_test/treasure_divide/play_to_complete/quarter_it_on_test.dart
//
// Play-to-Complete: Solo 2 players + Quarter It ON. Play-to-complete.
// Asserts the game completes (quarter mechanic doesn't break completion).
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
      'Play to Complete: Treasure Divide with Quarter It ON — game completes without errors',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartTreasureDivide(
      tester,
      config,
      quarterItEnabled: true,
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
            'Game should have a winner after Play To Complete with Quarter It ON. '
            'Quarter mechanic should not break PTC strategy.');
    expect(config.getPlayAgainButton(), findsOneWidget,
        reason: 'Results screen should be visible with Quarter It ON');
  });
}
