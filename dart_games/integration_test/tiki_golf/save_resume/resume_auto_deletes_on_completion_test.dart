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
    // Real-flow: navigate → throw → save → home → resume → play to completion
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

    // Get saved game and resume (Rule §18)
    final saved = await SaveGameService().loadSavedGames(gameType);
    expect(saved, hasLength(1));
    final savedGameId = saved[0].id;
    await UITestHelpers.selectSavedGameTile(tester, savedGameId);
    await UITestHelpers.tapResumeGameButton(tester);

    // Play resumed game to completion — drive every remaining turn to
    // a birdie (target hit on dart 1) then simulate takeout until winner.
    final provider = ProviderHelpers.getTikiGolfProvider(tester);
    while (!provider.hasWinner) {
      final hole = ProviderHelpers.getTikiGolfCurrentHole(tester);
      final target = ProviderHelpers.getTikiGolfHoleTarget(tester, hole);
      await throwDartViaMock(tester, target);
      await clickDartsRemoved(tester);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
    }

    // Wait for results screen navigation (victory delay + animation)
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    // Verify results screen
    expect(config.getPlayAgainButton(), findsOneWidget);

    // Verify saved game was auto-deleted on completion
    final remaining = await SaveGameService().loadSavedGames(gameType);
    expect(remaining, isEmpty);
  });
}
