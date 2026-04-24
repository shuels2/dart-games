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

  testWidgets('Resume Game loads game screen', (tester) async {
    await UITestHelpers.resetServerState();
    // Full roundtrip: navigate -> throw -> save -> home -> resume
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
    await UITestHelpers.selectSavedGameTile(tester, saved[0].id);
    await UITestHelpers.tapResumeGameButton(tester);

    // Verify game screen loaded
    expect(config.getSkipTurnButton(), findsOneWidget);

    // Verify visual elements on game screen (widget key checks)
    expect(find.byKey(ReefRoyaleGameKeys.pearlCounter), findsOneWidget);
    expect(find.byKey(ReefRoyaleGameKeys.coralCounter), findsOneWidget);

    // Verify pearl counter displays text (visual widget check)
    final pearlText =
        tester.widget<Text>(find.byKey(ReefRoyaleGameKeys.pearlCounter));
    expect(pearlText.data, contains('pearls'));

    // Verify coral counter displays text (visual widget check)
    final coralText =
        tester.widget<Text>(find.byKey(ReefRoyaleGameKeys.coralCounter));
    expect(coralText.data, contains('corals'));

    // Verify players exist in resumed game
    final alice = ProviderHelpers.findPlayerByName(tester, 'Alice');
    final bob = ProviderHelpers.findPlayerByName(tester, 'Bob');
    expect(alice, isNotNull);
    expect(bob, isNotNull);

    // Verify game state: 1 dart was thrown before save
    expect(
        ProviderHelpers.getReefRoyaleCurrentPlayerDartsThrown(tester), 1);

    // Verify game is active
    expect(ProviderHelpers.isReefRoyaleGameActive(tester), true);
  });
}
