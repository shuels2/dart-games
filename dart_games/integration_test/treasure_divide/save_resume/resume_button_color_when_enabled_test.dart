// integration_test/treasure_divide/save_resume/resume_button_color_when_enabled_test.dart
//
// SaveResume-6 — ResumeGameButton has Treasure Gold color when saves exist.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/save_resume_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('button is visible with Treasure Gold color when enabled',
      (tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToHomeScreen(tester);
    await SaveResumeHelpers.preSaveGame(GameSaveConfig.treasureDivide());
    await UITestHelpers.tapGameCard(tester, config);

    final resumeButton =
        find.byKey(TreasureDivideMenuKeys.resumeGameButton);
    expect(resumeButton, findsOneWidget);

    final iconButtonFinder = find.descendant(
      of: resumeButton,
      matching: find.byType(IconButton),
    );
    final iconButton = tester.widget<IconButton>(iconButtonFinder);

    // Treasure Gold color (matches _treasureGold in menu screen)
    expect(iconButton.color, const Color(0xFFFFD700));

    final icon = iconButton.icon as Icon;
    expect(icon.icon, Icons.history);
  });
}
