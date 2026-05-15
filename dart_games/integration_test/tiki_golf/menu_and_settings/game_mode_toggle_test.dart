// integration_test/tiki_golf/menu_and_settings/game_mode_toggle_test.dart
//
// Verifies Game Mode toggle behaviour:
//   - Default is SOLO
//   - Tapping TEAM segment switches to team mode
//   - TeamPlayerListPanel stays mounted (same widget, different isTeamMode flag)
//   - Toggling SOLO->TEAM enables the Team Assignment toggle (removes IgnorePointer)
//   - Toggling TEAM->SOLO disables the Team Assignment toggle again
//
// Section 12B File 2 — Test 6 (game_mode_toggle)
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../shared/ui_test_helpers.dart';
import '../../shared/element_finders.dart';
import '_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Game Mode toggle: SOLO-TEAM flips Team Assignment enable state',
      (tester) async {
    await UITestHelpers.resetServerState();
    await UITestHelpers.navigateToGameMenu(tester, config);

    // Helper: is there a 0.5 Opacity widget in the tree?
    bool foundHalfOpacity() {
      for (final element in find.byType(Opacity).evaluate()) {
        final w = element.widget as Opacity;
        if (w.opacity == 0.5) return true;
      }
      return false;
    }

    // Helper: is the player panel add-button mounted (either empty state or normal)?
    bool isAddButtonMounted() {
      return ElementFinders.getTikiGolfAddPlayerButton().evaluate().isNotEmpty ||
          ElementFinders.getTikiGolfAddPlayerButtonEmptyState().evaluate().isNotEmpty;
    }

    // ── Initial state: SOLO mode ──────────────────────────────────────────
    // Team Assignment should be at 50% opacity and IgnorePointer-wrapped.
    expect(foundHalfOpacity(), isTrue,
        reason:
            '[DIAG game_mode_toggle] Team Assignment should be at 50% opacity in Solo mode');

    // Panel mounted in Solo mode
    expect(isAddButtonMounted(), isTrue,
        reason:
            '[DIAG game_mode_toggle] Add player button should be mounted in Solo mode');

    // ── Switch to TEAM mode ────────────────────────────────────────────────
    await setGameModeTeam(tester);

    // Team Assignment box should now be at full opacity (no 0.5 Opacity wrap)
    expect(foundHalfOpacity(), isFalse,
        reason:
            '[DIAG game_mode_toggle] Team Assignment should be at full opacity in Team mode');

    // Add player button still present (panel stays mounted)
    expect(isAddButtonMounted(), isTrue,
        reason:
            '[DIAG game_mode_toggle] Add player button should stay mounted after mode switch to Team');

    // Team Assignment toggle segments should be interactable
    final manualSegment = ElementFinders.getTikiGolfAssignmentModeManual();
    expect(manualSegment, findsOneWidget,
        reason:
            '[DIAG game_mode_toggle] MANUAL segment should be visible in Team mode');

    final randomSegment = ElementFinders.getTikiGolfAssignmentModeRandom();
    expect(randomSegment, findsOneWidget,
        reason:
            '[DIAG game_mode_toggle] RANDOM segment should be visible in Team mode');

    // ── Switch back to SOLO mode ──────────────────────────────────────────
    await setGameModeSolo(tester);

    // Team Assignment should be disabled again
    expect(foundHalfOpacity(), isTrue,
        reason:
            '[DIAG game_mode_toggle] Team Assignment should be at 50% opacity after switching back to Solo');

    // Player list panel should still be mounted
    expect(isAddButtonMounted(), isTrue,
        reason:
            '[DIAG game_mode_toggle] Add player button should still be mounted in Solo mode');
  });
}
