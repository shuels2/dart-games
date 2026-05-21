// integration_test/tiki_golf/menu_and_settings/mulligan_toggle_persists_test.dart
//
// Verifies Mulligan toggle mechanics:
//   - Starts OFF (default)
//   - Flips to ON after single tap
//   - Flips back to OFF after second tap
//
// Note: The menu reinitialises state from widget.initialMulliganEnabled which
// is only set when navigating via Change-Settings flow (game→results→change).
// A plain back+return resets to provider.currentGame?.mulliganEnabled which
// is null before any game is started — so the default (OFF) applies.
// This test validates the within-session toggle mechanics, not cross-session
// storage.
//
// Section 12B File 2 — Test 3 (mulligan_toggle)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Mulligan toggle: flips OFF→ON→OFF correctly',
      (tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // ── Verify initial state: OFF ────────────────────────────────────────
    final mulliganSwitch = ElementFinders.getTikiGolfMulliganSwitch();
    expect(mulliganSwitch, findsOneWidget,
        reason: '[DIAG mulligan_toggle] Mulligan switch not found');

    Switch switchWidget = tester.widget<Switch>(mulliganSwitch);
    expect(switchWidget.value, isFalse,
        reason: '[DIAG mulligan_toggle] Mulligan should start OFF');

    // ── Toggle ON ────────────────────────────────────────────────────────
    await toggleMulligan(tester);

    // Verify it flipped to ON
    switchWidget = tester.widget<Switch>(mulliganSwitch);
    expect(switchWidget.value, isTrue,
        reason:
            '[DIAG mulligan_toggle] Mulligan should be ON after first toggle');

    // ── Toggle OFF again ──────────────────────────────────────────────────
    await toggleMulligan(tester);

    switchWidget = tester.widget<Switch>(mulliganSwitch);
    expect(switchWidget.value, isFalse,
        reason:
            '[DIAG mulligan_toggle] Mulligan should be OFF after second toggle');

    // ── Toggle ON one more time ────────────────────────────────────────────
    await toggleMulligan(tester);

    switchWidget = tester.widget<Switch>(mulliganSwitch);
    expect(switchWidget.value, isTrue,
        reason:
            '[DIAG mulligan_toggle] Mulligan should be ON after third toggle');
  });
}
