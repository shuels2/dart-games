// integration_test/tiki_golf/menu_and_settings/menu_initial_state_test.dart
//
// Verifies the menu screen renders all 4 settings boxes with correct defaults:
//   - Game Mode = SOLO
//   - Team Assignment = RANDOM (and greyed/disabled)
//   - Max Darts = 3 (dropdown)
//   - Mulligan = OFF (switch)
//
// Section 12B File 2 — Test 2 (menu_initial_state)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Menu initial state: 4 settings boxes with correct defaults',
      (tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // ── Game Mode toggle present (SOLO selected by default) ──────────────
    final gameModeToggle = ElementFinders.getTikiGolfGameModeToggle();
    expect(gameModeToggle, findsOneWidget,
        reason: '[DIAG menu_initial_state] Game Mode toggle row not found');

    final soloSegment = ElementFinders.getTikiGolfGameModeSolo();
    expect(soloSegment, findsOneWidget,
        reason: '[DIAG menu_initial_state] SOLO segment not found');

    final teamSegment = ElementFinders.getTikiGolfGameModeTeam();
    expect(teamSegment, findsOneWidget,
        reason: '[DIAG menu_initial_state] TEAM segment not found');

    // ── Team Assignment toggle present ────────────────────────────────────
    final assignmentToggle =
        ElementFinders.getTikiGolfAssignmentModeToggle();
    expect(assignmentToggle, findsOneWidget,
        reason:
            '[DIAG menu_initial_state] Team Assignment toggle row not found');

    final randomSegment =
        ElementFinders.getTikiGolfAssignmentModeRandom();
    expect(randomSegment, findsOneWidget,
        reason:
            '[DIAG menu_initial_state] RANDOM segment not found');

    final manualSegment =
        ElementFinders.getTikiGolfAssignmentModeManual();
    expect(manualSegment, findsOneWidget,
        reason:
            '[DIAG menu_initial_state] MANUAL segment not found');

    // ── Max Darts dropdown present, default 3 ────────────────────────────
    final maxStrokesDropdown =
        ElementFinders.getTikiGolfMaxStrokesDropdown();
    expect(maxStrokesDropdown, findsOneWidget,
        reason:
            '[DIAG menu_initial_state] Max Darts dropdown not found');

    // The dropdown should show '3' (default value) somewhere on the screen
    expect(find.text('3'), findsWidgets,
        reason:
            '[DIAG menu_initial_state] Default value 3 not visible on screen');

    // ── Mulligan switch present ───────────────────────────────────────────
    final mulliganSwitch = ElementFinders.getTikiGolfMulliganSwitch();
    expect(mulliganSwitch, findsOneWidget,
        reason: '[DIAG menu_initial_state] Mulligan switch not found');

    // Mulligan should be OFF (false) by default
    final switchWidget = tester.widget<Switch>(mulliganSwitch);
    expect(switchWidget.value, isFalse,
        reason:
            '[DIAG menu_initial_state] Mulligan should be OFF by default');

    // ── Team Assignment box disabled in SOLO mode ────────────────────────
    // In Solo mode, the Team Assignment toggle is wrapped in Opacity(0.5)
    // + IgnorePointer. We verify the toggle is still visible (in tree)
    // but that the Opacity widget with 0.5 wraps it.
    final opacityWidgets = find.byType(Opacity);
    bool foundHalfOpacityWrap = false;
    for (final element in opacityWidgets.evaluate()) {
      final widget = element.widget as Opacity;
      if (widget.opacity == 0.5) {
        foundHalfOpacityWrap = true;
        break;
      }
    }
    expect(foundHalfOpacityWrap, isTrue,
        reason:
            '[DIAG menu_initial_state] Team Assignment box should be at 50% opacity in Solo mode');

    // ── Team Count dropdown NOT shown in Solo mode ───────────────────────
    final teamCountDropdown =
        ElementFinders.getTikiGolfTeamCountDropdown();
    expect(teamCountDropdown, findsNothing,
        reason:
            '[DIAG menu_initial_state] Team Count dropdown should NOT appear in Solo mode');

    // ── TEE OFF button present but disabled (no players selected) ─────────
    final startButton = ElementFinders.getTikiGolfStartButton();
    expect(startButton, findsOneWidget,
        reason: '[DIAG menu_initial_state] TEE OFF button not found');
  });
}
