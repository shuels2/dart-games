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

  testWidgets('Resume: resumed game loads correct game state', (tester) async {
    await UITestHelpers.resetServerState();
    // Full roundtrip: navigate -> throw -> save -> home -> resume
    await navigateToGameScreen(tester);
    await throwOneDart(tester);
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await UITestHelpers.tapSaveGameButton(tester);

    // Back to home from menu
    await tester.tap(find.byKey(LunarLanderMenuKeys.backButton));
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

    // Verify players exist in resumed game
    final alice = ProviderHelpers.findPlayerByName(tester, 'Alice');
    final bob = ProviderHelpers.findPlayerByName(tester, 'Bob');
    expect(alice, isNotNull);
    expect(bob, isNotNull);

    // Verify game is active
    expect(ProviderHelpers.isLunarLanderGameActive(tester), true);

    // Verify 1 dart was thrown before save (darts thrown counter = 1)
    expect(ProviderHelpers.getLunarLanderCurrentPlayerDartsThrown(tester), 1);
  });
}
