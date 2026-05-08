import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/widgets/resume_game_button.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('button is visible with correct color when enabled',
      (tester) async {
    await UITestHelpers.resetServerState();
    await navigateToGameScreen(tester);
    await throwOneDart(tester);
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await UITestHelpers.tapSaveGameButton(tester);

    // PG's ResumeGameButton has no key — locate it by type.
    final resumeButton = find.byType(ResumeGameButton);
    expect(resumeButton, findsOneWidget);

    final iconButtonFinder = find.descendant(
      of: resumeButton,
      matching: find.byType(IconButton),
    );
    final iconButton = tester.widget<IconButton>(iconButtonFinder);

    // PG uses Treasure Gold for the resume button
    expect(iconButton.color, const Color(0xFFDAA520));

    final icon = iconButton.icon as Icon;
    expect(icon.icon, Icons.history);
  });
}
