import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';
import 'package:dart_games/services/save_game_service.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('resumed game auto-deletes saved game on completion',
      (tester) async {
    await UITestHelpers.resetServerState();
    // Full roundtrip: navigate -> throw -> save -> home -> resume -> complete
    await navigateToGameScreen(tester);
    await throwOneDart(tester);
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await UITestHelpers.tapSaveGameButton(tester);

    // Back to home from menu
    await tester.tap(find.byKey(ReefRoyaleMenuKeys.backButton));
    await PumpSequences.navigation(tester);

    // Tap game card on home — navigates to menu screen
    await tester.tap(config.getGameCard());
    await PumpSequences.navigation(tester);
    await PumpSequences.asyncDataLoad(tester);

    // Get saved game ID and select it
    final saved = await SaveGameService().loadSavedGames(gameType);
    expect(saved, hasLength(1));
    final savedGameId = saved[0].id;
    await UITestHelpers.selectSavedGameTile(tester, savedGameId);
    await UITestHelpers.tapResumeGameButton(tester);

    // Play to completion: Alice has 1 mark on 20, 2 darts remaining
    // Need 7 claimed targets to win

    // Alice's remaining 2 darts: finish claiming 20 + claim 19
    await throwDartViaMock(tester, 20, multiplier: 'double'); // 2 marks -> 3 total on 20 -> CLAIM
    await throwDartViaMock(tester, 19, multiplier: 'triple'); // 3 marks -> CLAIM (2 claimed)
    await clickDartsRemoved(tester);

    // Bob: miss x3
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Alice: claim 18, 17, 16
    await throwDartViaMock(tester, 18, multiplier: 'triple'); // CLAIM (3)
    await throwDartViaMock(tester, 17, multiplier: 'triple'); // CLAIM (4)
    await throwDartViaMock(tester, 16, multiplier: 'triple'); // CLAIM (5)
    await clickDartsRemoved(tester);

    // Bob: miss x3
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Alice: claim 15 + Bull (6th + 7th target)
    await throwDartViaMock(tester, 15, multiplier: 'triple'); // CLAIM (6)
    await throwBullseyeViaMock(tester); // 2 marks on Bull
    await throwOuterBullViaMock(tester); // 1 mark -> 3 total -> CLAIM (7) -> GAME OVER!

    // Wait for takeout prompt
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();

    // Click DARTS REMOVED for takeout
    await clickDartsRemoved(tester);

    // Wait for results screen navigation
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    await tester.pump();
    await tester.pump();

    // Verify results screen
    expect(config.getPlayAgainButton(), findsOneWidget);

    // Verify saved game was auto-deleted
    final remaining = await SaveGameService().loadSavedGames(gameType);
    expect(remaining, isEmpty);
  });
}
