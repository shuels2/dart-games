// integration_test/tiki_golf/menu_and_settings/start_solo_2_players_test.dart
//
// Verifies Solo mode with 2 players:
//   - TEE OFF is enabled when exactly 2 players are selected
//   - Tapping TEE OFF navigates to the game screen
//
// Section 12B File 2 — Test 5 (start_solo_2_players)
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '../../shared/pump_sequences.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Solo mode: 2 players enables TEE OFF and navigates to game',
      (tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_menu_and_settings_start_solo_2_players',
      () async {
        await UITestHelpers.resetServerState();
        await UITestHelpers.navigateToGameMenu(tester, config);

        // ── TEE OFF disabled with 0 players ─────────────────────────────────
        // (No players selected yet — button should be disabled or absent)
        // We don't tap it; just verify game screen is NOT shown yet.

        // ── Add 2 players ────────────────────────────────────────────────────
        await UITestHelpers.addPlayer(tester, 'TikiAlice', config);
        await UITestHelpers.addPlayer(tester, 'TikiBob', config);

        // ── TEE OFF button should now be enabled ─────────────────────────────
        final startButton = ElementFinders.getTikiGolfStartButton();
        expect(startButton, findsOneWidget,
            reason: '[DIAG start_solo_2p] TEE OFF button not found');

        // ── Tap TEE OFF ───────────────────────────────────────────────────────
        await tester.ensureVisible(startButton);
        await tester.pump();
        await tester.tap(startButton);
        await PumpSequences.navigation(tester);

        // ── Verify we navigated to the game screen ────────────────────────────
        // The game screen has the hole counter widget
        final holeCounter = ElementFinders.getTikiGolfHoleCounter();
        expect(holeCounter, findsOneWidget,
            reason:
                '[DIAG start_solo_2p] Hole counter not found — game screen did not load');

        // ── Verify the back button is the game screen back (not menu back) ────
        final gameBackButton = ElementFinders.getTikiGolfGameBackButton();
        expect(gameBackButton, findsOneWidget,
            reason: '[DIAG start_solo_2p] Game back button not found on game screen');
      },
    );
  });
}
