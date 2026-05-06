import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/play_to_complete_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Play to Complete: Pirate\'s Grid mid-game manual then auto-complete',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, config,
        playerNames: ['Player A', 'Player B']);

    // Throw a few manual darts to get mid-game state
    await throwDartViaMock(tester, 20);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Now use play-to-complete to finish
    await PlayToCompleteHelpers.tapPlayToComplete(tester);

    final provider = ProviderHelpers.getPiratesGridProvider(tester);
    await PlayToCompleteHelpers.waitForGameCompletion(
      tester,
      isComplete: () => provider.hasWinner,
    );

    expect(provider.hasWinner, isTrue,
        reason: 'Game should be complete after mid-game play-to-complete');
    expect(config.getPlayAgainButton(), findsOneWidget,
        reason: 'Results screen should be visible');
  });
}
