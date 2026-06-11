// integration_test/treasure_divide/save_resume/resume_game_loads_screen_test.dart
//
// SaveResume-14 — Full round-trip: start → throw → save → home → tap card →
//                 select tile → Resume → game screen loads with correct state.
//                 Uses in-game Save flow (Rule §17), NOT preSaveGame.
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

  testWidgets('Resume Game loads game screen with correct state',
      (tester) async {
    await UITestHelpers.resetServerState();

    // Step 1: Navigate to game screen, throw 1 dart, save
    await setupAndStartGame(tester, numberOfRounds: 7,
        playerNames: ['Alice', 'Bob']);
    await throwDartViaMock(tester, 20);
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await UITestHelpers.tapSaveGameButton(tester);

    // Step 2: Go back to home from menu
    await tester.tap(find.byKey(TreasureDivideMenuKeys.backButton));
    await PumpSequences.navigation(tester);

    // Step 3: Tap game card — navigates to menu with auto-popup
    await UITestHelpers.tapGameCard(tester, config);
    await PumpSequences.asyncDataLoad(tester);

    // Step 4: Select saved game tile and resume
    final saved = await SaveGameService().loadSavedGames(gameType);
    expect(saved, hasLength(1));
    await UITestHelpers.selectSavedGameTile(tester, saved[0].id);
    await UITestHelpers.tapResumeGameButton(tester);

    // Step 5: Verify game screen loaded
    expect(config.getSkipTurnButton(), findsOneWidget);

    // Step 6: Verify players in resumed game
    final alice = ProviderHelpers.findPlayerByName(tester, 'Alice');
    final bob = ProviderHelpers.findPlayerByName(tester, 'Bob');
    expect(alice, isNotNull);
    expect(bob, isNotNull);

    // Step 7: Verify game is active
    expect(ProviderHelpers.isTreasureDivideGameActive(tester), true);
  });
}
