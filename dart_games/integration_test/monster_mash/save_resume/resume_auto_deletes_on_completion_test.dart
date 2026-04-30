import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';
import 'package:dart_games/services/save_game_service.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('resumed game auto-deletes saved game on completion',
      (tester) async {
    await UITestHelpers.resetServerState();
    // Full roundtrip: navigate -> throw -> save -> home -> resume -> complete
    // Use low health (10) for quick game completion
    await navigateToGameScreenLowHealth(tester);
    await throwOneDart(tester);
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await UITestHelpers.tapSaveGameButton(tester);

    // Back to home from menu
    await tester.tap(find.byKey(MonsterMashMenuKeys.backButton));
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

    // Play to completion: health=10, Alice has 2 darts remaining
    // Get Bob's target number for attacks
    final bob = ProviderHelpers.findPlayerByName(tester, 'Bob')!;
    final bobTarget =
        ProviderHelpers.getMonsterMashPlayerTarget(tester, bob.id)!;

    // Alice's remaining 2 darts: attack Bob with triples (6 damage)
    await throwDartViaMock(tester, bobTarget, multiplier: 'triple');
    await throwDartViaMock(tester, bobTarget, multiplier: 'triple');
    await clickDartsRemoved(tester);

    // Bob's turn: miss all 3
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);

    // Alice: finish off Bob (need 4 more damage max, triple + single = 4)
    await throwDartViaMock(tester, bobTarget, multiplier: 'triple');
    await throwDartViaMock(tester, bobTarget);
    await clickDartsRemoved(tester);

    // Wait for results screen
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    // Verify results screen
    expect(config.getPlayAgainButton(), findsOneWidget);

    // Verify saved game was auto-deleted
    final remaining = await SaveGameService().loadSavedGames(gameType);
    expect(remaining, isEmpty);
  });
}
