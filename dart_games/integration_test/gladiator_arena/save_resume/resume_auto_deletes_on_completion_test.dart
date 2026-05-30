import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dart_games/constants/test_keys.dart';
import 'package:dart_games/services/save_game_service.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/provider_helpers.dart';
import '../../shared/pump_sequences.dart';
import '../../shared/game_setup_helpers.dart';
import '../../shared/results_helpers.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Saved game is auto-deleted when game completes after resume',
      (tester) async {
    await UITestHelpers.resetServerState();

    // Set up game with target=100, DF=OFF so S20×3 wins quickly.
    // navigateToGameScreen uses defaults (target=200, DF=ON) which
    // prevent winning via S20 throws → use setupAndStartGladiatorArena.
    await GameSetupHelpers.setupAndStartGladiatorArena(
      tester,
      config,
      targetScore: 100,
      doubleFinishEnabled: false,
      playerNames: ['Alice', 'Bob'],
    );
    await throwOneDart(tester);
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await UITestHelpers.tapSaveGameButton(tester);

    var saves = await SaveGameService().loadSavedGames(gameType);
    expect(saves, hasLength(1));
    final savedId = saves[0].id;

    // Go home, navigate back, resume
    await tester.tap(find.byKey(GladiatorArenaMenuKeys.backButton));
    await PumpSequences.navigation(tester);
    await UITestHelpers.tapGameCard(tester, config);
    await PumpSequences.asyncDataLoad(tester);

    await UITestHelpers.selectSavedGameTile(tester, savedId);
    await UITestHelpers.tapResumeGameButton(tester);

    // Complete the game to trigger auto-delete
    // Target=100, DF OFF so we can win quickly
    final provider = ProviderHelpers.getGladiatorArenaProvider(tester);
    for (int r = 0; r < 30; r++) {
      if (provider.hasWinner) break;
      for (int d = 0; d < 3; d++) {
        if (provider.hasWinner || provider.shouldPromptTakeout) break;
        await throwDartViaMock(tester, 20);
      }
      if (provider.hasWinner) break;
      if (provider.shouldPromptTakeout) {
        await clickDartsRemoved(tester);
        if (provider.hasWinner) break;
        await completeTurnWithMisses(tester);
      }
    }

    if (provider.hasWinner) {
      await clickDartsRemoved(tester);
    }

    // Wait for navigation (3s delayed) + results initState + HTTP delete call
    await ResultsHelpers.pumpUntilResults(tester, config);

    // Saved game should be auto-deleted
    saves = await SaveGameService().loadSavedGames(gameType);
    expect(saves, isEmpty,
        reason: 'Saved game should be auto-deleted after completion');
  });
}
