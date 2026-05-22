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
    // Real-flow: navigate → throw → save → resume → throw → save again
    await navigateToGameScreen(tester);
    await throwOneDart(tester);
    await clickDartsRemoved(tester);
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await UITestHelpers.tapSaveGameButton(tester);

    // Verify 1 saved game
    var saved = await SaveGameService().loadSavedGames(gameType);
    expect(saved, hasLength(1));
    final originalId = saved[0].id;

    // Save-and-back lands the user back on the menu WITHOUT auto-popping
    // the Resume modal — see save_and_back_no_auto_resume_modal_test.dart
    // for the regression guard. Just tap back to go home.

    // Back to home from menu
    await tester.tap(find.byKey(TikiGolfMenuKeys.backButton));
    await PumpSequences.navigation(tester);

    // Tap game card on home — navigates to menu screen with resume modal
    await UITestHelpers.tapGameCard(tester, config);
    await PumpSequences.asyncDataLoad(tester);

    // Select saved game and resume (Rule §18)
    saved = await SaveGameService().loadSavedGames(gameType);
    await UITestHelpers.selectSavedGameTile(tester, saved[0].id);
    await UITestHelpers.tapResumeGameButton(tester);

    // Throw another dart in resumed game (Bob's turn)
    await throwOneDart(tester);
    await clickDartsRemoved(tester);

    // Save again via back button
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await UITestHelpers.tapSaveGameButton(tester);

    // Should still be 1 saved game (overwritten, not duplicated)
    saved = await SaveGameService().loadSavedGames(gameType);
    expect(saved, hasLength(1));
    expect(saved[0].id, originalId);
  });
}
