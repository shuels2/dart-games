// integration_test/treasure_divide/save_resume/save_modal_dont_save_test.dart
//
// SaveResume-2 — Don't Save navigates back without saving.
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/services/save_game_service.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Don\'t Save navigates back without saving', (tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, numberOfRounds: 7,
        playerNames: ['Alice', 'Bob']);
    await throwDartViaMock(tester, 20);
    await UITestHelpers.tapGameScreenBackButton(tester, config);

    await UITestHelpers.tapDontSaveButton(tester);

    expect(config.getStartButton(), findsOneWidget);
    final hasSaved = await SaveGameService().hasSavedGames(gameType);
    expect(hasSaved, false);
  });
}
