// integration_test/treasure_divide/save_resume/resume_button_hidden_after_resume_test.dart
//
// SaveResume-8 — After resuming the only saved game, then re-saving and
//                returning to menu, button remains enabled (new save exists).
//                Also verifies no auto-popup of ResumeGameModal after re-save.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';
import 'package:dart_games/services/save_game_service.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('button stays enabled after resume-then-resave', (tester) async {
    await UITestHelpers.resetServerState();
    // In-game save flow (Rule §17)
    await setupAndStartGame(tester, numberOfRounds: 7,
        playerNames: ['Alice', 'Bob']);
    await throwDartViaMock(tester, 20);
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await UITestHelpers.tapSaveGameButton(tester);

    // Open resume modal via button tap
    final resumeButton =
        find.byKey(TreasureDivideMenuKeys.resumeGameButton);
    await tester.tap(resumeButton);
    await PumpSequences.asyncDataLoad(tester);

    final saved = await SaveGameService().loadSavedGames(gameType);
    await UITestHelpers.selectSavedGameTile(tester, saved[0].id);
    await UITestHelpers.tapResumeGameButton(tester);

    expect(config.getSkipTurnButton(), findsOneWidget);

    // Throw another dart and save again
    await throwDartViaMock(tester, 15);
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await UITestHelpers.tapSaveGameButton(tester);

    expect(config.getStartButton(), findsOneWidget);
    // No auto-popup of resume modal on return after re-save
    expect(ElementFinders.getResumeGameModalOverlay(), findsNothing);

    // Button should still be enabled (one save exists after re-save)
    final iconButtonFinder = find.descendant(
      of: find.byKey(TreasureDivideMenuKeys.resumeGameButton),
      matching: find.byType(IconButton),
    );
    final iconButton = tester.widget<IconButton>(iconButtonFinder);
    expect(iconButton.onPressed, isNotNull);
  });
}
