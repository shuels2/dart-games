// integration_test/treasure_divide/save_resume/resume_button_enabled_after_save_test.dart
//
// SaveResume-7 — ResumeGameButton becomes enabled after saving a game
//                via the in-game Save flow.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('button becomes enabled after saving a game', (tester) async {
    await UITestHelpers.resetServerState();
    await setupAndStartGame(tester, numberOfRounds: 7,
        playerNames: ['Alice', 'Bob']);
    await throwDartViaMock(tester, 20);
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await UITestHelpers.tapSaveGameButton(tester);

    final resumeButton =
        find.byKey(TreasureDivideMenuKeys.resumeGameButton);
    expect(resumeButton, findsOneWidget);

    final iconButtonFinder = find.descendant(
      of: resumeButton,
      matching: find.byType(IconButton),
    );
    final iconButton = tester.widget<IconButton>(iconButtonFinder);
    expect(iconButton.onPressed, isNotNull);
    expect(iconButton.tooltip, 'Resume saved game');
  });
}
