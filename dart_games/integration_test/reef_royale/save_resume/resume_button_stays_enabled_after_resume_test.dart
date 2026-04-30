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

  testWidgets('button stays hidden when modal is not shown after resume',
      (tester) async {
    await UITestHelpers.resetServerState();
    await navigateToGameScreen(tester);
    await throwOneDart(tester);
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await UITestHelpers.tapSaveGameButton(tester);

    final resumeButton = find.byKey(ReefRoyaleMenuKeys.resumeGameButton);
    await tester.tap(resumeButton);
    await PumpSequences.asyncDataLoad(tester);

    final saved = await SaveGameService().loadSavedGames(gameType);
    await UITestHelpers.selectSavedGameTile(tester, saved[0].id);
    await UITestHelpers.tapResumeGameButton(tester);

    expect(config.getSkipTurnButton(), findsOneWidget);

    await throwOneDart(tester);
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await UITestHelpers.tapSaveGameButton(tester);

    expect(config.getStartButton(), findsOneWidget);
    expect(ElementFinders.getResumeGameModalOverlay(), findsNothing);

    final resumeButtonAfter =
        find.byKey(ReefRoyaleMenuKeys.resumeGameButton);
    final iconButtonFinderAfter = find.descendant(
      of: resumeButtonAfter,
      matching: find.byType(IconButton),
    );
    final iconButton = tester.widget<IconButton>(iconButtonFinderAfter);
    expect(iconButton.onPressed, isNotNull);
  });
}
