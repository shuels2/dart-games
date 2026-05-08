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

  testWidgets('Resume Game loads game screen', (tester) async {
    await UITestHelpers.resetServerState();

    // Full roundtrip: navigate -> throw -> save -> home -> resume.
    // Uses in-game save flow because preSaveGame's placeholder gameState
    // (`{'_marker': 'test'}`) causes PiratesGridGame.fromJson to crash on
    // restore (`json['grid'] as List` throws on the placeholder value).
    await setupAndStartGame(tester, config,
        playerNames: ['Alice', 'Bob']);
    final t00 = ProviderHelpers.getPiratesGridCellTargetNumber(tester, 0, 0);
    await throwDartViaMock(tester, t00);

    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await PumpSequences.simpleUpdate(tester);
    final saveButton = ElementFinders.getSaveGameModalSaveButton();
    await tester.ensureVisible(saveButton);
    await tester.pump();
    await tester.tap(saveButton);
    await PumpSequences.navigation(tester);

    // Back to home from menu
    await tester.tap(find.byKey(PiratesGridMenuKeys.backButton));
    await PumpSequences.navigation(tester);

    // Tap game card on home â€” navigates to menu screen
    await UITestHelpers.tapGameCard(tester, config);
    await PumpSequences.asyncDataLoad(tester);

    // Get saved game ID and select it
    final saved = await SaveGameService().loadSavedGames(gameType);
    expect(saved, hasLength(1));
    await UITestHelpers.selectSavedGameTile(tester, saved[0].id);
    await UITestHelpers.tapResumeGameButton(tester);

    // Verify game screen loaded
    expect(config.getSkipTurnButton(), findsOneWidget);

    // Verify players exist in resumed game
    final alice = ProviderHelpers.findPlayerByName(tester, 'Alice');
    final bob = ProviderHelpers.findPlayerByName(tester, 'Bob');
    expect(alice, isNotNull);
    expect(bob, isNotNull);

    // Verify game state: P1 (Alice) should have 1 flag from the pre-save throw
    final provider = ProviderHelpers.getPiratesGridProvider(tester);
    expect(provider.isGameActive, isTrue,
        reason: 'Game should be active after resume');
    final p1Id = provider.currentGame!.playerIds[0];
    expect(provider.currentGame!.getFlagsPlanted(p1Id), 1,
        reason: 'P1 should have 1 flag after resume (state restored)');

    // Verify game is active
    expect(ProviderHelpers.isPiratesGridGameActive(tester), true);
  });
}
