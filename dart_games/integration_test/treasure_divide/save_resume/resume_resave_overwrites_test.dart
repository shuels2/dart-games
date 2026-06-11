// integration_test/treasure_divide/save_resume/resume_resave_overwrites_test.dart
//
// SaveResume-15 — Re-saving a resumed game overwrites the original save
//                 instead of creating a duplicate.
//                 Uses in-game Save flow (Rule §17).
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';
import 'package:dart_games/services/save_game_service.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('resumed game re-save overwrites instead of duplicating',
      (tester) async {
    await UITestHelpers.resetServerState();

    // Step 1: Navigate, throw 1 dart, save
    await setupAndStartGame(tester, numberOfRounds: 7,
        playerNames: ['Alice', 'Bob']);
    await throwDartViaMock(tester, 20);
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await UITestHelpers.tapSaveGameButton(tester);

    // Verify 1 saved game
    var saved = await SaveGameService().loadSavedGames(gameType);
    expect(saved, hasLength(1));
    final originalId = saved[0].id;

    // Step 2: Go back to home from menu
    await tester.tap(find.byKey(TreasureDivideMenuKeys.backButton));
    await PumpSequences.navigation(tester);

    // Step 3: Tap game card → navigate to menu with auto-popup
    await UITestHelpers.tapGameCard(tester, config);
    await PumpSequences.asyncDataLoad(tester);

    // Step 4: Select saved game and resume
    saved = await SaveGameService().loadSavedGames(gameType);
    await UITestHelpers.selectSavedGameTile(tester, saved[0].id);
    await UITestHelpers.tapResumeGameButton(tester);

    // Step 5: Throw another dart in resumed game
    await throwDartViaMock(tester, 15);

    // Step 6: Save again
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await UITestHelpers.tapSaveGameButton(tester);

    // Should still be 1 saved game (overwritten, not duplicated)
    saved = await SaveGameService().loadSavedGames(gameType);
    expect(saved, hasLength(1));
    expect(saved[0].id, originalId);
  });
}
