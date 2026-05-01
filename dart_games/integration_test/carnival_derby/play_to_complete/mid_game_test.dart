import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/play_to_complete_helpers.dart';
import '../ui/_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Play to Complete: Carnival Derby mid-game pickup',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await navigateToCarnivalDerbyMenu(tester);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    await startGame(tester);

    // Throw 2 manual darts first
    await throwDartViaMock(tester, 20, multiplier: 'single'); // 20 pts
    await throwDartViaMock(tester, 19, multiplier: 'single'); // 19 pts

    final provider = ProviderHelpers.getCarnivalDerbyProvider(tester);
    expect(provider.hasWinner, isFalse);

    // Now let Play to Complete finish the game
    await PlayToCompleteHelpers.tapPlayToComplete(tester);

    await PlayToCompleteHelpers.waitForGameCompletion(
      tester,
      isComplete: () => provider.hasWinner,
    );

    expect(provider.hasWinner, isTrue);

    final playAgainButton = config.getPlayAgainButton();
    expect(playAgainButton, findsOneWidget);
  });
}
