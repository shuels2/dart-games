import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/play_to_complete_helpers.dart';
import '../gameplay/_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Play to Complete: Target Tag mid-game pickup',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    await UITestHelpers.startGame(tester, config);

    // Throw 2 manual darts (building shields on own target)
    final targetNumber = getCurrentPlayerTargetNumber(tester);
    await throwDartViaMock(tester, targetNumber, multiplier: 'single');
    await throwDartViaMock(tester, targetNumber, multiplier: 'single');

    final provider = ProviderHelpers.getTargetTagProvider(tester);
    expect(provider.hasWinner, isFalse);

    await PlayToCompleteHelpers.tapPlayToComplete(tester);

    await PlayToCompleteHelpers.waitForGameCompletion(
      tester,
      isComplete: () => provider.hasWinner,
      maxIterations: 800,
    );

    expect(provider.hasWinner, isTrue);

    final playAgainButton = config.getPlayAgainButton();
    expect(playAgainButton, findsOneWidget);
  });
}
