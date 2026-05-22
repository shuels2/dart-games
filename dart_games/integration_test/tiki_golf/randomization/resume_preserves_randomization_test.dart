// integration_test/tiki_golf/randomization/resume_preserves_randomization_test.dart
//
// Save mid-game, capture targets+images, resume, verify identical.
//
// The randomization (holeTargets, holeImagePaths) must be preserved through
// a save/resume cycle. This test:
//   1. Starts a game and captures holeTargets + holeImagePaths
//   2. Throws one dart to advance game state
//   3. Saves the game via the back button → Save Game modal
//   4. Returns to the menu and resumes the game
//   5. Verifies holeTargets + holeImagePaths are identical to step 1
//
// Section 12B File 3a — Randomization test 4
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';
import 'package:dart_games/services/save_game_service.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'Randomization: save/resume cycle preserves holeTargets and holeImagePaths',
      (WidgetTester tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester);

    // Capture randomization from game 1
    final targets1 = getHoleTargets(tester);
    final images1 = getHoleImagePaths(tester);
    expect(targets1.length, 9);
    expect(images1.length, 9);

    // Throw one dart to advance state (miss on hole 1)
    await throwMissViaMock(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    // Save via back button → save modal → Save button
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await UITestHelpers.tapSaveGameButton(tester);

    // Save-and-back lands the user back on the menu WITHOUT auto-popping
    // the Resume modal — see save_and_back_no_auto_resume_modal_test.dart
    // for the regression guard. Just tap back to go home.

    // Back to home
    await tester.tap(find.byKey(TikiGolfMenuKeys.backButton));
    await PumpSequences.navigation(tester);

    // Navigate back to menu to trigger resume modal
    await UITestHelpers.tapGameCard(tester, config);
    await PumpSequences.asyncDataLoad(tester);

    // Select and resume the saved game
    final saved = await SaveGameService().loadSavedGames('tiki_golf');
    expect(saved, hasLength(1),
        reason: 'Should have exactly one saved game');
    await UITestHelpers.selectSavedGameTile(tester, saved[0].id);
    await UITestHelpers.tapResumeGameButton(tester);

    // Verify game screen loaded
    expect(config.getSkipTurnButton(), findsOneWidget);

    // Verify randomization is identical
    final targets2 = getHoleTargets(tester);
    final images2 = getHoleImagePaths(tester);

    expect(targets2, equals(targets1),
        reason:
            'holeTargets must be identical after resume. '
            'Before save: $targets1, After resume: $targets2');
    expect(images2, equals(images1),
        reason:
            'holeImagePaths must be identical after resume. '
            'Before save: $images1, After resume: $images2');
  });
}
