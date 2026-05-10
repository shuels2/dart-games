import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/services/save_game_service.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Back with 0 darts: save modal appears and save works',
      (tester) async {
    await UITestHelpers.resetServerState();
    await navigateToGameScreen(tester);

    // No darts thrown — tap back
    await UITestHelpers.tapGameScreenBackButton(tester, config);

    // Save modal should appear
    UITestHelpers.verifySaveGameModal();

    // Save it
    await UITestHelpers.tapSaveGameButton(tester);

    // Back on menu
    expect(config.getStartButton(), findsOneWidget);
    final hasSaved = await SaveGameService().hasSavedGames(gameType);
    expect(hasSaved, true);
  });
}
