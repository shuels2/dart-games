import 'package:flutter/material.dart';
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
    await navigateToGameScreenLowShields(tester);
    await throwOneDart(tester);
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await UITestHelpers.tapSaveGameButton(tester);

    // Back to home from menu
    await tester.tap(find.byKey(TargetTagMenuKeys.backButton));
    await PumpSequences.navigation(tester);

    // Tap game card on home - navigates to menu screen
    await tester.tap(config.getGameCard());
    await PumpSequences.navigation(tester);
    await PumpSequences.asyncDataLoad(tester);

    // Get saved game ID and select it
    final saved = await SaveGameService().loadSavedGames(gameType);
    expect(saved, hasLength(1));
    final savedGameId = saved[0].id;
    await UITestHelpers.selectSavedGameTile(tester, savedGameId);
    await UITestHelpers.tapResumeGameButton(tester);

    // Play to completion: 2-player solo, shield_max=3
    // Get dynamic target numbers from provider
    final alice = ProviderHelpers.findPlayerByName(tester, 'Alice')!;
    final bob = ProviderHelpers.findPlayerByName(tester, 'Bob')!;
    final aliceTarget =
        ProviderHelpers.getTargetTagPlayerTarget(tester, alice.id)!;
    final bobTarget =
        ProviderHelpers.getTargetTagPlayerTarget(tester, bob.id)!;

    // Alice has 2 darts remaining (threw S20 before save)
    // Dart 2: Triple own target -> 3 shields -> TAGGED IN
    await throwDartViaMock(tester, aliceTarget, multiplier: 'triple');
    // Dart 3: miss
    await throwDartViaMock(tester, 1);
    await clickDartsRemoved(tester);
    await PumpSequences.fullRebuild(tester);

    // Bob's turn: Triple own target -> TAGGED IN, then miss x2
    await throwDartViaMock(tester, bobTarget, multiplier: 'triple');
    await throwDartViaMock(tester, 1);
    await throwDartViaMock(tester, 1);
    await clickDartsRemoved(tester);
    await PumpSequences.fullRebuild(tester);

    // Alice attacks Bob: 3 singles -> shields 3->2->1->0 (vulnerable)
    await throwDartViaMock(tester, bobTarget);
    await throwDartViaMock(tester, bobTarget);
    await throwDartViaMock(tester, bobTarget);
    await clickDartsRemoved(tester);
    await PumpSequences.fullRebuild(tester);

    // Bob misses all 3
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await throwMissViaMock(tester);
    await clickDartsRemoved(tester);
    await PumpSequences.fullRebuild(tester);

    // Alice eliminates Bob (0 shields -> hit = elimination)
    await throwDartViaMock(tester, bobTarget);
    await PumpSequences.simpleUpdate(tester);
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
