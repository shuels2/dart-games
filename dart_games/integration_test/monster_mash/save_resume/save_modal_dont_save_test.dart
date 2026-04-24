import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/services/save_game_service.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Don\'t Save navigates back without saving', (tester) async {
    await UITestHelpers.resetServerState();
    await navigateToGameScreen(tester);
    await throwOneDart(tester);
    await UITestHelpers.tapGameScreenBackButton(tester, config);

    await UITestHelpers.tapDontSaveButton(tester);

    expect(config.getStartButton(), findsOneWidget);
    final hasSaved = await SaveGameService().hasSavedGames(gameType);
    expect(hasSaved, false);
  });
}
