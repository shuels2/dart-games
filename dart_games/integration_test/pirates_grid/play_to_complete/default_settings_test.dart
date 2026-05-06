import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/play_to_complete_helpers.dart';
import '../../shared/game_setup_helpers.dart';

final config = GameUIConfig.piratesGrid();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      "Play to Complete: Pirate's Grid with default settings (Easy, Bo1, Steal OFF, Speed OFF)",
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await GameSetupHelpers.setupAndStartPiratesGrid(tester, config);

    await PlayToCompleteHelpers.tapPlayToComplete(tester);

    final provider = ProviderHelpers.getPiratesGridProvider(tester);
    await PlayToCompleteHelpers.waitForGameCompletion(
      tester,
      isComplete: () => provider.hasWinner,
    );

    expect(provider.hasWinner, isTrue,
        reason: 'Game should be complete after play-to-complete');
    expect(config.getPlayAgainButton(), findsOneWidget,
        reason: 'Results screen should be visible');
  });
}
