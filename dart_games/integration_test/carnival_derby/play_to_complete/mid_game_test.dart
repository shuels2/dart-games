import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/game_ui_config.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/play_to_complete_helpers.dart';
import '../../shared/dart_throw_helpers.dart';

final config = GameUIConfig.carnivalDerby();

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Play to Complete: Carnival Derby mid-game pickup',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    await UITestHelpers.addPlayer(tester, 'Player A', config);
    await UITestHelpers.addPlayer(tester, 'Player B', config);

    await UITestHelpers.startGame(tester, config);

    // Throw 2 manual darts first
    await DartThrowHelpers.throwDartViaMock(tester, 20, multiplier: 'single'); // 20 pts
    await DartThrowHelpers.throwDartViaMock(tester, 19, multiplier: 'single'); // 19 pts

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
