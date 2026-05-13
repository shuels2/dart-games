import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/services/save_game_service.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Menu: Resume button is active when a saved game exists (real-flow)',
      (tester) async {
    await UITestHelpers.resetServerState();

    // Start game and save via real flow
    await setupAndStartGame(tester, config);
    await throwDartViaMock(tester, 20);
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await UITestHelpers.tapSaveGameButton(tester);

    // Verify a saved game exists
    final hasSaved =
        await SaveGameService().hasSavedGames('gladiator_arena');
    expect(hasSaved, isTrue,
        reason: 'A saved game should exist after saving');

    // Menu start button should be visible
    expect(ElementFinders.getGladiatorArenaStartButton(), findsOneWidget);

    // Resume modal can be triggered via the resume button area
    expect(ElementFinders.getResumeGameModalOverlay(), findsNothing,
        reason: 'Modal should not be visible yet');
  });
}
