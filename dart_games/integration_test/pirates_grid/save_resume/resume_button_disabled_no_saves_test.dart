import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/widgets/resume_game_button.dart';

import '../../shared/ui_test_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('button is disabled when no saved games exist', (tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // PG hides the ResumeGameButton entirely when no saves exist
    // (it is wrapped in `if (_hasSavedGames)` in the AppBar actions).
    final resumeButton = find.byType(ResumeGameButton);
    expect(resumeButton, findsNothing,
        reason: 'Resume button should not be shown when no saved games exist');
  });
}
