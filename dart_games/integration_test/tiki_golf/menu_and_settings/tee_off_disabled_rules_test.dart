// integration_test/tiki_golf/menu_and_settings/tee_off_disabled_rules_test.dart
//
// TEE OFF disable rules:
//   - Solo with 1 player → disabled
//   - Solo with 2 players → enabled
//   - Team+Random with 2 players → disabled (team mode needs ≥3)
//   - Team+Random with 3 players → enabled
//
// Section 12B File 2 — Test 11 (tee_off_disabled_rules)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TEE OFF button enable/disable rules across modes and player counts',
      (tester) async {
    await UITestHelpers.runWithFailureScreenshot(
      tester,
      'tiki_golf_menu_and_settings_tee_off_disabled_rules',
      () async {
        await UITestHelpers.resetServerState();
        await UITestHelpers.navigateToGameMenu(tester, config);

        // Helper: check if start button is enabled
        bool isStartEnabled() {
          final startButton = ElementFinders.getTikiGolfStartButton();
          if (startButton.evaluate().isEmpty) return false;
          // The ElevatedButton itself carries the key, so cast directly
          final widget = tester.widget<ElevatedButton>(startButton);
          return widget.onPressed != null;
        }

        // ── Solo, 0 players → disabled ────────────────────────────────────────
        expect(isStartEnabled(), isFalse,
            reason:
                '[DIAG tee_off_rules] TEE OFF should be DISABLED with 0 players in Solo');

        // ── Solo, 1 player → disabled ─────────────────────────────────────────
        await UITestHelpers.addPlayer(tester, 'P1', config);
        expect(isStartEnabled(), isFalse,
            reason:
                '[DIAG tee_off_rules] TEE OFF should be DISABLED with 1 player in Solo');

        // ── Solo, 2 players → enabled ─────────────────────────────────────────
        await UITestHelpers.addPlayer(tester, 'P2', config);
        expect(isStartEnabled(), isTrue,
            reason:
                '[DIAG tee_off_rules] TEE OFF should be ENABLED with 2 players in Solo');

        // ── Switch to Team+Random; 2 players selected → still disabled ─────────
        await setGameModeTeam(tester);
        // Random is default assignment; need ≥3 players for Team mode
        expect(isStartEnabled(), isFalse,
            reason:
                '[DIAG tee_off_rules] TEE OFF should be DISABLED in Team+Random with only 2 players');

        // ── Team+Random, 3 players → enabled ──────────────────────────────────
        await UITestHelpers.addPlayer(tester, 'P3', config);
        expect(isStartEnabled(), isTrue,
            reason:
                '[DIAG tee_off_rules] TEE OFF should be ENABLED in Team+Random with 3 players');
      },
    );
  });
}
