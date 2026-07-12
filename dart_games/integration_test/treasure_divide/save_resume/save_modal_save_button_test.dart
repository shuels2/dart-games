// integration_test/treasure_divide/save_resume/save_modal_save_button_test.dart
//
// SaveResume-1 — Save button saves game and returns to menu.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/services/save_game_service.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Save button saves game and navigates back', (tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, numberOfRounds: 7,
        playerNames: ['Alice', 'Bob']);
    await throwDartViaMock(tester, 20);
    await UITestHelpers.tapGameScreenBackButton(tester, config);

    await UITestHelpers.tapSaveGameButton(tester);

    expect(config.getStartButton(), findsOneWidget);
    final hasSaved = await SaveGameService().hasSavedGames(gameType);
    expect(hasSaved, true);
  });
}
