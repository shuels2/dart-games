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

    final resumeButton = find.byKey(MonsterMashMenuKeys.resumeGameButton);
    expect(resumeButton, findsOneWidget);

    final iconButtonFinder = find.descendant(
      of: resumeButton,
      matching: find.byType(IconButton),
    );
    final iconButton = tester.widget<IconButton>(iconButtonFinder);
    expect(iconButton.onPressed, isNull);
    expect(iconButton.tooltip, 'No saved games');
  });
}
