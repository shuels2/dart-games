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
    await navigateToGameScreen(tester);
    await throwOneDart(tester);
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await UITestHelpers.tapSaveGameButton(tester);

    // Now on menu screen, find the resume button
    final resumeButton = find.byKey(TargetTagMenuKeys.resumeGameButton);
    expect(resumeButton, findsOneWidget);

    // Find the IconButton within ResumeGameButton
    final iconButtonFinder = find.descendant(
      of: resumeButton,
      matching: find.byType(IconButton),
    );
    final iconButton = tester.widget<IconButton>(iconButtonFinder);

    // Verify button is enabled (IconButton with non-null onPressed)
    expect(iconButton.onPressed, isNotNull);

    // Verify tooltip shows "Resume saved game"
    expect(iconButton.tooltip, 'Resume saved game');
  });
}
