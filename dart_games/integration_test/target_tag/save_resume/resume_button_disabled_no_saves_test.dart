import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('button is disabled when no saved games exist', (tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Find the resume button
    final resumeButton = find.byKey(TargetTagMenuKeys.resumeGameButton);
    expect(resumeButton, findsOneWidget);

    // Find the IconButton within ResumeGameButton
    final iconButtonFinder = find.descendant(
      of: resumeButton,
      matching: find.byType(IconButton),
    );
    final iconButton = tester.widget<IconButton>(iconButtonFinder);

    // Verify button is disabled (IconButton with null onPressed)
    expect(iconButton.onPressed, isNull);

    // Verify tooltip shows "No saved games"
    expect(iconButton.tooltip, 'No saved games');
  });
}
