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
    // Real-flow: navigate → throw → clickDartsRemoved → save → home → resume
    await navigateToGameScreen(tester);
    await throwOneDart(tester);
    await clickDartsRemoved(tester);
    await UITestHelpers.tapGameScreenBackButton(tester, config);
    await UITestHelpers.tapSaveGameButton(tester);

    // Save-and-back lands the user back on the menu WITHOUT auto-popping
    // the Resume modal — see save_and_back_no_auto_resume_modal_test.dart
    // for the regression guard. Just tap back to go home.

    // Back to home from menu
    await tester.tap(find.byKey(TikiGolfMenuKeys.backButton));
    await PumpSequences.navigation(tester);

    // Tap game card on home — navigates to menu screen with resume modal
    await UITestHelpers.tapGameCard(tester, config);
    await PumpSequences.asyncDataLoad(tester);

    // Get saved game ID and select it (Rule §18 — must select before resume)
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
    expect(ProviderHelpers.isTikiGolfGameActive(tester), true);

    // Verify hole is still at 1 (Alice completed hole 1, Bob has not yet)
    expect(ProviderHelpers.getTikiGolfCurrentHole(tester), 1);
  });
}
