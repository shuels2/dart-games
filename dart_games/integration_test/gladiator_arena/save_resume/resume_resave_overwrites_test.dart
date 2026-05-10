import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';
import 'package:dart_games/services/save_game_service.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Re-saving a resumed game overwrites the original save',
      (tester) async {
    await UITestHelpers.resetServerState();

    // Save game via real flow
    await navigateToGameScreen(tester);
    await throwOneDart(tester);
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await UITestHelpers.tapSaveGameButton(tester);

    var saves = await SaveGameService().loadSavedGames(gameType);
    expect(saves, hasLength(1));
    final originalId = saves[0].id;

    // Go home, navigate back, resume
    await tester.tap(find.byKey(GladiatorArenaMenuKeys.backButton));
    await PumpSequences.navigation(tester);
    await UITestHelpers.tapGameCard(tester, config);
    await PumpSequences.asyncDataLoad(tester);

    await UITestHelpers.selectSavedGameTile(tester, originalId);
    await UITestHelpers.tapResumeGameButton(tester);

    // Throw another dart and save again
    await throwOneDart(tester);
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await UITestHelpers.tapSaveGameButton(tester);

    // Should still have only 1 save (overwritten)
    saves = await SaveGameService().loadSavedGames(gameType);
    expect(saves, hasLength(1),
        reason: 'Re-save should overwrite, not create a new entry');
  });
}
